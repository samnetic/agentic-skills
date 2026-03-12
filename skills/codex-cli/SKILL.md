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
policy and output contracts. Every invocation should declare its model, sandbox
level, and output format so results are reproducible and auditable.

---

## Core Principles

| Principle | Meaning |
|---|---|
| **Explicit over implicit** | Always pass `--sandbox`, `--json`, and `-m` rather than relying on defaults or ambient config |
| **Least privilege execution** | Start with `read-only` sandbox; escalate only when the task provably requires writes |
| **Reproducible commands** | Every recipe must be copy-pasteable and produce the same behavior tomorrow |
| **Structured output first** | Prefer `--json` JSONL streams for automation; plain text only for human consumption |
| **Config as code** | Use `config.toml`, profiles (`-p`), and `-c` overrides instead of environment hacks |
| **Treat MCP as untrusted** | MCP servers are third-party code; audit before enabling, scope to minimum capability |
| **Fail fast, fallback explicitly** | No silent retries; use shell-level `||` fallback orchestration |

---

## Workflow

1. **Run preflight** — verify installation and version:
   `codex --version`
2. **Choose mode** — interactive (`codex`) or non-interactive (`codex exec ...`).
3. **Set model and provider** — `-m`, optionally `--oss` / `--local-provider`, or config overrides with `-c`.
4. **Set execution constraints** — `--sandbox`, approval mode (interactive only), and writable dirs (`--add-dir`).
5. **Set output contract** — `codex exec --json`, optional `--output-schema`, optional `-o` file output.
6. **Configure MCP when needed** — `codex mcp add|list|get|remove|login|logout`.
7. **Execute and return** exact command + result stream summary.

---

## Quick Start

```bash
# Minimal automation-safe invocation
codex exec --skip-git-repo-check \
  --sandbox read-only \
  --json \
  "Summarize this repository structure in 8 bullets."
```

```bash
# Save structured output to file with explicit model
codex exec -m o3 \
  --sandbox read-only \
  --json \
  -o /tmp/summary.txt \
  "List all exported functions in src/index.ts."
```

```bash
# Enforce a JSON response schema
codex exec -m o3 \
  --sandbox read-only \
  --json \
  --output-schema ./response-schema.json \
  "Return the top 5 performance issues as structured JSON."
```

---

## Control Recipes

### Model and provider selection

```bash
# Direct model
codex exec -m o3 "Explain event sourcing."

# Local OSS provider
codex exec --oss --local-provider ollama "Summarize this file."

# Config override (useful in CI)
codex exec -c model="o3" -c model_provider="openai" "Run analysis."

# Named profile
codex exec -p fast-draft "Draft a README for this project."
```

### Sandbox, approvals, and tool restrictions

| Sandbox Level | Allowed Operations | Use When |
|---|---|---|
| `read-only` | Read files, no writes, no network | Q&A, analysis, code review |
| `workspace-write` | Read + write within project dir | Code generation, refactoring |
| `danger-full-access` | Unrestricted filesystem and network | Deployment scripts, system tasks |

```bash
# Interactive approval policy (not available in `codex exec`)
codex -a untrusted       # ask before every tool call
codex -a on-request      # ask only for risky operations
codex -a never           # auto-approve everything (use with caution)

# Sandbox for non-interactive
codex exec --sandbox read-only --json "Explain CRDTs in 5 bullets."
codex exec --sandbox workspace-write --json "Refactor utils.ts to use ESM."
```

- There is no first-class per-tool allow/deny list in the current CLI.
  Constrain behavior with sandbox + approvals + prompt instructions.

**Near-pure LLM recipe** (no tool execution):

```bash
codex exec \
  --skip-git-repo-check \
  --sandbox read-only \
  --json \
  "Answer as text only. Do not run shell commands. Explain CRDTs in 5 bullets."
```

### Streaming and structured output

```bash
# JSONL event stream to stdout
codex exec --json "Analyze this codebase."

# Save final response to file
codex exec -o /tmp/final.txt "Summarize the architecture."

# Enforce response schema
codex exec --output-schema ./schema.json --json "Return findings as JSON."

# Ephemeral session (no conversation history persisted)
codex exec --ephemeral --json "One-shot question."
```

**JSONL event types** emitted by `--json`:

| Event | Meaning |
|---|---|
| `thread.started` | Session initialized |
| `turn.started` | Model turn begins |
| `message.delta` | Incremental text chunk |
| `tool_call` | Tool invocation request |
| `tool_result` | Tool execution result |
| `error` | Recoverable error (may retry) |
| `turn.completed` | Model turn finished |

### Model fallback behavior

Current CLI has no dedicated fallback model flag.
Use shell fallback orchestration:

```bash
codex exec -m o3 --json "$PROMPT" \
  || codex exec -m gpt-5 --json "$PROMPT"
```

For CI pipelines, wrap with timeout:

```bash
timeout 120s codex exec -m o3 --json "$PROMPT" \
  || timeout 120s codex exec -m gpt-5 --json "$PROMPT" \
  || echo "All models failed" >&2 && exit 1
```

