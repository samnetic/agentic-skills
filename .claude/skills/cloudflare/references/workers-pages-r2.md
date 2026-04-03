# Workers, Pages, R2, and Wrangler CLI

## Table of Contents

- [Cloudflare Workers](#cloudflare-workers)
  - [Redirect Worker](#redirect-worker)
  - [Security Headers Worker](#security-headers-worker)
  - [Rate Limiting with KV](#rate-limiting-with-kv)
  - [A/B Testing Worker](#ab-testing-worker)
  - [Geolocation Routing Worker](#geolocation-routing-worker)
- [Cloudflare Pages](#cloudflare-pages)
  - [Build Configuration](#build-configuration)
  - [Pages Functions (Serverless API)](#pages-functions-serverless-api)
- [R2 Object Storage](#r2-object-storage)
  - [Worker Access to R2](#worker-access-to-r2)
  - [R2 Lifecycle Rules](#r2-lifecycle-rules)
- [Wrangler CLI Reference](#wrangler-cli-reference)

---

## Cloudflare Workers

### Redirect Worker

```javascript
export default {
  async fetch(request) {
    const url = new URL(request.url);
    const redirects = {
      '/old-page': '/new-page',
      '/blog/legacy': '/articles',
    };
    const target = redirects[url.pathname];
    if (target) return Response.redirect(`${url.origin}${target}`, 301);
    return fetch(request);
  },
};
```

### Security Headers Worker

```javascript
export default {
  async fetch(request) {
    const response = await fetch(request);
    const headers = new Headers(response.headers);
    headers.set('Strict-Transport-Security', 'max-age=31536000; includeSubDomains; preload');
    headers.set('X-Content-Type-Options', 'nosniff');
    headers.set('X-Frame-Options', 'DENY');
    headers.set('Referrer-Policy', 'strict-origin-when-cross-origin');
    headers.set('Permissions-Policy', 'camera=(), microphone=(), geolocation=(self)');
    headers.set('Content-Security-Policy',
      "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; " +
      "img-src 'self' data: https:; frame-ancestors 'none'; base-uri 'self';"
    );
    headers.delete('Server');
    headers.delete('X-Powered-By');
    return new Response(response.body, { status: response.status, headers });
  },
};
```

### Rate Limiting with KV

```javascript
// wrangler.toml: [[kv_namespaces]] binding = "RATE_LIMIT", id = "abc123"
export default {
  async fetch(request, env) {
    const ip = request.headers.get('CF-Connecting-IP');
    const key = `ratelimit:${ip}`;
    const current = parseInt(await env.RATE_LIMIT.get(key) || '0');
    const limit = 100, window = 60;

    if (current >= limit) {
      return new Response('Rate limit exceeded', {
        status: 429,
        headers: { 'Retry-After': String(window) },
      });
    }
    await env.RATE_LIMIT.put(key, String(current + 1), { expirationTtl: window });
    return fetch(request);
  },
};
```

### A/B Testing Worker

```javascript
export default {
  async fetch(request) {
    const url = new URL(request.url);
    const cookie = request.headers.get('Cookie') || '';
    let variant = cookie.match(/ab-variant=(A|B)/)?.[1];
    if (!variant) variant = Math.random() < 0.5 ? 'A' : 'B';

    if (variant === 'B' && url.pathname === '/') url.pathname = '/landing-v2';

    const response = await fetch(url.toString(), request);
    const newResponse = new Response(response.body, response);
    if (!cookie.includes('ab-variant')) {
      newResponse.headers.append('Set-Cookie',
        `ab-variant=${variant}; Path=/; Max-Age=2592000; SameSite=Lax; Secure; HttpOnly`
      );
    }
    return newResponse;
  },
};
```

### Geolocation Routing Worker

```javascript
export default {
  async fetch(request) {
    const country = request.cf?.country || 'US';
    const url = new URL(request.url);
    const regions = { US: 'us-origin', CA: 'us-origin', GB: 'eu-origin',
                      DE: 'eu-origin', JP: 'ap-origin', AU: 'ap-origin' };
    url.hostname = `${regions[country] || 'us-origin'}.example.com`;
    return fetch(url.toString(), { method: request.method, headers: request.headers, body: request.body });
  },
};
```

---

## Cloudflare Pages

### Build Configuration

```
Framework presets:
  Next.js     → Build: npx @cloudflare/next-on-pages  → Output: .vercel/output/static
  Astro       → Build: npm run build                   → Output: dist
  Remix       → Build: npm run build                   → Output: build/client
  React/Vite  → Build: npm run build                   → Output: dist

# Environment variables: Dashboard → Pages → Settings → Environment variables
# Separate production and preview values
```

### Pages Functions (Serverless API)

```javascript
// functions/api/users.js → auto-deployed as /api/users
export async function onRequestGet({ env }) {
  const users = await env.DB.prepare('SELECT * FROM users LIMIT 10').all();
  return new Response(JSON.stringify(users.results), {
    headers: { 'Content-Type': 'application/json' },
  });
}

export async function onRequestPost({ env, request }) {
  const body = await request.json();
  if (!body.name || !body.email) {
    return new Response(JSON.stringify({ error: 'Missing fields' }), { status: 400 });
  }
  await env.DB.prepare('INSERT INTO users (name, email) VALUES (?, ?)').bind(body.name, body.email).run();
  return new Response(JSON.stringify({ success: true }), { status: 201 });
}
```

---

## R2 Object Storage

### Worker Access to R2

```javascript
// wrangler.toml: [[r2_buckets]] binding = "BUCKET", bucket_name = "my-assets"
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const key = url.pathname.slice(1);

    if (request.method === 'GET') {
      const object = await env.BUCKET.get(key);
      if (!object) return new Response('Not Found', { status: 404 });
      const headers = new Headers();
      object.writeHttpMetadata(headers);
      headers.set('ETag', object.httpEtag);
      headers.set('Cache-Control', 'public, max-age=86400');
      return new Response(object.body, { headers });
    }
    if (request.method === 'PUT') {
      await env.BUCKET.put(key, request.body, {
        httpMetadata: { contentType: request.headers.get('Content-Type') || 'application/octet-stream' },
      });
      return new Response(JSON.stringify({ key }), { status: 201 });
    }
    if (request.method === 'DELETE') {
      await env.BUCKET.delete(key);
      return new Response(null, { status: 204 });
    }
    return new Response('Method Not Allowed', { status: 405 });
  },
};
```

### R2 Lifecycle Rules

```
Dashboard → R2 → Bucket → Settings → Object lifecycle rules
Prefix: tmp/  → Delete after 1 day
Prefix: logs/ → Infrequent Access after 30 days → Delete after 90 days
```

---

## Wrangler CLI Reference

```bash
# Auth
wrangler login                        # Browser OAuth
wrangler whoami                       # Check auth

# Workers
wrangler init my-worker               # New project
wrangler dev                          # Local dev (port 8787)
wrangler deploy                       # Deploy
wrangler tail                         # Live logs

# Pages
wrangler pages deploy ./dist          # Deploy static site

# R2
wrangler r2 bucket create my-bucket
wrangler r2 object put my-bucket/key --file ./file.txt

# KV
wrangler kv namespace create MY_KV
wrangler kv key put --binding MY_KV "key" "value"

# D1 (SQLite at edge)
wrangler d1 create my-db
wrangler d1 execute my-db --file schema.sql

# Secrets
wrangler secret put API_KEY           # Interactive
wrangler secret list
```
