---
name: data-modeling
description: >-
  Database design and data modeling expertise. Use when designing entity-relationship
  models, normalizing schemas, deciding between normalization vs denormalization, designing
  temporal data models, implementing soft deletes, creating audit trails, designing
  polymorphic associations, modeling hierarchical data (trees, graphs), designing
  multi-tenant data architectures, creating ERDs, defining domain entities and relationships,
  planning data migration strategies, event sourcing patterns, document model patterns with
  JSONB, vector embedding storage for AI/ML, Change Data Capture (CDC), temporal/system-versioned
  tables, data vault modeling for data warehouses, graph data patterns in relational DBs,
  or reviewing existing data models for issues.
  Triggers: data model, ERD, entity relationship, normalization, denormalization, schema
  design, database design, temporal, soft delete, audit trail, polymorphic, hierarchy,
  tree structure, multi-tenant, domain model, migration strategy, event sourcing, CQRS,
  JSONB document, vector embedding, CDC, change data capture, temporal table, data vault,
  graph data, adjacency list, Citus, distributed PostgreSQL.
---

# Data Modeling Skill

Design data models that accurately represent the domain, enforce integrity at the database
level, and perform well at scale. The database is the last line of defense for data quality.

---

## Core Principles

| Principle | Meaning |
|---|---|
| **Model the domain, not the UI** | Data structures outlive any frontend. Design for the business domain |
| **Constraints in the database** | NOT NULL, CHECK, UNIQUE, FK — enforce at the source of truth |
| **Normalize first, denormalize deliberately** | Start 3NF. Denormalize only with measured query evidence |
| **Immutability where possible** | Append events rather than mutating state when audit matters |
| **Design for queries you'll run** | Know your access patterns before finalizing the model |
| **Every table needs a purpose** | If you can't explain what a table represents in one sentence, redesign |

---

## Workflow: Data Modeling

```
1. DOMAIN ANALYSIS  → Identify entities, relationships, business rules
2. CONCEPTUAL MODEL → ERD with entities and relationships (no columns yet)
3. LOGICAL MODEL    → Add attributes, keys, constraints, normalization
4. PHYSICAL MODEL   → Data types, indexes, partitioning, denormalization
5. VALIDATE         → Review against query patterns, write sample queries
```

---

## Entity Design Patterns

### Standard Table Template

```sql
CREATE TABLE orders (
  -- Identity
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

  -- Relationships
  user_id bigint NOT NULL REFERENCES users(id),
  product_id bigint NOT NULL REFERENCES products(id),

  -- Domain attributes
  quantity int NOT NULL CHECK (quantity > 0),
  unit_price numeric(19,4) NOT NULL CHECK (unit_price >= 0),
  total_price numeric(19,4) GENERATED ALWAYS AS (quantity * unit_price) STORED,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','confirmed','shipped','delivered','cancelled')),
  notes text CHECK (length(notes) <= 5000),

  -- Metadata
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Indexes for known query patterns
CREATE INDEX idx_orders_user_id ON orders (user_id);
CREATE INDEX idx_orders_status_created ON orders (status, created_at DESC);
```

**Rules for every table:**
1. `bigint GENERATED ALWAYS AS IDENTITY` for PKs (or UUIDv7 for distributed systems)
2. `NOT NULL` on everything unless NULL has a specific business meaning
3. `CHECK` constraints for domain validation (status values, positive amounts)
4. `created_at` and `updated_at` on every mutable table
5. Foreign keys for every relationship
6. Indexes on every foreign key and common query patterns

---

## Normalization Quick Reference

| Form | Rule | Violation Example | Fix |
|---|---|---|---|
| **1NF** | Atomic values, no repeating groups | `tags: "red,blue,green"` | Separate table or `text[]` |
| **2NF** | No partial dependencies on composite key | `(order_id, product_id) → product_name` | Move product_name to products table |
| **3NF** | No transitive dependencies | `user → zip_code → city` | Move city to a zip_codes table |
| **BCNF** | Every determinant is a candidate key | Rare in practice | Decompose if found |

### When to Denormalize

