# Accessibility (WCAG 2.2 AA)

## Table of Contents

- [Keyboard Navigation](#keyboard-navigation)
- [ARIA Quick Reference](#aria-quick-reference)
- [WCAG 2.2 New Success Criteria](#wcag-22--new-success-criteria)
- [Target Size and Focus Visibility CSS](#target-size-and-focus-visibility-css)
- [Form Accessibility](#form-accessibility)
- [Semantic HTML Element Selection](#semantic-html-element-selection)

---

## Keyboard Navigation

```tsx
// Every interactive element must be keyboard accessible
// Tab order: follows DOM order. Use tabindex only for custom widgets

// Skip link (first element in body)
<a href="#main-content" className="sr-only focus:not-sr-only focus:absolute focus:p-4 focus:bg-white focus:z-50">
  Skip to main content
</a>

// Focus trap for modals
function Modal({ isOpen, onClose, children }) {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!isOpen) return;
    const focusableEls = ref.current?.querySelectorAll(
      'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
    );
    const firstEl = focusableEls?.[0] as HTMLElement;
    const lastEl = focusableEls?.[focusableEls.length - 1] as HTMLElement;

    firstEl?.focus();

    function handleTab(e: KeyboardEvent) {
      if (e.key !== 'Tab') return;
      if (e.shiftKey && document.activeElement === firstEl) {
        e.preventDefault();
        lastEl?.focus();
      } else if (!e.shiftKey && document.activeElement === lastEl) {
        e.preventDefault();
        firstEl?.focus();
      }
    }

    document.addEventListener('keydown', handleTab);
    return () => document.removeEventListener('keydown', handleTab);
  }, [isOpen]);

  return isOpen ? (
    <div role="dialog" aria-modal="true" aria-label="Modal title" ref={ref}>
      {children}
      <button onClick={onClose}>Close</button>
    </div>
  ) : null;
}
```

---

## ARIA Quick Reference

| Pattern | ARIA | When |
|---|---|---|
| Loading state | `aria-busy="true"` | Content is updating |
| Live region | `aria-live="polite"` | Content updates (alerts, toasts) |
| Error message | `aria-invalid="true"` + `aria-describedby` | Form validation errors |
| Expanded/collapsed | `aria-expanded="true/false"` | Accordions, dropdowns |
| Selected | `aria-selected="true"` | Tabs, listbox items |
| Current page | `aria-current="page"` | Navigation highlight |
| Disabled | `aria-disabled="true"` | Non-interactive disabled elements |
| Count | `aria-label="Cart (3 items)"` | Badges, counts |
| Required | `aria-required="true"` or `required` | Form fields |

**Rule**: Use native HTML elements first. ARIA is a last resort. `<button>` is always better than `<div role="button">`.

---

## WCAG 2.2 -- New Success Criteria

| Criterion | Level | Requirement |
|---|---|---|
| **2.4.11 Focus Not Obscured (Minimum)** | AA | When an element receives keyboard focus, it must be at least partially visible. Sticky headers, footers, and cookie banners must not fully cover the focused element |
| **2.4.12 Focus Not Obscured (Enhanced)** | AAA | Focused element must be *fully* visible (not just partially) |
| **2.5.7 Dragging Movements** | AA | Any drag-and-drop interaction must also be achievable with simple pointer actions (click, tap). Provide click-to-move or arrow buttons as alternatives to drag sorting |
| **2.5.8 Target Size (Minimum)** | AA | Interactive targets must be at least 24x24 CSS pixels, or have sufficient spacing from adjacent targets. Inline links in text are exempt |
| **3.2.6 Consistent Help** | A | Help mechanisms (contact info, chat, FAQ link) must appear in the same relative location across pages |
| **3.3.7 Redundant Entry** | A | Don't ask users to re-enter previously submitted information in the same session. Auto-populate or offer selection |

---

## Target Size and Focus Visibility CSS

```css
/* 2.5.8 Target Size — ensure minimum 24x24px touch targets */
button, a, input[type="checkbox"], input[type="radio"] {
  min-width: 24px;
  min-height: 24px;
}

/* Better: 44x44px for comfortable mobile tapping (AAA) */
.touch-target {
  min-width: 44px;
  min-height: 44px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

/* 2.4.11 Focus Not Obscured — scroll focused element into view above sticky elements */
:focus-visible {
  scroll-margin-top: 80px;   /* Height of sticky header */
  scroll-margin-bottom: 60px; /* Height of sticky footer */
}
```

---

## Form Accessibility

```tsx
<form onSubmit={handleSubmit} noValidate>
  <div>
    <label htmlFor="email">Email address</label>
    <input
      id="email"
      type="email"
      name="email"
      required
      aria-required="true"
      aria-invalid={errors.email ? 'true' : undefined}
      aria-describedby={errors.email ? 'email-error' : 'email-hint'}
      autoComplete="email"
    />
    <p id="email-hint" className="text-sm text-gray-500">
      We'll never share your email
    </p>
    {errors.email && (
      <p id="email-error" role="alert" className="text-sm text-red-600">
        {errors.email}
      </p>
    )}
  </div>
</form>
```

---

## Semantic HTML Element Selection

```html
<!-- BAD — div soup -->
<div class="header">
  <div class="nav">
    <div class="link" onclick="...">Home</div>
  </div>
</div>
<div class="main">
  <div class="article">
    <div class="title">...</div>
  </div>
</div>

<!-- GOOD — semantic elements -->
<header>
  <nav aria-label="Main navigation">
    <a href="/">Home</a>
  </nav>
</header>
<main>
  <article>
    <h1>Article Title</h1>
    <time datetime="2024-06-15">June 15, 2024</time>
    <p>Content...</p>
  </article>
</main>
<footer>
  <nav aria-label="Footer navigation">...</nav>
</footer>
```

### Element Selection Cheat Sheet

| Need | Element | NOT This |
|---|---|---|
| Page section | `<section>` with heading | `<div class="section">` |
| Independent content | `<article>` | `<div class="article">` |
| Navigation | `<nav aria-label="...">` | `<div class="nav">` |
| List of items | `<ul>` / `<ol>` | Nested `<div>`s |
| Key-value pairs | `<dl>` / `<dt>` / `<dd>` | Table or custom layout |
| Button (action) | `<button type="button">` | `<div onclick>` or `<a href="#">` |
| Link (navigation) | `<a href="/path">` | `<button>` for navigation |
| Input label | `<label for="id">` | Placeholder as label |
| Form group | `<fieldset>` + `<legend>` | `<div>` wrapper |
| Figure + caption | `<figure>` + `<figcaption>` | `<div>` + `<p>` |
| Time | `<time datetime="...">` | Plain text |
| Abbreviation | `<abbr title="...">` | Tooltip div |
