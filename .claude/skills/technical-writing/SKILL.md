---
name: technical-writing
description: >-
  Technical writing and documentation expertise. Use when writing or reviewing
  README files, API documentation (OpenAPI, Swagger, Redoc, Scalar), code
  documentation (JSDoc, TSDoc, docstrings, TypeDoc), architecture decision
  records (ADRs), changelogs, runbooks, onboarding guides, specifications,
  code comments, developer guides, or establishing documentation standards.
  Applies the Diataxis framework for documentation structure, docs-as-code
  workflows, and writing style best practices for technical content.
  Triggers: README, documentation, docs, API docs, JSDoc, TSDoc, ADR,
  architecture decision record, changelog, runbook, onboarding, code comments,
  technical writing, spec, specification, Diataxis, docstring, swagger, redoc,
  typedoc, OpenAPI, developer guide, writing style, docs-as-code, Scalar,
  knowledge base, how-to guide, tutorial, reference docs, explanation.
---

# Technical Writing Skill

Documentation is a product. If users cannot understand your software, your
software does not exist. Write for the reader, not for yourself. Every
doc should answer one question: "What does the reader need to do or know
right now?"

---

## Core Principles

| Principle | Meaning |
|---|---|
| **Write for the reader** | Assume they are smart but unfamiliar. No jargon without definition |
| **Diataxis: 4 doc types** | Tutorial, How-To, Reference, Explanation. Never mix them in one document |
| **README is the landing page** | 30 seconds to understand what this is and how to start |
| **Comments explain WHY** | Code shows WHAT and HOW. Comments explain the reasoning behind a choice |
| **Docs-as-code** | Version alongside source, review in PRs, test with CI, deploy automatically |
| **Colocation** | Place docs near the code they describe. A wiki across the building rots |
| **Examples over prose** | One working code example beats three paragraphs of explanation |
| **Current or deleted** | Wrong docs are worse than no docs. Stale documentation erodes trust |

---

## Diataxis Framework

Four types of documentation, each serving a different user need. Each type
has a distinct purpose, tone, and structure. Mixing them within a single
document creates confusion.

### Decision Tree: Choosing the Doc Type

```
What does the reader need?
├─ Learning (new to this)
│  ├─ Guided hands-on experience? → TUTORIAL
│  │  └─ "Learn Django by building a blog"
│  │  └─ Teaching-oriented, step-by-step, works first time
│  └─ Understand concepts / reasoning? → EXPLANATION
│     └─ "How Django's ORM maps objects to tables"
│     └─ Understanding-oriented, discursive, context-rich
├─ Working (trying to do something now)
│  ├─ Specific task to accomplish? → HOW-TO GUIDE
│  │  └─ "How to add authentication to your API"
│  │  └─ Task-oriented, assumes basic knowledge, practical
│  └─ Looking up specific details? → REFERENCE
│     └─ "List of all CLI flags and their defaults"
│     └─ Information-oriented, accurate, complete, structured
└─ Unsure? Ask: "Is the reader studying or working?"
   ├─ Studying → Tutorial or Explanation
   └─ Working → How-To or Reference
```

### The Four Types Compared

| Aspect | Tutorial | How-To Guide | Reference | Explanation |
|---|---|---|---|---|
| **Oriented to** | Learning | Tasks | Information | Understanding |
| **Purpose** | Teach a beginner | Solve a specific problem | Describe the machinery | Clarify concepts |
| **Form** | A lesson | A series of steps | Dry, structured description | Discursive prose |
| **Analogy** | Cooking class | A recipe | Encyclopedia entry | Article on culinary history |
| **Reader state** | "I don't know what I don't know" | "I know what I need to do" | "I need a specific fact" | "I want to understand why" |
| **Example** | "Build your first REST API" | "How to add rate limiting" | "CLI flag reference" | "Why we chose PostgreSQL (ADR)" |

### Tutorial Structure

```markdown
# Tutorial: Build a REST API with Express

## What you will learn
- Set up an Express server from scratch
- Create CRUD endpoints
- Connect to PostgreSQL with parameterized queries

## Prerequisites
- Node.js 20+ installed
- PostgreSQL running locally (or Docker)
- Basic JavaScript knowledge

## Step 1: Initialize the project

Create a new directory and initialize npm:

    mkdir my-api && cd my-api
    npm init -y
    npm install express pg

You should see a `package.json` file in your directory.

## Step 2: Create the server

Create `server.js` with the following content:

    const express = require('express');
    const app = express();
    app.use(express.json());

    app.get('/health', (req, res) => {
      res.json({ status: 'ok' });
    });

    app.listen(3000, () => console.log('Server running on port 3000'));

Start the server and verify it works:

    node server.js
    curl http://localhost:3000/health
    # Expected: {"status":"ok"}

## Step 3: Add your first endpoint
...

## What you have built
You now have a working REST API with CRUD operations and a PostgreSQL
database. Next steps:
- [How to add authentication](../how-to/add-auth.md)
- [API Reference](../reference/api.md)
```

### How-To Guide Structure

```markdown
# How to add rate limiting to your Express API

## Problem
Your API is vulnerable to abuse. You need to limit requests per client.

## Solution

### 1. Install the dependency

    npm install express-rate-limit

### 2. Configure the middleware

    import rateLimit from 'express-rate-limit';

    const limiter = rateLimit({
      windowMs: 15 * 60 * 1000,  // 15 minutes
      max: 100,                   // 100 requests per window
      standardHeaders: true,
      legacyHeaders: false,
    });

    app.use('/api/', limiter);

### 3. Test it

    for i in $(seq 1 105); do curl -s -o /dev/null -w "%{http_code}\n" http://localhost:3000/api/data; done
    # First 100 return 200, remaining return 429

## See also
- [Reference: express-rate-limit options](../reference/rate-limiter.md)
- [Explanation: How token bucket algorithms work](../explanation/rate-limiting.md)
```

### Reference Structure

