# Claude Code CLI Tested Behavior

Test date: 2026-03-03
Environment: `/home/sasik/personal/agentic-skills`

## Commands Executed

```bash
claude --version
claude --help
claude auth status
claude mcp --help
claude mcp add --help
claude mcp list
timeout 20s claude -p --output-format json "Reply with OK"
timeout 20s claude -p -d api "Reply with OK"
```

## Observed Results

- Version reported: `2.1.63 (Claude Code)`.
- Auth status command returned a valid logged-in account object.
- CLI help confirmed all key flags used by this skill:
  `--model`, `--fallback-model`, `--tools`, `--system-prompt`,
  `--output-format`, `--input-format`, `--mcp-config`, `--strict-mcp-config`.
- `claude mcp list` was able to enumerate configured servers and attempt health
  checks.

## Environment Caveat

- In this sandbox, `claude -p` hit a local filesystem permission error
  (`EACCES: permission denied, open`) when trying to write runtime state/logs.
- Practical implication: ensure Claude runtime directories are writable in
  restricted environments before relying on non-interactive automation.

## Recommendation

- For CI/sandbox usage, run a preflight command that checks:
  - CLI binary availability
  - auth status
  - writable runtime directory
  - MCP server connectivity only when required
