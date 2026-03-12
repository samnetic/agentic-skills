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
license: MIT
compatibility: Requires Claude Code CLI (claude)
metadata:
  author: samnetic
  version: "1.0"
---

# Claude Code CLI

Use this skill to operate Claude Code as a controllable CLI runtime, not only as
an interactive coding assistant. Every invocation should be reproducible,
auditable, and safe by default.

---

## Core Principles

| Principle | Meaning |
|---|---|
| **Explicit over implicit** | Always pass `--output-format`, `--model`, and tool flags. Never rely on ambient defaults for automation |
| **Least privilege** | Start with `--tools ""` and add only what the task needs. Prefer allowlists over denylists |
| **Reproducibility** | Pin model, system prompt, MCP config, and permission mode so reruns produce consistent results |
| **Fail fast** | Run preflight checks (`--version`, `auth status`, writable dirs) before long pipelines |
| **Machine-readable output** | Use `json` or `stream-json` output format for any downstream parsing; never scrape `text` mode |
| **Isolation in CI** | Use `--strict-mcp-config` with a minimal config file; do not inherit the developer's local servers |

---

## Workflow

Follow these steps for every Claude Code CLI task:

1. **Run preflight** — `claude --version` and `claude auth status`. Confirm the runtime directory is writable.
2. **Choose mode** — Interactive (`claude`) for exploratory work; non-interactive (`claude -p ...`) for automation and CI.
3. **Set model controls** — `--model`, `--effort`, and optionally `--fallback-model` (print mode only).
4. **Set output contract** — `--output-format text|json|stream-json`; add `--json-schema` for strict JSON output.
5. **Constrain behavior** — `--system-prompt` or `--append-system-prompt`, `--tools`, `--allowed-tools`/`--disallowed-tools`, `--permission-mode`.
6. **Isolate MCP** — Use `--mcp-config` with `--strict-mcp-config` when deterministic server scope is required.
7. **Execute, then return** — Commands used, settings chosen, and resulting output/error.

---

## Decision Tree: Choosing the Right CLI Approach

```
Is this a one-shot question or command?
├─ YES → Use `claude -p "prompt"`
│   ├─ Need structured output? → Add `--output-format json`
│   ├─ Need strict schema? → Add `--json-schema <schema>`
│   ├─ Need streaming? → Add `--output-format stream-json --include-partial-messages`
│   ├─ Need tool access? → Add `--tools "Read,Edit,Bash"` (only what's needed)
│   └─ Need text-only LLM? → Add `--tools "" --system-prompt "Do not call tools."`
│
├─ NO → Is it an interactive coding session?
│   ├─ YES → Use `claude` (interactive mode)
│   │   ├─ Need custom MCP servers? → `claude mcp add -s project <name> ...`
│   │   └─ Need restricted permissions? → `--permission-mode plan`
│   │
│   └─ NO → Is it CI / pipeline automation?
│       └─ YES → Use `claude -p` with full lockdown:
│           ├─ `--strict-mcp-config --mcp-config <minimal.json>`
│           ├─ `--permission-mode dontAsk`
│           ├─ `--model <pinned-model>`
│           └─ `--output-format json`
```

---

## Quick Start

```bash
# Simple JSON summary
claude -p --model sonnet --output-format json "Summarize ./README.md in 5 bullets."
```

```bash
# Streaming with fallback model
claude -p \
  --model sonnet \
  --fallback-model opus \
  --output-format stream-json \
  --include-partial-messages \
  "Generate release notes from the latest git commits."
```

```bash
# CI preflight script
claude --version && claude auth status && echo "CLI ready"
```

---

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

### JSON schema enforcement

```bash
claude -p \
  --model sonnet \
  --output-format json \
  --json-schema '{"type":"object","properties":{"summary":{"type":"string"},"score":{"type":"number"}},"required":["summary","score"]}' \
  "Rate the code quality of ./src/index.ts"
```

---

## Anti-Patterns

| Anti-Pattern | Why It's Dangerous | Fix |
|---|---|---|
| **Omitting `--output-format`** | Default text output is unparseable by downstream tools; format may change between versions | Always pass `--output-format json` or `stream-json` for automation |
| **Using `--dangerously-skip-permissions` in CI** | Grants unrestricted file/network access; a prompt injection can exfiltrate secrets | Use `--permission-mode dontAsk` with `--allowed-tools` allowlist instead |
| **Inheriting local MCP servers in pipelines** | Developer's local servers add non-determinism and may leak credentials | Pass `--strict-mcp-config --mcp-config <minimal.json>` |
| **Broad `--tools` without review** | Every enabled tool is an attack surface for prompt injection | Start with `--tools ""`, then add only the tools the task requires |
| **Scraping `text` output with regex** | Fragile; breaks on model phrasing changes | Use `json` output with `--json-schema` for guaranteed structure |
| **Hardcoding model names** | Model aliases change; full IDs get deprecated | Use stable aliases (`sonnet`, `opus`) and pin via `--model` |
| **Skipping preflight in CI** | Silent failures when auth expires or CLI is missing | Run `claude --version && claude auth status` before any `-p` call |
| **Using `--fallback-model` in interactive mode** | Flag is print-mode only; silently ignored in interactive sessions | Only use `--fallback-model` with `-p` |

---

## Output Contract

Return:

1. Exact command(s) executed.
2. Model and fallback model choice.
3. Prompt/tool/MCP restrictions applied.
4. Output mode (`text`, `json`, or `stream-json`).
5. Result status and error summary if any.

---

## Quality Gates

- Use non-interactive `-p` for automation.
- Set explicit `--output-format` for machine parsing.
- Avoid uncontrolled MCP usage in CI; prefer strict config.
- Use `--tools ""` when the task must be text-only.
- Verify writable runtime directories in restricted sandboxes.

---

## Safety Rules

- Do not use `--dangerously-skip-permissions` unless explicitly requested.
- Do not enable broad tools/MCP servers by default for untrusted repositories.
- Favor allowlists (`--tools`, `--allowed-tools`) over broad defaults.
- In CI, always combine `--strict-mcp-config` with a committed config file.
- Never embed secrets in `--system-prompt`; use environment variables or vault references.

---

## Checklist

Before shipping any Claude Code CLI automation, verify:

- [ ] `claude --version` returns expected CLI version
- [ ] `claude auth status` confirms valid authentication
- [ ] `--model` is explicitly set (not relying on default)
- [ ] `--output-format` is set to `json` or `stream-json` for machine consumption
- [ ] `--tools` allowlist is minimal and reviewed
- [ ] `--permission-mode` is set (not relying on default)
- [ ] MCP config is explicit (`--mcp-config` + `--strict-mcp-config`) for CI
- [ ] `--system-prompt` or `--append-system-prompt` does not contain secrets
- [ ] `--json-schema` is provided when downstream expects a strict contract
- [ ] Runtime directory is writable in the target environment
- [ ] `--fallback-model` is only used with `-p` (print mode)
- [ ] Pipeline handles non-zero exit codes and stderr
- [ ] Command is version-controlled and reproducible (no ambient config dependency)

---

## Progressive Disclosure Map

| Reference | Content | When to read |
|---|---|---|
| [references/capabilities.md](references/capabilities.md) | Full flag inventory, MCP transport options, near-pure LLM pattern details | When you need the exact flag name, allowed values, or MCP `add` sub-options |
| [references/tested-behavior.md](references/tested-behavior.md) | Real test transcripts, observed errors, sandbox caveats | When debugging CI failures, permission errors, or validating environment assumptions |