| Scenario | Denormalization Strategy | Trade-off |
|---|---|---|
| Expensive JOIN on every read | Materialized view | Stale data (refresh interval) |
| Count/sum needed constantly | Counter cache column + trigger | Write overhead |
| Full-text search | Separate search index (tsvector column) | Index maintenance |
| Reporting queries | Read replica with denormalized views | Replication lag |
| N+1 API responses | Embedded JSONB for nested data | Update complexity |
| Historical snapshots | Copy data at point-in-time | Storage cost |

**Rule**: Denormalize for reads, normalize for writes. Always maintain the normalized source of truth.

---

## Relationship Patterns

### One-to-Many

```sql
-- Parent
CREATE TABLE authors (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, name text NOT NULL);
-- Child
CREATE TABLE books (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  author_id bigint NOT NULL REFERENCES authors(id) ON DELETE CASCADE,
  title text NOT NULL
);
CREATE INDEX idx_books_author_id ON books (author_id);
```

### Many-to-Many

```sql
CREATE TABLE book_tags (
  book_id bigint NOT NULL REFERENCES books(id) ON DELETE CASCADE,
  tag_id bigint NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
  PRIMARY KEY (book_id, tag_id),
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_book_tags_tag_id ON book_tags (tag_id);
```

### Self-Referential (Hierarchy)

```sql
-- Adjacency List (simple, good for shallow trees)
CREATE TABLE categories (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  parent_id bigint REFERENCES categories(id),
  name text NOT NULL,
  depth int NOT NULL DEFAULT 0
);
CREATE INDEX idx_categories_parent ON categories (parent_id);

-- Materialized Path (fast reads, denormalized)
CREATE TABLE categories (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  path text NOT NULL, -- '/1/5/23/' — all ancestors in path
  name text NOT NULL
);
CREATE INDEX idx_categories_path ON categories USING gist (path gist_trgm_ops);
-- Find subtree: WHERE path LIKE '/1/5/%'

-- Closure Table (best for complex queries, normalized)
CREATE TABLE category_tree (
  ancestor_id bigint NOT NULL REFERENCES categories(id),
  descendant_id bigint NOT NULL REFERENCES categories(id),
  depth int NOT NULL,
  PRIMARY KEY (ancestor_id, descendant_id)
);
```

### Decision Tree: Hierarchy Pattern

```
How deep is the tree?
├── ≤ 5 levels, simple parent-child queries → Adjacency List + recursive CTE
├── Deep tree, mostly read subtrees → Materialized Path
├── Complex queries (all ancestors, all descendants, move subtree) → Closure Table
└── Ordered siblings (drag & drop) → Adjacency List + position column
```

### Polymorphic Associations

```sql
-- ANTI-PATTERN: polymorphic FK (no referential integrity)
-- comments.commentable_type = 'Post' | 'Video'
-- comments.commentable_id = 123
-- ❌ Cannot create FK constraint!

-- CORRECT: Separate FK per type (exclusive arc)
CREATE TABLE comments (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  post_id bigint REFERENCES posts(id),
  video_id bigint REFERENCES videos(id),
  body text NOT NULL,
  CONSTRAINT one_parent CHECK (
    num_nonnulls(post_id, video_id) = 1
  )
);

-- CORRECT: Shared parent table (class table inheritance)
CREATE TABLE commentables (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  type text NOT NULL CHECK (type IN ('post', 'video'))
);
CREATE TABLE posts (
  id bigint PRIMARY KEY REFERENCES commentables(id),
  title text NOT NULL
);
CREATE TABLE comments (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  commentable_id bigint NOT NULL REFERENCES commentables(id),
  body text NOT NULL
);
```

---

## Temporal Data Patterns

### Soft Deletes

```sql
ALTER TABLE users ADD COLUMN deleted_at timestamptz;
CREATE INDEX idx_users_active ON users (id) WHERE deleted_at IS NULL;

-- Application queries ALWAYS filter:
SELECT * FROM users WHERE deleted_at IS NULL AND ...;

-- Or use a view:
CREATE VIEW active_users AS SELECT * FROM users WHERE deleted_at IS NULL;
```

**Soft delete trade-offs:**
- Pro: Recovery possible, audit trail, FK references don't break
- Con: Every query needs filter, unique constraints need partial indexes, data accumulates
- Alternative: Move to archive table on delete (event sourcing)

### Audit Trail