```markdown
# CLI Reference: deploy

Deploy the application to the specified environment.

## Usage

    my-cli deploy [options] <environment>

## Arguments

| Argument | Required | Description |
|---|---|---|
| `environment` | Yes | Target environment: `staging` or `production` |

## Options

| Flag | Default | Description |
|---|---|---|
| `--dry-run` | `false` | Preview changes without applying |
| `--timeout` | `300` | Deployment timeout in seconds |
| `--force` | `false` | Skip the confirmation prompt |
| `--region` | `us-east-1` | Target deployment region |

## Examples

    my-cli deploy staging
    my-cli deploy production --dry-run
    my-cli deploy production --timeout 600 --region eu-west-1

## Exit Codes

| Code | Meaning |
|---|---|
| `0` | Deployment succeeded |
| `1` | Deployment failed |
| `2` | Invalid arguments |
| `3` | Timeout exceeded |
```

### Explanation Structure

```markdown
# Why we chose event sourcing for the order system

## Context
The order system processes financial transactions and must provide a
complete audit trail. Regulators require the ability to reconstruct
the exact state of any order at any point in time.

## How event sourcing works
Instead of storing the current state of an order, we store every event
that changed the order: OrderCreated, ItemAdded, PaymentProcessed,
OrderShipped. The current state is derived by replaying events.

## Trade-offs
- Pro: Complete audit trail for free
- Pro: Time-travel debugging (replay to any point)
- Con: Read model complexity (need projections)
- Con: Event schema evolution requires careful versioning

## Why not CRUD?
A traditional CRUD approach would overwrite previous states. We would
need a separate audit table maintained in sync — error-prone and
missing the "why" behind each change.

## Further reading
- [Tutorial: Build an event-sourced order system](../tutorials/event-sourcing.md)
- [How to add a new event type](../how-to/add-event-type.md)
```

---

## README Structure

The README is your project's landing page. A developer should understand
what this project does, why they would use it, and how to get started in
under 60 seconds.

### README Decision Tree

```
What kind of project?
├─ Library / Package
│  ├─ Must have: install, quick start, API reference, examples
│  └─ Nice to have: badges, comparison table, migration guide
├─ Application / Service
│  ├─ Must have: what it does, quick start, local dev setup, architecture
│  └─ Nice to have: deployment guide, env vars, API docs link
├─ Internal Tool
│  ├─ Must have: what problem it solves, who uses it, how to run it
│  └─ Nice to have: troubleshooting FAQ, who to contact
└─ Monorepo
   ├─ Must have: repo structure, package list, how to contribute
   └─ Nice to have: dependency graph, workspace commands
```

### Complete README Template

```markdown
# Project Name

> One-line description of what this project does and who it is for.

[![CI](https://github.com/org/repo/actions/workflows/ci.yml/badge.svg)](https://github.com/org/repo/actions)
[![npm version](https://img.shields.io/npm/v/package-name.svg)](https://www.npmjs.com/package/package-name)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)

## Features

- **Feature one** — brief description of the value it provides
- **Feature two** — brief description of the value it provides
- **Feature three** — brief description of the value it provides

## Quick Start

Get up and running in under 2 minutes:

    npm install package-name

    import { Client } from 'package-name';

    const client = new Client({ apiKey: process.env.API_KEY });
    const result = await client.query({ input: 'hello' });
    console.log(result);
    // => { output: 'Hello, world!' }

## Installation

    npm install package-name
    # or
    pnpm add package-name
    # or
    yarn add package-name

### Prerequisites

- Node.js >= 20
- PostgreSQL >= 15 (for local development)

## Usage

### Basic Example

    import { createClient } from 'package-name';

    const client = createClient({
      host: 'localhost',
      port: 5432,
    });

    const users = await client.users.list({ limit: 10 });

### Advanced: Custom Configuration

    const client = createClient({
      host: 'localhost',
      retry: { attempts: 3, delay: 1000 },
      logging: { level: 'debug' },
    });

## API

### `createClient(options)`

Create a new client instance.

| Parameter | Type | Default | Description |
|---|---|---|---|
| `host` | `string` | required | Server hostname |
| `port` | `number` | `5432` | Server port |
| `retry.attempts` | `number` | `3` | Max retry attempts |
| `retry.delay` | `number` | `1000` | Delay between retries (ms) |

**Returns:** `Client`

**Throws:** `ConnectionError` if the server is unreachable.

## Configuration

| Variable | Default | Required | Description |
|---|---|---|---|
| `DB_HOST` | `localhost` | No | Database hostname |
| `DB_PORT` | `5432` | No | Database port |
| `API_KEY` | — | Yes | Your API key |
| `LOG_LEVEL` | `info` | No | Logging: debug, info, warn, error |

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for development setup and guidelines.

## License

[MIT](./LICENSE)
```

### README Rules

```
1. Quick start must work on copy-paste — test on a fresh machine
2. No walls of text — use headings, bullets, tables, code blocks
3. Show, don't tell — code examples over paragraphs of explanation
4. Keep it current — outdated README is worse than no README
5. Link to details — README is an entry point, not a book
```

---

## API Documentation

### OpenAPI 3.1 Specification Pattern

