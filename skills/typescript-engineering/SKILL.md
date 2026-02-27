---
name: typescript-engineering
description: >-
  Advanced TypeScript development expertise. Use when writing TypeScript code, designing
  type-safe APIs, creating advanced generic types, implementing branded/nominal types,
  using discriminated unions, building type predicates and guards, configuring tsconfig.json,
  setting up monorepo project references, choosing between interfaces vs types, using
  utility types (Partial, Pick, Omit, Record, Readonly, Required, NoInfer), implementing the
  builder pattern with types, creating type-safe event emitters, designing Zod schemas
  with type inference, using Standard Schema for validation interop, optimizing TypeScript
  compilation, implementing strict mode patterns, using the `using` keyword for resource
  management, `satisfies` operator patterns, `const` type parameters, template literal types,
  Effect-TS for typed errors, decorator metadata, generic React components, type-safe builder
  pattern, erasable-syntax-only mode, iterator helpers, monorepo project references with
  configDir, avoiding common TypeScript pitfalls, or reviewing TypeScript code quality.
  Triggers: TypeScript, TS, type, generic, interface, tsconfig, strict mode, branded type,
  discriminated union, type guard, type predicate, utility type, Zod, type inference,
  monorepo, project references, type-safe, satisfies, using keyword, NoInfer, Standard Schema,
  Effect-TS, template literal types, verbatimModuleSyntax, isolated declarations, decorator,
  metadata, erasableSyntaxOnly, configDir, iterator helpers, builder pattern, generic component.
---

# TypeScript Engineering Skill

Write TypeScript that catches bugs at compile time, not runtime. Strict mode always.
Types are documentation that the compiler enforces.

---

## Core Principles

| Principle | Meaning |
|---|---|
| **Strict mode, always** | `"strict": true` in tsconfig. No exceptions |
| **No `any`, no `as`** | Use `unknown` + type narrowing. Cast only at system boundaries |
| **Types from data, not data from types** | Infer types from Zod schemas, API responses, DB queries |
| **Narrow, don't cast** | Use type guards, discriminated unions, exhaustive checks |
| **Prefer interfaces for objects, types for unions** | Interfaces extend, types compose |
| **Make illegal states unrepresentable** | Use the type system to prevent bugs |

---

## tsconfig.json — Non-Negotiable Settings

```jsonc
{
  "compilerOptions": {
    // Strictness (all enabled by "strict": true)
    "strict": true,
    "noUncheckedIndexedAccess": true,     // array[0] is T | undefined
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "exactOptionalPropertyTypes": true,    // distinguish undefined from missing

    // Module
    "module": "NodeNext",                  // or "ESNext" for bundled code
    "moduleResolution": "NodeNext",        // or "bundler" for Vite/webpack
    "verbatimModuleSyntax": true,          // explicit `import type` — replaces importsNotUsedAsValues
    "isolatedModules": true,               // required for most build tools

    // Output
    "target": "ES2022",
    "lib": ["ES2024"],                     // TS 5.7+: ES2024 includes Disposable, Promise.withResolvers, Object.groupBy
                                           // For TS <5.7: use ["ES2022", "ESNext.Disposable"]
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "outDir": "dist",

    // Path mapping
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src"],
  "exclude": ["node_modules", "dist"]
}
```

### moduleResolution: "bundler" vs "NodeNext"

| Scenario | Use | Why |
|---|---|---|
| **App with bundler** (Vite, webpack, Turbopack, esbuild) | `"bundler"` | No need for file extensions in imports, matches bundler behavior |
| **Node.js server** (no bundler at runtime) | `"NodeNext"` | Matches Node.js ESM resolution, requires `.js` extensions |
| **Library published to npm** | `"NodeNext"` | Strictest — output works everywhere (Node, bundlers, Deno) |
| **Monorepo app package** | `"bundler"` | Internal packages consumed by bundler |

```jsonc
// App with Vite/webpack/Next.js
{
  "compilerOptions": {
    "module": "ESNext",
    "moduleResolution": "bundler"   // no file extensions needed
  }
}

// Node.js server or npm library
{
  "compilerOptions": {
    "module": "NodeNext",
    "moduleResolution": "NodeNext"  // requires .js extensions in imports
  }
}
```

### verbatimModuleSyntax (TS 5.0+)

Replaces `importsNotUsedAsValues` and `preserveValueImports`. Makes module intentions explicit: imports/exports without `type` are kept, those with `type` are dropped entirely.

