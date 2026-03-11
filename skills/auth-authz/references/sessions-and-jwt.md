# Sessions and JWT

## Table of Contents

- [Session Management](#session-management)
  - [Express + Redis Full Example](#express--redis-full-example)
  - [Cookie Attributes Reference](#cookie-attributes-reference)
  - [Session Fixation Prevention](#session-fixation-prevention)
- [JWT Best Practices](#jwt-best-practices)
  - [Do You Actually Need JWTs?](#do-you-actually-need-jwts)
  - [JWT Implementation](#jwt-implementation)
  - [Signing Algorithm Selection](#signing-algorithm-selection)
  - [Revocation Strategies](#revocation-strategies)

---

## Session Management

### Express + Redis (Full Example)

```typescript
import express from 'express';
import session from 'express-session';
import RedisStore from 'connect-redis';
import { createClient } from 'redis';

const app = express();
const redisClient = createClient({ url: process.env.REDIS_URL });
await redisClient.connect();

app.use(session({
  store: new RedisStore({ client: redisClient }),
  name: '__Host-sid',                  // __Host- prefix enforces Secure + Path=/ + no Domain
  secret: process.env.SESSION_SECRET!, // Min 256 bits of entropy
  resave: false,
  saveUninitialized: false,
  cookie: {
    httpOnly: true,                    // Blocks document.cookie access
    secure: true,                      // HTTPS only
    sameSite: 'lax',                   // CSRF protection
    maxAge: 24 * 60 * 60 * 1000,      // 24h absolute timeout
    path: '/',
  },
}));

// Login — regenerate session to prevent fixation
app.post('/auth/login', async (req, res) => {
  const { email, password } = req.body;
  const user = await findUserByEmail(email);
  if (!user || !(await verifyPassword(user.passwordHash, password))) {
    return res.status(401).json({ error: 'Invalid email or password' });
  }

  req.session.regenerate((err) => {
    if (err) return res.status(500).json({ error: 'Session error' });
    req.session.userId = user.id;
    req.session.role = user.role;
    req.session.loginAt = Date.now();
    req.session.lastActivity = Date.now();
    req.session.save(() => res.json({ success: true }));
  });
});

// Logout — destroy server-side session + clear cookie
app.post('/auth/logout', (req, res) => {
  req.session.destroy(() => {
    res.clearCookie('__Host-sid', { httpOnly: true, secure: true, sameSite: 'lax', path: '/' });
    res.json({ success: true });
  });
});

// Middleware: absolute + idle timeouts
function sessionTimeout(req: express.Request, res: express.Response, next: express.NextFunction) {
  if (!req.session?.userId) return next();
  const now = Date.now();
  const ABSOLUTE_TIMEOUT = 8 * 60 * 60 * 1000;   // 8 hours
  const IDLE_TIMEOUT = 30 * 60 * 1000;             // 30 minutes

  if (now - req.session.loginAt > ABSOLUTE_TIMEOUT ||
      now - req.session.lastActivity > IDLE_TIMEOUT) {
    return req.session.destroy(() => res.status(401).json({ error: 'Session expired' }));
  }
  req.session.lastActivity = now;
  next();
}
```

### Cookie Attributes Reference

| Attribute | Purpose | Recommendation |
|---|---|---|
| `HttpOnly` | Blocks JavaScript access (mitigates XSS) | Always for session cookies |
| `Secure` | Only sent over HTTPS | Always in production |
| `SameSite=Lax` | Blocks cross-origin POST with cookie (CSRF) | Default for most apps |
| `SameSite=Strict` | Blocks all cross-origin requests with cookie | High-security (banking) |
| `__Host-` prefix | Enforces `Secure`, `Path=/`, no `Domain` | Use for session cookies |
| `__Secure-` prefix | Enforces `Secure` attribute | Minimum for sensitive cookies |

### Session Fixation Prevention

```
Session Fixation Attack:
├─ 1. Attacker obtains a valid session ID
├─ 2. Attacker tricks victim into using that session ID
├─ 3. Victim logs in — session ID now authenticated
└─ 4. Attacker uses same session ID — now authenticated

Prevention: ALWAYS regenerate session ID after:
├─ Successful login
├─ Privilege escalation
├─ Password change
└─ Any authentication state change
```

---

## JWT Best Practices

### Do You Actually Need JWTs?

```
Do you need JWT?
├─ Server-rendered web app? → NO. Use sessions.
├─ SPA with same-domain API? → NO. Use BFF + session cookies.
├─ SPA with cross-domain API? → YES. Short-lived access + HttpOnly refresh cookie.
├─ Mobile app with OAuth2? → YES. Standard OAuth2 token response.
├─ Microservices passing identity? → MAYBE. Consider shared session store first.
├─ Federated identity (OIDC)? → YES. ID tokens are JWTs by spec.
└─ "Everyone uses JWTs" → NOT a valid reason.
```

### JWT Implementation

```typescript
import { SignJWT, jwtVerify, JWTPayload } from 'jose';

const ACCESS_SECRET = new TextEncoder().encode(process.env.JWT_ACCESS_SECRET!);
const REFRESH_SECRET = new TextEncoder().encode(process.env.JWT_REFRESH_SECRET!);
const ISSUER = 'https://api.example.com';
const AUDIENCE = 'https://app.example.com';

// Access token (15min, Authorization header, in-memory only)
async function issueAccessToken(userId: string, role: string): Promise<string> {
  return new SignJWT({ sub: userId, role })
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime('15m')
    .setIssuer(ISSUER)
    .setAudience(AUDIENCE)
    .sign(ACCESS_SECRET);
}

// Refresh token (7d, HttpOnly cookie, rotate on every use)
async function issueRefreshToken(userId: string): Promise<string> {
  const jti = crypto.randomUUID();
  await db.refreshToken.create({
    data: { jti, userId, expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000) },
  });
  return new SignJWT({ sub: userId, jti })
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime('7d')
    .setIssuer(ISSUER)
    .setAudience(AUDIENCE)
    .sign(REFRESH_SECRET);
}

// Verify — always whitelist algorithm, check issuer + audience
async function verifyAccessToken(token: string): Promise<JWTPayload> {
  const { payload } = await jwtVerify(token, ACCESS_SECRET, {
    algorithms: ['HS256'],      // Prevents alg:none attack
    issuer: ISSUER,
    audience: AUDIENCE,
  });
  return payload;
}

// Refresh rotation — detect reuse (token theft)
async function refreshTokens(refreshToken: string) {
  const { payload } = await jwtVerify(refreshToken, REFRESH_SECRET, {
    algorithms: ['HS256'], issuer: ISSUER, audience: AUDIENCE,
  });

  const stored = await db.refreshToken.findUnique({ where: { jti: payload.jti as string } });
  if (!stored) {
    // Reuse detected — revoke ALL tokens for this user
    await db.refreshToken.deleteMany({ where: { userId: payload.sub } });
    throw new Error('Refresh token reuse detected. All sessions revoked.');
  }

  await db.refreshToken.delete({ where: { jti: payload.jti as string } });
  // Fetch current user role (may have changed since token was issued)
  const user = await db.user.findUniqueOrThrow({ where: { id: stored.userId } });
  const accessToken = await issueAccessToken(user.id, user.role);
  const newRefreshToken = await issueRefreshToken(user.id);
  return { accessToken, refreshToken: newRefreshToken };
}
```

### Signing Algorithm Selection

```
Which JWT signing algorithm?
├─ Single service (signs and verifies its own tokens)?
│  └─ HS256 — symmetric, fast, simple. Secret: min 256 bits.
├─ Multiple services verify tokens (microservices)?
│  └─ RS256 or ES256 — asymmetric
│     ├─ Private key signs (auth server only)
│     ├─ Public key verifies (any service)
│     ├─ Publish via JWKS endpoint (/.well-known/jwks.json)
│     └─ ES256 preferred (smaller tokens, faster)
└─ NEVER use algorithm 'none'
```

### Revocation Strategies

| Strategy | How It Works | Tradeoff |
|---|---|---|
| **Short expiry** | Access tokens expire in 15 min | Simplest; 15 min window of vulnerability |
| **Token blocklist** | Store revoked JTIs in Redis with TTL | Adds statefulness; check on every request |
| **Refresh rotation** | New refresh token on every use; detect reuse | Catches theft; requires DB lookup |
| **Version field** | `tokenVersion` in user record, included in JWT | Increment on logout/password change |
