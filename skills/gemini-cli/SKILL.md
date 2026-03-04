---
name: gemini-cli
description: >-
  Advanced Gemini CLI operations for interactive and headless automation,
  including positional and `-p` prompt execution, `--output-format json|stream-json`,
  model selection, model-routing fallback strategy, system prompt override,
  sandbox and approval controls, tool/MCP restriction, and settings precedence.
  Use when tasks require reproducible Gemini CLI command recipes, CI-safe
  non-interactive runs, strict policy constraints, or near-text-only Gemini
  operation from terminal workflows. Triggers: gemini cli, gemini headless,
  gemini stream-json, gemini model routing, gemini fallback model, gemini mcp,
  gemini settings.json, GEMINI_SYSTEM_MD, gemini sandbox, pure llm gemini.
---

# Gemini CLI

Use this skill to operate Gemini CLI as a controlled runtime for both interactive
and automation-heavy workflows.

## Workflow

1. Run preflight:
`gemini --version`
`gemini --help`
2. Detect version drift:
compare local help output against docs before using docs-only flags.
Preferred:
`./skills/gemini-cli/scripts/detect-gemini-capabilities.sh`
3. Choose execution mode:
interactive (`gemini`) or headless one-shot (`gemini "<prompt>"`).
4. Set response contract:
`--output-format text|json|stream-json`.
5. Set model behavior:
`--model` and, when needed, routing/fallback via settings.
6. Constrain execution:
`--sandbox`, `--approval-mode`, `--allowed-tools`, `--allowed-mcp-server-names`.
7. Configure prompt policy:
`GEMINI_SYSTEM_MD` for system prompt override when required.
8. Manage MCP scope:
`gemini mcp add|list|remove` (or version-specific equivalents).
9. Execute and return:
exact command(s), selected controls, and observed output/errors.

Load details from:
- [references/capabilities.md](references/capabilities.md)
- [references/tested-behavior.md](references/tested-behavior.md)

## Quick Start

```bash
./skills/gemini-cli/scripts/detect-gemini-capabilities.sh
```

```bash
gemini --output-format json \
  "Summarize ./README.md in 6 bullets."
```

```bash
gemini --model gemini-2.5-pro \
  --output-format stream-json \
  "Generate a release-note draft from recent commits."
```

## Control Recipes

### Headless mode and output

- Recommended one-shot prompt style:
`gemini "<prompt>"`
- Deprecated but still accepted in older builds:
`gemini -p "<prompt>"`
- JSON stream for automation:
`gemini --output-format stream-json "<prompt>"`

### Model selection and fallback

- Force model directly:
`gemini --model gemini-2.5-pro "<prompt>"`
- Use routing/fallback policy in settings (docs-driven):
configure model routing and fallback in `settings.json` (for example via
`modelRouter` and `bugCommand.fallbackModel` where supported by your version).

### Prompt override and context shaping

- Override system prompt with environment variable:
`GEMINI_SYSTEM_MD=/abs/path/system.md gemini "<prompt>"`
- Swap context instruction filename:
set `context.fileName` in settings.
- Add extra project context roots:
`--include-directories ../shared-lib`

### Restrict tools and approach pure-LLM behavior

- Approval policy:
`--approval-mode default|auto_edit|yolo`
- Allowlist auto-approved tools:
`--allowed-tools "run_shell_command(git status)"`
- Allowlist MCP servers:
`--allowed-mcp-server-names serverA,serverB`
- For near-text-only operation, combine:
  - strict system instruction via `GEMINI_SYSTEM_MD`
  - empty/minimal tool allowlist in settings (`tools.core`, `tools.exclude`)
  - no MCP servers (or strict MCP allowlist)

### MCP lifecycle

- Add server:
`gemini mcp add <name> <commandOrUrl> [args...]`
- List servers:
`gemini mcp list`
- Remove server:
`gemini mcp remove <name>`
- Newer docs may include `update`, `test`, `import`, `export`, `enable`,
  `disable`; verify availability with local `--help` first.

## Version Drift Guardrail

Gemini CLI docs are ahead of some installed builds.

Always:

1. Run `gemini --help` and `gemini mcp --help`.
2. Feature-detect flags/commands before use.
3. Fall back to settings-based control if a flag is missing.

Scripted check:

```bash
./skills/gemini-cli/scripts/detect-gemini-capabilities.sh \
  --require command.mcp,flag.output_format,mcp.add,mcp.list,mcp.remove
```

Example:
if docs mention `--all-files` but local help rejects it, use config-level
context settings instead.

## Output Contract

Return:

1. Exact command(s) executed.
2. Local CLI version and detected capability set.
3. Model/routing/sandbox/tool/MCP controls applied.
4. Output mode and parse strategy.
5. Success/error result and fallback action.

## Quality Gates

- Prefer headless mode with explicit `--output-format`.
- Keep a version/capability note on every non-trivial run.
- Use temporary home in restricted environments when `~/.gemini` is not
  writable.
- Treat docs-only features as conditional until local help confirms them.

## Safety Rules

- Do not use `--approval-mode yolo` unless explicitly requested.
- Do not trust MCP servers by default (`--trust`) unless user approved.
- Do not assume docs-latest command availability on older local binaries.
