---
name: frontend-development
description: >-
  Frontend development expertise — CSS, accessibility, responsive design, performance,
  and UX. Use when building responsive layouts, implementing accessibility (WCAG 2.2),
  writing modern CSS (container queries, :has(), subgrid, layers, nesting, @scope,
  anchor positioning, scroll-driven animations), designing CSS architecture
  (utility-first, CSS modules, Tailwind v4), optimizing Core Web Vitals
  (LCP, CLS, INP), implementing design tokens and systems, handling forms with
  validation, implementing animations and transitions (view transitions, @starting-style),
  writing semantic HTML, native dialog/popover elements, keyboard navigation,
  screen reader support, responsive images, dark mode (light-dark(), color-mix()),
  i18n/l10n patterns, or reviewing frontend code quality.
  Triggers: CSS, accessibility, a11y, WCAG, responsive, mobile-first, Tailwind,
  design system, design tokens, Core Web Vitals, LCP, CLS, INP, animation,
  semantic HTML, ARIA, screen reader, keyboard navigation, form validation,
  dark mode, i18n, container query, subgrid, CSS layers, CSS nesting, @scope,
  anchor positioning, popover, dialog, view transitions, scroll-driven animations,
  @starting-style, color-mix, light-dark, @property, Tailwind v4.
---

# Frontend Development Skill

Build interfaces that are accessible to everyone, responsive on every device,
performant on slow networks, and beautiful by design. HTML semantics first,
CSS layout second, JavaScript only when needed.

---

## Core Principles

| Principle | Meaning |
|---|---|
| **Semantic HTML first** | The right element for the right content. No div soup |
| **Progressive enhancement** | Works without JS. Enhanced with JS |
| **Mobile-first** | Design for smallest screen, enhance upward |
| **Accessibility is not optional** | WCAG 2.2 AA minimum. Test with keyboard and screen readers |
| **Performance budgets** | LCP <2.5s, INP <200ms, CLS <0.1 |
| **CSS > JavaScript for UI** | Animations, layouts, dark mode — CSS first |

---

## Decision Trees

### Choosing a Layout Method

```
Need to arrange items?
├─ One-dimensional (row OR column)?
│  └─ Flexbox
├─ Two-dimensional (rows AND columns)?
│  ├─ Child items need to align with parent grid? → CSS Subgrid
│  └─ Otherwise → CSS Grid
├─ Text wrapping around element?
│  └─ CSS Float (still valid for this use case)
└─ Overlapping / layered elements?
   └─ CSS Grid with grid-area overlap or position: absolute
```

### Choosing a Styling Approach

```
Project type?
├─ Design-system-heavy / component library?
│  └─ CSS Modules or vanilla-extract (type-safe, scoped)
├─ Rapid prototyping / marketing pages?
│  └─ Tailwind CSS v4 (utility-first, fast iteration)
├─ Small project / few custom styles?
│  └─ Native CSS with custom properties + layers
└─ Large app with strict design tokens?
   └─ Design tokens (CSS custom properties) + CSS layers + component CSS
```

### Choosing a Component Pattern

```
Interactive element needed?
├─ Navigates to another page/URL? → <a href>
├─ Triggers an action (submit, toggle, delete)? → <button>
├─ Shows additional info on hover/click? → Popover API (popover attribute)
├─ Modal dialog blocking interaction? → <dialog> with showModal()
├─ Expandable content section? → <details>/<summary>
└─ Custom dropdown/select?
   ├─ Simple list of options? → Native <select> (best a11y)
   └─ Rich content in options? → Combobox pattern (ARIA 1.2)
```

---

## Semantic HTML

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

---

## Accessibility (WCAG 2.2 AA)

### Keyboard Navigation

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

### ARIA Quick Reference

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

### WCAG 2.2 — New Success Criteria

