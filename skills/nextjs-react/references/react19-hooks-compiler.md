# React 19 Hooks & Compiler

## Table of Contents

- [use() Hook](#use-hook)
- [useOptimistic](#useoptimistic)
- [useFormStatus](#useformstatus)
- [React Compiler (Auto Memoization)](#react-compiler-auto-memoization)
- [View Transitions (Experimental)](#view-transitions-experimental)
- [Activity Component (Experimental)](#activity-component-experimental)

---

## use() Hook

Read Promises and Context in render. Unlike `useContext`, `use()` can be called inside `if`/loops.

```tsx
import { use, Suspense } from 'react';

// Read a promise during render -- component suspends until resolved
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

---

## useOptimistic

Instant UI updates that auto-revert if the server action throws.

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

---

## useFormStatus

Access parent form state from a child component. Must be a CHILD of `<form>` -- does not work in the same component as the form.

```tsx
'use client';
import { useFormStatus } from 'react-dom';

// Must be a CHILD of <form>
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

### Configuration

```tsx
// next.config.ts -- enable React Compiler
import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  experimental: {
    reactCompiler: true,  // auto-memoizes everything
  },
};
export default nextConfig;
```

### Before/After

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

// AFTER (React Compiler handles it -- just write plain React)
'use client';
function UserList({ users }: Props) {
  const sorted = users.sort(byName);
  const handleClick = (id: string) => router.push(`/users/${id}`);
  return sorted.map(u => <UserCard key={u.id} user={u} onClick={handleClick} />);
}
// Compiler auto-memoizes sorted, handleClick, and the component itself
```

**Rules:** Write idiomatic React following the Rules of React. The compiler understands hooks, conditional rendering, and component boundaries. Leave existing `useMemo`/`useCallback` in place -- the compiler works alongside them. For new code, skip manual memoization entirely.

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

## Activity Component (Experimental)

`<Activity>` hides/shows UI while preserving state, DOM, and effects -- similar to Android's Activity lifecycle. Useful for tab panels, cached views, and back/forward navigation.

```tsx
import { unstable_Activity as Activity } from 'react';

function TabPanel({ activeTab }: { activeTab: string }) {
  return (
    <div>
      {/* Both tabs stay mounted -- state is preserved when switching */}
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
