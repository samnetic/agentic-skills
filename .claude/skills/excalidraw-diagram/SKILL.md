---
name: excalidraw-diagram
description: >-
  Create and iteratively refine Excalidraw `.excalidraw` JSON diagrams that
  explain systems visually. Use when users ask for architecture, workflow,
  protocol, product, or educational diagrams from text, code, PDFs, transcripts,
  or research notes. Includes visual pattern mapping, section-by-section builds,
  render-based validation, and brand palette customization.
license: MIT
compatibility: Requires Docker for live preview server
metadata:
  author: samnetic
  version: "1.0"
---

# Excalidraw Diagram

Create diagrams that argue visually, not just labeled boxes.

## Core Principles

| Principle | Meaning |
|-----------|---------|
| Visual argument first | Every diagram defends a claim; layout, grouping, and flow encode meaning beyond labels |
| Structure mirrors behavior | Choose visual patterns that reflect how the system actually works, not uniform grids |
| Concrete over abstract | Prefer real names, real payloads, and real flows; avoid placeholders in technical diagrams |
| Progressive refinement | Build section-by-section, validate after each pass; never one-shot large diagrams |
| Semantic color | Colors carry meaning (success, warning, data flow); never decorative-only |
| Render-verified delivery | No diagram is done until it has been rendered to PNG and visually inspected |

## Workflow

1. Classify diagram depth (`simple` or `comprehensive`).
2. Research source material for factual accuracy when technical.
3. Optionally bootstrap from Mermaid for quick structural draft.
4. Map concepts to visual patterns before writing/fixing JSON.
5. Build `.excalidraw` JSON with semantic colors and clear hierarchy.
6. Lint structure, render PNG, and iterate until visual defects are removed.
7. Deliver JSON + validation artifacts.

## Required Inputs

- Diagram objective and audience.
- Source material (text, script, code, docs, transcript, PDF, notes).
- Preferred style constraints (brand colors, tone, detail level).
- Depth target (`simple` or `comprehensive`) if already decided.

If the user does not specify depth, infer it:
- `simple`: mental models, quick overviews, conceptual explanations.
- `comprehensive`: technical systems, tutorials, protocols, educational assets.

## Decision Tree — Choosing Diagram Approach

```
Start
 ├─ Is the concept mostly a flow/sequence/graph?
 │   ├─ YES → Consider Mermaid bootstrap (step 3)
 │   │        └─ Then refactor layout with visual argument rules
 │   └─ NO  → Skip Mermaid, go direct to JSON
 │
 ├─ Does the diagram need >15 elements or multiple sections?
 │   ├─ YES → Use comprehensive depth + section-by-section build
 │   └─ NO  → Use simple depth + single-pass build
 │
 ├─ Is the subject a real protocol/API/system?
 │   ├─ YES → Research first: gather real names, payloads, flows
 │   └─ NO  → Conceptual mapping is sufficient
 │
 └─ Does the user want live collaboration?
     ├─ YES → Launch preview editor (step 7) alongside build
     └─ NO  → Deliver static .excalidraw + PNG
```

## Progressive Disclosure Map

| Resource | Path | When to read |
|----------|------|--------------|
| Palette and brand tokens | [references/color-palette.md](references/color-palette.md) | Before choosing colors for any element |
| Pattern catalog | [references/visual-patterns.md](references/visual-patterns.md) | During step 4 (Plan the Visual Argument) |
| Excalidraw JSON contract | [references/json-schema.md](references/json-schema.md) | Before writing or editing any JSON |
| JSON snippets/templates | [references/element-templates.md](references/element-templates.md) | When constructing elements in JSON |
| Validation rubric | [references/quality-checklist.md](references/quality-checklist.md) | During step 6 (Validate) as stop criteria |
| Mermaid bootstrap workflow | [references/mermaid-bootstrap.md](references/mermaid-bootstrap.md) | Only when using the Mermaid bootstrap path |
| Renderer setup | [references/renderer-setup.md](references/renderer-setup.md) | First render attempt or on render errors |
| Mermaid conversion script | [scripts/mermaid_to_excalidraw.mjs](scripts/mermaid_to_excalidraw.mjs) | When converting .mmd to .excalidraw |
| Mermaid one-command pipeline | [scripts/mermaid_pipeline.sh](scripts/mermaid_pipeline.sh) | Quick Mermaid-to-PNG in one step |
| Structure lint script | [scripts/lint_excalidraw.py](scripts/lint_excalidraw.py) | Every validation pass (step 6) |
| PNG render script | [scripts/render_excalidraw.py](scripts/render_excalidraw.py) | Every validation pass (step 6) |
| Live preview editor | [scripts/preview.sh](scripts/preview.sh) | When user wants interactive editing |
| Scene description (AI) | [scripts/describe_scene.py](scripts/describe_scene.py) | To inspect scene without rendering |
| Preview API server | [scripts/preview_server.mjs](scripts/preview_server.mjs) | Launched automatically by preview.sh |
| Docker image | [scripts/Dockerfile](scripts/Dockerfile) | When running preview without local Node.js |

