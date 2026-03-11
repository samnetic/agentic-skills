---
name: postgres-db
description: >-
  PostgreSQL database expertise — design, optimization, operations, and ORM integration.
  Covers PostgreSQL 15–18 features including MERGE, JSON_TABLE, pg_stat_io, incremental
  backup, improved VACUUM, native uuidv7(), asynchronous I/O, and OAuth authentication.
  Use when designing schemas, writing queries, optimizing slow queries with EXPLAIN ANALYZE,
  creating indexes (B-tree, GIN, GiST, BRIN, HNSW), implementing Row-Level Security (RLS),
  setting up connection pooling (PgBouncer, Supavisor), partitioning tables, managing
  migrations, using JSONB effectively, writing CTEs and window functions, configuring
  replication (logical and physical), implementing full-text search, vector/embedding
  search (pgvector), working with Prisma ORM or Drizzle ORM patterns, analyzing pg_stat
  views, tuning postgresql.conf, implementing cursor pagination, designing for
  multi-tenancy, UUIDv7 primary keys, Supabase patterns, or troubleshooting PostgreSQL
  performance issues.
  Triggers: PostgreSQL, postgres, SQL, database, query, index, migration, schema,
  EXPLAIN, RLS, Prisma, Drizzle, pgbouncer, Supavisor, partition, replication, JSONB,
  CTE, window function, full-text search, pg_stat, vacuum, connection pool, pgvector,
  embedding, MERGE, JSON_TABLE, UUIDv7, Supabase.
---

# PostgreSQL Expert Skill

Write correct, performant, secure PostgreSQL. Every query should be explainable,
every index justified, every migration safe for zero-downtime deployment.

---

## Core Principles

| Principle | Meaning |
|---|---|
| **Correctness first** | Get the right answer before optimizing for speed |
| **Normalize by default** | Denormalize only with measured evidence |
| **Index what you query** | Every WHERE, JOIN, ORDER BY should have index support |
| **Migrations are code** | Versioned, reversible, reviewed, tested |
| **Security at the data layer** | RLS + least privilege + encrypted connections |
| **Measure, don't guess** | EXPLAIN ANALYZE before and after every optimization |

---

## Workflow

Follow these steps when approaching any PostgreSQL task:

1. **Clarify the requirement** — Understand the access pattern, data volume, and concurrency needs before writing any SQL.
2. **Choose the right data types** — Use `timestamptz`, `text`, `numeric` for money, `bigint`/UUIDv7 for PKs. Read [references/schema-and-types.md](references/schema-and-types.md) for the full type guide.
3. **Design the schema** — Normalize by default. Add constraints, foreign keys, and CHECK constraints at the database level.
4. **Write the query** — Use CTEs, window functions, and cursor pagination. See [references/query-optimization.md](references/query-optimization.md) for patterns.
5. **Add indexes** — Use the index decision tree to pick the right type (B-tree, GIN, GiST, BRIN, HNSW). Verify with EXPLAIN.
6. **Verify with EXPLAIN ANALYZE** — Check for row estimate mismatches, unnecessary Seq Scans, and high buffer reads.
7. **Plan the migration** — Use `CREATE INDEX CONCURRENTLY`, add constraints as `NOT VALID` first, and test rollback. See [references/operations.md](references/operations.md).
8. **Apply security** — Enable RLS for multi-tenant data, configure connection pooling. See [references/advanced-features.md](references/advanced-features.md).
9. **Validate against checklist** — Run through the checklist below before shipping.

---

## Progressive Disclosure Map

Read these references when you need deeper detail on a specific topic:

- When designing tables, choosing data types, UUIDv7, or using PG 16–18 features (MERGE, JSON_TABLE, AIO): see [references/schema-and-types.md](references/schema-and-types.md) for details
- When writing queries, choosing indexes, reading EXPLAIN output, full-text search, pgvector, or partitioning: see [references/query-optimization.md](references/query-optimization.md) for details
- When planning migrations, configuring PgBouncer/Supavisor, diagnosing performance, or tuning postgresql.conf: see [references/operations.md](references/operations.md) for details
- When implementing RLS, choosing Prisma vs Drizzle ORM, or building Supabase patterns: see [references/advanced-features.md](references/advanced-features.md) for details

