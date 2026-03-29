# Obsidian CLI Reference

The `obsidian` CLI interacts with a running Obsidian instance. Requires Obsidian to be open.

Run `obsidian help` for the latest commands. Full docs: https://help.obsidian.md/cli

## Syntax

**Parameters** take a value with `=`. Quote values with spaces:

```bash
obsidian create name="My Note" content="Hello world"
```

**Flags** are boolean switches with no value:

```bash
obsidian create name="My Note" silent overwrite
```

For multiline content use `\n` for newline and `\t` for tab.

## File Targeting

- `file=<name>` — resolves like a wikilink (name only, no path or extension needed)
- `path=<path>` — exact path from vault root, e.g. `folder/note.md`
- Without either, the active file is used

## Vault Targeting

Commands target the most recently focused vault. Use `vault=<name>` as the first parameter:

```bash
obsidian vault="My Vault" search query="test"
```

## Commands by Category

### File Operations

```bash
obsidian create name="Note" content="# Hello" template="Template" silent
obsidian read file="Note"
obsidian delete file="Note"
obsidian move file="Note" to="folder/"
obsidian append file="Note" content="New line"
```

### Daily Notes

```bash
obsidian daily                         # Open today's daily note
obsidian daily:read                    # Read today's daily note
obsidian daily:append content="text"   # Append to daily note
obsidian daily:prepend content="text"  # Prepend to daily note
```

### Search

```bash
obsidian search query="search term" limit=10
obsidian search query="test" path="notes/" caseSensitive
# Output formats: text (default), json
```

### Tasks

```bash
obsidian tasks                         # List all tasks
obsidian tasks daily todo              # List uncompleted tasks from daily note
obsidian tasks file="Note" done        # List completed tasks in note
```

### Properties (Frontmatter)

```bash
obsidian property:set name="status" value="done" file="Note"
obsidian property:get name="status" file="Note"
```

### Tags

```bash
obsidian tags                          # List all tags
obsidian tags sort=count counts        # Tags sorted by frequency
```

### Structure

```bash
obsidian backlinks file="Note"         # Files linking to this note
obsidian outgoing-links file="Note"    # Links from this note
```

### Bookmarks and Bases

```bash
obsidian bookmark file="Note"
obsidian bases query path="MyBase.base" format=json
# Formats: json, csv, tsv, markdown
```

### Sync

```bash
obsidian sync:status
obsidian sync:pause
obsidian sync:resume
```

### Workspace

```bash
obsidian workspace:save name="layout"
obsidian workspace:load name="layout"
obsidian workspace:list
```

## Plugin Development

### Develop/Test Cycle

1. Reload the plugin:
   ```bash
   obsidian plugin:reload id=my-plugin
   ```
2. Check for errors:
   ```bash
   obsidian dev:errors
   ```
3. Verify visually:
   ```bash
   obsidian dev:screenshot path=screenshot.png
   obsidian dev:dom selector=".workspace-leaf" text
   ```
4. Check console:
   ```bash
   obsidian dev:console level=error
   ```

### Additional Developer Commands

```bash
obsidian eval code="app.vault.getFiles().length"
obsidian dev:css selector=".workspace-leaf" prop=background-color
obsidian dev:mobile on
```

## Global Flags

| Flag | Description |
|------|-------------|
| `--copy` | Copy output to clipboard |
| `silent` | Prevent files from opening in UI |
| `overwrite` | Overwrite existing files |
| `total` | Show count on list commands |

## WSL2 Usage

The CLI binary is `obsidian.exe` on Windows. From WSL, create a wrapper:

```bash
#!/bin/bash
# ~/bin/obsidian
obsidian.exe "$@" 2>&1 | tr -d '\r'
```

Make executable and add `~/bin` to PATH. Requires `appendWindowsPath=true` in WSL config.

## Headless Sync (obsidian-headless / `ob`)

For headless/server environments without the Obsidian GUI:

```bash
ob login                               # Authenticate
ob sync-list-remote                    # List remote vaults
ob sync-setup --vault=<id> --path=/path/to/vault
ob sync-status --path=/path/to/vault
ob sync-config --path=/path/to/vault   # Change sync settings
ob sync-unlink --path=/path/to/vault   # Disconnect from sync
```

## References

- [Obsidian CLI](https://help.obsidian.md/cli)
- [obsidian-headless](https://www.npmjs.com/package/obsidian-headless)
