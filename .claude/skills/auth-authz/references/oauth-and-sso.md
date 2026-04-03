# OAuth2, OIDC, and SSO

## Table of Contents

- [Authorization Code + PKCE Flow](#authorization-code--pkce-flow)
- [Token Types in OIDC](#token-types-in-oidc)
- [Auth.js / next-auth Setup](#authjs--next-auth-setup)
- [Client Credentials Grant (M2M)](#client-credentials-grant-m2m)
- [Auth Libraries Comparison](#auth-libraries-comparison)
- [Library Selection Guide](#library-selection-guide)

---

## Authorization Code + PKCE Flow

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

## Token Types in OIDC

| Token | Purpose | Format | Storage |
|---|---|---|---|
| **ID Token** | User identity (authentication) | JWT (verify claims) | Parse, then discard |
| **Access Token** | API authorization | Opaque or JWT | Memory or HttpOnly cookie |
| **Refresh Token** | Obtain new access tokens | Opaque | HttpOnly cookie or secure storage |

> **Rule**: Never send the ID token to your API as a bearer token. Use the access token.

## Auth.js / next-auth Setup

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

## Client Credentials Grant (M2M)

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

## Auth Libraries Comparison

| Library | Language | Sessions | OAuth | Passkeys | Strengths | Weaknesses |
|---|---|---|---|---|---|---|
| **Auth.js (v5)** | TS/JS | DB/JWT | 80+ providers | Via adapter | Massive ecosystem, Next.js integration | Complex config, Credentials caveats |
| **better-auth** | TS/JS | DB | OAuth2/OIDC | Plugin | Type-safe, modern, plugin system | Newer, smaller community |
| **Lucia** | TS/JS | DB | Manual | Manual | Minimal, transparent, no magic | Deprecated (v3 final), build OAuth yourself |
| **Passport.js** | JS | Manual | 500+ strategies | Via strategy | Huge ecosystem, battle-tested | Dated API, callback-heavy |
| **oslo** | TS | Manual | Manual | Manual | Low-level primitives, tree-shakeable | Not a full auth solution |
| **authlib** | Python | Manual | Full OAuth2/OIDC | Manual | Spec-compliant, Flask/Django/FastAPI | Steeper learning curve |

## Library Selection Guide

```
Choosing an auth library?
├─ Next.js with social logins? → Auth.js (v5)
├─ Type-safe, modern, extensible? → better-auth
├─ Full control, minimal abstraction? → oslo + custom sessions
├─ Python (FastAPI/Flask/Django)? → authlib
├─ Need 500+ OAuth strategies? → Passport.js
└─ Learning auth internals? → Study Lucia source code
```