---

## Key Decision Trees

### Index Type Selection

```
What kind of query?
├── Equality (=) or Range (<, >, BETWEEN, ORDER BY)
│   └── B-tree (default, covers 90% of cases)
├── Full-text search (tsvector, @@)
│   └── GIN
├── JSONB containment (@>, ?, ?|, ?&)
│   └── GIN (with jsonb_path_ops for @> only)
├── Array containment (@>, &&)
│   └── GIN
├── Pattern matching (LIKE 'prefix%')
│   └── B-tree with text_pattern_ops
├── Pattern matching (ILIKE, regex)
│   └── GIN with pg_trgm
├── Geometric / PostGIS
│   └── GiST
├── Large table, naturally ordered (timestamp, ID)
│   └── BRIN (tiny index, great for append-only)
└── Only need specific rows indexed
    └── Partial index: CREATE INDEX ... WHERE condition
```

### Partition Decision

```
When to partition?
├── Table > 100M rows or > 50GB → Partition
├── Time-series data with retention → Range partition by time
├── Queries always filter by category → List partition
├── Even distribution needed (sharding prep) → Hash partition
├── Table < 10M rows → Don't partition (overhead not worth it)
└── Mixed access patterns → Consider partial indexes first
```

### ORM Selection

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

## Essential Patterns

### EXPLAIN Reading Guide

```sql
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) SELECT ...;

-- Key things to look for:
-- Seq Scan      → Missing index? Or small table where seq scan is optimal
-- Nested Loop   → Good for small result sets, bad for large joins
-- Hash Join     → Good for equality joins on large tables
-- Sort          → Check if index can avoid sort (ORDER BY matches index)
-- Bitmap Scan   → Multiple index conditions combined
-- actual time   → First row time..last row time (ms)
-- rows          → Estimated vs actual (big difference = stale stats → ANALYZE)
-- Buffers       → shared hit (cache) vs read (disk)

-- Red flags:
-- actual rows >> estimated rows  → Run ANALYZE, check stats
-- Seq Scan on large table        → Add index
-- Sort with high cost            → Add index matching ORDER BY
-- Nested Loop with large outer   → Consider Hash Join hint or restructure
```

### Cursor-Based Pagination (Always Prefer)

```sql
-- First page
SELECT id, title, created_at
FROM posts
WHERE published = true
ORDER BY created_at DESC, id DESC
LIMIT 20;

-- Next page (after last item: created_at='2024-06-15', id=42)
SELECT id, title, created_at
FROM posts
WHERE published = true
  AND (created_at, id) < ('2024-06-15T00:00:00Z', 42)
ORDER BY created_at DESC, id DESC
LIMIT 20;
```
**Why**: O(1) regardless of page depth. Offset pagination is O(n).

### Zero-Downtime Migration Rules

| Operation | Safe? | Safe Alternative |
|---|---|---|
| Add column with DEFAULT (PG 11+) | YES | Just do it (metadata-only since PG 11) |
| Add NOT NULL column | NO | Add nullable → backfill → add NOT NULL constraint |
| Drop column | NO (if app reads it) | Deploy app that ignores column first → then drop |
| Rename column | NO | Add new column → backfill → update app → drop old |
| Add index | NO (locks table) | `CREATE INDEX CONCURRENTLY` (always) |
| Change column type | NO (rewrites table) | Add new column → backfill → swap |
| Add constraint | MAYBE | `ALTER TABLE ADD CONSTRAINT ... NOT VALID; VALIDATE CONSTRAINT ...;` |

### Data Types Quick Reference

