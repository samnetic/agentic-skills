---
name: design-interface
description: >-
  Explore API and module interface designs by spawning 3+ parallel agents under
  different constraints. Each agent produces a concrete code-level interface,
  then proposals are compared on ergonomics, type safety, testability, and
  depth. Use when designing APIs, module boundaries, or service contracts.
  Triggers: design an interface, design the API, explore API designs, competing
  designs, design it twice, module interface, service contract design.
license: MIT
metadata:
  author: samnetic
  version: "1.0"
---

# Design Interface

Spawn 3+ competing designers under different constraints, each producing a
concrete code-level interface, then compare proposals and synthesize the best
approach into an ADR.

## Core Principles

| Principle | Meaning |
|---|---|
| Depth over surface area | A good module has a small interface hiding significant complexity (Ousterhout). Score every design by depth = implementation complexity / interface size |
| Competing constraints reveal tradeoffs | A single design attempt hides assumptions. Multiple designs under different lenses expose what each constraint costs |
| Concrete over abstract | Every proposal must include real code — types, method signatures, usage examples — not boxes-and-arrows diagrams |
| Parallel generation is mandatory | Designers must be spawned in a SINGLE message so no agent sees another's work. Sequential spawning creates anchoring bias |
| Synthesis beats selection | The final recommendation is usually a hybrid that takes the best ideas from multiple proposals, not a winner-takes-all pick |
| Testability is non-negotiable | If a design cannot be tested without mocking half the universe, it fails regardless of elegance |

## Workflow

1. **Requirements Gathering** — understand domain, stakeholders, key operations, constraints.
2. **Constraint Profile Definition** — select 3+ competing constraint lenses.
3. **Parallel Design Generation** — spawn 3+ sub-agents in a SINGLE message, each designing under their assigned constraint.
4. **Comparative Analysis** — evaluate across ergonomics, type safety, testability, extensibility, and depth ratio.
5. **Synthesis & ADR** — recommend best design or hybrid, produce an Architecture Decision Record.

## Required Inputs

- A description of the module, API, or service contract to design.
- Domain context: what the module does, who consumes it, key operations.
- Language preference (TypeScript, Python, Go, or multi-language).

Optional:
- Specific constraint profiles to include or exclude.
- Existing code or interfaces to evolve from.
- Non-functional requirements (latency, throughput, bundle-size).

## Progressive Disclosure Map

| Reference | Path | When to read |
|---|---|---|
| Constraint profiles | [references/constraint-profiles.md](references/constraint-profiles.md) | Phase 2: before selecting constraint lenses |
| Comparison matrix | [references/comparison-matrix-template.md](references/comparison-matrix-template.md) | Phase 4: before scoring proposals |
| Quality checklist | [references/interface-quality-checklist.md](references/interface-quality-checklist.md) | Phase 5: before finalizing the recommendation |

## Trigger Conditions

**Mandatory triggers** — always activate this skill:
- "design an interface"
- "design the API"
- "explore API designs"
- "competing designs"
- "design it twice"

**Strong triggers** — activate when the question involves interface decisions:
- "module interface"
- "service contract design"
- "what should the API look like"
- "how should this module expose its functionality"
- "API surface"

**Do NOT trigger on:**
- Implementing an already-decided interface
- Code review of existing interfaces (use `code-review`)
- Architecture-level system design without concrete interfaces (use `software-architecture`)
- Simple CRUD endpoint design with no real tradeoffs

## Execution Protocol

### Phase 1: Requirements Gathering

Before any design work, build a complete picture:

1. Check for `CLAUDE.md` in the workspace — extract project conventions and constraints.
2. Scan for existing interfaces, types, or contracts related to the module.
3. Identify consumers: who calls this interface? Other modules, external clients, CLI, UI?
4. Produce a **Design Brief**:

```
DESIGN BRIEF
=============
Module:       [Name and one-line purpose]
Language:     [TypeScript / Python / Go / etc.]
Consumers:    [Who calls this interface and how]
Key operations: [3-7 core operations the interface must support]
Constraints:  [Performance, backward compat, bundle size, etc.]
Existing code: [Relevant files or patterns already in the codebase]
Non-goals:    [What this interface explicitly does NOT need to handle]
```

Save this brief — it becomes the input for all designers.

### Phase 2: Constraint Profile Definition

1. Read `references/constraint-profiles.md`.
2. Select **3-5 constraint profiles** appropriate for the problem. Default set:
   - **Minimalist** — fewest methods, smallest surface area
   - **Extensibility-First** — plugin-friendly, open for extension
   - **Type-Safe-Maximum** — compile-time guarantees, branded types, discriminated unions
3. Optionally add domain-specific lenses:
   - **Performance-First** — zero-cost abstractions, no allocations on hot path
   - **DDD-Pure** — domain-driven, ubiquitous language, aggregate boundaries
4. For each selected profile, prepare the constraint brief from the reference file.

### Phase 3: Parallel Design Generation