| Criterion | Level | Requirement |
|---|---|---|
| **2.4.11 Focus Not Obscured (Minimum)** | AA | When an element receives keyboard focus, it must be at least partially visible. Sticky headers, footers, and cookie banners must not fully cover the focused element |
| **2.4.12 Focus Not Obscured (Enhanced)** | AAA | Focused element must be *fully* visible (not just partially) |
| **2.5.7 Dragging Movements** | AA | Any drag-and-drop interaction must also be achievable with simple pointer actions (click, tap). Provide click-to-move or arrow buttons as alternatives to drag sorting |
| **2.5.8 Target Size (Minimum)** | AA | Interactive targets must be at least 24x24 CSS pixels, or have sufficient spacing from adjacent targets. Inline links in text are exempt |
| **3.2.6 Consistent Help** | A | Help mechanisms (contact info, chat, FAQ link) must appear in the same relative location across pages |
| **3.3.7 Redundant Entry** | A | Don't ask users to re-enter previously submitted information in the same session. Auto-populate or offer selection |

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

### Form Accessibility

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

## Modern CSS Patterns

### Container Queries

```css
/* Size-based — respond to container size, not viewport */
.card-container {
  container-type: inline-size;
  container-name: card;
}

@container card (min-width: 400px) {
  .card { display: grid; grid-template-columns: 200px 1fr; }
}

@container card (max-width: 399px) {
  .card { display: flex; flex-direction: column; }
}
```

### `:has()` Selector

```css
/* Parent selection — style parent based on child */
.card:has(img) {
  grid-template-rows: auto 1fr; /* Only add image row when image exists */
}

/* Form validation states */
.field:has(input:invalid) {
  border-color: var(--color-error);
}
.field:has(input:valid) {
  border-color: var(--color-success);
}

/* Previous sibling selection */
h2:has(+ p) {
  margin-bottom: 0.5rem; /* Tighter spacing when followed by paragraph */
}

/* Conditional layout */
.nav:has(> .nav-item:nth-child(n+5)) {
  /* Switch to hamburger menu when 5+ items */
  flex-wrap: wrap;
}

/* Quantity queries */
.grid:has(> :nth-child(4)) {
  grid-template-columns: repeat(2, 1fr); /* 2-col when 4+ items */
}
```

### CSS Subgrid

```css
/* Subgrid — child inherits parent's grid tracks */
.card-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 2rem;
}

.card {
  display: grid;
  grid-template-rows: subgrid; /* Inherit row tracks from parent */
  grid-row: span 3; /* Card spans 3 rows: image, title, content */
}

/* Result: all card titles align across columns regardless of image height */

/* Named grid areas with subgrid */
.page {
  display: grid;
  grid-template-columns: [full-start] 1fr [content-start] minmax(0, 60ch) [content-end] 1fr [full-end];
}

.page > * {
  grid-column: content;
}

.page > .full-bleed {
  grid-column: full;
}
```

### CSS Layers (Cascade Control)

```css
/* Control specificity with layers */
@layer reset, base, components, utilities;

@layer reset {
  *, *::before, *::after { box-sizing: border-box; margin: 0; }
}

/* Import Tailwind into a layer (lower specificity) */
@import "tailwindcss" layer(utilities);

/* Your component styles always win over utilities */
@layer components {
  .btn { /* always overrides Tailwind */ }
}
```

### Native CSS Nesting

```css
/* Fully supported in all browsers — no preprocessor needed */
.card {
  padding: 1rem;
  background: var(--surface);

  & h2 {
    font-size: 1.25rem;
    margin-bottom: 0.5rem;
  }

  & p {
    color: var(--text-muted);
  }

  /* Nesting with pseudo-classes and pseudo-elements */
  &:hover {
    box-shadow: 0 4px 12px rgb(0 0 0 / 0.1);
  }

  &::before {
    content: '';
    display: block;
  }

  /* Nesting media queries */
  @media (min-width: 768px) {
    padding: 2rem;
  }
}

/* Compound selectors — use & for clarity */
.nav {
  & .link {
    color: var(--text);

    &.active {
      font-weight: bold;
    }
  }
}
```

### CSS `@scope` Rule

```css
/* Scope styles to a subtree — no class naming conventions needed */
@scope (.card) {
  h2 { font-size: 1.25rem; }
  p  { color: gray; }
  a  { color: var(--accent); }
}

/* "Donut scope" — scope with a lower boundary (exclude nested regions) */
@scope (.article) to (.comments) {
  /* Styles apply inside .article but NOT inside .comments */
  p { line-height: 1.8; }
  img { border-radius: 8px; }
}

/* Inline scoping — <style> inside a component scopes automatically */
/* <div class="widget">
  <style>
    @scope {
      p { color: var(--widget-text); }
    }
  </style>
  <p>Scoped to this widget</p>
</div> */

/* :scope pseudo-class — refers to the scope root */
@scope (.card) {
  :scope { border: 1px solid var(--border); }
  :scope > h2 { margin-top: 0; }
}
```

