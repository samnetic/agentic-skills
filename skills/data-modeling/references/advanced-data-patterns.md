# Advanced Data Patterns

## Table of Contents

- [Multi-Tenancy Patterns](#multi-tenancy-patterns)
  - [Pattern Comparison](#pattern-comparison)
  - [Shared Table Pattern with RLS](#shared-table-pattern-with-rls)
  - [Citus Distributed Multi-Tenancy](#citus-distributed-multi-tenancy)
- [Document Model Patterns (JSONB)](#document-model-patterns-jsonb)
  - [JSONB Schema Validation with CHECK Constraints](#jsonb-schema-validation-with-check-constraints)
  - [JSONB with Generated Columns (Hybrid Pattern)](#jsonb-with-generated-columns-hybrid-pattern)
- [Graph Data Patterns in Relational DB](#graph-data-patterns-in-relational-db)
  - [Enhanced Adjacency List with Recursive CTEs](#enhanced-adjacency-list-with-recursive-ctes)
  - [Edge Table for General Graphs](#edge-table-for-general-graphs)
- [Vector Embedding Storage Patterns](#vector-embedding-storage-patterns)
- [Data Vault Modeling (Data Warehouse)](#data-vault-modeling-data-warehouse)

---

## Multi-Tenancy Patterns

### Pattern Comparison

| Pattern | Isolation | Complexity | Use When |
|---------|-----------|------------|----------|
| **Shared table + tenant_id** | Low | Low | SaaS startup, <100 tenants |
| **Schema per tenant** | Medium | Medium | Regulatory needs, moderate tenants |
| **Database per tenant** | High | High | Enterprise, strict compliance |
| **Citus row-based sharding** | Medium | Medium | Scale-out, millions of tenants |
| **Citus schema-based sharding** | High | Low | Moderate tenants (~thousands), easy migration |

### Shared Table Pattern with RLS

The most common pattern for SaaS applications. Every table includes a `tenant_id` column, and Row Level Security ensures isolation.

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

### Citus Distributed Multi-Tenancy

For scale-out with millions of tenants. Citus co-locates rows with the same `tenant_id` on the same shard.

```sql
-- Row-based sharding: distribute all tables by tenant_id
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

## Document Model Patterns (JSONB)

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

### JSONB with Generated Columns (Hybrid Pattern)

Store raw payloads as JSONB while extracting frequently-queried fields into generated columns for fast indexing.

```sql
CREATE TABLE api_events (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  raw_payload jsonb NOT NULL,

  -- Generated columns for fast indexing/filtering
  event_type text GENERATED ALWAYS AS (raw_payload->>'type') STORED,
  user_id bigint GENERATED ALWAYS AS ((raw_payload->>'user_id')::bigint) STORED,
  occurred_at timestamptz GENERATED ALWAYS AS
    ((raw_payload->>'timestamp')::timestamptz) STORED
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

### Edge Table for General Graphs

For networks, social graphs, and dependency graphs (non-tree structures).

```sql
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

For AI/ML workloads using pgvector.

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

## Data Vault Modeling (Data Warehouse)

Data Vault is a modeling methodology for data warehouses ingesting data from many sources over long periods. It separates **structure** (Hubs), **relationships** (Links), and **context** (Satellites).

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
