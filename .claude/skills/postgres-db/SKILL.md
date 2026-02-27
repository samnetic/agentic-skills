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

## PostgreSQL 16/17 Modern Features

### MERGE Statement (SQL Standard — PG 15+, enhanced PG 17)

```sql
-- Upsert with full SQL-standard MERGE (cleaner than INSERT...ON CONFLICT for complex logic)
MERGE INTO inventory AS target
USING incoming_shipment AS source
ON target.product_id = source.product_id AND target.warehouse_id = source.warehouse_id
WHEN MATCHED AND source.quantity = 0 THEN
  DELETE
WHEN MATCHED THEN
  UPDATE SET quantity = target.quantity + source.quantity, updated_at = now()
WHEN NOT MATCHED THEN
  INSERT (product_id, warehouse_id, quantity, updated_at)
  VALUES (source.product_id, source.warehouse_id, source.quantity, now());

-- PG 17: MERGE with RETURNING clause + MERGE_ACTION()
MERGE INTO customer_accounts AS ca
USING new_transactions AS nt ON ca.id = nt.customer_id
WHEN MATCHED THEN
  UPDATE SET balance = ca.balance + nt.amount
WHEN NOT MATCHED THEN
  INSERT (id, balance) VALUES (nt.customer_id, nt.amount)
RETURNING merge_action(), ca.id, ca.balance;
-- Returns: 'INSERT' or 'UPDATE' | id | balance
```

**When to use MERGE vs INSERT...ON CONFLICT:**
- `MERGE`: Multiple conditions (update some, delete others, insert new), cross-table sync, RETURNING with action tracking
- `INSERT...ON CONFLICT`: Simple upsert on a single table (still preferred for performance)

### JSON_TABLE and SQL/JSON Functions (PG 17)

```sql
-- JSON_TABLE: Convert JSON data into relational rows
SELECT jt.*
FROM api_responses r,
  JSON_TABLE(
    r.body, '$.items[*]'
    COLUMNS (
      item_id   int          PATH '$.id',
      name      text         PATH '$.name',
      price     numeric(10,2) PATH '$.price',
      in_stock  boolean      PATH '$.available' DEFAULT true ON EMPTY
    )
  ) AS jt
WHERE jt.price > 10.00;

-- JSON_EXISTS: Check for JSON path existence
SELECT * FROM products
WHERE JSON_EXISTS(metadata, '$.ratings.average ? (@ > 4.0)');

-- JSON_QUERY: Extract JSON sub-objects
SELECT id, JSON_QUERY(metadata, '$.tags') AS tags
FROM products;

-- JSON_VALUE: Extract scalar values from JSON
SELECT id, JSON_VALUE(metadata, '$.author.name' RETURNING text) AS author_name
FROM articles;
```

### pg_stat_io — I/O Analysis (PG 16+)

`pg_stat_io` is a **built-in system view** in PostgreSQL 16+. It does NOT require any
extension or entry in `shared_preload_libraries` — it is always available.

```sql
-- I/O statistics by backend type and context
SELECT backend_type, io_object, io_context,
       reads, read_bytes, read_time,
       writes, write_bytes, write_time,
       extends, extends_bytes,
       hits  -- buffer cache hits
FROM pg_stat_io
WHERE reads > 0 OR writes > 0
ORDER BY read_bytes + write_bytes DESC;

-- Identify I/O-heavy operations (bulk reads from seq scans vs buffer hits)
SELECT backend_type, io_context,
       hits AS buffer_hits,
       reads AS disk_reads,
       round(hits::numeric / GREATEST(hits + reads, 1) * 100, 2) AS hit_pct
FROM pg_stat_io
WHERE backend_type = 'client backend'
  AND io_object = 'relation';
```

### COPY FROM ... WHERE (PG 17 Enhancement)

```sql
-- Import only matching rows from CSV (skip unwanted data at load time)
COPY staging_orders FROM '/data/export.csv'
WITH (FORMAT csv, HEADER true)
WHERE status = 'completed' AND amount > 0;
```