```yaml
openapi: 3.1.0
info:
  title: User Service API
  version: 1.0.0
  description: |
    Manages user accounts, authentication, and profiles.

    ## Authentication
    All endpoints require a Bearer token in the `Authorization` header
    unless marked as public.

    ## Rate Limits
    - Authenticated: 1000 requests/minute
    - Public: 100 requests/minute

    ## Errors
    All errors follow RFC 7807 (Problem Details for HTTP APIs).
  contact:
    name: Platform Team
    email: platform@example.com
  license:
    name: MIT

servers:
  - url: https://api.example.com/v1
    description: Production
  - url: https://api.staging.example.com/v1
    description: Staging

paths:
  /users:
    get:
      operationId: listUsers
      summary: List users
      description: |
        Returns a paginated list of users sorted by created_at descending.
      tags: [Users]
      parameters:
        - name: limit
          in: query
          schema:
            type: integer
            minimum: 1
            maximum: 100
            default: 20
          description: Number of results per page
        - name: cursor
          in: query
          schema:
            type: string
          description: Pagination cursor from previous response
      responses:
        '200':
          description: Paginated list of users
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/UserList'
              example:
                users:
                  - id: "usr_01H8ZMKR..."
                    email: "alice@example.com"
                    name: "Alice Smith"
                    created_at: "2025-01-15T09:30:00Z"
                next_cursor: "eyJpZCI6..."
                has_more: true
        '401':
          $ref: '#/components/responses/Unauthorized'

    post:
      operationId: createUser
      summary: Create a user
      tags: [Users]
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateUserInput'
            example:
              email: "alice@example.com"
              name: "Alice Smith"
      responses:
        '201':
          description: User created successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
        '409':
          description: Email already exists
        '422':
          $ref: '#/components/responses/ValidationError'

components:
  schemas:
    User:
      type: object
      required: [id, email, name, created_at]
      properties:
        id:
          type: string
          example: "usr_01H8ZMKR..."
        email:
          type: string
          format: email
        name:
          type: string
          minLength: 1
          maxLength: 200
        created_at:
          type: string
          format: date-time

    CreateUserInput:
      type: object
      required: [email, name]
      properties:
        email:
          type: string
          format: email
        name:
          type: string
          minLength: 1
          maxLength: 200

    UserList:
      type: object
      properties:
        users:
          type: array
          items:
            $ref: '#/components/schemas/User'
        next_cursor:
          type: string
          nullable: true
        has_more:
          type: boolean

    ProblemDetail:
      type: object
      description: RFC 7807 error response
      properties:
        type:
          type: string
        title:
          type: string
        status:
          type: integer
        detail:
          type: string

  responses:
    Unauthorized:
      description: Missing or invalid authentication token
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ProblemDetail'
    ValidationError:
      description: Request body failed validation
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ProblemDetail'

  securitySchemes:
    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT

security:
  - BearerAuth: []
```

### Endpoint Documentation Checklist

Every endpoint should document:

```
1. METHOD + PATH + one-line summary
2. Description (when to use, business context)
3. Authentication requirements
4. Request: path params, query params, headers, body + examples
5. Response: success schema + example, error schemas + examples
6. Rate limiting behavior for this endpoint
7. Code examples in 2+ languages (for public APIs)
```

### Authentication Section Template

```markdown
## Authentication

All API requests require a Bearer token in the `Authorization` header.

### Get your API key

1. Log in to the [dashboard](https://app.example.com)
2. Go to **Settings** > **API Keys**
3. Click **Create API Key** and copy the key

### Use your API key

Include the key in every request:

    curl https://api.example.com/v1/users \
      -H "Authorization: Bearer YOUR_API_KEY"

### Rate limits

| Plan | Requests/min | Requests/day |
|---|---|---|
| Free | 60 | 1,000 |
| Pro | 600 | 50,000 |
| Enterprise | 6,000 | Unlimited |

Rate limit headers are included in every response:

    X-RateLimit-Limit: 60
    X-RateLimit-Remaining: 45
    X-RateLimit-Reset: 1697371200
```

### Multi-Language Code Examples

Always provide examples in at least two languages for public APIs:

```markdown
### Create a user

**cURL**

    curl -X POST https://api.example.com/v1/users \
      -H "Authorization: Bearer $API_KEY" \
      -H "Content-Type: application/json" \
      -d '{"email": "alice@example.com", "name": "Alice Smith"}'

**TypeScript (fetch)**

    const response = await fetch('https://api.example.com/v1/users', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        email: 'alice@example.com',
        name: 'Alice Smith',
      }),
    });
    const user = await response.json();

**Python (requests)**

    import requests

    response = requests.post(
        'https://api.example.com/v1/users',
        headers={'Authorization': f'Bearer {api_key}'},
        json={'email': 'alice@example.com', 'name': 'Alice Smith'},
    )
    user = response.json()
```

### API Doc Rendering Tools

```
Which rendering tool?
├─ Redoc
│  ├─ Best for: public-facing API docs, clean reading experience
│  ├─ Strengths: three-panel layout, Markdown in descriptions, SEO-friendly
│  └─ Setup: npx @redocly/cli build-docs openapi.yaml
├─ Swagger UI
│  ├─ Best for: internal APIs, interactive "try it out" testing
│  ├─ Strengths: built-in request executor, wide adoption
│  └─ Setup: docker run -p 8080:8080 -e SWAGGER_JSON=/api/openapi.yaml swaggerapi/swagger-ui
├─ Scalar
│  ├─ Best for: modern developer experience, beautiful defaults
│  ├─ Strengths: fast, dark mode, built-in auth testing, OpenAPI 3.1 native
│  └─ Setup: npx @scalar/cli serve openapi.yaml
└─ Stoplight Elements
   ├─ Best for: embedding in existing documentation sites
   ├─ Strengths: React component, customizable, design-first workflow
   └─ Setup: npm install @stoplight/elements
```

### API Doc Strategy Decision Tree

```
How to manage API docs?
├─ Spec-first (recommended for public APIs)
│  └─ Write OpenAPI spec first → generate docs, SDKs, validation
│  └─ Tools: Redocly, Scalar, Swagger UI
├─ Code-first (acceptable for internal APIs)
│  └─ Write code with annotations → generate spec → render docs
│  └─ Tools: tsoa (Express), NestJS Swagger, FastAPI (Python)
└─ Hybrid
   └─ Write spec for contract, generate routes + validation from it
   └─ Tools: openapi-typescript, zodios
```

---

## Code Documentation (JSDoc / TSDoc)

### Decision Tree: When to Document Code

```
Should I add a doc comment?
├─ Exported function / class / type?
│  ├─ Public API (consumed by other packages)? → YES, always document
│  ├─ Internal but complex logic? → YES, explain the WHY and approach
│  └─ Internal and self-explanatory? → SKIP, good names suffice
├─ Private function?
│  ├─ Non-obvious algorithm or business rule? → YES, explain WHY
│  └─ Simple helper (< 10 lines, clear name)? → SKIP
├─ Type / Interface?
│  ├─ Has non-obvious fields? → YES, document each field
│  └─ All fields are self-explanatory? → SKIP
└─ Constant / Config?
   ├─ Magic number or business rule? → YES, explain the value
   └─ Standard value (port 3000, timeout 30s)? → SKIP
```

### JSDoc Examples (JavaScript)

