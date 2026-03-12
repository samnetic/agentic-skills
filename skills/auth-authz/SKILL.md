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
license: MIT
metadata:
  author: samnetic
  version: "1.0"
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

## Workflow

1. **Identify the auth requirements** -- Determine application type (web, SPA, mobile, M2M), user types, and security sensitivity level.
2. **Choose authentication strategy** -- Use the decision tree below to select sessions, JWTs, OAuth2/PKCE, or API keys based on your architecture.
3. **Implement password handling** -- Hash with Argon2id, follow NIST 800-63B, integrate breach checks. See [references/password-and-mfa.md](references/password-and-mfa.md).
4. **Set up session or token management** -- Configure cookies, timeouts, refresh rotation. See [references/sessions-and-jwt.md](references/sessions-and-jwt.md).
5. **Add OAuth2/OIDC if needed** -- Integrate social logins, SSO, or M2M flows. See [references/oauth-and-sso.md](references/oauth-and-sso.md).
6. **Layer MFA on sensitive operations** -- Add TOTP, passkeys, or backup codes. See [references/password-and-mfa.md](references/password-and-mfa.md).
7. **Design authorization model** -- Choose RBAC or ABAC, implement middleware guards, add tenant isolation if multi-tenant. See [references/rbac-and-multi-tenancy.md](references/rbac-and-multi-tenancy.md).
8. **Review against checklist** -- Walk through every item in the Auth Review Checklist below before shipping.

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

## Progressive Disclosure Map

Read these references on demand -- only when working on the specific topic.

| Topic | Reference | When to read |
|-------|-----------|-------------|
| Sessions, cookies, JWT tokens, refresh rotation | [references/sessions-and-jwt.md](references/sessions-and-jwt.md) | Implementing login/logout, configuring cookies, choosing sessions vs JWTs, building token refresh |
| OAuth2/OIDC, SSO, Auth.js, library comparison | [references/oauth-and-sso.md](references/oauth-and-sso.md) | Adding social login, configuring OAuth providers, setting up Auth.js/next-auth, choosing an auth library |
| Password hashing, passkeys/WebAuthn, MFA/TOTP | [references/password-and-mfa.md](references/password-and-mfa.md) | Implementing password hashing, adding passkey support, setting up TOTP/MFA, generating backup codes |
| RBAC/ABAC, multi-tenant isolation, API keys | [references/rbac-and-multi-tenancy.md](references/rbac-and-multi-tenancy.md) | Designing permission systems, adding role-based middleware, implementing tenant isolation, securing API keys |

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