```typescript
// With verbatimModuleSyntax: true
import { type User } from './models';     // dropped at emit — type-only
import { userSchema } from './schemas';   // kept — runtime value
import type { Config } from './config';   // dropped — entire import is type-only

// This prevents accidental side-effect imports being removed
// and makes code review clearer about what's runtime vs type
```

### Isolated Declarations (TS 5.5+)

Enables parallel `.d.ts` generation without the type checker. Required for fast DTS emit in esbuild/swc.

```jsonc
{
  "compilerOptions": {
    "isolatedDeclarations": true,  // forces explicit return types on exported functions
    "declaration": true
  }
}
```

```typescript
// With isolatedDeclarations, exported functions MUST have explicit return types
export function getUser(id: string): User {  // OK — explicit return type
  return db.users.find(id);
}

export function getUser(id: string) {  // ERROR — return type must be explicit
  return db.users.find(id);
}
```

### `${configDir}` Template Variable for Monorepo tsconfig (TS 5.5+)

Resolves relative paths based on the config file that contains them, not the extending file. Essential for shared tsconfig in monorepos.

```jsonc
// tsconfig.base.json (root)
{
  "compilerOptions": {
    "strict": true,
    "outDir": "${configDir}/dist",  // Resolves relative to the file that USES this
    "rootDir": "${configDir}/src"   // NOT relative to tsconfig.base.json
  }
}

// packages/shared/tsconfig.json
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "outDir": "${configDir}/dist",  // Resolves to packages/shared/dist
    "rootDir": "${configDir}/src"   // Resolves to packages/shared/src
  }
}

// packages/api/tsconfig.json
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "outDir": "${configDir}/dist",  // Resolves to packages/api/dist
    "rootDir": "${configDir}/src"   // Resolves to packages/api/src
  }
}
```

### Monorepo Project References

```jsonc
// tsconfig.json (root)
{
  "references": [
    { "path": "./packages/shared" },
    { "path": "./packages/api" },
    { "path": "./packages/web" }
  ]
}

// packages/shared/tsconfig.json
{
  "compilerOptions": {
    "composite": true,        // Required for project references
    "declaration": true,
    "declarationMap": true,
    "outDir": "dist",
    "rootDir": "src"
  }
}

// Build all projects in dependency order:
// tsc --build  (incremental, uses .tsBuildInfo)
```

---

## Type Design Patterns

### Discriminated Unions (State Machines)

```typescript
// Make illegal states unrepresentable
type RequestState =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'success'; data: User[] }
  | { status: 'error'; error: Error; retryCount: number };

function handleState(state: RequestState) {
  switch (state.status) {
    case 'idle':
      return renderEmpty();
    case 'loading':
      return renderSpinner();
    case 'success':
      return renderUsers(state.data); // data is available here
    case 'error':
      return renderError(state.error); // error is available here
    // No default — TypeScript errors if a case is missing (exhaustive check)
  }
}
```

### Branded/Nominal Types

```typescript
// Prevent mixing up IDs
type UserId = string & { readonly __brand: 'UserId' };
type OrderId = string & { readonly __brand: 'OrderId' };

function createUserId(id: string): UserId {
  if (!id.match(/^usr_/)) throw new Error('Invalid user ID format');
  return id as UserId;
}

function getUser(id: UserId): User { ... }
function getOrder(id: OrderId): Order { ... }

const userId = createUserId('usr_123');
const orderId = createOrderId('ord_456');

getUser(userId);   // OK
getUser(orderId);  // Compile error! Can't pass OrderId where UserId expected
```

### Type Predicates (Custom Type Guards)

```typescript
function isNonNullable<T>(value: T): value is NonNullable<T> {
  return value !== null && value !== undefined;
}

function isUser(data: unknown): data is User {
  return (
    typeof data === 'object' &&
    data !== null &&
    'id' in data &&
    'email' in data &&
    typeof (data as User).email === 'string'
  );
}

// Usage — filters with type narrowing
const validUsers = users.filter(isNonNullable);
// Type: User[] (not (User | null)[])
```

### Inferred Type Predicates (TS 5.5+)

TypeScript 5.5 automatically infers type predicates for simple guard functions. No more manual `x is T` annotations for obvious cases.

