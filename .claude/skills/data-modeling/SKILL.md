---
name: data-modeling
description: >-
  Database design and data modeling expertise. Use when designing entity-relationship
  models, normalizing schemas, deciding normalization vs denormalization, designing temporal
  data models, implementing soft deletes, creating audit trails, polymorphic associations,
  modeling hierarchical data (trees, graphs), multi-tenant architectures, creating ERDs,
  planning data migration strategies, event sourcing, JSONB document patterns, vector
  embedding storage, Change Data Capture (CDC), or reviewing existing data models.
  Triggers: data model, ERD, entity relationship, normalization, denormalization, schema
  design, database design, temporal, soft delete, audit trail, polymorphic, hierarchy,
  tree structure, multi-tenant, domain model, migration strategy, event sourcing, CQRS,
  JSONB document, vector embedding, CDC, temporal table, data vault.
license: MIT
metadata:
  author: samnetic
  version: "1.0"
---

# Data Modeling Skill

Design data models that accurately represent the domain, enforce integrity at the database
level, and perform well at scale. The database is the last line of defense for data quality.

---

## Core Principles

| # | Principle | Meaning |
|---|-----------|---------|
| 1 | **Model the domain, not the UI** | Data structures outlive any frontend. Design for the business domain |
| 2 | **Constraints in the database** | NOT NULL, CHECK, UNIQUE, FK — enforce at the source of truth |
| 3 | **Normalize first, denormalize deliberately** | Start 3NF. Denormalize only with measured query evidence |
| 4 | **Immutability where possible** | Append events rather than mutating state when audit matters |
| 5 | **Design for queries you'll run** | Know your access patterns before finalizing the model |
| 6 | **Every table needs a purpose** | If you can't explain what a table represents in one sentence, redesign |

---

## Workflow: Data Modeling

### 1. Domain Analysis

Identify entities, relationships, and business rules from requirements. Interview stakeholders. List every noun (candidate entity) and verb (candidate relationship).

### 2. Conceptual Model

Draw an ERD with entities and relationships only — no columns yet. Validate cardinality (1:1, 1:N, M:N) with domain experts.

### 3. Logical Model

Add attributes, primary keys, foreign keys, and constraints. Normalize to 3NF. Define data types semantically (not physically).

### 4. Physical Model

Choose concrete PostgreSQL types. Add indexes for known query patterns. Apply denormalization where measured evidence justifies it. Plan partitioning for large tables.

### 5. Validate

Write sample queries for every known access pattern. Check that no query requires more than 3-4 JOINs on hot paths. Verify constraint coverage. Run EXPLAIN on critical queries.

---

## Standard Table Template

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
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending','confirmed','shipped','delivered','cancelled')),
  notes text CHECK (length(notes) <= 5000),

  -- Metadata
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

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
|------|------|-------------------|-----|
| **1NF** | Atomic values, no repeating groups | `tags: "red,blue,green"` | Separate table or `text[]` |
| **2NF** | No partial dependencies on composite key | `(order_id, product_id) -> product_name` | Move product_name to products table |
| **3NF** | No transitive dependencies | `user -> zip_code -> city` | Move city to a zip_codes table |
| **BCNF** | Every determinant is a candidate key | Rare in practice | Decompose if found |

### When to Denormalize

| Scenario | Strategy | Trade-off |
|----------|----------|-----------|
| Expensive JOIN on every read | Materialized view | Stale data (refresh interval) |
| Count/sum needed constantly | Counter cache column + trigger | Write overhead |
| Full-text search | Separate search index (tsvector) | Index maintenance |
| Reporting queries | Read replica with denormalized views | Replication lag |
| N+1 API responses | Embedded JSONB for nested data | Update complexity |
| Historical snapshots | Copy data at point-in-time | Storage cost |

**Rule**: Denormalize for reads, normalize for writes. Always maintain the normalized source of truth.

---

## Decision Trees

### Hierarchy Pattern Selection

```
How deep is the tree?
├── <= 5 levels, simple parent-child queries
│   └── Adjacency List + recursive CTE
├── Deep tree, mostly read subtrees
│   └── Materialized Path
├── Complex queries (all ancestors, all descendants, move subtree)
│   └── Closure Table
└── Ordered siblings (drag & drop)
    └── Adjacency List + position column
```

### Multi-Tenancy Pattern Selection

```
How many tenants?
├── < 100, SaaS startup
│   └── Shared table + tenant_id + RLS
├── Moderate (~thousands), regulatory needs
│   ├── Schema per tenant
│   └── Citus schema-based sharding (Citus 12+)
├── Millions of tenants, scale-out needed
│   └── Citus row-based sharding (distribute by tenant_id)
└── Enterprise, strict compliance
    └── Database per tenant
```

### JSONB vs Relational Columns

```
Is the schema well-known and stable?
├── Yes → Use relational columns
├── No, varies per record → Use JSONB
├── Needs FKs or JOINs → Use relational columns
├── Sparse attributes → Use JSONB
└── Hybrid: JSONB + generated columns for hot fields
```

### Event Sourcing Decision

```
Does this domain need full audit history?
├── Yes, regulatory/compliance requirement
│   └── Event sourcing with projections
├── Yes, but simple audit is enough
│   └── Audit trail trigger (see references)
├── Need to publish domain events reliably?
│   └── Transactional outbox pattern
└── No audit needs
    └── Standard CRUD with updated_at
```

---

## Anti-Patterns

| Anti-Pattern | Why It's Dangerous | Fix |
|--------------|--------------------|-----|
| **Entity-Attribute-Value (EAV)** | No type safety, no constraints, impossible to query efficiently | Use JSONB for flexible data, proper columns for known attributes |
| **God table** | 50+ columns, many NULLable | Split into focused tables |
| **Smart primary keys** | `PRD-2024-001` encodes meaning | Use surrogate key + separate display_code column |
| **Missing foreign keys** | Orphaned data, no referential integrity | Always add FK constraints |
| **Polymorphic FK** (type + id columns) | No DB-level integrity | Exclusive arc or shared parent table |
| **Storing calculated values without source** | Source lost, values drift | Store source, calculate or use GENERATED column |
| **No constraints** | Application bugs corrupt data | CHECK, NOT NULL, UNIQUE, FK at DB level |
| **Over-normalization** | 15 JOINs to display a profile | Denormalize hot paths with materialized views |
| **Using status as workflow** | Complex transitions, missing history | State machine + event log |
| **No created_at/updated_at** | Can't debug, can't audit, can't replicate | Add to every table |

---

## Progressive Disclosure Map

| Topic | Reference | When to read |
|-------|-----------|--------------|
| Relationship patterns, polymorphic associations, hierarchy modeling | [Entity & Relationship Patterns](references/entity-relationship-patterns.md) | Designing relationships, hierarchies, or polymorphic models |
| Soft deletes, audit trails, event sourcing, CDC, temporal tables | [Temporal & Event Patterns](references/temporal-and-event-patterns.md) | Modeling time-sensitive data, audit requirements, or change feeds |
| Multi-tenancy, JSONB documents, graph data, vector embeddings, data vault | [Advanced Data Patterns](references/advanced-data-patterns.md) | Scaling multi-tenant apps, using JSONB, graph queries, AI/ML embeddings, or data warehousing |

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
