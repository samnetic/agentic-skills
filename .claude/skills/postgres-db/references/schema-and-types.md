# Schema Design and Data Types

## Table of Contents

- [Data Types — Use the Right One](#data-types--use-the-right-one)
- [UUIDv7 Implementation](#uuidv7-implementation)
  - [PG 18+ Native Support](#pg-18-native-support--recommended)
  - [pg_uuidv7 Extension (PG 13–17)](#using-pg_uuidv7-extension-pg-1317)
  - [Pure SQL Fallback](#pure-sql-fallback-no-extension-needed)
- [PostgreSQL 16/17 Modern Features](#postgresql-1617-modern-features)
  - [MERGE Statement](#merge-statement-sql-standard--pg-15-enhanced-pg-17)
  - [JSON_TABLE and SQL/JSON Functions](#json_table-and-sqljson-functions-pg-17)
  - [pg_stat_io](#pg_stat_io--io-analysis-pg-16)
  - [COPY FROM WHERE](#copy-from--where-pg-17-enhancement)
  - [Parallel Query](#improved-parallel-query-execution-pg-1617)
  - [Identity Columns](#pg-17-identity-columns--new-behavior)
- [PostgreSQL 18 Features](#postgresql-18-features-ga--released-september-2025)
  - [Native uuidv7() and uuidv4()](#native-uuidv7-and-uuidv4-functions)
  - [Asynchronous I/O](#asynchronous-io-aio-with-io_uring)
  - [OAuth Authentication](#oauth-authentication-oauthbearer)

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
