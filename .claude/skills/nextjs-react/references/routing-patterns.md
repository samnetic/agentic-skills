# Routing Patterns

## Table of Contents

- [Route Organization](#route-organization)
- [Route File Conventions](#route-file-conventions)
- [Dynamic Route Params (Next.js 15+)](#dynamic-route-params-nextjs-15)
- [useSearchParams + Suspense](#usesearchparams--suspense)
- [Parallel Routes](#parallel-routes)
- [default.tsx for Parallel Route Slots](#defaulttsx-for-parallel-route-slots)
- [Intercepting Routes for Modal Pattern](#intercepting-routes-for-modal-pattern)
- [Conditional Slots](#conditional-slots)
- [Partial Prerendering (PPR)](#partial-prerendering-ppr)
- [Middleware and Instrumentation](#middleware-and-instrumentation)

---

## Route Organization

```
app/
+-- layout.tsx              # Root layout (html, body, providers)
+-- page.tsx                # Home page
+-- loading.tsx             # Root loading UI
+-- error.tsx               # Root error boundary
+-- not-found.tsx           # 404 page
+-- (marketing)/            # Route group (no URL segment)
|   +-- layout.tsx          # Marketing layout
|   +-- page.tsx            # / (home)
|   +-- about/page.tsx      # /about
+-- (app)/                  # App route group
|   +-- layout.tsx          # Authenticated layout with sidebar
|   +-- dashboard/
|   |   +-- page.tsx        # /dashboard
|   |   +-- loading.tsx     # Dashboard skeleton
|   +-- settings/
|       +-- page.tsx        # /settings
|       +-- layout.tsx      # Settings sub-layout with tabs
+-- api/
|   +-- webhooks/
|       +-- stripe/route.ts # POST /api/webhooks/stripe
+-- middleware.ts           # Edge middleware (auth, redirects)
+-- instrumentation.ts     # Server startup hooks (OTel, monitoring)
```

---

## Route File Conventions

- `page.tsx` -- route component (required to make route accessible)
- `layout.tsx` -- shared layout (wraps children, preserved on navigation)
- `loading.tsx` -- instant Suspense fallback
- `error.tsx` -- error boundary (`'use client'` required)
- `not-found.tsx` -- 404 UI
- `forbidden.tsx` -- 403 UI (Next.js 15.1+)
- `unauthorized.tsx` -- 401 UI (Next.js 15.1+)
- `route.ts` -- API route handler (cannot coexist with page.tsx)
- `instrumentation.ts` -- server startup and error tracking hooks

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

## useSearchParams + Suspense

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

## Parallel Routes

Parallel routes render multiple pages in the same layout simultaneously. Define slots with `@` prefix folders.

```
app/
+-- layout.tsx          # Receives @analytics and @team as props
+-- page.tsx            # Main content
+-- @analytics/
|   +-- page.tsx        # /dashboard -- analytics panel
|   +-- default.tsx     # Fallback when navigating to unmatched route
+-- @team/
|   +-- page.tsx        # /dashboard -- team panel
|   +-- default.tsx     # Fallback when navigating to unmatched route
+-- settings/
    +-- page.tsx        # /dashboard/settings -- only main content changes
```

```tsx
// app/layout.tsx -- parallel slots are passed as props
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

---

## default.tsx for Parallel Route Slots

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

---

## Intercepting Routes for Modal Pattern

Intercepting routes let you "intercept" a route and show it in a modal overlay while keeping the current page visible. Direct navigation (hard refresh, shared link) loads the full page.

```
app/
+-- layout.tsx
+-- page.tsx                    # Feed page -- shows list of photos
+-- @modal/
|   +-- default.tsx             # Returns null when no modal is active
|   +-- (.)photo/[id]/
|       +-- page.tsx            # Intercepted route -- shows photo in modal
+-- photo/[id]/
    +-- page.tsx                # Direct route -- full photo page
```

**Convention:** The `(.)` prefix means "intercept from the same level":
- `(.)` -- same level
- `(..)` -- one level up
- `(..)(..)` -- two levels up
- `(...)` -- from root

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

// app/@modal/(.)photo/[id]/page.tsx -- modal version
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

// app/photo/[id]/page.tsx -- full page version (direct access / hard refresh)
export default async function PhotoPage({ params }: Props) {
  const { id } = await params;
  const photo = await getPhoto(id);
  return <PhotoDetail photo={photo} />;
}
```

---

## Conditional Slots

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

## Partial Prerendering (PPR)

PPR combines static shell (instant load) with dynamic streaming holes. The static parts are served from CDN, dynamic parts stream in via Suspense.

```tsx
// next.config.ts -- enable incrementally
const nextConfig: NextConfig = {
  experimental: {
    ppr: 'incremental',  // opt-in per route
  },
};

// app/products/[id]/page.tsx -- opt into PPR
export const experimental_ppr = true;

export default async function ProductPage({ params }: Props) {
  const { id } = await params;
  const product = await getProduct(id);  // static -- cached at build time

  return (
    <div>
      {/* Static shell -- served from CDN */}
      <ProductInfo product={product} />
      <ProductImages product={product} />

      {/* Dynamic hole -- streams in after static shell */}
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

## Middleware and Instrumentation

### Instrumentation Hook (`instrumentation.ts`)

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
