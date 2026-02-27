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
| **URL is state** | Use searchParams for filters, pagination, sorting — shareable, bookmarkable |
| **Streaming with Suspense** | Show UI progressively — don't wait for all data |
| **Minimize client bundles** | Every `'use client'` increases JavaScript shipped to browser |
| **Type everything** | Strict TypeScript. No `any`. Zod at API boundaries |

---

## Server vs Client Components

### Decision Tree

```
Does this component need:
├── Event handlers (onClick, onChange, onSubmit)?
│   └── YES → 'use client'
├── React hooks (useState, useEffect, useRef, useContext)?
│   └── YES → 'use client'
├── Browser APIs (window, document, localStorage)?
│   └── YES → 'use client'
├── Third-party client libraries (framer-motion, react-hook-form)?
│   └── YES → 'use client'
└── Only renders data, no interactivity?
    └── Server Component (no directive needed)
```

### Critical Rule: Push 'use client' Down

```tsx
// BAD — entire page is client-side
'use client'; // ❌ at page level
export default function ProductPage() {
  const [qty, setQty] = useState(1);
  return (
    <div>
      <ProductInfo product={product} />  {/* doesn't need client */}
      <Reviews reviews={reviews} />       {/* doesn't need client */}
      <AddToCart qty={qty} setQty={setQty} /> {/* needs client */}
    </div>
  );
}

// GOOD — only interactive part is client
// app/products/[id]/page.tsx (Server Component)
export default async function ProductPage({ params }: Props) {
  const { id } = await params;  // Next.js 15: params is Promise
  const product = await getProduct(id);
  return (
    <div>
      <ProductInfo product={product} />   {/* Server Component */}
      <Reviews productId={id} />           {/* Server Component */}
      <AddToCartButton productId={id} />   {/* Client Component */}
    </div>
  );
}
```

---

## Dynamic Route Params (Next.js 15+)

**Breaking change: `params` and `searchParams` are now Promises.**

```tsx
// app/products/[id]/page.tsx
type Props = {
  params: Promise<{ id: string }>;
  searchParams: Promise<{ tab?: string }>;
};

export default async function ProductPage({ params, searchParams }: Props) {
  const { id } = await params;           // Must await
  const { tab } = await searchParams;    // Must await
  const product = await getProduct(id);
  return <ProductDetail product={product} activeTab={tab} />;
}

// generateMetadata also async
export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { id } = await params;
  const product = await getProduct(id);
  return { title: product.name };
}

// generateStaticParams for SSG
export async function generateStaticParams() {
  const products = await getAllProducts();
  return products.map((p) => ({ id: p.id.toString() }));
}
```

---

## useSearchParams + Suspense (Mandatory Pattern)

```tsx
// useSearchParams REQUIRES 'use client' AND Suspense boundary
// Without Suspense: entire page becomes client-rendered

// app/search/page.tsx (Server Component wrapper)
import { Suspense } from 'react';

export default function SearchPage() {
  return (
    <Suspense fallback={<SearchSkeleton />}>
      <SearchResults />
    </Suspense>
  );
}

// components/search-results.tsx
'use client';
import { useSearchParams, useRouter, usePathname } from 'next/navigation';

export function SearchResults() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const pathname = usePathname();
  const query = searchParams.get('q') ?? '';
  const page = Number(searchParams.get('page') ?? '1');

  function updateSearch(key: string, value: string) {
    const params = new URLSearchParams(searchParams.toString());
    params.set(key, value);
    params.delete('page'); // Reset page on filter change
    router.push(`${pathname}?${params.toString()}`);
  }

  return ( /* render search UI */ );
}
```

---

## Server Actions

```tsx
// app/actions/user.ts
'use server';

import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { z } from 'zod';

const UpdateProfileSchema = z.object({
  name: z.string().min(1).max(100),
  email: z.string().email(),
});

export async function updateProfile(formData: FormData) {
  const session = await getSession();
  if (!session) redirect('/login');

  const parsed = UpdateProfileSchema.safeParse({
    name: formData.get('name'),
    email: formData.get('email'),
  });

  if (!parsed.success) {
    return { error: parsed.error.flatten().fieldErrors };
  }

  await db.user.update({
    where: { id: session.userId },
    data: parsed.data,
  });

  revalidatePath('/profile');
  return { success: true };
}

// Form component using Server Action
'use client';
import { useActionState } from 'react';  // React 19
import { updateProfile } from '@/app/actions/user';

export function ProfileForm({ user }: { user: User }) {
  const [state, action, isPending] = useActionState(updateProfile, null);

  return (
    <form action={action}>
      <input name="name" defaultValue={user.name} />
      {state?.error?.name && <p className="text-red-500">{state.error.name}</p>}
      <input name="email" defaultValue={user.email} />
      {state?.error?.email && <p className="text-red-500">{state.error.email}</p>}
      <button type="submit" disabled={isPending}>
        {isPending ? 'Saving...' : 'Save'}
      </button>
    </form>
  );
}
```

---

## Data Fetching & Caching

```tsx
// Server Component — fetch directly
async function getProduct(id: string): Promise<Product> {
  const res = await fetch(`${API_URL}/products/${id}`, {
    next: { revalidate: 3600 },  // ISR: revalidate every hour
  });
  if (!res.ok) throw new Error('Failed to fetch product');
  return res.json();
}

// Manual revalidation
import { revalidateTag } from 'next/cache';
revalidateTag('users');  // Invalidate all entries tagged 'users'
```

### `'use cache'` Directive (Next.js 15.1+ — replaces `unstable_cache`)

The `'use cache'` directive is the modern caching API. Add it to functions or entire components to cache their output. Use `cacheLife()` to control TTL and `cacheTag()` for targeted revalidation.

```tsx
import { cacheLife, cacheTag } from 'next/cache';

// Cache an entire page component
export default async function ProductPage({ params }: Props) {
  'use cache';
  cacheLife('hours');  // built-in profile: stale after 1h
  const { id } = await params;
  const product = await getProduct(id);
  return <ProductDetail product={product} />;
}

// Cache a data-fetching function
async function getUser(userId: string) {
  'use cache';
  cacheTag(`user-${userId}`);  // tag for targeted invalidation
  cacheLife('minutes');         // built-in profile: stale after a few minutes
  return db.user.findUnique({ where: { id: userId } });
}

// Custom cache profile with fine-grained control
async function getPopularProducts() {
  'use cache';
  cacheLife({
    stale: 3600,      // serve stale for 1 hour
    revalidate: 900,  // revalidate in background every 15 min
    expire: 86400,    // hard expire after 24 hours
  });
  cacheTag('popular-products');
  return db.product.findMany({ orderBy: { sales: 'desc' }, take: 20 });
}

// Conditional caching based on data
async function getPost(slug: string) {
  'use cache';
  cacheTag(`post-${slug}`);
  const post = await fetchPost(slug);

  if (!post) {
    cacheLife('minutes');  // not found — cache briefly
    return null;
  }
  cacheLife('days');  // published content — cache longer
  return post;
}

// Invalidate from a Server Action
'use server';
import { revalidateTag } from 'next/cache';

export async function updateUser(userId: string, data: UpdateUserData) {
  await db.user.update({ where: { id: userId }, data });
  revalidateTag(`user-${userId}`);  // bust the cache
}
```

