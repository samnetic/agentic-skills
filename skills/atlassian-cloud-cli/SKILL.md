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
license: MIT
compatibility: Requires acli (Atlassian CLI) and confluence-content-tools
metadata:
  author: samnetic
  version: "1.0"
---

# Atlassian Cloud CLI

Operate Jira and Confluence from terminal-first workflows while keeping changes
safe, traceable, and scriptable.

---

## Core Principles

| Principle | Meaning |
|---|---|
| **Read before write** | Always discover IDs/keys with read-only commands before any mutation. Never guess a page ID or issue key |
| **Scope-bound every query** | Every JQL/CQL query must include a project, space, or type restriction. Unbounded queries timeout or fail silently |
| **Preflight is mandatory** | Run `scripts/preflight-atlassian-cli.sh` to verify auth, connectivity, and CLI versions before any session |
| **Dry-run first, apply second** | Stage write payloads with `--generate-json` or `--dry-run` so the user can inspect before committing |
| **Verify after mutate** | Every write must be followed by an immediate read that proves the change landed |
| **Choose the right CLI** | `acli` for Jira, `confluence-cli` for Confluence content. Mixing them up wastes time on auth mismatches |
| **Deterministic output** | Use `--json` and parse programmatically. Never rely on human-readable table formatting for automation |
| **Least privilege** | Request only the fields you need (`--fields`), limit result sets, and redact tenant data by default |

---

## Tool Selection

- Use `acli jira ...` for Jira work: projects, boards, sprints, filters, work
  items.
- Use `confluence-cli ...` for most Confluence work: search/read/create/update,
  children trees, attachments, comments, properties, export, copy-tree.
- Use `acli confluence ...` only when it is confirmed healthy in the current
  environment; otherwise fall back to `confluence-cli`.
- Use `acli auth ...`, `acli jira auth ...`, and `acli confluence auth ...` for
  account status and switching.

---

## Progressive Disclosure Map

| Reference | Content | When to read |
|---|---|---|
| [references/capability-matrix.md](references/capability-matrix.md) | Full command support grid for `acli` and `confluence-cli` | Before choosing a CLI for an unfamiliar operation |
| [references/command-recipes.md](references/command-recipes.md) | Copy-paste recipes for common multi-step workflows | When building a new automation or script |
| [references/troubleshooting.md](references/troubleshooting.md) | Known errors, auth edge cases, environment quirks | When a command fails or returns unexpected output |

---

## Quick Start

```bash
scripts/preflight-atlassian-cli.sh
acli jira project list --limit 20 --json
confluence-cli search "type=page" --cql --limit 5
scripts/jira-to-confluence-sync.sh --jql "project = APPSMBO ORDER BY updated DESC" --limit 20
```

---

## Workflow

```
1. PREFLIGHT  → scripts/preflight-atlassian-cli.sh
2. SELECT CLI → Jira ⇒ acli | Confluence ⇒ confluence-cli
3. DISCOVER   → Read-only: list, search, view, info (resolve IDs/keys)
4. STAGE      → --generate-json or --dry-run (inspect payload)
5. CONFIRM    → Get explicit user approval for destructive actions
6. EXECUTE    → Run the bounded write command
7. VERIFY     → Immediate read-back to confirm the change
8. REPORT     → Hand off: CLI chosen, commands run, IDs touched, verification result
```

**Why this order matters:**
- You cannot write safely without resolved IDs from step 3
- You cannot recover from mistakes without the dry-run from step 4
- You cannot prove success without the verify step in step 7

---

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

### Embedding images in Confluence pages

`confluence-cli` markdown format does **not** convert `![](filename)` to inline
images. Uploaded attachments must be embedded via Confluence storage format.

**Workflow:**

1. Upload the image as an attachment:
`confluence-cli attachment-upload <pageId> --file ./diagram.png`
2. Embed it in the page using the REST API to inject storage-format XML:

```xml
<ac:image ac:align="center" ac:layout="center" ac:custom-width="true" ac:width="760">
  <ri:attachment ri:filename="diagram.png" />
</ac:image>
```

