# Advanced Features: RLS, JSONB, ORM Patterns, and Supabase

## Table of Contents

- [Row-Level Security (RLS)](#row-level-security-rls)
- [Supabase Patterns (RLS + PostgREST)](#supabase-patterns-rls--postgrest)
  - [RLS with PostgREST/Supabase Auth](#rls-with-postgrestsupabase-auth)
  - [Supabase Security Best Practices](#supabase-security-best-practices)
- [ORM Selection Guide](#orm-selection-guide)
- [Prisma ORM Patterns](#prisma-orm-patterns)
- [Drizzle ORM Patterns](#drizzle-orm-patterns)
- [Drizzle vs Prisma Comparison](#drizzle-vs-prisma--when-to-pick-which)

---

## Row-Level Security (RLS)

```sql
-- Enable RLS
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents FORCE ROW LEVEL SECURITY; -- Apply to table owner too

-- Policy: users see only their own documents
CREATE POLICY users_own_documents ON documents
  FOR ALL
  USING (user_id = current_setting('app.current_user_id')::bigint)
  WITH CHECK (user_id = current_setting('app.current_user_id')::bigint);

-- Policy: admins see everything
CREATE POLICY admins_see_all ON documents
  FOR SELECT
  USING (current_setting('app.current_role') = 'admin');

-- Set context in application (per-request)
SET LOCAL app.current_user_id = '42';
SET LOCAL app.current_role = 'user';
```

**RLS Rules:**
1. Always use `FORCE ROW LEVEL SECURITY` — otherwise table owners bypass policies
2. Use `SET LOCAL` (transaction-scoped) not `SET` (session-scoped)
3. Test with both authorized and unauthorized users
4. Wrap policy predicates in a `SECURITY DEFINER` function for complex logic
5. RLS adds overhead — benchmark on realistic data volumes

---

## Supabase Patterns (RLS + PostgREST)

### RLS with PostgREST/Supabase Auth

```sql
-- Supabase uses JWT claims in RLS policies via auth.uid() and auth.jwt()
-- Enable RLS on all tables exposed through the API
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Policy: users read/update their own profile
CREATE POLICY "Users read own profile" ON profiles
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users update own profile" ON profiles
  FOR UPDATE USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Policy: service role bypasses RLS (for server-side admin operations)
CREATE POLICY "Service role full access" ON profiles
  FOR ALL USING (auth.role() = 'service_role');

-- Policy: check JWT custom claims for roles
CREATE POLICY "Admins manage all" ON profiles
  FOR ALL USING ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

-- Team-based access using a junction table
CREATE POLICY "Team members see team data" ON projects
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM team_members
      WHERE team_members.team_id = projects.team_id
        AND team_members.user_id = auth.uid()
    )
  );
```

### Supabase Security Best Practices

```sql
-- NEVER expose tables directly. Use views for controlled access:
CREATE VIEW public.user_profiles AS
  SELECT id, display_name, avatar_url  -- exclude email, phone
  FROM profiles;

-- Revoke direct table access from anon/authenticated roles
REVOKE ALL ON profiles FROM anon, authenticated;
GRANT SELECT ON public.user_profiles TO authenticated;

-- Use SECURITY DEFINER functions for complex operations
CREATE OR REPLACE FUNCTION public.get_team_stats(team_id_input bigint)
RETURNS TABLE(member_count int, project_count int)
LANGUAGE sql SECURITY DEFINER SET search_path = ''
AS $$
  SELECT
    (SELECT count(*)::int FROM public.team_members WHERE team_id = team_id_input),
    (SELECT count(*)::int FROM public.projects WHERE team_id = team_id_input);
$$;
```

---

## ORM Selection Guide

```
ORM Selection:
├── Type-safe, SQL-like, lightweight → Drizzle ORM
├── Auto-migration, schema-first, broad ecosystem → Prisma
├── Complex queries, raw SQL when needed → Drizzle ORM
├── Python project → SQLAlchemy 2.0
├── Maximum control, performance-critical → Raw SQL (pg/postgres.js)
└── Rapid prototyping → Prisma
```

---

## Prisma ORM Patterns

```typescript
// Efficient relation loading (avoid N+1)
const users = await prisma.user.findMany({
  where: { active: true },
  include: {
    posts: {
      where: { published: true },
      orderBy: { createdAt: 'desc' },
      take: 5,
    },
  },
});

// Cursor pagination with Prisma
const posts = await prisma.post.findMany({
  take: 20,
  skip: 1,  // skip the cursor
  cursor: { id: lastPostId },
  orderBy: { createdAt: 'desc' },
  where: { published: true },
});

// Transaction with isolation
const result = await prisma.$transaction(async (tx) => {
  const account = await tx.account.findUnique({
    where: { id: accountId },
  });
  if (account.balance < amount) throw new Error('Insufficient funds');
  return tx.account.update({
    where: { id: accountId },
    data: { balance: { decrement: amount } },
  });
}, { isolationLevel: 'Serializable' });

// Raw query for complex operations
const result = await prisma.$queryRaw`
  SELECT department, COUNT(*) as count, AVG(salary)::numeric(10,2) as avg_salary
  FROM employees
  WHERE hired_at > ${startDate}
  GROUP BY department
  HAVING COUNT(*) > 5
`;
```

---

## Drizzle ORM Patterns

```typescript
// Schema definition — type-safe, SQL-like
import { pgTable, bigint, text, timestamp, boolean, jsonb, index, uniqueIndex } from 'drizzle-orm/pg-core';
import { relations } from 'drizzle-orm';

export const users = pgTable('users', {
  id: bigint('id', { mode: 'number' }).primaryKey().generatedAlwaysAsIdentity(),
  email: text('email').notNull(),
  name: text('name').notNull(),
  active: boolean('active').notNull().default(true),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
}, (table) => [
  uniqueIndex('idx_users_email').on(table.email),
]);

export const posts = pgTable('posts', {
  id: bigint('id', { mode: 'number' }).primaryKey().generatedAlwaysAsIdentity(),
  authorId: bigint('author_id', { mode: 'number' }).notNull().references(() => users.id),
  title: text('title').notNull(),
  content: text('content').notNull(),
  metadata: jsonb('metadata').$type<{ tags: string[]; readTime: number }>(),
  published: boolean('published').notNull().default(false),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
}, (table) => [
  index('idx_posts_author').on(table.authorId),
  index('idx_posts_published_created').on(table.published, table.createdAt),
]);

// Define relations for relational query API
export const usersRelations = relations(users, ({ many }) => ({
  posts: many(posts),
}));

export const postsRelations = relations(posts, ({ one }) => ({
  author: one(users, { fields: [posts.authorId], references: [users.id] }),
}));

// --- Queries ---

import { drizzle } from 'drizzle-orm/node-postgres';
import { eq, desc, and, gt, sql } from 'drizzle-orm';
import * as schema from './schema';

const db = drizzle({ connection: process.env.DATABASE_URL, schema });

// Relational query (no manual JOIN — Drizzle generates optimal SQL)
const usersWithPosts = await db.query.users.findMany({
  where: eq(users.active, true),
  with: {
    posts: {
      where: eq(posts.published, true),
      orderBy: [desc(posts.createdAt)],
      limit: 5,
    },
  },
});

// SQL-like query builder (full control)
const recentPosts = await db
  .select({
    id: posts.id,
    title: posts.title,
    authorName: users.name,
  })
  .from(posts)
  .innerJoin(users, eq(posts.authorId, users.id))
  .where(and(eq(posts.published, true), gt(posts.createdAt, new Date('2024-01-01'))))
  .orderBy(desc(posts.createdAt))
  .limit(20);

// Transaction
const result = await db.transaction(async (tx) => {
  const [user] = await tx.insert(users).values({ email: 'a@b.com', name: 'Alice' }).returning();
  await tx.insert(posts).values({ authorId: user.id, title: 'First Post', content: '...' });
  return user;
});

// Raw SQL escape hatch (still type-safe with sql template)
const stats = await db.execute(sql`
  SELECT department, COUNT(*)::int AS count, AVG(salary)::numeric(10,2) AS avg_salary
  FROM employees WHERE hired_at > ${startDate}
  GROUP BY department HAVING COUNT(*) > 5
`);
```

---

## Drizzle vs Prisma — When to Pick Which

| Aspect | Drizzle | Prisma |
|---|---|---|
| Schema definition | TypeScript code (co-located) | Separate `.prisma` file |
| Query style | SQL-like builder + relational API | Custom API (less SQL knowledge) |
| Bundle size | ~50KB | ~2MB+ (engine binary) |
| Raw SQL | First-class `sql` template | `$queryRaw` escape hatch |
| Serverless | Excellent (no binary engine) | Requires engine, cold starts |
| Migrations | SQL-based (`drizzle-kit`) | Prisma Migrate (auto-generated) |
