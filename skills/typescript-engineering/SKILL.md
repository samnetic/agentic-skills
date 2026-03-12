---
name: typescript-engineering
description: >-
  Advanced TypeScript development expertise. Use when writing TypeScript code, designing
  type-safe APIs, creating generic types, implementing branded/nominal types, using
  discriminated unions, building type guards, configuring tsconfig.json, setting up monorepo
  project references, using utility types (Partial, Pick, Omit, Record, NoInfer), designing
  Zod schemas with type inference, Standard Schema validation, strict mode patterns, the
  `using` keyword, `satisfies` operator, `const` type parameters, template literal types,
  Effect-TS for typed errors, generic React components, erasable-syntax-only mode, or
  reviewing TypeScript code quality.
  Triggers: TypeScript, TS, type, generic, interface, tsconfig, strict mode, branded type,
  discriminated union, type guard, utility type, Zod, type inference, monorepo, project
  references, type-safe, satisfies, NoInfer, Standard Schema, Effect-TS, template literal
  types, decorator, builder pattern.
license: MIT
metadata:
  author: samnetic
  version: "1.0"
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

## Workflow

Follow these steps when approaching TypeScript tasks:

1. **Assess the tsconfig** — Confirm `strict: true`, `noUncheckedIndexedAccess`, and `verbatimModuleSyntax` are enabled. Pick `moduleResolution` based on context (`"bundler"` for apps, `"NodeNext"` for libraries).
2. **Define the data model** — Start with Zod schemas as the single source of truth. Derive TypeScript types with `z.infer<>`. Use discriminated unions for state machines and branded types for domain IDs.
3. **Design the type contracts** — Write function signatures with explicit return types on public APIs. Use generics with constraints, `NoInfer<T>` for default params, and `satisfies` for config objects.
4. **Implement with narrowing** — Prefer type guards and exhaustive switches over `as` casts. Use `unknown` at system boundaries, validate with Zod, then work with typed data.
5. **Handle errors explicitly** — Use Result types for expected failures, typed Error hierarchies for domain errors. Consider Effect-TS for complex error propagation.
6. **Clean up resources** — Use the `using` keyword with `Symbol.dispose` for DB connections, file handles, and temp directories.
7. **Review against checklist** — Run through the code review checklist at the bottom of this file before shipping.

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

## Decision Trees

### When to use which type pattern

- **State with exclusive fields** → Discriminated union (see [references/type-patterns.md](references/type-patterns.md))
- **Preventing ID mix-ups** → Branded types (see [references/type-patterns.md](references/type-patterns.md))
- **Config objects that need autocomplete** → `satisfies` operator (see [references/type-patterns.md](references/type-patterns.md))
- **Literal inference from function args** → `const` type parameters (see [references/type-patterns.md](references/type-patterns.md))
- **Blocking inference at a position** → `NoInfer<T>` (see [references/type-patterns.md](references/type-patterns.md))
- **Type-safe string combinations** → Template literal types (see [references/type-patterns.md](references/type-patterns.md))
- **Runtime validation + type derivation** → Zod v4 schemas (see [references/zod-and-validation.md](references/zod-and-validation.md))
- **Validation library interop** → Standard Schema (see [references/zod-and-validation.md](references/zod-and-validation.md))
- **Auto-cleanup of resources** → `using` keyword (see [references/advanced-features.md](references/advanced-features.md))
- **Complex typed error propagation** → Effect-TS (see [references/advanced-features.md](references/advanced-features.md))
- **Node.js native TS execution** → `--erasableSyntaxOnly` (see [references/advanced-features.md](references/advanced-features.md))

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

For typed error channels with Effect-TS, see [references/advanced-features.md](references/advanced-features.md).

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

## References

Read these when you need deeper detail on a specific topic:

- **[Type Patterns](references/type-patterns.md)** — For discriminated unions, branded types, type predicates, `satisfies`, `const` type params, `NoInfer`, template literals, generics, builder pattern, generic React components
- **[Zod & Validation](references/zod-and-validation.md)** — For Zod v4 schemas, Standard Schema interop, validation patterns
- **[Advanced Features](references/advanced-features.md)** — For `using` keyword (resource management), decorator metadata, TS 5.6-5.9 features, `--erasableSyntaxOnly`, Effect-TS

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
