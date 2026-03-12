# Modern CSS Patterns

## Table of Contents

- [Container Queries](#container-queries)
- [:has() Selector](#has-selector)
- [CSS Subgrid](#css-subgrid)
- [CSS Layers (Cascade Control)](#css-layers-cascade-control)
- [Native CSS Nesting](#native-css-nesting)
- [CSS @scope Rule](#css-scope-rule)
- [CSS Anchor Positioning](#css-anchor-positioning)
- [@starting-style for Entry Animations](#starting-style-for-entry-animations)
- [Scroll-Driven Animations](#scroll-driven-animations)
- [View Transitions API](#view-transitions-api)
- [color-mix() Function](#color-mix-function)
- [light-dark() Function for Dark Mode](#light-dark-function-for-dark-mode)
- [@property for Custom Property Types and Animations](#property-for-custom-property-types-and-animations)
- [field-sizing: content](#field-sizing-content)
- [Viewport Units (dvh/svh/lvh)](#viewport-units-dvhsvhlvh)
- [Popover API](#popover-api)
- [Native dialog Element](#native-dialog-element)
- [Responsive Design — Mobile First](#responsive-design--mobile-first)

---

## Container Queries

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

---

## :has() Selector

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

---

## CSS Subgrid

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

---

## CSS Layers (Cascade Control)

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

---

## Native CSS Nesting

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

---

## CSS @scope Rule

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

---

## CSS Anchor Positioning

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

---

## @starting-style for Entry Animations

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

---

## Scroll-Driven Animations

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

---

## View Transitions API

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

---

## color-mix() Function

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

---

## light-dark() Function for Dark Mode

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

---

## @property for Custom Property Types and Animations

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

---

## field-sizing: content

```css
/* Auto-size textarea to content */
textarea {
  field-sizing: content;
  min-height: 3lh;    /* At least 3 lines */
  max-height: 10lh;   /* Cap at 10 lines */
}
```

---

## Viewport Units (dvh/svh/lvh)

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

---

## Popover API

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

---

## Native dialog Element

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

---

## Responsive Design -- Mobile First

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