```sql
CREATE TABLE audit_log (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  table_name text NOT NULL,
  record_id bigint NOT NULL,
  action text NOT NULL CHECK (action IN ('INSERT','UPDATE','DELETE')),
  old_data jsonb,
  new_data jsonb,
  changed_fields text[],
  user_id bigint,
  ip_address inet,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_audit_table_record ON audit_log (table_name, record_id);
CREATE INDEX idx_audit_created ON audit_log USING brin (created_at);

-- Generic trigger function
CREATE OR REPLACE FUNCTION audit_trigger() RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO audit_log (table_name, record_id, action, old_data, new_data, changed_fields, user_id)
  VALUES (
    TG_TABLE_NAME,
    COALESCE(NEW.id, OLD.id),
    TG_OP,
    CASE WHEN TG_OP IN ('UPDATE','DELETE') THEN to_jsonb(OLD) END,
    CASE WHEN TG_OP IN ('INSERT','UPDATE') THEN to_jsonb(NEW) END,
    CASE WHEN TG_OP = 'UPDATE' THEN
      ARRAY(SELECT key FROM jsonb_each(to_jsonb(OLD))
            WHERE to_jsonb(OLD) -> key IS DISTINCT FROM to_jsonb(NEW) -> key)
    END,
    NULLIF(current_setting('app.current_user_id', true), '')::bigint
  );
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Apply to any table
CREATE TRIGGER audit_users AFTER INSERT OR UPDATE OR DELETE ON users
  FOR EACH ROW EXECUTE FUNCTION audit_trigger();
```

### Temporal Validity (Bi-Temporal)

```sql
-- Track both when something IS valid and when we KNEW about it
CREATE TABLE prices (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  product_id bigint NOT NULL REFERENCES products(id),
  amount numeric(19,4) NOT NULL,
  valid_from timestamptz NOT NULL,
  valid_to timestamptz NOT NULL DEFAULT 'infinity',
  recorded_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT valid_range CHECK (valid_from < valid_to),
  EXCLUDE USING gist (
    product_id WITH =,
    tstzrange(valid_from, valid_to) WITH &&
  )
);
```

---

## Multi-Tenancy Patterns

| Pattern | Isolation | Complexity | Use When |
|---|---|---|---|
| **Shared table + tenant_id** | Low | Low | SaaS startup, <100 tenants |
| **Schema per tenant** | Medium | Medium | Regulatory needs, moderate tenants |
| **Database per tenant** | High | High | Enterprise, strict compliance |
| **Citus row-based sharding** | Medium | Medium | Scale-out, millions of tenants |
| **Citus schema-based sharding** | High | Low | Moderate tenants (~thousands), easy migration |

### Shared Table Pattern (Most Common)

```sql
-- Every table gets tenant_id
CREATE TABLE projects (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  tenant_id bigint NOT NULL REFERENCES tenants(id),
  name text NOT NULL,
  UNIQUE (tenant_id, name) -- unique within tenant
);

-- RLS enforces isolation
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON projects
  USING (tenant_id = current_setting('app.tenant_id')::bigint);

-- Every index includes tenant_id
CREATE INDEX idx_projects_tenant ON projects (tenant_id, created_at DESC);
```

### Citus Distributed Multi-Tenancy (Scale-Out)

```sql
-- Row-based sharding: distribute all tables by tenant_id
-- Citus co-locates rows with the same tenant_id on the same shard
SELECT create_distributed_table('projects', 'tenant_id');
SELECT create_distributed_table('tasks', 'tenant_id');
SELECT create_distributed_table('comments', 'tenant_id');

-- Reference tables: small shared data replicated to all nodes
SELECT create_reference_table('plan_types');
SELECT create_reference_table('countries');

-- Queries that filter by tenant_id are routed to a single shard (fast)
SELECT * FROM projects WHERE tenant_id = 42;

-- Cross-tenant queries are parallelized across all nodes
SELECT tenant_id, COUNT(*) FROM projects GROUP BY tenant_id;

-- Co-located JOINs (same tenant_id) stay on one node — no network shuffling
SELECT p.name, COUNT(t.id) AS task_count
FROM projects p JOIN tasks t ON p.id = t.project_id AND p.tenant_id = t.tenant_id
WHERE p.tenant_id = 42
GROUP BY p.name;
```

**Citus schema-based sharding** (Citus 12+): Each tenant gets its own PostgreSQL schema, automatically distributed across nodes. Simpler migration from single-tenant schemas, but recommended only up to ~thousands of tenants. Use row-based sharding for millions of tenants.

