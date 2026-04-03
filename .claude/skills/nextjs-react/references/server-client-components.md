# Server & Client Components

## Table of Contents

- [Decision Tree](#decision-tree)
- [Push use client Down](#push-use-client-down)
- [RSC Boundary Serialization Rules](#rsc-boundary-serialization-rules)
- [Conversion Patterns](#conversion-patterns)
- [Diagnostic: Silent Serialization Failures](#diagnostic-silent-serialization-failures)
- [Hydration Error Debugging](#hydration-error-debugging)
- [suppressHydrationWarning](#suppresshydrationwarning)
- [Client-Only Values Pattern](#client-only-values-pattern)
- [Hydration Debugging Approach](#hydration-debugging-approach)

---

## Decision Tree

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

---

## Push use client Down

```tsx
// BAD -- entire page is client-side
'use client'; // at page level
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

// GOOD -- only interactive part is client
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

## RSC Boundary Serialization Rules

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

---

## Conversion Patterns

```tsx
// Server Component -- convert before passing to Client Component
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

// Client Component -- reconstruct if needed
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

---

## Diagnostic: Silent Serialization Failures

The most dangerous aspect is that failures are **silent** -- no error is thrown. The data simply arrives as `undefined` or `{}` on the client. Always verify prop types at the Client Component boundary during development:

```tsx
'use client';

export function DebugProps(props: Record<string, unknown>) {
  if (process.env.NODE_ENV === 'development') {
    for (const [key, value] of Object.entries(props)) {
      if (value instanceof Date) console.warn(`Prop "${key}" is a Date -- convert to ISO string`);
      if (value instanceof Map) console.warn(`Prop "${key}" is a Map -- convert to object/array`);
      if (value instanceof Set) console.warn(`Prop "${key}" is a Set -- convert to array`);
      if (typeof value === 'function') console.warn(`Prop "${key}" is a function -- cannot serialize`);
    }
  }
  return null;
}
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
| Incorrect HTML nesting | `<p><div>...</div></p>` -- browser auto-corrects, server does not | Fix HTML structure |
| Third-party scripts | Scripts modify DOM before hydration | Load with `next/script` using `afterInteractive` strategy |

---

## suppressHydrationWarning

For intentional mismatches (timestamps, user-specific data), use `suppressHydrationWarning`:

```tsx
// Only suppresses the warning -- does NOT fix the mismatch
// The client render will take over with the client value
<time suppressHydrationWarning>
  {new Date().toLocaleTimeString()}
</time>
```

---

## Client-Only Values Pattern

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

---

## Hydration Debugging Approach

1. Open the browser error overlay -- React shows a diff of server HTML vs client HTML
2. Search for the mismatched element in your code
3. If caused by a browser extension, test in incognito
4. If caused by dynamic data (`Date`, `Math.random`), move to `useEffect`
5. If caused by third-party scripts, use `next/script` with proper loading strategy
6. If caused by incorrect HTML nesting, validate with the W3C validator
