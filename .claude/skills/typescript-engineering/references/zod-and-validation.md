# Zod & Validation Patterns

## Table of Contents

- [Zod Schema + Type Inference (Zod v4)](#zod-schema--type-inference-zod-v4)
- [Standard Schema (Validation Interop)](#standard-schema-validation-interop)

---

## Zod Schema + Type Inference (Zod v4)

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

---

## Standard Schema (Validation Interop)

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