### CSS Anchor Positioning

```css
/* Define an anchor */
.trigger {
  anchor-name: --my-anchor;
}

/* Position an element relative to the anchor */
.tooltip {
  position: fixed;
  position-anchor: --my-anchor;

  /* Place below the anchor, centered horizontally */
  top: anchor(bottom);
  justify-self: anchor-center;
  margin-top: 8px;
}

/* Fallback positions with @position-try */
@position-try --flip-above {
  bottom: anchor(top);
  top: auto;
  margin-top: 0;
  margin-bottom: 8px;
}

.tooltip {
  position-try-fallbacks: --flip-above;
}

/* Works with Popover API — implicit anchor between invoker and popover */
.my-popover {
  margin: 0;
  inset: auto;
  position-area: top;     /* Shorthand for anchored positioning */
}
```

### `@starting-style` for Entry Animations

```css
/* Animate elements entering the DOM (from display: none) */
dialog[open] {
  opacity: 1;
  transform: scale(1);
  transition: opacity 0.3s ease, transform 0.3s ease,
              display 0.3s ease allow-discrete;

  @starting-style {
    opacity: 0;
    transform: scale(0.95);
  }
}

/* Works with Popover API */
[popover]:popover-open {
  opacity: 1;
  translate: 0 0;
  transition: opacity 0.4s, translate 0.4s, display 0.4s allow-discrete;

  @starting-style {
    opacity: 0;
    translate: 0 10px;
  }
}

/* Exit animation (overlay + allow-discrete needed for display: none) */
[popover] {
  opacity: 0;
  translate: 0 10px;
  transition: opacity 0.3s, translate 0.3s,
              overlay 0.3s allow-discrete,
              display 0.3s allow-discrete;
}
```

### Scroll-Driven Animations

```css
/* Progress bar that fills as user scrolls the page */
.progress-bar {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 4px;
  background: var(--accent);
  transform-origin: left;
  animation: grow-progress linear;
  animation-timeline: scroll();     /* Tied to scroll position */
}

@keyframes grow-progress {
  from { transform: scaleX(0); }
  to   { transform: scaleX(1); }
}

/* view() — animate when element enters/exits viewport */
.reveal {
  animation: fade-in linear both;
  animation-timeline: view();       /* Based on element visibility */
  animation-range: entry 0% entry 100%;
}

@keyframes fade-in {
  from { opacity: 0; translate: 0 50px; }
  to   { opacity: 1; translate: 0 0; }
}

/* scroll() parameters: scroll(root | nearest | self, block | inline) */
/* view() parameters:  view(block | inline, <inset>) */
```

**Note**: Always declare `animation-timeline` after any `animation` shorthand, since the shorthand resets it to `auto`.

### View Transitions API

```css
/* MPA view transitions — opt in via CSS */
@view-transition {
  navigation: auto;
}

/* Name elements that should animate between views */
.hero-image {
  view-transition-name: hero;
}

.page-title {
  view-transition-name: title;
}

/* Customize the transition animation */
::view-transition-old(hero) {
  animation: fade-out 0.3s ease;
}

::view-transition-new(hero) {
  animation: fade-in 0.3s ease;
}
```

```tsx
// SPA view transitions — use document.startViewTransition()
function navigateTo(newContent: HTMLElement) {
  if (!document.startViewTransition) {
    // Fallback: just swap content
    updateDOM(newContent);
    return;
  }

  document.startViewTransition(() => {
    updateDOM(newContent);
  });
}

// Each view-transition-name must be unique on the page at any given time
// Before and after the callback, exactly one element per name must exist
```

### `color-mix()` Function

```css
/* Mix two colors in any color space */
.btn-hover {
  /* 80% brand color, 20% black — darken effect */
  background: color-mix(in oklab, var(--brand) 80%, black);
}

.surface-subtle {
  /* 10% of the brand color mixed with white */
  background: color-mix(in srgb, var(--brand) 10%, white);
}

/* Create semi-transparent variants without opacity */
.overlay {
  background: color-mix(in srgb, var(--text) 50%, transparent);
}

/* Generate tints and shades from a single design token */
:root {
  --primary: #3b82f6;
  --primary-light: color-mix(in oklab, var(--primary) 60%, white);
  --primary-dark:  color-mix(in oklab, var(--primary) 60%, black);
}
```

