# Claude Code CLI Capabilities

Last verified: 2026-03-03
CLI version checked locally: `2.1.63 (Claude Code)`

## Key Commands

- Interactive session: `claude`
- Non-interactive print mode: `claude -p ...`
- MCP management: `claude mcp ...`
- Auth management: `claude auth ...`

## Control Surface (High Value Flags)

- Prompt and output:
  - `-p, --print`
  - `--output-format text|json|stream-json`
  - `--input-format text|stream-json`
  - `--include-partial-messages`
  - `--json-schema <schema>`
- Model controls:
  - `--model <alias-or-full-model>`
  - `--effort low|medium|high`
  - `--fallback-model <model>` (print mode only)
- Prompt overrides:
  - `--system-prompt <prompt>`
  - `--append-system-prompt <prompt>`
  - `--disable-slash-commands`
- Tool and permission controls:
  - `--tools <tools...>` (use `""` to disable all built-in tools)
  - `--allowed-tools <tools...>`
  - `--disallowed-tools <tools...>`
  - `--permission-mode acceptEdits|bypassPermissions|default|dontAsk|plan`
- MCP controls:
  - `--mcp-config <json-file-or-json-string>`
  - `--strict-mcp-config`
  - `claude mcp add|get|list|remove|reset-project-choices|serve`

## MCP Notes

- `claude mcp add` supports `stdio`, `sse`, and `http` transports.
- Scope selection is available through `-s, --scope local|user|project`.
- OAuth-oriented options are available on add (`--client-id`, `--client-secret`,
  callback port, headers, env vars).

## Near-Pure LLM Pattern

Use all three constraints together:

1. Disable built-in tools: `--tools ""`
2. Isolate MCP to an empty config: `--strict-mcp-config --mcp-config <empty>`
3. Use explicit instruction: `--system-prompt "Do not call tools"`

Example:

```bash
cat >/tmp/empty-mcp.json <<'JSON'
{"mcpServers":{}}
JSON

claude -p \
  --model sonnet \
  --system-prompt "Answer in plain text only. Do not call tools." \
  --tools "" \
  --strict-mcp-config \
  --mcp-config /tmp/empty-mcp.json \
  --output-format json \
  "Explain eventual consistency in 4 bullets."
```

## Sources

- https://code.claude.com/docs/en/docs/claude-code/cli-reference
- https://code.claude.com/docs/en/docs/claude-code/settings
- https://code.claude.com/docs/en/docs/claude-code/mcp
