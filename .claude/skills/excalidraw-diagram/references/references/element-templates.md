# Element Templates

Copy, then replace IDs, coordinates, and colors from `color-palette.md`.

## Free-Floating Text

```json
{
  "type": "text",
  "id": "label_title",
  "x": 120,
  "y": 80,
  "width": 320,
  "height": 28,
  "text": "System Overview",
  "originalText": "System Overview",
  "fontSize": 24,
  "fontFamily": 3,
  "textAlign": "left",
  "verticalAlign": "top",
  "strokeColor": "#1E3A8A",
  "backgroundColor": "transparent",
  "fillStyle": "solid",
  "strokeWidth": 1,
  "strokeStyle": "solid",
  "roughness": 0,
  "opacity": 100,
  "angle": 0,
  "seed": 11001,
  "version": 1,
  "versionNonce": 21001,
  "isDeleted": false,
  "groupIds": [],
  "boundElements": null,
  "link": null,
  "locked": false,
  "containerId": null,
  "lineHeight": 1.25
}
```

## Rectangle + Centered Text

```json
{
  "type": "rectangle",
  "id": "process_box",
  "x": 220,
  "y": 180,
  "width": 220,
  "height": 100,
  "strokeColor": "#1E3A8A",
  "backgroundColor": "#DBEAFE",
  "fillStyle": "solid",
  "strokeWidth": 2,
  "strokeStyle": "solid",
  "roughness": 0,
  "opacity": 100,
  "angle": 0,
  "seed": 12001,
  "version": 1,
  "versionNonce": 22001,
  "isDeleted": false,
  "groupIds": [],
  "boundElements": [{ "id": "process_label", "type": "text" }],
  "link": null,
  "locked": false,
  "roundness": { "type": 3 }
}
```

```json
{
  "type": "text",
  "id": "process_label",
  "x": 260,
  "y": 218,
  "width": 140,
  "height": 24,
  "text": "Process",
  "originalText": "Process",
  "fontSize": 18,
  "fontFamily": 3,
  "textAlign": "center",
  "verticalAlign": "middle",
  "strokeColor": "#1F2937",
  "backgroundColor": "transparent",
  "fillStyle": "solid",
  "strokeWidth": 1,
  "strokeStyle": "solid",
  "roughness": 0,
  "opacity": 100,
  "angle": 0,
  "seed": 12002,
  "version": 1,
  "versionNonce": 22002,
  "isDeleted": false,
  "groupIds": [],
  "boundElements": null,
  "link": null,
  "locked": false,
  "containerId": "process_box",
  "lineHeight": 1.25
}
```

## Diamond (Decision)

```json
{
  "type": "diamond",
  "id": "decision_node",
  "x": 520,
  "y": 190,
  "width": 180,
  "height": 100,
  "strokeColor": "#B45309",
  "backgroundColor": "#FEF3C7",
  "fillStyle": "solid",
  "strokeWidth": 2,
  "strokeStyle": "solid",
  "roughness": 0,
  "opacity": 100,
  "angle": 0,
  "seed": 13001,
  "version": 1,
  "versionNonce": 23001,
  "isDeleted": false,
  "groupIds": [],
  "boundElements": [{ "id": "decision_label", "type": "text" }],
  "link": null,
  "locked": false
}
```

## Structural Line + Marker Dot

```json
{
  "type": "line",
  "id": "timeline_spine",
  "x": 120,
  "y": 340,
  "width": 0,
  "height": 320,
  "strokeColor": "#334155",
  "backgroundColor": "transparent",
  "fillStyle": "solid",
  "strokeWidth": 2,
  "strokeStyle": "solid",
  "roughness": 0,
  "opacity": 100,
  "angle": 0,
  "seed": 14001,
  "version": 1,
  "versionNonce": 24001,
  "isDeleted": false,
  "groupIds": [],
  "boundElements": null,
  "link": null,
  "locked": false,
  "points": [[0, 0], [0, 320]]
}
```

```json
{
  "type": "ellipse",
  "id": "timeline_dot_1",
  "x": 114,
  "y": 390,
  "width": 12,
  "height": 12,
  "strokeColor": "#2563EB",
  "backgroundColor": "#2563EB",
  "fillStyle": "solid",
  "strokeWidth": 1,
  "strokeStyle": "solid",
  "roughness": 0,
  "opacity": 100,
  "angle": 0,
  "seed": 14002,
  "version": 1,
  "versionNonce": 24002,
  "isDeleted": false,
  "groupIds": [],
  "boundElements": null,
  "link": null,
  "locked": false
}
```

## Arrow

```json
{
  "type": "arrow",
  "id": "arrow_process_to_decision",
  "x": 442,
  "y": 230,
  "width": 76,
  "height": 0,
  "strokeColor": "#1E3A8A",
  "backgroundColor": "transparent",
  "fillStyle": "solid",
  "strokeWidth": 2,
  "strokeStyle": "solid",
  "roughness": 0,
  "opacity": 100,
  "angle": 0,
  "seed": 15001,
  "version": 1,
  "versionNonce": 25001,
  "isDeleted": false,
  "groupIds": [],
  "boundElements": null,
  "link": null,
  "locked": false,
  "points": [[0, 0], [76, 0]],
  "startBinding": { "elementId": "process_box", "focus": 0, "gap": 2 },
  "endBinding": { "elementId": "decision_node", "focus": 0, "gap": 2 },
  "startArrowhead": null,
  "endArrowhead": "arrow"
}
```

