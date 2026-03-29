---
name: obsidian
description: >-
  Obsidian vault management — notes, Bases views, CLI operations, Canvas, and
  Obsidian Flavored Markdown. Use when creating or editing notes in an Obsidian
  vault, working with .base files, .canvas files, frontmatter/properties,
  wikilinks, callouts, embeds, tags, templates, daily notes, vault search,
  task management, or interacting with Obsidian via CLI. Also use when the user
  mentions Obsidian, vault, wikilinks, Bases, Canvas, or asks to manage notes
  from the command line.
  Triggers: obsidian, vault, note, wikilink, frontmatter, properties, tags,
  callout, embed, base file, canvas, daily note, template, obsidian cli,
  obsidian search, obsidian sync, bases view, card view, table view, backlinks.
---

# Obsidian Skill

Create, edit, and manage Obsidian vaults with correct syntax, proper metadata,
and full use of Obsidian features. Every note should have valid frontmatter,
every link should be a wikilink, every Base should be valid YAML.

---

## Core Principles

| Principle | Meaning |
|---|---|
| **Wikilinks over Markdown links** | Use `[[Note]]` for internal vault links; Obsidian tracks renames automatically |
| **Frontmatter on every note** | YAML properties at top enable Bases views, search, and filtering |
| **Bases for navigation** | `.base` files replace manual folder browsing with dynamic filtered views |
| **CLI for automation** | Use `obsidian` CLI for programmatic vault operations from terminal/agents |
| **Templates for consistency** | Every note type should have a template with pre-filled frontmatter |
| **Link over duplicate** | Link to existing notes rather than restating information |

---

## Workflow: Creating a Note

1. **Check CLAUDE.md** for vault-specific conventions (folder structure, required frontmatter fields, naming rules)
2. **Choose the right template** — match the note's category to a template
3. **Add frontmatter** with all required properties (see [PROPERTIES.md](references/PROPERTIES.md))
4. **Write content** using Obsidian Flavored Markdown (see [MARKDOWN.md](references/MARKDOWN.md))
5. **Link related notes** with `[[wikilinks]]` — prefer linking to existing notes
6. **Place in correct folder** per vault conventions (check CLAUDE.md)

## Workflow: Creating a Base View

1. Create a `.base` file with valid YAML
2. Define `filters` to scope which notes appear (by folder, tag, property, date)
3. Add `formulas` for computed values (optional)
4. Configure one or more `views` (table, cards, list, map)
5. Specify `order` for which properties/columns to display
6. Validate YAML syntax — quote strings with special characters

See [BASES.md](references/BASES.md) for full schema, filter syntax, formulas, and examples.

## Workflow: Using the CLI

The `obsidian` CLI interacts with a running Obsidian instance. Always check `obsidian help` for the latest commands.

```bash
# Read/write notes
obsidian read file="My Note"
obsidian create name="New Note" content="# Hello" template="Template" silent
obsidian append file="My Note" content="New line"
obsidian search query="search term" limit=10

# Daily notes
obsidian daily:read
obsidian daily:append content="- [ ] New task"

# Properties and tags
obsidian property:set name="status" value="done" file="My Note"
obsidian tags sort=count counts

# Tasks and structure
obsidian tasks daily todo
obsidian backlinks file="My Note"
```

**Parameters** take a value with `=` (quote values with spaces). **Flags** are boolean switches with no value (e.g., `silent`, `overwrite`).

**File targeting:** `file=<name>` resolves like a wikilink (name only). `path=<path>` is an exact path from vault root.

**Vault targeting:** Commands target the most recently focused vault. Use `vault=<name>` to target a specific vault.

Use `--copy` to copy output to clipboard. Use `total` on list commands for counts.

See [CLI.md](references/CLI.md) for the full command reference including plugin development commands.

---

## Obsidian Flavored Markdown — Quick Reference

### Internal Links (Wikilinks)

```markdown
[[Note Name]]                          Link to note
[[Note Name|Display Text]]             Custom display text
[[Note Name#Heading]]                  Link to heading
[[Note Name#^block-id]]                Link to block
[[#Heading in same note]]              Same-note heading link
```

### Embeds

```markdown
![[Note Name]]                         Embed full note
![[image.png]]                         Embed image
![[image.png|300]]                     Image with width
![[document.pdf#page=3]]               PDF page
```

### Callouts

```markdown
> [!note]
> Basic callout.

> [!warning] Custom Title
> Callout with a custom title.

> [!faq]- Collapsed by default
> Foldable callout content.
```

Types: `note`, `tip`, `warning`, `info`, `example`, `quote`, `bug`, `danger`, `success`, `failure`, `question`, `abstract`, `todo`.

### Other Obsidian Syntax

```markdown
==Highlighted text==                   Highlight
%%Hidden comment%%                     Comment (hidden in reading view)
#tag  #nested/tag                      Tags
$e^{i\pi} + 1 = 0$                    Inline math
```

See [MARKDOWN.md](references/MARKDOWN.md) for full syntax including Mermaid diagrams, footnotes, and block IDs.

