# Command Recipes

Use these as copy/paste starting points. Replace placeholders first.

## Preflight

```bash
scripts/preflight-atlassian-cli.sh
```

## Automated Jira -> Confluence Sync

### Generate report only (safe default)

```bash
scripts/jira-to-confluence-sync.sh \
  --jql "project = APPSMBO ORDER BY updated DESC" \
  --limit 25
```

### Update existing Confluence page

```bash
scripts/jira-to-confluence-sync.sh \
  --jql "project = APPSMBO AND statusCategory != Done ORDER BY updated DESC" \
  --page-id 123456789 \
  --apply
```

### Create new Confluence page

```bash
scripts/jira-to-confluence-sync.sh \
  --jql "project = APPSMBO ORDER BY updated DESC" \
  --space-key DOCS \
  --title "Weekly Jira Sync - 2026-03-03" \
  --apply
```

## Jira (`acli`)

### Discover projects and boards

```bash
acli jira project list --limit 50 --json
acli jira board search --limit 20 --json
```

### Search work items (bounded JQL)

```bash
acli jira workitem search \
  --jql "project = APPSMBO ORDER BY updated DESC" \
  --limit 20 \
  --fields key,summary,status,assignee \
  --json
```

### View work item details

```bash
acli jira workitem view APPSMBO-906 \
  --fields key,summary,status,assignee,description \
  --json
```

### Stage create/edit payloads before execution

```bash
acli jira workitem create --generate-json
acli jira workitem edit --generate-json
```

## Confluence (`confluence-cli`)

### Discover spaces and pages

```bash
confluence-cli spaces
confluence-cli search "type=page" --cql --limit 10
```

### Resolve page ID from search output

```bash
PAGE_ID=$(confluence-cli search "Release notes" --limit 1 \
  | sed -n 's/.*(ID: \([0-9]\+\)).*/\1/p' | head -n1)
echo "$PAGE_ID"
```

### Read and inspect a page

```bash
confluence-cli info "$PAGE_ID"
confluence-cli read "$PAGE_ID" --format markdown
confluence-cli children "$PAGE_ID" --format tree --max-depth 2 --show-id
confluence-cli comments "$PAGE_ID" --limit 25 --format markdown
```

### Create or update page content from file

```bash
confluence-cli create "Release Notes - 2026-03-03" DOCS \
  --file ./release-notes.md --format markdown

confluence-cli update "$PAGE_ID" \
  --file ./release-notes.md --format markdown
```

### Attach artifacts and set page properties

```bash
confluence-cli attachment-upload "$PAGE_ID" \
  --file ./report.pdf --comment "Automated report" --replace

confluence-cli property-set "$PAGE_ID" sync-state \
  --file ./sync-state.json --format json
```

### Safe tree copy

```bash
confluence-cli copy-tree "$SOURCE_PAGE_ID" "$TARGET_PARENT_ID" \
  --dry-run --max-depth 3
```

## Auth and Account Switching

```bash
acli auth status
acli jira auth status
acli confluence auth status

acli jira auth switch --site <site>.atlassian.net --email <email>
acli confluence auth switch --site <site>.atlassian.net --email <email>
```