### `light-dark()` Function for Dark Mode

```css
/* Requires color-scheme declaration */
:root {
  color-scheme: light dark;
}

/* Single declaration handles both modes — no media query needed */
:root {
  --bg:      light-dark(#ffffff, #0a0a0a);
  --text:    light-dark(#111111, #eeeeee);
  --border:  light-dark(#e5e5e5, #333333);
  --accent:  light-dark(DeepPink, HotPink);
  --surface: light-dark(#f5f5f5, #1a1a1a);
}

body {
  background-color: var(--bg);
  color: var(--text);
}

/* Combine with color-mix() for derived values */
.card {
  background: light-dark(
    color-mix(in oklab, var(--accent) 5%, white),
    color-mix(in oklab, var(--accent) 10%, black)
  );
}
```

### `@property` for Custom Property Types and Animations

```css
/* Register custom properties with types — enables smooth animation */
@property --hue {
  syntax: '<number>';
  inherits: false;
  initial-value: 220;
}

@property --progress {
  syntax: '<percentage>';
  inherits: false;
  initial-value: 0%;
}

/* Now custom properties can be animated/transitioned */
.gradient-shift {
  --hue: 220;
  background: hsl(var(--hue) 80% 55%);
  transition: --hue 0.6s ease;
}

.gradient-shift:hover {
  --hue: 320;  /* Smoothly transitions the hue */
}

/* Animate a gradient stop position */
.progress-fill {
  --progress: 0%;
  background: linear-gradient(90deg, var(--accent) var(--progress), transparent var(--progress));
  transition: --progress 0.4s ease;
}
```

### `field-sizing: content`

```css
/* Auto-size textarea to content */
textarea {
  field-sizing: content;
  min-height: 3lh;    /* At least 3 lines */
  max-height: 10lh;   /* Cap at 10 lines */
}
```

### Viewport Units (`dvh`/`svh`/`lvh`)

```css
/* dvh = dynamic viewport height — accounts for mobile URL bar show/hide */
/* svh = small viewport height  — smallest possible viewport (URL bar visible) */
/* lvh = large viewport height  — largest possible viewport (URL bar hidden) */

/* Use dvh for full-screen hero sections on mobile */
.hero {
  min-height: 100dvh;  /* Always fills the visible area */
}

/* svh for elements that must never be clipped */
.modal-overlay {
  height: 100svh;  /* Never extends beyond visible area */
}

/* Fallback pattern for older browsers */
.full-screen {
  min-height: 100vh;      /* Fallback */
  min-height: 100dvh;     /* Modern browsers */
}

/* Also available: dvw, svw, lvw for width, and dvi, svi, lvi for inline axis */
```

### Popover API

```html
<!-- Native popover — no JavaScript required for basic toggle -->
<button popovertarget="my-popover">Open Menu</button>
<div id="my-popover" popover>
  <p>Popover content — click outside to dismiss</p>
</div>

<!-- Manual popover — does not auto-dismiss on outside click -->
<button popovertarget="tooltip" popovertargetaction="toggle">Info</button>
<div id="tooltip" popover="manual">Persistent tooltip</div>

<!-- Popover actions: toggle (default), show, hide -->
<button popovertarget="details" popovertargetaction="show">Show</button>
<button popovertarget="details" popovertargetaction="hide">Hide</button>
```

```css
/* Style the popover and its backdrop */
[popover] {
  border: 1px solid var(--border);
  border-radius: 8px;
  padding: 1rem;
  box-shadow: 0 8px 32px rgb(0 0 0 / 0.15);
}

[popover]::backdrop {
  background: rgb(0 0 0 / 0.3);
}
```

**Benefits**: Built-in top layer (no z-index issues), light-dismiss, focus management, accessibility. Replaces many custom dropdown/tooltip/menu implementations.

### Native `<dialog>` Element