**Built-in cache profiles:** `'default'`, `'seconds'`, `'minutes'`, `'hours'`, `'days'`, `'weeks'`, `'max'`.

**Migration from `unstable_cache`:** Replace `unstable_cache(fn, keys, opts)` with `'use cache'` + `cacheTag()` + `cacheLife()` inside the function body.

### Parallel Data Fetching

```tsx
// GOOD — parallel fetches
export default async function Dashboard() {
  // Start all fetches simultaneously
  const [user, stats, notifications] = await Promise.all([
    getUser(),
    getStats(),
    getNotifications(),
  ]);
  return <DashboardView user={user} stats={stats} notifications={notifications} />;
}

// BETTER — streaming with Suspense (shows UI progressively)
export default async function Dashboard() {
  const user = await getUser(); // Fast — needed for layout
  return (
    <div>
      <Header user={user} />
      <Suspense fallback={<StatsSkeleton />}>
        <StatsSection />  {/* Fetches its own data */}
      </Suspense>
      <Suspense fallback={<NotificationsSkeleton />}>
        <NotificationsSection />  {/* Fetches its own data */}
      </Suspense>
    </div>
  );
}
```

---

## Route Organization

```
app/
├── layout.tsx              # Root layout (html, body, providers)
├── page.tsx                # Home page
├── loading.tsx             # Root loading UI
├── error.tsx               # Root error boundary
├── not-found.tsx           # 404 page
├── (marketing)/            # Route group (no URL segment)
│   ├── layout.tsx          # Marketing layout
│   ├── page.tsx            # / (home)
│   └── about/page.tsx      # /about
├── (app)/                  # App route group
│   ├── layout.tsx          # Authenticated layout with sidebar
│   ├── dashboard/
│   │   ├── page.tsx        # /dashboard
│   │   └── loading.tsx     # Dashboard skeleton
│   └── settings/
│       ├── page.tsx        # /settings
│       └── layout.tsx      # Settings sub-layout with tabs
├── api/
│   └── webhooks/
│       └── stripe/route.ts # POST /api/webhooks/stripe
├── middleware.ts           # Edge middleware (auth, redirects)
└── instrumentation.ts     # Server startup hooks (OTel, monitoring)
```

**Route file conventions:**
- `page.tsx` — route component (required to make route accessible)
- `layout.tsx` — shared layout (wraps children, preserved on navigation)
- `loading.tsx` — instant Suspense fallback
- `error.tsx` — error boundary (`'use client'` required)
- `not-found.tsx` — 404 UI
- `forbidden.tsx` — 403 UI (Next.js 15.1+)
- `unauthorized.tsx` — 401 UI (Next.js 15.1+)
- `route.ts` — API route handler (cannot coexist with page.tsx)
- `instrumentation.ts` — server startup and error tracking hooks

---

## React 19 Hooks

### `use()` — Read Promises and Context in Render

```tsx
import { use, Suspense } from 'react';

// Read a promise during render — component suspends until resolved
function Comments({ commentsPromise }: { commentsPromise: Promise<Comment[]> }) {
  const comments = use(commentsPromise);  // suspends here
  return comments.map(c => <p key={c.id}>{c.text}</p>);
}

// Parent creates the promise, Suspense handles loading
export default async function PostPage({ params }: Props) {
  const { id } = await params;
  const commentsPromise = getComments(id);  // start fetch, don't await

  return (
    <article>
      <PostContent id={id} />
      <Suspense fallback={<CommentsSkeleton />}>
        <Comments commentsPromise={commentsPromise} />
      </Suspense>
    </article>
  );
}

// Also works for reading context conditionally
function ThemeIcon() {
  const theme = use(ThemeContext);  // can be called inside if/loops (unlike useContext)
  return <Icon name={theme === 'dark' ? 'moon' : 'sun'} />;
}
```

### `useOptimistic` — Instant UI Updates

```tsx
'use client';
import { useOptimistic } from 'react';
import { toggleLike } from '@/app/actions/likes';

export function LikeButton({ postId, initialLikes, isLiked }: Props) {
  const [optimistic, setOptimistic] = useOptimistic(
    { likes: initialLikes, isLiked },
    (current, newIsLiked: boolean) => ({
      likes: current.likes + (newIsLiked ? 1 : -1),
      isLiked: newIsLiked,
    }),
  );

  async function handleClick() {
    setOptimistic(!optimistic.isLiked);    // instant UI update
    await toggleLike(postId);              // server call in background
    // auto-reverts if server action throws
  }

  return (
    <button onClick={handleClick}>
      {optimistic.isLiked ? 'Unlike' : 'Like'} ({optimistic.likes})
    </button>
  );
}
```

### `useFormStatus` — Access Parent Form State

```tsx
'use client';
import { useFormStatus } from 'react-dom';

// Must be a CHILD of <form> — does not work in the same component as the form
function SubmitButton() {
  const { pending, data, method, action } = useFormStatus();
  return (
    <button type="submit" disabled={pending}>
      {pending ? 'Submitting...' : 'Submit'}
    </button>
  );
}

// Usage
export function ContactForm() {
  return (
    <form action={submitContact}>
      <input name="email" type="email" required />
      <textarea name="message" required />
      <SubmitButton />  {/* reads form state from parent <form> */}
    </form>
  );
}
```

---

## React Compiler (Auto Memoization)

React Compiler (v1.0, stable) automatically memoizes components, values, and callbacks. No more manual `useMemo`, `useCallback`, or `React.memo` for new code.

```tsx
// next.config.ts — enable React Compiler
import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  experimental: {
    reactCompiler: true,  // auto-memoizes everything
  },
};
export default nextConfig;
```

```tsx
// BEFORE (manual memoization)
'use client';
const MemoizedList = React.memo(function UserList({ users }: Props) {
  const sorted = useMemo(() => users.sort(byName), [users]);
  const handleClick = useCallback((id: string) => {
    router.push(`/users/${id}`);
  }, [router]);
  return sorted.map(u => <UserCard key={u.id} user={u} onClick={handleClick} />);
});

// AFTER (React Compiler handles it — just write plain React)
'use client';
function UserList({ users }: Props) {
  const sorted = users.sort(byName);
  const handleClick = (id: string) => router.push(`/users/${id}`);
  return sorted.map(u => <UserCard key={u.id} user={u} onClick={handleClick} />);
}
// Compiler auto-memoizes sorted, handleClick, and the component itself
```

**Rules:** Write idiomatic React following the Rules of React. The compiler understands hooks, conditional rendering, and component boundaries. Leave existing `useMemo`/`useCallback` in place — the compiler works alongside them. For new code, skip manual memoization entirely.

---

## `after()` API — Post-Response Work (Next.js 15+)

