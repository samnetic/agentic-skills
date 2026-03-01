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
---

# Trigger.dev Self-Hosted Production Skill

Build Trigger.dev systems that are durable, observable, and safe at production scale.
Treat self-hosted production as a platform problem, not only a task-authoring problem.

## Read-First Map

Read only the references needed for the user request:

- Setup, profiles, and mode selection: [references/SETUP_AND_MODES.md](references/SETUP_AND_MODES.md)
- Task design and coding standards: [references/TASK_DESIGN.md](references/TASK_DESIGN.md)
- AI agent orchestration patterns: [references/AI_AGENT_PATTERNS.md](references/AI_AGENT_PATTERNS.md)
- Self-hosting runbook (Docker local + Kubernetes prod): [references/SELF_HOSTING.md](references/SELF_HOSTING.md)
- CI/CD for self-hosted Trigger.dev: [references/CICD_SELF_HOSTED.md](references/CICD_SELF_HOSTED.md)

## Non-Negotiable Rules

1. Use named task exports. Do not default-export tasks.
2. Keep task `id` values stable after release; create a new `id` for breaking changes.
3. Enforce input schemas on external payload entry points (prefer `schemaTask` + `zod`).
4. Use deterministic idempotency keys for externally-triggered operations.
5. Use queue names and explicit concurrency limits for side-effecting workflows.
6. Treat Docker Compose as local/dev only; use Kubernetes for production self-hosting.
7. In CI for self-hosted deployments, use `TRIGGER_API_URL` and `TRIGGER_ACCESS_TOKEN`.

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

## Anti-Patterns

| Anti-pattern | Why it fails | Correct approach |
|---|---|---|
| Giant task mixing many side effects | Unsafe retries and poor debuggability | Split by workflow boundaries |
| Random idempotency keys | Duplicate work still occurs | Deterministic business-identity keys |
| Unlimited concurrency | Throttling and cascading failures | Queue + explicit concurrency limits |
| Production on ad-hoc Compose | Weak HA, upgrade, and recovery posture | Kubernetes + Helm + managed stateful deps |
| Silent catch-and-continue | Hidden corruption and operator blind spots | Structured errors + explicit compensation |

## Definition of Done

1. Task exports are named and IDs are stable.
2. External payload entry points enforce schemas.
3. Idempotency keys are deterministic and documented.
4. Queue and retry settings match downstream constraints.
5. `trigger.config.ts` is explicit and reviewed.
6. Self-host mode matches environment: Docker local, Kubernetes production.
7. CI uses `TRIGGER_API_URL` and `TRIGGER_ACCESS_TOKEN`.
8. Smoke run and observability checks pass after deploy.

## Quick Response Pattern

When implementing Trigger.dev work:

1. Confirm mode and environment (`dev/staging/prod`).
2. Draft contracts (schema, idempotency, queue/retry).
3. Implement tasks/config with named exports and focused files.
4. Provide deployment commands and verification steps.
5. Provide rollback/safety notes for production changes.