### pg_stat_progress_copy — Monitor COPY Operations

```sql
-- Track long-running COPY progress in real time
SELECT pid, relid::regclass AS table_name,
       command, type,
       bytes_processed, bytes_total,
       tuples_processed, tuples_excluded
FROM pg_stat_progress_copy;
```

### Improved Parallel Query Execution (PG 16/17)

```sql
-- PG 16+: Full support for parallel FULL and RIGHT outer hash joins
-- PG 17: Parallel execution of subqueries in RETURN and SELECT list
-- Enable/tune parallelism:
SET max_parallel_workers_per_gather = 4;  -- workers per query
SET parallel_tuple_cost = 0.01;
SET parallel_setup_cost = 100;

-- Verify parallel plan
EXPLAIN (ANALYZE, BUFFERS)
SELECT department_id, COUNT(*), AVG(salary)
FROM employees
GROUP BY department_id;
-- Look for: "Workers Planned: 4" and "Workers Launched: 4"
```

### PG 17: Incremental Backup

```bash
# Full base backup (first time)
pg_basebackup -D /backups/full --checkpoint=fast

# Incremental backup (only changed blocks since last backup)
pg_basebackup -D /backups/incr1 --incremental=/backups/full/backup_manifest

# Combine full + incremental for restore
pg_combinebackup /backups/full /backups/incr1 -o /backups/restored
```

### PG 17: Improved VACUUM

```sql
-- PG 17: VACUUM can process indexes in parallel, improved dead-tuple handling
-- New visibility map improvements reduce unnecessary page visits
-- Urgent vacuuming kicks in more aggressively near wraparound

-- Monitor vacuum progress
SELECT relname, phase, heap_blks_total, heap_blks_scanned, heap_blks_vacuumed,
       index_vacuum_count, max_dead_tuple_bytes, num_dead_tuple_bytes
FROM pg_stat_progress_vacuum
JOIN pg_class ON pg_class.oid = relid;
```

### Modern pg_stat_statements (PG 16+ Improvements)

```sql
-- PG 16+: Track JIT statistics and I/O timing per query
-- Ensure extension is loaded:
-- shared_preload_libraries = 'pg_stat_statements'

-- Top queries by total execution time
SELECT queryid,
       calls,
       round(total_exec_time::numeric, 2) AS total_ms,
       round(mean_exec_time::numeric, 2) AS mean_ms,
       round(stddev_exec_time::numeric, 2) AS stddev_ms,
       rows,
       round((shared_blks_hit::numeric / GREATEST(shared_blks_hit + shared_blks_read, 1)) * 100, 2) AS cache_hit_pct,
       -- PG 16+: I/O timing columns
       round(shared_blk_read_time::numeric, 2) AS read_time_ms,
       round(shared_blk_write_time::numeric, 2) AS write_time_ms,
       -- PG 16+: JIT statistics
       jit_functions, jit_generation_time, jit_emission_time,
       query
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 20;

-- Reset stats periodically for fresh analysis
SELECT pg_stat_statements_reset();
```

### PG 17: Identity Columns — New Behavior

```sql
-- PG 17: ALTER TABLE can change identity column sequence options more flexibly
CREATE TABLE orders (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  description text
);

-- PG 17: Can restart identity sequence independently
ALTER TABLE orders ALTER COLUMN id RESTART WITH 1000;
```

---

## PostgreSQL 18 Features (GA — Released September 2025)

### Native uuidv7() and uuidv4() Functions

```sql
-- PG 18: Built-in uuidv7() — no extension needed!
CREATE TABLE events (
  id uuid NOT NULL DEFAULT uuidv7() PRIMARY KEY,
  event_type text NOT NULL,
  payload jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- PG 18: uuidv4() is an alias for gen_random_uuid()
SELECT uuidv4();  -- same as gen_random_uuid(), clearer intent
```

### Asynchronous I/O (AIO) with io_uring

