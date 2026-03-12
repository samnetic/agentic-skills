---
name: positioning-brand-system
description: >-
  Positioning, branding, and messaging system design for software products. Use
  when defining ICP, category, differentiation, brand narrative, message
  hierarchy, voice rules, homepage messaging, or sales narrative alignment.
  Triggers: branding, positioning, messaging, value proposition, ICP, category
  design, differentiation, brand voice, narrative, tagline, homepage message,
  founder story, go-to-market message.
---

# Positioning Brand System

Build a coherent positioning and messaging system that aligns product, marketing, and sales.
Positioning is not a tagline exercise — it is a strategic decision that determines which deals you win,
which channels work, and which messages resonate. Get it wrong and every downstream asset underperforms.

---

## Core Principles

| Principle | Meaning |
|---|---|
| **Context over claims** | Positioning sets the buying context so the value is obvious before you state it |
| **Best-fit, not biggest market** | Define the tightest ICP where you win decisively, then expand |
| **Differentiation through alternatives** | Your positioning exists relative to what the buyer would do instead |
| **Outcome-first language** | Lead with measurable buyer outcomes, not feature descriptions |
| **One narrative, many surfaces** | A single positioning truth adapts to homepage, sales deck, email, and docs |
| **Category is a strategy** | You either win an existing category, create a new one, or subcategorize — choose deliberately |
| **Validate with wallets** | Positioning is only real when buyers repeat your value in their own words |

---

## Positioning Approach Decision Tree

Use this tree to choose the right positioning strategy before drafting any messaging.

```
START: How established is the category?
│
├─ Category exists and leader is entrenched
│  ├─ Can you win a specific sub-segment? ──→ SUBCATEGORY STRATEGY
│  │   (Own a niche: "CRM for recruiting agencies")
│  └─ No defensible sub-segment? ──→ HEAD-TO-HEAD STRATEGY
│      (Requires clear, provable superiority on a metric buyers care about)
│
├─ Category exists but is fragmented / no clear leader
│  └─ Can you credibly lead it? ──→ CATEGORY LEADERSHIP STRATEGY
│      (Consolidate messaging, set the evaluation criteria)
│
├─ No category exists for the problem you solve
│  ├─ Buyers already feel the pain? ──→ CREATE CATEGORY STRATEGY
│  │   (Name the problem, define the space, educate the market)
│  └─ Buyers don't know they have the problem? ──→ REFRAME STRATEGY
│      (Attach to an existing budget line, reframe an adjacent category)
│
└─ Product spans multiple categories
   └─ PICK ONE primary category for positioning. Use secondary categories
      only in feature-level messaging, never in the top-line narrative.
```

**Rule**: If you cannot draw a clear line from your strategy choice back to a specific buyer trigger event, go back and tighten the ICP first.

---

## Workflow

1. Define best-fit customer and buying context.
2. Map alternatives and differentiation.
3. Choose category strategy and positioning.
4. Build messaging architecture from top-line narrative to proof.
5. Define brand voice guardrails and copy constraints.
6. Validate message resonance with real buyers.

## Required Inputs

- Product capabilities and constraints
- Target segments and deal motion
- Known competitors and substitutes
- Existing customer language (calls, support, reviews)

## Progressive Disclosure Map

| Reference | When to read |
|---|---|
| [references/positioning-canvas.md](references/positioning-canvas.md) | When starting ICP definition, competitive mapping, or drafting the positioning statement |
| [references/messaging-architecture-template.md](references/messaging-architecture-template.md) | When building the message hierarchy from master narrative down to CTA language |
| [references/brand-voice-guardrails.md](references/brand-voice-guardrails.md) | When defining tone, lexical rules, or channel-specific voice variations |

## Execution Protocol

### 1) Lock the ICP

- Define who buys, who uses, and who blocks.
- Define trigger events that create urgency.
- Exclude low-fit segments explicitly.

### 2) Build Competitive Context

- List direct competitors, adjacent options, and status quo.
- Define where each alternative wins and fails.
- Choose a differentiation wedge tied to buyer outcomes.

### 3) Draft Positioning Statement

Produce one statement that includes:

- Who it is for
- What category frame you choose
- What distinct value is delivered
- Why alternatives fail for this use case

