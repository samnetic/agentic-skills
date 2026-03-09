# Codex CLI Capabilities

Last verified: 2026-03-03
CLI version checked locally: `codex-cli 0.106.0`

## Key Commands

- Interactive: `codex [prompt]`
- Non-interactive: `codex exec [prompt]`
- Code review mode: `codex review`
- MCP management: `codex mcp ...`

## Control Surface (High Value Flags)

- Global/runtime:
  - `-m, --model`
  - `-c, --config key=value` (override config.toml keys)
  - `-p, --profile`
  - `-C, --cd`
- Sandbox/approvals:
  - `-s, --sandbox read-only|workspace-write|danger-full-access`
  - Interactive: `-a, --ask-for-approval untrusted|on-request|never`
  - `--full-auto` convenience mode
  - `--dangerously-bypass-approvals-and-sandbox` (unsafe)
- Non-interactive output:
  - `codex exec --json` (JSONL events)
  - `codex exec --output-schema <file>`
  - `codex exec -o <file>` (save final message)
  - `codex exec --ephemeral`
- Local provider:
  - `--oss`
  - `--local-provider lmstudio|ollama`
- Web tool:
  - `--search` enables live web search tool

## Config Reference Highlights

From official docs and CLI references:

- Primary config file: `~/.codex/config.toml`
- Core keys:
  - `model`
  - `model_provider`
  - `model_providers.<id>.base_url`
  - `model_providers.<id>.env_key`
  - `model_providers.<id>.wire_api`
- MCP:
  - `mcp_servers` supports stdio and streamable HTTP server definitions
  - `experimental_use_rmcp_client` exists in current config reference docs

## Fallback Model Note

- Current CLI help does not provide a dedicated fallback-model flag.
- Use shell-level fallback orchestration:

```bash
codex exec -m o3 "$PROMPT" || codex exec -m gpt-5 "$PROMPT"
```

## Tool Restriction Note

- Current CLI help does not expose a first-class per-tool allow/deny flag.
- Restrict behavior via:
  - conservative sandbox (`--sandbox read-only`)
  - approval policy (interactive mode)
  - not enabling optional web search (`--search`)
  - explicit prompt constraints

## Near-Pure LLM Pattern

```bash
codex exec \
  --skip-git-repo-check \
  --sandbox read-only \
  --json \
  "Answer in text only. Do not execute shell commands. Explain two-phase commit."
```

## Sources

- https://developers.openai.com/codex/cli
- https://developers.openai.com/codex/cli/command-line-options
- https://developers.openai.com/codex/cli/config
- https://developers.openai.com/codex/cli/mcp
- https://github.com/openai/codex
