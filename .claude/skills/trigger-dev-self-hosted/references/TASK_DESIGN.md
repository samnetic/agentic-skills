# Trigger.dev Task Design

## Table Of Contents

- [Core Standards](#core-standards)
- [Schema-First Task Example](#schema-first-task-example)
- [Idempotency Pattern](#idempotency-pattern)
- [Queue And Priority Pattern](#queue-and-priority-pattern)
- [Retry Strategy](#retry-strategy)
- [Workflow Composition](#workflow-composition)

## Core Standards

1. Export tasks with named exports only.
2. Keep task IDs stable after release.
3. Validate external payloads with explicit schemas.
4. Make trigger boundaries idempotent.
5. Control side effects with queue and concurrency settings.

## Schema-First Task Example

```ts
import { schemaTask, wait } from "@trigger.dev/sdk/v3";
import { z } from "zod";

const SyncCustomerInput = z.object({
  tenantId: z.string().min(1),
  customerId: z.string().min(1),
  sourceVersion: z.number().int().nonnegative(),
});

export const syncCustomerV1 = schemaTask({
  id: "sync-customer-v1",
  schema: SyncCustomerInput,
  queue: {
    name: "tenant-sync",
    concurrencyLimit: 5,
  },
  run: async (payload) => {
    await wait.for({ seconds: 2 });
    return {
      tenantId: payload.tenantId,
      customerId: payload.customerId,
      synced: true,
    };
  },
});
```

## Idempotency Pattern

Use deterministic keys derived from business identity:

```ts
await syncCustomerV1.trigger(
  {
    tenantId,
    customerId,
    sourceVersion,
  },
  {
    idempotencyKey: `${tenantId}:${customerId}:${sourceVersion}:v1`,
  }
);
```

Rules:

- Do not use random UUIDs for idempotency keys.
- Keep key format stable across retries.
- Add a semantic version segment when payload meaning changes.

## Queue And Priority Pattern

```ts
export const generateInvoicePdfV1 = schemaTask({
  id: "generate-invoice-pdf-v1",
  schema: z.object({ invoiceId: z.string(), tenantId: z.string() }),
  queue: {
    name: "invoice-pdf",
    concurrencyLimit: 2,
  },
  run: async ({ invoiceId }) => ({ invoiceId, status: "done" }),
});

await generateInvoicePdfV1.trigger(
  { invoiceId, tenantId },
  { queue: { priority: "high" } }
);
```

## Retry Strategy

Retry transient failures:

- Network timeouts.
- Provider 429/5xx responses.
- Temporary dependency outages.

Do not retry permanent failures:

- Schema validation failures.
- Domain rule violations.
- Missing required entities that cannot appear later.

Prefer typed errors and operator-readable metadata to support triage.

## Workflow Composition

- Split long workflows into sub-tasks.
- Use `triggerAndWait` when parent tasks depend on child output.
- Isolate irreversible side effects into narrow dedicated tasks.
- Attach metadata/tags early for searchability and incident response.
