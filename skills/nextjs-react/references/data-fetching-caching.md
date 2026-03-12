# Data Fetching & Caching

## Table of Contents

- [Server Component Data Fetching](#server-component-data-fetching)
- [use cache Directive](#use-cache-directive)
- [Built-in Cache Profiles](#built-in-cache-profiles)
- [Conditional Caching](#conditional-caching)
- [Cache Invalidation from Server Actions](#cache-invalidation-from-server-actions)
- [Migration from unstable_cache](#migration-from-unstable_cache)
- [Parallel Data Fetching](#parallel-data-fetching)
- [Streaming with Suspense](#streaming-with-suspense)
- [React.cache for Request Deduplication](#reactcache-for-request-deduplication)
- [RSC Serialization Minimization](#rsc-serialization-minimization)

---

## Server Component Data Fetching

```tsx
// Server Component -- fetch directly
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

---

## use cache Directive

The `'use cache'` directive (Next.js 15.1+) is the modern caching API, replacing `unstable_cache`. Add it to functions or entire components to cache their output. Use `cacheLife()` to control TTL and `cacheTag()` for targeted revalidation.

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
```

---

## Built-in Cache Profiles

`'default'`, `'seconds'`, `'minutes'`, `'hours'`, `'days'`, `'weeks'`, `'max'`.

---

## Conditional Caching

```tsx
async function getPost(slug: string) {
  'use cache';
  cacheTag(`post-${slug}`);
  const post = await fetchPost(slug);

  if (!post) {
    cacheLife('minutes');  // not found -- cache briefly
    return null;
  }
  cacheLife('days');  // published content -- cache longer
  return post;
}
```

---

## Cache Invalidation from Server Actions

```tsx
'use server';
import { revalidateTag } from 'next/cache';

export async function updateUser(userId: string, data: UpdateUserData) {
  await db.user.update({ where: { id: userId }, data });
  revalidateTag(`user-${userId}`);  // bust the cache
}
```

---

## Migration from unstable_cache

Replace `unstable_cache(fn, keys, opts)` with `'use cache'` + `cacheTag()` + `cacheLife()` inside the function body.

---

## Parallel Data Fetching

```tsx
// BAD -- sequential waterfall: each await blocks the next
export default async function UserProfile({ params }: Props) {
  const { id } = await params;
  const user = await getUser(id);          // 200ms
  const posts = await getUserPosts(id);     // 300ms -- waits for user
  const followers = await getFollowers(id); // 150ms -- waits for posts
  // Total: 650ms sequential
  return <Profile user={user} posts={posts} followers={followers} />;
}

// GOOD -- parallel with Promise.all
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

// BEST -- streaming: start all fetches, pass promises down, unwrap at leaves
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

---

## Streaming with Suspense

```tsx
// BETTER -- streaming with Suspense (shows UI progressively)
export default async function Dashboard() {
  const user = await getUser(); // Fast -- needed for layout
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

## React.cache for Request Deduplication

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

// Multiple components can call getUser(id) -- only one DB query per request
// app/profile/layout.tsx
export default async function ProfileLayout({ children }: Props) {
  const user = await getUser(currentUserId); // First call -- executes query
  return <ProfileShell user={user}>{children}</ProfileShell>;
}

// app/profile/page.tsx
export default async function ProfilePage() {
  const user = await getUser(currentUserId); // Second call -- returns cached result
  return <ProfileContent user={user} />;
}
```

**Important:** `React.cache()` is per-request only -- it does not persist across requests. For cross-request caching, use `'use cache'` + `cacheLife()`.

---

## RSC Serialization Minimization

Only pass the data a Client Component actually needs. Never pass entire database objects:

```tsx
// BAD -- passes entire user object with sensitive fields
<UserAvatar user={user} />

// GOOD -- pass only what the client needs
<UserAvatar name={user.name} imageUrl={user.avatarUrl} />
```