1. Spawn **3-5 parallel sub-agents in a SINGLE message**. Use the platform's
   sub-agent tool (`Agent` in Claude Code, `spawn_agent` in Codex CLI,
   `task` in OpenCode):
   - Sub-agent 1: Constraint Profile A + Design Brief
   - Sub-agent 2: Constraint Profile B + Design Brief
   - Sub-agent 3: Constraint Profile C + Design Brief
   - (Optional) Sub-agents 4-5 for additional profiles
2. Each sub-agent must produce:
   - **Interface code** — full type definitions, method signatures, key types
   - **Usage example** — 10-20 lines showing how a consumer uses this interface
   - **Depth score** — self-assessed ratio of implementation complexity to interface size
   - **Tradeoff statement** — what this design sacrifices and what it optimizes for
3. Collect all design proposals.

**Critical:** All designers must be spawned in one message. Sequential spawning
allows later agents to anchor on earlier designs, destroying the diversity of
approaches that makes this skill valuable.

### Phase 4: Comparative Analysis

1. Read `references/comparison-matrix-template.md`.
2. Build a **comparison matrix** scoring each design (1-5) across:
   - **Ergonomics** — how natural is it for consumers to use?
   - **Type safety** — how many errors does the compiler catch?
   - **Testability** — can each operation be tested in isolation?
   - **Extensibility** — how easy to add new operations or behaviors?
   - **Depth ratio** — small interface hiding significant complexity?
   - **Consistency** — does it match existing codebase patterns?
3. Identify:
   - **Convergent ideas** — concepts that appear in 2+ designs (high confidence)
   - **Unique strengths** — ideas that only one design surfaced
   - **Deal-breakers** — designs that fail on a critical dimension
4. Present the matrix to the user before proceeding to synthesis.

### Phase 5: Synthesis & ADR

1. Read `references/interface-quality-checklist.md`.
2. Produce a **recommended interface** — usually a hybrid taking the best ideas:
   - Start from the highest-scoring design
   - Incorporate convergent ideas from other designs
   - Add unique strengths where they do not conflict
   - Verify against the quality checklist
3. Write an **Architecture Decision Record**:

```markdown
# ADR: [Module] Interface Design

## Status
Proposed

## Context
[Design brief summary — what problem, who consumes it, constraints]

## Designs Considered
### Design A: [Constraint Profile Name]
[Summary + key tradeoff]

### Design B: [Constraint Profile Name]
[Summary + key tradeoff]

### Design C: [Constraint Profile Name]
[Summary + key tradeoff]

## Comparison Matrix
| Criterion       | Design A | Design B | Design C |
|-----------------|----------|----------|----------|
| Ergonomics      |          |          |          |
| Type safety     |          |          |          |
| Testability     |          |          |          |
| Extensibility   |          |          |          |
| Depth ratio     |          |          |          |
| Consistency     |          |          |          |

## Decision
[Recommended interface — the hybrid or winning design]

## Consequences
[What this decision enables and what it costs]
```

4. Write the recommended interface code to a file the user can review.
5. Write the ADR to `adr-{module}-interface-{YYYYMMDD}.md` in the working directory.

## Quality Gates

- [ ] Design brief captures domain, consumers, key operations, and constraints
- [ ] 3+ designers spawned in a single parallel message (no sequential anchoring)
- [ ] Each design includes real code — types, signatures, and a usage example
- [ ] Depth ratio scored for every design (implementation complexity / interface size)
- [ ] Comparison matrix covers all 6 criteria with scores and justification
- [ ] Recommended design verified against the interface quality checklist
- [ ] ADR written with all sections populated
- [ ] Recommended interface code written to a reviewable file

## Anti-Patterns

| Anti-Pattern | Why It's Dangerous | Fix |
|---|---|---|
| Sequential designer spawning | Later agents anchor on earlier designs, destroying diversity of approaches | Always spawn all designers in a single parallel message |
| Abstract-only proposals | Designs without code are untestable opinions — you cannot evaluate ergonomics from a description | Require full type definitions and usage examples from every agent |
| Skipping depth analysis | Shallow interfaces with thin wrappers add indirection without value | Score depth ratio for every design; reject depth < 2 |
| Winner-takes-all selection | Picking one design wholesale misses the best ideas from runners-up | Default to hybrid synthesis; justify if selecting a single design |
| Ignoring existing patterns | A brilliant interface that contradicts codebase conventions creates friction | Always score consistency; adapt the recommendation to local patterns |
| Single language bias | Designing in TypeScript when the consumer is Python wastes the exercise | Match language to the actual project; offer multi-language if mixed |
| Too many constraint profiles | More than 5 profiles dilutes focus and makes comparison unwieldy | Default to 3; go to 5 only for complex cross-cutting modules |

## Delivery Checklist

- [ ] Design brief was framed with domain, consumers, operations, and constraints
- [ ] Constraint profiles were selected and documented
- [ ] 3+ designers convened in parallel with concrete constraint briefs
- [ ] Each designer produced interface code, usage example, depth score, and tradeoff statement
- [ ] Comparison matrix built and presented to user
- [ ] Hybrid or winning design synthesized with justification
- [ ] Quality checklist verified against recommended interface
- [ ] ADR written with all sections populated
- [ ] Recommended interface code written to a reviewable file
- [ ] File paths reported to user
