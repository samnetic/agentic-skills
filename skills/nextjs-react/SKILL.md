---
name: nextjs-react
description: >-
  Next.js 15+ and React 19+ development expertise. Use when building Next.js applications
  with App Router, implementing Server Components vs Client Components, using Server Actions
  and form handling, designing data fetching and caching strategies with 'use cache' directive,
  cacheLife() and cacheTag() APIs, implementing parallel routes and intercepting routes,
  configuring streaming with Suspense, using useSearchParams with proper Suspense boundaries,
  handling dynamic route params (Promise-based in Next.js 15), implementing ISR/SSG/SSR/PPR
  strategies, using after() for post-response work, setting up middleware and instrumentation,
  configuring next.config, working with React Server Components (RSC), React Compiler for
  auto memoization, using the `use()` hook, `useOptimistic`, `useFormStatus`, implementing
  error boundaries with forbidden()/unauthorized(), working with Turbopack, View Transitions,
  TanStack Query, or reviewing Next.js code quality.
  Triggers: Next.js, nextjs, React, RSC, Server Component, Client Component, App Router,
  Server Action, useSearchParams, Suspense, streaming, parallel routes, intercepting routes,
  ISR, SSR, SSG, PPR, cache, use cache, cacheLife, cacheTag, revalidate, middleware, layout,
  loading, error boundary, TanStack, after, instrumentation, React Compiler, useOptimistic,
  useFormStatus, Turbopack, View Transitions, forbidden, unauthorized.
---

# Next.js & React Skill

Build Next.js 15+ applications using App Router with Server Components by default.
Minimize client-side JavaScript. Let the server do the work.

---

## Core Principles

| Principle | Meaning |
|---|---|
| **Server Components by default** | Only add `'use client'` when you need interactivity, browser APIs, or hooks |
| **Fetch on the server** | Data fetching in Server Components or Server Actions. Never in useEffect |
| **URL is state** | Use searchParams for filters, pagination, sorting -- shareable, bookmarkable |
| **Streaming with Suspense** | Show UI progressively -- don't wait for all data |
| **Minimize client bundles** | Every `'use client'` increases JavaScript shipped to browser |
| **Type everything** | Strict TypeScript. No `any`. Zod at API boundaries |

---

## Decision Tree: Server vs Client Components

```
Does this component need:
+-- Event handlers (onClick, onChange, onSubmit)?
|   +-- YES -> 'use client'
+-- React hooks (useState, useEffect, useRef, useContext)?
|   +-- YES -> 'use client'
+-- Browser APIs (window, document, localStorage)?
|   +-- YES -> 'use client'
+-- Third-party client libraries (framer-motion, react-hook-form)?
|   +-- YES -> 'use client'
+-- Only renders data, no interactivity?
    +-- Server Component (no directive needed)
```

**Critical rule:** Push `'use client'` down to the smallest interactive leaf component. Never place it at the page level.

---

## Workflow

1. **Choose rendering strategy** -- Server Component by default. Add `'use client'` only for interactivity, hooks, or browser APIs. Keep it on leaf components.
2. **Structure routes** -- Use App Router file conventions (`page.tsx`, `layout.tsx`, `loading.tsx`, `error.tsx`). Group with `(parentheses)` for shared layouts. Add `forbidden.tsx`/`unauthorized.tsx` for auth-protected routes.
3. **Handle dynamic params** -- In Next.js 15+, `params` and `searchParams` are Promises. Always `await` them. Wrap `useSearchParams` consumers in `<Suspense>`.
4. **Fetch data on the server** -- Fetch in Server Components or Server Actions. Use `Promise.all()` for parallel fetches or Suspense boundaries for streaming. Use `React.cache()` for request-level deduplication.
5. **Configure caching** -- Use `'use cache'` directive with `cacheLife()` and `cacheTag()` (not `unstable_cache`). Invalidate with `revalidateTag()` from Server Actions.
6. **Build forms with Server Actions** -- Validate with Zod in `'use server'` functions. Use `useActionState` for form state, `useFormStatus` for pending UI, `useOptimistic` for instant feedback.
7. **Handle errors safely** -- Use `unstable_rethrow(err)` as the first line in any `catch` block that might swallow `redirect()`, `notFound()`, `forbidden()`, or `unauthorized()`.
8. **Optimize performance** -- Enable React Compiler (skip manual memoization). Configure `optimizePackageImports` for heavy barrel-export packages. Use `after()` for post-response work (analytics, logging).
9. **Configure deployment** -- Set `output: 'standalone'` for Docker. Use `next/font` for fonts. Load third-party scripts via `next/script`. Use `generateMetadata` for dynamic SEO.

