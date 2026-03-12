---
name: product-marketing-context
description: >-
  Shared product and market context management for software products. Use when
  creating or updating canonical context used across positioning, pricing, SEO,
  copywriting, launch planning, and growth experiments. Triggers: product
  context, marketing context, ICP context, messaging baseline, shared context
  doc, go-to-market context, positioning context.
---

# Product Marketing Context

Maintain one canonical source of truth for market and messaging assumptions so every downstream skill — positioning, pricing, SEO, copywriting, launch, growth — starts from the same verified facts.

## Core Principles

| Principle | Meaning |
|---|---|
| Single source of truth | One file holds all shared context; duplicates are deleted on sight |
| Evidence over opinion | Every claim is tagged as **fact** (data-backed) or **assumption** (needs validation) |
| ICP clarity | Best-fit and excluded segments are always explicit; ambiguity invites waste |
| Living document | Context is reviewed on a fixed cadence; stale context is worse than none |
| Minimal viable context | Include only what downstream skills actually consume; trim the rest |
| Change transparency | Every edit carries a dated change-log entry with rationale |

## Decision Tree — Choosing the Right Marketing Approach

Use this tree when you are unsure which marketing skill to invoke or which section of the context doc to update first.

```
START
 │
 ├─ Do you have a written ICP with explicit exclusions?
 │   ├─ NO  → Run ICP Discovery (Section: ICP and Non-ICP) first
 │   └─ YES
 │       │
 │       ├─ Can you name the top 3 alternatives buyers evaluate?
 │       │   ├─ NO  → Run Competitive Mapping (Section: Problem and Alternatives)
 │       │   └─ YES
 │       │       │
 │       │       ├─ Is your differentiation tied to a measurable outcome?
 │       │       │   ├─ NO  → Use → positioning-brand-system skill
 │       │       │   └─ YES
 │       │       │       │
 │       │       │       ├─ Is pricing/packaging documented and current?
 │       │       │       │   ├─ NO  → Use → pricing-strategy skill
 │       │       │       │   └─ YES
 │       │       │       │       │
 │       │       │       │       ├─ Ready for launch or campaign?
 │       │       │       │       │   ├─ YES → Use → launch-strategy skill
 │       │       │       │       │   └─ NO  → Use → growth-experiment-lab skill
 │       │       │       │       │          for incremental tests
```

## Workflow

1. Collect current product facts and constraints.
2. Define ICP and non-ICP segments.
3. Document core problem, alternatives, and differentiation.
4. Capture pricing motion, GTM channels, and proof assets.
5. Draft or update the messaging baseline.
6. Publish and version a single context file.
7. Review and refresh on a fixed cadence (default: every 4 weeks).

## Required Inputs

- Product capabilities and roadmap constraints
- Best-fit customers and buying process
- Competitive alternatives and positioning stance
- Current GTM, pricing, and activation motion
- Recent customer language (support tickets, sales call transcripts, reviews)

## Progressive Disclosure Map

| Reference | Path | When to read |
|---|---|---|
| Primary artifact template | [references/context-template.md](references/context-template.md) | First time creating a context doc, or when adding a new section |
| Update checklist | [references/context-update-checklist.md](references/context-update-checklist.md) | Before every scheduled refresh or after a major product/market change |

## Execution Protocol

Create or update `.agents/product-marketing-context.md` using the template.

### 1) Product Snapshot

- Capture product name, category, stage, last-updated date, and owner.
- Keep this section factual; no aspirational language.

### 2) ICP and Non-ICP

- Define best-fit segment, buyer roles, trigger events, and urgent pains.
- List excluded segments with explicit reasons.
- Tag each attribute as **fact** or **assumption**.

### 3) Problem and Alternatives

- State the core problem in buyer language, not product language.
- List current alternatives (competitors, manual workarounds, status quo).
- Explain why each alternative fails for the ICP.

### 4) Differentiation and Proof