```sql
-- PG 18: Asynchronous I/O support via io_uring on Linux
-- Dramatically improves throughput for I/O-bound workloads (sequential scans,
-- bulk reads, VACUUM, checkpointing) by issuing multiple I/O requests in parallel
-- instead of blocking on one-at-a-time synchronous reads.

-- Enable in postgresql.conf:
-- io_method = 'io_uring'       # Options: io_uring, worker (default)
-- io_combine_limit = 128kB     # Max combined I/O size
```

### OAuth Authentication (OAUTHBEARER)

```
# PG 18: OAuth 2.0 authentication via OAUTHBEARER SASL mechanism
# Allows clients to authenticate using OAuth tokens from identity providers
# instead of passwords — integrates with corporate SSO, Azure AD, Okta, etc.

# pg_hba.conf example:
# TYPE  DATABASE  USER  ADDRESS        METHOD
# host  all       all   0.0.0.0/0      oauth
```

### Improved pg_upgrade Preserving Logical Replication Slots

```bash
# PG 18: pg_upgrade now preserves logical replication slots and subscriptions
# Previously, logical replication had to be torn down and rebuilt after major upgrades
# This makes major version upgrades far less disruptive for replicated environments.

pg_upgrade --old-datadir /var/lib/pgsql/17/data \
           --new-datadir /var/lib/pgsql/18/data \
           --old-bindir /usr/pgsql-17/bin \
           --new-bindir /usr/pgsql-18/bin
# Logical replication slots are automatically carried over
```

---

## UUIDv7 Implementation

### PG 18+ (Native Support — Recommended)

```sql
-- PostgreSQL 18 has built-in uuidv7() — no extension needed
CREATE TABLE orders (
  id uuid NOT NULL DEFAULT uuidv7() PRIMARY KEY
);

-- Also provides uuidv4() as a clearer alias for gen_random_uuid()
SELECT uuidv4();
```

### Using pg_uuidv7 Extension (PG 13–17)

```sql
-- Install extension
CREATE EXTENSION IF NOT EXISTS pg_uuidv7;

-- Use as primary key — time-ordered, no index fragmentation
CREATE TABLE events (
  id uuid NOT NULL DEFAULT uuid_generate_v7() PRIMARY KEY,
  event_type text NOT NULL,
  payload jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Extract timestamp from UUIDv7 (no created_at column needed for ordering)
SELECT id, uuid_v7_to_timestamptz(id) AS event_time FROM events ORDER BY id DESC;

-- Create UUIDv7 from a specific timestamp (useful for range queries)
SELECT uuid_timestamptz_to_v7('2024-06-15T00:00:00Z'::timestamptz);
-- Use for cursor pagination: WHERE id > uuid_timestamptz_to_v7($cursor_ts)
```

### Pure SQL Fallback (No Extension Needed)

```sql
-- Generate UUIDv7 with a PL/pgSQL function (works on any PG 13+)
CREATE OR REPLACE FUNCTION generate_uuidv7() RETURNS uuid AS $$
DECLARE
  unix_ts_ms bigint;
  buffer bytea;
BEGIN
  unix_ts_ms := extract(epoch FROM clock_timestamp()) * 1000;
  buffer := set_byte(
    set_byte(
      overlay(uuid_send(gen_random_uuid()) PLACING substring(int8send(unix_ts_ms) FROM 3) FROM 1 FOR 6),
      6, (get_byte(uuid_send(gen_random_uuid()), 6) & 15) | 112  -- version 7
    ),
    8, (get_byte(uuid_send(gen_random_uuid()), 8) & 63) | 128  -- variant 2
  );
  RETURN encode(buffer, 'hex')::uuid;
END;
$$ LANGUAGE plpgsql VOLATILE;
```

**Why UUIDv7 over UUIDv4?** UUIDv7 embeds a millisecond timestamp, so values are naturally time-ordered. This means B-tree indexes stay compact (sequential inserts, no page splits), and you get temporal ordering for free without a separate `created_at` column.

