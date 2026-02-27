---
name: auth-authz
description: >-
  Authentication and authorization expertise for web and API applications. Use when
  implementing login/signup flows, choosing between sessions and JWTs, configuring
  OAuth2/OIDC providers, implementing passkeys/WebAuthn, setting up MFA/2FA with
  TOTP, designing RBAC or ABAC permission systems, securing multi-tenant applications,
  managing API keys, handling password hashing with Argon2id or bcrypt, configuring
  session management with cookies, implementing refresh token rotation, setting up
  Auth.js/next-auth/Lucia/better-auth, designing middleware-based auth guards,
  implementing SSO with SAML, or reviewing authentication and authorization code.
  Triggers: authentication, authorization, auth, login, signup, OAuth, OIDC, JWT,
  session, cookie, RBAC, ABAC, permission, role, access control, passkey, WebAuthn,
  MFA, 2FA, TOTP, SSO, SAML, API key, token, refresh token, password, bcrypt,
  argon2, multi-tenant, tenant isolation, middleware, Auth.js, next-auth, Lucia,
  better-auth.
---

# Authentication & Authorization Skill

Secure your application's front door. Sessions over JWTs for web apps. Argon2id
for passwords. Defense in depth. Least privilege everywhere. Never roll your own
crypto. When in doubt, fail closed.

---

## Core Principles

| Principle | Meaning |
|---|---|
| **Sessions over JWTs for web apps** | Server-side sessions with HttpOnly cookies are simpler and more secure than JWTs for most web applications |
| **Argon2id for passwords** | Memory-hard hashing defeats GPU attacks. Bcrypt (cost 12+) is the fallback |
| **Defense in depth** | Multiple layers: middleware, DB-level RLS, column encryption. Never rely on one control |
| **Least privilege** | Grant minimum permissions. Default deny. Escalate only when needed |
| **Never roll your own crypto** | Use established libraries (argon2, jose, @simplewebauthn). Custom crypto = broken crypto |
| **Fail closed** | Auth errors must deny access, never grant it. A crashed auth service means no one gets in |

---

## Authentication Decision Tree

```
What type of application?
├─ Server-rendered web app (Next.js, Rails, Django)?
│  └─ Sessions with HttpOnly cookies
│     ├─ Use Auth.js / better-auth for Next.js
│     ├─ Cookie: HttpOnly, Secure, SameSite=Lax, __Host- prefix
│     └─ Store sessions in Redis or database
├─ SPA with same-domain API?
│  └─ BFF (Backend for Frontend) pattern + session cookies
│     ├─ API routes proxy to backend — cookie set on same domain
│     ├─ No tokens in JavaScript — cookie handles everything
│     └─ SameSite=Lax provides CSRF protection
├─ SPA with cross-domain API?
│  └─ Short-lived JWT (access) + HttpOnly cookie (refresh)
│     ├─ Access token: 15min, in memory only (never localStorage)
│     ├─ Refresh token: 7 days, HttpOnly cookie, rotate on use
│     └─ Silent refresh before access token expires
├─ Mobile app?
│  └─ OAuth2 Authorization Code + PKCE
│     ├─ Use system browser (ASWebAuthenticationSession / Custom Tabs)
│     ├─ Store tokens in Keychain (iOS) / Keystore (Android)
│     └─ Never embed client secrets in mobile apps
├─ Machine-to-machine (M2M)?
│  └─ API keys or OAuth2 client credentials
│     ├─ API keys: prefixed (sk_live_), hashed, scoped, rotatable
│     └─ Client credentials: short-lived access tokens, no user context
└─ Third-party integration?
   └─ OAuth2 Authorization Code + PKCE
      ├─ State parameter for CSRF protection
      ├─ Nonce for replay protection (OIDC)
      └─ Validate id_token signature and claims
```

---

## Password Handling

### Argon2id Configuration (Recommended)

Argon2id is the winner of the Password Hashing Competition. It combines resistance to
GPU attacks (memory-hard) and side-channel attacks.