```javascript
/**
 * Calculate the shipping cost based on weight and destination zone.
 *
 * Uses tiered pricing: orders over 5kg get a 15% bulk discount.
 * International zones (3+) include a flat customs processing fee.
 *
 * @param {number} weightKg - Package weight in kilograms. Must be > 0.
 * @param {number} zone - Shipping zone (1-5). Higher zones = farther.
 * @returns {number} Total shipping cost in cents (USD).
 * @throws {RangeError} If weight is <= 0 or zone is not 1-5.
 *
 * @example
 * // Domestic lightweight package
 * calculateShipping(2.5, 1); // => 750
 *
 * @example
 * // International heavy package (bulk discount applied)
 * calculateShipping(8.0, 4); // => 3400
 */
function calculateShipping(weightKg, zone) {
  // ...
}

/**
 * Format a date for display in the user's locale.
 *
 * Falls back to ISO 8601 if Intl.DateTimeFormat is unavailable
 * (SSR without full-icu).
 *
 * @param {Date} date - The date to format.
 * @param {string} [locale='en-US'] - BCP 47 language tag.
 * @returns {string} The formatted date string.
 *
 * @example
 * formatDate(new Date('2025-03-15'), 'en-US'); // => "March 15, 2025"
 * formatDate(new Date('2025-03-15'), 'de-DE'); // => "15. Marz 2025"
 */
function formatDate(date, locale = 'en-US') {
  // ...
}
```

### TSDoc Examples (TypeScript)

```typescript
/**
 * Retry a function with exponential backoff and jitter.
 *
 * Each retry waits `baseDelay * 2^attempt` milliseconds, capped at
 * `maxDelay`. Random jitter of +/- 25% prevents thundering herd.
 *
 * @param fn - The async function to retry. Called with no arguments.
 * @param options - Retry configuration.
 * @returns The resolved value of `fn` on success.
 * @throws The last error if all retries are exhausted.
 *
 * @example
 * ```typescript
 * const data = await retry(
 *   () => fetch('https://api.example.com/data').then(r => r.json()),
 *   { attempts: 3, baseDelay: 1000 },
 * );
 * ```
 */
export async function retry<T>(
  fn: () => Promise<T>,
  options: RetryOptions = {},
): Promise<T> {
  // ...
}

/**
 * Configuration for the retry function.
 */
export interface RetryOptions {
  /** Maximum number of attempts (including the first call). @defaultValue 3 */
  attempts?: number;
  /** Base delay in milliseconds before the first retry. @defaultValue 1000 */
  baseDelay?: number;
  /** Maximum delay cap in milliseconds. @defaultValue 30000 */
  maxDelay?: number;
  /** If provided, only retry when this returns `true` for the error. */
  retryIf?: (error: unknown) => boolean;
}

/**
 * Represents a paginated API response.
 *
 * @typeParam T - The type of items in the response.
 */
export interface PaginatedResponse<T> {
  /** The items for the current page. */
  data: T[];
  /** Total number of items across all pages. */
  total: number;
  /** Cursor for the next page. `null` if this is the last page. */
  nextCursor: string | null;
  /** Whether more pages exist after this one. */
  hasMore: boolean;
}
```

### Python Docstring Examples

```python
def calculate_shipping(
    weight_kg: float,
    destination: str,
    speed: str = "standard",
) -> int:
    """Calculate shipping cost for an order.

    Uses tiered pricing with an international multiplier.
    Returns cost in cents (USD).

    Args:
        weight_kg: Package weight in kilograms (max 30).
        destination: ISO 3166-1 alpha-2 country code.
        speed: Shipping speed, either "standard" or "express".

    Returns:
        Shipping cost in cents (USD).

    Raises:
        ValueError: If weight exceeds the 30kg carrier limit.
        ValueError: If destination is not a valid country code.

    Example:
        >>> calculate_shipping(3.0, "US")
        599
        >>> calculate_shipping(10.0, "DE", speed="express")
        4250
    """
```

### TypeDoc Configuration

```json
{
  "entryPoints": ["src/index.ts"],
  "out": "docs/api",
  "plugin": ["typedoc-plugin-markdown"],
  "excludePrivate": true,
  "excludeInternal": true,
  "readme": "none",
  "categorizeByGroup": true,
  "categoryOrder": ["Client", "Configuration", "Models", "Errors", "*"],
  "navigation": {
    "includeCategories": true,
    "includeGroups": true
  }
}
```

```bash
# Generate API docs
npx typedoc --options typedoc.json

# Watch mode for development
npx typedoc --options typedoc.json --watch

# Validate that all public exports are documented
npx typedoc --options typedoc.json --requiredToBeDocumented class,function,interface,type
```

---

## Code Comments

### The Golden Rule: WHY, Not WHAT

```typescript
// BAD: restates the code (WHAT)
// Increment counter by 1
counter += 1;

// BAD: describes the HOW
// Loop through users and filter active ones
const active = users.filter(u => u.isActive);

// GOOD: explains the WHY (business context)
// Offset by 1 because the external API uses 1-based page indexing
counter += 1;

// GOOD: explains the WHY (policy)
// Active users only — inactive accounts are retained for 90 days
// per GDPR data retention policy, then hard-deleted by a cron job
const active = users.filter(u => u.isActive);
```

### TODO / FIXME / HACK Format

Always include a ticket reference and author. TODOs without tickets are
wishes, not plans.

```typescript
// TODO(alice, #1234): Replace with batch API once v2 endpoint ships (Q2 2026)
// Current implementation makes N+1 calls — acceptable for < 100 items
for (const item of items) {
  await processItem(item);
}

// FIXME(bob, #5678): Race condition when two requests update the same order
// Reproduce: concurrent POST /orders/123/items from two tabs
// Workaround: advisory lock added, proper fix needs optimistic locking
await updateOrder(orderId, items);

// HACK(carol, #9012): Safari miscalculates grid height with dynamic content
// Remove after Safari 20+ reaches 95% adoption (track at caniuse.com)
element.style.minHeight = `${calculatedHeight + 1}px`;
```

### Inline Documentation Patterns

