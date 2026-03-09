---
name: atlassian-cloud-cli
description: >-
  Atlassian Cloud operations via `acli` (Jira + Confluence) and
  `confluence-cli` (Confluence-focused). Use when tasks involve Jira project,
  board, sprint, filter, or work item search/view/create/edit; Confluence page
  search/read/create/update/move/export; attachment/comment/property management;
  or Atlassian CLI auth troubleshooting and account switching. Triggers: jira,
  confluence, atlassian, acli, confluence-cli, jql, cql, work item triage,
  confluence docs automation, release notes sync.
---

# Atlassian Cloud CLI

Operate Jira and Confluence from terminal-first workflows while keeping changes
safe, traceable, and scriptable.

## Tool Selection

- Use `acli jira ...` for Jira work: projects, boards, sprints, filters, work
  items.
- Use `confluence-cli ...` for most Confluence work: search/read/create/update,
  children trees, attachments, comments, properties, export, copy-tree.
- Use `acli confluence ...` only when it is confirmed healthy in the current
  environment; otherwise fall back to `confluence-cli`.
- Use `acli auth ...`, `acli jira auth ...`, and `acli confluence auth ...` for
  account status and switching.

Capability details and validated observations live in:
- [references/capability-matrix.md](references/capability-matrix.md)
- [references/command-recipes.md](references/command-recipes.md)
- [references/troubleshooting.md](references/troubleshooting.md)

## Quick Start

```bash
scripts/preflight-atlassian-cli.sh
acli jira project list --limit 20 --json
confluence-cli search "type=page" --cql --limit 5
scripts/jira-to-confluence-sync.sh --jql "project = APPSMBO ORDER BY updated DESC" --limit 20
```

## Workflow

1. Run preflight:
`scripts/preflight-atlassian-cli.sh`
2. Choose CLI based on task scope:
Jira => `acli`, Confluence content => `confluence-cli` (unless `acli confluence`
is verified working).
3. Discover IDs with read-only commands first (`list`, `search`, `view`, `info`).
4. For write operations, stage inputs before execution:
`acli jira workitem create --generate-json`, `acli jira workitem edit --generate-json`,
or `confluence-cli copy-tree --dry-run`.
For Jira-to-Confluence status publishing, use
`scripts/jira-to-confluence-sync.sh` in dry-run first, then rerun with
`--apply`.
5. Execute mutation only after user intent is explicit for destructive actions
(`delete`, `move`, archive/unarchive).
6. Verify result with an immediate read command and include the verification
output in handoff.

## Command Patterns

### Jira (`acli`)

- Project inventory:
`acli jira project list --limit 50 --json`
- Bounded JQL search:
`acli jira workitem search --jql "project = APPSMBO ORDER BY updated DESC" --limit 20 --fields key,summary,status,assignee --json`
- Work item detail:
`acli jira workitem view APPSMBO-906 --fields key,summary,status,assignee --json`
- Create/edit with deterministic payloads:
`acli jira workitem create --generate-json`
`acli jira workitem edit --generate-json`

Important: unbounded JQL can fail in this environment. Always add a project or
equivalent restriction.

### Confluence (`confluence-cli`)

- Spaces:
`confluence-cli spaces`
- CQL search:
`confluence-cli search "type=page" --cql --limit 10`
- Page read/info:
`confluence-cli info <pageId>`
`confluence-cli read <pageId> --format markdown`
- Page maintenance:
`confluence-cli create "<title>" <spaceKey> --file ./content.md --format markdown`
`confluence-cli update <pageId> --file ./content.md --format markdown`
`confluence-cli move <pageId> <newParentId>`
- Tree/export:
`confluence-cli children <pageId> --recursive --format tree --show-id`
`confluence-cli export <pageId> --dest ./exports --format markdown`
- Attachments/comments/properties:
`confluence-cli attachment-upload <pageId> --file ./artifact.pdf --comment "Weekly report"`
`confluence-cli comments <pageId> --limit 50 --format markdown`
`confluence-cli property-set <pageId> sync-state --file ./state.json --format json`

## Output Contract

For every task, return:

1. CLI chosen and why.
2. Commands executed (sanitized if needed).
3. IDs/keys touched (project key, issue key, page ID, space key).
4. Verification command and result summary.
5. Any blocker and fallback taken.

## Quality Gates

- Preflight completed or equivalent checks performed.
- Target IDs/keys are resolved and validated before mutation.
- Write commands are scope-bounded and mapped to explicit IDs/keys.
- Post-change verification read completed (`view`, `info`, or `read`).
- Final handoff includes executed commands, results, and fallback path if used.

## Guardrails

- Prefer `--json` output when supported and parse deterministically.
- Keep reads bounded (`--limit`, targeted fields) to avoid oversized output.
- Do not run destructive commands without explicit user confirmation.
- Treat `acli` and `confluence-cli` auth contexts as independent until verified.
- Redact tenant-sensitive data in summaries unless user asks for raw output.