```typescript
// TS 5.5 infers: (x: unknown) => x is number
const isNumber = (x: unknown) => typeof x === 'number';

// TS 5.5 infers: (x: T) => x is NonNullable<T>
const isNonNullish = <T,>(x: T) => x != null;

// .filter() now narrows correctly without manual type predicates
const nums = [1, 2, 3, null, 5].filter(x => x !== null);
// TS 5.4: (number | null)[]
// TS 5.5: number[]  — automatically inferred!

// Still write manual predicates for complex checks
function isAdmin(user: User): user is AdminUser {
  return user.role === 'admin' && 'permissions' in user;
}
```

### Const Assertions and Enums

```typescript
// AVOID TypeScript enums — use const objects instead
// Why: enums generate runtime code, have weird behavior with number values

// DO: const object + type derivation
const ORDER_STATUS = {
  PENDING: 'pending',
  CONFIRMED: 'confirmed',
  SHIPPED: 'shipped',
  DELIVERED: 'delivered',
  CANCELLED: 'cancelled',
} as const;

type OrderStatus = typeof ORDER_STATUS[keyof typeof ORDER_STATUS];
// Type: 'pending' | 'confirmed' | 'shipped' | 'delivered' | 'cancelled'

// Also works for lookup maps
const HTTP_STATUS = {
  200: 'OK',
  201: 'Created',
  400: 'Bad Request',
  404: 'Not Found',
  500: 'Internal Server Error',
} as const;

type HttpStatusCode = keyof typeof HTTP_STATUS; // 200 | 201 | 400 | 404 | 500
```

### `satisfies` Operator Patterns (TS 4.9+)

`satisfies` validates a value matches a type WITHOUT widening it. You keep literal types and autocomplete.

```typescript
// PROBLEM: type annotation widens — lose literal types
const routes: Record<string, { path: string }> = {
  home: { path: '/' },
  about: { path: '/about' },
};
routes.home.path; // string (wide)
routes.typo;      // no error! any key is valid

// SOLUTION: satisfies — validate shape, keep literals
const routes = {
  home: { path: '/' },
  about: { path: '/about' },
} satisfies Record<string, { path: string }>;
routes.home.path; // "/" (literal)
routes.typo;      // error: Property 'typo' does not exist

// Great for config objects
type Theme = { colors: Record<string, string>; spacing: Record<string, number> };

const theme = {
  colors: { primary: '#3b82f6', danger: '#ef4444' },
  spacing: { sm: 4, md: 8, lg: 16 },
} satisfies Theme;

theme.colors.primary; // "#3b82f6" (literal, not string)
theme.spacing.sm;     // 4 (literal, not number)

// Combine with `as const` for fully immutable + validated
const permissions = {
  admin: ['read', 'write', 'delete'],
  viewer: ['read'],
} as const satisfies Record<string, readonly string[]>;
```

### `const` Type Parameters (TS 5.0+)

Forces callers to infer literal types without requiring `as const` at the call site.

```typescript
// WITHOUT const — infers wide types
function getRoutes<T extends Record<string, string>>(routes: T): T {
  return routes;
}
const r1 = getRoutes({ home: '/', about: '/about' });
// Type: { home: string; about: string }  — too wide

// WITH const — infers literal types automatically
function getRoutes<const T extends Record<string, string>>(routes: T): T {
  return routes;
}
const r2 = getRoutes({ home: '/', about: '/about' });
// Type: { readonly home: "/"; readonly about: "/about" }  — precise!

// Useful for builder patterns, config factories, event maps
function defineEvents<const T extends Record<string, (...args: unknown[]) => void>>(events: T): T {
  return events;
}
const events = defineEvents({
  userCreated: (user: User) => {},
  orderPlaced: (order: Order, total: number) => {},
});
// Full type safety on event names AND handler signatures
```

### `NoInfer<T>` Utility Type (TS 5.4+)

Prevents TypeScript from inferring a type parameter from a specific position. Forces inference from other arguments.

```typescript
// WITHOUT NoInfer — TypeScript infers from BOTH arguments (union)
function createFSM<S extends string>(states: S[], initial: S) {}
createFSM(['idle', 'loading', 'done'], 'invalid');
// No error! TS infers S as 'idle' | 'loading' | 'done' | 'invalid'

// WITH NoInfer — inference blocked on `initial`, must match `states`
function createFSM<S extends string>(states: S[], initial: NoInfer<S>) {}
createFSM(['idle', 'loading', 'done'], 'invalid');
//                                      ^^^^^^^^^ Error!
// Argument of type '"invalid"' is not assignable to '"idle" | "loading" | "done"'

// Works for default values, fallback configs, etc.
function createStreetLight<C extends string>(
  colors: C[],
  defaultColor?: NoInfer<C>,
) {}
createStreetLight(['red', 'yellow', 'green'], 'blue'); // Error!
```

