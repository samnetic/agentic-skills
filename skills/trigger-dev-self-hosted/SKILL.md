---
name: trigger-dev-self-hosted
description: >-
  Trigger.dev self-hosting and production workflow engineering for AI-assisted development.
  Use when building, reviewing, or debugging Trigger.dev tasks, AI agents, realtime updates,
  deployment pipelines, and self-hosted infrastructure.
  Covers: task exports, schema validation with Zod, queues and concurrency, idempotency,
  retries, versioning, trigger.config.ts setup, CI/CD deployment, and production hardening
  for Kubernetes-based self-hosting.
  Triggers: Trigger.dev, trigger.config.ts, trigger task, background job, workflow,
  self-hosted Trigger.dev, queue, concurrency, idempotency key, retry policy,
  codex trigger, claude code trigger, trigger deployment, helm trigger.
license: MIT
compatibility: Requires Docker and Kubernetes for self-hosting
metadata:
  author: samnetic
  version: "1.0"
---

# Trigger.dev Self-Hosted Production Skill

Build Trigger.dev systems that are durable, observable, and safe at production scale.
Treat self-hosted production as a platform problem, not only a task-authoring problem.

---

## Core Principles

| Principle | Meaning |
|---|---|
| **Durable by default** | Every task must survive restarts, crashes, and retries without data loss or duplication |
| **Schema at the boundary** | Validate all external inputs with Zod via `schemaTask`; never trust unvalidated payloads |
| **Deterministic idempotency** | Derive idempotency keys from business identifiers, not random values; same input produces same deduplication key |
| **Explicit concurrency** | Always declare queue names and concurrency limits; unbounded parallelism causes cascading failures |
| **Stable task identity** | Task `id` values are a public contract; never rename after release, create a new id for breaking changes |
| **Environment parity** | Docker Compose for local dev, Kubernetes for production; never promote Compose to prod |
| **Observe everything** | Emit structured metadata, trace workflow composition, and verify with post-deploy smoke runs |

---

## Progressive Disclosure Map

Read only the references needed for the user request:

| Reference | Path | When to read |
|---|---|---|
| Setup and Modes | [references/SETUP_AND_MODES.md](references/SETUP_AND_MODES.md) | User is bootstrapping a project, choosing cloud vs self-hosted, configuring profiles, or asking about mode selection |
| Task Design | [references/TASK_DESIGN.md](references/TASK_DESIGN.md) | User is writing tasks, defining schemas, setting up idempotency, configuring queues/retries, or composing workflows |
| AI Agent Patterns | [references/AI_AGENT_PATTERNS.md](references/AI_AGENT_PATTERNS.md) | User is building LLM-driven workflows, orchestrating multi-step AI agents, or adding human-in-the-loop approval |
| Self-Hosting Runbook | [references/SELF_HOSTING.md](references/SELF_HOSTING.md) | User is deploying Trigger.dev infrastructure with Docker Compose locally or Kubernetes/Helm in production |
| CI/CD for Self-Hosted | [references/CICD_SELF_HOSTED.md](references/CICD_SELF_HOSTED.md) | User is setting up CI/CD pipelines, automating deployments, or configuring `TRIGGER_API_URL` / `TRIGGER_ACCESS_TOKEN` |

---

## Decision Trees

### Choosing a Deployment Mode

```
What environment are you targeting?
├─ Local development or evaluation?
│  └─ Use Docker Compose (self-host-local)
│     ├─ Quick start, low ops overhead
│     └─ NOT suitable for production traffic
├─ Production with managed infrastructure?
│  └─ Use Trigger.dev Cloud (cloud mode)
│     ├─ Zero self-hosting ops burden
│     └─ Best when team lacks Kubernetes expertise
└─ Production with self-hosted requirements?
   └─ Use Kubernetes + Helm (self-host-production)
      ├─ Full control over data residency and networking
      ├─ Requires managed PostgreSQL + managed Redis
      └─ Use official Helm chart; do not hand-roll manifests
```

### Choosing a Task Architecture

```
What does the task do?
├─ Single side-effect (send email, call API)?
│  └─ Single focused task with schema + idempotency key
├─ Multi-step workflow with independent stages?
│  └─ Compose with triggerAndWait / batchTriggerAndWait
│     ├─ Each stage is its own task with its own retry policy
│     └─ Parent task orchestrates; child tasks execute
├─ LLM/AI agent with tool loops?
│  └─ Use AI Agent pattern (see AI_AGENT_PATTERNS.md)
│     ├─ Bound loops with maxSteps + timeout
│     ├─ Isolate irreversible actions into separate tasks
│     └─ Require human approval for destructive operations
└─ High-throughput batch processing?
   └─ Queue with explicit concurrency limit
      ├─ Use batchTrigger for fan-out
      └─ Set concurrency to match downstream rate limits
```