---

## Bases — Quick Reference

```yaml
filters:
  and:
    - file.inFolder("notes")
    - 'status != "archived"'

formulas:
  days_old: '(now() - file.ctime).days'

views:
  - type: table
    name: "Active Notes"
    order:
      - file.name
      - status
      - formula.days_old
    sort:
      - column: created
        direction: DESC
```

Key filter functions: `file.inFolder()`, `file.hasTag()`, `file.hasLink()`, `file.hasProperty()`.

See [BASES.md](references/BASES.md) for filter operators, all view types, formula functions, summaries, and troubleshooting.

---

## Canvas — Quick Reference

Canvas files (`.canvas`) contain JSON with `nodes` and `edges` arrays.

Node types: `text`, `file`, `link`, `group`. Each needs `id` (16-char hex), `x`, `y`, `width`, `height`.

```json
{
  "nodes": [
    {"id": "6f0ad84f44ce9c17", "type": "text", "x": 0, "y": 0, "width": 300, "height": 150, "text": "# Hello"}
  ],
  "edges": []
}
```

See [CANVAS.md](references/CANVAS.md) for full node/edge schemas, layout guidelines, and examples.

---

## Properties (Frontmatter) — Quick Reference

```yaml
---
title: Note Title
date: 2024-01-15
tags:
  - project
  - active
aliases:
  - Alternative Name
status: in-progress
---
```

Types: Text, Number, Checkbox (`true`/`false`), Date (`YYYY-MM-DD`), Date & Time (`YYYY-MM-DDTHH:mm:ss`), List, Links (`"[[Note]]"`).

Default properties: `tags` (searchable labels), `aliases` (alternative names for link suggestions), `cssclasses` (CSS classes for styling).

See [PROPERTIES.md](references/PROPERTIES.md) for all types and tag syntax rules.

---

## Output Contract

Every skill invocation produces one or more of:

| Artifact | Format | When |
|----------|--------|------|
| Note file | `.md` with YAML frontmatter | Creating or editing notes |
| Base view | `.base` with valid YAML | Creating filtered views |
| Canvas file | `.canvas` with valid JSON | Creating visual canvases |
| CLI command | `obsidian <command>` | Vault operations via terminal |
| Frontmatter patch | YAML property changes | Updating note metadata |

---

## Anti-Patterns

| Mistake | Why it breaks | Fix |
|---------|--------------|-----|
| Using `[text](path)` for internal links | Obsidian cannot track renames; graph view misses the link | Use `[[Note]]` or `[[Note\|display]]` |
| Forgetting frontmatter | Note is invisible to Bases views, search filters, and Dataview | Always add YAML frontmatter block |
| Unquoted special chars in `.base` YAML | YAML parse error — Base view fails to render | Quote strings containing `:`, `#`, `[`, `]`, `{`, `}` |
| Duration `.round()` without field access | Duration type has no `.round()` method — formula crashes | Access `.days` or `.hours` first, then `.round()` |
| Duplicate IDs in `.canvas` | Edges break, nodes stack, unpredictable rendering | Generate unique 16-char hex IDs per node/edge |
| Missing null checks in formulas | Formula crashes when property is missing on some notes | Wrap with `if(property, ..., "")` |
| Creating notes without checking vault CLAUDE.md | Wrong folder, missing required fields, wrong naming convention | Always read CLAUDE.md first for vault-specific rules |
| Using Markdown links for vault images | Image won't render in Obsidian reading view | Use `![[image.png]]` embed syntax |

---

## Decision Tree: Which Approach?

```
Need to display/navigate notes? → Create a .base file with filters
Need to create a note? → Check CLAUDE.md → use template → place in correct folder
Need to link content? → Is it in the vault? → [[wikilink]] : [text](url)
Need to embed content? → ![[Note]] or ![[image.png|width]]
Need automation/search? → Use obsidian CLI commands
Need visual layout? → Create a .canvas file
```

---

## Validation Checklist

Before finalizing any vault operation:

- [ ] Frontmatter is valid YAML with no syntax errors
- [ ] All required properties are present per vault CLAUDE.md
- [ ] Internal links use `[[wikilinks]]`, external links use `[text](url)`
- [ ] Note is placed in the correct folder per vault conventions
- [ ] Tags follow rules: letters, numbers (not first char), underscores, hyphens, forward slashes
- [ ] `.base` files have valid YAML with no unquoted special characters
- [ ] `.canvas` files have valid JSON with unique IDs and valid edge references
- [ ] Templates use `{{title}}` and `{{date:FORMAT}}` placeholders

## References

- [Obsidian Flavored Markdown](references/MARKDOWN.md)
- [Bases Syntax & Formulas](references/BASES.md)
- [Canvas (JSON Canvas)](references/CANVAS.md)
- [CLI Command Reference](references/CLI.md)
- [Properties & Frontmatter](references/PROPERTIES.md)
- [Obsidian Help](https://help.obsidian.md)
