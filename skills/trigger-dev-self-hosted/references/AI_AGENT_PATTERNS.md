# Trigger.dev AI Agent Patterns

Use this pattern when implementing LLM-driven workflows on Trigger.dev.

## Agent Reliability Rules

1. Bound model/tool loops with `maxSteps`, timeout, and stop conditions.
2. Persist intermediate state needed for retries and restarts.
3. Isolate irreversible side effects into dedicated tasks.
4. Require human approval for destructive or high-cost actions.
5. Emit metadata for model, prompt version, and key tool decisions.

## Recommended Task Decomposition

- Planner task: classify request, choose strategy, emit a machine-readable plan.
- Executor task(s): call tools with strict typed input/output contracts.
- Reviewer task: run policy checks and quality gates.
- Publisher task: perform final side effects (write, send, webhook).

This decomposition keeps retries and rollbacks targeted.

## Human-In-The-Loop Gate

Place approvals at the boundary right before side effects:

- Data mutation across many records.
- External notifications to customers.
- Payments, billing, or quota-expensive operations.

Approval tasks should include:

- Proposed action summary.
- Impact scope (tenant/user/resource counts).
- Rollback strategy if available.

## Observability Minimum For Agents

Log and tag each run with:

- `tenantId` (if multi-tenant).
- `agentWorkflowId` or task family.
- `model`, `temperature`, and relevant prompt version.
- Outcome classification (`success`, `policy_blocked`, `retry_exhausted`, `failed`).

## Common Failure Modes

| Failure mode | Symptom | Mitigation |
|---|---|---|
| Unbounded loops | Cost spikes and long runtimes | Enforce `maxSteps`, timeout budget |
| Non-deterministic side effects | Duplicate writes | Add idempotency at side-effect boundary |
| Hidden policy breaks | Silent risky output | Insert reviewer/policy task before publish |
| Poor postmortems | Hard to reconstruct agent path | Record plan/tool decisions in metadata |
