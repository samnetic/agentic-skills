# OpenCode CLI Capabilities

Last verified: 2026-03-03
CLI version checked locally: `1.2.10`

## Key Commands

- Interactive UI: `opencode`
- Non-interactive execution: `opencode run [message...]`
- MCP management: `opencode mcp ...`
- Model listing: `opencode models [provider]`

## Control Surface (High Value Flags)

- Runtime and output:
  - `opencode run --format default|json`
  - `--thinking` (show thinking blocks)
  - Global logging flags: `--print-logs`, `--log-level`
- Model control:
  - `-m, --model provider/model`
  - `--variant <provider-specific-effort>`
- Session control:
  - `--continue`, `--session`, `--fork`
  - `--agent`
  - `--prompt`
- File/context:
  - `-f, --file`
  - `--dir`
  - `--attach` (attach to running server)

## Config-Level Controls

From official docs (`opencode.json` / `.opencode.json`):

- Model defaults and family tiers:
  - `model`
  - `model.small`, `model.medium`, `model.large`
  - `model.<provider>.reasoning` and effort variants
- Prompt/instruction layering:
  - `instructions` (paths to markdown instruction files)
- Tool restriction:
  - `tools` allowlist
- Permission policy:
  - `permission` rules with `allow`, `ask`, `deny`
  - glob patterns for tools and command-level matching
- MCP integration:
  - `mcp` map for local and remote servers

## Fallback Model Note

- There is no dedicated CLI `--fallback-model` flag in current docs/help.
- Implement fallback at orchestration level:

```bash
opencode run --model anthropic/claude-sonnet-4-5 "$PROMPT" \
  || opencode run --model openai/gpt-5 "$PROMPT"
```

## Near-Pure LLM Pattern

Use config to disable tools and MCP, then run in JSON mode:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "openai/gpt-5",
  "tools": [],
  "mcp": {}
}
```

```bash
opencode run --format json "Explain optimistic concurrency in 5 bullets."
```

## Sources

- https://opencode.ai/docs/cli
- https://opencode.ai/docs/config
- https://opencode.ai/docs/models
- https://opencode.ai/docs/agents/tools