---

## Event Sourcing Patterns

### Event Store Schema

```sql
-- Core event store: append-only, immutable
CREATE TABLE events (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  stream_id text NOT NULL,                          -- e.g., 'order-123'
  stream_type text NOT NULL,                        -- e.g., 'Order'
  event_type text NOT NULL,                         -- e.g., 'OrderPlaced'
  data jsonb NOT NULL,                              -- event payload
  metadata jsonb NOT NULL DEFAULT '{}',             -- correlation_id, user_id, etc.
  version int NOT NULL,                             -- per-stream version for optimistic concurrency
  created_at timestamptz NOT NULL DEFAULT now(),

  -- Optimistic concurrency: no two events with same stream + version
  UNIQUE (stream_id, version)
);

-- Fast stream lookups (replay a single aggregate)
CREATE INDEX idx_events_stream ON events (stream_id, version);
-- Time-based queries (projections, catch-up subscriptions)
CREATE INDEX idx_events_created ON events USING brin (created_at);
-- Event type filtering (rebuild specific projections)
CREATE INDEX idx_events_type ON events (event_type, created_at);
```

### Appending Events with Optimistic Concurrency

```sql
-- Append event only if expected version matches (prevents conflicts)
INSERT INTO events (stream_id, stream_type, event_type, data, metadata, version)
VALUES (
  'order-123', 'Order', 'ItemAdded',
  '{"product_id": 42, "quantity": 2, "price": 29.99}'::jsonb,
  '{"user_id": 7, "correlation_id": "req-abc"}'::jsonb,
  -- Expected version: current max + 1
  (SELECT COALESCE(MAX(version), 0) + 1 FROM events WHERE stream_id = 'order-123')
);
-- If another transaction already wrote version N, the UNIQUE constraint fails → retry
```

### Projections (Read Models)

```sql
-- Materialized projection: rebuild from events
CREATE TABLE order_summaries (
  order_id text PRIMARY KEY,
  customer_id bigint NOT NULL,
  status text NOT NULL,
  item_count int NOT NULL DEFAULT 0,
  total_amount numeric(19,4) NOT NULL DEFAULT 0,
  last_event_id bigint NOT NULL,  -- checkpoint for incremental rebuild
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Incremental projection update (process new events since last checkpoint)
WITH new_events AS (
  SELECT * FROM events
  WHERE stream_type = 'Order' AND id > (SELECT COALESCE(MAX(last_event_id), 0) FROM order_summaries)
  ORDER BY id
)
INSERT INTO order_summaries (order_id, customer_id, status, item_count, total_amount, last_event_id)
SELECT
  stream_id,
  (data->>'customer_id')::bigint,
  CASE event_type
    WHEN 'OrderPlaced' THEN 'placed'
    WHEN 'OrderShipped' THEN 'shipped'
    WHEN 'OrderCancelled' THEN 'cancelled'
  END,
  0, 0, id
FROM new_events
WHERE event_type = 'OrderPlaced'
ON CONFLICT (order_id) DO UPDATE SET
  status = EXCLUDED.status,
  last_event_id = EXCLUDED.last_event_id,
  updated_at = now();
```

### Transactional Outbox Pattern

```sql
-- Outbox table: events to be published to message broker
CREATE TABLE outbox (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  aggregate_type text NOT NULL,
  aggregate_id text NOT NULL,
  event_type text NOT NULL,
  payload jsonb NOT NULL,
  published_at timestamptz,  -- NULL = not yet published
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_outbox_unpublished ON outbox (created_at) WHERE published_at IS NULL;

-- In the same transaction as domain write:
BEGIN;
  UPDATE orders SET status = 'shipped' WHERE id = 123;
  INSERT INTO outbox (aggregate_type, aggregate_id, event_type, payload)
  VALUES ('Order', '123', 'OrderShipped', '{"shipped_at": "2024-06-15"}'::jsonb);
COMMIT;

-- Separate publisher process claims and publishes:
WITH claimed AS (
  SELECT id, payload FROM outbox
  WHERE published_at IS NULL
  ORDER BY created_at
  LIMIT 100
  FOR UPDATE SKIP LOCKED
)
UPDATE outbox SET published_at = now()
FROM claimed WHERE outbox.id = claimed.id
RETURNING outbox.*;
```