---

## Table Partitioning

### Range Partitioning (Most Common — Time-Series Data)

```sql
CREATE TABLE events (
    id          bigint GENERATED ALWAYS AS IDENTITY,
    created_at  timestamptz NOT NULL,
    event_type  text NOT NULL,
    payload     jsonb
) PARTITION BY RANGE (created_at);

CREATE TABLE events_2025_q1 PARTITION OF events
    FOR VALUES FROM ('2025-01-01') TO ('2025-04-01');
CREATE TABLE events_2025_q2 PARTITION OF events
    FOR VALUES FROM ('2025-04-01') TO ('2025-07-01');

-- Auto-create future partitions with pg_partman
CREATE EXTENSION IF NOT EXISTS pg_partman;
SELECT partman.create_parent(
    p_parent_table := 'public.events',
    p_control := 'created_at',
    p_interval := '3 months',
    p_premake := 4
);
```

### List Partitioning (Enum-Like Categories)

```sql
CREATE TABLE orders (
    id          bigint GENERATED ALWAYS AS IDENTITY,
    status      text NOT NULL,
    total       numeric(10,2)
) PARTITION BY LIST (status);

CREATE TABLE orders_active PARTITION OF orders
    FOR VALUES IN ('pending', 'processing', 'shipped');
CREATE TABLE orders_archive PARTITION OF orders
    FOR VALUES IN ('delivered', 'cancelled', 'refunded');
```

### Hash Partitioning (Even Distribution)

```sql
CREATE TABLE sessions (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     bigint NOT NULL,
    data        jsonb
) PARTITION BY HASH (user_id);

CREATE TABLE sessions_0 PARTITION OF sessions FOR VALUES WITH (MODULUS 4, REMAINDER 0);
CREATE TABLE sessions_1 PARTITION OF sessions FOR VALUES WITH (MODULUS 4, REMAINDER 1);
CREATE TABLE sessions_2 PARTITION OF sessions FOR VALUES WITH (MODULUS 4, REMAINDER 2);
CREATE TABLE sessions_3 PARTITION OF sessions FOR VALUES WITH (MODULUS 4, REMAINDER 3);
```

### Partition Decision Tree

```
When to partition?
├── Table > 100M rows or > 50GB → Partition
├── Time-series data with retention → Range partition by time
├── Queries always filter by category → List partition
├── Even distribution needed (sharding prep) → Hash partition
├── Table < 10M rows → Don't partition (overhead not worth it)
└── Mixed access patterns → Consider partial indexes first
```

---

## EXPLAIN Reading Guide

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
-- Buffers       → shared hit (cache) vs read (disk) — high reads = cold cache or bad indexes

-- Red flags:
-- actual rows >> estimated rows  → Run ANALYZE, check stats
-- Seq Scan on large table        → Add index
-- Sort with high cost            → Add index matching ORDER BY
-- Nested Loop with large outer   → Consider Hash Join hint or restructure
```

---

## Full-Text Search

```sql
-- Basic full-text search with weighted columns
ALTER TABLE articles ADD COLUMN search_vector tsvector
    GENERATED ALWAYS AS (
        setweight(to_tsvector('english', coalesce(title, '')), 'A') ||
        setweight(to_tsvector('english', coalesce(body, '')), 'B')
    ) STORED;

CREATE INDEX idx_articles_search ON articles USING GIN (search_vector);

-- Search with ranking
SELECT id, title, ts_rank(search_vector, query) AS rank
FROM articles, to_tsquery('english', 'postgres & performance') AS query
WHERE search_vector @@ query
ORDER BY rank DESC
LIMIT 20;
```

---

## CTE Materialization Control (PG 12+)

```sql
-- Force materialization (prevent optimization across CTE boundary)
WITH active_users AS MATERIALIZED (
    SELECT * FROM users WHERE is_active = true
)
SELECT * FROM active_users WHERE ...;

