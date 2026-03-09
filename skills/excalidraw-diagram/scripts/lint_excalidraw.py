#!/usr/bin/env python3
"""Lint Excalidraw JSON for structural correctness and common quality issues."""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any


@dataclass
class LintIssue:
    severity: str  # "error" or "warn"
    code: str
    message: str
    element_id: str | None = None


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Lint .excalidraw JSON files")
    parser.add_argument("input", type=Path, help="Path to .excalidraw file")
    parser.add_argument(
        "--strict",
        action="store_true",
        help="Treat warnings as errors (non-zero exit code)",
    )
    return parser.parse_args()


def load_json(path: Path) -> dict[str, Any]:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise ValueError(f"invalid JSON: {exc}") from exc


def lint_payload(payload: dict[str, Any]) -> list[LintIssue]:
    issues: list[LintIssue] = []

    if payload.get("type") != "excalidraw":
        issues.append(
            LintIssue(
                severity="error",
                code="top-level-type",
                message=f"top-level 'type' must be 'excalidraw' (found {payload.get('type')!r})",
            )
        )

    elements = payload.get("elements")
    if not isinstance(elements, list):
        issues.append(
            LintIssue(
                severity="error",
                code="elements-type",
                message="top-level 'elements' must be an array",
            )
        )
        return issues
    if len(elements) == 0:
        issues.append(
            LintIssue(
                severity="error",
                code="elements-empty",
                message="'elements' array is empty",
            )
        )
        return issues

    element_ids: list[str] = []
    for index, element in enumerate(elements):
        if not isinstance(element, dict):
            issues.append(
                LintIssue(
                    severity="error",
                    code="element-not-object",
                    message=f"element at index {index} is not an object",
                )
            )
            continue
        element_id = element.get("id")
        if not isinstance(element_id, str) or not element_id.strip():
            issues.append(
                LintIssue(
                    severity="error",
                    code="missing-id",
                    message=f"element at index {index} has missing/invalid id",
                )
            )
            continue
        element_ids.append(element_id)

    id_set = set(element_ids)
    if len(id_set) != len(element_ids):
        seen: set[str] = set()
        duplicates: set[str] = set()
        for element_id in element_ids:
            if element_id in seen:
                duplicates.add(element_id)
            seen.add(element_id)
        for duplicate in sorted(duplicates):
            issues.append(
                LintIssue(
                    severity="error",
                    code="duplicate-id",
                    message=f"duplicate element id: {duplicate}",
                    element_id=duplicate,
                )
            )

    def ensure_reference(ref_id: Any, field_name: str, owner_id: str) -> None:
        if ref_id is None:
            return
        if not isinstance(ref_id, str) or ref_id not in id_set:
            issues.append(
                LintIssue(
                    severity="error",
                    code="broken-reference",
                    message=f"{field_name} references missing element id {ref_id!r}",
                    element_id=owner_id,
                )
            )

    for element in elements:
        if not isinstance(element, dict):
            continue
        owner_id = str(element.get("id", "<unknown>"))
        element_type = element.get("type")

        if not isinstance(element_type, str):
            issues.append(
                LintIssue(
                    severity="error",
                    code="missing-type",
                    message="element is missing valid 'type'",
                    element_id=owner_id,
                )
            )

        for field in ("x", "y"):
            value = element.get(field)
            if not isinstance(value, (int, float)):
                issues.append(
                    LintIssue(
                        severity="warn",
                        code="missing-position",
                        message=f"element has non-numeric '{field}'",
                        element_id=owner_id,
                    )
                )

        if element_type in {"rectangle", "diamond", "ellipse", "text", "frame"}:
            for field in ("width", "height"):
                value = element.get(field)
                if not isinstance(value, (int, float)):
                    issues.append(
                        LintIssue(
                            severity="warn",
                            code="missing-size",
                            message=f"{element_type} element has non-numeric '{field}'",
                            element_id=owner_id,
                        )
                    )

        if element_type == "text":
            text = element.get("text")
            original_text = element.get("originalText")
            if not isinstance(text, str) or not text.strip():
                issues.append(
                    LintIssue(
                        severity="error",
                        code="text-missing",
                        message="text element has empty/missing 'text'",
                        element_id=owner_id,
                    )
                )
            if not isinstance(original_text, str) or not original_text.strip():
                issues.append(
                    LintIssue(
                        severity="warn",
                        code="original-text-missing",
                        message="text element has empty/missing 'originalText'",
                        element_id=owner_id,
                    )
                )
            container_id = element.get("containerId")
            ensure_reference(container_id, "containerId", owner_id)

        if element_type in {"arrow", "line"}:
            points = element.get("points")
            if not isinstance(points, list) or len(points) < 2:
                issues.append(
                    LintIssue(
                        severity="warn",
                        code="points-invalid",
                        message=f"{element_type} should have at least two points",
                        element_id=owner_id,
                    )
                )

        if element_type == "arrow":
            for binding_name in ("startBinding", "endBinding"):
                binding = element.get(binding_name)
                if binding is None:
                    continue
                if not isinstance(binding, dict):
                    issues.append(
                        LintIssue(
                            severity="warn",
                            code="binding-invalid",
                            message=f"{binding_name} should be an object",
                            element_id=owner_id,
                        )
                    )
                    continue
                ensure_reference(binding.get("elementId"), f"{binding_name}.elementId", owner_id)

        bound_elements = element.get("boundElements")
        if bound_elements is None:
            continue
        if not isinstance(bound_elements, list):
            issues.append(
                LintIssue(
                    severity="warn",
                    code="bound-elements-invalid",
                    message="'boundElements' should be an array or null",
                    element_id=owner_id,
                )
            )
            continue
        for bound in bound_elements:
            if not isinstance(bound, dict):
                issues.append(
                    LintIssue(
                        severity="warn",
                        code="bound-element-item-invalid",
                        message="boundElements entry should be an object",
                        element_id=owner_id,
                    )
                )
                continue
            ensure_reference(bound.get("id"), "boundElements[].id", owner_id)

    return issues


def print_issues(issues: list[LintIssue]) -> None:
    if not issues:
        print("OK: no lint issues found")
        return

    for issue in issues:
        prefix = issue.severity.upper()
        target = f" [id={issue.element_id}]" if issue.element_id else ""
        print(f"{prefix} {issue.code}{target}: {issue.message}")

    error_count = sum(1 for issue in issues if issue.severity == "error")
    warning_count = sum(1 for issue in issues if issue.severity == "warn")
    print(f"\nSummary: {error_count} error(s), {warning_count} warning(s)")


def main() -> int:
    args = parse_args()

    if not args.input.exists():
        print(f"ERROR: file not found: {args.input}", file=sys.stderr)
        return 2

    try:
        payload = load_json(args.input)
    except Exception as exc:  # noqa: BLE001
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2

    issues = lint_payload(payload)
    print_issues(issues)

    has_error = any(issue.severity == "error" for issue in issues)
    has_warning = any(issue.severity == "warn" for issue in issues)
    if has_error:
        return 1
    if args.strict and has_warning:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