```typescript
// Explain regex patterns (always — regex is write-only code)
// Match semantic version: major.minor.patch with optional pre-release
// Examples: "1.0.0", "2.3.1-beta.1", "0.1.0-rc.2"
const SEMVER_REGEX = /^(\d+)\.(\d+)\.(\d+)(?:-([a-zA-Z0-9.]+))?$/;

// Warn about non-obvious behavior
// WARNING: This mutates the input array. Clone before calling if needed.
function sortInPlace(items: Item[]): Item[] { /* ... */ }

// Cite external sources for algorithms
// Algorithm: Fisher-Yates shuffle
// https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle
function shuffle<T>(array: T[]): T[] { /* ... */ }

// Performance note — explains non-obvious optimization
// Using a Map instead of Array.find() because this runs in a hot loop.
// O(1) lookup vs O(n) matters at 10k+ items.
const userMap = new Map(users.map(u => [u.id, u]));

// Legal header (when required by license or organization)
// Copyright 2025 Example Corp. All rights reserved.
// SPDX-License-Identifier: MIT
```

### Comments to Avoid

```
Six types of comments that add noise, not value:

1. Obvious comments
   // Get the user        ← the function is called getUser()
   // Return the result   ← "return result" is self-evident

2. Journal comments
   // 2024-01-15: Added validation (alice)  ← use git log

3. Closing brace comments
   } // end if            ← extract to a function if nesting is deep
   } // end for

4. Commented-out code
   // const oldValue = calculate(x);  ← delete it, git remembers
   // if (featureFlag) { ... }        ← delete it, git remembers

5. Divider comments
   /////////////////////////////////  ← use functions/modules instead
   // *** SECTION THREE ***
   /////////////////////////////////

6. Redundant JSDoc
   /** The name. */
   name: string;  ← the type and name are self-documenting
```

---

## Architecture Decision Records (ADRs)

### When to Write an ADR

```
Write an ADR when:
├─ Choosing a technology (database, framework, language, cloud service)
├─ Changing architecture (monolith → microservices, REST → GraphQL)
├─ Establishing a pattern (error handling, auth, logging, testing)
├─ Making a trade-off (consistency vs availability, build vs buy)
├─ Constraining future decisions (API versioning, data format, protocol)
└─ The decision is hard to reverse or affects multiple teams

Do NOT write an ADR for:
├─ Trivial choices (tabs vs spaces — use a formatter)
├─ Temporary decisions (which bug to fix first)
└─ Easily reversible decisions (variable naming, file structure)
```

### MADR Template (Markdown Any Decision Record)

```markdown
# ADR-0001: Use PostgreSQL as primary database

## Status

Accepted (2025-03-15)

<!-- Status lifecycle: Proposed → Accepted → Deprecated → Superseded by ADR-XXXX -->

## Context

We need a primary database for the order management system. The system
requires ACID transactions, complex queries across related entities,
and must handle approximately 10,000 writes per second at peak.

Current team has strong SQL experience. No existing database
infrastructure to maintain compatibility with.

## Decision Drivers

- ACID compliance for financial transactions
- Query flexibility for reporting and analytics
- Operational maturity and ecosystem tooling
- Team expertise and hiring pool
- Cost at projected scale (500GB data, 10K writes/sec)

## Considered Options

### Option 1: PostgreSQL
- Pros: ACID, JSON support, mature ecosystem, team expertise, free
- Cons: Horizontal scaling requires careful planning (partitioning, replicas)

### Option 2: MySQL 8
- Pros: ACID, wide adoption, managed options everywhere
- Cons: Weaker JSON support, less expressive query language

### Option 3: MongoDB
- Pros: Flexible schema, horizontal scaling, JSON-native
- Cons: Weaker consistency guarantees, no joins, team lacks experience

## Decision

Use PostgreSQL 16 with:
- Primary + 2 read replicas for read scaling
- Connection pooling via PgBouncer
- TimescaleDB extension for time-series analytics (if needed later)

## Consequences

### Positive
- Team can start immediately (existing expertise)
- Strong tooling: pgAdmin, pg_dump, logical replication
- JSONB columns for semi-structured data without a second database

### Negative
- Must plan partitioning strategy before tables exceed 100M rows
- Write scaling limited to vertical or application-level sharding
- Must invest in connection pooling from day one

### Risks
- If write volume exceeds 50K/sec, may need to shard — evaluate at 30K/sec

## Related

- ADR-0002: Connection pooling strategy
- ADR-0005: Data partitioning approach
```

### ADR Status Lifecycle

```
Proposed
├─ Team reviews and discusses
├─ Accepted ← Decision is active and should be followed
│  ├─ Deprecated ← Decision no longer recommended but not replaced
│  └─ Superseded by ADR-XXXX ← A newer decision replaces this one
└─ Rejected ← Decision was considered but not adopted (keep for context)
```

### ADR File Organization

```
docs/
└── adr/
    ├── README.md              ← Index of all ADRs with status
    ├── 0001-use-postgresql.md
    ├── 0002-connection-pooling.md
    ├── 0003-api-versioning.md
    ├── 0004-auth-with-jwt.md
    └── template.md            ← Copy this for new ADRs
```

### ADR Index Template

```markdown
# Architecture Decision Records

| ADR | Title | Status | Date |
|-----|-------|--------|------|
| [0001](./0001-use-postgresql.md) | Use PostgreSQL as primary database | Accepted | 2025-03-15 |
| [0002](./0002-connection-pooling.md) | Connection pooling with PgBouncer | Accepted | 2025-03-20 |
| [0003](./0003-api-versioning.md) | URL-based API versioning | Accepted | 2025-04-01 |
| [0004](./0004-auth-with-jwt.md) | JWT-based authentication | Superseded by 0008 | 2025-04-10 |
```

---

## Changelogs

### Keep a Changelog Format

Follow https://keepachangelog.com. The audience is users of the software,
not the development team.

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- Support for cursor-based pagination on all list endpoints

## [2.1.0] - 2025-06-15

### Added
- `--dry-run` flag on the `deploy` command
- Webhook support for order status changes

### Changed
- Default timeout increased from 30s to 60s for large file uploads
- Error responses now follow RFC 7807 (Problem Details) format

### Deprecated
- `/v1/users/search` endpoint — use query parameters on `/v1/users` instead

### Fixed
- Connection pool exhaustion under concurrent batch imports
- Race condition in order status transitions

### Security
- Upgraded `jsonwebtoken` to 9.0.2 (CVE-2024-XXXXX)