```html
<!-- Modal dialog — blocks interaction with rest of page -->
<dialog id="confirm-dialog">
  <h2>Confirm Action</h2>
  <p>Are you sure you want to delete this item?</p>
  <form method="dialog">
    <button value="cancel">Cancel</button>
    <button value="confirm">Confirm</button>
  </form>
</dialog>
```

```tsx
// Open as modal (with backdrop, focus trap, Escape to close)
const dialog = document.getElementById('confirm-dialog') as HTMLDialogElement;
dialog.showModal();

// Listen for close
dialog.addEventListener('close', () => {
  console.log(dialog.returnValue); // "cancel" or "confirm"
});
```

```css
dialog {
  border: none;
  border-radius: 12px;
  padding: 2rem;
  max-width: 480px;
  width: 90vw;
}

dialog::backdrop {
  background: rgb(0 0 0 / 0.5);
  backdrop-filter: blur(4px);
}
```

**Prefer `<dialog>` over custom modals**: It provides native focus trapping, Escape key handling, top-layer rendering, and `::backdrop` styling. No JavaScript focus-trap library needed.

### Responsive Design — Mobile First

```css
/* Base: mobile (no media query needed) */
.grid { display: flex; flex-direction: column; gap: 1rem; }

/* Tablet */
@media (min-width: 768px) {
  .grid { display: grid; grid-template-columns: repeat(2, 1fr); }
}

/* Desktop */
@media (min-width: 1024px) {
  .grid { grid-template-columns: repeat(3, 1fr); }
}

/* Large desktop */
@media (min-width: 1280px) {
  .grid { grid-template-columns: repeat(4, 1fr); }
}

/* Reduced motion preference */
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}

/* Dark mode (system preference) */
@media (prefers-color-scheme: dark) {
  :root { --bg: #0a0a0a; --text: #ededed; }
}
```

---

## Design Tokens / System Architecture

```css
/* Token taxonomy: Primitive -> Semantic -> Component */

/* Primitive tokens (raw values) */
:root {
  --gray-50: #f9fafb;
  --gray-900: #111827;
  --blue-500: #3b82f6;
  --space-1: 0.25rem;
  --space-2: 0.5rem;
  --space-4: 1rem;
  --space-8: 2rem;
  --radius-sm: 0.25rem;
  --radius-md: 0.5rem;
  --radius-lg: 1rem;
}

/* Semantic tokens (purpose-based) */
:root {
  --color-text: var(--gray-900);
  --color-text-muted: var(--gray-500);
  --color-surface: white;
  --color-primary: var(--blue-500);
  --color-border: var(--gray-200);
  --spacing-section: var(--space-8);
  --spacing-element: var(--space-4);
}

/* Component tokens (component-scoped) */
.btn {
  --btn-padding-x: var(--space-4);
  --btn-padding-y: var(--space-2);
  --btn-radius: var(--radius-md);
  --btn-bg: var(--color-primary);

  padding: var(--btn-padding-y) var(--btn-padding-x);
  border-radius: var(--btn-radius);
  background: var(--btn-bg);
}

/* Dark mode via semantic token swap */
@media (prefers-color-scheme: dark) {
  :root {
    --color-text: var(--gray-50);
    --color-surface: var(--gray-900);
    --color-border: var(--gray-700);
  }
}
```

---

## Fluid Typography

```css
/* Fluid typography with clamp() */
:root {
  /* Min: 16px at 320px viewport -> Max: 20px at 1200px viewport */
  --font-body: clamp(1rem, 0.909rem + 0.45vw, 1.25rem);

  /* Headings scale more aggressively */
  --font-h1: clamp(2rem, 1.5rem + 2.5vw, 4rem);
  --font-h2: clamp(1.5rem, 1.25rem + 1.25vw, 2.5rem);
  --font-h3: clamp(1.25rem, 1.1rem + 0.75vw, 1.75rem);
}

body { font-size: var(--font-body); }
h1 { font-size: var(--font-h1); }
h2 { font-size: var(--font-h2); }
h3 { font-size: var(--font-h3); }

/* Fluid spacing (same principle) */
:root {
  --space-fluid-s: clamp(0.5rem, 0.4rem + 0.5vw, 1rem);
  --space-fluid-m: clamp(1rem, 0.8rem + 1vw, 2rem);
  --space-fluid-l: clamp(2rem, 1.5rem + 2.5vw, 4rem);
}
```

---

## Responsive Images

