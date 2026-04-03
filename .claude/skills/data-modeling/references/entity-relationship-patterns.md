# Entity & Relationship Patterns

## Table of Contents

- [One-to-Many Relationships](#one-to-many-relationships)
- [Many-to-Many Relationships](#many-to-many-relationships)
- [Self-Referential Hierarchy Patterns](#self-referential-hierarchy-patterns)
  - [Adjacency List](#adjacency-list)
  - [Materialized Path](#materialized-path)
  - [Closure Table](#closure-table)
- [Polymorphic Associations](#polymorphic-associations)
  - [Anti-Pattern: Polymorphic FK](#anti-pattern-polymorphic-fk)
  - [Exclusive Arc Pattern](#exclusive-arc-pattern)
  - [Shared Parent Table (Class Table Inheritance)](#shared-parent-table-class-table-inheritance)

---

## One-to-Many Relationships

```sql
-- Parent
CREATE TABLE authors (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name text NOT NULL
);

-- Child
CREATE TABLE books (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  author_id bigint NOT NULL REFERENCES authors(id) ON DELETE CASCADE,
  title text NOT NULL
);
CREATE INDEX idx_books_author_id ON books (author_id);
```

**Key rules:**
- Always index the foreign key column on the child table
- Choose ON DELETE behavior deliberately: CASCADE, SET NULL, or RESTRICT
- Use NOT NULL on the FK unless the relationship is optional

---

## Many-to-Many Relationships

```sql
CREATE TABLE book_tags (
  book_id bigint NOT NULL REFERENCES books(id) ON DELETE CASCADE,
  tag_id bigint NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
  PRIMARY KEY (book_id, tag_id),
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_book_tags_tag_id ON book_tags (tag_id);
```

**Key rules:**
- Composite primary key on both FKs
- Add a reverse index on the second FK (the PK only indexes the first column efficiently)
- Add `created_at` if you need to know when the association was created
- If the junction table has its own attributes (e.g., quantity, role), it becomes a first-class entity — give it a surrogate PK

---

## Self-Referential Hierarchy Patterns

### Adjacency List

Best for shallow trees (up to ~5 levels) with simple parent-child queries.

```sql
CREATE TABLE categories (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  parent_id bigint REFERENCES categories(id),
  name text NOT NULL,
  depth int NOT NULL DEFAULT 0
);
CREATE INDEX idx_categories_parent ON categories (parent_id);
```

Query full subtree with recursive CTE:

```sql
WITH RECURSIVE tree AS (
  SELECT id, parent_id, name, 0 AS depth,
         ARRAY[id] AS path,
         name::text AS full_path
  FROM categories WHERE id = $root_id
  UNION ALL
  SELECT c.id, c.parent_id, c.name, t.depth + 1,
         t.path || c.id,
         t.full_path || ' > ' || c.name
  FROM categories c JOIN tree t ON c.parent_id = t.id
  WHERE t.depth < 20  -- safety limit
)
SELECT * FROM tree ORDER BY path;
```

### Materialized Path

Best for deep trees where you mostly read subtrees. Denormalized — trades write complexity for fast reads.

```sql
CREATE TABLE categories (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  path text NOT NULL, -- '/1/5/23/' — all ancestors in path
  name text NOT NULL
);
CREATE INDEX idx_categories_path ON categories USING gist (path gist_trgm_ops);

-- Find entire subtree:
SELECT * FROM categories WHERE path LIKE '/1/5/%';

-- Find ancestors:
-- Parse the path and query by IDs
```

**Trade-offs:**
- Moving a subtree requires updating all descendant paths
- Path string can grow long for very deep trees
- Very fast read queries with LIKE prefix matching

### Closure Table

Best for complex queries: all ancestors, all descendants, move subtrees, depth queries. Fully normalized.

```sql
CREATE TABLE category_tree (
  ancestor_id bigint NOT NULL REFERENCES categories(id),
  descendant_id bigint NOT NULL REFERENCES categories(id),
  depth int NOT NULL,
  PRIMARY KEY (ancestor_id, descendant_id)
);
```

**Key operations:**
- Find all descendants: `WHERE ancestor_id = $id`
- Find all ancestors: `WHERE descendant_id = $id`
- Find direct children: `WHERE ancestor_id = $id AND depth = 1`
- Move subtree: Delete old ancestor links, insert new ones

**Trade-offs:**
- More storage (O(n^2) worst case for closure rows)
- Insertions require adding rows for every ancestor
- Most flexible query model

---

## Polymorphic Associations

### Anti-Pattern: Polymorphic FK

```sql
-- DO NOT DO THIS — no referential integrity possible
-- comments.commentable_type = 'Post' | 'Video'
-- comments.commentable_id = 123
-- Cannot create FK constraint!
```

### Exclusive Arc Pattern

Use separate FK columns with a CHECK constraint ensuring exactly one is set.

```sql
CREATE TABLE comments (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  post_id bigint REFERENCES posts(id),
  video_id bigint REFERENCES videos(id),
  body text NOT NULL,
  CONSTRAINT one_parent CHECK (
    num_nonnulls(post_id, video_id) = 1
  )
);
```

**When to use:** Few parent types (2-4). Simple to query. Full FK integrity.

**Trade-off:** Adding a new parent type requires an ALTER TABLE to add a new FK column.

### Shared Parent Table (Class Table Inheritance)

Use a shared base table that all commentable types extend.

```sql
CREATE TABLE commentables (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  type text NOT NULL CHECK (type IN ('post', 'video'))
);

CREATE TABLE posts (
  id bigint PRIMARY KEY REFERENCES commentables(id),
  title text NOT NULL
);

CREATE TABLE videos (
  id bigint PRIMARY KEY REFERENCES commentables(id),
  url text NOT NULL
);

CREATE TABLE comments (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  commentable_id bigint NOT NULL REFERENCES commentables(id),
  body text NOT NULL
);
```

**When to use:** Many parent types, or types added frequently. Single FK on the child. Most extensible.

**Trade-off:** Extra JOIN through the base table. Slightly more complex inserts (must insert into base table first).
