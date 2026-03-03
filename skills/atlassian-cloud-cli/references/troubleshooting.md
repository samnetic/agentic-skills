# Troubleshooting

## `getaddrinfo EAI_AGAIN` (network resolution error)

Symptom:
- Commands fail with DNS/network errors such as:
  `Error: getaddrinfo EAI_AGAIN <tenant>.atlassian.net`

Actions:
1. Re-run outside sandboxed/no-network environment.
2. Confirm DNS resolution and outbound access for `<tenant>.atlassian.net`.

## `acli confluence` fails with `Activation id for cloudId null not found.`

Symptom:
- `acli confluence space list --limit 1 --json` fails with:
  `Activation id for cloudId null not found.`

Actions:
1. Verify account status:
   ```bash
   acli confluence auth status
   ```
2. Switch account explicitly:
   ```bash
   acli confluence auth switch --site <site>.atlassian.net --email <email>
   ```
3. Retry probe:
   ```bash
   acli confluence space list --limit 1 --json
   ```
4. If still failing, use `confluence-cli` for Confluence operations and keep
   `acli` for Jira.

## `acli jira workitem search` rejects JQL

Symptom:
- Error:
  `Unbounded JQL queries are not allowed here. Please add a search restriction to your query.`

Actions:
1. Add project/assignee/time bound:
   ```bash
   acli jira workitem search --jql "project = APPSMBO ORDER BY updated DESC" --limit 20 --json
   ```
2. Keep result size bounded with `--limit`.

## `acli jira workitem search` field not allowed

Symptom:
- Error:
  `field 'updated' is not allowed`

Actions:
1. Use an allowed field subset, for example:
   ```bash
   acli jira workitem search \
     --jql "project = APPSMBO ORDER BY updated DESC" \
     --fields key,summary,status,assignee,priority \
     --limit 20 --json
   ```
2. For additional fields, fetch issue details with
   `acli jira workitem view <KEY> --fields ...`.

## `confluence-cli spaces` output is too large

Symptom:
- Space list is very long for large tenants.

Actions:
1. Prefer targeted search for work tasks:
   ```bash
   confluence-cli search "type=page" --cql --limit 10
   ```
2. For scripts, truncate output:
   ```bash
   confluence-cli spaces | sed -n '1,60p'
   ```

## Page ID confusion

Symptom:
- Page title search returns multiple candidates, wrong page edited/read.

Actions:
1. Resolve and verify ID:
   ```bash
   PAGE_ID=$(confluence-cli search "Exact Title" --limit 5 \
     | sed -n 's/.*(ID: \([0-9]\+\)).*/\1/p')
   ```
2. Confirm with:
   ```bash
   confluence-cli info <pageId>
   ```
