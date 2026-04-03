# Mermaid Bootstrap

Use Mermaid as a fast structure draft, then refine in Excalidraw.

## When To Use

- Flow-heavy diagrams with clear sequence/branching.
- System overviews where topology matters more than polish in first pass.
- Early draft stage where fast iteration is priority.

## When To Skip

- Dense educational diagrams with code/data evidence artifacts.
- Diagrams requiring strong visual metaphors (clouds, layered narratives, custom composition).
- Cases where converted layout quality hurts more than helps.

## Bootstrap Workflow

1. Draft Mermaid focused on structure only.
2. Convert Mermaid to `.excalidraw`.
3. Open generated JSON and refactor:
   - apply semantic color palette
   - improve spacing/hierarchy
   - replace generic box layouts with visual patterns
   - add evidence artifacts for technical content
4. Run lint + render loop.

## Conversion Command

```bash
node scripts/mermaid_to_excalidraw.mjs path/to/diagram.mmd --output path/to/diagram.excalidraw
```

Or run convert + lint + render:

```bash
bash scripts/mermaid_pipeline.sh path/to/diagram.mmd
```

Input formats:
- `.mmd` file
- Markdown file containing fenced Mermaid blocks (` ```mermaid ... ``` `)

## Design Rule

Converted output is never final output. Treat it as scaffold.