Schedule work to run after the response is sent. Use for logging, analytics, cache warming — anything that should not block the user.

```tsx
import { after } from 'next/server';
import { log } from '@/lib/logger';

export default async function CheckoutPage() {
  const order = await processCheckout();

  // Runs AFTER response is sent to user — does not block page render
  after(async () => {
    await log('checkout_completed', { orderId: order.id });
    await sendConfirmationEmail(order);
    await updateAnalytics('purchase', order.total);
  });

  return <OrderConfirmation order={order} />;
}

// Also works in Server Actions and Route Handlers
'use server';
export async function deleteAccount(userId: string) {
  await db.user.delete({ where: { id: userId } });

  after(async () => {
    await cleanupUserData(userId);    // S3, Stripe, etc.
    await notifyAdminTeam(userId);
  });
}

// In Route Handlers
import { after, NextResponse } from 'next/server';

export async function POST(request: Request) {
  const data = await request.json();
  const result = await processWebhook(data);

  after(async () => {
    await logWebhook(data, result);
  });

  return NextResponse.json({ success: true });
}
```

---

## `forbidden()` and `unauthorized()` (Next.js 15.1+)

Throw authorization errors that render `forbidden.tsx` (403) or `unauthorized.tsx` (401) boundary files. Pair with `forbidden.tsx`/`unauthorized.tsx` files in your route segments.

```tsx
// app/admin/page.tsx
import { forbidden } from 'next/navigation';

export default async function AdminPage() {
  const session = await getSession();
  if (!session) redirect('/login');
  if (session.role !== 'admin') forbidden();  // renders forbidden.tsx

  return <AdminDashboard />;
}

// app/admin/forbidden.tsx
'use client';
export default function Forbidden() {
  return (
    <div>
      <h2>Access Denied</h2>
      <p>You do not have permission to view this page.</p>
    </div>
  );
}

// unauthorized() works the same way for 401 responses
import { unauthorized } from 'next/navigation';

export default async function ProtectedPage() {
  const session = await getSession();
  if (!session) unauthorized();  // renders unauthorized.tsx
  // ...
}
```

Enable in next.config.ts:
```ts
const nextConfig = { experimental: { authInterrupts: true } };
```

---

## Partial Prerendering (PPR) — Experimental

PPR combines static shell (instant load) with dynamic streaming holes. The static parts are served from CDN, dynamic parts stream in via Suspense.

```tsx
// next.config.ts — enable incrementally
const nextConfig: NextConfig = {
  experimental: {
    ppr: 'incremental',  // opt-in per route
  },
};

// app/products/[id]/page.tsx — opt into PPR
export const experimental_ppr = true;

export default async function ProductPage({ params }: Props) {
  const { id } = await params;
  const product = await getProduct(id);  // static — cached at build time

  return (
    <div>
      {/* Static shell — served from CDN */}
      <ProductInfo product={product} />
      <ProductImages product={product} />

      {/* Dynamic hole — streams in after static shell */}
      <Suspense fallback={<PriceSkeleton />}>
        <DynamicPrice productId={id} />  {/* uses cookies/headers = dynamic */}
      </Suspense>

      <Suspense fallback={<ReviewsSkeleton />}>
        <Reviews productId={id} />  {/* personalized = dynamic */}
      </Suspense>
    </div>
  );
}
```

**How it works:** At build time, Next.js prerenders the static shell (everything outside `<Suspense>`). At request time, the static HTML is served instantly from CDN, then the dynamic Suspense boundaries stream in. Result: static speed + dynamic personalization.

---

## Instrumentation Hook (`instrumentation.ts`)

Runs once when the Next.js server starts. Use for OpenTelemetry setup, monitoring initialization, or global error tracking.

```tsx
// instrumentation.ts (project root)
import type { Instrumentation } from 'next';

export async function register() {
  // Runs once on server startup
  if (process.env.NEXT_RUNTIME === 'nodejs') {
    // Initialize OTel, Sentry, Datadog, etc.
    const { NodeSDK } = await import('@opentelemetry/sdk-node');
    const sdk = new NodeSDK({ /* ... */ });
    sdk.start();
  }
}

// Optional: track all server errors globally
export const onRequestError: Instrumentation.onRequestError = async (
  error,
  request,
  context,
) => {
  await fetch('https://monitoring.example.com/report', {
    method: 'POST',
    body: JSON.stringify({
      message: error.message,
      path: request.path,
      method: request.method,
      routeType: context.routeType,  // 'page' | 'route' | 'middleware'
    }),
  });
};
```

---

## Turbopack (Stable for Dev in Next.js 15)

Turbopack is now the default dev bundler in Next.js 15. Faster HMR and cold starts than webpack.

```bash
# Turbopack is used automatically in dev (Next.js 15+)
next dev                # uses Turbopack by default
next dev --turbopack    # explicit flag (same behavior)
```

No configuration changes needed. Turbopack supports the same `next.config.ts` options as webpack for development. For production builds, webpack is still used (`next build`).

---

## View Transitions (Experimental)

Enable native browser View Transitions for smooth page navigation animations.

```tsx
// next.config.ts
const nextConfig: NextConfig = {
  experimental: {
    viewTransition: true,
  },
};

// Use React's ViewTransition component for animated elements
import { unstable_ViewTransition as ViewTransition } from 'react';

export function ProductCard({ product }: { product: Product }) {
  return (
    <ViewTransition name={`product-${product.id}`}>
      <Link href={`/products/${product.id}`}>
        <img src={product.image} alt={product.name} />
        <h3>{product.name}</h3>
      </Link>
    </ViewTransition>
  );
}
```

**Status:** Experimental. Requires React canary. Chrome/Edge/Safari 18+ support. No Firefox yet.

---

## Anti-Patterns

| Anti-Pattern | Why It's Dangerous | Fix |
|---|---|---|
| `'use client'` on page level | Entire page becomes client-rendered | Push down to smallest interactive component |
| `useEffect` for data fetching | Loading spinners, waterfalls, no SSR | Fetch in Server Components |
| `useSearchParams` without Suspense | Opts entire page out of SSG | Wrap in Suspense boundary |
| Not awaiting params/searchParams | Build errors in Next.js 15 | `const { id } = await params` |
| Fetching in layout.tsx | Blocks entire layout, can't stream | Fetch in page.tsx or child components |
| Sequential fetches | Waterfall — slow page loads | `Promise.all()` or Suspense boundaries |
| `router.push` for navigation | Client-side only, no prefetching | `<Link>` component (prefetches) |
| Giant Client Components | Large JS bundles, slow TTI | Split: Server wrapper + small Client parts |
| No loading.tsx | Blank screen during navigation | Add loading.tsx with skeletons |
| `typeof window !== 'undefined'` | Wrong mental model | Use 'use client' directive properly |
| Unnecessary state for URL data | Not shareable, not bookmarkable | useSearchParams + URL state |
| Not using `<Image>` | No optimization, layout shift | `next/image` for all images |
| Manual `useMemo`/`useCallback` everywhere | Unnecessary with React Compiler | Enable React Compiler, write plain React |
| `unstable_cache` in new code | Being replaced | `'use cache'` + `cacheLife()` + `cacheTag()` |
| Blocking response with analytics/logging | Slow responses for non-critical work | `after()` for post-response tasks |
| Generic 404 for auth errors | Poor UX, no distinction | `forbidden()` / `unauthorized()` + boundary files |
| `useEffect` for optimistic updates | Complex, error-prone | `useOptimistic` hook |
| Prop drilling form pending state | Boilerplate | `useFormStatus` in child components |