## [2.0.0] - 2025-03-01

### Removed
- `/v1/legacy-auth` endpoint (deprecated since 1.8.0)

### Changed
- **BREAKING**: Authentication switched from API keys to OAuth 2.0
- **BREAKING**: All timestamps now use ISO 8601 format (was Unix epoch)

[Unreleased]: https://github.com/org/repo/compare/v2.1.0...HEAD
[2.1.0]: https://github.com/org/repo/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/org/repo/releases/tag/v2.0.0
```

### Changelog Categories

```
Use exactly these categories, in this order:
├─ Added      → New features, new endpoints, new capabilities
├─ Changed    → Changes to existing functionality
├─ Deprecated → Features that will be removed in a future release
├─ Removed    → Features removed in this release
├─ Fixed      → Bug fixes
└─ Security   → Vulnerability fixes (always note the CVE)
```

### Changelog Category to Semver Mapping

| Category | Semver Bump | Example |
|---|---|---|
| **Added** | Minor | New endpoint, new CLI flag |
| **Changed** | Minor (or Major if breaking) | Behavior change, dependency upgrade |
| **Deprecated** | Minor | Feature marked for removal |
| **Removed** | Major | Feature or endpoint removed |
| **Fixed** | Patch | Bug fix, typo correction |
| **Security** | Patch | Vulnerability fix |

### Auto-Generation from Conventional Commits

```bash
# Using conventional-changelog
npx conventional-changelog -p conventionalcommits -i CHANGELOG.md -s

# Using changesets (monorepo-friendly)
npx changeset              # Create a changeset during development
npx changeset version      # Bump versions and update changelogs
npx changeset publish      # Publish to npm
```

```yaml
# .github/workflows/release.yml — auto release PR via release-please
name: Release
on:
  push:
    branches: [main]

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: googleapis/release-please-action@v4
        with:
          release-type: node
```

### Writing Good Changelog Entries

```
BAD:  "Fixed bug"                        → Which bug? What impact?
BAD:  "Updated dependencies"             → Which ones? Why?
BAD:  "Refactored user module"           → Users don't care about internals
BAD:  "PR #247"                          → Not a description

GOOD: "Fixed connection pool exhaustion under concurrent batch imports"
GOOD: "Upgraded jsonwebtoken to 9.0.2 (CVE-2024-XXXXX)"
GOOD: "Added --dry-run flag on the deploy command"
GOOD: "BREAKING: Authentication switched from API keys to OAuth 2.0"
```

---

## Runbooks

### Severity Classification Decision Tree

```
What is the impact?
├─ P0 — Complete outage
│  ├─ All users affected, no workaround
│  ├─ Data loss or corruption occurring
│  └─ Security breach in progress
│  → Response: All hands. War room. 15-min status updates.
├─ P1 — Major degradation
│  ├─ Core functionality impaired (auth, checkout, data access)
│  ├─ > 25% of users affected
│  └─ Workaround exists but is painful
│  → Response: On-call + backup. 30-min status updates.
├─ P2 — Minor degradation
│  ├─ Non-core feature broken (search, reports, notifications)
│  ├─ < 25% of users affected
│  └─ Easy workaround available
│  → Response: On-call investigates. Fix within business hours.
└─ P3 — Cosmetic / low impact
   ├─ UI glitch, minor text error
   ├─ Performance slightly degraded but within SLA
   └─ Single user or edge case affected
   → Response: Ticket created. Fix in next sprint.
```

### Incident Response Runbook Template

```markdown
# Runbook: Database Connection Pool Exhaustion

## Severity: P1 (Service Degradation)

## Trigger
Alert: `db_pool_available_connections < 5` for 2+ minutes
Dashboard: https://grafana.internal/d/db-pool

## Symptoms
- API response times exceed 2s at p99
- 503 errors increasing on `/health` endpoint
- Application logs: "connection pool exhausted, waiting for available connection"

## Impact
- Users experience timeouts on all write operations
- Read operations degraded (some succeed via read replicas)
- Estimated: 30% of requests failing

## Diagnosis

### Step 1: Confirm the alert

    kubectl exec -it deploy/api -- curl localhost:3000/health
    # Check: "database" status in health response

### Step 2: Check active connections

    psql -h db-primary -U monitor -c "
      SELECT state, count(*)
      FROM pg_stat_activity
      WHERE datname = 'appdb'
      GROUP BY state;
    "
    # Healthy: idle < 80, active < 20
    # Problem: active > 50 or idle_in_transaction > 10

### Step 3: Identify long-running queries

    psql -h db-primary -U monitor -c "
      SELECT pid, now() - query_start AS duration, query, state
      FROM pg_stat_activity
      WHERE (now() - query_start) > interval '30 seconds'
      ORDER BY duration DESC;
    "

### Step 4: Check for lock contention

    psql -h db-primary -U monitor -c "
      SELECT blocked.pid AS blocked_pid,
             blocking.pid AS blocking_pid,
             blocked_activity.query AS blocked_query
      FROM pg_catalog.pg_locks blocked
      JOIN pg_catalog.pg_stat_activity blocked_activity
        ON blocked_activity.pid = blocked.pid
      JOIN pg_catalog.pg_locks blocking
        ON blocking.locktype = blocked.locktype
      WHERE NOT blocked.granted;
    "

## Resolution

### Option A: Kill long-running queries (least disruptive)

    psql -h db-primary -U admin -c "
      SELECT pg_terminate_backend(pid)
      FROM pg_stat_activity
      WHERE (now() - query_start) > interval '5 minutes'
        AND state = 'active';
    "

### Option B: Restart application pods (moderate disruption)

    kubectl rollout restart deploy/api
    # Drains connections and re-establishes the pool

### Option C: Increase pool size temporarily

    # Update DATABASE_POOL_SIZE env var from 20 to 40
    kubectl set env deploy/api DATABASE_POOL_SIZE=40
    # WARNING: Ensure total connections across all pods < max_connections (100)

## Post-Incident
- [ ] Identify the root cause query or code path
- [ ] Add query timeout: `statement_timeout = '30s'` on the application role
- [ ] Review connection pool settings (min, max, idle timeout)
- [ ] Add slow query logging: `log_min_duration_statement = 1000`
- [ ] Update this runbook with findings

