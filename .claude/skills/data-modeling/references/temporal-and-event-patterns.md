# Temporal & Event Patterns

## Table of Contents

- [Soft Deletes](#soft-deletes)
- [Audit Trail](#audit-trail)
- [Temporal Validity (Bi-Temporal)](#temporal-validity-bi-temporal)
- [Event Sourcing Patterns](#event-sourcing-patterns)
  - [Event Store Schema](#event-store-schema)
  - [Appending Events with Optimistic Concurrency](#appending-events-with-optimistic-concurrency)
  - [Projections (Read Models)](#projections-read-models)
  - [Transactional Outbox Pattern](#transactional-outbox-pattern)
- [Change Data Capture (CDC)](#change-data-capture-cdc)
  - [Logical Replication-Based CDC](#logical-replication-based-cdc)
  - [Trigger-Based CDC](#trigger-based-cdc)
  - [LISTEN/NOTIFY for Real-Time CDC](#listennotify-for-real-time-cdc)
- [Temporal Tables (System-Versioned)](#temporal-tables-system-versioned)

---

## Soft Deletes

```sql
ALTER TABLE users ADD COLUMN deleted_at timestamptz;
CREATE INDEX idx_users_active ON users (id) WHERE deleted_at IS NULL;

-- Application queries ALWAYS filter:
SELECT * FROM users WHERE deleted_at IS NULL AND ...;

-- Or use a view:
CREATE VIEW active_users AS SELECT * FROM users WHERE deleted_at IS NULL;
```

**Trade-offs:**
- Pro: Recovery possible, audit trail, FK references don't break
- Con: Every query needs filter, unique constraints need partial indexes, data accumulates
- Alternative: Move to archive table on delete (event sourcing)

---

## Audit Trail

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
```

### Generic Audit Trigger Function

```sql
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

---

## Temporal Validity (Bi-Temporal)

Track both when something IS valid and when we KNEW about it.

```sql
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

The EXCLUDE constraint prevents overlapping validity periods for the same product, enforced at the database level.

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
-- If another transaction already wrote version N, the UNIQUE constraint fails -> retry
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
  WHERE stream_type = 'Order'
    AND id > (SELECT COALESCE(MAX(last_event_id), 0) FROM order_summaries)
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

## Change Data Capture (CDC)

### Logical Replication-Based CDC

PostgreSQL 10+ supports logical replication for streaming changes to external consumers.

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

### Trigger-Based CDC

Simpler, self-contained approach without external infrastructure.

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
  SELECT id, name, department, salary, updated_at AS valid_from,
         'infinity'::timestamptz AS valid_to
  FROM employees
  UNION ALL
  SELECT id, name, department, salary, valid_from, valid_to
  FROM employees_history;
```