- State the primary differentiator as a measurable outcome.
- Provide at least two proof points (case studies, benchmarks, testimonials).
- If proof is missing, record the gap and planned validation step.

### 5) Pricing and GTM

- Document packaging model, current pricing motion, and main acquisition channels.
- Describe the activation motion (free trial, demo, PLG, sales-led).

### 6) Messaging Baseline

- Draft or reference the master narrative, headline direction, and objection handling.
- Link to the positioning-brand-system artifact if one exists.

### 7) Risks and Unknowns

- List assumptions at risk, data gaps, and planned validation.
- Assign an owner and target date for each open item.

## Context File Template (Quick Start)

Use this YAML front-matter block at the top of your context doc to make it machine-parseable by other skills:

```yaml
# .agents/product-marketing-context.md front-matter
---
product: "Acme Deploy"
category: "Developer Platform"
stage: "Growth"
last_updated: "2026-03-12"
owner: "@jane"
review_cadence: "every 4 weeks"
next_review: "2026-04-09"
icp:
  segment: "Series A–B SaaS engineering teams (10–50 devs)"
  buyer_role: "VP Engineering / Platform Lead"
  trigger_event: "Failed deploy blocks release for >4 hours"
  top_pain: "Deploy rollbacks are manual and take 30+ minutes"
non_icp:
  - segment: "Solo developers"
    reason: "No team coordination need; free-tier only"
  - segment: "Enterprise (>500 devs)"
    reason: "Require FedRAMP; not on roadmap until 2027"
differentiation:
  primary: "One-click rollback in <60 seconds with zero-downtime guarantee"
  proof:
    - type: "case_study"
      detail: "Loom reduced MTTR from 38 min to 52 sec"
    - type: "benchmark"
      detail: "99.97% rollback success rate across 12k deploys"
---
```

## Output Contract

Deliver:

1. Updated `.agents/product-marketing-context.md` with YAML front-matter and all seven sections.
2. Change-log entry at the bottom of the file (date, author, what changed, why).
3. Next review date and owner recorded in front-matter.

## Quality Gates

- ICP/non-ICP boundaries are explicit and tagged as fact or assumption.
- Claims are backed by evidence or labeled assumptions with a validation plan.
- Pricing/GTM sections reflect current operating reality, not aspirational plans.
- Messaging baseline is present or linked to the positioning-brand-system artifact.
- Last-updated date and next-review date are both set.
- Change-log contains an entry for the current edit.

## Pre-Publish Checklist

Before sharing or merging an updated context doc, verify every item:

- [ ] Product snapshot (name, category, stage) is accurate
- [ ] ICP segment, roles, trigger event, and pains are filled in
- [ ] Non-ICP segments are listed with exclusion reasons
- [ ] Every claim is tagged **fact** or **assumption**
- [ ] At least two proof points support the primary differentiator
- [ ] Competitive alternatives list has been reviewed in the last 30 days
- [ ] Pricing and packaging match what is live in production
- [ ] Messaging baseline or positioning-brand-system link is present
- [ ] Risks/unknowns each have an owner and target date
- [ ] YAML front-matter `last_updated` and `next_review` are set
- [ ] Change-log entry for this update is appended
- [ ] No conflicting duplicate context exists in other files

## Anti-Patterns

| Anti-Pattern | Why It Hurts | Fix |
|---|---|---|
| Duplicate conflicting context files | Downstream skills pick up stale or contradictory data | Delete duplicates; link to the single canonical file |
| Mixing aspiration with current truth | Messaging oversells; sales and support lose trust | Tag each claim as **fact** or **assumption** |
| Omitting non-ICP boundaries | Marketing spends budget on low-fit segments | Always define who you are *not* for |
| Never refreshing the doc | Context drifts from reality within weeks | Set a cadence in front-matter; enforce via checklist |
| Proof-free differentiation claims | Positioning collapses under buyer scrutiny | Require at least two proof points or flag the gap |

