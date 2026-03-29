# JSON Canvas Reference

Canvas files (`.canvas`) follow the [JSON Canvas Spec 1.0](https://jsoncanvas.org/spec/1.0/).

## File Structure

```json
{
  "nodes": [],
  "edges": []
}
```

## Nodes

Array order determines z-index (first = bottom, last = top).

### Generic Attributes (all nodes)

| Attribute | Required | Type | Description |
|-----------|----------|------|-------------|
| `id` | Yes | string | Unique 16-char hex identifier |
| `type` | Yes | string | `text`, `file`, `link`, or `group` |
| `x` | Yes | integer | X position in pixels |
| `y` | Yes | integer | Y position in pixels |
| `width` | Yes | integer | Width in pixels |
| `height` | Yes | integer | Height in pixels |
| `color` | No | canvasColor | Preset `"1"`-`"6"` or hex `"#FF0000"` |

### Text Node

Additional: `text` (required) — plain text with Markdown syntax.

```json
{"id": "6f0ad84f44ce9c17", "type": "text", "x": 0, "y": 0, "width": 400, "height": 200, "text": "# Hello World\n\nThis is **Markdown**."}
```

Use `\n` for line breaks. Do NOT use literal `\\n`.

### File Node

Additional: `file` (required) — path to file within vault. `subpath` (optional) — heading/block link starting with `#`.

```json
{"id": "a1b2c3d4e5f67890", "type": "file", "x": 500, "y": 0, "width": 400, "height": 300, "file": "Attachments/diagram.png"}
```

### Link Node

Additional: `url` (required) — external URL.

```json
{"id": "c3d4e5f678901234", "type": "link", "x": 1000, "y": 0, "width": 400, "height": 200, "url": "https://obsidian.md"}
```

### Group Node

Additional: `label` (optional), `background` (optional — image path), `backgroundStyle` (optional — `cover`, `ratio`, `repeat`).

```json
{"id": "d4e5f6789012345a", "type": "group", "x": -50, "y": -50, "width": 1000, "height": 600, "label": "Project Overview", "color": "4"}
```

## Edges

| Attribute | Required | Type | Default | Description |
|-----------|----------|------|---------|-------------|
| `id` | Yes | string | - | Unique identifier |
| `fromNode` | Yes | string | - | Source node ID |
| `fromSide` | No | string | - | `top`, `right`, `bottom`, `left` |
| `fromEnd` | No | string | `none` | `none` or `arrow` |
| `toNode` | Yes | string | - | Target node ID |
| `toSide` | No | string | - | `top`, `right`, `bottom`, `left` |
| `toEnd` | No | string | `arrow` | `none` or `arrow` |
| `color` | No | canvasColor | - | Line color |
| `label` | No | string | - | Text label |

```json
{"id": "0123456789abcdef", "fromNode": "6f0ad84f44ce9c17", "fromSide": "right", "toNode": "a1b2c3d4e5f67890", "toSide": "left", "label": "leads to"}
```

## Colors

| Preset | Color |
|--------|-------|
| `"1"` | Red |
| `"2"` | Orange |
| `"3"` | Yellow |
| `"4"` | Green |
| `"5"` | Cyan |
| `"6"` | Purple |

## ID Generation

16-character lowercase hexadecimal strings (64-bit random value): `"6f0ad84f44ce9c17"`

## Layout Guidelines

- Coordinates can be negative (canvas extends infinitely)
- `x` increases right, `y` increases down; position is top-left corner
- Space nodes 50-100px apart; 20-50px padding inside groups
- Align to grid (multiples of 20) for cleaner layouts

| Node Type | Width | Height |
|-----------|-------|--------|
| Small text | 200-300 | 80-150 |
| Medium text | 300-450 | 150-300 |
| Large text | 400-600 | 300-500 |
| File preview | 300-500 | 200-400 |
| Link preview | 250-400 | 100-200 |

## Validation Checklist

1. All `id` values are unique across nodes and edges
2. Every `fromNode`/`toNode` references an existing node ID
3. Required fields present for each node type
4. `type` is one of: `text`, `file`, `link`, `group`
5. `fromSide`/`toSide` is one of: `top`, `right`, `bottom`, `left`
6. `fromEnd`/`toEnd` is one of: `none`, `arrow`
7. Color presets are `"1"` through `"6"` or valid hex
8. JSON is valid and parseable

## References

- [JSON Canvas Spec 1.0](https://jsoncanvas.org/spec/1.0/)
- [JSON Canvas GitHub](https://github.com/obsidianmd/jsoncanvas)