---

## Document Model Patterns (JSONB)

### When to Use JSONB vs Relational Columns

| Use JSONB | Use Relational Columns |
|---|---|
| Schema varies per record (user preferences, form data) | Schema is well-known and stable |
| Nested/hierarchical data from APIs | Data participates in JOINs and FKs |
| Rapidly evolving schema (early-stage product) | Needs strong type enforcement |
| Sparse attributes (most records use few of many possible fields) | Queried/filtered frequently |
| Event payloads, audit metadata | Needs UNIQUE, CHECK, FK constraints |

### JSONB Schema Validation with CHECK Constraints

```sql
CREATE TABLE products (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name text NOT NULL,
  -- Flexible attributes stored as JSONB with validation
  attributes jsonb NOT NULL DEFAULT '{}',

  -- Validate required JSONB structure at the database level
  CONSTRAINT valid_attributes CHECK (
    jsonb_typeof(attributes) = 'object'
    AND (attributes ? 'category')                              -- required key
    AND jsonb_typeof(attributes->'category') = 'string'        -- type check
    AND (NOT attributes ? 'weight'                             -- optional, but if present...
         OR jsonb_typeof(attributes->'weight') = 'number')     -- must be numeric
    AND (NOT attributes ? 'tags'
         OR jsonb_typeof(attributes->'tags') = 'array')
  )
);

-- GIN index for containment queries
CREATE INDEX idx_products_attributes ON products USING gin (attributes jsonb_path_ops);

-- Querying JSONB efficiently
SELECT * FROM products WHERE attributes @> '{"category": "electronics"}';
SELECT * FROM products WHERE attributes->'tags' ? 'sale';
SELECT * FROM products WHERE (attributes->>'weight')::numeric > 5.0;
```

### JSONB Document with Generated Columns (Hybrid Pattern)

```sql
-- Store raw API response as JSONB, extract frequently-queried fields into columns
CREATE TABLE api_events (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  raw_payload jsonb NOT NULL,

  -- Generated columns for fast indexing/filtering
  event_type text GENERATED ALWAYS AS (raw_payload->>'type') STORED,
  user_id bigint GENERATED ALWAYS AS ((raw_payload->>'user_id')::bigint) STORED,
  occurred_at timestamptz GENERATED ALWAYS AS ((raw_payload->>'timestamp')::timestamptz) STORED
);

CREATE INDEX idx_api_events_type ON api_events (event_type, occurred_at);
CREATE INDEX idx_api_events_user ON api_events (user_id);
-- Full JSONB search when needed
CREATE INDEX idx_api_events_payload ON api_events USING gin (raw_payload);
```

---

## Graph Data Patterns in Relational DB

### Enhanced Adjacency List with Recursive CTEs

```sql
-- Adjacency list with depth and ordering
CREATE TABLE org_nodes (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  parent_id bigint REFERENCES org_nodes(id) ON DELETE CASCADE,
  name text NOT NULL,
  node_type text NOT NULL CHECK (node_type IN ('company','division','department','team')),
  sort_order int NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_org_parent ON org_nodes (parent_id, sort_order);

-- Full subtree query with path
WITH RECURSIVE tree AS (
  SELECT id, parent_id, name, node_type, 0 AS depth,
         ARRAY[id] AS path,
         ARRAY[sort_order] AS sort_path,
         name::text AS full_path
  FROM org_nodes WHERE id = $root_id
  UNION ALL
  SELECT n.id, n.parent_id, n.name, n.node_type, t.depth + 1,
         t.path || n.id,
         t.sort_path || n.sort_order,
         t.full_path || ' > ' || n.name
  FROM org_nodes n JOIN tree t ON n.parent_id = t.id
  WHERE t.depth < 20  -- safety limit
)
SELECT * FROM tree ORDER BY sort_path;

-- All ancestors of a node (walk up)
WITH RECURSIVE ancestors AS (
  SELECT id, parent_id, name, 0 AS distance
  FROM org_nodes WHERE id = $node_id
  UNION ALL
  SELECT n.id, n.parent_id, n.name, a.distance + 1
  FROM org_nodes n JOIN ancestors a ON n.id = a.parent_id
)
SELECT * FROM ancestors ORDER BY distance DESC;
```