---

## Key Patterns (Quick Reference)

### Dynamic Route Params (Next.js 15+ Breaking Change)

```tsx
type Props = {
  params: Promise<{ id: string }>;
  searchParams: Promise<{ tab?: string }>;
};

export default async function Page({ params, searchParams }: Props) {
  const { id } = await params;           // Must await
  const { tab } = await searchParams;    // Must await
}
```

### useSearchParams Requires Suspense

```tsx
// Page wrapper (Server Component)
export default function SearchPage() {
  return (
    <Suspense fallback={<SearchSkeleton />}>
      <SearchResults />  {/* 'use client' component using useSearchParams */}
    </Suspense>
  );
}
```

### Server Action with Zod Validation

```tsx
'use server';
const Schema = z.object({ name: z.string().min(1), email: z.string().email() });

export async function updateProfile(formData: FormData) {
  const parsed = Schema.safeParse(Object.fromEntries(formData));
  if (!parsed.success) return { error: parsed.error.flatten().fieldErrors };
  await db.user.update({ where: { id: session.userId }, data: parsed.data });
  revalidatePath('/profile');
  return { success: true };
}
```

### Caching with use cache

```tsx
async function getUser(userId: string) {
  'use cache';
  cacheTag(`user-${userId}`);
  cacheLife('minutes');
  return db.user.findUnique({ where: { id: userId } });
}
```

### Parallel Fetching (Avoid Waterfalls)

```tsx
// Promise.all for parallel fetches
const [user, posts] = await Promise.all([getUser(id), getPosts(id)]);

// Or streaming with Suspense for progressive UI
<Suspense fallback={<Skeleton />}>
  <PostsList postsPromise={getPostsPromise} />
</Suspense>
```

### Error Handling with unstable_rethrow

```tsx
try {
  if (res.status === 404) notFound();
  if (res.status === 401) redirect('/login');
} catch (err) {
  unstable_rethrow(err);  // MUST be first line -- re-throws Next.js internal errors
  console.error(err);
}
```

### after() for Post-Response Work

```tsx
import { after } from 'next/server';

export default async function Page() {
  const data = await getData();
  after(async () => { await logAnalytics(data); });  // runs after response sent
  return <View data={data} />;
}
```

---

## Anti-Patterns

| Anti-Pattern | Why It's Dangerous | Fix |
|---|---|---|
| `'use client'` on page level | Entire page becomes client-rendered | Push down to smallest interactive component |
| `useEffect` for data fetching | Loading spinners, waterfalls, no SSR | Fetch in Server Components |
| `useSearchParams` without Suspense | Opts entire page out of SSG | Wrap in Suspense boundary |
| Not awaiting params/searchParams | Build errors in Next.js 15 | `const { id } = await params` |
| Fetching in layout.tsx | Blocks entire layout, can't stream | Fetch in page.tsx or child components |
| Sequential fetches | Waterfall -- slow page loads | `Promise.all()` or Suspense boundaries |
| `router.push` for navigation | Client-side only, no prefetching | `<Link>` component (prefetches) |
| Giant Client Components | Large JS bundles, slow TTI | Split: Server wrapper + small Client parts |
| No loading.tsx | Blank screen during navigation | Add loading.tsx with skeletons |
| `typeof window !== 'undefined'` | Wrong mental model | Use `'use client'` directive properly |
| Unnecessary state for URL data | Not shareable, not bookmarkable | useSearchParams + URL state |
| Not using `<Image>` | No optimization, layout shift | `next/image` for all images |
| Manual `useMemo`/`useCallback` everywhere | Unnecessary with React Compiler | Enable React Compiler, write plain React |
| `unstable_cache` in new code | Being replaced | `'use cache'` + `cacheLife()` + `cacheTag()` |
| Blocking response with analytics/logging | Slow responses for non-critical work | `after()` for post-response tasks |
| Generic 404 for auth errors | Poor UX, no distinction | `forbidden()` / `unauthorized()` + boundary files |
| `useEffect` for optimistic updates | Complex, error-prone | `useOptimistic` hook |
| Prop drilling form pending state | Boilerplate | `useFormStatus` in child components |

---