---

## RSC Boundary Detection & Serialization Rules

When data crosses from a Server Component to a Client Component, it must be serialized to JSON for transport over the network. Many JavaScript types are **not** JSON-serializable and will silently break or produce unexpected results.

### What Can Cross the Server-Client Boundary

| Type | Serializable? | Notes |
|---|---|---|
| `string` | Yes | |
| `number` (finite) | Yes | `NaN`, `Infinity` are also supported by React |
| `boolean` | Yes | |
| `null` | Yes | |
| `undefined` | Yes | Supported by React's serialization |
| Plain object `{}` | Yes | Nested values must also be serializable |
| Array `[]` | Yes | Elements must be serializable |
| `Promise<T>` | Yes | Passed as prop, unwrap with `use()` on client |
| JSX (Server Component) | Yes | Rendered on server, HTML sent to client |
| `Date` | **No** | Becomes empty object `{}` silently |
| `Map` | **No** | Silently drops data |
| `Set` | **No** | Silently drops data |
| `RegExp` | **No** | Silently drops data |
| `Function` | **No** | Cannot serialize closures |
| `class` instance | **No** | Loses methods, prototype chain |
| `Symbol` | **No** | Not serializable |
| DOM nodes | **No** | Server has no DOM |
| `BigInt` | **No** | Not JSON-serializable |

### Conversion Patterns

```tsx
// Server Component — convert before passing to Client Component
export default async function EventPage({ params }: Props) {
  const { id } = await params;
  const event = await getEvent(id);

  return (
    <EventDetails
      // Convert non-serializable types before crossing the boundary
      title={event.title}
      date={event.date.toISOString()}          // Date -> string
      tags={Array.from(event.tags)}             // Set -> array
      metadata={Object.fromEntries(event.meta)} // Map -> plain object
      attendeeCount={Number(event.count)}       // BigInt -> number (if safe)
    />
  );
}

// Client Component — reconstruct if needed
'use client';

export function EventDetails({ title, date, tags, metadata, attendeeCount }: Props) {
  const eventDate = new Date(date);  // string -> Date
  const tagSet = new Set(tags);       // array -> Set (if needed)

  return (
    <div>
      <h1>{title}</h1>
      <time dateTime={date}>
        {eventDate.toLocaleDateString()}
      </time>
      <p>{attendeeCount} attending</p>
    </div>
  );
}
```

### Diagnostic: Silent Serialization Failures

The most dangerous aspect is that failures are **silent** — no error is thrown. The data simply arrives as `undefined` or `{}` on the client. Always verify prop types at the Client Component boundary during development:

```tsx
'use client';

export function DebugProps(props: Record<string, unknown>) {
  if (process.env.NODE_ENV === 'development') {
    for (const [key, value] of Object.entries(props)) {
      if (value instanceof Date) console.warn(`Prop "${key}" is a Date — convert to ISO string`);
      if (value instanceof Map) console.warn(`Prop "${key}" is a Map — convert to object/array`);
      if (value instanceof Set) console.warn(`Prop "${key}" is a Set — convert to array`);
      if (typeof value === 'function') console.warn(`Prop "${key}" is a function — cannot serialize`);
    }
  }
  return null;
}
```

---

## Error Handling Gotcha: `redirect()` / `notFound()` in try-catch

`redirect()` and `notFound()` work by **throwing special errors** (`NEXT_REDIRECT`, `NEXT_HTTP_ERROR_FALLBACK;404`). If you wrap code in a `try-catch`, these errors get silently swallowed and the redirect/404 never happens.

### The Bug

```tsx
// BUG: redirect() and notFound() are silently swallowed
import { redirect, notFound } from 'next/navigation';

export default async function Page({ params }: Props) {
  try {
    const { id } = await params;
    const post = await fetch(`https://api.example.com/posts/${id}`).then((res) => {
      if (res.status === 404) notFound();       // Throws NEXT_HTTP_ERROR_FALLBACK
      if (res.status === 401) redirect('/login'); // Throws NEXT_REDIRECT
      if (!res.ok) throw new Error(res.statusText);
      return res.json();
    });

    return <PostDetail post={post} />;
  } catch (err) {
    // This catches EVERYTHING — including Next.js internal errors
    console.error(err);
    return <p>Something went wrong</p>; // notFound() and redirect() never fire
  }
}
```

### The Fix: `unstable_rethrow()`

```tsx
// FIXED: use unstable_rethrow() to re-throw Next.js internal errors
import { redirect, notFound } from 'next/navigation';
import { unstable_rethrow } from 'next/navigation';

export default async function Page({ params }: Props) {
  try {
    const { id } = await params;
    const post = await fetch(`https://api.example.com/posts/${id}`).then((res) => {
      if (res.status === 404) notFound();
      if (res.status === 401) redirect('/login');
      if (!res.ok) throw new Error(res.statusText);
      return res.json();
    });

    return <PostDetail post={post} />;
  } catch (err) {
    unstable_rethrow(err); // Re-throws if it's a Next.js internal error
    // Only your application errors reach this point
    console.error(err);
    return <p>Something went wrong</p>;
  }
}
```

**Rule:** Whenever you use `try-catch` in a Server Component or Server Action that might call `redirect()`, `notFound()`, `forbidden()`, or `unauthorized()`, always call `unstable_rethrow(err)` as the first line in your `catch` block.

---

## Self-Hosting Next.js

### Standalone Output for Docker

Set `output: 'standalone'` in `next.config.ts` to produce a minimal, self-contained build that includes only the necessary `node_modules`. This dramatically reduces Docker image size.

```ts
// next.config.ts
import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  output: 'standalone', // Produces .next/standalone with minimal node_modules
};
export default nextConfig;
```

### Multi-Stage Dockerfile

```dockerfile
# Stage 1: Install dependencies
FROM node:20-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --ignore-scripts

# Stage 2: Build the application
FROM node:20-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Build-time env vars are baked into the bundle
ENV NEXT_TELEMETRY_DISABLED=1
RUN npm run build

# Stage 3: Production runner
FROM node:20-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Required for Docker: listen on all interfaces
ENV HOSTNAME=0.0.0.0
ENV PORT=3000

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Copy standalone output
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs
EXPOSE 3000

