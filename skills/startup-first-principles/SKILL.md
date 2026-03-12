---
name: startup-first-principles
description: >-
  First-principles startup and product strategy for software founders. Use when
  deciding what to build, evaluating business opportunities, choosing target
  segments, framing critical assumptions, planning validation experiments, or
  making build/pivot/kill decisions. Triggers: first principles, startup
  strategy, entrepreneurship, opportunity sizing, thesis, assumption mapping,
  validation plan, pivot decision, founder strategy, product thesis.
license: MIT
metadata:
  author: samnetic
  version: "1.0"
---

# Startup First Principles

Make strategy decisions from fundamentals instead of trend-following.

## Workflow

1. Define the objective and decision horizon.
2. Decompose the problem into first principles.
3. Convert assumptions into falsifiable hypotheses.
4. Rank hypotheses by value, risk, and reversibility.
5. Design minimum-cost tests that change decisions.
6. Decide: commit, iterate, pivot, or stop.

## Required Inputs

- Product and user context
- Current constraints (time, cash, team, distribution)
- Candidate opportunities or strategic options
- Decision deadline and owner

## Progressive Disclosure Map

| Reference | When to read |
|---|---|
| [references/first-principles-decomposition.md](references/first-principles-decomposition.md) | Steps 1-2: scoping the decision and decomposing to fundamentals |
| [references/evidence-and-tests.md](references/evidence-and-tests.md) | Steps 3-4: building the assumption register and planning validation |
| [references/strategy-memo-template.md](references/strategy-memo-template.md) | Step 5: producing the final decision memo |

Load only the file needed for the current step.

## Execution Protocol

### 1) Define Decision Scope

- State one concrete decision question.
- State one decision deadline.
- State one success metric and one failure metric.
- Set the required confidence threshold before deciding.

### 2) Decompose to Fundamentals

- Separate facts, assumptions, and constraints.
- Isolate value creation, value capture, and distribution mechanics.
- Identify the bottleneck that blocks progress now.

### 3) Build the Assumption Register

For each assumption, document:

- Why it matters
- Current evidence quality
- Cost of being wrong
- Fastest test that can disconfirm it

```yaml
# Assumption Register — example entry
assumptions:
  - id: A1
    statement: "RevOps managers spend >5 hrs/week on manual data reconciliation"
    evidence_tier: E1          # E0=opinion, E1=anecdotal, E2=pattern, E3=behavioral, E4=repeated
    confidence: 0.3
    cost_if_wrong: high        # low | medium | high | fatal
    impact_area: value-creation
    test:
      type: problem-interview
      sample_size: 12
      success_threshold: ">=8/12 confirm >5 hrs AND rate pain >=4/5"
      failure_threshold: "<5/12 confirm"
      max_cost: "$0 + 6 hours founder time"
      deadline: "2026-03-26"
    status: untested            # untested | in-progress | passed | failed
    decision_if_fail: "Pivot to adjacent segment (FinOps) or kill workstream"
```

### 4) Plan Validation Sequence

- Run cheap and high-learning tests first.
- Prefer tests that invalidate multiple assumptions at once.
- Define stop conditions before running each test.

### 5) Produce a Decision Memo

Use the memo template and include:

- Decision taken
- Evidence summary
- Rejected alternatives and rationale
- Next checkpoint date

## Output Contract

Deliver these artifacts:

1. Assumption register with ranked risks
2. Validation plan with owner, cost, and timeline
3. One-page strategy memo with explicit decision

## Quality Gates

- Decision question is binary and time-bound.
- Assumptions are testable and ranked.
- At least one disconfirming test exists for top risks.
- Decision memo includes explicit stop/pivot criteria.

## Anti-Patterns

- Starting with solution features before problem proof.
- Treating opinions as evidence.
- Running experiments without predefined decision rules.
- Continuing after stop criteria have been met.

## Checklist

Use before finalizing any strategic decision.

- [ ] Decision question is stated as a single binary, time-bound question
- [ ] Decision owner and deadline are named
- [ ] Success metric and failure metric are defined with numeric thresholds
- [ ] Problem decomposed into value creation, value capture, and distribution
- [ ] Hard constraints separated from soft constraints
- [ ] Dominant bottleneck identified (demand / activation / retention / monetization / delivery)
- [ ] Assumption register contains at least 3 ranked assumptions
- [ ] Every top-3 assumption has at least one disconfirming test designed
- [ ] Each test has pre-defined success threshold, failure threshold, and cost cap
- [ ] Evidence tier recorded for every assumption (no irreversible decisions on E0-E1)
- [ ] Validation sequence ordered by cost (cheapest first)
- [ ] Stop/pivot criteria written before any test begins
- [ ] Decision memo completed with alternatives considered and next checkpoint date
- [ ] Hand-off skill identified for the next phase of work

## Hand-off Guidance

- Use `business-analysis` for PRD decomposition after strategy lock.
- Use `pricing-strategy` and `page-cro` from `external-skills/reused/` once value proposition is validated.
