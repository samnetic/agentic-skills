# Operations: Migrations, Pooling, Diagnostics, and Configuration

## Table of Contents

- [Migration Safety](#migration-safety)
  - [Zero-Downtime Migration Rules](#zero-downtime-migration-rules)
  - [Migration Template](#migration-template)
- [Connection Pooling](#connection-pooling)
  - [PgBouncer Config Essentials](#pgbouncer-config-essentials)
  - [Supavisor — Cloud-Native Alternative](#supavisor--cloud-native-alternative-to-pgbouncer)
- [Performance Diagnostics](#performance-diagnostics)
- [PostgreSQL Configuration Essentials](#postgresql-configuration-essentials)

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