### Edge Table for General Graphs (Non-Tree)

```sql
-- For networks, social graphs, dependency graphs
CREATE TABLE nodes (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  label text NOT NULL,
  properties jsonb NOT NULL DEFAULT '{}'
);

CREATE TABLE edges (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  source_id bigint NOT NULL REFERENCES nodes(id) ON DELETE CASCADE,
  target_id bigint NOT NULL REFERENCES nodes(id) ON DELETE CASCADE,
  edge_type text NOT NULL,         -- 'follows', 'depends_on', 'related_to'
  weight numeric DEFAULT 1.0,
  properties jsonb NOT NULL DEFAULT '{}',
  UNIQUE (source_id, target_id, edge_type)
);
CREATE INDEX idx_edges_source ON edges (source_id, edge_type);
CREATE INDEX idx_edges_target ON edges (target_id, edge_type);

-- Shortest path (BFS using recursive CTE)
WITH RECURSIVE paths AS (
  SELECT target_id AS current_node, ARRAY[source_id, target_id] AS path, 1 AS depth
  FROM edges WHERE source_id = $start_id AND edge_type = 'depends_on'
  UNION ALL
  SELECT e.target_id, p.path || e.target_id, p.depth + 1
  FROM edges e JOIN paths p ON e.source_id = p.current_node
  WHERE e.target_id <> ALL(p.path)  -- prevent cycles
    AND p.depth < 10
    AND e.edge_type = 'depends_on'
)
SELECT path, depth FROM paths
WHERE current_node = $end_id
ORDER BY depth LIMIT 1;
```

---

## Vector Embedding Storage Patterns

### Storing Embeddings for AI/ML Workloads

```sql
-- Requires pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Content with embeddings for semantic search
CREATE TABLE knowledge_base (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  content text NOT NULL,
  content_hash text GENERATED ALWAYS AS (md5(content)) STORED,  -- dedup
  embedding vector(1536) NOT NULL,     -- OpenAI ada-002 = 1536 dims
  source_url text,
  metadata jsonb NOT NULL DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (content_hash)
);

-- HNSW index for approximate nearest neighbor
CREATE INDEX idx_kb_embedding ON knowledge_base
  USING hnsw (embedding vector_cosine_ops)
  WITH (m = 16, ef_construction = 64);

-- Chunked documents pattern (for RAG)
CREATE TABLE document_chunks (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  document_id bigint NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  chunk_index int NOT NULL,
  content text NOT NULL,
  token_count int NOT NULL,
  embedding vector(1536) NOT NULL,
  UNIQUE (document_id, chunk_index)
);
CREATE INDEX idx_chunks_doc ON document_chunks (document_id, chunk_index);
CREATE INDEX idx_chunks_embedding ON document_chunks
  USING hnsw (embedding vector_cosine_ops);

-- Semantic search with metadata filtering
SELECT dc.content, d.title,
       1 - (dc.embedding <=> $query_embedding::vector) AS similarity
FROM document_chunks dc
JOIN documents d ON dc.document_id = d.id
WHERE d.workspace_id = $workspace_id  -- tenant scoping
ORDER BY dc.embedding <=> $query_embedding::vector
LIMIT 5;
```

---

## Change Data Capture (CDC) Patterns

### Logical Replication-Based CDC (PG 10+)

```sql
-- 1. Enable logical replication in postgresql.conf
-- wal_level = logical
-- max_replication_slots = 4

-- 2. Create a publication (what to capture)
CREATE PUBLICATION cdc_orders FOR TABLE orders, order_items;
-- Or capture all tables:
-- CREATE PUBLICATION cdc_all FOR ALL TABLES;

-- 3. Create a logical replication slot
SELECT pg_create_logical_replication_slot('cdc_orders_slot', 'pgoutput');

-- 4. Read changes (from external consumer like Debezium, or pg_logical)
-- Debezium connector config (conceptual):
-- connector.class=io.debezium.connector.postgresql.PostgresConnector
-- database.hostname=localhost
-- slot.name=cdc_orders_slot
-- publication.name=cdc_orders
```

### Trigger-Based CDC (Simpler, Self-Contained)

