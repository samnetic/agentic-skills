# Gemini CLI Tested Behavior

Test date: 2026-03-04
Environment: `/home/sasik/personal/agentic-skills`
Local binary: `/usr/bin/gemini` -> `@google/gemini-cli`

## Commands Executed

```bash
gemini --version
gemini --help
gemini mcp --help
gemini mcp add --help
gemini extensions --help
gemini mcp list
./skills/gemini-cli/scripts/detect-gemini-capabilities.sh
./skills/gemini-cli/scripts/detect-gemini-capabilities.sh --json
./skills/gemini-cli/scripts/detect-gemini-capabilities.sh \
  --require command.mcp,flag.output_format,mcp.add,mcp.list,mcp.remove

gemini --prompt "x" "y"
gemini --prompt "x" --prompt-interactive "y"
gemini --output-format yaml "x"
gemini --all-files "x"
gemini mcp update sample --scope project

HOME=/tmp gemini --list-extensions
HOME=/tmp gemini extensions list
HOME=/tmp gemini mcp list

# MCP add/list/remove integration check in /tmp
HOME=/tmp gemini mcp add sample https://example.com/sse -t sse --scope project \
  --description "sample server" \
  --include-tools "toolA,toolB" \
  --exclude-tools "toolX" \
  --header "Authorization: Bearer demo"
HOME=/tmp gemini mcp list
HOME=/tmp gemini mcp remove sample
HOME=/tmp gemini mcp list

# Headless runtime probes
gemini --output-format json "Respond exactly with OK"
HOME=/tmp gemini --debug --output-format stream-json "Respond exactly with OK"
```

## Observed Results

- Version reported: `0.18.4`.
- Top-level commands available locally: default `gemini`, `mcp`, `extensions`.
- `mcp` subcommands available locally: `add`, `list`, `remove`.
- `mcp add` accepts:
  - `--scope user|project`
  - `--transport stdio|sse|http`
  - `--env`, `--header`, `--timeout`, `--trust`, `--description`
  - `--include-tools`, `--exclude-tools`
- Parser validation confirmed:
  - positional prompt cannot be combined with `--prompt`
  - `--prompt` cannot be combined with `--prompt-interactive`
  - invalid output format is rejected
- `--all-files` is unknown in this local version.
- `gemini mcp update ...` is unknown in this local version.
- capability detector script correctly reported local capabilities and
  returned:
  - exit `0` for satisfied `--require` sets
  - exit `2` when required capabilities were missing

## Integration Findings

- MCP lifecycle (`add -> list -> remove -> list`) worked in `/tmp` and showed
  expected config state transitions.
- `--include-tools` / `--exclude-tools` options were accepted in `mcp add`.

## Environment Caveats

- In this sandbox, headless prompt execution failed when writing under default
  `~/.gemini/tmp/...` with:
  - `EACCES: permission denied, mkdir .../chats`
- Using `HOME=/tmp` avoided the local write-permission error.
- Model calls still could not be fully validated here due network/DNS limits:
  - observed `fetch failed` / `EAI_AGAIN play.googleapis.com`
  - headless runs timed out (`EXIT:124`) before model response completion

## Practical Implication

For CI/sandbox automation, run preflight checks before prompt execution:

1. `gemini --version`
2. `gemini --help` (feature detect)
3. writable runtime directory (e.g., set `HOME` when needed)
4. network/auth reachability for Gemini endpoints
