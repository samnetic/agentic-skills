#!/usr/bin/env python3
"""Describe an Excalidraw scene in human/AI-readable format.

Outputs a structured summary: element types, text labels with container info,
connections graph, and canvas bounds. Useful for AI agents to understand
what's in a diagram without parsing raw JSON.

Usage: python describe_scene.py <file.excalidraw>
"""

import json
import sys
from collections import Counter


def describe(path: str) -> str:
    with open(path) as f:
        data = json.load(f)

    elements = [e for e in data.get("elements", []) if not e.get("isDeleted")]
    types = Counter(e["type"] for e in elements)

    # Bounding box
    xs = [e["x"] for e in elements if "x" in e]
    ys = [e["y"] for e in elements if "y" in e]
    x2s = [e["x"] + e.get("width", 0) for e in elements if "x" in e]
    y2s = [e["y"] + e.get("height", 0) for e in elements if "y" in e]

    bbox = {
        "left": min(xs) if xs else 0,
        "top": min(ys) if ys else 0,
        "right": max(x2s) if x2s else 0,
        "bottom": max(y2s) if y2s else 0,
    }
    bbox["width"] = bbox["right"] - bbox["left"]
    bbox["height"] = bbox["bottom"] - bbox["top"]

    # Build label lookup: container_id -> text label
    id_to_label = {}
    for e in elements:
        if e.get("text") and e.get("containerId"):
            id_to_label[e["containerId"]] = e["text"].replace("\n", " ").strip()
        elif e.get("text"):
            id_to_label[e["id"]] = e["text"].replace("\n", " ").strip()

    # Text content with context
    texts = []
    for e in elements:
        if e.get("text"):
            label = e["text"].replace("\n", " ").strip()
            container = e.get("containerId")
            if container:
                texts.append(f'  "{label}" (in {container})')
            else:
                texts.append(f'  "{label}" (free @ {e.get("x", "?")},{e.get("y", "?")})')

    # Connections as readable graph
    connections = []
    for e in elements:
        if e["type"] == "arrow":
            src = e.get("startBinding", {}).get("elementId", "?") if e.get("startBinding") else "?"
            dst = e.get("endBinding", {}).get("elementId", "?") if e.get("endBinding") else "?"
            src_label = id_to_label.get(src, src)
            dst_label = id_to_label.get(dst, dst)
            connections.append(f"  {src_label} --> {dst_label}")

    # Format output
    type_summary = ", ".join(f"{t}: {c}" for t, c in types.most_common())
    lines = [
        f"Scene: {len(elements)} elements",
        f"Types: {type_summary}",
        f"Canvas: {bbox['width']:.0f} x {bbox['height']:.0f} px  (origin: {bbox['left']:.0f}, {bbox['top']:.0f})",
        "",
        "Labels:",
        *(texts if texts else ["  (none)"]),
        "",
        "Connections:",
        *(connections if connections else ["  (none)"]),
    ]
    return "\n".join(lines)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python describe_scene.py <file.excalidraw>", file=sys.stderr)
        sys.exit(1)
    print(describe(sys.argv[1]))
