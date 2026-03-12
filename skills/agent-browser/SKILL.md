---
name: agent-browser
description: >-
  Browser automation skill using the `agent-browser` CLI. Use when a task
  requires opening websites, navigating pages, filling forms, clicking UI
  elements, taking screenshots, extracting page data, validating web flows,
  handling login flows, or comparing web states. Triggers: browser automation,
  open website, click button, fill form, take screenshot, scrape page, test web
  app, login to site, web UI automation.
---

# Agent Browser

Use this skill whenever the task requires deterministic browser interaction.

## Core Principles

| Principle | Meaning |
|-----------|---------|
| Snapshot-first | Never interact with elements blindly. Always take a snapshot to get stable refs before clicking, filling, or reading. |
| Refs are ephemeral | Element refs (`@e1`, `@e2`) are invalidated by any DOM change. Re-snapshot after every navigation or mutation. |
| Explicit waits over sleeps | Use `wait --load networkidle` or `wait @ref` instead of fixed `wait <ms>` delays. Fixed waits are flaky and slow. |
| Least privilege | Restrict domains, actions, and output size to the minimum needed. Do not scrape broadly when scoped extraction suffices. |
| Session isolation | Use named sessions (`--session`) when running concurrent automations to prevent cross-contamination. |
| Artifacts as proof | Every task must produce verifiable artifacts (screenshots, extracted text, diffs) so outcomes can be audited. |
| Credential hygiene | Never pass raw passwords on the command line. Use auth vault, `--password-stdin`, env vars, or saved state files. |

## Workflow

1. Verify tooling and open target page.
2. Take interactive snapshot (`-i`) to get stable element refs.
3. Perform actions using refs and re-snapshot after DOM changes.
4. Capture artifacts (screenshots, extracted data, diffs) for handoff.
5. Close or persist session state as requested.

## Decision Tree

Use this tree to choose the right approach for each scenario.

### Headless vs Headed

```
Need to automate a browser task?
├── Debugging or demonstrating? ──> --headed (visual browser)
│   └── Need video proof? ──> record start demo.webm
└── Production / CI / agent workflow? ──> headless (default)
```

### Screenshots vs DOM Inspection

```
Need to understand page content?
├── Structured data (text, links, form fields)? ──> snapshot -i
│   ├── Need only a section? ──> snapshot -i -s "#selector"
│   └── Page has onclick divs / cursor:pointer? ──> snapshot -i -C
├── Visual layout, icons, charts, or canvas? ──> screenshot --annotate
├── Need to compare before/after? ──> diff snapshot (text) or diff screenshot (visual)
└── Need raw JS data (API responses, computed values)? ──> eval
```

### Authentication Strategy

```
Need to authenticate?
├── Reusable across sessions? ──> auth vault (auth save / auth login)
├── One-time login, persist cookies? ──> state save / state load
├── Multiple concurrent agents, same site? ──> --session-name per agent + state files
└── OAuth / 2FA required? ──> --headed for interactive steps, then save state
```

### Waiting Strategy

```
Page not ready after navigation?
├── Know which element to wait for? ──> wait @ref or wait "#selector"
├── Page loads data via XHR/fetch? ──> wait --load networkidle
├── Redirect expected? ──> wait --url "**/target-path"
├── Custom JS condition? ──> wait --fn "expression"
└── Nothing else works? ──> wait <ms> (last resort)
```

## Quick Start

```bash
agent-browser --version
agent-browser open https://example.com
agent-browser snapshot -i
```

Then act on returned refs (`@e1`, `@e2`, etc.), re-running snapshot after major
page updates.

## Output Contract

Every browser task response should include:

1. Target URL(s) visited
2. Actions executed (high-level command log)
3. Result status (success/partial/failure)
4. Artifacts created (screenshots, extracted files, diffs, session files)
5. Any unresolved blockers and next suggested step

## Anti-Patterns