-- Prevent materialization (allow optimizer to inline the CTE)
WITH filtered AS NOT MATERIALIZED (
    SELECT * FROM orders WHERE status = 'pending'
)
SELECT * FROM filtered WHERE total > 100;
-- NOT MATERIALIZED allows PG to push the WHERE total > 100 into the CTE scan
```

---

## pgvector — Vector/Embedding Search

### Setup and Basic Usage

```sql
-- Install the extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Create table with vector column (1536 = OpenAI text-embedding-3-small dimensions)
CREATE TABLE documents (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  content text NOT NULL,
  embedding vector(1536) NOT NULL,
  metadata jsonb DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Insert with embedding
INSERT INTO documents (content, embedding)
VALUES ('PostgreSQL is great', '[0.1, 0.2, ...]'::vector);

-- Similarity search (cosine distance — most common for text embeddings)
SELECT id, content, 1 - (embedding <=> $1::vector) AS similarity
FROM documents
ORDER BY embedding <=> $1::vector
LIMIT 10;

-- L2 (Euclidean) distance
SELECT * FROM documents ORDER BY embedding <-> $1::vector LIMIT 10;

-- Inner product (maximize, not minimize)
SELECT * FROM documents ORDER BY embedding <#> $1::vector LIMIT 10;
```

### Indexing for Performance

```sql
-- HNSW index (preferred — faster queries, builds in memory)
CREATE INDEX idx_documents_embedding ON documents
  USING hnsw (embedding vector_cosine_ops)
  WITH (m = 16, ef_construction = 64);

-- Build concurrently for production
SET maintenance_work_mem = '4GB';
SET max_parallel_maintenance_workers = 4;
CREATE INDEX CONCURRENTLY idx_documents_embedding ON documents
  USING hnsw (embedding vector_cosine_ops)
  WITH (m = 24, ef_construction = 128);

-- Tune search accuracy vs speed
SET hnsw.ef_search = 100;  -- higher = more accurate, slower (default: 40)

-- IVFFlat index (alternative — faster build, slower queries)
CREATE INDEX ON documents USING ivfflat (embedding vector_cosine_ops)
  WITH (lists = 100);  -- rule of thumb: sqrt(row_count)
SET ivfflat.probes = 10;  -- higher = more accurate (default: 1)
```

### Filtered Vector Search

```sql
-- Combine vector search with metadata filters
SELECT id, content, 1 - (embedding <=> $1::vector) AS similarity
FROM documents
WHERE metadata @> '{"category": "technical"}'
  AND created_at > now() - interval '30 days'
ORDER BY embedding <=> $1::vector
LIMIT 10;

-- Partial index for filtered vector search
CREATE INDEX idx_docs_tech_embedding ON documents
  USING hnsw (embedding vector_cosine_ops)
  WHERE metadata @> '{"category": "technical"}';
```

### RAG (Retrieval-Augmented Generation) Pattern

```sql
-- Hybrid search: combine full-text + vector similarity
WITH semantic AS (
  SELECT id, content, 1 - (embedding <=> $1::vector) AS vector_score
  FROM documents
  ORDER BY embedding <=> $1::vector
  LIMIT 50
),
fulltext AS (
  SELECT id, content, ts_rank(to_tsvector('english', content), plainto_tsquery($2)) AS text_score
  FROM documents
  WHERE to_tsvector('english', content) @@ plainto_tsquery($2)
  LIMIT 50
)
SELECT COALESCE(s.id, f.id) AS id,
       COALESCE(s.content, f.content) AS content,
       COALESCE(s.vector_score, 0) * 0.7 + COALESCE(f.text_score, 0) * 0.3 AS combined_score
FROM semantic s FULL OUTER JOIN fulltext f ON s.id = f.id
ORDER BY combined_score DESC
LIMIT 10;
```

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

## Data Types — Use the Right One

| Use Case | Type | NOT This |
|---|---|---|
| Primary key | `bigint GENERATED ALWAYS AS IDENTITY` or `uuid` | `serial` (legacy), `int` (will overflow) |
| Strings (any length) | `text` | `varchar(255)` (arbitrary limit) |
| Strings (enforced max) | `text` + `CHECK(length(x) <= n)` | `varchar(n)` (same effect, less clear) |
| Money | `numeric(19,4)` | `float`, `real`, `money` (rounding errors) |
| Timestamps | `timestamptz` (ALWAYS with timezone) | `timestamp` (ambiguous, loses timezone) |
| Booleans | `boolean` | `int` (0/1), `char(1)` |
| Enums (few fixed values) | `text` + `CHECK` constraint | PostgreSQL `ENUM` type (hard to modify) |
| JSON (queried) | `jsonb` | `json` (no indexing, no operators) |
| JSON (stored only) | `jsonb` | `text` (no validation) |
| IP addresses | `inet` | `text` |
| Date ranges | `daterange`, `tstzrange` | Two separate columns |
| Arrays (simple) | `text[]`, `int[]` | Separate junction table (for truly simple cases) |
| Tags/labels | `text[]` + GIN index | Junction table (overkill for simple tags) |

---

## Index Strategy

### Decision Tree: Which Index Type?

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

### Index Rules

1. **Composite index column order matters**: equality columns first, then range, then sort
   ```sql
   -- Query: WHERE status = 'active' AND created_at > '2024-01-01' ORDER BY priority
   CREATE INDEX idx_tasks_status_created_priority
     ON tasks (status, created_at, priority);
   ```

2. **Covering indexes** avoid heap lookups:
   ```sql
   CREATE INDEX idx_users_email ON users (email) INCLUDE (name, avatar_url);
   -- Query: SELECT name, avatar_url FROM users WHERE email = ?
   -- Index-only scan — never touches the table
   ```

3. **Partial indexes** for common filters:
   ```sql
   CREATE INDEX idx_orders_pending ON orders (created_at)
     WHERE status = 'pending';
   -- Tiny index, only rows that matter
   ```

4. **Never index blindly** — check with:
   ```sql
   EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) SELECT ...;
   ```

### Finding Missing Indexes

```sql
-- Unused indexes (candidates for removal)
SELECT schemaname, relname, indexrelname, idx_scan, idx_tup_read
FROM pg_stat_user_indexes
WHERE idx_scan = 0
  AND indexrelname NOT LIKE '%_pkey'
