#!/usr/bin/env python3
"""Render Excalidraw JSON files to PNG using Playwright + headless Chromium."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Render .excalidraw to PNG")
    parser.add_argument("input", type=Path, help="Path to .excalidraw JSON file")
    parser.add_argument(
        "--output",
        "-o",
        type=Path,
        default=None,
        help="Output PNG path (default: same basename as input with .png)",
    )
    parser.add_argument(
        "--scale",
        "-s",
        type=int,
        default=2,
        help="Device scale factor for screenshot output (default: 2)",
    )
    parser.add_argument(
        "--max-width",
        type=int,
        default=2200,
        help="Maximum viewport width in pixels (default: 2200)",
    )
    parser.add_argument(
        "--min-height",
        type=int,
        default=640,
        help="Minimum viewport height in pixels (default: 640)",
    )
    parser.add_argument(
        "--padding",
        type=int,
        default=96,
        help="Padding around computed element bounds in pixels (default: 96)",
    )
    parser.add_argument(
        "--module-timeout-ms",
        type=int,
        default=45000,
        help="Max wait time for module import (default: 45000)",
    )
    parser.add_argument(
        "--render-timeout-ms",
        type=int,
        default=20000,
        help="Max wait time for render completion (default: 20000)",
    )
    return parser.parse_args()


def read_payload(path: Path) -> dict[str, Any]:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise ValueError(f"invalid JSON in {path}: {exc}") from exc


def validate_payload(payload: dict[str, Any]) -> list[str]:
    errors: list[str] = []

    if payload.get("type") != "excalidraw":
        errors.append(f"expected top-level type 'excalidraw', found {payload.get('type')!r}")

    elements = payload.get("elements")
    if not isinstance(elements, list):
        errors.append("top-level 'elements' must be an array")
        return errors
    if len(elements) == 0:
        errors.append("'elements' is empty")
        return errors

    seen: set[str] = set()
    duplicate: set[str] = set()
    for idx, element in enumerate(elements):
        if not isinstance(element, dict):
            errors.append(f"element at index {idx} is not an object")
            continue
        element_id = element.get("id")
        if not isinstance(element_id, str) or not element_id.strip():
            errors.append(f"element at index {idx} has missing/invalid id")
            continue
        if element_id in seen:
            duplicate.add(element_id)
        seen.add(element_id)

    for element_id in sorted(duplicate):
        errors.append(f"duplicate element id: {element_id}")

    return errors


def _safe_number(value: Any, default: float = 0.0) -> float:
    return float(value) if isinstance(value, (int, float)) else default


def compute_bounds(elements: list[dict[str, Any]]) -> tuple[float, float, float, float]:
    min_x = float("inf")
    min_y = float("inf")
    max_x = float("-inf")
    max_y = float("-inf")

    for element in elements:
        if element.get("isDeleted"):
            continue

        x = _safe_number(element.get("x"), 0.0)
        y = _safe_number(element.get("y"), 0.0)
        width = _safe_number(element.get("width"), 0.0)
        height = _safe_number(element.get("height"), 0.0)

        points = element.get("points")
        if isinstance(points, list) and points and element.get("type") in {"arrow", "line"}:
            for point in points:
                if (
                    isinstance(point, (list, tuple))
                    and len(point) == 2
                    and isinstance(point[0], (int, float))
                    and isinstance(point[1], (int, float))
                ):
                    px = x + float(point[0])
                    py = y + float(point[1])
                    min_x = min(min_x, px)
                    min_y = min(min_y, py)
                    max_x = max(max_x, px)
                    max_y = max(max_y, py)
            continue

        left = min(x, x + width)
        right = max(x, x + width)
        top = min(y, y + height)
        bottom = max(y, y + height)

        min_x = min(min_x, left)
        min_y = min(min_y, top)
        max_x = max(max_x, right)
        max_y = max(max_y, bottom)

    if min_x == float("inf"):
        return (0.0, 0.0, 1200.0, 800.0)

    if max_x <= min_x:
        max_x = min_x + 1.0
    if max_y <= min_y:
        max_y = min_y + 1.0
    return (min_x, min_y, max_x, max_y)


def render_to_png(
    payload: dict[str, Any],
    output_path: Path,
    scale: int,
    max_width: int,
    min_height: int,
    padding: int,
    module_timeout_ms: int,
    render_timeout_ms: int,
) -> None:
    try:
        from playwright.sync_api import sync_playwright
    except Exception as exc:  # noqa: BLE001
        raise RuntimeError(
            "playwright is not installed. Run: uv sync && uv run playwright install chromium"
        ) from exc

    elements = [el for el in payload.get("elements", []) if isinstance(el, dict)]
    min_x, min_y, max_x, max_y = compute_bounds(elements)
    diagram_width = (max_x - min_x) + (padding * 2)
    diagram_height = (max_y - min_y) + (padding * 2)

    viewport_width = max(800, min(int(diagram_width), max_width))
    viewport_height = max(min_height, int(diagram_height))

    template_path = Path(__file__).parent / "render_template.html"
    if not template_path.exists():
        raise RuntimeError(f"template not found: {template_path}")
    template_url = template_path.resolve().as_uri()

    with sync_playwright() as playwright:
        try:
            browser = playwright.chromium.launch(headless=True)
        except Exception as exc:  # noqa: BLE001
            raise RuntimeError(
                "Chromium is not available for Playwright. Run: uv run playwright install chromium"
            ) from exc

        page = browser.new_page(
            viewport={"width": viewport_width, "height": viewport_height},
            device_scale_factor=scale,
        )
        page.goto(template_url)

        page.wait_for_function(
            "() => window.__moduleReady === true || window.__moduleError !== null",
            timeout=module_timeout_ms,
        )

        module_error = page.evaluate("() => window.__moduleError")
        if module_error:
            browser.close()
            raise RuntimeError(f"failed to load Excalidraw module in browser context: {module_error}")

        result = page.evaluate(
            "async (diagram) => await window.renderDiagram(diagram)",
            payload,
        )
        if not isinstance(result, dict) or not result.get("success"):
            browser.close()
            msg = "unknown render failure"
            if isinstance(result, dict):
                msg = str(result.get("error", msg))
            raise RuntimeError(msg)

        page.wait_for_function("() => window.__renderComplete === true", timeout=render_timeout_ms)

        render_error = page.evaluate("() => window.__renderError")
        if render_error:
            browser.close()
            raise RuntimeError(f"render error: {render_error}")

        svg = page.query_selector("#root svg")
        if svg is None:
            browser.close()
            raise RuntimeError("no SVG output found in renderer root")

        output_path.parent.mkdir(parents=True, exist_ok=True)
        svg.screenshot(path=str(output_path))
        browser.close()


def main() -> int:
    args = parse_args()

    if not args.input.exists():
        print(f"ERROR: file not found: {args.input}", file=sys.stderr)
        return 2

    output = args.output if args.output is not None else args.input.with_suffix(".png")

    try:
        payload = read_payload(args.input)
    except Exception as exc:  # noqa: BLE001
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2

    validation_errors = validate_payload(payload)
    if validation_errors:
        print("ERROR: invalid .excalidraw payload:", file=sys.stderr)
        for err in validation_errors:
            print(f"  - {err}", file=sys.stderr)
        return 1

    try:
        render_to_png(
            payload=payload,
            output_path=output,
            scale=max(1, args.scale),
            max_width=max(1000, args.max_width),
            min_height=max(300, args.min_height),
            padding=max(0, args.padding),
            module_timeout_ms=max(1, args.module_timeout_ms),
            render_timeout_ms=max(1, args.render_timeout_ms),
        )
    except Exception as exc:  # noqa: BLE001
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    print(str(output))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

