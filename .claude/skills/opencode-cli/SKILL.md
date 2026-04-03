---
name: opencode-cli
description: >-
  Advanced OpenCode CLI operations for `opencode run` automation, model and
  variant selection, JSON event streaming, instruction/prompt customization,
  tool and permission restriction, MCP server management, and low-tool
  "pure LLM style" usage. Use when tasks require reproducible OpenCode terminal
  workflows, safe automation, CLI-only model control, or strict runtime policy
  tuning via config and flags. Triggers: opencode cli, opencode run, opencode
  model, opencode variant, opencode json output, opencode tools, opencode
  permissions, opencode mcp, opencode automation.
license: MIT
compatibility: Requires OpenCode CLI (opencode)
metadata:
  author: samnetic
  version: "1.0"
---

# OpenCode CLI

Use this skill to control OpenCode from scripts and terminals with explicit
policies for prompts, tools, permissions, and MCP integration.

## Core Principles

| Principle | Meaning |
|-----------|---------|
| Explicit over implicit | Always pass `--model`, `--format`, and policy flags; never rely on ambient defaults |
| Config-driven reproducibility | Pin model, tools, permissions, and MCP servers in `opencode.json` so every run is identical |
| Least-privilege by default | Start with `"tools": []` and empty `mcp`; add capabilities only when the task demands them |
| Fail-fast with fallback | Detect failure via exit code and cascade to alternative model or strategy immediately |
| JSON for machines, default for humans | Use `--format json` in CI/scripts; use `--format default` in interactive terminals |
| Writable runtime paths | Set `XDG_DATA_HOME` and `XDG_CONFIG_HOME` in containers and CI to avoid read-only DB errors |

## Decision Tree

Use this tree to choose the right OpenCode invocation strategy.

```
Is the task interactive (human in the loop)?
├─ YES → Run `opencode` (TUI mode)
│        Need a custom persona? → Add `--prompt "..."`
│        Need session continuity? → Add `--continue` or `--session <id>`
└─ NO  → Run `opencode run ...` (non-interactive)
         │
         Will output be parsed by a script or CI?
         ├─ YES → Add `--format json`
         │        Need reasoning trace? → Add `--thinking`
         │        Need strict schema? → Post-process JSON events with jq
         └─ NO  → Use `--format default`
         │
         Does the task need tool access (file edits, shell, MCP)?
         ├─ YES → Define `tools` allowlist and `permission` policy in config
         │        Need MCP servers? → Add `mcp` map to config or use `opencode mcp add`
         └─ NO  → Set `"tools": []` and `"mcp": {}` for pure-LLM mode
         │
         Is model reliability critical?
         ├─ YES → Script fallback: `opencode run -m primary ... || opencode run -m backup ...`
         └─ NO  → Single `--model provider/model` is sufficient
```

## Workflow

1. Run preflight:
`opencode --version`
2. Choose mode:
Interactive TUI: `opencode`
Non-interactive: `opencode run ...`
3. Set model behavior:
`-m provider/model` and optional `--variant` (provider-specific effort/reasoning tier).
4. Choose output mode:
`opencode run --format default|json`
5. Apply prompt/policy controls:
`--prompt`, config `instructions`, config `tools`, config `permission`.
6. Manage MCP:
`opencode mcp add|list|auth|logout|debug`, plus config-level `mcp` definitions.
7. Execute and return command + structured result.

## Progressive Disclosure Map

| Reference | Contents | When to read |
|-----------|----------|--------------|
| [references/capabilities.md](references/capabilities.md) | Full flag reference, config schema, model tiers, near-pure LLM pattern | When you need exact flag names, config keys, or model family syntax |
| [references/tested-behavior.md](references/tested-behavior.md) | Real command outputs, environment caveats, XDG workaround | When debugging runtime errors, read-only DB issues, or sandbox failures |

## Quick Start

```bash
opencode run --model anthropic/claude-sonnet-4-5 "Summarize CHANGELOG.md in 5 bullets."
```

```bash
opencode run \
  --format json \
  --model openai/gpt-5 \
  --variant high \
  --thinking \
  "Create a migration checklist for this repo."
```

## Control Recipes

### Prompt customization and instruction layering

- One-off prompt layer:
`opencode --prompt "You are a terse JSON assistant." run ...`
- Persistent instruction files via config:
Set `instructions` to markdown files in config JSON.