```typescript
// Node.js — argon2 library
import argon2 from 'argon2';

const ARGON2_OPTIONS: argon2.Options = {
  type: argon2.argon2id,         // Argon2id — hybrid (GPU + side-channel resistant)
  memoryCost: 65536,             // 64 MB memory
  timeCost: 3,                   // 3 iterations
  parallelism: 4,                // 4 parallel threads
  hashLength: 32,                // 256-bit output
};

async function hashPassword(password: string): Promise<string> {
  return argon2.hash(password, ARGON2_OPTIONS);
}

async function verifyPassword(hash: string, password: string): Promise<boolean> {
  try {
    return await argon2.verify(hash, password);
  } catch {
    return false; // Fail closed — invalid hash format = rejection
  }
}

async function needsRehash(hash: string): Promise<boolean> {
  return argon2.needsRehash(hash, ARGON2_OPTIONS);
}
```

```python
# Python — passlib with argon2
from passlib.hash import argon2

hasher = argon2.using(
    type="ID",              # Argon2id
    memory_cost=65536,      # 64 MB
    time_cost=3,            # 3 iterations
    parallelism=4,          # 4 threads
    digest_size=32,         # 256-bit output
)

hashed = hasher.hash("user_password")
is_valid = hasher.verify("user_password", hashed)

if hasher.needs_update(hashed):
    new_hash = hasher.hash("user_password")
```

### Bcrypt Fallback

```typescript
import bcrypt from 'bcrypt';
const SALT_ROUNDS = 12; // Minimum 10 (OWASP), prefer 12+

const hash = await bcrypt.hash(password, SALT_ROUNDS);
const isValid = await bcrypt.compare(password, hash);
```

> **Note**: Bcrypt has a 72-byte input limit. Longer passwords are silently truncated.
> Pre-hash with SHA-256 if needed: `bcrypt.hash(sha256(password), SALT_ROUNDS)`.

### NIST 800-63B Password Rules

```
Password Policy (NIST 800-63B):
├─ Minimum length: 8 characters (allow up to 64+)
├─ NO complexity rules (no "must include uppercase/number/symbol")
│  └─ Complexity rules produce predictable patterns: Password1!
├─ Check against breach databases (HaveIBeenPwned API)
├─ Block common passwords (dictionary of 100K+ known bad passwords)
├─ NO periodic password rotation (only rotate after breach)
├─ Allow paste in password fields (enables password managers)
└─ Show password strength meter (zxcvbn library)
```

```typescript
// Check password against HaveIBeenPwned using k-anonymity
import crypto from 'crypto';

async function isPasswordPwned(password: string): Promise<boolean> {
  const sha1 = crypto.createHash('sha1').update(password).digest('hex').toUpperCase();
  const prefix = sha1.slice(0, 5);
  const suffix = sha1.slice(5);

  const response = await fetch(`https://api.pwnedpasswords.com/range/${prefix}`);
  const text = await response.text();
  return text.split('\n').some(line => line.startsWith(suffix));
}
```

### Password Reset Flow

```
Password Reset (Secure):
├─ 1. User submits email address
│     └─ Always respond "If that email exists, we sent a reset link"
│        (prevent email enumeration)
├─ 2. Generate cryptographically random token
│     ├─ 32 bytes minimum (crypto.randomBytes(32))
│     ├─ Hash token before storing (SHA-256)
│     └─ Set expiry: 1 hour maximum
├─ 3. Send email with one-time link
├─ 4. User clicks link, submits new password
│     ├─ Verify token hash matches stored hash
│     ├─ Check expiry, validate new password
│     └─ Hash new password with Argon2id
├─ 5. Invalidate token after use (one-time only)
├─ 6. Invalidate all existing sessions
└─ 7. Send confirmation email
```

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

---

## OAuth2 / OIDC

### Authorization Code + PKCE Flow

```
Authorization Code + PKCE Flow:
├─ 1. Client generates code_verifier (random 43-128 chars)
│     └─ code_challenge = BASE64URL(SHA256(code_verifier))
│
├─ 2. Redirect user to authorization server:
│     GET /authorize?
│       response_type=code
│       &client_id=CLIENT_ID
│       &redirect_uri=https://app.example.com/callback
│       &scope=openid profile email
│       &state=RANDOM_STATE          ← CSRF protection
│       &nonce=RANDOM_NONCE          ← Replay protection (OIDC)
│       &code_challenge=CHALLENGE
│       &code_challenge_method=S256
│
├─ 3. User authenticates and consents
│
├─ 4. Authorization server redirects back:
│     GET /callback?code=AUTH_CODE&state=RANDOM_STATE
│     └─ Verify state matches stored value
│
├─ 5. Exchange code for tokens (server-side):
│     POST /token
│       grant_type=authorization_code
│       &code=AUTH_CODE
│       &redirect_uri=https://app.example.com/callback
│       &client_id=CLIENT_ID
│       &code_verifier=ORIGINAL_VERIFIER
│
└─ 6. Authorization server returns tokens:
      ├─ id_token    — Who the user is (JWT, verify signature + nonce)
      ├─ access_token — What the user can do (opaque or JWT)
      └─ refresh_token — Get new access tokens (store securely)