---

## Non-Negotiable Rules

1. Use named task exports. Do not default-export tasks.
2. Keep task `id` values stable after release; create a new `id` for breaking changes.
3. Enforce input schemas on external payload entry points (prefer `schemaTask` + `zod`).
4. Use deterministic idempotency keys for externally-triggered operations.
5. Use queue names and explicit concurrency limits for side-effecting workflows.
6. Treat Docker Compose as local/dev only; use Kubernetes for production self-hosting.
7. In CI for self-hosted deployments, use `TRIGGER_API_URL` and `TRIGGER_ACCESS_TOKEN`.

---

## Operating Workflow

1. Choose mode first: `cloud`, `self-host-local`, or `self-host-production`.
2. Install official Trigger.dev coding guidance:

```bash
npx skills add triggerdotdev/skills
npx trigger.dev@latest install-rules
```

3. Confirm project bootstrapping and profile setup (see `SETUP_AND_MODES.md`).
4. Define task contracts before coding: schema, idempotency, queue/retry strategy.
5. Implement in small domain-focused task files.
6. Deploy with environment-specific pipeline and run post-deploy smoke checks.

---

## Anti-Patterns

| Anti-pattern | Why it fails | Correct approach |
|---|---|---|
| Giant task mixing many side effects | Unsafe retries and poor debuggability | Split by workflow boundaries |
| Random idempotency keys | Duplicate work still occurs | Deterministic business-identity keys |
| Unlimited concurrency | Throttling and cascading failures | Queue + explicit concurrency limits |
| Production on ad-hoc Compose | Weak HA, upgrade, and recovery posture | Kubernetes + Helm + managed stateful deps |
| Silent catch-and-continue | Hidden corruption and operator blind spots | Structured errors + explicit compensation |
| Default-exported tasks | Fragile imports and unclear task registry | Always use named exports |
| Hardcoded API URLs in task code | Breaks across environments | Use environment variables and trigger.config.ts |

---

## Checklist

### Task Design Checklist

- [ ] Task uses named export (not default export)
- [ ] Task `id` is stable, descriptive, and follows naming convention
- [ ] Input schema defined with Zod via `schemaTask` for external entry points
- [ ] Idempotency key is deterministic and derived from business identifiers
- [ ] Queue name and concurrency limit explicitly set for side-effecting tasks
- [ ] Retry policy configured with appropriate `maxAttempts` and backoff
- [ ] Task file is focused on a single domain boundary
- [ ] Workflow composition uses `triggerAndWait` / `batchTriggerAndWait` (not inline logic)

### Self-Hosted Production Checklist

- [ ] Deployment mode chosen: Docker Compose (dev) or Kubernetes (prod)
- [ ] PostgreSQL is managed (RDS, Cloud SQL, etc.), not a container in prod
- [ ] Redis is managed (ElastiCache, Memorystore, etc.), not a container in prod
- [ ] Official Helm chart used for Kubernetes deployment
- [ ] `TRIGGER_API_URL` and `TRIGGER_ACCESS_TOKEN` configured in CI secrets
- [ ] TLS termination configured for the Trigger.dev API endpoint
- [ ] Resource limits and requests set on all Kubernetes pods
- [ ] Health check endpoints verified (liveness and readiness probes)

### Go-Live Verification Checklist

- [ ] Smoke run triggered and completed successfully after deploy
- [ ] Task logs emit structured metadata (task id, run id, timestamps)
- [ ] Idempotency verified: duplicate trigger produces no duplicate side effects
- [ ] Queue concurrency observed under load (no runaway parallelism)
- [ ] Rollback procedure documented and tested
- [ ] Alerting configured for task failure rate and queue depth
- [ ] `trigger.config.ts` reviewed and committed to version control

---

## Definition of Done

1. Task exports are named and IDs are stable.
2. External payload entry points enforce schemas.
3. Idempotency keys are deterministic and documented.
4. Queue and retry settings match downstream constraints.
5. `trigger.config.ts` is explicit and reviewed.
6. Self-host mode matches environment: Docker local, Kubernetes production.
7. CI uses `TRIGGER_API_URL` and `TRIGGER_ACCESS_TOKEN`.
8. Smoke run and observability checks pass after deploy.

---

## Quick Response Pattern

When implementing Trigger.dev work:

1. Confirm mode and environment (`dev/staging/prod`).
2. Draft contracts (schema, idempotency, queue/retry).
3. Implement tasks/config with named exports and focused files.
4. Provide deployment commands and verification steps.
5. Provide rollback/safety notes for production changes.
