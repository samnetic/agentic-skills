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

## Workflow

1. Verify tooling and open target page.
2. Take interactive snapshot (`-i`) to get stable element refs.
3. Perform actions using refs and re-snapshot after DOM changes.
4. Capture artifacts (screenshots, extracted data, diffs) for handoff.
5. Close or persist session state as requested.

Use these upstream docs on demand:
- Core upstream instructions: [references/upstream/SKILL.md](references/upstream/SKILL.md)
- Full command reference: [references/upstream/references/commands.md](references/upstream/references/commands.md)
- Snapshot/ref strategy: [references/upstream/references/snapshot-refs.md](references/upstream/references/snapshot-refs.md)
- Auth flows: [references/upstream/references/authentication.md](references/upstream/references/authentication.md)
- Session management: [references/upstream/references/session-management.md](references/upstream/references/session-management.md)

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

## Quality Gates

- `agent-browser` is available before workflow starts.
- Actions are based on fresh refs from latest snapshot when DOM changed.
- Navigation-dependent actions include explicit waits where needed.
- Destructive or account-impacting actions require explicit user intent.
- Final response includes verifiable artifact paths when artifacts were requested.

## Safety Rules

- Do not submit irreversible forms unless user requested it clearly.
- Prefer saved auth profiles/session state over exposing raw credentials.
- Avoid broad scraping if scoped extraction satisfies the request.

## Maintenance

Upstream source is vendored under `references/upstream/` and synced via:

```bash
bash scripts/sync-agent-browser-skill.sh
```

