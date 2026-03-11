# Query Optimization and Indexing

## Table of Contents

- [EXPLAIN Reading Guide](#explain-reading-guide)
- [Index Strategy](#index-strategy)
  - [Decision Tree: Which Index Type?](#decision-tree-which-index-type)
  - [Index Rules](#index-rules)
  - [Finding Missing Indexes](#finding-missing-indexes)
- [Query Patterns](#query-patterns)
  - [Cursor-Based Pagination](#pagination--cursor-based-always-prefer)
  - [Upsert](#upsert-insert--on-conflict)
  - [Queue Pattern](#queue-pattern-for-update-skip-locked)
  - [Bulk Operations](#bulk-operations-efficient)
  - [CTEs and Window Functions](#ctes-and-window-functions)
- [CTE Materialization Control](#cte-materialization-control-pg-12)
- [Full-Text Search](#full-text-search)
- [pgvector — Vector/Embedding Search](#pgvector--vectorembedding-search)
  - [Setup and Basic Usage](#setup-and-basic-usage)
  - [Indexing for Performance](#indexing-for-performance)
  - [Filtered Vector Search](#filtered-vector-search)
  - [RAG Pattern](#rag-retrieval-augmented-generation-pattern)
- [Table Partitioning](#table-partitioning)
  - [Range Partitioning](#range-partitioning-most-common--time-series-data)
  - [List Partitioning](#list-partitioning-enum-like-categories)
  - [Hash Partitioning](#hash-partitioning-even-distribution)
  - [Partition Decision Tree](#partition-decision-tree)

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