| Anti-Pattern | Why It's Dangerous | Fix |
|--------------|--------------------|-----|
| Using stale refs after navigation | Refs point to old DOM nodes; clicks hit wrong elements or fail silently | Always `snapshot -i` after any page change before interacting |
| Fixed `wait 5000` instead of explicit waits | Flaky in CI (too short on slow infra, wasteful on fast infra) | Use `wait --load networkidle`, `wait @ref`, or `wait --url` |
| Passing passwords as CLI arguments | Visible in `ps`, shell history, and process logs | Use `--password-stdin`, auth vault, or env vars |
| Scraping entire page when only one element is needed | Floods LLM context, wastes tokens, risks hallucination | Use `snapshot -i -s "#target"` or `get text @ref` |
| Skipping `close` at end of workflow | Leaked browser daemons consume memory and ports | Always `agent-browser close` when done |
| Running concurrent automations on default session | Race conditions between agents sharing one browser | Use `--session <name>` for each concurrent agent |
| Using `eval` with complex JS in inline quotes | Shell escaping corrupts nested quotes, `!`, backticks, `$()` | Use `eval --stdin <<'HEREDOC'` or `eval -b` with base64 |
| Not verifying action results | Silent failures (form didn't submit, click missed) go undetected | `diff snapshot` or re-snapshot after every critical action |
| Ignoring `--content-boundaries` for agent workflows | LLM may treat untrusted page text as instructions (prompt injection) | Set `AGENT_BROWSER_CONTENT_BOUNDARIES=1` |

## Quality Gates

- `agent-browser` is available before workflow starts.
- Actions are based on fresh refs from latest snapshot when DOM changed.
- Navigation-dependent actions include explicit waits where needed.
- Destructive or account-impacting actions require explicit user intent.
- Final response includes verifiable artifact paths when artifacts were requested.

## Checklist

Use this to verify output quality before completing a browser automation task.

- [ ] `agent-browser --version` confirmed tool is installed and accessible
- [ ] Target URL(s) opened successfully (no DNS/TLS/timeout errors)
- [ ] Snapshot taken with `-i` flag before first interaction
- [ ] Refs re-fetched after every navigation or DOM mutation
- [ ] Explicit waits used instead of fixed delays
- [ ] No raw credentials passed as CLI arguments
- [ ] Content boundaries enabled for agent-facing workflows (`AGENT_BROWSER_CONTENT_BOUNDARIES=1`)
- [ ] Domain allowlist set when operating on untrusted sites
- [ ] All requested artifacts (screenshots, PDFs, extracted data) saved with clear paths
- [ ] `diff snapshot` or re-snapshot used to verify critical actions succeeded
- [ ] Session closed with `agent-browser close` at end of workflow
- [ ] Output contract fields (URL, actions, status, artifacts, blockers) included in response

## Safety Rules

- Do not submit irreversible forms unless user requested it clearly.
- Prefer saved auth profiles/session state over exposing raw credentials.
- Avoid broad scraping if scoped extraction satisfies the request.

## Progressive Disclosure Map

Read upstream docs on demand based on the task at hand.

| Reference | When to Read |
|-----------|-------------|
| [references/upstream/SKILL.md](references/upstream/SKILL.md) | Core upstream instructions. Read first when you need command syntax beyond the Quick Start, or when handling an unfamiliar command. |
| [references/upstream/references/commands.md](references/upstream/references/commands.md) | Full command reference. Read when you need exact flags, option names, or edge-case command behavior. |
| [references/upstream/references/snapshot-refs.md](references/upstream/references/snapshot-refs.md) | Snapshot/ref strategy. Read when refs behave unexpectedly, elements are missing from snapshots, or you need scoped/filtered snapshots. |
| [references/upstream/references/authentication.md](references/upstream/references/authentication.md) | Auth flows. Read when the task involves login, OAuth, 2FA, session cookies, or credential management. |
| [references/upstream/references/session-management.md](references/upstream/references/session-management.md) | Session management. Read when running parallel agents, persisting state across restarts, or debugging leaked sessions. |
| [references/upstream/references/video-recording.md](references/upstream/references/video-recording.md) | Video recording. Read when the user wants a visual record of the automation for debugging or documentation. |
| [references/upstream/references/profiling.md](references/upstream/references/profiling.md) | Chrome DevTools profiling. Read when diagnosing page performance issues or generating performance traces. |
| [references/upstream/references/proxy-support.md](references/upstream/references/proxy-support.md) | Proxy configuration. Read when the task requires geo-testing, rotating proxies, or corporate proxy setup. |

## Maintenance

Upstream source is vendored under `references/upstream/` and synced via:

```bash
bash scripts/sync-agent-browser-skill.sh
```