```

### Token Types in OIDC

| Token | Purpose | Format | Storage |
|---|---|---|---|
| **ID Token** | User identity (authentication) | JWT (verify claims) | Parse, then discard |
| **Access Token** | API authorization | Opaque or JWT | Memory or HttpOnly cookie |
| **Refresh Token** | Obtain new access tokens | Opaque | HttpOnly cookie or secure storage |

> **Rule**: Never send the ID token to your API as a bearer token. Use the access token.

### Auth.js / next-auth Setup

```typescript
// app/api/auth/[...nextauth]/route.ts
import NextAuth from 'next-auth';
import GitHub from 'next-auth/providers/github';
import Google from 'next-auth/providers/google';
import Credentials from 'next-auth/providers/credentials';
import { PrismaAdapter } from '@auth/prisma-adapter';
import { prisma } from '@/lib/prisma';

export const { handlers, auth, signIn, signOut } = NextAuth({
  adapter: PrismaAdapter(prisma),
  providers: [
    GitHub({ clientId: process.env.GITHUB_ID!, clientSecret: process.env.GITHUB_SECRET! }),
    Google({ clientId: process.env.GOOGLE_ID!, clientSecret: process.env.GOOGLE_SECRET! }),
    Credentials({
      credentials: {
        email: { label: 'Email', type: 'email' },
        password: { label: 'Password', type: 'password' },
      },
      authorize: async (credentials) => {
        const user = await findUserByEmail(credentials.email as string);
        if (!user) return null;
        const valid = await verifyPassword(user.passwordHash, credentials.password as string);
        return valid ? { id: user.id, email: user.email, name: user.name } : null;
      },
    }),
  ],
  session: { strategy: 'database' },    // Server-side sessions (not JWT)
  callbacks: {
    session({ session, user }) {
      session.user.id = user.id;
      return session;
    },
  },
});
```

### Client Credentials Grant (M2M)

```typescript
async function getM2MToken(): Promise<string> {
  const response = await fetch('https://auth.example.com/oauth/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      grant_type: 'client_credentials',
      client_id: process.env.M2M_CLIENT_ID,
      client_secret: process.env.M2M_CLIENT_SECRET,
      audience: 'https://api.example.com',
    }),
  });
  const { access_token } = await response.json();
  return access_token; // Cache until expiry
}
```

---

## Passkeys / WebAuthn

Passkeys replace passwords with phishing-resistant, public-key cryptography.
The private key never leaves the user's device.

### Registration Flow

```typescript
import {
  generateRegistrationOptions,
  verifyRegistrationResponse,
} from '@simplewebauthn/server';

const RP_NAME = 'My App';
const RP_ID = 'example.com';
const ORIGIN = 'https://example.com';

async function startRegistration(userId: string, userEmail: string) {
  const existingCredentials = await db.credential.findMany({
    where: { userId },
    select: { credentialId: true, transports: true },
  });

  const options = await generateRegistrationOptions({
    rpName: RP_NAME,
    rpID: RP_ID,
    userID: new TextEncoder().encode(userId),
    userName: userEmail,
    attestationType: 'none',
    excludeCredentials: existingCredentials.map(c => ({
      id: c.credentialId, transports: c.transports,
    })),
    authenticatorSelection: {
      residentKey: 'preferred',        // Discoverable credentials (passkeys)
      userVerification: 'preferred',   // Biometric / PIN
    },
  });

  await setSessionChallenge(userId, options.challenge);
  return options;
}

