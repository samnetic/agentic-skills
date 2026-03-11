# RBAC, ABAC, and Multi-Tenancy

## Table of Contents

- [RBAC (Role-Based Access Control)](#rbac-role-based-access-control)
  - [Role-Permission Mapping](#role-permission-mapping)
  - [Express Middleware Pattern](#express-middleware-pattern)
  - [FastAPI Decorator Pattern](#fastapi-decorator-pattern)
  - [Database Schema (Users-Roles-Permissions)](#database-schema-users-roles-permissions)
- [ABAC (Attribute-Based Access Control)](#abac-attribute-based-access-control)
  - [When RBAC Isn't Enough](#when-rbac-isnt-enough)
  - [CASL Library (Node.js)](#casl-library-nodejs)
- [Multi-Tenancy Auth](#multi-tenancy-auth)
  - [Tenant Isolation Decision Tree](#tenant-isolation-decision-tree)
  - [Row-Level Security (PostgreSQL)](#row-level-security-postgresql)
  - [Tenant Context Middleware](#tenant-context-middleware)
- [API Authentication](#api-authentication)
  - [API Key Patterns](#api-key-patterns)
  - [HMAC Signing for Webhooks](#hmac-signing-for-webhooks)

---

## RBAC (Role-Based Access Control)

### Role-Permission Mapping

```typescript
const PERMISSIONS = {
  'article:read': 'Read articles',
  'article:create': 'Create articles',
  'article:update': 'Update own articles',
  'article:update:any': 'Update any article',
  'article:delete': 'Delete own articles',
  'article:delete:any': 'Delete any article',
  'article:publish': 'Publish articles',
  'user:read': 'View user profiles',
  'user:manage': 'Manage users',
  'admin:access': 'Access admin panel',
} as const;

type Permission = keyof typeof PERMISSIONS;

const ROLES: Record<string, Permission[]> = {
  viewer: ['article:read', 'user:read'],
  author: ['article:read', 'article:create', 'article:update', 'article:delete', 'user:read'],
  editor: ['article:read', 'article:create', 'article:update', 'article:update:any',
           'article:delete', 'article:delete:any', 'article:publish', 'user:read'],
  admin:  Object.keys(PERMISSIONS) as Permission[],
};
```

### Express Middleware Pattern

```typescript
function requirePermission(...permissions: Permission[]) {
  return (req: express.Request, res: express.Response, next: express.NextFunction) => {
    if (!req.session?.userId) return res.status(401).json({ error: 'Authentication required' });
    const userPerms = ROLES[req.session.role] ?? [];
    if (!permissions.every(p => userPerms.includes(p))) {
      return res.status(403).json({ error: 'Insufficient permissions' });
    }
    next();
  };
}

app.get('/api/articles', requirePermission('article:read'), listArticles);
app.post('/api/articles', requirePermission('article:create'), createArticle);
app.delete('/api/articles/:id', requirePermission('article:delete:any'), deleteArticle);
```

### FastAPI Decorator Pattern

```python
from fastapi import Depends, HTTPException, status

ROLES: dict[str, set[str]] = {
    "viewer": {"article:read", "user:read"},
    "author": {"article:read", "article:create", "article:update", "user:read"},
    "admin": {"*"},
}

def has_permission(role: str, permission: str) -> bool:
    perms = ROLES.get(role, set())
    return "*" in perms or permission in perms

def require_permission(*permissions: str):
    async def dependency(current_user: User = Depends(get_current_user)):
        for perm in permissions:
            if not has_permission(current_user.role, perm):
                raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Insufficient permissions")
        return current_user
    return Depends(dependency)

@app.get("/api/articles")
async def list_articles(user: User = require_permission("article:read")):
    ...
```

### Database Schema (Users-Roles-Permissions)

```sql
CREATE TABLE permissions (
  id          BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  name        TEXT NOT NULL UNIQUE,
  description TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE roles (
  id          BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  name        TEXT NOT NULL UNIQUE,
  description TEXT,
  parent_id   BIGINT REFERENCES roles(id),  -- Hierarchical roles
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE role_permissions (
  role_id       BIGINT NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  permission_id BIGINT NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
  PRIMARY KEY (role_id, permission_id)
);

CREATE TABLE user_roles (
  user_id    TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role_id    BIGINT NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  granted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  granted_by TEXT REFERENCES users(id),
  PRIMARY KEY (user_id, role_id)
);

-- Get all permissions for a user (including inherited via parent roles)
WITH RECURSIVE role_tree AS (
  SELECT r.id, r.parent_id
  FROM user_roles ur JOIN roles r ON r.id = ur.role_id
  WHERE ur.user_id = $1
  UNION ALL
  SELECT r.id, r.parent_id
  FROM roles r JOIN role_tree rt ON r.id = rt.parent_id
)
SELECT DISTINCT p.name
FROM role_tree rt
JOIN role_permissions rp ON rp.role_id = rt.id
JOIN permissions p ON p.id = rp.permission_id;
```

---

## ABAC (Attribute-Based Access Control)

### When RBAC Isn't Enough

```
RBAC vs ABAC:
├─ Simple role hierarchy (admin > editor > viewer)?
│  └─ RBAC is sufficient
├─ Need resource ownership checks ("edit only own posts")?
│  └─ ABAC — check resource.authorId === user.id
├─ Time-based access ("only during business hours")?
│  └─ ABAC — check current time in allowed range
├─ Multi-tenant with tenant-scoped rules?
│  └─ ABAC — check user.tenantId === resource.tenantId
└─ Complex combinations of conditions?
   └─ ABAC — policy engine evaluates all attributes
```

### CASL Library (Node.js)

```typescript
import { AbilityBuilder, createMongoAbility, type MongoAbility } from '@casl/ability';

type Actions = 'read' | 'create' | 'update' | 'delete' | 'publish';
type Subjects = 'Article' | 'User' | 'Comment' | 'all';
type AppAbility = MongoAbility<[Actions, Subjects]>;

function defineAbilitiesFor(user: { id: string; role: string; tenantId: string }): AppAbility {
  const { can, cannot, build } = new AbilityBuilder<AppAbility>(createMongoAbility);

  if (user.role === 'admin') {
    can('read', 'all'); can('create', 'all'); can('update', 'all');
    can('delete', 'all'); can('publish', 'Article');
  }
  if (user.role === 'editor') {
    can('read', 'Article'); can('create', 'Article');
    can('update', 'Article');
    can('publish', 'Article');
    can('delete', 'Article', { authorId: user.id });
  }
  if (user.role === 'author') {
    can('read', 'Article'); can('create', 'Article');
    can('update', 'Article', { authorId: user.id });
    can('delete', 'Article', { authorId: user.id });
    cannot('update', 'Article', { status: 'published' });
  }

  // Tenant isolation
  can('read', 'Article', { tenantId: user.tenantId });

  return build();
}

// Usage
app.put('/api/articles/:id', requireAuth, async (req, res) => {
  const article = await db.article.findUnique({ where: { id: req.params.id } });
  const ability = defineAbilitiesFor(req.user);
  if (!ability.can('update', { ...article, kind: 'Article' })) {
    return res.status(403).json({ error: 'Cannot update this article' });
  }
  // Proceed...
});
```

---

## Multi-Tenancy Auth

### Tenant Isolation Decision Tree

```
How to isolate tenants?
├─ Shared tables with Row-Level Security (RLS)?
│  ├─ Pros: Simple ops, single migration path, lowest cost
│  ├─ Cons: Must never forget tenant filter, noisy neighbor risk
│  └─ Best for: SaaS with many small tenants
├─ Schema per tenant?
│  ├─ Pros: Logical isolation, per-tenant migration
│  ├─ Cons: Connection pooling complexity
│  └─ Best for: Medium tenants needing some isolation
└─ Database per tenant?
   ├─ Pros: Strongest isolation, independent scaling
   ├─ Cons: Operational complexity, cost
   └─ Best for: Enterprise, regulated industries, data residency
```

### Row-Level Security (PostgreSQL)

```sql
ALTER TABLE articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE articles FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON articles
  USING (tenant_id = current_setting('app.current_tenant_id')::text);

CREATE POLICY tenant_insert ON articles
  FOR INSERT
  WITH CHECK (tenant_id = current_setting('app.current_tenant_id')::text);
```

### Tenant Context Middleware

```typescript
async function tenantMiddleware(req: express.Request, res: express.Response, next: express.NextFunction) {
  const tenantId = req.session?.tenantId || req.headers['x-tenant-id'];
  if (!tenantId) return res.status(400).json({ error: 'Tenant context required' });

  const membership = await db.tenantMember.findFirst({
    where: { userId: req.session.userId, tenantId: tenantId as string },
  });
  if (!membership) return res.status(403).json({ error: 'Not a member of this tenant' });

  // Set PostgreSQL session variable for RLS
  await db.$executeRaw`SELECT set_config('app.current_tenant_id', ${tenantId}::text, true)`;
  req.tenantId = tenantId as string;
  next();
}
```

---

## API Authentication

### API Key Patterns

```typescript
import crypto from 'crypto';

function generateApiKey(env: 'live' | 'test'): { key: string; hash: string } {
  const prefix = env === 'live' ? 'sk_live_' : 'sk_test_';
  const key = `${prefix}${crypto.randomBytes(32).toString('hex')}`;
  const hash = crypto.createHash('sha256').update(key).digest('hex');
  return { key, hash }; // Show key ONCE, store only hash + prefix
}

async function apiKeyAuth(req: express.Request, res: express.Response, next: express.NextFunction) {
  const apiKey = req.headers['x-api-key'] as string;
  if (!apiKey) return res.status(401).json({ error: 'API key required' });

  const hash = crypto.createHash('sha256').update(apiKey).digest('hex');
  const stored = await db.apiKey.findFirst({ where: { keyHash: hash, revokedAt: null } });
  if (!stored) return res.status(401).json({ error: 'Invalid API key' });
  if (stored.expiresAt && stored.expiresAt < new Date()) {
    return res.status(401).json({ error: 'API key expired' });
  }

  req.apiKeyScopes = stored.scopes;
  await db.apiKey.update({ where: { id: stored.id }, data: { lastUsedAt: new Date() } });
  next();
}

function requireScope(...scopes: string[]) {
  return (req: express.Request, res: express.Response, next: express.NextFunction) => {
    if (!scopes.every(s => req.apiKeyScopes?.includes(s))) {
      return res.status(403).json({ error: `Required scopes: ${scopes.join(', ')}` });
    }
    next();
  };
}
```

### HMAC Signing for Webhooks

```typescript
function signWebhookPayload(payload: string, secret: string): string {
  return `sha256=${crypto.createHmac('sha256', secret).update(payload, 'utf8').digest('hex')}`;
}

function verifyWebhookSignature(payload: string, signature: string, secret: string): boolean {
  const expected = crypto.createHmac('sha256', secret).update(payload, 'utf8').digest('hex');
  const provided = signature.replace('sha256=', '');
  if (expected.length !== provided.length) return false;
  return crypto.timingSafeEqual(Buffer.from(expected, 'hex'), Buffer.from(provided, 'hex'));
}
```
