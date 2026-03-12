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
license: MIT
compatibility: Requires Gemini CLI (gemini)
metadata:
  author: samnetic
  version: "1.0"
---

# Gemini CLI

Use this skill to operate Gemini CLI as a controlled runtime for both interactive
and automation-heavy workflows.

---

## Core Principles

| Principle | Meaning |
|---|---|
| **Feature-detect before use** | Always run `gemini --help` and compare against docs; never assume a flag exists |
| **Headless by default** | Prefer one-shot `gemini "<prompt>"` with explicit `--output-format` for reproducibility |
| **Settings over flags** | When a CLI flag is missing locally, fall back to `settings.json` equivalents |
| **Least-privilege execution** | Default to `--sandbox` and restrictive `--approval-mode`; escalate only when asked |
| **Version-pinned recipes** | Record CLI version + detected capabilities alongside every non-trivial command |
| **Explicit output contracts** | Always specify `--output-format text|json|stream-json`; never rely on implicit defaults |

---

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

### Progressive Disclosure Map

| Reference | When to read |
|---|---|
| [references/capabilities.md](references/capabilities.md) | Before using any docs-only flag; when comparing local vs latest feature surface |
| [references/tested-behavior.md](references/tested-behavior.md) | When debugging unexpected errors, permission issues, or CI sandbox failures |

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

---

## Anti-Patterns

| Anti-Pattern | Why It's Dangerous | Fix |
|---|---|---|
| **Using docs-only flags without detection** | Command fails silently or errors on older CLI versions | Run `gemini --help` or the capability detector script first |
| **Omitting `--output-format`** | Output format is unpredictable across versions; breaks automation parsing | Always pass `--output-format text\|json\|stream-json` explicitly |
| **`--approval-mode yolo` by default** | Grants unrestricted tool execution; may modify filesystem or run arbitrary commands | Default to `default`; only escalate to `yolo` when the user explicitly requests it |
| **Passing `--trust` to MCP add** | Auto-approves all tool calls from an external server without user review | Omit `--trust`; use `--include-tools` / `--exclude-tools` to scope access |
| **Combining `--prompt` with positional args** | Parser rejects the combination; command fails immediately | Use positional prompt only (`gemini "<prompt>"`); drop deprecated `-p` |
| **Hardcoding model names without fallback** | Model unavailable or quota-exhausted returns an error with no recovery | Configure `fallbackModel` in settings or implement retry with alternate model |
| **Running headless without writable `~/.gemini`** | `EACCES` on chat directory creation kills the run | Set `HOME=/tmp` or `GEMINI_CLI_HOME` to a writable path in CI/sandbox |
| **Ignoring version drift** | Recipes break when copied between machines with different CLI versions | Pin CLI version in CI; always record version in output contract |

---

## Checklist

### Pre-Execution

- [ ] Run `gemini --version` to confirm CLI is installed and record version
- [ ] Run `gemini --help` to detect locally available flags and commands
- [ ] Run capability detector script if using non-trivial flags
- [ ] Confirm `~/.gemini` (or `GEMINI_CLI_HOME`) is writable; set `HOME` override for CI if needed
- [ ] Verify network/auth reachability for Gemini API endpoints

### Command Construction

- [ ] Use positional prompt style (`gemini "<prompt>"`) — not deprecated `-p`
- [ ] Specify `--output-format` explicitly (`text`, `json`, or `stream-json`)
- [ ] Set `--model` or configure model routing in settings
- [ ] Apply `--sandbox` for untrusted workloads
- [ ] Set `--approval-mode default` unless escalation is justified
- [ ] Scope tools with `--allowed-tools` and MCP servers with `--allowed-mcp-server-names`

### MCP Integration

- [ ] Add MCP servers with `gemini mcp add` and verify with `gemini mcp list`
- [ ] Use `--include-tools` / `--exclude-tools` to restrict server capabilities
- [ ] Do not pass `--trust` unless user explicitly approves
- [ ] Verify `update`/`test`/`import`/`export` subcommands exist locally before using

### Post-Execution

- [ ] Record exact command(s) executed in output
- [ ] Include CLI version and detected capability set
- [ ] Document model, routing, sandbox, and tool controls applied
- [ ] Note output format and parse strategy used
- [ ] Report success/error result and any fallback actions taken