## Escalation

| Level | Who | When |
|---|---|---|
| L1 | On-call engineer | Alert fires |
| L2 | Database team (`#db-ops` Slack) | Pool > 90% for 5+ minutes |
| L3 | VP Engineering | Full outage > 15 minutes |

## Related
- [Runbook: Database failover](./db-failover.md)
- [ADR-0002: Connection pooling strategy](../adr/0002-connection-pooling.md)
```

### Runbook Rules

```
1. No "ask Dave" steps — Dave is on vacation. Every step is self-contained
2. Copy-paste commands — the person running this is stressed at 2 AM
3. Include dashboard/log links — don't make them search
4. Decision tree for diagnosis — help them diagnose before they act
5. Update after every incident — the runbook is a living document
```

### Runbook Organization

```
docs/
└── runbooks/
    ├── README.md                    ← Index with severity tags
    ├── alerts/
    │   ├── db-pool-exhaustion.md
    │   ├── high-error-rate.md
    │   ├── disk-space-low.md
    │   └── certificate-expiring.md
    ├── procedures/
    │   ├── db-failover.md
    │   ├── rollback-deployment.md
    │   ├── rotate-secrets.md
    │   └── scale-up-pods.md
    └── postmortems/
        ├── 2025-01-15-checkout-outage.md
        └── 2025-03-02-db-migration-failure.md
```

---

## Onboarding Documentation

### Developer Getting Started Template

```markdown
# Developer Onboarding Guide

Welcome to the team. This guide gets you from zero to a running local
environment in under 30 minutes.

## Day 1: Environment Setup

### Prerequisites
- macOS 14+ / Ubuntu 22.04+ / WSL2
- Git configured with SSH keys
- Access granted to: GitHub org, Slack workspace, 1Password vault

### Step 1: Clone and install

    git clone git@github.com:org/repo.git
    cd repo
    cp .env.example .env.local
    # Fill in values from 1Password > "Dev Environment" vault

### Step 2: Start services

    docker compose up -d       # PostgreSQL, Redis, Mailhog
    npm install
    npm run db:migrate
    npm run db:seed            # Creates test data + test user
    npm run dev                # http://localhost:3000

### Step 3: Verify everything works

    npm run test               # All tests should pass
    npm run typecheck          # No type errors
    curl http://localhost:3000/health  # {"status":"ok"}

### Troubleshooting

| Problem | Solution |
|---|---|
| Port 3000 in use | `lsof -i :3000` then kill the process |
| Database connection refused | `docker compose up -d postgres` and wait 10s |
| Missing env vars | Compare `.env.local` with `.env.example` |
| Node version mismatch | `nvm use` (reads `.nvmrc` in repo root) |

## Day 2: Architecture Overview

### System Diagram

    [Browser] → [Next.js App] → [API Routes] → [PostgreSQL]
                                     ↓
                                [Redis Cache]
                                     ↓
                             [Background Jobs]

### Key Directories

    src/
    ├── app/           → Next.js pages and layouts (App Router)
    ├── components/    → Shared React components
    ├── lib/           → Business logic, database queries, utilities
    ├── jobs/          → Background job processors
    └── tests/         → Test files (mirrors src/ structure)

### Key Workflows

| Task | Command | Notes |
|---|---|---|
| Run dev server | `npm run dev` | Hot reload enabled |
| Run tests | `npm run test` | Uses Vitest |
| Run single test file | `npm run test -- path/to/file` | |
| Create DB migration | `npm run db:create-migration name` | Creates up + down SQL |
| Lint + format | `npm run lint && npm run format` | Runs on pre-commit hook |
| Build for production | `npm run build` | Output in `.next/` |

## Day 3: Make Your First Change

1. Pick a "good first issue" from the issue board
2. Create a branch: `git checkout -b feat/issue-123-short-description`
3. Make changes, write tests
4. Run: `npm run lint && npm run test && npm run typecheck`
5. Push and open a PR. Link the issue in the PR description
6. Request review from your onboarding buddy

## Domain Glossary

| Term | Definition |
|---|---|
| **Workspace** | A tenant in the multi-tenant system. All data is scoped to a workspace |
| **Member** | A user within a workspace with a role (owner, admin, member) |
| **Pipeline** | A sequence of stages that an entity moves through |
| **Webhook** | An HTTP callback triggered by an event (order.created, user.updated) |

## Who to Ask

| Topic | Person / Channel |
|---|---|
| Architecture decisions | `#architecture` Slack channel |
| Database questions | `#db-ops` Slack channel |
| Deployment / CI issues | `#devops` Slack channel |
| Code review conventions | Your onboarding buddy |
| Access / permissions | IT team via Jira service desk |
```

### Onboarding Rules

```
1. Must work on first try — test the guide on a new machine monthly
2. 30-minute setup target — if it takes longer, automate more
3. Include "verify it works" checkpoints — confidence builders
4. Glossary for domain terms — don't assume everyone knows your jargon
5. Link, don't duplicate — reference other docs instead of copying
```

---

## Writing Style Guide

### Voice and Tone

| Rule | Do | Do Not |
|---|---|---|
| **Active voice** | "Run the command" | "The command should be run" |
| **Present tense** | "This function returns a list" | "This function will return a list" |
| **Second person** | "You can configure the timeout" | "One can configure the timeout" |
| **Direct** | "Set `API_KEY` in your environment" | "It is necessary to set the `API_KEY`" |
| **Positive** | "Use HTTPS for all requests" | "Do not use HTTP for requests" |

### Sentence Structure

```
Rules for clear technical writing:
├─ Short sentences: 25 words max, aim for 15-20
├─ One idea per sentence
├─ One idea per paragraph
├─ Lead with the action: "Install Node.js" not "First, you need to install..."
├─ Use lists for 3+ related items — don't bury them in prose
├─ Headings as tasks: "Install dependencies" not "Dependencies"
└─ Code examples before explanation — show first, explain second
```

### Words to Avoid

```
├─ "Simply" / "Just" / "Easy" → Dismissive. If it were easy, they wouldn't need docs
├─ "Obviously" / "Clearly"   → If it were obvious, they wouldn't be reading this
├─ "Please note that"        → Delete it. State the fact directly
├─ "In order to"             → Replace with "to"
├─ "Utilize"                 → Replace with "use"
├─ "Leverage"                → Replace with "use"
├─ "Robust" / "Powerful"     → Meaningless. Describe the specific quality
├─ "Seamless"                → Everything has seams. Describe what happens
├─ "It should be noted"      → Delete it. Just state the note
└─ "As previously mentioned" → Link to the section instead
```

### Word Choice Quick Reference

| Instead of | Use |
|---|---|
| utilize | use |
| in order to | to |
| at this point in time | now |
| a number of | several |
| in the event that | if |
| prior to | before |
| subsequent to | after |
| functionality | feature |
| leverage | use |
| facilitate | help or enable |
| terminate | stop or end |
| initiate | start |

### Formatting Conventions

```
Code elements:
- Inline code for: commands, file paths, config keys, function names, flags
  Example: Run `npm install` to install dependencies.
  Example: Set `LOG_LEVEL` to `debug` in `.env.local`.

