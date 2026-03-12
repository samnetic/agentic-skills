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

| # | Principle | Meaning |
|---|---|---|
| 1 | **Semantic HTML first** | The right element for the right content. No div soup |
| 2 | **Progressive enhancement** | Works without JS. Enhanced with JS |
| 3 | **Mobile-first** | Design for smallest screen, enhance upward |
| 4 | **Accessibility is not optional** | WCAG 2.2 AA minimum. Test with keyboard and screen readers |
| 5 | **Performance budgets** | LCP <2.5s, INP <200ms, CLS <0.1 |
| 6 | **CSS > JavaScript for UI** | Animations, layouts, dark mode -- CSS first |

---

## Workflow

1. **AUDIT** -- Identify the task type (layout, component, form, animation, page). Determine which principles and patterns apply.
2. **STRUCTURE** -- Write semantic HTML first. Choose the correct elements from the element selection cheat sheet ([references/accessibility.md](references/accessibility.md)). No `<div>` unless no semantic element fits.
3. **LAYOUT** -- Apply CSS layout using the decision tree below. Mobile-first breakpoints. Use container queries for component-level responsiveness.
4. **STYLE** -- Apply design tokens (primitive > semantic > component). Use native CSS features: nesting, layers, `@scope`, `light-dark()`, `color-mix()`. See [references/modern-css.md](references/modern-css.md).
5. **ACCESSIBLE** -- Keyboard navigation, ARIA attributes, focus management, target sizes. Every interactive element must pass WCAG 2.2 AA. See [references/accessibility.md](references/accessibility.md).
6. **PERFORM** -- Optimize Core Web Vitals: preload LCP images, set dimensions to prevent CLS, break long tasks for INP. See [references/performance-and-assets.md](references/performance-and-assets.md).
7. **POLISH** -- Typography micro-rules, touch interactions, form UX. See [references/ux-patterns.md](references/ux-patterns.md).
8. **REVIEW** -- Run the checklist at the bottom of this file against every output.

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

### Choosing a CSS Feature for the Task

```
What are you trying to do?
├─ Scope styles to a component subtree?
│  ├─ Need a lower boundary (donut)? → @scope (.root) to (.exclude)
│  └─ Simple scoping? → @scope (.root) or CSS Modules
├─ Control cascade specificity?
│  └─ CSS @layer (reset < base < components < utilities)
├─ Animate element entering the DOM?
│  └─ @starting-style + transition with allow-discrete
├─ Animate based on scroll position?
│  └─ animation-timeline: scroll() or view()
├─ Animate between page navigations?
│  └─ View Transitions API (@view-transition or startViewTransition())
├─ Position a tooltip/popover relative to trigger?
│  └─ CSS Anchor Positioning (anchor-name + position-anchor)
├─ Dark mode with single declarations?
│  └─ light-dark() function (requires color-scheme: light dark)
├─ Generate color variants from one token?
│  └─ color-mix() in oklab/srgb
├─ Animate a custom property smoothly?
│  └─ @property with typed syntax
└─ Auto-size a textarea?
   └─ field-sizing: content
```

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

## Progressive Disclosure Map

Read references on demand based on the task at hand.

| Topic | Reference | When to read |
|---|---|---|
| Container queries, `:has()`, subgrid, CSS layers, nesting, `@scope`, anchor positioning, `@starting-style`, scroll-driven animations, view transitions, `color-mix()`, `light-dark()`, `@property`, `field-sizing`, viewport units, popover API, `<dialog>`, responsive breakpoints | [references/modern-css.md](references/modern-css.md) | Writing or reviewing CSS layout, animations, dark mode, or component styling |
| Keyboard navigation, ARIA patterns, WCAG 2.2 criteria, focus management, target sizes, form accessibility, semantic HTML elements | [references/accessibility.md](references/accessibility.md) | Building interactive components, forms, modals, or reviewing a11y compliance |
| Core Web Vitals (LCP/CLS/INP), resource hints, responsive images, fluid typography, design tokens, Tailwind CSS v4 | [references/performance-and-assets.md](references/performance-and-assets.md) | Optimizing page load, setting up design systems, configuring Tailwind, or handling images/fonts |
| i18n/RTL logical properties, typography micro-rules, touch interactions, form UX patterns, UI copy guidelines | [references/ux-patterns.md](references/ux-patterns.md) | Polishing UX, supporting RTL, writing UI copy, or handling micro-interactions |

---

## Checklist: Frontend Code Review

### Structure and Semantics
- [ ] Semantic HTML elements used (not div soup)
- [ ] Native `<dialog>` used for modals (not custom div-based)
- [ ] Popover API used for tooltips/dropdowns where applicable
- [ ] Logical properties used instead of physical (`margin-inline-start` not `margin-left`)

### Accessibility
- [ ] All interactive elements keyboard accessible (Tab, Enter, Escape)
- [ ] ARIA attributes used correctly where native elements don't suffice
- [ ] Images have descriptive alt text (or alt="" for decorative)
- [ ] Forms have labels, error messages, and autocomplete attributes
- [ ] Color is not the only indicator (add icons/text)
- [ ] Focus styles visible on all interactive elements
- [ ] Skip link for keyboard navigation
- [ ] Touch targets at least 24x24px (WCAG 2.5.8)
- [ ] Focused elements not obscured by sticky headers/footers (WCAG 2.4.11)
- [ ] Drag interactions have click/tap alternatives (WCAG 2.5.7)

### Responsiveness
- [ ] Responsive: works on 320px-1920px viewports
- [ ] Dark mode supported (prefers-color-scheme)
- [ ] Reduced motion respected (prefers-reduced-motion)

### Performance
- [ ] Core Web Vitals within targets (LCP <2.5s, CLS <0.1, INP <200ms)
- [ ] Images optimized (WebP/AVIF, lazy loaded below fold, sized)
- [ ] No layout shifts from dynamically loaded content
- [ ] Resource hints in place (`preconnect`, `preload` for critical assets, `fetchpriority`)
- [ ] INP optimized (long tasks broken with `scheduler.yield()`, web-vitals measured)

### Modern CSS
- [ ] `:has()` used for parent/sibling selection instead of JS class toggling
- [ ] CSS Subgrid used for aligned card grids and complex layouts
- [ ] `field-sizing: content` on textareas for auto-sizing
- [ ] CSS layers ordered correctly (reset < base < components < utilities)
- [ ] View transitions used for page/state navigation where appropriate

### Design and UX
- [ ] Design tokens follow three-tier taxonomy (primitive/semantic/component)
- [ ] Fluid typography via `clamp()` -- no fixed breakpoint font swaps
- [ ] Responsive images use `srcset`/`sizes` or `<picture>` for art direction
- [ ] Curly quotes used in editorial/marketing content
- [ ] `text-wrap: balance` on headings, `text-wrap: pretty` on body text
- [ ] `font-variant-numeric: tabular-nums` on numeric table columns
- [ ] `touch-action: manipulation` on interactive elements
- [ ] `overscroll-behavior: contain` on scrollable containers (modals, drawers)
- [ ] Spellcheck disabled on code/email/URL input fields
- [ ] Button labels are specific (not generic "Submit"/"OK")