## Execution Protocol

### 1) Classify Depth

Decide whether the request is `simple` or `comprehensive`:

- `simple`: 1-2 visual patterns, minimal evidence artifacts, fast iteration.
- `comprehensive`: multiple sections, evidence artifacts, explicit educational flow.

### 2) Research (Technical Diagrams Only)

For protocols, APIs, architecture, and framework internals, verify concrete facts:

- Real event names and message types.
- Actual method names/endpoints.
- Real payload structures.
- True flow direction and lifecycle steps.

Do not use placeholders like `Event A` or `Some API` when concrete artifacts are required.

### 3) Optional Mermaid Bootstrap

When the source concept is mostly flow/graph-oriented, you may start with Mermaid:

1. Draft concise Mermaid that captures topology and sequence only.
2. Convert to `.excalidraw` using
   `node scripts/mermaid_to_excalidraw.mjs input.mmd --output draft.excalidraw`.
   Or run full pipeline in one command:
   `bash scripts/mermaid_pipeline.sh input.mmd`.
3. Treat output as scaffold, not final design.
4. Immediately refactor layout/style with this skill's visual argument rules.

Skip Mermaid when diagrams depend on custom composition, rich evidence artifacts, or non-flow visual metaphors.

### 4) Plan the Visual Argument

Before writing JSON, produce a short plan:

- Primary claim: what should viewers learn.
- Visual structure: which patterns represent each concept.
- Flow direction: left->right, top->bottom, radial, or cyclical.
- Evidence artifacts: code snippets, JSON, sequences, UI mockups.
- Section boundaries: where chunks begin/end for large builds.

Pattern selection guidance lives in [references/visual-patterns.md](references/visual-patterns.md).

### 5) Build JSON

Use [references/json-schema.md](references/json-schema.md) and
[references/element-templates.md](references/element-templates.md).

Rules:

- Set top-level `type` to `excalidraw`.
- Use descriptive IDs (`entry_trigger`, `parser_box`, `arrow_api_to_ui`).
- Keep `text` and `originalText` human-readable.
- Bind arrows/containers correctly on both ends.
- Pull colors from [references/color-palette.md](references/color-palette.md).
- Use font family `2` (Helvetica) for titles and wide labels — monospace (family `3`) has wider characters and clips more easily in Excalidraw's text rendering.

#### Large Diagram Strategy (Comprehensive)

For large diagrams, build section-by-section:

1. Create base file with wrapper keys and section 1.
2. Append one section per edit pass.
3. Keep cross-section bindings updated as each section lands.
4. Reserve whitespace between sections before final balancing.
5. Run lint + render loop after each major section and again at final pass.

Do not attempt one-shot generation for large diagrams.

#### Programmatic Generation (Recommended for Complex Diagrams)

For diagrams with many elements (30+), write a Python builder script instead of hand-editing JSON.
Define helper functions for each element type:

```python
elements = []
seed_counter = [1000]

def next_seed():
    seed_counter[0] += 1
    return seed_counter[0]

def rect(id, x, y, w, h, stroke, bg, bound_text=None, bound_arrows=None):
    be = []
    if bound_text: be.append({"id": bound_text, "type": "text"})
    for a in (bound_arrows or []): be.append({"id": a, "type": "arrow"})
    elements.append({
        "type": "rectangle", "id": id,
        "x": x, "y": y, "width": w, "height": h,
        "strokeColor": stroke, "backgroundColor": bg,
        "fillStyle": "solid", "strokeWidth": 2, "strokeStyle": "solid",
        "roughness": 0, "opacity": 100, "angle": 0,
        "seed": next_seed(), "version": 1, "versionNonce": next_seed(),
        "isDeleted": False, "groupIds": [], "boundElements": be or None,
        "link": None, "locked": False, "roundness": {"type": 3}
    })

def text(id, x, y, w, h, txt, size=13, color="#1F2937", align="center",
         valign="middle", container=None, family=2):
    elements.append({
        "type": "text", "id": id,
        "x": x, "y": y, "width": w, "height": h,
        "text": txt, "originalText": txt,
        "fontSize": size, "fontFamily": family,
        "textAlign": align, "verticalAlign": valign,
        "strokeColor": color, "backgroundColor": "transparent",
        "fillStyle": "solid", "strokeWidth": 1, "strokeStyle": "solid",
        "roughness": 0, "opacity": 100, "angle": 0,
        "seed": next_seed(), "version": 1, "versionNonce": next_seed(),
        "isDeleted": False, "groupIds": [],
        "boundElements": None, "link": None, "locked": False,
        "containerId": container, "autoResize": True, "lineHeight": 1.25
    })

# Build the diagram using these helpers
rect("staging_box", 50, 100, 200, 300, "#1971C2", "#D0EBFF", bound_text="staging_label")
text("staging_label", 50, 100, 200, 30, "Staging n8n", container="staging_box")

# Write output
import json
with open("diagram.excalidraw", "w") as f:
    json.dump({
        "type": "excalidraw", "version": 2,
        "source": "https://excalidraw.com",
        "elements": elements,
        "appState": {"viewBackgroundColor": "#ffffff", "gridSize": None},
        "files": {}
    }, f, indent=2)
```

