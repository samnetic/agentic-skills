# OpenCode CLI Tested Behavior

Test date: 2026-03-03
Environment: `/home/sasik/personal/agentic-skills`

## Commands Executed

```bash
opencode --version
opencode --help
opencode run --help
opencode mcp --help
opencode mcp list

# with writable XDG paths in sandbox:
XDG_DATA_HOME=/tmp/opencode-data XDG_CONFIG_HOME=/tmp/opencode-config \
  opencode mcp list

XDG_DATA_HOME=/tmp/opencode-data XDG_CONFIG_HOME=/tmp/opencode-config \
  opencode run --format json --model openai/gpt-5-nano "Reply with OK"
```

## Observed Results

- Version reported: `1.2.10`.
- Help output confirmed key flags used by this skill:
  `run --format`, `-m/--model`, `--variant`, `--thinking`, `--prompt`.
- MCP list command worked and reported "No MCP servers configured" when empty.
- JSON mode emits structured events/errors on stdout.

## Environment Caveats

- In this sandbox, default runtime paths triggered `attempt to write a readonly database`.
- Setting writable XDG paths (`XDG_DATA_HOME`, `XDG_CONFIG_HOME`) allowed CLI
  commands to proceed further.
- External model discovery/service access failed due network restrictions
  (`Unable to connect ... models.dev`), which can hide provider/model catalog.

## Recommendation

- For CI or restricted containers, set writable XDG paths explicitly.
- Keep a pinned config file with known provider/model IDs to reduce dependence
  on live model catalog discovery.