CMD ["node", "server.js"]
```

### Environment Variables: Build-Time vs Runtime

| Type | Prefix | Behavior |
|---|---|---|
| Server-only | No prefix (`DATABASE_URL`) | Available at runtime via `process.env` — can differ per environment |
| Public (browser) | `NEXT_PUBLIC_` | **Inlined at build time** — baked into JS bundle, cannot change at runtime |
| Docker runtime | `HOSTNAME=0.0.0.0` | Required for Docker to accept external connections |

**Key implication:** `NEXT_PUBLIC_*` variables are replaced at `next build` time. To use different values per environment with a single Docker image, use the App Router and read server-side env vars in Server Components or Route Handlers, then pass values to Client Components as props.

### Custom ISR Cache Handler

When self-hosting, the default file-system cache is local to each container. For multi-pod deployments (Kubernetes, ECS), you need a shared cache backend like Redis.

```ts
// next.config.ts
import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  cacheHandler: require.resolve('./cache-handler.js'),
  cacheMaxMemorySize: 0, // Disable in-memory cache — use external store only
};
export default nextConfig;
```

```js
// cache-handler.js — Redis-based ISR cache handler
const { createClient } = require('redis');

const client = createClient({ url: process.env.REDIS_URL });
client.connect();

module.exports = {
  async get(cacheKey) {
    const stored = await client.get(cacheKey);
    if (!stored) return undefined;

    const data = JSON.parse(stored);
    return {
      value: new ReadableStream({
        start(controller) {
          controller.enqueue(Buffer.from(data.value, 'base64'));
          controller.close();
        },
      }),
      tags: data.tags,
      stale: data.stale,
      timestamp: data.timestamp,
      expire: data.expire,
      revalidate: data.revalidate,
    };
  },

  async set(cacheKey, pendingEntry) {
    const entry = await pendingEntry;
    const reader = entry.value.getReader();
    const chunks = [];

    try {
      while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        chunks.push(value);
      }
    } finally {
      reader.releaseLock();
    }

    const data = Buffer.concat(chunks.map((chunk) => Buffer.from(chunk)));

    await client.set(
      cacheKey,
      JSON.stringify({
        value: data.toString('base64'),
        tags: entry.tags,
        stale: entry.stale,
        timestamp: entry.timestamp,
        expire: entry.expire,
        revalidate: entry.revalidate,
      }),
      { EX: entry.expire },
    );
  },

  async refreshTags() {
    // No-op for basic Redis — implement tag syncing if needed
  },

  async getExpiration() {
    return 0;
  },

  async updateTags() {
    // Implement tag-based invalidation for revalidateTag() support
  },
};
```

### OpenNext for Serverless Self-Hosting

[OpenNext](https://open-next.js.org/) adapts Next.js for serverless platforms without Vercel:

- **AWS Lambda** — deploys Next.js as Lambda functions with CloudFront CDN
- **Cloudflare Workers** — edge-first deployment
- **SST (Serverless Stack)** — uses OpenNext under the hood for AWS deployments

OpenNext handles ISR, image optimization, middleware, and other Vercel-specific features in a platform-agnostic way. Consider it when you need serverless but cannot use Vercel.

---

## Metadata & OG Image Generation

### Dynamic Metadata with `generateMetadata`

```tsx
// app/products/[id]/page.tsx
import type { Metadata } from 'next';

type Props = {
  params: Promise<{ id: string }>;
};

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { id } = await params;
  const product = await getProduct(id);

  return {
    title: product.name,
    description: product.description,
    openGraph: {
      title: product.name,
      description: product.description,
      images: [`/api/og?title=${encodeURIComponent(product.name)}`],
    },
    twitter: {
      card: 'summary_large_image',
      title: product.name,
      description: product.description,
    },
  };
}

export default async function ProductPage({ params }: Props) {
  const { id } = await params;
  const product = await getProduct(id);
  return <ProductDetail product={product} />;
}
```

### Dynamic OG Images with `next/og`

```tsx
// app/api/og/route.tsx
import { ImageResponse } from 'next/og';
import type { NextRequest } from 'next/server';

export const runtime = 'edge';

export async function GET(request: NextRequest) {
  const { searchParams } = request.nextUrl;
  const title = searchParams.get('title') ?? 'My Site';

  return new ImageResponse(
    (
      <div
        style={{
          width: '100%',
          height: '100%',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          backgroundColor: '#0a0a0a',
          color: '#fafafa',
          fontFamily: 'Inter, sans-serif',
        }}
      >
        <h1 style={{ fontSize: 64, fontWeight: 700, margin: 0 }}>{title}</h1>
        <p style={{ fontSize: 28, color: '#a1a1aa', marginTop: 16 }}>
          mysite.com
        </p>
      </div>
    ),
    { width: 1200, height: 630 },
  );
}
```

### Route-Level OG Images (File Convention)

```tsx
// app/products/[id]/opengraph-image.tsx
// Automatically generates OG image for this route segment
import { ImageResponse } from 'next/og';

export const alt = 'Product image';
export const size = { width: 1200, height: 630 };
export const contentType = 'image/png';

export default async function Image({ params }: { params: { id: string } }) {
  const product = await getProduct(params.id);

  return new ImageResponse(
    (
      <div
        style={{
          width: '100%',
          height: '100%',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          backgroundColor: '#000',
          color: '#fff',
          fontSize: 48,
        }}
      >
        {product.name}
      </div>
    ),
    { ...size },
  );
}
```

### Sitemap & Robots (File Conventions)

```tsx
// app/sitemap.ts — static sitemap
import type { MetadataRoute } from 'next';

export default function sitemap(): MetadataRoute.Sitemap {
  return [
    { url: 'https://example.com', lastModified: new Date(), changeFrequency: 'yearly', priority: 1 },
    { url: 'https://example.com/about', lastModified: new Date(), changeFrequency: 'monthly', priority: 0.8 },
  ];
}

// app/sitemap.ts — dynamic sitemap for large sites
export async function generateSitemaps() {
  // Fetch total product count and split into chunks
  const products = await getProducts();
  const sitemaps = [];
  for (let i = 0; i < products.length; i += 50000) {
    sitemaps.push({ id: i });
  }
  return sitemaps; // Creates /sitemap/0.xml, /sitemap/50000.xml, etc.
}

export default async function sitemap({ id }: { id: number }): Promise<MetadataRoute.Sitemap> {
  const products = await getProducts({ offset: id, limit: 50000 });
  return products.map((product) => ({
    url: `https://example.com/products/${product.id}`,
    lastModified: product.updatedAt,
  }));
}
```

```tsx
// app/robots.ts
import type { MetadataRoute } from 'next';

export default function robots(): MetadataRoute.Robots {
  return {
    rules: {
      userAgent: '*',
      allow: '/',
      disallow: ['/admin/', '/api/'],
    },
    sitemap: 'https://example.com/sitemap.xml',
  };
}
```

**File convention summary:**
- `opengraph-image.tsx` / `opengraph-image.png` — OG image for route segment
- `twitter-image.tsx` / `twitter-image.png` — Twitter card image for route segment
- `sitemap.ts` — sitemap generation
- `robots.ts` — robots.txt generation
- `manifest.ts` — PWA manifest

---

## Font Optimization (`next/font`)

Load fonts with zero layout shift and no external network requests. Fonts are self-hosted automatically.

### Google Fonts

```tsx
// app/layout.tsx
import { Inter, JetBrains_Mono } from 'next/font/google';

