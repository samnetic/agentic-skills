# Gemini CLI Capabilities

Last verified: 2026-03-04
Local CLI version checked: `gemini 0.18.4`

## Documented Latest (geminicli.com)

The current docs indicate support for:

- Headless/non-interactive execution with:
  - positional prompt
  - `-p, --prompt` (deprecated)
  - `-i, --prompt-interactive`
  - `--output-format text|json|stream-json`
- Model control:
  - `--model`
  - model routing and fallback policies (`turn`, `background`, `think`,
    `longContext`, and fallback patterns)
- Prompt override:
  - `GEMINI_SYSTEM_MD` environment variable for system prompt replacement
- Settings and precedence guidance:
  - user/workspace/system settings
  - command-line arguments
  - environment variables
  - documented env vars include `GEMINI_API_KEY`, `GOOGLE_API_KEY`,
    `GEMINI_MODEL`, `GEMINI_CLI_HOME`, `GEMINI_SANDBOX`,
    `GOOGLE_CLOUD_PROJECT`
- Extended CLI/reference surface (docs may vary by version):
  - additional flags such as `--all-files`, `--show-memory-usage`,
    `--checkpointing`, `--telemetry`
  - command families such as `cache`, `memory`, `tools`, `auth`, `doctor`,
    `bugreport`
  - extended MCP management (`update`, `test`, `import`, `export`,
    `enable`, `disable`)

## Observed Local (0.18.4) Behavior

### Top-level commands

- Present:
  - `gemini [query..]`
  - `gemini mcp`
  - `gemini extensions`
- Version:
  - `0.18.4`

### Local top-level flags (verified via `gemini --help`)

- `-m, --model`
- `-p, --prompt` (deprecated)
- `-i, --prompt-interactive`
- `-s, --sandbox`
- `-y, --yolo`
- `--approval-mode default|auto_edit|yolo`
- `--allowed-mcp-server-names`
- `--allowed-tools`
- `--include-directories`
- `--resume`, `--list-sessions`, `--delete-session`
- `--output-format text|json|stream-json`

### Local MCP surface (verified via `gemini mcp --help`)

- Present:
  - `gemini mcp add`
  - `gemini mcp list`
  - `gemini mcp remove`
- Not present in this local build:
  - `update`, `test`, `import`, `export`, `enable`, `disable`

### Local settings schema highlights (installed package)

- Tool restrictions:
  - `tools.core` (allowlist of built-in tools)
  - `tools.exclude` (tool exclusions)
  - `tools.allowed` (skip-confirmation allowlist)
- MCP controls:
  - `mcpServers` (top-level server map)
  - `mcp.allowed`, `mcp.excluded`
- Context/prompt controls:
  - `context.fileName`
  - `context.includeDirectories`
- Model controls:
  - `model.name`

## Compatibility Strategy

1. Detect local features first:
`gemini --help`
`gemini mcp --help`
2. Treat docs-latest flags as conditional until local confirmation.
3. Prefer settings-based controls when a desired CLI flag is unavailable.
4. For restricted environments, validate writable runtime paths (`~/.gemini`
or alternate `HOME`) before headless runs.

Recommended detector command:

```bash
./skills/gemini-cli/scripts/detect-gemini-capabilities.sh \
  --require command.mcp,flag.output_format,mcp.add,mcp.list,mcp.remove
```

## Sources

- https://geminicli.com/docs/cli/cli-reference
- https://geminicli.com/docs/cli/headless
- https://geminicli.com/docs/cli/model-selection
- https://geminicli.com/docs/cli/model-routing
- https://geminicli.com/docs/cli/sandbox
- https://geminicli.com/docs/tools/mcp-server
- https://geminicli.com/docs/configuration/system-prompt-override
- https://geminicli.com/docs/reference/configuration
- https://geminicli.com/docs/reference/commands
- Local installed package:
  - `/usr/lib/node_modules/@google/gemini-cli/dist/src/config/config.js`
  - `/usr/lib/node_modules/@google/gemini-cli/dist/src/config/settingsSchema.js`
  - `/usr/lib/node_modules/@google/gemini-cli/dist/src/commands/mcp.js`
