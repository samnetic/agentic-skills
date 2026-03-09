# Excalidraw JSON Contract

Use this contract as the minimum valid shape for generated files.

## Top-Level Skeleton

```json
{
  "type": "excalidraw",
  "version": 2,
  "source": "https://excalidraw.com",
  "elements": [],
  "appState": {
    "viewBackgroundColor": "#ffffff",
    "gridSize": null
  },
  "files": {}
}
```

## Required Invariants

- `type` must be `excalidraw`.
- `elements` must be a non-empty array for renderable output.
- Every element must have unique `id`.
- `containerId`, `startBinding.elementId`, `endBinding.elementId`, and `boundElements[*].id` must reference existing elements.
- `text` elements should include both `text` and `originalText`.

## Common Element Types

| Type | Typical Use |
|---|---|
| `text` | Labels and annotations |
| `rectangle` | Processes and grouped components |
| `ellipse` | Start/end nodes, markers, or abstract states |
| `diamond` | Decisions |
| `line` | Structural skeletons (timelines/trees/dividers) |
| `arrow` | Directed relationships |
| `frame` | Optional visual grouping |

## Coordinate and Size Guidance

- Use integer coordinates for maintainability.
- Keep consistent spacing increments (for example 40px or 80px grid steps).
- Prefer larger spacing over dense packing in first pass.
- Use `roughness: 0` for clean technical output unless user requests sketch style.

## Arrow Binding Example

```json
{
  "type": "arrow",
  "id": "arrow_request",
  "startBinding": { "elementId": "client_box", "focus": 0, "gap": 2 },
  "endBinding": { "elementId": "api_box", "focus": 0, "gap": 2 },
  "endArrowhead": "arrow"
}
```

