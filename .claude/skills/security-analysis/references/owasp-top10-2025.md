# OWASP Top 10 (2025) — Detailed Reference

## Table of Contents

- [Overview of 2025 Changes](#overview-of-2025-changes)
- [A01: Broken Access Control](#a01-broken-access-control)
- [A02: Security Misconfiguration](#a02-security-misconfiguration)
- [A03: Software Supply Chain Failures](#a03-software-supply-chain-failures)
- [A04: Cryptographic Failures](#a04-cryptographic-failures)
- [A05: Injection](#a05-injection)
- [A06: Insecure Design](#a06-insecure-design)
- [A07: Authentication Failures](#a07-authentication-failures)
- [A08: Software and Data Integrity](#a08-software-and-data-integrity)
- [A09: Security Logging and Monitoring](#a09-security-logging-and-monitoring)
- [A10: Mishandling of Exceptional Conditions](#a10-mishandling-of-exceptional-conditions)

---

## Overview of 2025 Changes

> The OWASP Top 10 was updated in 2025. Key changes from 2021:
> - **A02 is now Security Misconfiguration** (moved up from A05 in 2021)
> - **A03 is now Software Supply Chain Failures** (expanded from Vulnerable Components)
> - **A04 is now Cryptographic Failures** (was A02 in 2021)
> - **A05 is now Injection** (was A03 in 2021)
> - **A07 is now Authentication Failures** (renamed from Identification and Authentication Failures)
> - **A10 is now Mishandling of Exceptional Conditions** (new — replaces SSRF which merged into A01)
> - Focus shifted from symptoms to root causes

---

## A01: Broken Access Control

```typescript
// VULNERABLE — IDOR (Insecure Direct Object Reference)
app.get('/api/users/:id', async (req, res) => {
  const user = await db.user.findUnique({ where: { id: req.params.id } });
  res.json(user); // ❌ Any authenticated user can access any user's data
});

// SECURE — Authorization check
app.get('/api/users/:id', authenticate, async (req, res) => {
  if (req.user.id !== req.params.id && req.user.role !== 'admin') {
    return res.status(403).json({ error: 'Forbidden' });
  }
  const user = await db.user.findUnique({ where: { id: req.params.id } });
  res.json(user);
});
```

### SSRF (Server-Side Request Forgery)

> **2025 Change**: SSRF was previously A10 in the 2021 list. It has been merged into A01: Broken Access Control in the 2025 update because SSRF is fundamentally an access control failure on the server side.

```typescript
// VULNERABLE — user controls URL
const response = await fetch(req.body.url); // ❌ Can access internal services

// SECURE — allowlist + URL validation
const ALLOWED_HOSTS = new Set(['api.example.com', 'cdn.example.com']);

function validateUrl(url: string): URL {
  const parsed = new URL(url);
  if (!ALLOWED_HOSTS.has(parsed.hostname)) throw new Error('Host not allowed');
  if (parsed.protocol !== 'https:') throw new Error('HTTPS required');
  // Block internal IPs (127.x, 10.x, 172.16-31.x, 192.168.x, 169.254.x)
  if (isInternalIp(parsed.hostname)) throw new Error('Internal access blocked');
  // Block cloud metadata endpoints explicitly (primary SSRF target in cloud)
  const CLOUD_METADATA = new Set(['169.254.169.254', 'metadata.google.internal', '100.100.100.200']);
  if (CLOUD_METADATA.has(parsed.hostname)) throw new Error('Metadata access blocked');
  // Block DNS rebinding — resolve hostname and check IP before making request
  return parsed;
}
// Infrastructure-level defense: enforce AWS IMDSv2 (HttpTokens=required)
// so metadata requires a PUT session token — simple SSRF GETs won't work.
```

**Checklist:**
- [ ] Every endpoint has authentication + authorization
- [ ] Server-side authorization (never rely on client-side hiding)
- [ ] Users can only access their own data (test with different user IDs)
- [ ] Admin endpoints behind role checks
- [ ] Deny by default — whitelist allowed actions
- [ ] SSRF mitigated: URL allowlists, internal IP blocking, DNS rebinding prevention
- [ ] Cloud metadata endpoints (169.254.169.254) explicitly blocked; AWS IMDSv2 enforced

---

## A02: Security Misconfiguration

> **2025 Change**: Moved up from A05 in the 2021 list to A02, reflecting that misconfiguration is one of the most prevalent and impactful vulnerability categories.

```typescript
// Security headers (use helmet for Express)
import helmet from 'helmet';
import crypto from 'crypto';
app.use(helmet());

// Modern CSP — nonce-based with strict-dynamic
app.use((req, res, next) => {
  res.locals.nonce = crypto.randomBytes(16).toString('base64');
  next();
});

app.use(helmet.contentSecurityPolicy({
  directives: {
    defaultSrc: ["'self'"],
    scriptSrc: [
      "'strict-dynamic'",                  // Trust scripts loaded by trusted scripts
      (req, res) => `'nonce-${res.locals.nonce}'`, // Per-request nonce
    ],
    styleSrc: ["'self'", "'unsafe-inline'"], // Needed for some CSS-in-JS
    imgSrc: ["'self'", "data:", "https:"],
    connectSrc: ["'self'", "https://api.example.com"],
    fontSrc: ["'self'"],
    objectSrc: ["'none'"],
    baseUri: ["'self'"],                    // Prevent base tag hijacking
    frameAncestors: ["'none'"],             // Prevent clickjacking
    upgradeInsecureRequests: [],
  },
}));

// Use CSP report-only mode during rollout
// Content-Security-Policy-Report-Only: ... ; report-uri /csp-report

// Permissions-Policy (replaces Feature-Policy)
app.use((req, res, next) => {
  res.setHeader('Permissions-Policy',
    'camera=(), microphone=(), geolocation=(self), payment=(self), usb=()'
  );
  next();
});

// Cross-origin isolation headers (required for SharedArrayBuffer, high-res timers)
app.use((req, res, next) => {
  // COOP — isolate browsing context from cross-origin windows
  res.setHeader('Cross-Origin-Opener-Policy', 'same-origin');
  // COEP — require CORP or CORS for all subresources
  res.setHeader('Cross-Origin-Embedder-Policy', 'require-corp');
  // Use 'credentialless' instead of 'require-corp' if third-party resources lack CORP headers
  next();
});

// CORS — be specific, never wildcard in production
app.use(cors({
  origin: ['https://app.example.com'],   // NOT '*'
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
}));
```

**Checklist:**
- [ ] CSP uses nonces or `strict-dynamic` (not `unsafe-inline` for scripts)
- [ ] CSP deployed in `report-only` mode first, then enforced
- [ ] Permissions-Policy restricts camera, microphone, geolocation, payment
- [ ] COOP (`same-origin`) and COEP (`require-corp` or `credentialless`) set
- [ ] HSTS configured with `includeSubDomains` and `preload`
- [ ] CORS configured with specific origins (not `*`)
- [ ] Debug mode disabled in production
- [ ] Default credentials changed
- [ ] Error messages don't leak stack traces or internals
- [ ] Directory listing disabled
- [ ] Unnecessary HTTP methods disabled

---

## A03: Software Supply Chain Failures

> **2025 Change**: Expanded from A06 (Vulnerable Components) in the 2021 list to cover the entire ecosystem of dependencies, build systems, and distribution infrastructure.

```bash
# Dependency auditing
npm audit                         # Built-in
npx better-npm-audit audit        # Better formatting
snyk test                         # Snyk (more comprehensive)
trivy fs .                        # Trivy (multi-language)
npx socket optimize               # Socket.dev — detects typosquatting, install scripts, etc.

# Lock file integrity
npm ci --ignore-scripts           # Don't run arbitrary install scripts
# Review install scripts before allowing: npm show <package> scripts

# SBOM generation (Software Bill of Materials)
npx @cyclonedx/cyclonedx-npm --output-file sbom.json   # CycloneDX format
syft dir:. -o spdx-json > sbom.spdx.json                # Syft (SPDX format)

# Artifact signing with Sigstore/Cosign
cosign sign --yes myregistry.io/myapp:latest             # Keyless signing
cosign verify myregistry.io/myapp:latest                 # Verify signature

# Automated updates
# .github/dependabot.yml
```

### npm Supply Chain Attack Patterns

| Attack | How It Works | Defense |
|---|---|---|
| **Typosquatting** | Malicious package with similar name (`lodasg` vs `lodash`) | Use Socket.dev, review package names, use lockfiles |
| **Dependency confusion** | Public package matches private package name | Scope private packages (`@company/pkg`), configure registry |
| **Install script exploitation** | `postinstall` runs arbitrary code on `npm install` | Use `--ignore-scripts`, audit scripts before allowing |
| **Maintainer compromise** | Attacker gains access to legitimate maintainer account | MFA on npm, monitor for unexpected version bumps |
| **Star-jacking** | Fake popularity metrics to build trust | Check actual download stats, review code, check age |

### SLSA Framework (Supply-chain Levels for Software Artifacts)

| Level | Requirement | Meaning |
|---|---|---|
| **L1** | Provenance exists | Build system generates provenance describing how artifact was built |
| **L2** | Hosted build | Build runs on a hosted service (not developer laptop) |
| **L3** | Hardened build | Build service provides tamper-resistant provenance |

```yaml
# GitHub Actions — generate SLSA provenance (L2)
# Use slsa-framework/slsa-github-generator
- uses: slsa-framework/slsa-github-generator/.github/workflows/generator_generic_slsa3.yml@v2.0.0
  with:
    base64-subjects: ${{ steps.hash.outputs.hashes }}
```

**Checklist:**
- [ ] `npm audit` (or equivalent) runs in CI, blocks on critical/high
- [ ] Socket.dev or similar tool detects typosquatting and install scripts
- [ ] No critical/high severity vulnerabilities unaddressed
- [ ] Lock file committed and used (`npm ci` not `npm install`)
- [ ] Dependabot or Renovate configured for automated updates
- [ ] Install scripts reviewed for suspicious packages
- [ ] Private packages use scoped names (`@org/package`)
- [ ] SBOM generated and published with releases
- [ ] Artifacts signed (Sigstore/Cosign for containers, npm provenance for packages)
- [ ] MFA enabled for all npm publish accounts

---

## A04: Cryptographic Failures

> **2025 Change**: Was A02 in the 2021 list. Moved to A04 in 2025.

```typescript
// Password hashing — ALWAYS use bcrypt or argon2
import bcrypt from 'bcrypt';
const SALT_ROUNDS = 12; // OWASP minimum work factor is 10, 12+ preferred

const hash = await bcrypt.hash(password, SALT_ROUNDS);
const isValid = await bcrypt.compare(password, hash);

// NEVER: MD5, SHA-1, SHA-256 for passwords (no salt, too fast)
// NEVER: Roll your own crypto
// NEVER: Hardcoded encryption keys
```

> **Note on bcrypt cost factor**: OWASP recommends a minimum work factor of 10 for bcrypt.
> A cost of 12 is preferred and provides a good balance between security and performance.
> Each increment doubles the computation time — cost 12 is 4x slower than cost 10.
> Test on your hardware: hashing should take 250ms-1s. Increase if faster.

**Checklist:**
- [ ] Passwords hashed with bcrypt (cost 10 minimum, 12+ preferred) or argon2id
- [ ] TLS 1.2+ for all network communication
- [ ] Sensitive data encrypted at rest (database, backups)
- [ ] No sensitive data in logs (passwords, tokens, PII)
- [ ] No sensitive data in URLs (tokens in query strings)
- [ ] Encryption keys rotated on a schedule and stored in secret managers
- [ ] No use of deprecated algorithms (MD5, SHA-1, DES, RC4)

---

## A05: Injection

> **2025 Change**: Was A03 in the 2021 list. Moved to A05 in 2025.

```typescript
// SQL Injection — ALWAYS parameterized queries
// VULNERABLE
const query = `SELECT * FROM users WHERE email = '${email}'`; // ❌

// SECURE
const user = await db.query('SELECT * FROM users WHERE email = $1', [email]); // ✅
// ORMs (Prisma, Drizzle) parameterize by default — safe as long as you don't use $queryRawUnsafe

// XSS — React escapes by default, but watch for:
// VULNERABLE
<div dangerouslySetInnerHTML={{ __html: userInput }} /> // ❌
// Use DOMPurify if you must render HTML:
import DOMPurify from 'dompurify';
<div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(userInput) }} />

// Command Injection — never interpolate user input into shell commands
// VULNERABLE
exec(`convert ${filename} output.png`); // ❌
// SECURE
execFile('convert', [filename, 'output.png']); // ✅ — no shell interpretation
```

**Checklist:**
- [ ] All SQL uses parameterized queries or ORM (never string concatenation)
- [ ] No `dangerouslySetInnerHTML` without DOMPurify
- [ ] No `eval()`, `new Function()`, or template strings with user input
- [ ] No `exec()` with user input — use `execFile()` with argument arrays
- [ ] HTTP headers set: `Content-Type`, prevent MIME sniffing

---

## A06: Insecure Design

- [ ] Threat model exists (STRIDE analysis)
- [ ] Rate limiting on authentication endpoints
- [ ] Account lockout after failed attempts
- [ ] Password complexity requirements enforced
- [ ] Multi-factor authentication available for sensitive operations

---

## A07: Authentication Failures

> **2025 Change**: Renamed from "Identification and Authentication Failures" to "Authentication Failures" for clarity.

```typescript
// JWT — secure configuration
const token = jwt.sign(
  { sub: user.id, role: user.role },
  process.env.JWT_SECRET,         // ≥256 bits for HS256
  {
    algorithm: 'HS256',           // Explicit algorithm (never 'none')
    expiresIn: '15m',             // Short-lived access tokens
    issuer: 'my-app',
    audience: 'my-app-api',
  },
);

// Verification — always verify algorithm, issuer, audience
const decoded = jwt.verify(token, process.env.JWT_SECRET, {
  algorithms: ['HS256'],          // Whitelist — prevents algorithm confusion
  issuer: 'my-app',
  audience: 'my-app-api',
});

// Cookie settings for tokens
res.cookie('session', token, {
  httpOnly: true,                 // JavaScript can't read it
  secure: true,                   // HTTPS only
  sameSite: 'lax',               // CSRF protection
  maxAge: 15 * 60 * 1000,        // 15 minutes
  path: '/',
  domain: '.example.com',
});
```

### Passkeys / WebAuthn

Passkeys replace passwords with phishing-resistant, public-key cryptography. The private key never leaves the user's device.

```typescript
// Registration — server generates challenge, client creates credential
import { generateRegistrationOptions, verifyRegistrationResponse } from '@simplewebauthn/server';

const options = await generateRegistrationOptions({
  rpName: 'My App',
  rpID: 'example.com',                     // Must match your domain
  userID: user.id,
  userName: user.email,
  attestationType: 'none',                 // 'none' is sufficient for most apps
  authenticatorSelection: {
    residentKey: 'preferred',              // Enables discoverable credentials (passkeys)
    userVerification: 'preferred',         // Biometric/PIN verification
  },
});

// Store challenge in session for verification
session.currentChallenge = options.challenge;

// Authentication — identifier-first flow with Conditional UI
const authOptions = await generateAuthenticationOptions({
  rpID: 'example.com',
  allowCredentials: [],                    // Empty = discoverable credentials (passkeys)
  userVerification: 'preferred',
});
```

```html
<!-- Conditional UI — browser autofill suggests passkeys -->
<input type="text" name="username" autocomplete="username webauthn" />
```

**Passkey Best Practices:**
- HTTPS is mandatory (WebAuthn requires secure context)
- Store credential `publicKey`, `credentialId`, `signCount` in database (never the private key)
- Track `signCount` to detect cloned authenticators
- Offer passkey creation during login, signup, and post-password-recovery flows
- Support multiple passkeys per account (phone + laptop + security key)
- Keep password fallback during transition period

---

## A08: Software and Data Integrity

- [ ] CI/CD pipeline has integrity checks
- [ ] Dependencies verified (lock files, checksums)
- [ ] No untrusted serialization (avoid `JSON.parse` on untrusted input without validation)
- [ ] Subresource Integrity (SRI) on CDN scripts

---

## A09: Security Logging and Monitoring

```typescript
// Log security events (structured)
logger.warn({
  event: 'auth_failed',
  email: maskEmail(email),        // Don't log full email
  ip: req.ip,
  userAgent: req.headers['user-agent'],
  reason: 'invalid_password',
  attemptCount: failedAttempts,
});

// NEVER log:
// - Passwords (even failed ones)
// - Full credit card numbers
// - Session tokens
// - Personal data without masking
```

---

## A10: Mishandling of Exceptional Conditions

> **2025 Change**: This is a NEW category in the 2025 list, replacing SSRF (which merged into A01). It addresses code that fails open, swallows errors silently, or exposes sensitive information through error handling.

```typescript
// VULNERABLE — catch-all that fails open
async function isAuthorized(user: User, resource: string): Promise<boolean> {
  try {
    const result = await authService.checkPermission(user, resource);
    return result.allowed;
  } catch (error) {
    console.log('Auth check failed');
    return true; // ❌ FAILS OPEN — grants access when auth service is down
  }
}

// SECURE — fail closed with explicit error handling
async function isAuthorized(user: User, resource: string): Promise<boolean> {
  try {
    const result = await authService.checkPermission(user, resource);
    return result.allowed;
  } catch (error) {
    logger.error({
      event: 'auth_check_failed',
      userId: user.id,
      resource,
      error: error instanceof Error ? error.message : 'Unknown error',
    });
    return false; // ✅ FAILS CLOSED — denies access when auth service is down
  }
}

// VULNERABLE — swallowed error hides security issue
async function processPayment(order: Order): Promise<void> {
  try {
    await validatePayment(order);
    await chargeCard(order);
    await updateInventory(order);
  } catch {
    // ❌ Silently swallows ALL errors — payment may fail but inventory still updated
  }
}

// SECURE — typed error handling with appropriate responses
async function processPayment(order: Order): Promise<PaymentResult> {
  try {
    await validatePayment(order);
    await chargeCard(order);
    await updateInventory(order);
    return { status: 'success' };
  } catch (error) {
    if (error instanceof PaymentValidationError) {
      return { status: 'validation_failed', message: error.userMessage };
    }
    if (error instanceof PaymentGatewayError) {
      logger.error({ event: 'payment_gateway_error', orderId: order.id, code: error.code });
      return { status: 'gateway_error', retryable: true };
    }
    // Unknown errors — log full context, return safe generic message
    logger.error({ event: 'payment_unknown_error', orderId: order.id, error });
    return { status: 'error', message: 'An unexpected error occurred. Please try again.' };
  }
}

// VULNERABLE — error response leaks internals
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  res.status(500).json({
    error: err.message,         // ❌ May contain SQL errors, file paths, stack traces
    stack: err.stack,           // ❌ Stack trace in production
  });
});

// SECURE — generic error response with correlation ID
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  const correlationId = crypto.randomUUID();
  logger.error({
    correlationId,
    error: err.message,
    stack: err.stack,
    path: req.path,
    method: req.method,
  });
  res.status(500).json({
    error: 'Internal server error',
    correlationId,              // ✅ Client can reference this for support
  });
});
```

### Error Boundaries (React)

```tsx
// React error boundaries prevent entire app crashes from exposing sensitive state
class SecurityErrorBoundary extends React.Component<Props, State> {
  state = { hasError: false };

  static getDerivedStateFromError() {
    return { hasError: true };
  }

  componentDidCatch(error: Error, info: React.ErrorInfo) {
    // Log to monitoring service — NOT to console in production
    securityLogger.error({
      event: 'react_error_boundary',
      error: error.message,
      componentStack: info.componentStack,
    });
  }

  render() {
    if (this.state.hasError) {
      return <GenericErrorPage />; // ✅ Safe fallback, no sensitive data
    }
    return this.props.children;
  }
}
```

**Checklist:**
- [ ] All catch blocks either handle the error specifically or fail closed
- [ ] No empty catch blocks that silently swallow errors
- [ ] Security-critical operations (auth, payment, access control) always fail closed
- [ ] Error responses in production never include stack traces, SQL errors, or file paths
- [ ] Correlation IDs used to link user-facing errors to detailed server logs
- [ ] React error boundaries prevent sensitive state from leaking on crash
- [ ] Async operations have proper error handling (no unhandled promise rejections)
- [ ] Resource cleanup happens in `finally` blocks (connections, file handles, locks)
