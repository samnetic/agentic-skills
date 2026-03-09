---
name: excalidraw-diagram
description: >-
  Create and iteratively refine Excalidraw `.excalidraw` JSON diagrams that
  explain systems visually. Use when users ask for architecture, workflow,
  protocol, product, or educational diagrams from text, code, PDFs, transcripts,
  or research notes. Includes visual pattern mapping, section-by-section builds,
  render-based validation, and brand palette customization.
---

# Excalidraw Diagram

Create diagrams that argue visually, not just labeled boxes.

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

## Progressive Disclosure Map

- Palette and brand tokens: [references/color-palette.md](references/color-palette.md)
- Pattern catalog: [references/visual-patterns.md](references/visual-patterns.md)
- Excalidraw JSON contract: [references/json-schema.md](references/json-schema.md)
- JSON snippets/templates: [references/element-templates.md](references/element-templates.md)
- Validation rubric: [references/quality-checklist.md](references/quality-checklist.md)
- Mermaid bootstrap workflow: [references/mermaid-bootstrap.md](references/mermaid-bootstrap.md)
- Renderer setup and troubleshooting: [references/renderer-setup.md](references/renderer-setup.md)
- Mermaid conversion script: [scripts/mermaid_to_excalidraw.mjs](scripts/mermaid_to_excalidraw.mjs)
- Mermaid one-command pipeline: [scripts/mermaid_pipeline.sh](scripts/mermaid_pipeline.sh)
- Structure lint script: [scripts/lint_excalidraw.py](scripts/lint_excalidraw.py)
- PNG render script: [scripts/render_excalidraw.py](scripts/render_excalidraw.py)

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

#### Large Diagram Strategy (Comprehensive)

For large diagrams, build section-by-section:

1. Create base file with wrapper keys and section 1.
2. Append one section per edit pass.
3. Keep cross-section bindings updated as each section lands.
4. Reserve whitespace between sections before final balancing.
5. Run lint + render loop after each major section and again at final pass.

Do not attempt one-shot generation for large diagrams.

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

### 7) Deliver

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