```sql
-- Change log table
CREATE TABLE change_log (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  table_name text NOT NULL,
  record_id bigint NOT NULL,
  operation text NOT NULL CHECK (operation IN ('INSERT','UPDATE','DELETE')),
  old_data jsonb,
  new_data jsonb,
  changed_at timestamptz NOT NULL DEFAULT now(),
  processed_at timestamptz   -- NULL = not yet consumed
);
CREATE INDEX idx_changelog_unprocessed ON change_log (changed_at) WHERE processed_at IS NULL;

-- Generic CDC trigger
CREATE OR REPLACE FUNCTION capture_changes() RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO change_log (table_name, record_id, operation, old_data, new_data)
  VALUES (
    TG_TABLE_NAME,
    COALESCE(NEW.id, OLD.id),
    TG_OP,
    CASE WHEN TG_OP IN ('UPDATE','DELETE') THEN to_jsonb(OLD) END,
    CASE WHEN TG_OP IN ('INSERT','UPDATE') THEN to_jsonb(NEW) END
  );
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Apply to tables
CREATE TRIGGER cdc_orders AFTER INSERT OR UPDATE OR DELETE ON orders
  FOR EACH ROW EXECUTE FUNCTION capture_changes();

-- Consumer: process and mark as consumed
WITH batch AS (
  SELECT id, table_name, operation, new_data
  FROM change_log
  WHERE processed_at IS NULL
  ORDER BY changed_at
  LIMIT 1000
  FOR UPDATE SKIP LOCKED
)
UPDATE change_log SET processed_at = now()
FROM batch WHERE change_log.id = batch.id
RETURNING batch.*;
```

### LISTEN/NOTIFY for Real-Time CDC

```sql
-- Trigger that sends NOTIFY on change
CREATE OR REPLACE FUNCTION notify_change() RETURNS TRIGGER AS $$
BEGIN
  PERFORM pg_notify(
    'data_changes',
    json_build_object(
      'table', TG_TABLE_NAME,
      'op', TG_OP,
      'id', COALESCE(NEW.id, OLD.id)
    )::text
  );
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Application listens: LISTEN data_changes;
-- Receives: {"table":"orders","op":"INSERT","id":456}
```

---

## Temporal Tables (System-Versioned)

### PostgreSQL Implementation

PostgreSQL does not have built-in SQL:2011 temporal tables (unlike SQL Server or MariaDB), but you can implement the same pattern with triggers and range types.

```sql
-- Main table (current state)
CREATE TABLE employees (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name text NOT NULL,
  department text NOT NULL,
  salary numeric(19,4) NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- History table (system-versioned rows)
CREATE TABLE employees_history (
  id bigint NOT NULL,  -- FK intentionally omitted (row may be deleted)
  name text NOT NULL,
  department text NOT NULL,
  salary numeric(19,4) NOT NULL,
  valid_from timestamptz NOT NULL,
  valid_to timestamptz NOT NULL,
  EXCLUDE USING gist (id WITH =, tstzrange(valid_from, valid_to) WITH &&)
);
CREATE INDEX idx_emp_history_id ON employees_history (id, valid_from);
CREATE INDEX idx_emp_history_time ON employees_history USING brin (valid_to);

-- Trigger: auto-version on UPDATE/DELETE
CREATE OR REPLACE FUNCTION version_employee() RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'UPDATE' OR TG_OP = 'DELETE' THEN
    INSERT INTO employees_history (id, name, department, salary, valid_from, valid_to)
    VALUES (OLD.id, OLD.name, OLD.department, OLD.salary, OLD.updated_at, now());
  END IF;
  IF TG_OP = 'UPDATE' THEN
    NEW.updated_at := now();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_version_employee
  BEFORE UPDATE OR DELETE ON employees
  FOR EACH ROW EXECUTE FUNCTION version_employee();

-- Query: "What was this employee's salary on 2024-03-15?"
SELECT * FROM employees WHERE id = $1
UNION ALL
SELECT id, name, department, salary, valid_from AS updated_at
FROM employees_history
WHERE id = $1 AND tstzrange(valid_from, valid_to) @> '2024-03-15'::timestamptz
LIMIT 1;

-- Convenience view: combine current + history
CREATE VIEW employees_as_of AS
  SELECT id, name, department, salary, updated_at AS valid_from, 'infinity'::timestamptz AS valid_to
  FROM employees
  UNION ALL
  SELECT id, name, department, salary, valid_from, valid_to
  FROM employees_history;
```

