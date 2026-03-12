# API Security, Session Management & CORS — Detailed Reference

## Table of Contents

- [OWASP API Security Top 10 (2023)](#owasp-api-security-top-10-2023)
- [Rate Limiting](#rate-limiting)
- [API Key Management](#api-key-management)
- [Request Signing / HMAC Verification](#request-signing--hmac-verification)
- [GraphQL-Specific Security](#graphql-specific-security)
- [Session Management](#session-management)
- [Session Timeouts](#session-timeouts)
- [Secure Cookie Attributes](#secure-cookie-attributes)
- [Token Storage Comparison](#token-storage-comparison)
- [CORS Deep Dive](#cors-deep-dive)
- [Common CORS Misconfigurations](#common-cors-misconfigurations)
- [Debugging CORS Issues](#debugging-cors-issues)

---

## OWASP API Security Top 10 (2023)

| # | Vulnerability | Description | Mitigation |
|---|---|---|---|
| API1 | **BOLA** — Broken Object-Level Authorization | Accessing other users' resources by changing IDs | Verify ownership on EVERY object access: `WHERE id = :id AND user_id = :userId` |
| API2 | **Broken Authentication** | Weak auth flows, credential stuffing | Rate limit auth, MFA, no client-side token storage |
| API3 | **BOPLA** — Broken Object Property-Level Authorization | Mass assignment, excessive data exposure | Explicit allowlist fields: response DTOs, `z.pick()` for input |
| API4 | **Unrestricted Resource Consumption** | No limits on request size, rate, pagination | Rate limit + max page size + request body size limits |
| API5 | **BFLA** — Broken Function-Level Authorization | Accessing admin endpoints as regular user | Check role/permissions on every handler, not just routes |
| API6 | **Unrestricted Access to Sensitive Flows** | Abuse of business flows (mass signups, scraping) | CAPTCHA, business flow rate limiting, anomaly detection |
| API7 | **Server-Side Request Forgery (SSRF)** | Fetching internal resources via user-provided URLs | URL allowlist, block private IPs, validate scheme |
| API8 | **Security Misconfiguration** | Default configs, CORS *, verbose errors | Harden defaults, audit headers, no stack traces in prod |
| API9 | **Improper Inventory Management** | Shadow/deprecated API versions still active | API gateway inventory, sunset old versions, `/docs` audit |
| API10 | **Unsafe Consumption of APIs** | Trusting third-party API responses without validation | Validate ALL external API responses with Zod/Pydantic |

```typescript
// BOLA prevention — ALWAYS verify object ownership
router.get('/orders/:id', auth, async (req, res) => {
  const order = await db.order.findFirst({
    where: { id: req.params.id, userId: req.user.id },  // userId check = BOLA prevention
  });
  if (!order) throw new NotFoundError('Order');
  res.json(order);
});

// BFLA prevention — check function-level permissions in EVERY handler
router.delete('/users/:id', auth, requireRole('admin'), async (req, res) => {
  // Even though route has requireRole, verify in service layer too
  if (!req.user.permissions.includes('users:delete')) {
    throw new ForbiddenError('Missing permission: users:delete');
  }
  await userService.delete(req.params.id);
  res.status(204).end();
});

// BOPLA prevention — explicit response DTO (never return raw DB objects)
const UserResponseSchema = z.object({
  id: z.string(),
  email: z.string(),
  name: z.string(),
  // Note: password, internalNotes, etc. are NOT included
});
```

---

## Rate Limiting

```typescript
import rateLimit from 'express-rate-limit';

// Global rate limit — all endpoints
const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,         // 15 minutes
  max: 100,                          // 100 requests per window per IP
  standardHeaders: true,             // Return RateLimit-* headers
  legacyHeaders: false,              // Disable X-RateLimit-* headers
  message: { error: 'Too many requests, please try again later.' },
});

// Strict rate limit — authentication endpoints
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,                            // 5 attempts per 15 minutes
  skipSuccessfulRequests: true,      // Only count failed attempts
  keyGenerator: (req) => {
    // Rate limit by IP + email to prevent distributed brute force
    return `${req.ip}:${req.body?.email || 'unknown'}`;
  },
});

// Sliding window with Redis (for distributed systems)
import { RedisStore } from 'rate-limit-redis';
import { createClient } from 'redis';

const redisClient = createClient({ url: process.env.REDIS_URL });
const distributedLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  store: new RedisStore({ sendCommand: (...args) => redisClient.sendCommand(args) }),
});

app.use('/api/', globalLimiter);
app.use('/api/auth/', authLimiter);
```

---

## API Key Management

```typescript
// API key generation — use cryptographically secure random values
import crypto from 'crypto';

function generateApiKey(): string {
  const prefix = 'sk_live_';                       // Identifiable prefix for secret scanning
  const key = crypto.randomBytes(32).toString('hex'); // 256-bit key
  return `${prefix}${key}`;
}

// Store hashed API keys — never store plaintext
const hashedKey = crypto.createHash('sha256').update(apiKey).digest('hex');
await db.apiKey.create({
  data: {
    keyHash: hashedKey,
    prefix: apiKey.slice(0, 12),                   // Store prefix for identification
    userId: user.id,
    scopes: ['read:orders', 'write:orders'],       // Least privilege scopes
    expiresAt: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000), // 90-day expiry
  },
});

// Verification — constant-time comparison to prevent timing attacks
function verifyApiKey(providedKey: string, storedHash: string): boolean {
  const providedHash = crypto.createHash('sha256').update(providedKey).digest('hex');
  return crypto.timingSafeEqual(Buffer.from(providedHash), Buffer.from(storedHash));
}
```

---

## Request Signing / HMAC Verification

```typescript
// Webhook signature verification (e.g., Stripe, GitHub)
import crypto from 'crypto';

function verifyWebhookSignature(
  payload: string,
  signature: string,
  secret: string,
): boolean {
  const expected = crypto
    .createHmac('sha256', secret)
    .update(payload, 'utf8')
    .digest('hex');

  const sig = signature.replace('sha256=', '');

  // Constant-time comparison — prevents timing attacks
  return crypto.timingSafeEqual(
    Buffer.from(sig, 'hex'),
    Buffer.from(expected, 'hex'),
  );
}

// Usage in middleware
app.post('/webhooks/stripe', express.raw({ type: 'application/json' }), (req, res) => {
  const signature = req.headers['stripe-signature'] as string;
  if (!verifyWebhookSignature(req.body.toString(), signature, process.env.STRIPE_WEBHOOK_SECRET!)) {
    return res.status(401).json({ error: 'Invalid signature' });
  }
  // Process the verified webhook...
});
```

---

## GraphQL-Specific Security

```typescript
import depthLimit from 'graphql-depth-limit';
import costAnalysis from 'graphql-cost-analysis';
import { ApolloServer } from '@apollo/server';

const server = new ApolloServer({
  typeDefs,
  resolvers,
  validationRules: [
    // Prevent deeply nested queries (DoS vector)
    depthLimit(10),

    // Cost analysis — limit query complexity
    costAnalysis({
      maximumCost: 1000,
      defaultCost: 1,
      variables: req.body.variables,
      createError: (max, actual) =>
        new Error(`Query cost ${actual} exceeds maximum ${max}`),
    }),
  ],

  // Disable introspection in production — prevents schema discovery
  introspection: process.env.NODE_ENV !== 'production',
});

// Rate limit by query complexity, not just request count
// Example: a single request fetching 10,000 items costs more than 100 simple requests
```

**Dangerous GraphQL patterns:**
- Nested relationship queries: `{ users { posts { comments { author { posts { ... } } } } } }` — causes N+1 and exponential joins
- Alias-based batching: sending the same expensive query 100 times via aliases in one request
- Introspection query in production: reveals entire schema to attackers

---

## Session Management

### Session Lifecycle

```typescript
import session from 'express-session';
import RedisStore from 'connect-redis';
import { createClient } from 'redis';

const redisClient = createClient({ url: process.env.REDIS_URL });

app.use(session({
  store: new RedisStore({ client: redisClient }),
  name: '__Host-session',           // __Host- prefix enforces Secure + Path=/ + no Domain
  secret: process.env.SESSION_SECRET!,
  resave: false,
  saveUninitialized: false,
  cookie: {
    httpOnly: true,                 // Not accessible via JavaScript
    secure: true,                   // Only sent over HTTPS
    sameSite: 'lax',               // CSRF protection (blocks cross-origin POST)
    maxAge: 24 * 60 * 60 * 1000,  // 24h absolute timeout
    path: '/',
  },
}));

// Session rotation after authentication — prevents session fixation
app.post('/login', async (req, res) => {
  const user = await authenticate(req.body.email, req.body.password);
  if (!user) return res.status(401).json({ error: 'Invalid credentials' });

  // CRITICAL: Regenerate session ID after login to prevent session fixation
  req.session.regenerate((err) => {
    if (err) return res.status(500).json({ error: 'Session error' });
    req.session.userId = user.id;
    req.session.loginAt = Date.now();
    req.session.lastActivity = Date.now();
    res.json({ success: true });
  });
});

// Session rotation after privilege change
app.post('/become-admin', requireAdmin, async (req, res) => {
  req.session.regenerate((err) => {
    if (err) return res.status(500).json({ error: 'Session error' });
    req.session.userId = req.user.id;
    req.session.role = 'admin';
    res.json({ success: true });
  });
});
```

---

## Session Timeouts

```typescript
// Middleware: enforce absolute and idle timeouts
function sessionTimeoutMiddleware(req: Request, res: Response, next: NextFunction) {
  if (!req.session?.userId) return next();

  const now = Date.now();
  const ABSOLUTE_TIMEOUT = 8 * 60 * 60 * 1000;  // 8 hours — max session lifetime
  const IDLE_TIMEOUT = 30 * 60 * 1000;            // 30 minutes — inactivity timeout

  // Absolute timeout — session cannot live beyond this regardless of activity
  if (now - req.session.loginAt > ABSOLUTE_TIMEOUT) {
    return req.session.destroy(() => {
      res.status(401).json({ error: 'Session expired. Please log in again.' });
    });
  }

  // Idle timeout — session expires after period of inactivity
  if (now - req.session.lastActivity > IDLE_TIMEOUT) {
    return req.session.destroy(() => {
      res.status(401).json({ error: 'Session timed out due to inactivity.' });
    });
  }

  // Update last activity timestamp
  req.session.lastActivity = now;
  next();
}
```

---

## Secure Cookie Attributes

| Attribute | Purpose | Recommendation |
|---|---|---|
| `HttpOnly` | Prevents JavaScript access (mitigates XSS) | Always set for session cookies |
| `Secure` | Only sent over HTTPS | Always set in production |
| `SameSite=Lax` | Blocks cross-origin POST requests (CSRF) | Default for most apps |
| `SameSite=Strict` | Blocks all cross-origin requests with cookie | Use for high-security (banking) |
| `__Host-` prefix | Enforces `Secure`, `Path=/`, no `Domain` | Use for session cookies |
| `__Secure-` prefix | Enforces `Secure` attribute | Minimum for sensitive cookies |
| `Max-Age` | Cookie expiry in seconds | Set to match session timeout |
| `Path=/` | Cookie sent for all paths | Default; narrow only if needed |

---

## Token Storage Comparison

| Storage | XSS Risk | CSRF Risk | Persistence | Best For |
|---|---|---|---|---|
| **HttpOnly Cookie** | Safe (JS cannot read) | Vulnerable (use SameSite) | Until expiry | Session tokens (recommended) |
| **localStorage** | Vulnerable (JS can read) | Safe (not sent automatically) | Permanent | Non-sensitive preferences |
| **sessionStorage** | Vulnerable (JS can read) | Safe (not sent automatically) | Tab lifetime | Temporary non-sensitive data |
| **Memory (JS variable)** | Safe-ish (cleared on refresh) | Safe | Page lifetime | Short-lived access tokens in SPAs |

> **Recommendation**: Store session tokens in `HttpOnly` + `Secure` + `SameSite=Lax` cookies with the `__Host-` prefix. If using JWTs in an SPA, store the refresh token in an HttpOnly cookie and keep the short-lived access token in memory only.

---

## CORS Deep Dive

### How CORS Works

CORS (Cross-Origin Resource Sharing) controls which origins can make requests to your API. The browser enforces CORS — the server just sets the policy via response headers.

### Simple vs Preflight Requests

```
Simple Request (no preflight):
  - Methods: GET, HEAD, POST
  - Headers: only Accept, Accept-Language, Content-Language, Content-Type
  - Content-Type: only application/x-www-form-urlencoded, multipart/form-data, text/plain

Preflight Request (OPTIONS sent first):
  - Any method besides GET/HEAD/POST (PUT, DELETE, PATCH)
  - Custom headers (Authorization, X-Request-ID, etc.)
  - Content-Type: application/json
  - The browser sends OPTIONS first, checks the response headers, then sends the actual request
```

### Configuration Patterns

```typescript
import cors from 'cors';

// PRODUCTION — specific origins, credentials enabled
const allowedOrigins = [
  'https://app.example.com',
  'https://admin.example.com',
];

app.use(cors({
  origin: (origin, callback) => {
    // Allow requests with no origin (mobile apps, curl, server-to-server)
    if (!origin) return callback(null, true);

    if (allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error(`Origin ${origin} not allowed by CORS`));
    }
  },
  credentials: true,                         // Allow cookies/auth headers
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Request-ID'],
  exposedHeaders: ['X-Request-ID', 'X-RateLimit-Remaining'], // Headers client can read
  maxAge: 86400,                             // Cache preflight for 24 hours
}));

// Handle preflight explicitly if needed
app.options('/api/*', cors());               // Enable preflight for all /api/ routes
```

---

## Common CORS Misconfigurations

| Misconfiguration | Why It's Dangerous | Fix |
|---|---|---|
| `origin: '*'` with `credentials: true` | Browsers block this, but devs often "fix" by reflecting the Origin header — which is worse | Use explicit allowlist |
| Reflecting `Origin` header blindly | Any site can make credentialed requests to your API | Validate origin against allowlist |
| `Access-Control-Allow-Origin: null` | Sandboxed iframes and `data:` URLs have `null` origin — attacker can exploit this | Never allow `null` origin |
| No `Vary: Origin` header | CDN may cache response for one origin and serve to another | Always include `Vary: Origin` when origin varies |
| Allowing `*.example.com` via regex | Regex like `/example\.com$/` also matches `evil-example.com` | Use exact match or carefully anchored regex: `/^https:\/\/[\w-]+\.example\.com$/` |
| Overly broad `allowedHeaders` | Exposing headers like `X-Forwarded-For` to the client | Only expose headers the client actually needs |

---

## Debugging CORS Issues

```bash
# Test preflight request manually
curl -X OPTIONS https://api.example.com/endpoint \
  -H "Origin: https://app.example.com" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type, Authorization" \
  -v 2>&1 | grep -i "access-control"

# Expected response headers:
# Access-Control-Allow-Origin: https://app.example.com
# Access-Control-Allow-Methods: GET, POST, PUT, DELETE, PATCH
# Access-Control-Allow-Headers: Content-Type, Authorization
# Access-Control-Allow-Credentials: true
# Access-Control-Max-Age: 86400
```

**CORS troubleshooting steps:**
1. Check browser console — the error message tells you exactly what's wrong
2. Verify the `Origin` header is in your allowlist (case-sensitive, include protocol)
3. For preflight: ensure OPTIONS requests return 200/204 (not 401/403)
4. If using credentials: `Access-Control-Allow-Origin` cannot be `*`
5. Check that `Vary: Origin` is set to prevent CDN caching issues
6. For non-standard headers: ensure they're in `Access-Control-Allow-Headers`
