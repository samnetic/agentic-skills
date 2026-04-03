# Quality Checklist

Use this after lint and after each render pass.

## 1) Concept Quality

- Diagram expresses an argument, not just labels.
- Visual structure mirrors behavior of concepts.
- Pattern choice is intentional (timeline, fan-out, cycle, etc.).
- For comprehensive diagrams, includes summary + sections + concrete detail.

## 2) Educational Value

- Technical diagrams show real artifacts (code, JSON, event names, APIs).
- Terms and payloads match source material.
- Reader can learn a concrete mechanic, not only vocabulary.

## 3) Structural Integrity

- All referenced IDs exist.
- Arrow bindings point to intended elements.
- Container/text bindings are valid.
- No duplicated element IDs.

## 4) Visual Integrity

- No clipped or overflowing text.
- No accidental overlap between text and shapes.
- Arrows avoid crossing through unrelated elements when avoidable.
- Spacing is consistent within peer groups.
- Composition is balanced (no major empty void next to dense cluster).
- Readable at exported size.

## 5) Style Consistency

- Colors come from `color-palette.md`.
- Typography is consistent with hierarchy.
- `roughness` and stroke widths match requested style.
- Container use is disciplined; not every label is boxed.

## 6) Delivery Readiness

- `.excalidraw` file saved.
- `.png` render generated (if renderer available).
- If Mermaid bootstrap was used, final layout is refined beyond default conversion output.
- Remaining caveats documented briefly.