async function finishRegistration(userId: string, response: RegistrationResponseJSON) {
  const expectedChallenge = await getSessionChallenge(userId);
  const verification = await verifyRegistrationResponse({
    response,
    expectedChallenge,
    expectedOrigin: ORIGIN,
    expectedRPID: RP_ID,
  });

  if (verification.verified && verification.registrationInfo) {
    const { credential, credentialDeviceType, credentialBackedUp } = verification.registrationInfo;
    await db.credential.create({
      data: {
        userId,
        credentialId: credential.id,
        publicKey: Buffer.from(credential.publicKey),
        counter: credential.counter,
        transports: response.response.transports ?? [],
        deviceType: credentialDeviceType,
        backedUp: credentialBackedUp,
      },
    });
  }
  return verification.verified;
}
```

### Authentication Flow

```typescript
import {
  generateAuthenticationOptions,
  verifyAuthenticationResponse,
} from '@simplewebauthn/server';

async function startAuthentication() {
  const options = await generateAuthenticationOptions({
    rpID: RP_ID,
    allowCredentials: [],              // Empty = discoverable credentials (passkey autofill)
    userVerification: 'preferred',
  });
  return options;
}

async function finishAuthentication(response: AuthenticationResponseJSON) {
  const credential = await db.credential.findUnique({ where: { credentialId: response.id } });
  if (!credential) throw new Error('Credential not found');

  const verification = await verifyAuthenticationResponse({
    response,
    expectedChallenge: await getSessionChallenge(credential.userId),
    expectedOrigin: ORIGIN,
    expectedRPID: RP_ID,
    credential: {
      id: credential.credentialId,
      publicKey: credential.publicKey,
      counter: credential.counter,
    },
  });

  if (verification.verified) {
    await db.credential.update({
      where: { credentialId: response.id },
      data: { counter: verification.authenticationInfo.newCounter },
    });
  }
  return { verified: verification.verified, userId: credential.userId };
}
```

### Client-Side

```html
<!-- Conditional UI — browser autofill suggests passkeys -->
<input type="text" name="username" autocomplete="username webauthn" />
```

```typescript
import { startRegistration, startAuthentication } from '@simplewebauthn/browser';

// Registration
const options = await fetch('/api/passkey/register/start').then(r => r.json());
const result = await startRegistration({ optionsJSON: options });
await fetch('/api/passkey/register/finish', {
  method: 'POST', headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(result),
});

// Authentication
const authOptions = await fetch('/api/passkey/login/start').then(r => r.json());
const authResult = await startAuthentication({ optionsJSON: authOptions });
await fetch('/api/passkey/login/finish', {
  method: 'POST', headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(authResult),
});
```

### Passkey Best Practices

```
Passkey Implementation:
├─ HTTPS is mandatory (WebAuthn requires secure context)
├─ Store: credentialId, publicKey, counter, transports, deviceType
│  └─ NEVER store the private key (it never leaves the device)
├─ Track signCount to detect cloned authenticators
├─ Support multiple passkeys per account (phone + laptop + security key)
├─ Offer passkey creation during: signup, login, post-recovery
├─ Keep password fallback during transition period
├─ Platform authenticators: Touch ID, Face ID, Windows Hello
└─ Roaming authenticators: YubiKey, Titan Security Key
```

---

## MFA / 2FA

### TOTP Setup

```typescript
import { authenticator } from 'otplib';
import QRCode from 'qrcode';

async function setupTOTP(userId: string, userEmail: string) {
  const secret = authenticator.generateSecret();

  await db.user.update({
    where: { id: userId },
    data: { totpSecret: encrypt(secret), totpEnabled: false },
  });

  const otpauthUrl = authenticator.keyuri(userEmail, 'MyApp', secret);
  const qrCodeDataUrl = await QRCode.toDataURL(otpauthUrl);
  return { qrCodeDataUrl, secret };
}

async function verifyTOTPSetup(userId: string, code: string): Promise<boolean> {
  const user = await db.user.findUnique({ where: { id: userId } });
  const secret = decrypt(user.totpSecret);
  const isValid = authenticator.verify({ token: code, secret });

  if (isValid) {
    const backupCodes = await generateBackupCodes(userId);
    await db.user.update({ where: { id: userId }, data: { totpEnabled: true } });
    return true;
  }
  return false;
}

function verifyTOTP(secret: string, code: string): boolean {
  return authenticator.verify({ token: code, secret });
}
```

```python
# Python — pyotp
import pyotp
import qrcode
import io, base64

