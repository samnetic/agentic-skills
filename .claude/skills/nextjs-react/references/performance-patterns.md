# React Performance Patterns

## Table of Contents

- [Barrel File Optimization](#barrel-file-optimization)
- [Re-render Optimization Rules](#re-render-optimization-rules)
- [Children as Stable Reference](#children-as-stable-reference)
- [CSS content-visibility for Long Lists](#css-content-visibility-for-long-lists)
- [Preload on Hover](#preload-on-hover)
- [Compound Components with Context](#compound-components-with-context)
- [Boolean Prop Elimination](#boolean-prop-elimination)
- [Generic Context Pattern](#generic-context-pattern)

---

## Barrel File Optimization

Barrel files (`index.ts` that re-exports everything) cause entire packages to be bundled even when you import one function. Configure `optimizePackageImports` to tree-shake them:

```ts
// next.config.ts
import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  experimental: {
    optimizePackageImports: [
      'lucide-react',
      'date-fns',
      '@mui/material',
      '@mui/icons-material',
      'lodash-es',
      '@heroicons/react/24/outline',
      '@heroicons/react/24/solid',
      'rxjs',
      'recharts',
    ],
  },
};
export default nextConfig;
```

**Note:** Some packages are optimized by default in Next.js 15+ (e.g., `lucide-react`, `date-fns`, `lodash-es`). Add others as needed.

---

## Re-render Optimization Rules

1. **Move state down** -- keep state in the closest component to where it is used, not in a shared parent
2. **Extract components that change** from components that do not -- when part of a component re-renders frequently, extract the changing part into its own component
3. **Pass components as `children`** -- the parent re-renders, but `children` is a stable reference and does not re-render
4. **Use composition (`children` prop)** instead of conditional rendering that re-mounts -- `{show && <Heavy />}` re-mounts on every toggle; instead, always render and use CSS to hide
5. **Avoid object/array literals in JSX** -- `style={{ color: 'red' }}` creates a new object every render, forcing child re-renders. Extract to a constant or `useMemo`
6. **Avoid inline function definitions for expensive children** -- `<ExpensiveList onSelect={(id) => setSelected(id)} />` creates a new function reference every render. With React Compiler this is auto-memoized, but be aware for non-compiled code
7. **Use `key` to force remount when identity changes** -- do not use array index as key if items can reorder. Use a stable ID
8. **Lift expensive computations out of render** -- use `React.cache()`, `'use cache'`, or compute in a Server Component

---

## Children as Stable Reference

```tsx
// Pattern: children as stable reference
function Layout({ children }: { children: React.ReactNode }) {
  const [sidebarOpen, setSidebarOpen] = useState(true);
  return (
    <div className="flex">
      <Sidebar open={sidebarOpen} onToggle={() => setSidebarOpen(!sidebarOpen)} />
      {/* children does NOT re-render when sidebarOpen changes */}
      <main>{children}</main>
    </div>
  );
}
```

---

## CSS content-visibility for Long Lists

For long scrollable content, use CSS-level virtualization before reaching for JavaScript virtualization libraries:

```css
/* Apply to each item in a long list */
.list-item {
  content-visibility: auto;
  contain-intrinsic-size: 0 80px; /* estimated height */
}
```

This tells the browser to skip rendering off-screen items entirely. Unlike JS virtualization, it preserves accessibility (screen readers still see all content) and search (Ctrl+F works).

---

## Preload on Hover

```tsx
'use client';
import { useRouter } from 'next/navigation';

export function ProductCard({ product }: { product: Product }) {
  const router = useRouter();

  return (
    <Link
      href={`/products/${product.id}`}
      // Next.js <Link> prefetches automatically in viewport
      // For programmatic prefetch on hover:
      onMouseEnter={() => router.prefetch(`/products/${product.id}`)}
    >
      {product.name}
    </Link>
  );
}
```

---

## Compound Components with Context

The compound component pattern lets related components share implicit state. The parent provides context, children consume it.

```tsx
// components/tabs.tsx
'use client';
import { createContext, use, useState, type ReactNode } from 'react';

// Internal context -- not exported
type TabsContextValue = {
  activeTab: string;
  setActiveTab: (tab: string) => void;
};

const TabsContext = createContext<TabsContextValue | null>(null);

function useTabsContext() {
  const context = use(TabsContext);
  if (!context) throw new Error('Tabs components must be used within <Tabs>');
  return context;
}

// Root component -- provides context
function Tabs({ defaultTab, children }: { defaultTab: string; children: ReactNode }) {
  const [activeTab, setActiveTab] = useState(defaultTab);
  return (
    <TabsContext value={{ activeTab, setActiveTab }}>
      <div role="tablist">{children}</div>
    </TabsContext>
  );
}

// Trigger component -- switches tabs
function TabsTrigger({ value, children }: { value: string; children: ReactNode }) {
  const { activeTab, setActiveTab } = useTabsContext();
  return (
    <button
      role="tab"
      aria-selected={activeTab === value}
      onClick={() => setActiveTab(value)}
      className={activeTab === value ? 'border-b-2 border-blue-500 font-semibold' : ''}
    >
      {children}
    </button>
  );
}

// Content component -- shows when active
function TabsContent({ value, children }: { value: string; children: ReactNode }) {
  const { activeTab } = useTabsContext();
  if (activeTab !== value) return null;
  return <div role="tabpanel">{children}</div>;
}

// Attach sub-components to parent
Tabs.Trigger = TabsTrigger;
Tabs.Content = TabsContent;
export { Tabs };

// Usage -- clean, declarative API
<Tabs defaultTab="overview">
  <Tabs.Trigger value="overview">Overview</Tabs.Trigger>
  <Tabs.Trigger value="analytics">Analytics</Tabs.Trigger>
  <Tabs.Trigger value="settings">Settings</Tabs.Trigger>

  <Tabs.Content value="overview"><OverviewPanel /></Tabs.Content>
  <Tabs.Content value="analytics"><AnalyticsPanel /></Tabs.Content>
  <Tabs.Content value="settings"><SettingsPanel /></Tabs.Content>
</Tabs>
```

---

## Boolean Prop Elimination

Avoid boolean props that lead to inconsistent, hard-to-maintain APIs:

```tsx
// BAD -- boolean props create 2^n combinations, many of which conflict
<Button primary large disabled outline />
// What happens when both primary and outline are true?

// GOOD -- explicit variants with discriminated values
<Button variant="primary" size="lg" disabled />
<Button variant="outline" size="sm" />
```

Define variant types with a union:

```tsx
type ButtonProps = {
  variant: 'primary' | 'secondary' | 'outline' | 'ghost' | 'destructive';
  size: 'sm' | 'md' | 'lg';
  disabled?: boolean;
  children: React.ReactNode;
};
```

---

## Generic Context Pattern

Standardize context shape across your application for predictable consumption:

```tsx
// lib/create-context.ts
import { createContext, use, type ReactNode } from 'react';

interface ContextValue<TState, TActions> {
  state: TState;
  actions: TActions;
}

export function createTypedContext<TState, TActions>(displayName: string) {
  const Context = createContext<ContextValue<TState, TActions> | null>(null);
  Context.displayName = displayName;

  function useTypedContext(): ContextValue<TState, TActions> {
    const value = use(Context);
    if (!value) {
      throw new Error(`use${displayName} must be used within ${displayName}Provider`);
    }
    return value;
  }

  function Provider({
    state,
    actions,
    children,
  }: ContextValue<TState, TActions> & { children: ReactNode }) {
    return <Context value={{ state, actions }}>{children}</Context>;
  }

  return { Provider, useContext: useTypedContext } as const;
}

// Usage
type CartState = { items: CartItem[]; total: number };
type CartActions = { addItem: (item: CartItem) => void; removeItem: (id: string) => void };

const { Provider: CartProvider, useContext: useCart } = createTypedContext<CartState, CartActions>('Cart');
```