```html
<!-- Art direction with <picture> -->
<picture>
  <source media="(min-width: 1024px)" srcset="/hero-wide.avif" type="image/avif">
  <source media="(min-width: 1024px)" srcset="/hero-wide.webp" type="image/webp">
  <source media="(min-width: 640px)" srcset="/hero-medium.avif" type="image/avif">
  <img src="/hero-small.jpg" alt="Hero" width="800" height="400" loading="eager" fetchpriority="high">
</picture>

<!-- Responsive with srcset + sizes -->
<img
  srcset="/photo-400.jpg 400w, /photo-800.jpg 800w, /photo-1200.jpg 1200w"
  sizes="(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 33vw"
  src="/photo-800.jpg"
  alt="Photo"
  width="800" height="600"
  loading="lazy"
  decoding="async"
>
```

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

## Resource Hints

```html
<!-- Preconnect to critical third-party origins -->
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://cdn.example.com" crossorigin>
<link rel="dns-prefetch" href="https://analytics.example.com">

<!-- Preload critical resources -->
<link rel="preload" href="/fonts/inter.woff2" as="font" type="font/woff2" crossorigin>

<!-- fetchpriority for LCP optimization -->
<img src="/hero.jpg" fetchpriority="high" alt="Hero">
<img src="/below-fold.jpg" fetchpriority="low" loading="lazy" alt="Below fold">

<!-- Prefetch next page (speculative) -->
<link rel="prefetch" href="/next-page">

<!-- Speculation Rules API (Chrome 121+) -->
<script type="speculationrules">
{
  "prerender": [{ "urls": ["/likely-next-page"] }],
  "prefetch": [{ "where": { "href_matches": "/products/*" } }]
}
</script>
```

---

## Core Web Vitals Optimization

### LCP (Largest Contentful Paint) — Target < 2.5s

```tsx
// Preload critical images
<link rel="preload" as="image" href="/hero.webp" />

// Priority on hero image
<Image src="/hero.webp" alt="Hero" priority />

// No lazy loading above the fold
// lazy load everything below the fold
<Image src="/card.webp" alt="Card" loading="lazy" />

// Inline critical CSS (Next.js does this automatically)
// Eliminate render-blocking resources
```

### CLS (Cumulative Layout Shift) — Target < 0.1

```tsx
// Always set dimensions on images
<Image src="/photo.webp" alt="Photo" width={800} height={600} />

// Reserve space for dynamic content
<div style={{ minHeight: '200px' }}>
  {isLoading ? <Skeleton height={200} /> : <Content />}
</div>

// Use CSS aspect-ratio
.video-container { aspect-ratio: 16 / 9; }

// Avoid injecting content above existing content
// Avoid dynamically resizing fonts (FOUT)
```

### INP (Interaction to Next Paint) — Target < 200ms

```tsx
// Defer expensive work
function handleClick() {
  // Update UI immediately (optimistic)
  setItems(prev => [...prev, newItem]);

  // Defer heavy work
  requestIdleCallback(() => {
    analytics.track('item_added');
    syncToServer(newItem);
  });
}

// Use CSS transitions instead of JS animation
// Avoid layout thrashing (read then write, never interleave)
// Use content-visibility: auto for off-screen content
```

```javascript
// Break long tasks with scheduler.yield() (Chrome 129+)
async function handleClick() {
  doFirstPart();
  await scheduler.yield(); // Give browser a chance to process events
  doSecondPart();
  await scheduler.yield();
  doThirdPart();
}

// Measure INP
import { onINP } from 'web-vitals';
onINP(({ value, attribution }) => {
  console.log('INP:', value, 'ms');
  console.log('Element:', attribution.interactionTarget);
  console.log('Type:', attribution.interactionType);
});
```

---

## Tailwind CSS v4

Tailwind CSS v4 is a ground-up rewrite with a CSS-first configuration model, powered by Lightning CSS (Oxide engine).

### Key Changes from v3

