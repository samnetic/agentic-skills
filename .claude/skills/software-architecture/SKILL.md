---
name: software-architecture
description: >-
  Software architecture and system design skill for architecture decision
  records, architecture design documents, and non-functional requirement
  modeling. Use when evaluating architecture options, defining boundaries,
  setting measurable quality targets, and producing audience-specific design
  artifacts. Triggers: architecture design, system design, ADR, NFR,
  scalability, resilience, distributed systems, C4, trade-off analysis.
license: MIT
metadata:
  author: samnetic
  version: "1.0"
---

# Software Architecture

Produce architecture artifacts that make trade-offs explicit and execution-safe.

## Core Principles

| Principle | Meaning |
|---|---|
| Decisions over diagrams | An architecture is the sum of its decisions, not its boxes and arrows. Capture *why* before *what*. |
| Constraints first | Every design starts from constraints (budget, team size, latency SLA, compliance). Patterns follow constraints, not the reverse. |
| Explicit trade-offs | Every option gains something and loses something. Make both visible so stakeholders can choose, not guess. |
| Fitness over perfection | Define measurable quality attributes (NFRs) and validate them continuously; do not chase an ideal end-state. |
| Reversibility by default | Prefer decisions that can be cheaply reversed. Flag irreversible choices for extra scrutiny. |
| Boundary ownership | Every component, service, or module has exactly one owning team. Shared ownership is no ownership. |
| Evolutionary architecture | Design for change: feature flags, anti-corruption layers, contract tests. Big-bang rewrites are a last resort. |

## Workflow

1. Frame the problem, constraints, and quality attributes.
2. Evaluate at least two architecture options with trade-offs.
3. Select a recommendation and draft/update ADRs.
4. Define implementation boundaries, rollout plan, and observability.
5. Validate design against quality gates.

## Progressive Disclosure Map

| Reference | Path | When to read |
|---|---|---|
| Full design doc template | [references/architecture-design-doc-template.md](references/architecture-design-doc-template.md) | Starting a new architecture design document from scratch |
| ADR format | [references/adr-template.md](references/adr-template.md) | Recording or updating a specific architecture decision |
| C4 communication checklist | [references/c4-checklist.md](references/c4-checklist.md) | Producing or reviewing C4 diagrams for stakeholder communication |
| NFR metrics and fitness checks | [references/nfr-fitness-catalog.md](references/nfr-fitness-catalog.md) | Defining measurable quality attributes or fitness functions |
| Risk register format | [references/risk-register-template.md](references/risk-register-template.md) | Cataloguing risks, likelihood, impact, and mitigations |

## Decision Tree — Choosing an Architecture Pattern

Use the following tree when the user asks "which architecture should we use?"

1. **How many teams will build and operate this system?**
   - One team (<=8 people) --> start with a **Modular Monolith**.
   - Multiple teams with independent release cadences --> consider service boundaries (step 2).
2. **Do components have different scalability or availability requirements?**
   - No --> **Modular Monolith** with clear module boundaries.
   - Yes --> **Service-Oriented Architecture** (SOA) or **Microservices** (step 3).
3. **Is the domain well-understood with stable bounded contexts?**
   - No --> **SOA with coarser services**; refine boundaries as understanding grows.
   - Yes --> **Microservices** per bounded context.
4. **Is there heavy asynchronous or event-driven workload?**
   - Yes --> layer an **Event-Driven Architecture** (Kafka/NATS/SQS) on top of service topology.
   - No --> synchronous REST/gRPC is sufficient.
5. **Are there strict latency requirements (<10 ms P99)?**
   - Yes --> co-locate hot paths; avoid network hops. Consider **CQRS** to separate read/write models.
   - No --> standard request/response is fine.
6. **Regulatory / data-residency constraints?**
   - Yes --> **Cell-Based Architecture** or region-scoped deployments.
   - No --> single-region or multi-AZ is likely enough.

Always document the decision and reasoning in an ADR.

## ADR Template (Concrete Example)

```markdown
# ADR-NNN: Choose modular monolith over microservices

## Status
Accepted

## Date
2026-03-12

## Context
We are a single team of 6 engineers building an order-management
system. Expected peak load is 200 RPS. The domain model is still
evolving as we onboard new fulfilment partners.

## Decision
We will build a modular monolith deployed as a single unit, with
explicit module boundaries enforced by ArchUnit tests. Modules
communicate through an in-process event bus (no direct imports
across module boundaries).

## Consequences
- **Positive**: Simpler deployment, easier debugging, single DB
  transaction scope.
- **Negative**: All modules share the same scaling profile; a
  CPU-heavy reporting module may need extraction later.
- **Risks**: Module coupling may creep without lint enforcement.
  Mitigated by CI architecture fitness checks.

## Review Trigger
Revisit when team count exceeds 2 or peak load exceeds 1 000 RPS.
```

