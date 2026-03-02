---
name: startup-first-principles
description: >-
  First-principles startup and product strategy for software founders. Use when
  deciding what to build, evaluating business opportunities, choosing target
  segments, framing critical assumptions, planning validation experiments, or
  making build/pivot/kill decisions. Triggers: first principles, startup
  strategy, entrepreneurship, opportunity sizing, thesis, assumption mapping,
  validation plan, pivot decision, founder strategy, product thesis.
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

- Decomposition workflow: [references/first-principles-decomposition.md](references/first-principles-decomposition.md)
- Evidence and validation design: [references/evidence-and-tests.md](references/evidence-and-tests.md)
- Decision memo template: [references/strategy-memo-template.md](references/strategy-memo-template.md)

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

## Hand-off Guidance

- Use `business-analysis` for PRD decomposition after strategy lock.
- Use `pricing-strategy` and `page-cro` from `external-skills/reused/` once value proposition is validated.