### Template Literal Types

Type-safe string patterns at compile time. Compose unions to generate all valid combinations.

```typescript
// Type-safe API routes
type HttpMethod = 'GET' | 'POST' | 'PUT' | 'DELETE';
type ApiVersion = 'v1' | 'v2';
type Resource = 'users' | 'orders' | 'products';
type ApiEndpoint = `/${ApiVersion}/${Resource}`;
// "/v1/users" | "/v1/orders" | "/v1/products" | "/v2/users" | ...

// CSS utility classes (like Tailwind)
type Size = 'sm' | 'md' | 'lg' | 'xl';
type Side = 'top' | 'right' | 'bottom' | 'left';
type SpacingClass = `${'p' | 'm'}${'' | `${'-' | 'x-' | 'y-' | 't-' | 'b-' | 'l-' | 'r-'}`}${Size}`;

// Type-safe CSS values
type CSSUnit = 'px' | 'rem' | 'em' | '%' | 'vh' | 'vw';
type CSSValue = `${number}${CSSUnit}`;
const width: CSSValue = '100px';  // OK
const bad: CSSValue = '100';      // Error — missing unit

// Event handler pattern — auto-generate "on" + capitalized event
type EventName = 'click' | 'focus' | 'blur';
type EventHandler = `on${Capitalize<EventName>}`;
// "onClick" | "onFocus" | "onBlur"

// Extract route params from URL pattern
type ExtractParams<T extends string> =
  T extends `${infer _}:${infer Param}/${infer Rest}`
    ? Param | ExtractParams<Rest>
    : T extends `${infer _}:${infer Param}`
      ? Param
      : never;

type Params = ExtractParams<'/users/:userId/posts/:postId'>;
// "userId" | "postId"
```

### Generic Constraints

```typescript
// Constrained generics
function getProperty<T, K extends keyof T>(obj: T, key: K): T[K] {
  return obj[key];
}

// Generic with default
type ApiResponse<T = unknown> = {
  data: T;
  meta: { timestamp: number; requestId: string };
};

// Conditional types
type ExtractArrayItem<T> = T extends (infer U)[] ? U : never;
type Item = ExtractArrayItem<string[]>; // string

// Illustration of how the built-in Readonly<T> works — use the built-in directly
type ReadonlyIllustration<T> = { readonly [K in keyof T]: T[K] };

// This is the built-in Partial<T>
type PartialIllustration<T> = { [K in keyof T]?: T[K] };

type Nullable<T> = { [K in keyof T]: T[K] | null };
```

### Type-Safe Builder Pattern

```typescript
// Functional builder — no `as any`, fully type-safe
interface ConnectionConfig {
  readonly host: string;
  readonly port: number;
  readonly database: string;
}

type Builder<T extends Partial<ConnectionConfig> = {}> = Readonly<T> & {
  host(value: string): Builder<T & { host: string }>;
  port(value: number): Builder<T & { port: number }>;
  database(value: string): Builder<T & { database: string }>;
} & (T extends ConnectionConfig ? { build(): Connection } : {});

function createConnectionBuilder<T extends Partial<ConnectionConfig> = {}>(
  config: T = {} as T
): Builder<T> {
  return {
    ...config,
    host: (value: string) => createConnectionBuilder({ ...config, host: value }),
    port: (value: number) => createConnectionBuilder({ ...config, port: value }),
    database: (value: string) => createConnectionBuilder({ ...config, database: value }),
    ...(isComplete(config) ? { build: () => new Connection(config) } : {}),
  } as Builder<T>;
}

function isComplete(c: Partial<ConnectionConfig>): c is ConnectionConfig {
  return 'host' in c && 'port' in c && 'database' in c;
}

createConnectionBuilder().host('localhost').build();
// ❌ Error: Property 'build' does not exist

createConnectionBuilder().host('localhost').port(5432).database('mydb').build();
// ✓ Compiles — build() only available when all fields set
```

### Generic React Component Patterns