3. To inject this, fetch the current page body via REST API
(`GET /wiki/rest/api/content/<pageId>?expand=body.storage`), insert the
`<ac:image>` tag at the desired location, then update via REST API
(`PUT /wiki/rest/api/content/<pageId>` with the new `body.storage.value`).

**Alternative:** Upload the attachment, then manually insert it via the
Confluence editor UI (`+` → Image → select attached file). This is simpler for
one-off insertions.

---

## Anti-Patterns

| Anti-Pattern | Why It's Dangerous | Fix |
|---|---|---|
| **Unbounded JQL/CQL queries** | Timeouts, truncated results, or API rate-limit bans. Silent data loss in automation | Always add `project = X`, `space = X`, or `type = page` restriction plus `--limit` |
| **Writing without ID discovery** | Wrong page overwritten, wrong issue edited. No undo for most Confluence writes | Run `search` / `info` / `view` first; confirm the ID matches the expected title/key |
| **Skipping preflight** | Auth may be expired, CLI may be missing, wrong account may be active | Run `scripts/preflight-atlassian-cli.sh` at session start |
| **Parsing human-readable output** | Table column alignment changes between versions; fragile regex breaks silently | Use `--json` and parse with `jq` or structured tooling |
| **Mixing CLI auth contexts** | `acli` and `confluence-cli` may be authenticated to different tenants or accounts | Verify both with `acli auth status` and `confluence-cli` equivalent before cross-tool workflows |
| **Mutating without dry-run** | Bulk creates/moves with wrong parameters are expensive to reverse | Use `--generate-json` or `--dry-run` to preview, then apply |
| **Skipping post-write verify** | API may return 200 but silently drop fields (e.g., labels, custom fields) | Always read back the entity and diff against expected state |
| **Embedding images via markdown** | `confluence-cli` markdown does not render `![](file)` as images | Upload as attachment, then inject `<ac:image>` via storage-format REST API |
| **Deleting without backup** | Confluence pages and Jira issues in trash may be auto-purged | Export page or capture full JSON before any delete/archive operation |

---

## Output Contract

For every task, return:

1. CLI chosen and why.
2. Commands executed (sanitized if needed).
3. IDs/keys touched (project key, issue key, page ID, space key).
4. Verification command and result summary.
5. Any blocker and fallback taken.

---

## Quality Gates

- Preflight completed or equivalent checks performed.
- Target IDs/keys are resolved and validated before mutation.
- Write commands are scope-bounded and mapped to explicit IDs/keys.
- Post-change verification read completed (`view`, `info`, or `read`).
- Final handoff includes executed commands, results, and fallback path if used.

---

## Guardrails

- Prefer `--json` output when supported and parse deterministically.
- Keep reads bounded (`--limit`, targeted fields) to avoid oversized output.
- Do not run destructive commands without explicit user confirmation.
- Treat `acli` and `confluence-cli` auth contexts as independent until verified.
- Redact tenant-sensitive data in summaries unless user asks for raw output.

---

## Checklist

Use before closing any Atlassian CLI task:

### Session Setup
- [ ] Preflight script ran successfully (`scripts/preflight-atlassian-cli.sh`)
- [ ] Correct account/tenant is active for both `acli` and `confluence-cli`
- [ ] CLI versions are compatible with target Atlassian Cloud instance

### Read Operations
- [ ] All JQL/CQL queries are scope-bounded (project, space, type restriction)
- [ ] Result limits are set (`--limit`) to prevent oversized responses
- [ ] Output format is `--json` for any downstream parsing

### Write Operations
- [ ] Target IDs/keys resolved via read-only discovery before mutation
- [ ] Payload previewed with `--generate-json` or `--dry-run`
- [ ] User explicitly confirmed destructive actions (delete, move, archive)
- [ ] Write command is scoped to specific IDs -- no wildcard or bulk-all mutations

### Post-Write Verification
- [ ] Read-back command executed immediately after each write
- [ ] Returned state matches expected outcome (fields, content, parent, status)
- [ ] Any discrepancy logged and escalated before continuing

### Handoff
- [ ] Output contract fulfilled (CLI chosen, commands, IDs, verification, blockers)
- [ ] Tenant-sensitive data redacted in summary
- [ ] Fallback path documented if primary CLI was unavailable
