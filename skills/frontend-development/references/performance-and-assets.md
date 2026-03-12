# Performance, Assets, and Design Systems

## Table of Contents

- [Core Web Vitals Optimization](#core-web-vitals-optimization)
  - [LCP (Largest Contentful Paint)](#lcp-largest-contentful-paint--target--25s)
  - [CLS (Cumulative Layout Shift)](#cls-cumulative-layout-shift--target--01)
  - [INP (Interaction to Next Paint)](#inp-interaction-to-next-paint--target--200ms)
- [Resource Hints](#resource-hints)
- [Responsive Images](#responsive-images)
- [Fluid Typography](#fluid-typography)
- [Design Tokens / System Architecture](#design-tokens--system-architecture)
- [Tailwind CSS v4](#tailwind-css-v4)

---

## Core Web Vitals Optimization

### LCP (Largest Contentful Paint) -- Target < 2.5s

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

### CLS (Cumulative Layout Shift) -- Target < 0.1

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

### INP (Interaction to Next Paint) -- Target < 200ms

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
