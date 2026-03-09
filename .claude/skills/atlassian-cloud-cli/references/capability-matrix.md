# Capability Matrix

Validation snapshot from this machine on 2026-03-03.

## Tool Versions

- `acli`: `1.3.14-stable`
- `confluence-cli`: `1.21.1`

## Coverage

| Area | `acli` | `confluence-cli` | Preferred CLI | Notes |
| --- | --- | --- | --- | --- |
| Jira auth/account switch | Verified | N/A | `acli` | `acli jira auth status/switch` works. |
| Jira projects/boards/sprints/workitems | Verified | N/A | `acli` | `project list`, `board search`, `workitem search/view` tested. |
| Jira create/edit workflows | Available (help verified) | N/A | `acli` | Supports `--generate-json`, `--from-json`. |
| Confluence auth/account switch | Status verified | N/A | Mixed | Auth status works, but operations may still fail. |
| Confluence spaces/pages/blogs via `acli` | Partially available | N/A | `confluence-cli` | In this environment, `acli confluence` operations fail with `Activation id for cloudId null not found.` |
| Confluence spaces listing | Not reliable in current env | Verified | `confluence-cli` | `confluence-cli spaces` succeeds. |
| Confluence page search/read/info | Not reliable in current env | Verified | `confluence-cli` | `search`, `info`, `read` tested successfully. |
| Confluence create/update/move/delete | Help verified | Available (help verified) | `confluence-cli` | Prefer `confluence-cli` for operational stability. |
| Confluence comments/attachments/properties | Limited in `acli` | Available (help verified) | `confluence-cli` | Rich operations in `confluence-cli`. |
| Confluence export/copy-tree | Not exposed in tested `acli` commands | Available | `confluence-cli` | `copy-tree` supports `--dry-run`. |
| JSON/CSV output for automation | Strong | Mixed by command | Depends | `acli` is stronger for machine output; `confluence-cli` has text-first defaults. |

## Observed Failure Modes

- `acli jira workitem search` rejects unbounded queries:
  - Error: `Unbounded JQL queries are not allowed here. Please add a search restriction to your query.`
- `acli jira workitem search` enforces an allowed field subset:
  - Error: `field 'updated' is not allowed`
- `acli confluence` operations fail in current account context:
  - Error: `Activation id for cloudId null not found.`

Treat these as environment-specific until revalidated.