| Use Case | Type | NOT This |
|---|---|---|
| Primary key | `bigint GENERATED ALWAYS AS IDENTITY` or `uuid` | `serial` (legacy), `int` (will overflow) |
| Strings | `text` | `varchar(255)` (arbitrary limit) |
| Money | `numeric(19,4)` | `float`, `real`, `money` |
| Timestamps | `timestamptz` (ALWAYS with timezone) | `timestamp` (ambiguous) |
| Enums | `text` + `CHECK` constraint | PostgreSQL `ENUM` type (hard to modify) |
| JSON (queried) | `jsonb` | `json` (no indexing) |

---

## Anti-Patterns

| Anti-Pattern | Why It's Dangerous | Fix |
|---|---|---|
| `SELECT *` | Fetches unnecessary data, breaks with schema changes | List specific columns |
| `OFFSET` for deep pagination | O(n) — scans and discards rows | Cursor pagination |
| Missing `WHERE` on `UPDATE/DELETE` | Modifies entire table | Always have predicates, use transactions |
| `varchar(255)` everywhere | Arbitrary limit, no perf benefit over `text` | Use `text` + CHECK constraint |
| Indexing every column | Write overhead, storage waste | Index what queries need |
| N+1 queries (ORM loop) | 1000 users = 1001 queries | Use `include`/`join`/batch loading |
| `timestamp` without timezone | Ambiguous times, DST bugs | `timestamptz` always |
| `ENUM` type in PostgreSQL | Hard to modify (requires ALTER TYPE) | `text` + CHECK constraint |
| Not using `CONCURRENTLY` for indexes | Locks table for writes during creation | `CREATE INDEX CONCURRENTLY` |
| Storing money as float | Rounding errors accumulate | `numeric(19,4)` |
| No connection pooling | Exhausts max_connections | PgBouncer or built-in pool |
| UUIDs as primary key (v4) | Random → index fragmentation, bloat | UUIDv7 (time-ordered) or bigint |
| CTEs as optimization fences | Pre-PG 12 CTEs always materialized | Use `NOT MATERIALIZED` hint (PG 12+) |
| Partitioning small tables | Overhead of partition pruning > benefit | Only partition tables > 100M rows or > 50GB |
| Ignoring EXPLAIN output | Guessing at query performance | Always run `EXPLAIN (ANALYZE, BUFFERS)` |

---

## Checklist: Every Database Task

- [ ] Data types are appropriate (timestamptz, text, numeric for money)
- [ ] Primary keys are bigint or UUIDv7 (not serial, not UUIDv4)
- [ ] Foreign keys have indexes
- [ ] Queries verified with EXPLAIN (ANALYZE, BUFFERS)
- [ ] EXPLAIN output checked for red flags (row estimate mismatches, unnecessary Seq Scans)
- [ ] Migrations use CONCURRENTLY for indexes
- [ ] Migrations are reversible (down migration exists)
- [ ] No N+1 query patterns in application code
- [ ] Connection pooling configured
- [ ] RLS enabled for multi-tenant data
- [ ] Sensitive data encrypted (pgcrypto for at-rest)
- [ ] Backup and restore tested (consider PG 17 incremental backup)
- [ ] UUIDv7 used instead of UUIDv4 for UUID primary keys
- [ ] pgvector indexes use HNSW (preferred) or IVFFlat for vector columns
- [ ] pg_stat_statements enabled and monitored for query regression
- [ ] MERGE used for complex upsert/sync logic (PG 15+)
- [ ] JSON_TABLE considered for JSON-heavy query patterns (PG 17+)
- [ ] Partitioning evaluated for tables > 100M rows or > 50GB
- [ ] Full-text search uses GIN-indexed tsvector columns (not LIKE '%query%')
- [ ] CTEs use MATERIALIZED/NOT MATERIALIZED hints when optimization matters (PG 12+)
- [ ] ORM choice justified (Drizzle for SQL-like control, Prisma for rapid development)