### Restrict tools and permissions

- Configure allowed built-in tools with config `tools`.
- Define granular allow/ask/deny policy with config `permission`.
- Use narrow allowlists for sensitive repos.

Minimal text-focused config example:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "openai/gpt-5",
  "tools": [],
  "mcp": {},
  "instructions": ["./instructions/minimal.md"]
}
```

Run with:
`opencode run --format json "Explain CQRS in 5 bullets."`

### Model fallback behavior

OpenCode currently has no dedicated `--fallback-model` flag.
Use wrapper logic when strict fallback is required:

```bash
opencode run --model anthropic/claude-sonnet-4-5 "$PROMPT" \
  || opencode run --model openai/gpt-5 "$PROMPT"
```

### MCP control

- Manage servers from CLI:
`opencode mcp add`
`opencode mcp list`
`opencode mcp auth <name>`
`opencode mcp logout <name>`
`opencode mcp debug <name>`
- Keep server definitions in config `mcp` for reproducible setups.

## Anti-Patterns

| Anti-Pattern | Why It's Dangerous | Fix |
|--------------|--------------------|-----|
| Running without `--model` flag | Relies on ambient default which may change between machines or config files | Always pass `-m provider/model` explicitly |
| Using `--format default` in CI pipelines | Human-readable output breaks parsers and gives no structured error codes | Use `--format json` and parse events with `jq` |
| Wildcard `permission` allow rules in shared repos | Grants tool access to any action, risking unintended file writes or shell execution | Define narrow allow rules per tool; use `deny` for destructive operations |
| Skipping `XDG_*` env vars in containers | Default runtime paths are often read-only, causing `readonly database` crashes | Export `XDG_DATA_HOME` and `XDG_CONFIG_HOME` to writable directories |
| Trusting unknown MCP servers with `auth` | Authentication tokens may leak to malicious servers | Vet MCP server source; use `opencode mcp debug <name>` before authenticating |
| Hardcoding model IDs without fallback | Provider outage or model deprecation breaks the entire pipeline | Script `||` fallback to a secondary model |
| Leaving `tools` unconstrained for text-only tasks | Model may invoke file-edit or shell tools when only text generation is needed | Set `"tools": []` in config for pure-LLM usage |
| Passing secrets via `--prompt` flag | Prompt text may appear in shell history, process lists, and logs | Use instruction files via config `instructions` for sensitive content |

## Output Contract

Return:

1. Command(s) and config file(s) used.
2. Model + variant used.
3. Tool/permission/MCP constraints applied.
4. Output mode and parse strategy.
5. Success/error result and fallback action.

## Quality Gates

- Use `--format json` for automation and CI parsing.
- Explicitly set `-m` and optionally `--variant`.
- Keep `tools` and `permission` explicit for safety-sensitive tasks.
- Handle read-only environment issues for runtime state (see tested behavior).

## Checklist

Before executing an OpenCode CLI workflow, verify every applicable item:

### Setup
- [ ] `opencode --version` confirms expected CLI version
- [ ] `opencode.json` or `.opencode.json` exists in project root with pinned config
- [ ] `XDG_DATA_HOME` and `XDG_CONFIG_HOME` point to writable paths (CI/containers)

### Model and Output
- [ ] `-m provider/model` is set explicitly in command or config
- [ ] `--variant` is set when provider supports effort/reasoning tiers
- [ ] `--format json` is used for any machine-consumed output
- [ ] `--thinking` is added when reasoning trace is needed for debugging

### Security and Policy
- [ ] `tools` allowlist in config is scoped to required tools only
- [ ] `permission` rules use deny-by-default with narrow allow entries
- [ ] MCP servers are vetted; `opencode mcp debug <name>` passes before `auth`
- [ ] No secrets appear in `--prompt` text; use `instructions` files instead

### Automation and CI
- [ ] Fallback model chain is scripted with `||` for critical pipelines
- [ ] JSON output is validated or parsed with `jq` before downstream consumption
- [ ] Exit codes are checked; non-zero triggers fallback or alerting
- [ ] Config file is committed to repo for reproducibility across environments

## Safety Rules

- Do not allow destructive tool actions without explicit user intent.
- Avoid permissive wildcard policies in shared repositories.
- Validate MCP server trust before enabling authentication flows.