```markdown
## Positioning Statement Template

**For** [best-fit customer + trigger event]
**who** [core unmet need / job-to-be-done],
**[Product]** is a [category frame]
**that** [primary value delivered as measurable outcome].
**Unlike** [top alternative the buyer would actually consider],
**we** [key differentiator tied to a capability the alternative lacks].

### Example — filled in

**For** mid-market engineering teams migrating off legacy CI
**who** need deploys under 5 minutes without dedicated DevOps hires,
**ShipFast** is a zero-config deployment platform
**that** cuts deploy time by 80 % with no pipeline YAML.
**Unlike** Jenkins or GitHub Actions,
**we** auto-detect stack, parallelize builds, and require zero maintenance.
```

### 4) Build Message Architecture

Use a hierarchy:

1. Master narrative
2. Homepage headline and subhead
3. Benefit pillars
4. Proof points and evidence
5. CTA language by stage of intent

```yaml
# messaging-architecture.yml — concrete example
master_narrative: >
  Engineering teams waste 30% of sprint capacity on deploy plumbing.
  ShipFast eliminates pipeline maintenance so teams ship features, not YAML.

homepage:
  headline: "Ship features, not pipelines"
  subhead: "Zero-config deploys for teams that move fast. 80% faster than DIY CI."

benefit_pillars:
  - pillar: "Zero-config setup"
    proof: "Auto-detects Node, Python, Go, Rust — no Dockerfile required"
    evidence: "94% of repos deploy on first push without config changes"
  - pillar: "Parallel builds"
    proof: "Splits test suites across workers automatically"
    evidence: "Average deploy time: 2m 14s (industry median: 11m)"
  - pillar: "No maintenance burden"
    proof: "Managed runners, auto-patched, zero YAML"
    evidence: "Teams reclaim 6+ hours/week previously spent on CI fixes"

cta_by_intent:
  high_intent: "Start deploying free →"
  mid_intent: "See a 2-minute demo"
  low_intent: "Read the migration guide"
```

### 5) Enforce Brand Voice

- Define do/don't language patterns.
- Define lexical guardrails by audience sophistication.
- Define tone variation by channel (site, email, demo deck, docs).

### 6) Validate with Buyers

- Run at least 5 message tests with target users.
- Capture confusion points and objection language.
- Iterate until users can restate value clearly without prompts.

## Output Contract

Deliver these artifacts:

1. Completed positioning canvas
2. Messaging architecture document
3. Brand voice guide with positive/negative examples

## Quality Gates

- ICP and non-ICP are explicit.
- Positioning avoids feature-only claims.
- Message hierarchy maps every claim to evidence.
- Brand voice has concrete do/don't examples.
- At least one message validation round is documented.

## Anti-Patterns

- Claiming broad category leadership without proof.
- Mixing multiple ICPs in one homepage narrative.
- Relying on adjectives instead of measurable outcomes.
- Writing brand voice as abstract adjectives only.

## Checklist

Use this checklist to verify completeness before finalizing positioning and messaging artifacts.

### Positioning Foundation
- [ ] ICP defined with firmographics, buyer role, and trigger event
- [ ] Non-ICP segments explicitly listed with rejection rationale
- [ ] At least 3 real alternatives mapped (direct competitor, adjacent tool, status quo)
- [ ] Differentiation wedge tied to a buyer outcome, not a feature
- [ ] Positioning approach chosen from decision tree with justification
- [ ] Positioning statement drafted using the template format

### Messaging Architecture
- [ ] Master narrative written (2-3 sentences, outcome-focused)
- [ ] Homepage headline and subhead drafted and tested for clarity
- [ ] 3 benefit pillars defined, each with proof point and quantified evidence
- [ ] CTA language written for high, mid, and low intent stages
- [ ] Every claim in the hierarchy traced to a proof point or data source

### Brand Voice
- [ ] Voice attributes defined with do/don't examples per attribute
- [ ] Lexical guardrails set per audience sophistication level
- [ ] Tone variation documented for each channel (site, email, sales deck, docs)
- [ ] Banned words and phrases listed with preferred alternatives

### Validation
- [ ] At least 5 message tests conducted with target ICP buyers
- [ ] Confusion points and objection language captured verbatim
- [ ] Buyer can restate value proposition unprompted in their own words
- [ ] Positioning reviewed against product roadmap for 6-month durability

---

## Hand-off Guidance

- Use `copywriting` and `page-cro` from `external-skills/reused/` for channel-specific execution.
- Use `startup-first-principles` when positioning conflicts with product strategy constraints.