## Audience Modes

| Mode | Reader | Goal | Word Budget |
|---|---|---|---:|
| `exec` | CTO/founder | Strategic trade-off + investment decision | <= 700 |
| `product` | PM/BA | Product constraints and delivery impact | <= 1100 |
| `engineering` | Eng lead/team | Buildable architecture and boundaries | <= 1800 |
| `architecture-review` | Staff/principal/security | Decision rationale + risks + controls | <= 2200 |

Default to `engineering` unless the user asks for a decision brief.

## Output Contract

Every architecture response must include:

1. `Context and Constraints`
2. `Quality Targets` (NFR metrics with numbers)
3. `Options Considered` (at least 2)
4. `Recommended Architecture`
5. `Boundary and Ownership Model`
6. `Risks and Mitigations`
7. `Rollout and Validation Plan`
8. `ADR Delta` (new ADR or updates required)

If diagrams are requested, provide a Mermaid C4-level summary plus narrative.

## Quality Gates

- NFRs are measurable (metric + threshold + validation method).
- At least two viable options are compared.
- Recommendation traces back to stated constraints.
- Component boundaries and ownership are explicit.
- Failure modes for critical dependencies are documented.
- Security/privacy constraints are represented where relevant.
- Rollout plan includes verification and rollback criteria.
- Output stays within chosen audience word budget.

## Anti-Patterns

| Anti-Pattern | Why It's Dangerous | Fix |
|---|---|---|
| Resume-Driven Architecture | Choosing tech/patterns to pad resumes, not to solve the problem. Leads to unnecessary complexity. | Start from constraints and quality attributes; justify every pattern with a measurable benefit. |
| Distributed Monolith | Services are deployed independently but coupled at the data or API layer; you get the pain of microservices with none of the benefits. | Enforce contract tests, eliminate shared databases, define clear API boundaries per bounded context. |
| Golden Hammer | Applying one familiar pattern everywhere (e.g., event sourcing for a simple CRUD app). | Match pattern to problem characteristics; use the Decision Tree above. |
| Infinite Abstraction | Creating layers of abstraction "just in case" (Repository -> Service -> Facade -> Controller -> Gateway). | Apply YAGNI; add indirection only when you have two or more concrete reasons. |
| Big-Bang Migration | Rewriting an entire system at once, delivering zero value until "done". | Strangle Fig pattern: migrate incrementally behind feature flags with traffic shifting. |
| Accidental Public API | Internal implementation details leak through APIs and become impossible to change. | Define explicit public contracts; hide internals behind anti-corruption layers. |
| Cargo-Cult DDD | Using DDD vocabulary (aggregates, value objects) without understanding bounded contexts or ubiquitous language. | Start with context mapping and event storming before naming tactical patterns. |

## Architecture Review Checklist

Use before finalizing any architecture document or ADR.

- [ ] Problem statement and constraints are written down and agreed upon.
- [ ] At least two viable options were evaluated with explicit trade-offs.
- [ ] Quality attributes have numeric targets (e.g., P99 latency < 200 ms).
- [ ] Each quality attribute has a validation method (load test, synthetic monitor, fitness function).
- [ ] Component/module/service boundaries are drawn with owning team assigned.
- [ ] Data flow and storage ownership are explicit (no shared databases across boundaries).
- [ ] Failure modes for every external dependency are documented with mitigation.
- [ ] Security and privacy constraints are addressed (auth, encryption, data residency).
- [ ] Migration/rollout plan includes feature flags, traffic shifting, or canary strategy.
- [ ] Rollback criteria and procedure are defined.
- [ ] ADR is written or updated with status, context, decision, and consequences.
- [ ] Diagram (C4 level 2 minimum) matches the narrative description.
- [ ] Document stays within the chosen audience word budget.

## Common Failure Modes

- Choosing patterns by trend instead of constraints.
- Describing components without ownership boundaries.
- Listing NFRs without test/monitoring strategy.
- Ignoring migration and rollback in rollout plans.

## Escalation Rules

- If requirements are unclear, loop through `business-analysis` first.
- If final document readability/format is weak, run
  `technical-writing` cleanup before handoff.
