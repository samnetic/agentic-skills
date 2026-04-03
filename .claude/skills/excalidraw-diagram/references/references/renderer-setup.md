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

### Title text appears cropped

Switch from monospace (family=3) to Helvetica (family=2) and reduce font size.
Monospace characters are wider per-character, causing Excalidraw to clip text
that fits fine in Helvetica at the same width.

| Font Family | ID | Character Width | Best For |
|-------------|----|-----------------|-----------------------|
| Virgil | 1 | Medium | Handwritten / sketch |
| Helvetica | 2 | Narrow | Titles, labels, clean |
| Cascadia | 3 | Wide (monospace) | Code snippets only |

## Alternative: Self-Hosted Docker + DragEvent Drop

If the `render_template.html` approach has connectivity issues (it fetches
Excalidraw via `esm.sh`), use a self-hosted Excalidraw container instead:

```bash
# Start Excalidraw container (one-time)
docker run -d --name excalidraw-local -p 3030:80 excalidraw/excalidraw:latest
```

Then inject diagrams via Playwright's DragEvent API:

```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page(viewport={"width": 1920, "height": 1080})
    page.goto("http://localhost:3030", wait_until="networkidle")
    page.wait_for_timeout(3000)

    # Inject via DragEvent drop (proven approach)
    page.evaluate(f"""() => {{
        const data = JSON.stringify({diagram_json});
        const blob = new Blob([data], {{ type: "application/json" }});
        const file = new File([blob], "d.excalidraw", {{ type: "application/json" }});
        const drop = new DragEvent("drop", {{
            bubbles: true, cancelable: true, dataTransfer: new DataTransfer()
        }});
        drop.dataTransfer.items.add(file);
        (document.querySelector(".excalidraw__canvas") || document.body)
            .dispatchEvent(drop);
    }}""")

    page.wait_for_timeout(2000)
    page.keyboard.press("Escape")        # dismiss modals
    page.keyboard.press("Control+Shift+Digit1")  # zoom-to-fit
    page.wait_for_timeout(1000)
    page.screenshot(path="output.png")
    browser.close()
```

This approach works offline and avoids ESM CDN dependencies.