const inter = Inter({
  subsets: ['latin'],
  display: 'swap',        // Show fallback font immediately, swap when loaded
  variable: '--font-inter', // CSS variable for Tailwind
});

const jetbrainsMono = JetBrains_Mono({
  subsets: ['latin'],
  display: 'swap',
  variable: '--font-mono',
});

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={`${inter.variable} ${jetbrainsMono.variable}`}>
      <body className={inter.className}>{children}</body>
    </html>
  );
}
```

### Local Fonts

```tsx
import localFont from 'next/font/local';

const geist = localFont({
  src: [
    { path: './fonts/Geist-Regular.woff2', weight: '400', style: 'normal' },
    { path: './fonts/Geist-Medium.woff2', weight: '500', style: 'normal' },
    { path: './fonts/Geist-Bold.woff2', weight: '700', style: 'normal' },
  ],
  display: 'swap',
  variable: '--font-geist',
});
```

### Using with Tailwind CSS

```css
/* app/globals.css (Tailwind v4) */
@theme {
  --font-sans: var(--font-inter);
  --font-mono: var(--font-mono);
}
```

```css
/* tailwind.config.ts (Tailwind v3) */
/* extend: { fontFamily: { sans: ['var(--font-inter)'], mono: ['var(--font-mono)'] } } */
```

### Display Strategies

| Strategy | Behavior | Use When |
|---|---|---|
| `'swap'` | Show fallback immediately, swap when font loads | Default choice — good for body text |
| `'optional'` | Use font only if cached, never block rendering | Performance-critical pages, tolerate fallback |
| `'auto'` | Browser decides | Rarely needed |
| `'block'` | Hide text briefly until font loads | Icons, logo text (short invisible period) |
| `'fallback'` | Brief block, then fallback, swap if loaded quickly | Compromise between swap and block |

### Variable Fonts

Prefer variable fonts to reduce file count and bundle size. Instead of loading 4 weight-specific files, a single variable font file covers all weights:

```tsx
const inter = Inter({
  subsets: ['latin'],
  display: 'swap',
  // Variable font — no need to specify individual weights
  // Automatically supports weight range 100-900
});
```

---

## Parallel & Intercepting Routes (Complete Pattern)

### Parallel Routes with `@slot` Convention

Parallel routes render multiple pages in the same layout simultaneously. Define slots with `@` prefix folders.

```
app/
├── layout.tsx          # Receives @analytics and @team as props
├── page.tsx            # Main content
├── @analytics/
│   ├── page.tsx        # /dashboard — analytics panel
│   └── default.tsx     # Fallback when navigating to unmatched route
├── @team/
│   ├── page.tsx        # /dashboard — team panel
│   └── default.tsx     # Fallback when navigating to unmatched route
└── settings/
    └── page.tsx        # /dashboard/settings — only main content changes
```

```tsx
// app/layout.tsx — parallel slots are passed as props
export default function DashboardLayout({
  children,
  analytics,
  team,
}: {
  children: React.ReactNode;
  analytics: React.ReactNode;
  team: React.ReactNode;
}) {
  return (
    <div className="grid grid-cols-3 gap-4">
      <main className="col-span-2">{children}</main>
      <aside>
        {analytics}
        {team}
      </aside>
    </div>
  );
}
```

### `default.tsx` — Required for Parallel Route Slots

Every parallel route slot **must** have a `default.tsx`. When soft-navigating to a route that does not have a matching segment for a slot, Next.js renders the `default.tsx` for that slot. Without it, the build fails (Next.js 16+) or the slot renders nothing.

```tsx
// app/@analytics/default.tsx
// Option A: render nothing
export default function Default() {
  return null;
}

// Option B: show not-found UI
import { notFound } from 'next/navigation';
export default function Default() {
  notFound();
}
```

### Intercepting Routes for Modal Pattern

Intercepting routes let you "intercept" a route and show it in a modal overlay while keeping the current page visible. Direct navigation (hard refresh, shared link) loads the full page.

```
app/
├── layout.tsx
├── page.tsx                    # Feed page — shows list of photos
├── @modal/
│   ├── default.tsx             # Returns null when no modal is active
│   └── (.)photo/[id]/
│       └── page.tsx            # Intercepted route — shows photo in modal
└── photo/[id]/
    └── page.tsx                # Direct route — full photo page
```

**Convention:** The `(.)` prefix means "intercept from the same level":
- `(.)` — same level
- `(..)` — one level up
- `(..)(..)` — two levels up
- `(...)` — from root

```tsx
// app/layout.tsx
export default function RootLayout({
  children,
  modal,
}: {
  children: React.ReactNode;
  modal: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>
        {children}
        {modal}
      </body>
    </html>
  );
}

// app/@modal/default.tsx
export default function Default() {
  return null;
}

// app/@modal/(.)photo/[id]/page.tsx — modal version
'use client';
import { useRouter } from 'next/navigation';

export default function PhotoModal({ params }: { params: { id: string } }) {
  const router = useRouter();

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/60"
      onClick={() => router.back()} // Close modal on backdrop click
    >
      <div
        className="relative max-w-3xl rounded-lg bg-white p-6"
        onClick={(e) => e.stopPropagation()} // Prevent closing when clicking modal content
      >
        <button
          onClick={() => router.back()}
          className="absolute right-4 top-4"
          aria-label="Close"
        >
          &times;
        </button>
        <PhotoDetail id={params.id} />
      </div>
    </div>
  );
}

// app/photo/[id]/page.tsx — full page version (direct access / hard refresh)
export default async function PhotoPage({ params }: Props) {
  const { id } = await params;
  const photo = await getPhoto(id);
  return <PhotoDetail photo={photo} />;
}
```

### Conditional Slots

Use parallel routes to conditionally render content based on conditions like auth state:

```tsx
// app/layout.tsx
import { getSession } from '@/lib/auth';