```typescript
// Generic table component
interface Column<T> {
  key: keyof T;
  header: string;
  render?: (value: T[keyof T], row: T) => React.ReactNode;
}

interface DataTableProps<T> {
  data: T[];
  columns: Column<T>[];
  onRowClick?: (row: T) => void;
}

function DataTable<T extends Record<string, unknown>>({
  data, columns, onRowClick,
}: DataTableProps<T>) {
  return (
    <table>
      <thead>
        <tr>{columns.map(col => <th key={String(col.key)}>{col.header}</th>)}</tr>
      </thead>
      <tbody>
        {data.map((row, i) => (
          <tr key={i} onClick={() => onRowClick?.(row)}>
            {columns.map(col => (
              <td key={String(col.key)}>
                {col.render ? col.render(row[col.key], row) : String(row[col.key])}
              </td>
            ))}
          </tr>
        ))}
      </tbody>
    </table>
  );
}

// Usage — T is inferred
<DataTable
  data={users}
  columns={[
    { key: 'name', header: 'Name' },
    { key: 'email', header: 'Email' },
    { key: 'role', header: 'Role', render: (v) => <Badge>{v}</Badge> },
  ]}
/>
```

### Zod Schema + Type Inference (Zod v4)

```typescript
import { z } from 'zod';  // Zod v4 — same import path

// Define schema — single source of truth
const UserSchema = z.object({
  id: z.uuid(),            // v4: top-level z.uuid() replaces z.string().uuid()
  email: z.email(),        // v4: top-level z.email() replaces z.string().email()
  name: z.string().min(1).max(100),
  role: z.enum(['admin', 'user', 'viewer']),
  settings: z.object({
    theme: z.enum(['light', 'dark']).default('light'),
    notifications: z.boolean().default(true),
  }),
  createdAt: z.coerce.date(),
});

// Derive type from schema — no duplication
type User = z.infer<typeof UserSchema>;

// Partial schema for updates
const UpdateUserSchema = UserSchema.partial().omit({ id: true, createdAt: true });
type UpdateUser = z.infer<typeof UpdateUserSchema>;

// v4: z.record requires explicit key AND value types
const UserMap = z.record(z.string(), UserSchema);

// Validate at system boundaries
function createUser(input: unknown): User {
  return UserSchema.parse(input); // throws ZodError; access .issues not .errors
}

// v4: z.interface() — precise optional semantics + recursive types (no z.lazy)
const TreeNodeSchema = z.interface({
  id: z.string(),
  label: z.string(),
  get children() { return z.array(TreeNodeSchema); }, // recursive without z.lazy()
  "metadata?": z.record(z.string(), z.string()),      // key-optional (omittable)
});

// v4: .meta() + z.toJSONSchema() — first-party JSON Schema export
const EmailSchema = z.email().meta({
  title: 'Email address',
  description: 'A valid email address',
});
const jsonSchema = z.toJSONSchema(UserSchema);

// v4: unified error param (replaces invalid_type_error / required_error)
const RequiredString = z.string({
  error: (issue) => issue.input === undefined ? 'Required' : 'Must be a string',
});

// Zod Mini — for bundle-critical paths (< 2kb core)
// import * as z from '@zod/mini';  // functional API, no method chaining
// z.optional(z.string())  instead of  z.string().optional()
```

### Standard Schema (Validation Interop)

Standard Schema is a shared TypeScript interface (~60 lines of types) that all major validation libraries implement: Zod (v3.23+), Valibot (v1+), ArkType, Effect Schema, TypeBox. Libraries implement it once, tools consume it once — no vendor lock-in.

```typescript
import type { StandardSchemaV1 } from '@standard-schema/spec';

// Write framework code that accepts ANY validation library
function createEndpoint<T>(config: {
  schema: StandardSchemaV1<T>;  // Zod, Valibot, ArkType — any of them
  handler: (data: T) => Response;
}) {
  return async (req: Request) => {
    const result = await config.schema['~standard'].validate(await req.json());
    if (result.issues) {
      return Response.json({ errors: result.issues }, { status: 400 });
    }
    return config.handler(result.value);
  };
}

// Consumers use whatever library they prefer
import { z } from 'zod';
import * as v from 'valibot';

// Both work — Standard Schema is the common interface
createEndpoint({ schema: z.object({ name: z.string() }), handler: ... });
createEndpoint({ schema: v.object({ name: v.string() }), handler: ... });
```

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
// ❌ ERROR: value < options.max ?? 100
//    Parses as (value < options.max) ?? 100 — left is never nullish
// ✓ FIX: value < (options.max ?? 100)
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