## Progressive Disclosure Map

| Topic | Reference | When to read |
|---|---|---|
| Server vs Client Components, RSC serialization, hydration errors | [references/server-client-components.md](references/server-client-components.md) | Deciding component boundaries, debugging serialization or hydration issues |
| Data fetching, `'use cache'`, parallel fetching, streaming, `React.cache()` | [references/data-fetching-caching.md](references/data-fetching-caching.md) | Implementing data fetching, configuring caching, eliminating waterfalls |
| Route organization, parallel/intercepting routes, PPR, dynamic params, middleware | [references/routing-patterns.md](references/routing-patterns.md) | Structuring app routes, building modals, setting up parallel slots or PPR |
| React 19 hooks (`use`, `useOptimistic`, `useFormStatus`), React Compiler, View Transitions | [references/react19-hooks-compiler.md](references/react19-hooks-compiler.md) | Using new React 19 APIs, enabling auto-memoization, adding page transitions |
| Server Actions, form handling, `useActionState`, error handling, `after()`, `forbidden()`/`unauthorized()` | [references/server-actions-forms.md](references/server-actions-forms.md) | Building forms, handling mutations, implementing auth boundaries |
| Self-hosting, Docker, metadata/OG images, fonts, scripts, problematic packages, Turbopack | [references/deployment-optimization.md](references/deployment-optimization.md) | Deploying to production, optimizing bundles, configuring SEO and fonts |
| Re-render optimization, compound components, barrel file optimization, CSS virtualization | [references/performance-patterns.md](references/performance-patterns.md) | Optimizing render performance, building reusable component APIs |

---

## Route File Conventions

| File | Purpose |
|---|---|
| `page.tsx` | Route component (required to make route accessible) |
| `layout.tsx` | Shared layout (wraps children, preserved on navigation) |
| `loading.tsx` | Instant Suspense fallback |
| `error.tsx` | Error boundary (`'use client'` required) |
| `not-found.tsx` | 404 UI |
| `forbidden.tsx` | 403 UI (Next.js 15.1+) |
| `unauthorized.tsx` | 401 UI (Next.js 15.1+) |
| `route.ts` | API route handler (cannot coexist with page.tsx) |
| `instrumentation.ts` | Server startup and error tracking hooks |

---

## Checklist

- [ ] Pages are Server Components by default
- [ ] `'use client'` only on interactive leaf components
- [ ] `params` and `searchParams` are awaited (Next.js 15)
- [ ] `useSearchParams` wrapped in Suspense
- [ ] Data fetching in Server Components or Server Actions
- [ ] No `useEffect` for data fetching
- [ ] Parallel fetches with `Promise.all` or Suspense streaming
- [ ] Caching uses `'use cache'` + `cacheLife()` + `cacheTag()` (not `unstable_cache`)
- [ ] `loading.tsx` exists for routes with data fetching
- [ ] `error.tsx` exists for routes that can fail
- [ ] `forbidden.tsx` / `unauthorized.tsx` for auth-protected routes
- [ ] Forms use Server Actions with Zod validation
- [ ] `useFormStatus` for submit button states (no prop drilling)
- [ ] `useOptimistic` for instant UI feedback on mutations
- [ ] React Compiler enabled -- no manual `useMemo`/`useCallback` in new code
- [ ] `after()` used for analytics, logging, and non-blocking side effects
- [ ] `instrumentation.ts` set up for monitoring/OTel
- [ ] Images use `next/image`
- [ ] Metadata exported from pages/layouts
- [ ] No full-page client rendering
- [ ] Non-serializable types (`Date`, `Map`, `Set`) converted before crossing RSC boundary
- [ ] `redirect()` / `notFound()` not swallowed by `try-catch` (`unstable_rethrow` used)
- [ ] `optimizePackageImports` configured for heavy barrel-export packages
- [ ] `React.cache()` used for request-level deduplication of shared data fetching
- [ ] Dynamic imports with `{ ssr: false }` for client-only heavy packages
- [ ] `generateMetadata` used for dynamic page metadata (not hardcoded)
- [ ] Fonts loaded via `next/font` (not CDN link tags)
- [ ] Self-hosting considerations documented if not deploying to Vercel
- [ ] Parallel route slots have `default.tsx` files
- [ ] Third-party scripts loaded via `next/script` with appropriate strategy
- [ ] No hydration mismatches from `Date`, `Math.random`, or browser-only APIs in initial render