- Code blocks for: multi-line code, terminal output, file contents
  Always specify the language for syntax highlighting.

Structure:
- Numbered lists for sequential steps (do this, then this)
- Bulleted lists for unordered items (features, options)
- Tables for structured data (flags + defaults, env vars, glossaries)

Headings:
- H1: Document title (one per document)
- H2: Major sections
- H3: Subsections
- Never skip levels (no H2 → H4)
- Sentence case: "Configure the database" not "Configure The Database"
```

---

## Anti-Patterns

| Anti-Pattern | Why Dangerous | Fix |
|---|---|---|
| **No README** | Project is invisible. No one knows what it does | Write a README before you write code |
| **README with no quick start** | Developers bounce. Can't try it in 2 min, they leave | Add 3-command quick start at the top |
| **Outdated documentation** | Worse than no docs. Users follow wrong instructions | Docs-as-code: update docs in the same PR as code |
| **No code examples** | Prose without examples is theory, not documentation | One working example per concept minimum |
| **Commented-out code** | Visual noise, creates doubt, not documentation | Delete it. Git remembers everything |
| **"Ask Dave" runbooks** | Single point of failure. Dave is on vacation | Write every step so anyone can follow it |
| **Auto-generated docs, no curation** | Raw TypeDoc output is not documentation | Add descriptions, examples, getting started on top |
| **Docs in a wiki nobody checks** | Wiki rots faster than anything. No review, no version control | Docs-as-code in the repo, reviewed in PRs |
| **No changelog** | Users have no idea what changed between versions | Keep a Changelog format, automate from commits |
| **ADRs only for accepted decisions** | Rejected options are lost context. Future engineers re-evaluate | Record rejected options with reasoning |
| **Jargon without definition** | Excludes newcomers and cross-team readers | Define every acronym on first use, maintain glossary |
| **Mixing Diataxis doc types** | Tutorial that becomes reference confuses everyone | One type per document, link between them |
| **No onboarding guide** | Every new hire wastes a week figuring out setup | Write getting-started guide, update on each new hire |
| **Screenshots without alt text** | Inaccessible, breaks when UI changes, cannot be searched | Use text and code blocks. Add alt text to all images |
| **Docs only in Confluence/Notion** | Disconnected from code, goes stale within weeks | Critical docs (README, API, ADR) live in the repo |
| **No error documentation** | Users get cryptic errors with no guidance | Document every user-facing error with cause and fix |
| **"// increment i" comments** | Obvious comments waste reader attention | Comment WHY, never WHAT |
| **Documentation as afterthought** | "We'll document later" means never | Write docs alongside code, include in PR reviews |

---

## Review Checklist: Documentation Quality

### README

- [ ] Project name and one-line description at the top
- [ ] Quick Start section with 3 or fewer steps to a working state
- [ ] Installation instructions for all supported package managers
- [ ] Prerequisites listed (runtime versions, system dependencies)
- [ ] At least one usage example with working, copy-pasteable code
- [ ] API documentation or link to generated API docs
- [ ] Configuration / environment variables documented with defaults
- [ ] License specified
- [ ] Badges are current and links work (CI, version, license)

### API Docs

- [ ] OpenAPI spec validates without errors (`npx @redocly/cli lint openapi.yaml`)
- [ ] Every endpoint has summary and description
- [ ] Request/response examples for every endpoint
- [ ] Error responses documented with status codes and body schema
- [ ] Authentication section with step-by-step setup
- [ ] Pagination approach documented (cursor, offset, or page-based)
- [ ] Rate limits documented per plan or endpoint

### Code Comments

- [ ] Exported functions and types have doc comments (@param, @returns, @example)
- [ ] Comments explain WHY, not WHAT
- [ ] No commented-out code anywhere
- [ ] TODOs have ticket references and owners (`TODO(name, #123)`)
- [ ] Regex patterns have explanatory comments
- [ ] Magic numbers are explained or extracted to named constants
- [ ] No redundant comments that restate the code

### ADRs

- [ ] ADR exists for every significant technical decision
- [ ] Each ADR has: Status, Context, Decision, Consequences
- [ ] Considered alternatives documented with pros/cons and rejection reasoning
- [ ] Superseded ADRs link to their replacement
- [ ] ADR index (README in `/docs/adr/`) is up to date
- [ ] File naming follows convention: `NNNN-short-title.md`

### Changelogs

- [ ] Follows Keep a Changelog format (Added/Changed/Deprecated/Removed/Fixed/Security)
- [ ] Entries written from the user's perspective, not the developer's
- [ ] Breaking changes clearly marked with **BREAKING** prefix
- [ ] Security fixes reference the CVE number
- [ ] Version comparison links at the bottom are correct and current

### Runbooks

- [ ] Every production alert has a corresponding runbook
- [ ] Each runbook has: Trigger, Symptoms, Diagnosis, Resolution, Escalation
- [ ] Diagnosis steps include exact commands to run (copy-pasteable)
- [ ] Escalation path documented with names/channels and timing thresholds
- [ ] No "ask [person]" steps — all steps are self-contained
- [ ] Post-incident checklist included
- [ ] Runbook has been tested by someone who did not write it
