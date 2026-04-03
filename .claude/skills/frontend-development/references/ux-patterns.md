# UX Patterns: i18n, Typography, and Micro-Interactions

---

## i18n / RTL / Logical Properties

```css
/* Use logical properties for RTL support */
.card {
  /* Physical (breaks in RTL) */
  margin-left: 1rem;
  padding-right: 2rem;
  border-left: 3px solid blue;
  text-align: left;

  /* Logical (works in LTR and RTL) */
  margin-inline-start: 1rem;
  padding-inline-end: 2rem;
  border-inline-start: 3px solid blue;
  text-align: start;
}

/* Logical property mapping */
/* left    -> inline-start    right  -> inline-end */
/* top     -> block-start     bottom -> block-end */
/* width   -> inline-size     height -> block-size */
```

---

## Typography Micro-Rules

- **Curly quotes**: Use `&lsquo;` / `&rsquo;` / `&ldquo;` / `&rdquo;` (or CSS `quotes` property) instead of straight quotes in editorial content
- **Ellipsis**: Use `&hellip;` (...) not three dots (...)
- **`text-wrap: balance`**: Apply to headings for even line distribution. `text-wrap: pretty` for body text to avoid orphans
- **`font-variant-numeric: tabular-nums`**: Use on numbers in tables/price lists for aligned columns
- **Non-breaking spaces**: Use `&nbsp;` between number and unit (e.g., "10&nbsp;kg"), and between short prepositions and following words in headings

---

## Touch and Interaction

- **`touch-action: manipulation`**: Removes 300ms tap delay on touch devices without disabling pinch-zoom. Apply to interactive elements
- **`-webkit-tap-highlight-color: transparent`**: Remove blue highlight flash on mobile taps. Replace with your own `:active` style
- **`overscroll-behavior: contain`**: Prevents scroll chaining -- when a scrollable element reaches the end, the parent doesn't scroll. Essential for modals, drawers, dropdowns

---

## Form Micro-Rules

- **Disable spellcheck on code/email inputs**: `spellCheck={false}` or `spellcheck="false"` on code inputs, email fields, URLs
- **Placeholders with ellipsis**: Use "Search..." not "Search" (communicates it's a text input)
- **Warn before navigation with unsaved changes**: Use `beforeunload` event or framework-specific route guards. Show confirmation dialog

---

## Content/Copy Style

- **Active voice for UI copy**: "Delete this item?" not "This item will be deleted"
- **Specific button labels**: "Save changes" not "Submit". "Delete account" not "OK". The label should tell the user what will happen
