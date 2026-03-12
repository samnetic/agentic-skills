# Server Actions & Form Handling

## Table of Contents

- [Server Action Pattern](#server-action-pattern)
- [Form Component with useActionState](#form-component-with-useactionstate)
- [Error Handling: redirect/notFound in try-catch](#error-handling-redirectnotfound-in-try-catch)
- [The Fix: unstable_rethrow](#the-fix-unstable_rethrow)
- [forbidden() and unauthorized()](#forbidden-and-unauthorized)
- [after() API -- Post-Response Work](#after-api----post-response-work)

---

## Server Action Pattern

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
```

---

## Form Component with useActionState

```tsx
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

## Error Handling: redirect/notFound in try-catch

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
    // This catches EVERYTHING -- including Next.js internal errors
    console.error(err);
    return <p>Something went wrong</p>; // notFound() and redirect() never fire
  }
}
```

---

## The Fix: unstable_rethrow

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

## forbidden() and unauthorized()

Throw authorization errors that render `forbidden.tsx` (403) or `unauthorized.tsx` (401) boundary files. Available in Next.js 15.1+.

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

## after() API -- Post-Response Work

Schedule work to run after the response is sent (Next.js 15+). Use for logging, analytics, cache warming -- anything that should not block the user.

```tsx
import { after } from 'next/server';
import { log } from '@/lib/logger';

export default async function CheckoutPage() {
  const order = await processCheckout();

  // Runs AFTER response is sent to user -- does not block page render
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