```css
/* v3: @tailwind directives + tailwind.config.js */
/* v4: Single CSS import — no JavaScript config needed */
@import "tailwindcss";

/* Design tokens via @theme (replaces tailwind.config.js theme) */
@theme {
  --font-display: "Satoshi", "sans-serif";
  --color-brand-50: oklch(0.97 0.02 240);
  --color-brand-500: oklch(0.55 0.18 240);
  --color-brand-900: oklch(0.25 0.10 240);
  --breakpoint-3xl: 120rem;
  --ease-snappy: cubic-bezier(0.2, 0, 0, 1);
  --spacing-18: 4.5rem;
}

/* Source detection — Tailwind auto-scans your project files */
/* Add extra sources explicitly if needed */
@source "../components/**/*.tsx";

/* Prefix support (avoids class name conflicts) */
@import "tailwindcss" prefix(tw);
/* Usage: <div class="tw:flex tw:gap-4"> */

/* Legacy config migration — load v3 config temporarily */
@config "../../tailwind.config.js";
```

### Migration Highlights

| v3 | v4 |
|---|---|
| `tailwind.config.js` | `@theme` in CSS |
| `@tailwind base/components/utilities` | `@import "tailwindcss"` |
| `postcss-import` + `autoprefixer` | Built-in (remove from PostCSS) |
| `darkMode: 'class'` | `@variant dark (&:where(.dark, .dark *))` |
| `@apply` in config | Still supported, but prefer native CSS |
| JavaScript plugins | CSS `@plugin` or native CSS |

```javascript
// PostCSS config — simplified for v4
export default {
  plugins: {
    "@tailwindcss/postcss": {},  // Replaces tailwindcss + autoprefixer
  },
};
```

**Rule**: In new projects, use `@theme` in CSS instead of `tailwind.config.js`. For migration, use `@config` to load legacy configs incrementally.

---

## Typography & Micro-Interaction Rules

### Typography Micro-Rules
- **Curly quotes**: Use `&lsquo;` / `&rsquo;` / `&ldquo;` / `&rdquo;` (or CSS `quotes` property) instead of straight quotes in editorial content
- **Ellipsis**: Use `&hellip;` (...) not three dots (...)
- **`text-wrap: balance`**: Apply to headings for even line distribution. `text-wrap: pretty` for body text to avoid orphans
- **`font-variant-numeric: tabular-nums`**: Use on numbers in tables/price lists for aligned columns
- **Non-breaking spaces**: Use `&nbsp;` between number and unit (e.g., "10&nbsp;kg"), and between short prepositions and following words in headings

### Touch & Interaction
- **`touch-action: manipulation`**: Removes 300ms tap delay on touch devices without disabling pinch-zoom. Apply to interactive elements
- **`-webkit-tap-highlight-color: transparent`**: Remove blue highlight flash on mobile taps. Replace with your own `:active` style
- **`overscroll-behavior: contain`**: Prevents scroll chaining — when a scrollable element reaches the end, the parent doesn't scroll. Essential for modals, drawers, dropdowns

