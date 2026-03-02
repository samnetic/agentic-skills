---
name: spec-orchestrator
description: >-
  Orchestrate high-quality specification and documentation workflows across
  product, business analysis, and architecture audiences. Use when users ask for
  PRDs, requirement specs (functional/non-functional), architecture design docs,
  ADR packs, implementation plans, or document refactors for clarity and
  audience-fit structure. Triggers: specification, spec, PRD, BRD, SRS, FRS,
  NFR, architecture doc, design doc, ADR, implementation plan, requirements.
---

# Spec Orchestrator

Route each request to the minimum set of spec/document skills needed to produce
audience-fit, decision-ready artifacts.

## Workflow

1. Identify artifact type, audience, and decision purpose.
2. Choose route: BA-led, architecture-led, or writing-led.
3. Build draft with required sections and word budget.
4. Run cross-skill quality checks.
5. Deliver final artifact plus next actions.

## Required Inputs

- Target artifact type (PRD, requirement spec, architecture design doc, ADR)
- Primary audience (`exec`, `product`, `engineering`, `architecture-review`)
- Business context and scope boundaries
- Known constraints (timeline, compliance, stack, org)
- Requested depth (brief, standard, full)

## Progressive Disclosure Map

- Routing matrix: [references/routing-matrix.md](references/routing-matrix.md)
- Artifact contracts: [references/artifact-output-contracts.md](references/artifact-output-contracts.md)
- Clarification questions: [references/clarification-questions.md](references/clarification-questions.md)
- Quality review checklist: [references/cross-skill-quality-checklist.md](references/cross-skill-quality-checklist.md)

## Execution Protocol

### 1) Route Selection

Pick the dominant route before drafting:

- **BA-led route**: problem framing, scope, FR/NFR, acceptance, prioritization.
  Primary skill: `business-analysis`.
- **Architecture-led route**: option analysis, boundaries, NFR fitness, risks,
  ADR changes. Primary skill: `software-architecture`.
- **Writing-led route**: structure, readability, audience adaptation, and final
  compression. Primary skill: `technical-writing`.

Use at most two secondary skills unless the user explicitly requests a full
multi-audience package.

### 2) Draft Strategy

- Create one primary artifact for the main audience.
- Add appendices for secondary audiences instead of separate full documents.
- Reuse table-based sections for precision and brevity.

### 3) Clarification Loop

If critical data is missing, ask only the smallest set of targeted questions
needed to continue. Use the clarification reference file.

### 4) Quality Pass

Run the cross-skill checklist before delivery. If any blocking gate fails,
revise before final output.

## Output Contract

Every orchestrated output must include:

1. `Artifact Type and Audience`
2. `Decision Goal`
3. `Core Content` using selected artifact contract
4. `Assumptions and Open Questions`
5. `Quality Gate Result` (pass/fail by gate)
6. `Recommended Next Actions`

When asked for “full pack”, deliver in this order:

1. executive brief
2. primary spec
3. architecture appendix (if applicable)
4. implementation-ready checklist

## Quality Gates

- Route choice is explicit and justified.
- Scope boundaries are explicit (`in` and `out`).
- Functional and non-functional requirements are testable where applicable.
- Architecture recommendations compare at least two viable options.
- Content fits the target audience and selected depth.
- Document stays within target word budget.
- No unresolved critical ambiguity is hidden in prose.

## Anti-Patterns

- Producing one generic long document for all audiences.
- Mixing discovery notes with finalized requirements without labeling.
- Architecture recommendations without constraints or option comparison.
- Quality claims without measurable thresholds.

## Handoff Guidance

- Use `business-analysis` for requirement depth.
- Use `software-architecture` for design trade-offs and ADR deltas.
- Use `technical-writing` for final structure and compression pass.
