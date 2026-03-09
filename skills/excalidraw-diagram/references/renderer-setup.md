# Renderer Setup

This skill can render `.excalidraw` to PNG for visual self-validation.

## Quick Setup

From the skill root:

```bash
cd scripts
uv sync
uv run playwright install chromium
npm install
```

## Render Command

```bash
uv run python render_excalidraw.py /absolute/or/relative/path/diagram.excalidraw
```

Optional flags:

- `--output path/to/file.png`
- `--scale 2`
- `--max-width 2200`
- `--min-height 640`
- `--padding 96`

## Mermaid Conversion Command

```bash
node mermaid_to_excalidraw.mjs /absolute/or/relative/path/diagram.mmd --output diagram.excalidraw
```

If input is Markdown, the script will read the first fenced Mermaid block.

## One-Command Pipeline

```bash
bash mermaid_pipeline.sh /absolute/or/relative/path/diagram.mmd
```

Pipeline steps:
1. Mermaid -> `.excalidraw`
2. JSON lint
3. PNG render (unless `--no-render`)

Examples:

```bash
# Strict lint and default render
bash mermaid_pipeline.sh ./flow.mmd --strict-lint

# Convert + lint only
bash mermaid_pipeline.sh ./flow.mmd --no-render

# Custom output paths
bash mermaid_pipeline.sh ./flow.mmd -o ./out/flow.excalidraw -p ./out/flow.png
```

## Lint Command

```bash
python lint_excalidraw.py /absolute/or/relative/path/diagram.excalidraw
```

Use `--strict` to fail on warnings.

## Troubleshooting

### `playwright not installed`

Run:

```bash
uv sync
uv run playwright install chromium
```

### `Cannot find package '@excalidraw/mermaid-to-excalidraw'`

Run:

```bash
cd scripts
npm install
```

### Renderer waits then times out

- Confirm outbound network access to `esm.sh` (used in `render_template.html` import).
- Re-run with higher timeout:
  `uv run python render_excalidraw.py file.excalidraw --module-timeout-ms 90000`

### Empty output image

- Ensure `elements` is non-empty.
- Run `python lint_excalidraw.py file.excalidraw --strict`.
- Verify no elements are all marked `"isDeleted": true`.