### Form Micro-Rules
- **Disable spellcheck on code/email inputs**: `spellCheck={false}` or `spellcheck="false"` on code inputs, email fields, URLs
- **Placeholders with ellipsis**: Use "Search..." not "Search" (communicates it's a text input)
- **Warn before navigation with unsaved changes**: Use `beforeunload` event or framework-specific route guards. Show confirmation dialog

### Content/Copy Style
- **Active voice for UI copy**: "Delete this item?" not "This item will be deleted"
- **Specific button labels**: "Save changes" not "Submit". "Delete account" not "OK". The label should tell the user what will happen

---

## Anti-Patterns

| Anti-Pattern | Why It's Dangerous | Fix |
|---|---|---|
| `<div onclick>` | Not keyboard accessible, no focus, no screen reader | `<button>` |
| `<a href="#">` | Scrolls to top, wrong semantics | `<button>` for actions, `<a>` for navigation |
| Placeholder as label | Disappears on type, low contrast | `<label>` element |
| `outline: none` on focus | Keyboard users can't navigate | Custom focus styles: `focus-visible` |
| Images without alt text | Screen readers say "image" | Descriptive alt or `alt=""` for decorative |
| Color as only indicator | Color-blind users miss it | Icon + text + color |
| Fixed font sizes (px) | Ignores user zoom preferences | `rem` for fonts, `em` for local spacing |
| `z-index: 9999` | Z-index war, unpredictable stacking | CSS layers or stacking context management |
| Viewport units without fallback | Mobile URL bar issues | `dvh`/`svh`/`lvh` (dynamic viewport units) |
| Custom modal with div + JS | Missing focus trap, no Escape, z-index wars | Native `<dialog>` element with `showModal()` |
| Custom tooltip/dropdown JS | Over-engineered, accessibility gaps | Popover API (`popover` attribute) |
| JS scroll animations | Layout thrashing, poor perf, jank | CSS scroll-driven animations (`animation-timeline`) |
| Preprocessor nesting only | Build step dependency | Native CSS nesting (fully supported) |
| `!important` everywhere | Specificity nuclear option | Fix cascade, use CSS layers |
| No prefers-reduced-motion | Motion sickness for some users | Respect the preference |
| No prefers-color-scheme | Forced light mode hurts eyes | Support system dark mode preference |
| Physical properties for layout | Breaks in RTL languages, non-logical | Logical properties (`margin-inline-start`, `padding-inline-end`) |
| Hard-coded breakpoints only | Components don't adapt to their container | Container queries (`@container`) |
| No resource hints | Slow third-party fonts/scripts, poor LCP | `preconnect`, `preload`, `fetchpriority` |
| JS-driven textarea auto-resize | Extra JS, layout thrashing, flash of wrong size | `field-sizing: content` |
| Unstructured CSS custom properties | No naming convention, inconsistent theming | Design token taxonomy (primitive/semantic/component) |
| Fixed font sizes across viewports | Text too large on mobile or too small on desktop | Fluid typography with `clamp()` |
| `<img>` without `srcset`/`sizes` | Oversized images on small screens, wasted bandwidth | Responsive images with `srcset`, `sizes`, `<picture>` |

---

## Checklist: Frontend Code Review

- [ ] Semantic HTML elements used (not div soup)
- [ ] All interactive elements keyboard accessible (Tab, Enter, Escape)
- [ ] ARIA attributes used correctly where native elements don't suffice
- [ ] Images have descriptive alt text (or alt="" for decorative)
- [ ] Forms have labels, error messages, and autocomplete attributes
- [ ] Color is not the only indicator (add icons/text)
- [ ] Focus styles visible on all interactive elements
- [ ] Responsive: works on 320px-1920px viewports
- [ ] Dark mode supported (prefers-color-scheme)
- [ ] Reduced motion respected (prefers-reduced-motion)
- [ ] Core Web Vitals within targets (LCP <2.5s, CLS <0.1, INP <200ms)
- [ ] Images optimized (WebP/AVIF, lazy loaded below fold, sized)
- [ ] No layout shifts from dynamically loaded content
- [ ] Skip link for keyboard navigation
- [ ] Native `<dialog>` used for modals (not custom div-based)
- [ ] Popover API used for tooltips/dropdowns where applicable
- [ ] Touch targets at least 24x24px (WCAG 2.5.8)
- [ ] Focused elements not obscured by sticky headers/footers (WCAG 2.4.11)
- [ ] Drag interactions have click/tap alternatives (WCAG 2.5.7)
- [ ] View transitions used for page/state navigation where appropriate
- [ ] Curly quotes used in editorial/marketing content
- [ ] `text-wrap: balance` on headings, `text-wrap: pretty` on body text
- [ ] `font-variant-numeric: tabular-nums` on numeric table columns
- [ ] `touch-action: manipulation` on interactive elements
- [ ] `overscroll-behavior: contain` on scrollable containers (modals, drawers)
- [ ] Spellcheck disabled on code/email/URL input fields
- [ ] Button labels are specific (not generic "Submit"/"OK")
- [ ] Logical properties used instead of physical (`margin-inline-start` not `margin-left`)
- [ ] Design tokens follow three-tier taxonomy (primitive/semantic/component)
- [ ] Fluid typography via `clamp()` -- no fixed breakpoint font swaps
- [ ] Responsive images use `srcset`/`sizes` or `<picture>` for art direction
- [ ] Resource hints in place (`preconnect`, `preload` for critical assets, `fetchpriority`)
- [ ] `:has()` used for parent/sibling selection instead of JS class toggling
- [ ] CSS Subgrid used for aligned card grids and complex layouts
- [ ] `field-sizing: content` on textareas for auto-sizing
- [ ] CSS layers ordered correctly (reset < base < components < utilities)
- [ ] INP optimized (long tasks broken with `scheduler.yield()`, web-vitals measured)
