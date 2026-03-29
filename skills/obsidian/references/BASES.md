# Obsidian Bases Reference

Bases are `.base` files containing YAML that create dynamic database-like views of notes.

## Table of Contents

- [Schema](#schema)
- [Filter Syntax](#filter-syntax)
- [Properties](#properties)
- [Formula Syntax](#formula-syntax)
- [View Types](#view-types)
- [Default Summary Formulas](#default-summary-formulas)
- [Embedding Bases](#embedding-bases)
- [Complete Examples](#complete-examples)
- [YAML Quoting Rules](#yaml-quoting-rules)
- [Troubleshooting](#troubleshooting)

## Schema

```yaml
# Global filters apply to ALL views
filters:
  and: []    # All conditions must be true
  or: []     # Any condition can be true
  not: []    # Exclude matching items

# Computed properties
formulas:
  formula_name: 'expression'

# Display names for properties
properties:
  property_name:
    displayName: "Display Name"
  formula.formula_name:
    displayName: "Formula Display Name"

# Custom summary formulas
summaries:
  custom_summary_name: 'values.mean().round(3)'

# One or more views
views:
  - type: table | cards | list | map
    name: "View Name"
    limit: 10                    # Optional: limit results
    groupBy:                     # Optional: group results
      property: property_name
      direction: ASC | DESC
    filters:                     # View-specific filters (override global)
      and: []
    order:                       # Properties to display in order
      - file.name
      - property_name
      - formula.formula_name
    sort:                        # Sort order
      - column: property_name
        direction: ASC | DESC
    summaries:                   # Map properties to summary formulas
      property_name: Sum
    columnSize:                  # Column widths (table view)
      file.name: 300
```

## Filter Syntax

### Filter Structure

```yaml
# Single filter
filters: 'status == "done"'

# AND - all conditions must be true
filters:
  and:
    - 'status == "done"'
    - 'priority > 3'

# OR - any condition can be true
filters:
  or:
    - file.hasTag("book")
    - file.hasTag("article")

# NOT - exclude matching items
filters:
  not:
    - file.hasTag("archived")

# Nested
filters:
  or:
    - file.hasTag("tag")
    - and:
        - file.hasTag("book")
        - file.hasLink("Textbook")
    - not:
        - file.hasTag("book")
```

### Filter Operators

| Operator | Description |
|----------|-------------|
| `==` | equals |
| `!=` | not equal |
| `>`, `<`, `>=`, `<=` | comparison |
| `&&` | logical and |
| `\|\|` | logical or |
| `!` | logical not |

### Filter Functions

| Function | Description |
|----------|-------------|
| `file.inFolder("path")` | File is in folder or subfolder |
| `file.hasTag("tag")` | File has tag |
| `file.hasLink("Note")` | File links to note |
| `file.hasProperty("name")` | File has property |

## Properties

### Three Types

1. **Note properties** — from frontmatter: `author` or `note.author`
2. **File properties** — file metadata: `file.name`, `file.mtime`, etc.
3. **Formula properties** — computed: `formula.my_formula`

### File Properties

| Property | Type | Description |
|----------|------|-------------|
| `file.name` | String | File name |
| `file.basename` | String | File name without extension |
| `file.path` | String | Full path to file |
| `file.folder` | String | Parent folder path |
| `file.ext` | String | File extension |
| `file.size` | Number | File size in bytes |
| `file.ctime` | Date | Created time |
| `file.mtime` | Date | Modified time |
| `file.tags` | List | All tags in file |
| `file.links` | List | Internal links in file |
| `file.backlinks` | List | Files linking to this file |
| `file.embeds` | List | Embeds in the note |
| `file.properties` | Object | All frontmatter properties |

### The `this` Keyword

- In main content area: refers to the base file itself
- When embedded: refers to the embedding file
- In sidebar: refers to the active file in main content

## Formula Syntax

```yaml
formulas:
  # Arithmetic
  total: "price * quantity"

  # Conditional
  status_icon: 'if(done, "✅", "⏳")'

  # String formatting
  formatted: 'if(price, price.toFixed(2) + " dollars")'

  # Date formatting
  created: 'file.ctime.format("YYYY-MM-DD")'

  # Days since created
  days_old: '(now() - file.ctime).days'

  # Days until due (with null check)
  days_until_due: 'if(due_date, (date(due_date) - today()).days, "")'
```

### Key Functions

| Function | Signature | Description |
|----------|-----------|-------------|
| `date()` | `date(string): date` | Parse string to date |
| `now()` | `now(): date` | Current date and time |
| `today()` | `today(): date` | Current date (time = 00:00:00) |
| `if()` | `if(cond, true, false?)` | Conditional |
| `duration()` | `duration(string): duration` | Parse duration |
| `file()` | `file(path): file` | Get file object |
| `link()` | `link(path, display?): Link` | Create a link |
| `image()` | `image(path): image` | Create image |
| `icon()` | `icon(name): icon` | Lucide icon |
| `min()`, `max()` | `(n1, n2, ...): number` | Min/max |

### Duration Type

Subtracting dates returns a **Duration** (not a number). Access `.days`, `.hours`, `.minutes`, `.seconds`, `.milliseconds` to get a number.

```yaml
# CORRECT
"(now() - file.ctime).days"
"(date(due_date) - today()).days.round(0)"

# WRONG — Duration doesn't support .round() directly
# "(now() - file.ctime).round(0)"
```

### Date Arithmetic

```yaml
# Units: y/year/years, M/month/months, d/day/days, w/week/weeks,
#         h/hour/hours, m/minute/minutes, s/second/seconds
"now() + \"1 day\""
"today() + \"7d\""
```

### String Functions

`contains()`, `startsWith()`, `endsWith()`, `lower()`, `trim()`, `replace()`, `split()`, `slice()`, `length`

### Number Functions

`abs()`, `ceil()`, `floor()`, `round(digits?)`, `toFixed(precision)`

### List Functions

`contains()`, `filter()`, `map()`, `reduce()`, `join()`, `sort()`, `unique()`, `flat()`, `length`

## View Types

### Table

```yaml
views:
  - type: table
    name: "My Table"
    order:
      - file.name
      - status
    summaries:
      price: Sum
```

### Cards

```yaml
views:
  - type: cards
    name: "Gallery"
    order:
      - cover_image
      - file.name
      - description
```

### List

```yaml
views:
  - type: list
    name: "Simple List"
    order:
      - file.name
      - status
```

### Map

Requires latitude/longitude properties and the Maps community plugin.

## Default Summary Formulas

| Name | Input Type | Description |
|------|------------|-------------|
| `Average` | Number | Mathematical mean |
| `Min` / `Max` | Number | Smallest / largest |
| `Sum` | Number | Sum of all |
| `Range` | Number | Max - Min |
| `Median` | Number | Mathematical median |
| `Stddev` | Number | Standard deviation |
| `Earliest` / `Latest` | Date | Earliest / latest date |
| `Checked` / `Unchecked` | Boolean | Count true / false |
| `Empty` / `Filled` | Any | Count empty / non-empty |
| `Unique` | Any | Count unique values |

## Embedding Bases

```markdown
![[MyBase.base]]
![[MyBase.base#View Name]]
```

## Complete Examples

### Task Tracker

```yaml
filters:
  and:
    - file.hasTag("task")
    - 'file.ext == "md"'

formulas:
  days_until_due: 'if(due, (date(due) - today()).days, "")'
  is_overdue: 'if(due, date(due) < today() && status != "done", false)'
  priority_label: 'if(priority == 1, "🔴 High", if(priority == 2, "🟡 Medium", "🟢 Low"))'

views:
  - type: table
    name: "Active Tasks"
    filters:
      and:
        - 'status != "done"'
    order:
      - file.name
      - status
      - formula.priority_label
      - due
      - formula.days_until_due
    groupBy:
      property: status
      direction: ASC
```

### Reading List

```yaml
filters:
  or:
    - file.hasTag("book")
    - file.hasTag("article")

formulas:
  reading_time: 'if(pages, (pages * 2).toString() + " min", "")'
  status_icon: 'if(status == "reading", "📖", if(status == "done", "✅", "📚"))'

views:
  - type: cards
    name: "Library"
    order:
      - cover
      - file.name
      - author
      - formula.status_icon
```

### Daily Notes Index

```yaml
filters:
  and:
    - file.inFolder("daily")
    - '/^\d{4}-\d{2}-\d{2}$/.matches(file.basename)'

formulas:
  word_estimate: '(file.size / 5).round(0)'
  day_of_week: 'date(file.basename).format("dddd")'

views:
  - type: table
    name: "Recent Notes"
    limit: 30
    order:
      - file.name
      - formula.day_of_week
      - formula.word_estimate
      - file.mtime
```

## YAML Quoting Rules

- Use **single quotes** for formulas containing double quotes: `'if(done, "Yes", "No")'`
- Use **double quotes** for simple strings: `"My View Name"`
- Strings with `:`, `{`, `}`, `[`, `]`, `#`, `?`, `|`, `>`, `=`, `!` must be quoted

## Troubleshooting

**Duration math without field access:** Always access `.days`, `.hours`, etc. before calling number methods.

**Missing null checks:** Use `if()` to guard properties that may not exist on all notes.

**Undefined formulas:** Every `formula.X` in `order` must have a matching entry in `formulas`.

## References

- [Bases Syntax](https://help.obsidian.md/bases/syntax)
- [Functions](https://help.obsidian.md/bases/functions)
- [Views](https://help.obsidian.md/bases/views)