def setup_mfa(user_email: str) -> dict:
    secret = pyotp.random_base32()
    totp = pyotp.TOTP(secret)
    uri = totp.provisioning_uri(user_email, issuer_name="MyApp")
    img = qrcode.make(uri)
    buffer = io.BytesIO()
    img.save(buffer, format="PNG")
    qr_b64 = base64.b64encode(buffer.getvalue()).decode()
    return {"secret": secret, "qr_code": f"data:image/png;base64,{qr_b64}"}

def verify_totp(secret: str, code: str) -> bool:
    return pyotp.TOTP(secret).verify(code, valid_window=1)
```

### Backup Codes

```typescript
import crypto from 'crypto';
import bcrypt from 'bcrypt';

async function generateBackupCodes(userId: string): Promise<string[]> {
  const codes: string[] = [];
  const hashedCodes: string[] = [];

  for (let i = 0; i < 10; i++) {
    const code = `${crypto.randomBytes(2).toString('hex')}-${crypto.randomBytes(2).toString('hex')}`;
    codes.push(code);
    hashedCodes.push(await bcrypt.hash(code, 10));
  }

  await db.backupCode.createMany({
    data: hashedCodes.map(hash => ({ userId, codeHash: hash, used: false })),
  });

  return codes; // Show ONCE to the user
}

async function verifyBackupCode(userId: string, code: string): Promise<boolean> {
  const storedCodes = await db.backupCode.findMany({ where: { userId, used: false } });
  for (const stored of storedCodes) {
    if (await bcrypt.compare(code, stored.codeHash)) {
      await db.backupCode.update({ where: { id: stored.id }, data: { used: true, usedAt: new Date() } });
      return true;
    }
  }
  return false;
}
```

### MFA Method Decision Tree

```
Which MFA method?
├─ Highest security (phishing-resistant)?
│  └─ Passkeys / WebAuthn (security keys, platform authenticators)
│     └─ Best for: admin accounts, financial apps
├─ Good security, broad compatibility?
│  └─ TOTP (Google Authenticator, Authy, 1Password)
│     └─ Best for: most applications
├─ User convenience priority?
│  └─ Push notifications (via auth provider)
│     └─ Best for: consumer apps with mobile focus
├─ Fallback / recovery?
│  └─ Backup codes (one-time, hashed, stored securely)
│     └─ ALWAYS provide alongside primary MFA method
└─ Avoid if possible:
   └─ SMS OTP — vulnerable to SIM swap, SS7 attacks
      └─ Only use if no alternative (regulatory requirement)
