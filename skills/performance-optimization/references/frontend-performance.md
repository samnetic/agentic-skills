# Frontend Performance Reference

## Table of Contents

- [Core Web Vitals Deep Dive](#core-web-vitals-deep-dive)
  - [LCP — Largest Contentful Paint](#lcp--largest-contentful-paint-target--25s)
  - [CLS — Cumulative Layout Shift](#cls--cumulative-layout-shift-target--01)
  - [INP — Interaction to Next Paint](#inp--interaction-to-next-paint-target--200ms)
- [Bundle Optimization](#bundle-optimization)
- [Code Splitting](#code-splitting)
- [Image Optimization](#image-optimization)
- [React Performance](#react-performance)
  - [React Compiler (React 19+)](#react-compiler-react-19)
  - [Server Components (Zero Client JS)](#server-components-zero-client-js)
  - [Suspense Boundaries for Streaming](#suspense-boundaries-for-streaming)
  - [Avoiding Unnecessary Rerenders](#avoiding-unnecessary-rerenders)

---

## Core Web Vitals Deep Dive

### LCP — Largest Contentful Paint (Target: < 2.5s)

LCP measures when the largest visible content element finishes rendering. Usually a hero image, heading, or video poster.

**Optimization strategies (ordered by impact):**

```html
<!-- 1. Preload the LCP resource — tell the browser about it ASAP -->
<link rel="preload" as="image" href="/hero.webp" fetchpriority="high" />

<!-- 2. Use fetchpriority on the LCP element itself -->
<img src="/hero.webp" alt="Hero" fetchpriority="high" loading="eager" />

<!-- 3. Preconnect to critical third-party origins -->
<link rel="preconnect" href="https://cdn.example.com" />
<link rel="dns-prefetch" href="https://cdn.example.com" />
```

```
LCP Optimization Checklist:
├── Server response time (TTFB < 800ms)
│   ├── Use CDN for static and edge-rendered pages
│   ├── Enable HTTP/2 or HTTP/3
│   ├── Optimize server-side data fetching
│   └── Use streaming SSR (React renderToPipeableStream)
├── Resource load delay
│   ├── Inline critical CSS (< 14KB first paint)
│   ├── Preload LCP image with fetchpriority="high"
│   ├── Avoid render-blocking JavaScript in <head>
│   └── Remove unused CSS (PurgeCSS or Tailwind JIT)
├── Resource load duration
│   ├── Compress images: WebP/AVIF (30-50% smaller)
│   ├── Serve responsive sizes with srcset
│   ├── Use CDN with edge caching
│   └── Enable Brotli compression for text assets
└── Element render delay
    ├── Avoid client-side rendering for LCP content
    ├── Minimize JavaScript that must execute before LCP
    └── Avoid lazy-loading the LCP image
```

### CLS — Cumulative Layout Shift (Target: < 0.1)

CLS measures visual stability. Layout shifts frustrate users and cause misclicks.

```html
<!-- 1. Always set explicit dimensions on images and video -->
<img src="/photo.webp" alt="Photo" width="800" height="600" />
<video width="1280" height="720" poster="/poster.webp"></video>

<!-- 2. Use aspect-ratio CSS for responsive containers -->
<style>
.video-container { aspect-ratio: 16 / 9; }
.avatar { aspect-ratio: 1; width: 48px; }
</style>

<!-- 3. Font display strategy — prevent FOIT/FOUT layout shifts -->
<style>
@font-face {
  font-family: 'CustomFont';
  src: url('/fonts/custom.woff2') format('woff2');
  font-display: optional; /* Best for CLS — uses fallback if font is slow */
}
</style>
```

**Common CLS causes and fixes:**

| Cause | Fix |
|---|---|
| Images without dimensions | Always set `width` and `height` attributes |
| Ads/embeds without reserved space | Use `min-height` placeholder or `aspect-ratio` |
| Web fonts causing FOUT | `font-display: optional` or `font-display: swap` with size-adjust |
| Dynamic content injected above viewport | Insert below the fold, or use `content-visibility: auto` |
| Late-loading CSS | Inline critical CSS, preload stylesheets |
| Animations triggering layout | Use `transform` and `opacity` only (compositor-only properties) |

### INP — Interaction to Next Paint (Target: < 200ms)

INP measures responsiveness. It captures the delay from user input (click, tap, key) to the next visual update.

```typescript
// 1. Break up long tasks with scheduler.yield()
async function processLargeList(items: Item[]) {
  for (let i = 0; i < items.length; i++) {
    processItem(items[i]);

    // Yield to the browser every 5 items so it can handle input
    if (i % 5 === 0) {
      await scheduler.yield();
    }
  }
}

// 2. Fallback for browsers without scheduler.yield()
function yieldToMain(): Promise<void> {
  if ('scheduler' in globalThis && 'yield' in scheduler) {
    return scheduler.yield();
  }
  return new Promise(resolve => setTimeout(resolve, 0));
}

// 3. Debounce expensive event handlers
function handleSearch(query: string) {
  // Don't run search on every keystroke
  clearTimeout(searchTimeout);
  searchTimeout = setTimeout(() => {
    performSearch(query);
  }, 150);
}

// 4. Use startTransition for non-urgent updates (React)
import { startTransition } from 'react';

function handleFilterChange(filter: string) {
  // Urgent: update the input field immediately
  setInputValue(filter);

  // Non-urgent: update the filtered list (can be interrupted)
  startTransition(() => {
    setFilteredItems(items.filter(item => item.name.includes(filter)));
  });
}
```

**INP optimization strategies:**

| Strategy | When to Use |
|---|---|
| `scheduler.yield()` | Breaking up loops or sequential processing > 50ms |
| `requestAnimationFrame` | Visual updates that should sync with paint |
| `requestIdleCallback` | Non-critical work (analytics, prefetching) |
| Web Workers | CPU-heavy computation (sorting, parsing, encryption) |
| `startTransition` (React) | Non-urgent state updates that can be interrupted |
| Event delegation | Many similar event handlers (use one on the parent) |
| Debounce/throttle | Frequent events (scroll, resize, input) |

---

## Bundle Optimization

```bash
# Analyze bundle size
npx next build                     # Next.js shows route sizes
npx vite-bundle-visualizer         # Vite
npx webpack-bundle-analyzer        # Webpack

# Common wins (ordered by impact):
# 1. Tree-shaking: import { format } from 'date-fns'  NOT  import dayjs from 'dayjs'
# 2. Code splitting: dynamic import() for route-level splitting
# 3. Replace heavy libraries:
#    moment.js (300KB) -> date-fns (tree-shakeable)
#    lodash (70KB) -> lodash-es (tree-shakeable) or native methods
#    axios (30KB) -> fetch (0KB, built-in)
```

---

## Code Splitting

```tsx
// Route-level (automatic in Next.js)
// Next.js does this for every page.tsx automatically

// Component-level lazy loading
import { lazy, Suspense } from 'react';

const HeavyChart = lazy(() => import('./HeavyChart'));

function Dashboard() {
  return (
    <Suspense fallback={<ChartSkeleton />}>
      <HeavyChart data={data} />
    </Suspense>
  );
}

// Library-level (load only when needed)
async function handleExport() {
  const { exportToPdf } = await import('./pdf-exporter');
  await exportToPdf(data);
}
```

---

## Image Optimization

```tsx
// Next.js Image (automatic optimization)
import Image from 'next/image';

<Image
  src="/hero.jpg"
  alt="Hero"
  width={1200}
  height={630}
  priority              // Above the fold — preload
  sizes="(max-width: 768px) 100vw, 50vw"
  quality={80}          // 80 is sweet spot
/>

// Below the fold — lazy load (default)
<Image
  src="/card.jpg"
  alt="Card"
  width={400}
  height={300}
  loading="lazy"        // Default — deferred
/>
```

**Image rules:**
- WebP/AVIF format (30-50% smaller than JPEG)
- Serve responsive sizes (`sizes` attribute)
- `priority` only for above-the-fold images
- Lazy load everything else
- Use `aspect-ratio` CSS to prevent layout shift

---

## React Performance

### React Compiler (React 19+)

```tsx
// React Compiler auto-memoizes components, hooks, and expressions.
// No more manual React.memo, useMemo, useCallback.

// Before React Compiler — manual memoization:
const MemoizedList = React.memo(function List({ items, onSelect }) {
  const sorted = useMemo(() => items.sort(compareFn), [items]);
  const handleSelect = useCallback((id) => onSelect(id), [onSelect]);
  return sorted.map(item => <Item key={item.id} item={item} onSelect={handleSelect} />);
});

// With React Compiler — just write normal code:
function List({ items, onSelect }) {
  const sorted = items.sort(compareFn);
  return sorted.map(item => <Item key={item.id} item={item} onSelect={onSelect} />);
}
// Compiler inserts memoization automatically where beneficial.
```

### Server Components (Zero Client JS)

```tsx
// Server Components run ONLY on the server — zero JavaScript shipped to client.
// Default in Next.js App Router. No 'use client' directive = Server Component.

// This component sends only HTML to the client (no JS bundle cost):
async function ProductList() {
  const products = await db.product.findMany(); // Direct DB access
  return (
    <ul>
      {products.map(p => <li key={p.id}>{p.name} — ${p.price}</li>)}
    </ul>
  );
}

// Only add 'use client' when you NEED interactivity:
// - Event handlers (onClick, onChange)
// - useState, useEffect, useReducer
// - Browser-only APIs (localStorage, IntersectionObserver)
```

### Suspense Boundaries for Streaming

```tsx
// Stream HTML progressively — show content as it becomes ready
import { Suspense } from 'react';

export default function DashboardPage() {
  return (
    <main>
      <h1>Dashboard</h1>

      {/* Fast — renders immediately */}
      <UserGreeting />

      {/* Slow data — streams in when ready */}
      <Suspense fallback={<StatsSkeleton />}>
        <StatsPanel />   {/* async Server Component */}
      </Suspense>

      <Suspense fallback={<ActivitySkeleton />}>
        <RecentActivity /> {/* async Server Component */}
      </Suspense>
    </main>
  );
}

// Each Suspense boundary streams independently.
// User sees the page progressively, not a blank screen.
```

### Avoiding Unnecessary Rerenders

```tsx
// 1. Lift state down — keep state close to where it's used
// BAD: entire page rerenders on search input change
function Page() {
  const [search, setSearch] = useState('');
  return (
    <div>
      <SearchInput value={search} onChange={setSearch} />
      <ExpensiveTree />  {/* Rerenders on every keystroke */}
    </div>
  );
}

// GOOD: isolate the state into its own component
function Page() {
  return (
    <div>
      <SearchSection />    {/* Contains its own state */}
      <ExpensiveTree />    {/* Never rerenders from search */}
    </div>
  );
}

// 2. Composition pattern — pass components as children
function Layout({ children }: { children: React.ReactNode }) {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  return (
    <div>
      <Sidebar open={sidebarOpen} onToggle={() => setSidebarOpen(!sidebarOpen)} />
      {children}  {/* children don't rerender when sidebarOpen changes */}
    </div>
  );
}

// 3. use() hook for lazy data (React 19+)
import { use } from 'react';

function Comments({ commentsPromise }: { commentsPromise: Promise<Comment[]> }) {
  const comments = use(commentsPromise);  // Suspends until resolved
  return comments.map(c => <Comment key={c.id} comment={c} />);
}
```