export default async function Layout({
  children,
  dashboard,
  login,
}: {
  children: React.ReactNode;
  dashboard: React.ReactNode;
  login: React.ReactNode;
}) {
  const session = await getSession();
  return session ? dashboard : login;
}
```

---

## Problematic Packages

Packages known to cause issues with Next.js App Router and Server Components:

| Package | Issue | Workaround |
|---|---|---|
| `sharp` | Needs native binaries in Docker | `npm install --os=linux --cpu=x64 sharp` or use `output: 'standalone'` |
| `bcrypt` | Native module, breaks in Edge Runtime | Use `bcryptjs` (pure JS implementation) |
| `recharts` | Client-only, large bundle (~450kb) | `dynamic(() => import('...'), { ssr: false })` |
| `react-quill` | Accesses `window`/`document` at import | `dynamic(() => import('...'), { ssr: false })` |
| `node-canvas` | Native C++ module, complex build | Use `@napi-rs/canvas` or offload to API route |
| `dotenv` | Conflicts with Next.js built-in `.env` loading | Remove — Next.js loads `.env` files natively |
| `moment` | Massive bundle, locale files included | Use `date-fns` or `dayjs` with tree-shaking |
| `lodash` | Full bundle imported by default | Use `lodash-es` + `optimizePackageImports`, or individual imports |
| `@aws-sdk/*` | Large, pulls in many sub-packages | Import only specific clients; use `optimizePackageImports` |
| `mongoose` | Cannot run in Edge Runtime | Use in API routes/Server Actions with Node.js runtime only |

```tsx
// Dynamic import pattern for client-only packages
import dynamic from 'next/dynamic';

const RichTextEditor = dynamic(() => import('react-quill'), {
  ssr: false,
  loading: () => <div className="h-64 animate-pulse rounded bg-gray-100" />,
});

const Chart = dynamic(() => import('recharts').then((mod) => mod.LineChart), {
  ssr: false,
});
```

---

## React Performance Patterns

### Barrel File Optimization

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

### Waterfall Elimination

```tsx
// BAD — sequential waterfall: each await blocks the next
export default async function UserProfile({ params }: Props) {
  const { id } = await params;
  const user = await getUser(id);          // 200ms
  const posts = await getUserPosts(id);     // 300ms — waits for user
  const followers = await getFollowers(id); // 150ms — waits for posts
  // Total: 650ms sequential
  return <Profile user={user} posts={posts} followers={followers} />;
}

// GOOD — parallel with Promise.all
export default async function UserProfile({ params }: Props) {
  const { id } = await params;
  const [user, posts, followers] = await Promise.all([
    getUser(id),
    getUserPosts(id),
    getFollowers(id),
  ]);
  // Total: 300ms (slowest fetch)
  return <Profile user={user} posts={posts} followers={followers} />;
}

// BEST — streaming: start all fetches, pass promises down, unwrap at leaves
export default async function UserProfile({ params }: Props) {
  const { id } = await params;
  const userPromise = getUser(id);
  const postsPromise = getUserPosts(id);
  const followersPromise = getFollowers(id);

  // Fastest data renders first, slower data streams in
  return (
    <div>
      <Suspense fallback={<HeaderSkeleton />}>
        <ProfileHeader userPromise={userPromise} />
      </Suspense>
      <Suspense fallback={<PostsSkeleton />}>
        <PostsList postsPromise={postsPromise} />
      </Suspense>
      <Suspense fallback={<FollowersSkeleton />}>
        <FollowersPanel followersPromise={followersPromise} />
      </Suspense>
    </div>
  );
}

// Client component unwraps with use()
'use client';
import { use } from 'react';

function PostsList({ postsPromise }: { postsPromise: Promise<Post[]> }) {
  const posts = use(postsPromise);
  return posts.map((post) => <PostCard key={post.id} post={post} />);
}
```

### `React.cache()` for Request Deduplication

Wrap expensive functions with `React.cache()` so multiple components calling the same function within a single request only execute it once:

```tsx
// lib/data.ts
import { cache } from 'react';

// Without cache: if 3 components call getUser(), it runs 3 times
// With cache: runs once per request, subsequent calls return cached result
export const getUser = cache(async (userId: string): Promise<User> => {
  const user = await db.user.findUnique({ where: { id: userId } });
  if (!user) throw new Error('User not found');
  return user;
});

// Multiple components can call getUser(id) — only one DB query per request
// app/profile/layout.tsx
export default async function ProfileLayout({ children }: Props) {
  const user = await getUser(currentUserId); // First call — executes query
  return <ProfileShell user={user}>{children}</ProfileShell>;
}

// app/profile/page.tsx
export default async function ProfilePage() {
  const user = await getUser(currentUserId); // Second call — returns cached result
  return <ProfileContent user={user} />;
}
```

**Important:** `React.cache()` is per-request only — it does not persist across requests. For cross-request caching, use `'use cache'` + `cacheLife()`.

### RSC Serialization Minimization

Only pass the data a Client Component actually needs. Never pass entire database objects:

```tsx
// BAD — passes entire user object with sensitive fields
<UserAvatar user={user} />

// GOOD — pass only what the client needs
<UserAvatar name={user.name} imageUrl={user.avatarUrl} />
```

### Re-render Optimization Rules

1. **Move state down** — keep state in the closest component to where it is used, not in a shared parent
2. **Extract components that change** from components that do not — when part of a component re-renders frequently, extract the changing part into its own component
3. **Pass components as `children`** — the parent re-renders, but `children` is a stable reference and does not re-render
4. **Use composition (`children` prop)** instead of conditional rendering that re-mounts — `{show && <Heavy />}` re-mounts on every toggle; instead, always render and use CSS to hide
5. **Avoid object/array literals in JSX** — `style={{ color: 'red' }}` creates a new object every render, forcing child re-renders. Extract to a constant or `useMemo`
6. **Avoid inline function definitions for expensive children** — `<ExpensiveList onSelect={(id) => setSelected(id)} />` creates a new function reference every render. With React Compiler this is auto-memoized, but be aware for non-compiled code
7. **Use `key` to force remount when identity changes** — do not use array index as key if items can reorder. Use a stable ID
8. **Lift expensive computations out of render** — use `React.cache()`, `'use cache'`, or compute in a Server Component

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

### CSS `content-visibility: auto` for Long Lists

For long scrollable content, use CSS-level virtualization before reaching for JavaScript virtualization libraries:

```css
/* Apply to each item in a long list */
.list-item {
  content-visibility: auto;
  contain-intrinsic-size: 0 80px; /* estimated height */
}
```

This tells the browser to skip rendering off-screen items entirely. Unlike JS virtualization, it preserves accessibility (screen readers still see all content) and search (Ctrl+F works).

### Preload on Hover

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

### React 19 `<Activity>` Component (Experimental)

`<Activity>` hides/shows UI while preserving state, DOM, and effects — similar to Android's Activity lifecycle. Useful for tab panels, cached views, and back/forward navigation.

```tsx
import { unstable_Activity as Activity } from 'react';

function TabPanel({ activeTab }: { activeTab: string }) {
  return (
    <div>
      {/* Both tabs stay mounted — state is preserved when switching */}
      <Activity mode={activeTab === 'posts' ? 'visible' : 'hidden'}>
        <PostsTab />
      </Activity>
      <Activity mode={activeTab === 'comments' ? 'visible' : 'hidden'}>
        <CommentsTab />
      </Activity>
    </div>
  );
}
```

**Status:** Experimental in React 19. API may change. The `'hidden'` mode detaches effects and hides the DOM subtree without unmounting.

---

## React Composition Patterns

### Compound Components with Context

The compound component pattern lets related components share implicit state. The parent provides context, children consume it.

```tsx
// components/tabs.tsx
'use client';
import { createContext, use, useState, type ReactNode } from 'react';

// Internal context — not exported
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