---

## Data Vault Modeling (Data Warehouse Scenarios)

Data Vault is a modeling methodology designed for data warehouses that need to ingest data from many sources over long periods. It separates **structure** (Hubs), **relationships** (Links), and **context** (Satellites).

```sql
-- HUB: Business key anchor (one per business entity)
CREATE TABLE hub_customer (
  hub_customer_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  customer_bk text NOT NULL UNIQUE,    -- business key (e.g., customer number)
  load_date timestamptz NOT NULL DEFAULT now(),
  record_source text NOT NULL           -- which system sent this
);

-- SATELLITE: Descriptive attributes (change-tracked)
CREATE TABLE sat_customer_details (
  hub_customer_id bigint NOT NULL REFERENCES hub_customer(hub_customer_id),
  load_date timestamptz NOT NULL,
  load_end_date timestamptz DEFAULT 'infinity',
  name text NOT NULL,
  email text,
  tier text,
  record_source text NOT NULL,
  hash_diff text NOT NULL,              -- hash of payload to detect changes
  PRIMARY KEY (hub_customer_id, load_date)
);

-- LINK: Relationship between hubs
CREATE TABLE link_customer_order (
  link_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  hub_customer_id bigint NOT NULL REFERENCES hub_customer(hub_customer_id),
  hub_order_id bigint NOT NULL REFERENCES hub_order(hub_order_id),
  load_date timestamptz NOT NULL DEFAULT now(),
  record_source text NOT NULL,
  UNIQUE (hub_customer_id, hub_order_id)
);
```

**When to use Data Vault:** Enterprise data warehouses with multiple source systems, long data retention requirements, and need for full auditability. Not suitable for operational/transactional databases or simple analytics.

---

## Anti-Patterns

| Anti-Pattern | Why It's Dangerous | Fix |
|---|---|---|
| **Entity-Attribute-Value (EAV)** | No type safety, no constraints, impossible to query efficiently | Use JSONB for flexible data, proper columns for known attributes |
| **God table** | 50+ columns, many NULLable | Split into focused tables |
| **Smart primary keys** | `PRD-2024-001` encodes meaning | Use surrogate key + separate display_code column |
| **Missing foreign keys** | Orphaned data, no referential integrity | Always add FK constraints |
| **Polymorphic FK** (type + id columns) | No DB-level integrity | Exclusive arc or shared parent table |
| **Storing calculated values without source** | Source lost, values drift | Store source, calculate or use GENERATED column |
| **No constraints** | Application bugs corrupt data | CHECK, NOT NULL, UNIQUE, FK at DB level |
| **Over-normalization** | 15 JOINs to display a profile | Denormalize hot paths with materialized views |
| **Using status as workflow** | Complex state transitions, missing history | State machine + event log |
| **No created_at/updated_at** | Can't debug, can't audit, can't replicate | Add to every table |

---

## Checklist: Data Model Review

- [ ] Every table has a clear single purpose (one sentence description)
- [ ] Primary keys are bigint or UUIDv7
- [ ] Foreign keys exist for every relationship with appropriate ON DELETE
- [ ] NOT NULL on every column unless NULL has business meaning
- [ ] CHECK constraints for domain validation
- [ ] UNIQUE constraints where business requires uniqueness
- [ ] Indexes on foreign keys and known query patterns
- [ ] Temporal columns (created_at, updated_at) on mutable tables
- [ ] Soft delete strategy decided (if needed)
- [ ] Audit trail strategy decided (if needed)
- [ ] Multi-tenancy strategy decided (if applicable, consider Citus for scale)
- [ ] Sample queries written and tested against the model
- [ ] Normalization level is appropriate (3NF default, denormalize with reason)
- [ ] No EAV tables, no polymorphic FKs, no god tables
- [ ] Migration path exists from current state
- [ ] JSONB columns have CHECK constraints for structure validation
- [ ] Event sourcing evaluated for audit-critical domains
- [ ] CDC strategy decided if downstream systems need change feeds
- [ ] Temporal/versioning pattern chosen for history-sensitive data
- [ ] Vector columns use pgvector with HNSW indexes (if AI/embedding workloads)
- [ ] Graph relationships use appropriate pattern (adjacency list, closure table, or edge table)
