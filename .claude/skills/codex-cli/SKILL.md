---
name: codex-cli
description: >-
  Advanced Codex CLI operations for interactive and non-interactive execution,
  including `codex exec` JSONL streaming, model and provider selection, sandbox
  and approval policy control, MCP server management, structured output schema,
  and CLI-only automation profiles. Use when tasks require reproducible Codex
  command recipes, strict execution controls, MCP integration, or near-text-only
  operation with constrained tool execution. Triggers: codex cli, codex exec,
  codex model, codex sandbox, codex approvals, codex json output, codex mcp,
  codex config toml, codex automation.
---

# Codex CLI

Use this skill to run Codex as an automation-friendly CLI with explicit runtime
policy and output contracts.

## Workflow

1. Run preflight:
`codex --version`
2. Choose mode:
Interactive: `codex`
Non-interactive: `codex exec ...`
3. Set model and provider:
`-m`, optionally `--oss` / `--local-provider`, or config overrides with `-c`.
4. Set execution constraints:
`--sandbox`, approval mode (interactive), and writable dirs (`--add-dir`).
5. Set output contract:
`codex exec --json`, optional `--output-schema`, optional `-o` file output.
6. Configure MCP when needed:
`codex mcp add|list|get|remove|login|logout`.
7. Execute and return exact command + result stream summary.

Load details from:
- [references/capabilities.md](references/capabilities.md)
- [references/tested-behavior.md](references/tested-behavior.md)

## Quick Start

```bash
codex exec --skip-git-repo-check \
  --sandbox read-only \
  --json \
  "Summarize this repository structure in 8 bullets."
```

## Control Recipes

### Model and provider selection

- Direct model:
`codex exec -m o3 ...`
- Local OSS provider:
`codex exec --oss --local-provider ollama ...`
- Config override:
`codex exec -c model=\"o3\" -c model_provider=\"openai\" ...`

### Sandbox, approvals, and tool restrictions

- Interactive approval policy:
`codex -a untrusted|on-request|never`
- Execution sandbox:
`--sandbox read-only|workspace-write|danger-full-access`
- There is no first-class per-tool allow/deny list in current CLI help output.
  Constrain behavior with sandbox + approvals + prompt instructions.

Closest "pure LLM style" recipe:

```bash
codex exec \
  --skip-git-repo-check \
  --sandbox read-only \
  --json \
  "Answer as text only. Do not run shell commands. Explain CRDTs in 5 bullets."
```

### Streaming and structured output

- JSONL event stream:
`codex exec --json ...`
- Save final response:
`codex exec -o /tmp/final.txt ...`
- Enforce response schema:
`codex exec --output-schema ./schema.json ...`

### Model fallback behavior

Current CLI has no dedicated fallback model flag.
Use shell fallback orchestration:

```bash
codex exec -m o3 "$PROMPT" || codex exec -m gpt-5 "$PROMPT"
```

### MCP control

- Add HTTP server:
`codex mcp add sentry --url https://mcp.sentry.dev/mcp`
- Add stdio server:
`codex mcp add myserver -- npx -y my-mcp-server`
- Inspect and remove:
`codex mcp list`
`codex mcp get myserver`
`codex mcp remove myserver`

## Output Contract

Return:

1. Command(s) executed.
2. Model/provider/sandbox settings.
3. MCP and web-search settings.
4. Output mode (`json` or plain) and parse approach.
5. Success/error result and fallback action.

## Quality Gates

- Prefer `codex exec --json` for automation.
- Set explicit sandbox policy on every run.
- Keep approvals conservative unless the user explicitly asks otherwise.
- Use profile/config overrides (`-p`, `-c`) instead of ad hoc hidden state.

## Safety Rules

- Never use `--dangerously-bypass-approvals-and-sandbox` unless explicitly required.
- Do not enable `--search` unless live web search is actually required.
- Treat MCP servers as untrusted until explicitly approved.