This is more maintainable than editing raw JSON for large diagrams, and makes
repositioning, color changes, and section additions trivial.

### 6) Validate and Iterate (Mandatory)

Run deterministic checks first, then visual checks:

1. Structure lint:
   `python scripts/lint_excalidraw.py path/to/diagram.excalidraw`
2. Render PNG:
   `uv run python scripts/render_excalidraw.py path/to/diagram.excalidraw`
3. Inspect rendered PNG and fix:
   - clipping/overflow
   - overlaps
   - ambiguous label anchoring
   - broken hierarchy
   - lopsided composition
4. Re-run until quality gates pass.

Use [references/quality-checklist.md](references/quality-checklist.md) as stop criteria.

### 7) Live Preview (Optional)

Launch an interactive Excalidraw editor for collaborative editing with the user:

```bash
bash scripts/preview.sh path/to/diagram.excalidraw --open
```

This starts a full Excalidraw React app with bidirectional file sync:
- Agent edits the `.excalidraw` file on disk → browser auto-updates (~1s).
- User edits in the browser → file on disk auto-saves (~2s).
- Dependencies auto-install on first run.

Alternatively, use Docker (no local Node.js required):

```bash
cd scripts && docker build -t excalidraw-preview .
docker run -p 8091:8091 -v /path/to/diagram.excalidraw:/data/diagram.excalidraw excalidraw-preview
```

Use `python scripts/describe_scene.py path/to/diagram.excalidraw` to get an AI-readable
summary of the current scene (element types, labels, connections, bounds).

### 8) Deliver

Return final artifacts and the short rationale:

- why structure matches concept behavior
- what changed in validation loops
- where viewers should focus first

## Output Contract

Every response should include:

1. Final `.excalidraw` JSON file path.
2. Rendered `.png` path when renderer is available.
3. Depth classification used (`simple` or `comprehensive`).
4. Whether Mermaid bootstrap was used (`yes/no`).
5. Brief visual argument summary (2-6 bullets).
6. Validation summary:
   - lint result
   - number of render/fix iterations
   - remaining known limitations, if any.

## Quality Gates

- Structure mirrors concept behavior (not uniform box grid).
- Technical diagrams contain concrete evidence artifacts.
- Major relationships are shown by arrows/lines, not proximity alone.
- Text is readable at exported scale with no clipping.
- Colors are semantic and drawn from the palette reference.
- Cross-element bindings are valid and resolvable.
- Composition is balanced (no crowded/empty extremes).
- For comprehensive diagrams, section-by-section build strategy was used.
- If Mermaid bootstrap was used, final design is meaningfully refined beyond default conversion output.

## Checklist

Use before declaring a diagram complete:

- [ ] Depth classification (`simple`/`comprehensive`) recorded
- [ ] Visual argument plan written before JSON construction
- [ ] Pattern selection justified (not default box grid)
- [ ] Colors pulled from palette reference, used semantically
- [ ] All arrow bindings valid (startBinding/endBinding resolve to real IDs)
- [ ] Container bindings correct (containerId on children, boundElements on parents)
- [ ] IDs are descriptive strings, not random UUIDs
- [ ] Text readable at export scale, no clipping or overflow
- [ ] Structure lint passes with zero errors
- [ ] PNG rendered and visually inspected at least once
- [ ] No overlapping elements or ambiguous label anchoring
- [ ] Composition balanced (no crowded or empty regions)
- [ ] For comprehensive: section-by-section build strategy was used
- [ ] For Mermaid bootstrap: output meaningfully refined beyond raw conversion
- [ ] Evidence artifacts (code, payloads, sequences) included for technical diagrams
- [ ] Output contract items delivered (JSON path, PNG path, summary, validation log)

## Anti-Patterns

- Card-grid diagrams with identical containers for every concept.
- Visuals that only repeat text labels without showing mechanics.
- Placeholder evidence in technical diagrams.
- One-shot huge JSON generation that causes truncation or broken bindings.
- Skipping render review and declaring completion from raw JSON only.

## Handoff Guidance

- Use `software-architecture` for deeper system decomposition before diagramming.
- Use `business-analysis` when requirements are ambiguous and need structured extraction.
- Use `technical-writing` when the diagram needs a paired narrative artifact.
