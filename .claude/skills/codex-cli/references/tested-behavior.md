# Codex CLI Tested Behavior

Test date: 2026-03-03
Environment: `/home/sasik/personal/agentic-skills`

## Commands Executed

```bash
codex --version
codex --help
codex exec --help
codex mcp --help
codex mcp add --help
codex mcp list

timeout 20s codex exec \
  --skip-git-repo-check \
  --json \
  --sandbox read-only \
  "Reply with OK"
```

## Observed Results

- Version reported: `codex-cli 0.106.0`.
- Help output confirmed this skill's command recipes:
  - `codex exec --json`
  - `--sandbox` modes
  - `--output-schema`
  - `--oss` and `--local-provider`
  - `codex mcp add --url` and stdio form
- Non-interactive JSON mode emitted structured events:
  - `thread.started`
  - `turn.started`
  - repeated `error` events with reconnect attempts

## Environment Caveats

- In this sandbox, Codex emitted warnings about temp dir cleanup in
  `~/.codex/tmp/arg0` due permissions.
- Network-restricted environment prevented successful API completion and caused
  repeated reconnect attempts.
- In current `codex exec --help`, `--ask-for-approval` is not accepted; that
  flag is available on top-level interactive mode.

## Recommendation

- Treat `codex exec --json` event stream as the source of truth for automation.
- For strict automation, combine:
  - `--skip-git-repo-check` (if outside git repo)
  - explicit `--sandbox`
  - explicit model/profile/config overrides