// ✓ Works with erasable-only
type Role = 'admin' | 'user';
interface Config { port: number; }

// ❌ Blocked by erasable-only
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

## Error Handling Patterns

```typescript
// Result type (no thrown exceptions for expected errors)
type Result<T, E = Error> =
  | { ok: true; value: T }
  | { ok: false; error: E };

function ok<T>(value: T): Result<T, never> {
  return { ok: true, value };
}

function err<E>(error: E): Result<never, E> {
  return { ok: false, error };
}

// Custom error hierarchy
class AppError extends Error {
  constructor(
    message: string,
    public readonly code: string,
    public readonly statusCode: number = 500,
    public readonly cause?: Error,
  ) {
    super(message);
    this.name = this.constructor.name;
  }
}

class NotFoundError extends AppError {
  constructor(resource: string, id: string) {
    super(`${resource} not found: ${id}`, 'NOT_FOUND', 404);
  }
}

class ValidationError extends AppError {
  constructor(
    message: string,
    public readonly fields: Record<string, string[]>,
  ) {
    super(message, 'VALIDATION_ERROR', 400);
  }
}
```

### Effect-TS (Emerging Pattern for Typed Errors)

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

**When to consider Effect-TS:** Complex error propagation across many layers, dependency injection needs, concurrent/streaming workflows. Overkill for simple CRUD apps — use the Result type pattern above instead.

---

## Module Organization

```
src/
├── modules/
│   └── users/
│       ├── user.router.ts     # HTTP layer (routes, middleware)
│       ├── user.service.ts    # Business logic
│       ├── user.repository.ts # Data access
│       ├── user.schema.ts     # Zod schemas + derived types
│       ├── user.errors.ts     # Domain-specific errors
│       └── index.ts           # Public API (re-exports)
├── shared/
│   ├── types.ts               # Shared type utilities
│   ├── errors.ts              # Base error classes
│   ├── result.ts              # Result type
│   └── middleware/             # Cross-cutting middleware
├── config/
│   └── env.ts                 # Environment config with Zod validation
└── main.ts                    # Entry point
```

**Rules:**
- Import from module's `index.ts` only — never reach into internal files
- Schemas are the single source of truth for types
- Each module exports only what other modules need

---

## Test Data Patterns

### Type-Safe Partial Test Data
Instead of using `as` casts in tests, create a helper that allows partial data with type safety:

```typescript
// test/helpers.ts
function createPartial<T>(overrides: Partial<T>): T {
  return overrides as T; // Single controlled cast location
}

// Or better — merge with defaults
function createTestUser(overrides: Partial<User> = {}): User {
  return {
    id: 'usr_test_1',
    email: 'test@example.com',
    name: 'Test User',
    role: 'user',
    createdAt: new Date('2025-01-01'),
    ...overrides,
  };
}

// Usage in tests — type-safe, no `as` casts scattered everywhere
const admin = createTestUser({ role: 'admin' });
const user = createTestUser({ email: 'specific@test.com' });
```

### Note on `as` in Tests
- Tests are a *legitimate exception* to the "no `as`" rule when creating partial test fixtures
- BUT prefer factory functions with defaults (above) over scattered `as` casts
- The factory pattern centralizes the cast to one place, making tests more maintainable

---

## Anti-Patterns