ORDER BY pg_relation_size(indexrelid) DESC;

-- Tables with most sequential scans (need indexes)
SELECT relname, seq_scan, seq_tup_read, idx_scan,
       seq_tup_read / GREATEST(seq_scan, 1) AS avg_rows_per_scan
FROM pg_stat_user_tables
WHERE seq_scan > 100
ORDER BY seq_tup_read DESC
LIMIT 20;

-- Unindexed foreign keys (common performance killer)
SELECT conrelid::regclass AS table_name,
       conname AS constraint_name,
       a.attname AS column_name
FROM pg_constraint c
JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = ANY(c.conkey)
WHERE c.contype = 'f'
  AND NOT EXISTS (
    SELECT 1 FROM pg_index i
    WHERE i.indrelid = c.conrelid
      AND a.attnum = ANY(i.indkey)
  );
```

---

## Query Patterns

### Pagination — Cursor-Based (Always Prefer)

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
**Why**: O(1) regardless of page depth. Offset pagination is O(n) — page 1000 reads 20,000 rows.

### Upsert (INSERT ... ON CONFLICT)

```sql
INSERT INTO user_preferences (user_id, key, value, updated_at)
VALUES ($1, $2, $3, now())
ON CONFLICT (user_id, key) DO UPDATE SET
  value = EXCLUDED.value,
  updated_at = EXCLUDED.updated_at