### MCP control

```bash
# Add HTTP server
codex mcp add sentry --url https://mcp.sentry.dev/mcp

# Add stdio server
codex mcp add myserver -- npx -y my-mcp-server

# List, inspect, remove
codex mcp list
codex mcp get myserver
codex mcp remove myserver

# Auth flows
codex mcp login myserver
codex mcp logout myserver
```

### Configuration management

```bash
# Primary config location
# ~/.codex/config.toml

# Override any config key at runtime
codex exec -c model="o3" -c model_provider="openai" "..."

# Use a named profile
codex exec -p my-profile "..."

# Change working directory
codex exec -C /path/to/project "Analyze this project."
```

**Key `config.toml` settings:**

```toml
model = "o3"
model_provider = "openai"

[model_providers.local]
base_url = "http://localhost:11434/v1"
env_key = "OLLAMA_API_KEY"
wire_api = "openai"
```

---

## Output Contract

Every response using this skill MUST return:

1. **Command(s) executed** — exact copy-pasteable invocation.
2. **Model/provider/sandbox settings** — what was configured and why.
3. **MCP and web-search settings** — which servers were active, whether `--search` was enabled.
4. **Output mode** — `json` or plain, and how to parse the result.
5. **Success/error result** — outcome summary and fallback action if failed.

---

## Anti-Patterns

| Anti-Pattern | Why It's Dangerous | Fix |
|---|---|---|
| Omitting `--sandbox` | Defaults may allow writes or network access you did not intend | Always pass `--sandbox` explicitly |
| Using `--dangerously-bypass-approvals-and-sandbox` | Disables all safety rails; full filesystem and network access | Use the minimum sandbox level needed; never bypass in CI |
| Relying on ambient `config.toml` in CI | Config differs across machines; builds become non-reproducible | Pass `-c` overrides or `-p` profile explicitly |
| Piping secrets into prompt strings | Secrets leak into shell history, logs, and JSONL output | Use environment variables or file-based injection |
| Skipping `--json` in automation | Plain text output is unparseable and breaks downstream tooling | Always use `--json` for scripted/CI invocations |
| Adding MCP servers without review | MCP servers execute arbitrary code on your machine | Audit server source, use `read-only` sandbox, restrict scope |
| Ignoring `error` events in JSONL stream | Silent failures lead to incomplete or corrupt output | Parse JSONL, check for `error` events, implement retry logic |
| Using `--full-auto` without sandbox | Combines auto-approval with unscoped permissions | If using `--full-auto`, always pair with `--sandbox read-only` or `workspace-write` |
| Hardcoding model names without fallback | Model deprecation or outage breaks entire pipeline | Use shell-level `||` fallback chain |

---

## Quality Gates

- Prefer `codex exec --json` for all automation and CI usage.
- Set explicit `--sandbox` policy on every run — never rely on defaults.
- Keep approvals conservative unless the user explicitly asks otherwise.
- Use profile/config overrides (`-p`, `-c`) instead of ad hoc hidden state.
- Validate JSONL output by checking for `error` events before processing results.
- Always include `--skip-git-repo-check` when running outside a git repository.
- Use `timeout` wrapper in CI to prevent hung sessions from blocking pipelines.

---

## Safety Rules

- Never use `--dangerously-bypass-approvals-and-sandbox` unless the user explicitly requires it and understands the risk.
- Do not enable `--search` unless live web search is actually required for the task.
- Treat MCP servers as untrusted until explicitly audited and approved.
- Never embed API keys, tokens, or passwords directly in prompt strings.
- In CI environments, pin the Codex CLI version to avoid breaking changes.
- Audit `config.toml` and MCP server definitions before sharing across teams.

---

## Checklist

Before delivering any Codex CLI recipe, verify:

- [ ] `codex --version` confirms expected CLI version is installed
- [ ] `--sandbox` is explicitly set to the minimum required level
- [ ] `-m` or `-c model=` specifies the intended model
- [ ] `--json` is enabled for any automated or scripted invocation
- [ ] `--skip-git-repo-check` is included when running outside a git repo
- [ ] `--output-schema` is provided when structured JSON response is required
- [ ] No secrets or credentials appear in the prompt string
- [ ] MCP servers have been audited before first use (`codex mcp list` to verify)
- [ ] Shell-level fallback (`||`) is configured for model unavailability
- [ ] `timeout` wrapper is used in CI to prevent indefinite hangs
- [ ] JSONL output is validated for `error` events before downstream processing
- [ ] Config overrides (`-c`, `-p`) are used instead of relying on ambient config

---

## Progressive Disclosure Map

| Reference | Contents | When to Read |
|---|---|---|
| [references/capabilities.md](references/capabilities.md) | Full flag reference, config.toml keys, MCP config schema, provider setup | When you need the exact flag name, config key, or provider wiring details |
| [references/tested-behavior.md](references/tested-behavior.md) | Real execution logs, observed JSONL events, environment caveats, sandbox behavior | When debugging unexpected output, verifying event stream format, or troubleshooting sandbox issues |
