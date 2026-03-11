# Advanced TypeScript Features

## Table of Contents

- [Explicit Resource Management (using keyword, TS 5.2+)](#explicit-resource-management-using-keyword-ts-52)
- [Decorator Metadata (TS 5.2+)](#decorator-metadata-ts-52)
- [TS 5.6 Features](#ts-56-features)
  - [Iterator Helper Methods](#iterator-helper-methods-ts-56)
  - [Disallowed Nullish Coalescing Precedence](#disallowed-nullish-coalescing-precedence-ts-56)
  - [--noCheck Flag](#--nocheck-flag-ts-56)
- [TS 5.7+ Features](#ts-57-features)
  - [ES2024 Target/Lib](#es2024-targetlib-ts-57)
  - [--rewriteRelativeImportExtensions](#--rewriterelativeimportextensions-ts-57)
- [TS 5.8 Features](#ts-58-features)
  - [--erasableSyntaxOnly](#--erasablesyntaxonly-ts-58)
  - [Granular Return-Branch Type Checking](#granular-return-branch-type-checking-ts-58)
- [TS 5.9 Features](#ts-59-features)
  - [import defer — Deferred Module Evaluation](#import-defer--deferred-module-evaluation-ts-59)
  - [--strictInference](#--strictinference-ts-59-included-in---strict)
- [Effect-TS (Typed Error Handling)](#effect-ts-typed-error-handling)

---

## Explicit Resource Management (`using` keyword, TS 5.2+)

The `using` keyword auto-disposes resources at end of scope via `Symbol.dispose`. No more try/finally for cleanup.

```typescript
// Define a disposable resource
class DbConnection implements Disposable {
  constructor(private url: string) {
    console.log('Connected');
  }

  query(sql: string) { /* ... */ }

  [Symbol.dispose]() {
    console.log('Connection closed');  // auto-called at end of scope
  }
}

// `using` ensures cleanup even if errors are thrown
function runQuery() {
  using conn = new DbConnection('postgres://localhost/db');
  conn.query('SELECT * FROM users');
  // conn[Symbol.dispose]() called automatically here
}

// Async resources use `await using` + Symbol.asyncDispose
class FileHandle implements AsyncDisposable {
  static async open(path: string): Promise<FileHandle> {
    const handle = new FileHandle();
    await handle.init(path);
    return handle;
  }

  async [Symbol.asyncDispose]() {
    await this.flush();
    await this.close();
  }
}

async function processFile() {
  await using file = await FileHandle.open('/tmp/data.csv');
  // file is auto-closed when scope exits
}

// Helper: wrap any cleanup function into a disposable
function disposable(cleanup: () => void): Disposable {
  return { [Symbol.dispose]: cleanup };
}

function withTempDir() {
  const dir = mkdtempSync('/tmp/work-');
  using _ = disposable(() => rmSync(dir, { recursive: true }));
  // dir cleaned up at end of scope
}
```

**tsconfig requirement:** Use `"lib": ["ES2024"]` on TS 5.7+ (includes `Disposable` / `AsyncDisposable` natively). For TS 5.2-5.6, use `"lib": ["ES2022", "ESNext.Disposable"]`.

---

## Decorator Metadata (TS 5.2+)

The `Symbol.metadata` proposal lets decorators attach metadata to classes, accessible at runtime without reflection libraries.

```typescript
// Decorator metadata with Symbol.metadata
function track(target: Function, context: ClassMethodDecoratorContext) {
  context.metadata[context.name] = { tracked: true };
}

class Analytics {
  @track
  pageView(url: string) { /* ... */ }

  @track
  click(element: string) { /* ... */ }
}

// Access metadata
const meta = Analytics[Symbol.metadata];
// { pageView: { tracked: true }, click: { tracked: true } }
```

---

## TS 5.6 Features

### Iterator Helper Methods (TS 5.6+)

Built-in iterator prototype methods — chain operations on generators and iterators without collecting to array first.

```typescript
// Iterator helper methods (TS 5.6+)
function* positiveIntegers() {
  let i = 1;
  while (true) yield i++;
}

// Chain iterator operations without collecting to array
const result = positiveIntegers()
  .map(x => x * 2)
  .filter(x => x % 3 === 0)
  .take(5)
  .toArray(); // [6, 12, 18, 24, 30]
```

### Disallowed Nullish Coalescing Precedence (TS 5.6+)

```typescript
// ERROR: value < options.max ?? 100
//    Parses as (value < options.max) ?? 100 — left is never nullish
// FIX: value < (options.max ?? 100)
```

### `--noCheck` Flag (TS 5.6+)

```bash
# Skip type checking, still emit JS output
tsc --noCheck  # useful for CI: separate check from emit
```

---

## TS 5.7+ Features

### ES2024 Target/Lib (TS 5.7+)

```typescript
// ES2024 target/lib (TS 5.7+)
// Includes: Promise.withResolvers, Object.groupBy, Map.groupBy, Disposable
const { promise, resolve, reject } = Promise.withResolvers<string>();

const grouped = Object.groupBy(users, user => user.role);
// Partial<Record<string, User[]>>
```

### `--rewriteRelativeImportExtensions` (TS 5.7)

```typescript
// Rewrites .ts → .js in declaration files for bundler-free ESM
// tsc --rewriteRelativeImportExtensions

import { helper } from './utils.ts';
// Emitted as: import { helper } from './utils.js';
```

---

## TS 5.8 Features

### `--erasableSyntaxOnly` (TS 5.8+)

Required for Node.js native TypeScript support (`--experimental-strip-types`). Disallows syntax that cannot simply be erased — only allows types, interfaces, and type annotations.

```typescript
// --erasableSyntaxOnly (TS 5.8+)
// Required for Node.js native TypeScript support (--experimental-strip-types)
// Disallows: enums, namespaces, parameter properties, import = require
// Only allows syntax that can be erased (types, interfaces, type annotations)

// Works with erasable-only
type Role = 'admin' | 'user';
interface Config { port: number; }

// Blocked by erasable-only
enum Status { Active, Inactive } // Use union types instead
namespace Utils { } // Use modules instead
```

### Granular Return-Branch Type Checking (TS 5.8)

TypeScript 5.8 checks each branch of a conditional return independently.
Previously, `any` in one branch infected the union and suppressed errors.

```typescript
declare const cache: Map<any, any>;

// TS 5.7: NO ERROR (any infects the union)
// TS 5.8: ERROR on the else branch — catches a real bug
function getUrlObject(urlString: string): URL {
  return cache.has(urlString)
    ? cache.get(urlString)   // any — OK
    : urlString;             // Error: Type 'string' is not assignable to type 'URL'
}
```

---

## TS 5.9 Features

### `import defer` — Deferred Module Evaluation (TS 5.9+)

Delays module execution until first property access. Useful for
startup-time optimization of heavy modules.

```typescript
// Only namespace imports supported
import defer * as analytics from './analytics.js';

startApp();                         // analytics module NOT evaluated yet
analytics.trackPageView('/home');   // evaluated NOW — on first access
```

### `--strictInference` (TS 5.9+, included in `--strict`)

Tightens inference for unconstrained generics. Previously TypeScript
fell back silently — now it reports an error when inference is ambiguous.

---

## Effect-TS (Typed Error Handling)

Effect-TS brings Rust/Scala-style typed error channels to TypeScript. Each Effect carries its success type, error type, and dependencies in the type signature: `Effect<A, E, R>`. Consider for complex domains where error tracking across function composition matters.

```typescript
import { Effect, pipe } from 'effect';

// Errors are tracked in the type system — like Rust's Result<T, E>
class UserNotFoundError { readonly _tag = 'UserNotFoundError' as const; }
class DatabaseError { readonly _tag = 'DatabaseError' as const; }

// --- Style 1: Effect.gen (preferred for sequential workflows) ---
// Reads like async/await; errors short-circuit automatically
const getUser = (id: string): Effect.Effect<User, UserNotFoundError | DatabaseError> =>
  Effect.gen(function* () {
    const user = yield* Effect.tryPromise({
      try: () => db.user.findUnique({ where: { id } }),
      catch: () => new DatabaseError(),
    });
    if (!user) yield* Effect.fail(new UserNotFoundError());
    return user!;
  });

const program = Effect.gen(function* () {
  const user = yield* getUser('usr_123').pipe(
    Effect.catchTag('UserNotFoundError', () => Effect.succeed(defaultUser)),
    Effect.catchTag('DatabaseError', (e) => Effect.die(e)),
  );
  return user;
});

// --- Style 2: pipe-based (functional composition) ---
const getUserPipe = (id: string): Effect.Effect<User, UserNotFoundError | DatabaseError> =>
  pipe(
    Effect.tryPromise({
      try: () => db.user.findUnique({ where: { id } }),
      catch: () => new DatabaseError(),
    }),
    Effect.flatMap((user) =>
      user ? Effect.succeed(user) : Effect.fail(new UserNotFoundError())
    ),
  );
```

**When to consider Effect-TS:** Complex error propagation across many layers, dependency injection needs, concurrent/streaming workflows. Overkill for simple CRUD apps — use the Result type pattern instead.
