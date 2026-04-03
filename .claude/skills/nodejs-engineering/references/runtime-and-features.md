# Node.js Runtime and Features Reference

## Table of Contents

- [Event Loop Architecture](#event-loop-architecture)
- [Node.js 22 LTS Features](#nodejs-22-lts-features)
- [Node.js 24 LTS Features](#nodejs-24-lts-features)
- [ESM Migration Guide](#esm-migration-guide)
- [Bun Compatibility](#bun-compatibility)

---

## Event Loop Architecture

```
   ┌──────────────────────────────────────┐
   │              timers                   │  ← setTimeout, setInterval
   │          (execute callbacks)          │
   ├──────────────────────────────────────┤
   │         pending callbacks             │  ← I/O callbacks deferred
   ├──────────────────────────────────────┤
   │          idle, prepare               │  ← internal use
   ├──────────────────────────────────────┤
   │              poll                     │  ← I/O events (fs, net, etc.)
   │      (retrieve new I/O events)       │     Blocks here if nothing pending
   ├──────────────────────────────────────┤
   │              check                    │  ← setImmediate callbacks
   ├──────────────────────────────────────┤
   │         close callbacks               │  ← socket.on('close'), etc.
   └──────────────────────────────────────┘

   Between EVERY phase: process microtasks
   → process.nextTick() callbacks (first)
   → Promise .then/.catch/.finally callbacks (second)
```

**Critical rules:**
- Never block the event loop with synchronous operations
- `JSON.parse()` on large payloads — use streaming JSON parser
- `crypto.pbkdf2Sync` → use `crypto.pbkdf2` (async version)
- Large loops (>10ms) — break into chunks with `setImmediate`
- CPU-intensive work → Worker threads

---

## Node.js 22 LTS Features

```typescript
// --- Always use node: protocol for built-in imports ---
import { readFile } from 'node:fs/promises';     // ALWAYS 'node:fs', not 'fs'
import { createServer } from 'node:http';         // Prevents accidental npm package shadowing
import { test, describe, it } from 'node:test';   // Built-in test runner
import { DatabaseSync } from 'node:sqlite';        // Built-in SQLite (22+)

// --- Built-in test runner (node:test) — replaces Jest/Vitest for unit tests ---
import { test, describe, it, mock, before, after } from 'node:test';
import assert from 'node:assert/strict';

describe('UserService', () => {
  it('should create a user', async () => {
    const service = new UserService(mockRepo);
    const user = await service.create({ email: 'test@example.com', name: 'Test' });
    assert.equal(user.email, 'test@example.com');
    assert.ok(user.id);
  });

  it('should reject duplicate email', async () => {
    await assert.rejects(
      () => service.create({ email: 'existing@example.com', name: 'Dup' }),
      { code: 'DUPLICATE_EMAIL' },
    );
  });
});
// Run: node --test src/**/*.test.ts

// --- Built-in SQLite (node:sqlite) — great for local state, caching, embeddings ---
// Requires: node --experimental-sqlite src/server.ts   (stability 1.1 in Node 22 LTS)
import { DatabaseSync } from 'node:sqlite';

const db = new DatabaseSync(':memory:');
db.exec('CREATE TABLE kv (key TEXT PRIMARY KEY, value TEXT) STRICT');

// Positional parameters
const insert = db.prepare('INSERT OR REPLACE INTO kv (key, value) VALUES (?, ?)');
insert.run('session:abc', JSON.stringify({ userId: '123' }));

// Named parameters (prefixed with :, @, or $)
const upsert = db.prepare('INSERT OR REPLACE INTO kv (key, value) VALUES (:key, :value)');
upsert.run({ key: 'session:xyz', value: JSON.stringify({ userId: '456' }) });

// Query methods: get() → first row, all() → all rows
const row = db.prepare('SELECT value FROM kv WHERE key = ?').get('session:abc');
const all = db.prepare('SELECT * FROM kv').all();

// IMPORTANT: All operations are synchronous — avoid in hot request paths.
// Best for: CLI tools, local caching, embedded metadata, feature flags, tests.
// For production web servers: use postgres (pg) with async pool.

// --- fetch() is stable — no more node-fetch ---
const response = await fetch('https://api.example.com/data', {
  headers: { 'Authorization': `Bearer ${token}` },
  signal: AbortSignal.timeout(5000), // Built-in timeout
});
const data = await response.json();

// --- .env file support (--env-file flag) ---
// node --env-file=.env src/server.ts
// node --env-file=.env --env-file=.env.local src/server.ts  // Multiple files, last wins
// node --env-file-if-exists=.env src/server.ts              // No error if file absent (CI/CD)

// --- process.loadEnvFile() — programmatic .env loading (Node 21.7+) ---
// Use when env file path is dynamic or loading happens in code (test setup, scripts)
process.loadEnvFile();            // Loads .env from cwd (throws if not found)
process.loadEnvFile('.env.test'); // Load a specific file

// --- node --watch (replaces nodemon) ---
// node --watch src/server.ts            # Restart on file changes
// node --watch-path=./src src/server.ts # Watch specific directory

// --- Permission Model (--experimental-permission, stable in v22.13+) ---
// node --experimental-permission --allow-fs-read=/app --allow-fs-write=/tmp src/server.ts
// Restricts: file system, child processes, worker threads, native addons, WASI
// All access DENIED by default; use --allow-* flags to grant:
//   --allow-fs-read=<path>  --allow-fs-write=<path>  --allow-child-process  --allow-worker
// Runtime check: process.permission.has('fs.write', '/tmp')  → true/false

// --- Web Crypto API (stable — globalThis.crypto.subtle) ---
// Symmetric encryption (AES-GCM)
const aesKey = await crypto.subtle.generateKey({ name: 'AES-GCM', length: 256 }, true, ['encrypt', 'decrypt']);
const iv = crypto.getRandomValues(new Uint8Array(12));
const ciphertext = await crypto.subtle.encrypt({ name: 'AES-GCM', iv }, aesKey, new TextEncoder().encode('secret'));

// Asymmetric signing (ECDSA P-256) — same API works in browsers
const { privateKey, publicKey } = await crypto.subtle.generateKey({ name: 'ECDSA', namedCurve: 'P-256' }, true, ['sign', 'verify']);
const sig = await crypto.subtle.sign({ name: 'ECDSA', hash: 'SHA-256' }, privateKey, new TextEncoder().encode('payload'));
const valid = await crypto.subtle.verify({ name: 'ECDSA', hash: 'SHA-256' }, publicKey, sig, new TextEncoder().encode('payload'));

// SHA-256 hashing
const hashBuf = await crypto.subtle.digest('SHA-256', new TextEncoder().encode('hello'));
const hashHex = Buffer.from(hashBuf).toString('hex');

// --- TypeScript without build step (22.6+ type stripping) ---
// node --strip-types src/server.ts                # Stable in 22.6+, strips types, runs directly
// node --experimental-transform-types src/server.ts  # Still experimental (Node 23+) — needed for enums/namespaces

// --- Node 23+: require() for ESM ---
// const { Hono } = require('hono');  // ESM packages can now be require()'d
// Enables gradual migration from CJS to ESM
```

---

## Node.js 24 LTS Features

```typescript
// --- URLPattern (stable) — web-standard URL matching ---
const pattern = new URLPattern({ pathname: '/users/:id' });
const match = pattern.exec('https://example.com/users/123');
console.log(match?.pathname.groups.id); // '123'

// Works for routing, middleware matching, API gateways
const apiPattern = new URLPattern({ pathname: '/api/v:version/:resource' });
const result = apiPattern.exec('https://example.com/api/v2/orders');
// result.pathname.groups → { version: '2', resource: 'orders' }

// --- import.meta.dirname / import.meta.filename (stable since Node 20.11, available in Node 22 LTS) ---
// Replaces the CJS __dirname / __filename pattern in ESM
console.log(import.meta.dirname);   // '/app/src' — directory of current module
console.log(import.meta.filename);  // '/app/src/server.ts' — full path of current module

// No more: import { fileURLToPath } from 'node:url'; const __dirname = path.dirname(fileURLToPath(import.meta.url));
// Just use import.meta.dirname directly

// --- Built-in .env file loader (stable, no flag needed) ---
// node --env-file=.env src/server.ts
// node --env-file=.env --env-file=.env.local src/server.ts  // Multiple files, last wins
// Now stable — no longer behind a flag

// --- Permission Model (stable — renamed from --experimental-permission) ---
// node --permission --allow-fs-read=/app --allow-fs-write=/tmp src/server.ts
// --experimental-permission renamed to --permission in Node 22.13+ / 23.5+
// Restricts: file system, child processes, worker threads, native addons, WASI
// NOTE: Network access is NOT restricted by the Permission Model
// Runtime API: process.permission.has('fs.read', '/home/secrets')  → true/false

// --- Glob support in node:fs (stable) ---
import { glob, globSync } from 'node:fs';

const migrations = await Array.fromAsync(glob('migrations/*.sql'));
// No more need for `fast-glob` or `globby` packages for simple cases
```

---

## ESM Migration Guide

### Step-by-Step Migration

```jsonc
// 1. Set "type": "module" in package.json
{
  "name": "my-app",
  "type": "module",         // ← This makes .js files ESM by default
  "engines": { "node": ">=22" }
}
```

```typescript
// 2. Update imports — use file extensions and node: protocol

// BEFORE (CJS)
const express = require('express');
const { readFile } = require('fs/promises');
const config = require('./config');

// AFTER (ESM)
import express from 'express';
import { readFile } from 'node:fs/promises';    // Always node: prefix
import { config } from './config.js';            // File extension REQUIRED in ESM
```

```typescript
// 3. Replace __dirname / __filename

// BEFORE (CJS)
const configPath = path.join(__dirname, 'config.json');

// AFTER (ESM) — Node 22+
const configPath = path.join(import.meta.dirname, 'config.json');

// AFTER (ESM) — Node 20 (older approach, still works)
import { fileURLToPath } from 'node:url';
const __dirname = path.dirname(fileURLToPath(import.meta.url));
```

```typescript
// 4. Replace require.resolve with import.meta.resolve

// BEFORE
const templatePath = require.resolve('my-templates/default.html');

// AFTER
const templatePath = import.meta.resolve('my-templates/default.html');
```

```typescript
// 5. Replace module.exports with export

// BEFORE (CJS)
module.exports = { createApp };
module.exports.config = config;

// AFTER (ESM)
export { createApp };
export { config };
export default createApp; // Only if you had module.exports = singleThing
```

```jsonc
// 6. Update tsconfig.json for ESM
{
  "compilerOptions": {
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "target": "ES2022",
    "outDir": "dist",
    "rootDir": "src",
    "verbatimModuleSyntax": true  // Forces explicit import type
  }
}
```

### ESM Migration Checklist

- [ ] Set `"type": "module"` in package.json
- [ ] Add `.js` extension to all relative imports
- [ ] Replace `require()` with `import`
- [ ] Replace `module.exports` with `export`
- [ ] Replace `__dirname`/`__filename` with `import.meta.dirname`/`import.meta.filename`
- [ ] Replace `require.resolve()` with `import.meta.resolve()`
- [ ] Update `tsconfig.json` to use `"module": "NodeNext"`
- [ ] Replace `fs` with `node:fs` (all built-in imports use `node:` prefix)
- [ ] Test that all dependencies support ESM (most do as of 2025)
- [ ] Update test runner config if needed

---

## Bun Compatibility

| Feature | Node.js 22 | Bun |
|---|---|---|
| **npm compatibility** | Full | Full (faster installs) |
| **Built-in test runner** | `node:test` | `bun test` (Jest-compatible) |
| **TypeScript** | `--strip-types` (stable 22.6+) | Native, no config needed |
| **SQLite** | `node:sqlite` | `bun:sqlite` (stable, faster) |
| **Package manager** | npm/pnpm | `bun install` (10x faster) |
| **HTTP server** | `node:http` + Express/Fastify | `Bun.serve()` (fastest) |
| **Watch mode** | `node --watch` | `bun --watch` |
| **Worker threads** | Mature, stable | Supported but less mature |
| **Native addons (N-API)** | Full support | Partial support |
| **Production maturity** | Battle-tested | Growing, some edge cases |

**Use Bun when:** startup speed matters (serverless), TypeScript without config, internal tools.
**Stick with Node.js when:** production stability required, native addon dependencies, complex streams, enterprise environments.