// Root component — provides context
function Tabs({ defaultTab, children }: { defaultTab: string; children: ReactNode }) {
  const [activeTab, setActiveTab] = useState(defaultTab);
  return (
    <TabsContext value={{ activeTab, setActiveTab }}>
      <div role="tablist">{children}</div>
    </TabsContext>
  );
}

// Trigger component — switches tabs
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

// Content component — shows when active
function TabsContent({ value, children }: { value: string; children: ReactNode }) {
  const { activeTab } = useTabsContext();
  if (activeTab !== value) return null;
  return <div role="tabpanel">{children}</div>;
}

// Attach sub-components to parent
Tabs.Trigger = TabsTrigger;
Tabs.Content = TabsContent;
export { Tabs };

// Usage — clean, declarative API
<Tabs defaultTab="overview">
  <Tabs.Trigger value="overview">Overview</Tabs.Trigger>
  <Tabs.Trigger value="analytics">Analytics</Tabs.Trigger>
  <Tabs.Trigger value="settings">Settings</Tabs.Trigger>

  <Tabs.Content value="overview"><OverviewPanel /></Tabs.Content>
  <Tabs.Content value="analytics"><AnalyticsPanel /></Tabs.Content>
  <Tabs.Content value="settings"><SettingsPanel /></Tabs.Content>
</Tabs>
```

### Boolean Prop Elimination

Avoid boolean props that lead to inconsistent, hard-to-maintain APIs:

```tsx
// BAD — boolean props create 2^n combinations, many of which conflict
<Button primary large disabled outline />
// What happens when both primary and outline are true?

// GOOD — explicit variants with discriminated values
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

### Generic Context Pattern

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

---

## Hydration Error Debugging

Hydration errors occur when the server-rendered HTML does not match the client-rendered DOM. React cannot reconcile the differences and throws an error.

### Common Causes

| Cause | Example | Fix |
|---|---|---|
| Browser extensions | Extensions inject `<div>`, `<script>`, or modify attributes | Test in incognito mode; use `suppressHydrationWarning` on `<body>` if needed |
| `Date`/time differences | `new Date().toLocaleString()` differs between server and client | Use `useEffect` + state, or format on the server with a fixed timezone |
| Browser-only APIs in initial render | `window.innerWidth`, `navigator.language` | Guard with `useEffect` or dynamic import with `ssr: false` |
| `Math.random()` in render | Different values on server and client | Generate on server, pass as prop |
| Incorrect HTML nesting | `<p><div>...</div></p>` — browser auto-corrects, server does not | Fix HTML structure |
| Third-party scripts | Scripts modify DOM before hydration | Load with `next/script` using `afterInteractive` strategy |

### `suppressHydrationWarning`

For intentional mismatches (timestamps, user-specific data), use `suppressHydrationWarning`:

```tsx
// Only suppresses the warning — does NOT fix the mismatch
// The client render will take over with the client value
<time suppressHydrationWarning>
  {new Date().toLocaleTimeString()}
</time>
```

### Pattern: Client-Only Values

```tsx
'use client';
import { useState, useEffect } from 'react';

export function ClientTimestamp({ serverTime }: { serverTime: string }) {
  const [clientTime, setClientTime] = useState(serverTime); // Match server on first render

  useEffect(() => {
    // After hydration, update with client's local time
    setClientTime(new Date().toLocaleTimeString());
    const interval = setInterval(() => {
      setClientTime(new Date().toLocaleTimeString());
    }, 1000);
    return () => clearInterval(interval);
  }, []);

  return <time>{clientTime}</time>;
}
```

### Debugging Approach

1. Open the browser error overlay — React shows a diff of server HTML vs client HTML
2. Search for the mismatched element in your code
3. If caused by a browser extension, test in incognito
4. If caused by dynamic data (`Date`, `Math.random`), move to `useEffect`
5. If caused by third-party scripts, use `next/script` with proper loading strategy
6. If caused by incorrect HTML nesting, validate with the W3C validator

---

## Scripts & Third Parties

### `next/script` Loading Strategies

```tsx
import Script from 'next/script';

// beforeInteractive — loads before page hydration (rare, use for critical polyfills)
<Script src="/polyfill.js" strategy="beforeInteractive" />

// afterInteractive (default) — loads after page hydration
<Script
  src="https://www.googletagmanager.com/gtag/js?id=G-XXXXX"
  strategy="afterInteractive"
/>

// lazyOnload — loads during browser idle time (lowest priority)
<Script src="https://widget.example.com/embed.js" strategy="lazyOnload" />

// worker — offloads to web worker via Partytown (experimental)
<Script
  src="https://www.googletagmanager.com/gtag/js?id=G-XXXXX"
  strategy="worker"
/>
```

### `@next/third-parties`

Pre-built integrations for common third-party services with optimized loading:

```tsx
// Google Analytics
import { GoogleAnalytics } from '@next/third-parties/google';

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
      <GoogleAnalytics gaId="G-XXXXX" />
    </html>
  );
}

// Google Tag Manager
import { GoogleTagManager } from '@next/third-parties/google';

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <GoogleTagManager gtmId="GTM-XXXXX" />
      <body>{children}</body>
    </html>
  );
}

// YouTube Embed (lazy-loaded, facade pattern)
import { YouTubeEmbed } from '@next/third-parties/google';

export function VideoSection() {
  return <YouTubeEmbed videoid="dQw4w9WgXcQ" params="controls=0" />;
}
```

### Script Event Handlers

```tsx
<Script
  src="https://checkout.stripe.com/checkout.js"
  strategy="lazyOnload"
  onLoad={() => {
    console.log('Stripe script loaded');
  }}
  onError={(e) => {
    console.error('Failed to load Stripe script', e);
  }}
/>
```

---

## Checklist: Next.js Code Review

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
- [ ] React Compiler enabled — no manual `useMemo`/`useCallback` in new code
- [ ] `after()` used for analytics, logging, and non-blocking side effects
- [ ] `instrumentation.ts` set up for monitoring/OTel
- [ ] Images use `next/image`
- [ ] Metadata exported from pages/layouts
- [ ] No full-page client rendering
- [ ] Non-serializable types (`Date`, `Map`, `Set`) converted before crossing RSC boundary
- [ ] `redirect()` / `notFound()` not swallowed by `try-catch` blocks (`unstable_rethrow` used)
- [ ] `optimizePackageImports` configured for heavy barrel-export packages
- [ ] `React.cache()` used for request-level deduplication of shared data fetching
- [ ] Dynamic imports with `{ ssr: false }` for client-only heavy packages
- [ ] `generateMetadata` used for dynamic page metadata (not hardcoded)
- [ ] Fonts loaded via `next/font` (not CDN link tags)
- [ ] Self-hosting considerations documented if not deploying to Vercel
- [ ] Parallel route slots have `default.tsx` files
- [ ] Third-party scripts loaded via `next/script` with appropriate strategy
- [ ] No hydration mismatches from `Date`, `Math.random`, or browser-only APIs in initial render