```

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

---

## Auth Libraries Comparison

| Library | Language | Sessions | OAuth | Passkeys | Strengths | Weaknesses |
|---|---|---|---|---|---|---|
| **Auth.js (v5)** | TS/JS | DB/JWT | 80+ providers | Via adapter | Massive ecosystem, Next.js integration | Complex config, Credentials caveats |
| **better-auth** | TS/JS | DB | OAuth2/OIDC | Plugin | Type-safe, modern, plugin system | Newer, smaller community |
| **Lucia** | TS/JS | DB | Manual | Manual | Minimal, transparent, no magic | Deprecated (v3 final), build OAuth yourself |
| **Passport.js** | JS | Manual | 500+ strategies | Via strategy | Huge ecosystem, battle-tested | Dated API, callback-heavy |
| **oslo** | TS | Manual | Manual | Manual | Low-level primitives, tree-shakeable | Not a full auth solution |
| **authlib** | Python | Manual | Full OAuth2/OIDC | Manual | Spec-compliant, Flask/Django/FastAPI | Steeper learning curve |

### Selection Guide

```
Choosing an auth library?
├─ Next.js with social logins? → Auth.js (v5)
├─ Type-safe, modern, extensible? → better-auth
├─ Full control, minimal abstraction? → oslo + custom sessions
├─ Python (FastAPI/Flask/Django)? → authlib
├─ Need 500+ OAuth strategies? → Passport.js
└─ Learning auth internals? → Study Lucia source code
```

---

## Anti-Patterns

| Anti-Pattern | Why It's Dangerous | Fix |
|---|---|---|
| Using JWTs as sessions in web apps | Cannot revoke, larger than cookies, XSS risk if in localStorage | Server-side sessions with HttpOnly cookies |
| Storing tokens in `localStorage` | Any XSS vulnerability steals tokens | HttpOnly cookies or in-memory only |
| MD5/SHA-1/SHA-256 for passwords | No salt, too fast on GPUs | Argon2id (preferred) or bcrypt (cost 12+) |
| No CSRF protection on cookie auth | Cross-origin forms submit with cookies | `SameSite=Lax` + CSRF token for non-GET |
| Password complexity rules | Predictable patterns: Password1! | NIST 800-63B: min 8, breach check, no complexity |
| Rolling your own crypto | Subtle bugs lead to auth bypass | Use established libraries (argon2, jose, @simplewebauthn) |
| API keys hardcoded in source | Leaked in git history forever | Environment variables, secret manager |
| No rate limiting on login | Brute force and credential stuffing | 5 attempts per 15min per IP+email |
| Session ID in URL query string | Leaked via Referer header, logs, history | Session ID in HttpOnly cookie only |
| No session regeneration after login | Session fixation attack | `req.session.regenerate()` after auth |
| Long-lived JWTs (hours/days) | Stolen token = long-term access | Access tokens: 15 min max. Use refresh tokens |
| Same refresh token forever | Stolen token = permanent access | Rotate on every use; detect reuse |
| Storing passwords in plaintext | Single breach exposes all users | Always hash with Argon2id/bcrypt |
| JWT `alg: none` accepted | Disables signature verification | Whitelist algorithms: `algorithms: ['HS256']` |
| Same error for "not found" vs "wrong password" missing | Enables username enumeration | Same message + constant-time response |
| MFA backup codes in plaintext | Breach exposes recovery codes | Hash with bcrypt before storing |
| Not validating OAuth `state` param | CSRF in OAuth flow | Random state, store in session, verify on callback |
| Refresh tokens in `localStorage` | XSS steals long-lived tokens | HttpOnly cookie with `Secure` + `SameSite=Lax` |

---

## Checklist: Auth Review

### Authentication
- [ ] Password hashing uses Argon2id (64MB/3/4) or bcrypt (cost 12+)
- [ ] Password policy follows NIST 800-63B (min 8, no complexity, breach check)
- [ ] Login endpoint rate-limited (5 attempts per 15min per IP+email)
- [ ] Auth errors are generic ("Invalid email or password")
- [ ] Password reset uses random tokens with 1-hour expiry
- [ ] Password reset invalidates all existing sessions
- [ ] Passkeys/WebAuthn offered as auth option
- [ ] MFA available for sensitive operations

### Sessions
- [ ] Session ID regenerated after login (prevents fixation)
- [ ] Session ID regenerated after privilege escalation
- [ ] Absolute timeout enforced (8-24 hours)
- [ ] Idle timeout enforced (15-30 minutes)
- [ ] Cookie: `HttpOnly`, `Secure`, `SameSite=Lax`, `__Host-` prefix
- [ ] Session data server-side (Redis/DB), not in cookie
- [ ] Logout destroys server-side session and clears cookie
- [ ] Concurrent session limits for high-security apps

### Passwords
- [ ] Argon2id or bcrypt used (never MD5/SHA/plaintext)
- [ ] Checked against HaveIBeenPwned breach database
- [ ] No complexity rules (NIST 800-63B)
- [ ] No periodic forced rotation
- [ ] Paste allowed in password fields
- [ ] Max length enforced (128 chars; bcrypt 72 bytes)

### Authorization
- [ ] Every endpoint has authentication + authorization
- [ ] Authorization enforced server-side (never client-only)
- [ ] Permissions checked at resource level
- [ ] Default deny: whitelist allowed actions
- [ ] RBAC or ABAC model defined and documented
- [ ] No IDOR: users cannot access others' resources by changing IDs
- [ ] Admin endpoints behind separate role checks

### API Security
- [ ] API keys use identifiable prefix (`sk_live_`, `sk_test_`)
- [ ] API keys stored as SHA-256 hashes
- [ ] API keys have scopes and expiry dates
- [ ] API key rotation supported without downtime
- [ ] Webhook signatures verified with HMAC (constant-time)
- [ ] Rate limiting per API key
- [ ] OAuth2 uses PKCE for all public clients
- [ ] OAuth2 state parameter validated
- [ ] ID tokens never used as API bearer tokens

### Multi-Tenancy
- [ ] Tenant isolation at database level (RLS or schema/DB separation)
- [ ] Tenant context set on every request via middleware
- [ ] Users verified as members of requested tenant
- [ ] Cross-tenant data access impossible (tested)
- [ ] Tenant ID in JWT claims where applicable
- [ ] Super-admin is explicit, separate role
