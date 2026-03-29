# Properties (Frontmatter) Reference

Properties use YAML frontmatter at the start of a note:

```yaml
---
title: My Note Title
date: 2024-01-15
tags:
  - project
  - important
aliases:
  - My Note
  - Alternative Name
cssclasses:
  - custom-class
status: in-progress
rating: 4.5
completed: false
due: 2024-02-01T14:30:00
---
```

## Property Types

| Type | Example |
|------|---------|
| Text | `title: My Title` |
| Number | `rating: 4.5` |
| Checkbox | `completed: true` |
| Date | `date: 2024-01-15` |
| Date & Time | `due: 2024-01-15T14:30:00` |
| List | `tags: [one, two]` or YAML list |
| Links | `related: "[[Other Note]]"` |

## Default Properties

| Property | Purpose |
|----------|---------|
| `tags` | Searchable labels, shown in graph view |
| `aliases` | Alternative names for the note (used in link suggestions) |
| `cssclasses` | CSS classes applied to the note in reading/editing view |

## Tag Syntax Rules

Tags can contain:
- Letters (any language)
- Numbers (NOT as first character)
- Underscores `_`
- Hyphens `-`
- Forward slashes `/` (for nesting)

```yaml
# In frontmatter
tags:
  - project
  - nested/subtag

# Inline in content
#tag #nested/tag #tag-with-dashes
```

## YAML Quoting Rules

- Strings with special characters (`:`, `#`, `[`, `]`, `{`, `}`, etc.) must be quoted
- Links in frontmatter must be quoted: `related: "[[Other Note]]"`
- Lists can use array syntax `[a, b]` or block syntax with `-`

```yaml
# Both are valid
tags: [project, active]
tags:
  - project
  - active
```
