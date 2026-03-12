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

## Core Principles

| Principle | Meaning |
|---|---|
| Audience-first | Every artifact targets one primary reader; secondary audiences get appendices, not separate docs |
| Decision-ready | A spec exists to enable a specific decision; if no decision is clearer after reading, the spec failed |
| Minimum viable scope | Include only what the audience needs to decide; defer everything else to appendices or follow-ups |
| Testable requirements | Every FR has acceptance criteria; every NFR has a numeric target and validation method |
| Explicit routing | State which skill leads and why before drafting begins; never drift between routes mid-document |
| Budget discipline | Agree on word/page budget up-front; compress ruthlessly during the quality pass |

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

| Reference | Path | When to read |
|---|---|---|
| Routing matrix | [references/routing-matrix.md](references/routing-matrix.md) | At start of every request to select the correct route |
| Artifact contracts | [references/artifact-output-contracts.md](references/artifact-output-contracts.md) | After route selection to load required sections for the artifact type |
| Clarification questions | [references/clarification-questions.md](references/clarification-questions.md) | When critical inputs are missing and you need targeted questions |
| Quality review checklist | [references/cross-skill-quality-checklist.md](references/cross-skill-quality-checklist.md) | Before delivering any final artifact to verify all gates pass |

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

## Spec Template Example

Use this skeleton when producing a PRD. Adapt sections per the artifact contract
for other document types.

```markdown
# PRD: [Feature Name]

## Meta
- **Audience:** [exec | product | engineering | architecture-review]
- **Decision goal:** [What this document should enable the reader to decide]
- **Route:** [BA-led | Architecture-led | Writing-led]
- **Word budget:** [e.g., 1500 words]
- **Status:** [Draft | Review | Approved]

## 1. Problem & Outcome
[2-3 sentences: what pain exists, what success looks like]

## 2. Scope
| In scope | Out of scope |
|----------|-------------|
| Item A   | Item X      |
| Item B   | Item Y      |

## 3. Functional Requirements
| ID    | Requirement           | Acceptance Criteria              | Priority |
|-------|-----------------------|----------------------------------|----------|
| FR-01 | User can reset password | Email sent within 30 s; link expires in 1 h | Must |
| FR-02 | ...                   | ...                              | Should   |

## 4. Non-Functional Requirements
| ID     | Category    | Target          | Validation Method       |
|--------|-------------|-----------------|-------------------------|
| NFR-01 | Latency     | p95 < 200 ms    | Load test (k6, 500 RPS) |
| NFR-02 | Availability | 99.9 % monthly  | Uptime monitor          |

## 5. Dependencies, Risks & Assumptions
- **Dependency:** Auth service v2 API must be deployed first.
- **Risk:** Third-party email provider SLA is 99.5 %.
- **Assumption:** Existing user table schema is unchanged.

## 6. Success Metrics
| Metric              | Baseline | Target | Measurement        |
|---------------------|----------|--------|--------------------|
| Password reset rate | 12 %     | 25 %   | Analytics dashboard |

## 7. Next Actions
| Action                  | Owner       | Horizon    |
|-------------------------|-------------|------------|
| Engineering sizing      | Tech Lead   | Sprint +1  |
| Security review         | SecOps      | Sprint +1  |
```

## Delivery Checklist

Run through before handing any artifact to the requester.

- [ ] Route (BA / Architecture / Writing) is stated and justified
- [ ] Primary audience and decision goal are in the document header
- [ ] Scope table has both "in" and "out" columns filled
- [ ] Every FR has an acceptance criterion
- [ ] Every NFR has a numeric target and a validation method
- [ ] Architecture options compared (at least two) when design decisions are present
- [ ] Assumptions and open questions are surfaced, not buried in prose
- [ ] Word count is within the agreed budget
- [ ] Next-actions table includes owner and time horizon
- [ ] Cross-skill quality checklist (reference file) passes with no blocking failures

## Anti-Patterns

- Producing one generic long document for all audiences.
- Mixing discovery notes with finalized requirements without labeling.
- Architecture recommendations without constraints or option comparison.
- Quality claims without measurable thresholds.

## Handoff Guidance

- Use `business-analysis` for requirement depth.
- Use `software-architecture` for design trade-offs and ADR deltas.
- Use `technical-writing` for final structure and compression pass.
