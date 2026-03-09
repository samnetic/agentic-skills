---
name: claude-code-cli
description: >-
  Advanced Claude Code CLI operations for interactive and non-interactive
  workflows, including `-p/--print` automation, model and fallback model
  selection, JSON/stream JSON output handling, system prompt overrides,
  built-in tool restriction, MCP server isolation, and permission-mode control.
  Use when tasks require Claude Code terminal automation, reproducible CLI
  recipes, CI usage, strict tool sandboxing, or "pure LLM style" runs with
  tools disabled. Triggers: claude code cli, claude -p, claude print mode,
  fallback model, claude streaming json, claude system prompt, claude tools,
  claude mcp, claude permissions, claude automation.
---

# Claude Code CLI

Use this skill to operate Claude Code as a controllable CLI runtime, not only as
an interactive coding assistant.

## Workflow

1. Run preflight:
`claude --version`
`claude auth status`
2. Choose mode:
Interactive: `claude`
Non-interactive: `claude -p ...`
3. Set model controls:
`--model`, `--effort`, and optionally `--fallback-model` (print mode only).
4. Set output contract:
`--output-format text|json|stream-json`; add `--json-schema` for strict JSON output.
5. Constrain behavior:
`--system-prompt` or `--append-system-prompt`, `--tools`, `--allowed-tools`/`--disallowed-tools`,
`--permission-mode`.
6. Isolate MCP:
Use `--mcp-config` with `--strict-mcp-config` when deterministic server scope is required.
7. Execute, then return:
Commands used, settings chosen, and resulting output/error.

Load detailed tables and caveats from:
- [references/capabilities.md](references/capabilities.md)
- [references/tested-behavior.md](references/tested-behavior.md)

## Quick Start

```bash
claude -p --model sonnet --output-format json "Summarize ./README.md in 5 bullets."
```

```bash
claude -p \
  --model sonnet \
  --fallback-model opus \
  --output-format stream-json \
  --include-partial-messages \
  "Generate release notes from the latest git commits."
```

## Control Recipes

### Strip prompts or replace defaults

- Replace session-level prompt with your own:
`claude -p --system-prompt "You are a concise JSON assistant." ...`
- Add policy on top of defaults:
`claude -p --append-system-prompt "Never call tools." ...`
- Disable skill slash commands:
`claude --disable-slash-commands ...`

### Restrict tools and run in "pure LLM style"

- Disable built-in tools:
`claude -p --tools "" ...`
- Allow only specific tools:
`claude -p --tools "Read,Edit" ...`
- Apply permission policy:
`claude -p --permission-mode dontAsk ...`

Recommended near-pure text recipe:

```bash
cat >/tmp/empty-mcp.json <<'JSON'
{"mcpServers":{}}
JSON

claude -p \
  --model sonnet \
  --system-prompt "Answer as a pure text LLM. Do not call tools." \
  --tools "" \
  --strict-mcp-config \
  --mcp-config /tmp/empty-mcp.json \
  --output-format json \
  "Explain event sourcing in 4 bullets."
```

### MCP server control

- Add/list/remove servers:
`claude mcp add ...`
`claude mcp list`
`claude mcp remove <name>`
- Scope configuration:
`claude mcp add -s local ...`
`claude mcp add -s project ...`
`claude mcp add -s user ...`
- Session-only isolation:
`--mcp-config ... --strict-mcp-config`

## Output Contract

Return:

1. Exact command(s) executed.
2. Model and fallback model choice.
3. Prompt/tool/MCP restrictions applied.
4. Output mode (`text`, `json`, or `stream-json`).
5. Result status and error summary if any.

## Quality Gates

- Use non-interactive `-p` for automation.
- Set explicit `--output-format` for machine parsing.
- Avoid uncontrolled MCP usage in CI; prefer strict config.
- Use `--tools ""` when the task must be text-only.
- Verify writable runtime directories in restricted sandboxes.

## Safety Rules

- Do not use `--dangerously-skip-permissions` unless explicitly requested.
- Do not enable broad tools/MCP servers by default for untrusted repositories.
- Favor allowlists (`--tools`, `--allowed-tools`) over broad defaults.