| Anti-Pattern | Why It's Dangerous | Fix |
|---|---|---|
| `any` type | Disables all type checking | `unknown` + type narrowing |
| `as` assertion everywhere | Lies to the compiler | Type guards, discriminated unions |
| `// @ts-ignore` | Hides real errors | Fix the type error properly |
| TypeScript `enum` | Runtime artifacts, confusing behavior | `as const` objects + derived types |
| `!` non-null assertion | Runtime crash waiting to happen | Proper null checks or optional chaining |
| Optional properties for everything | Hides required vs optional distinction | Be explicit about required fields |
| `Object`, `Function`, `{}` types | Too broad, no safety | Specific object shapes, function signatures |
| `string` for IDs | Mix up user ID and order ID | Branded types |
| Duplicate type + schema definitions | Types and validation drift apart | Zod schema -> infer type |
| Barrel exports (re-export everything) | Kills tree-shaking, circular deps | Export only public API |
| `interface` for function types | Misleading | `type Handler = (req: Request) => Response` |
| Not using `satisfies` | Lose literal types with annotation | `const x = {...} satisfies Config` |
| Manual `try/finally` for cleanup | Verbose, easy to forget | `using` keyword with `Symbol.dispose` |
| `importsNotUsedAsValues` | Deprecated, confusing | `verbatimModuleSyntax: true` |
| Manual type predicates for `.filter()` | Verbose boilerplate since TS 5.5 | Let TS 5.5+ infer predicates |
| Locking to single validation library | Vendor lock-in | Standard Schema interface for interop |
| Redefining built-in utility types | Shadows `Readonly<T>`, `Partial<T>`, etc. | Use the built-in utility types directly |
| `enum` with `--erasableSyntaxOnly` | Blocked by Node.js strip-types | Union types: `type Status = 'active' \| 'inactive'` |
| `namespace` in modern code | Blocked by erasable-only, poor tree-shaking | ES modules |
| Hardcoded relative paths in monorepo tsconfig | Breaks when extended by other packages | `${configDir}` template variable (TS 5.5+) |
| Collecting infinite iterators to array before transforming | Memory blowup, unnecessary allocation | Iterator helper methods (TS 5.6+) |
| `z.string().email()` in Zod v4 | Deprecated; use top-level validators | `z.email()`, `z.uuid()`, `z.url()` |
| `z.record(z.string())` single-arg in Zod v4 | Missing value type, breaks | `z.record(z.string(), z.string())` |
| `error.errors` on ZodError in v4 | Property renamed | `error.issues` |

---

## Utility Type Cheat Sheet

| Utility | Purpose | Example |
|---|---|---|
| `Partial<T>` | All properties optional | Update payloads |
| `Required<T>` | All properties required | Ensure completeness |
| `Pick<T, K>` | Select properties | API response subset |
| `Omit<T, K>` | Exclude properties | Remove internal fields |
| `Record<K, V>` | Dictionary type | `Record<string, Handler>` |
| `Readonly<T>` | Immutable | Config objects |
| `NonNullable<T>` | Remove null/undefined | After filtering |
| `ReturnType<F>` | Extract return type | From function signatures |
| `Parameters<F>` | Extract param types | Wrapper functions |
| `Awaited<T>` | Unwrap Promise | Async function returns |
| `Extract<T, U>` | Keep matching members | From union types |
| `Exclude<T, U>` | Remove matching members | From union types |
| `NoInfer<T>` | Block type inference at position | Default params, fallback values |
| `satisfies` | Validate without widening | `const x = {...} satisfies Config` |

---

## Checklist: TypeScript Code Review

- [ ] `strict: true` in tsconfig with `noUncheckedIndexedAccess`
- [ ] `verbatimModuleSyntax: true` — explicit `import type` everywhere
- [ ] No `any` types (search for `: any` and `as any`)
- [ ] No `// @ts-ignore` or `// @ts-expect-error` without linked issue
- [ ] Zod schemas are single source of truth for types
- [ ] `satisfies` used for config objects (keep literal types)
- [ ] Error handling uses Result type or typed Error hierarchy
- [ ] Discriminated unions for state machines
- [ ] Branded types for IDs and domain primitives
- [ ] Functions have explicit return types on public APIs
- [ ] Exported functions have explicit return types (for `isolatedDeclarations`)
- [ ] Exhaustive switch statements (no default for unions)
- [ ] `as const` objects instead of enums
- [ ] `using` keyword for resource cleanup (DB connections, file handles, temp dirs)
- [ ] `moduleResolution` matches target: `"bundler"` for apps, `"NodeNext"` for libraries
- [ ] Modules export only public API via index.ts
- [ ] Test factories use typed defaults, not scattered `as` casts
- [ ] `lib: ["ES2024"]` on TS 5.7+ (no need for `ESNext.Disposable` shim)
- [ ] `composite: true` and `declaration: true` for project reference packages
- [ ] `${configDir}` used in shared tsconfig for monorepo path resolution
- [ ] No custom redefinitions of built-in utility types (`Readonly`, `Partial`, etc.)
- [ ] `--erasableSyntaxOnly` considered for Node.js native TS execution
- [ ] Generic components use type inference (no manual type params at call site)
- [ ] Builder pattern enforces required fields at the type level