WHERE user_preferences.value IS DISTINCT FROM EXCLUDED.value;
-- Skip update if value unchanged (avoid unnecessary WAL writes)
```

### Queue Pattern (FOR UPDATE SKIP LOCKED)

```sql
-- Worker claims a job atomically
WITH next_job AS (
  SELECT id FROM jobs
  WHERE status = 'pending'
    AND run_at <= now()
  ORDER BY priority DESC, run_at ASC
  LIMIT 1
  FOR UPDATE SKIP LOCKED
)
UPDATE jobs SET status = 'processing', started_at = now(), worker_id = $1
FROM next_job WHERE jobs.id = next_job.id
RETURNING jobs.*;
```

### Bulk Operations (Efficient)

```sql
-- Bulk insert with unnest (much faster than multiple INSERTs)
INSERT INTO events (user_id, event_type, payload, created_at)
SELECT * FROM unnest(
  $1::bigint[],       -- user_ids
  $2::text[],         -- event_types
  $3::jsonb[],        -- payloads
  $4::timestamptz[]   -- timestamps
);

-- Bulk update with VALUES
UPDATE products SET price = v.price, updated_at = now()
FROM (VALUES (1, 29.99), (2, 49.99), (3, 9.99)) AS v(id, price)
WHERE products.id = v.id;
```

### CTEs and Window Functions

```sql
-- Running total with window function
SELECT date, revenue,
       SUM(revenue) OVER (ORDER BY date) AS running_total,
       AVG(revenue) OVER (ORDER BY date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS rolling_7d_avg
FROM daily_revenue;

-- Rank within groups
SELECT department, name, salary,
       RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS dept_rank
FROM employees;

-- Recursive CTE (tree traversal)
WITH RECURSIVE tree AS (
  SELECT id, parent_id, name, 1 AS depth
  FROM categories WHERE parent_id IS NULL
  UNION ALL
  SELECT c.id, c.parent_id, c.name, t.depth + 1
  FROM categories c JOIN tree t ON c.parent_id = t.id
  WHERE t.depth < 10  -- safety limit
)
SELECT * FROM tree ORDER BY depth, name;
```

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

## Migration Safety

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

### Migration Template

```sql
-- migrate up
BEGIN;

-- Add column (safe — metadata only in PG 11+)
ALTER TABLE orders ADD COLUMN tracking_number text;

-- Add index CONCURRENTLY (must be outside transaction)
COMMIT;
CREATE INDEX CONCURRENTLY idx_orders_tracking ON orders (tracking_number);

-- migrate down
DROP INDEX CONCURRENTLY IF EXISTS idx_orders_tracking;
ALTER TABLE orders DROP COLUMN IF EXISTS tracking_number;
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

**Drizzle vs Prisma — when to pick which:**
| Aspect | Drizzle | Prisma |
|---|---|---|
| Schema definition | TypeScript code (co-located) | Separate `.prisma` file |
| Query style | SQL-like builder + relational API | Custom API (less SQL knowledge) |
| Bundle size | ~50KB | ~2MB+ (engine binary) |
| Raw SQL | First-class `sql` template | `$queryRaw` escape hatch |
| Serverless | Excellent (no binary engine) | Requires engine, cold starts |
| Migrations | SQL-based (`drizzle-kit`) | Prisma Migrate (auto-generated) |

---

## Connection Pooling

```
Application (100 workers, each opens 1 connection)
  → PgBouncer (pool_size=25, pool_mode=transaction)
    → PostgreSQL (max_connections=100)
```

### PgBouncer Config Essentials

```ini
[pgbouncer]
pool_mode = transaction          # MUST for serverless/many-connection apps
max_client_conn = 1000           # clients waiting
default_pool_size = 25           # actual PG connections per database
min_pool_size = 5                # keep warm connections
reserve_pool_size = 5            # overflow for bursts
reserve_pool_timeout = 3         # seconds before using reserve
server_idle_timeout = 600        # close idle server connections
client_idle_timeout = 0          # 0 = never timeout idle clients
```

**Key rule**: In transaction pooling mode, you CANNOT use:
- `SET` / `SET LOCAL` (use function parameters instead)
- `LISTEN/NOTIFY` (use session mode for this)
- `PREPARE` (use `server_reset_query = DISCARD ALL`)
- Temp tables (auto-cleaned on return to pool)

### Supavisor — Cloud-Native Alternative to PgBouncer

Supavisor is an Elixir-based, multi-tenant connection pooler built by Supabase. Designed for serverless and high-connection-count environments.

| Aspect | PgBouncer | Supavisor |
|---|---|---|
| Architecture | Single-process, C | Multi-node, Elixir/BEAM |
| Max connections | ~10K clients | ~1M+ clients (tested) |
| Multi-tenancy | One instance per DB | Single cluster, many DBs |
| Protocol | TCP only | TCP + HTTP (WebSocket) |
| Scaling | Vertical only | Horizontal (add nodes) |
| Best for | Single DB, low latency | SaaS, serverless, massive fan-out |
| Latency | Lowest (single-process) | Higher (~80–160% vs PgBouncer) |

**When to choose Supavisor:**
- Serverless platforms (Vercel, Cloudflare Workers) with many short-lived connections
- Multi-tenant SaaS routing many databases through one pooler
- Need horizontal scaling beyond what a single PgBouncer can handle

**When to stay with PgBouncer:**
- Single database, latency-sensitive workloads
- Already deployed and working (don't fix what isn't broken)
- Lowest possible overhead matters more than scale

---

## Performance Diagnostics

```sql
-- Slow query log (postgresql.conf)
log_min_duration_statement = 100  -- log queries > 100ms

-- Current running queries
SELECT pid, now() - query_start AS duration, state, query
FROM pg_stat_activity
WHERE state = 'active' AND query_start < now() - interval '5 seconds'
ORDER BY duration DESC;

-- Table bloat estimate
SELECT relname, n_dead_tup, n_live_tup,
       round(n_dead_tup::numeric / GREATEST(n_live_tup, 1) * 100, 2) AS dead_pct,
       last_vacuum, last_autovacuum
FROM pg_stat_user_tables
WHERE n_dead_tup > 1000
ORDER BY n_dead_tup DESC;

-- Cache hit ratio (should be >99%)
SELECT
  sum(heap_blks_hit) / GREATEST(sum(heap_blks_hit) + sum(heap_blks_read), 1) AS cache_hit_ratio
FROM pg_statio_user_tables;

-- Index hit ratio
SELECT
  sum(idx_blks_hit) / GREATEST(sum(idx_blks_hit) + sum(idx_blks_read), 1) AS idx_cache_hit_ratio
FROM pg_statio_user_indexes;
```

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

## PostgreSQL Configuration Essentials

```ini
# Connection
max_connections = 100                # Keep low. Use PgBouncer for more
shared_buffers = '1GB'               # 25% of RAM
effective_cache_size = '3GB'         # 75% of RAM
work_mem = '16MB'                    # Per operation — careful with high connections

# Write Performance
wal_buffers = '64MB'
checkpoint_completion_target = 0.9
max_wal_size = '2GB'

# Query Planner
random_page_cost = 1.1              # SSD (default 4.0 is for spinning disks)
effective_io_concurrency = 200      # SSD

# Autovacuum (tune for busy tables)
autovacuum_max_workers = 4
autovacuum_naptime = '30s'
autovacuum_vacuum_cost_delay = '2ms'

# Logging
log_min_duration_statement = 100    # Log queries > 100ms
log_checkpoints = on
log_lock_waits = on
log_temp_files = 0                  # Log all temp file usage

# Extensions (load at startup)
shared_preload_libraries = 'pg_stat_statements'

# PG 16+: Enable I/O timing for pg_stat_io and pg_stat_statements
# (pg_stat_io is a built-in view — no shared_preload_libraries entry needed)
track_io_timing = on

# PG 17: Improved WAL summarizer for incremental backup
summarize_wal = on

# PG 18: Asynchronous I/O (Linux only)
# io_method = 'io_uring'
```

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
