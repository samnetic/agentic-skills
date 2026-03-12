---
name: copywriting
description: >-
  Conversion-focused copywriting for software products across homepage, landing,
  feature, pricing, onboarding, and sales-assist pages. Use when creating or
  rewriting copy to improve clarity, differentiation, and conversion outcomes.
  Triggers: copywriting, rewrite copy, headline, subhead, CTA text, landing page
  copy, pricing page copy, messaging rewrite, conversion copy.
---

# Copywriting

Write copy that connects buyer pain to clear outcomes and action.

## Core Principles

| Principle | Meaning |
|---|---|
| Clarity over cleverness | If the reader has to re-read, you lost them. Plain language wins. |
| One page, one job | Every page exists to move the reader toward a single conversion goal. |
| Outcome before feature | Lead with what the buyer gains, not what the product does. |
| Proof on every claim | Assertions without evidence are decoration. Add numbers, quotes, or demos. |
| Specificity sells | "Save 4 hours/week" beats "save time." Concrete details build trust. |
| Voice consistency | Tone may flex by page, but vocabulary and personality stay on-brand. |
| Scannable hierarchy | Most visitors skim. Headings, bullets, and bold text carry the message alone. |

## Workflow

1. Define audience, intent stage, and page objective.
2. Translate positioning into message hierarchy.
3. Select copy approach using the decision tree below.
4. Draft copy blocks from problem to proof to CTA.
5. Align tone and terminology with brand voice.
6. QA for clarity, specificity, and objection handling.
7. Publish variants and measure performance.

## Required Inputs

- Target page type and audience segment
- Current positioning and differentiation
- Offer details, proof points, and constraints
- Conversion goal and baseline metrics

## Decision Tree — Choosing Copy Approach

Use this tree to select the right structure before drafting.

```
START: What is the page's primary job?
│
├─ Introduce the product to new visitors?
│  └─ HOMEPAGE
│     ├─ Lead with positioning statement (who + what + why different)
│     ├─ Cover 3-4 top use cases or benefits
│     ├─ Include social proof (logos, testimonial, metric)
│     └─ CTA: "Start free trial" / "See how it works"
│
├─ Convert traffic from a specific campaign or ad?
│  └─ LANDING PAGE
│     ├─ Match headline to the ad/source promise exactly
│     ├─ Single offer, single CTA — remove all navigation
│     ├─ Problem → Outcome → Proof → CTA structure
│     └─ CTA: Direct action verb matching the offer
│
├─ Explain a feature or capability in depth?
│  └─ FEATURE PAGE
│     ├─ Outcome-first headline, not feature name
│     ├─ How-it-works visual or 3-step explanation
│     ├─ Comparison or before/after framing
│     └─ CTA: "Try [feature]" / "See it in action"
│
├─ Help buyer evaluate pricing and plans?
│  └─ PRICING PAGE
│     ├─ Anchor with recommended plan (visual highlight)
│     ├─ Clarify who each plan is for, not just what it includes
│     ├─ Address cost objections (ROI calc, guarantee, free tier)
│     └─ CTA: "Start free" / "Talk to sales" per plan
│
├─ Nurture or re-engage via email?
│  └─ EMAIL
│     ├─ Subject line: curiosity or benefit in < 50 chars
│     ├─ One idea per email, one CTA
│     ├─ Open with reader context ("You signed up last week…")
│     └─ CTA: Single text link or button, verb-first
│
└─ Activate or onboard a new user?
   └─ ONBOARDING / IN-APP
      ├─ Microcopy: short, action-oriented, no jargon
      ├─ Progressive disclosure — show next step only
      ├─ Celebrate completion ("You're set up!")
      └─ CTA: Next action in the workflow
```

## Progressive Disclosure Map

| Reference | Purpose | When to read |
|---|---|---|
| [references/copy-frameworks.md](references/copy-frameworks.md) | Headline formulas, page section types, structural templates | When drafting headlines or choosing page structure |
| [references/natural-transitions.md](references/natural-transitions.md) | Transitional phrases for section flow | When body copy feels choppy or disconnected |
| [references/copy-draft-template.md](references/copy-draft-template.md) | Fillable draft worksheet | At the start of any new page draft |

## Execution Protocol

### 1) Message Architecture First

- Problem statement
- Desired outcome
- Differentiation claim
- Proof evidence
- Single primary CTA

### 2) Draft By Block

- Headline and subhead
- Benefit bullets
- Objection handling section
- Proof/social evidence
- CTA block

### 3) Quality Pass

- Remove vague adjectives without proof.
- Replace feature-first phrasing with outcome-first language.
- Ensure each section has one clear purpose.

## Concrete Example — SaaS Landing Page Hero

```html
<section class="hero">
  <h1>Ship bug fixes before your customers notice them</h1>
  <p class="subhead">
    Acme Monitor detects production errors in real time and opens
    a fix PR in your repo — so your team resolves issues 3x faster
    than with alerting alone.
  </p>
  <ul class="proof-bar">
    <li>Used by 1,200+ engineering teams</li>
    <li>Median time-to-fix: 12 minutes</li>
    <li>Free for up to 5 developers</li>
  </ul>
  <a href="/signup" class="cta-primary">Start free — no credit card</a>
  <a href="/demo" class="cta-secondary">Watch 2-min demo</a>
</section>
```

**Why this works:**
- Headline states outcome, not feature ("detects errors" is subordinate).
- Subhead names the mechanism and quantifies the benefit (3x faster).
- Proof bar uses specifics (1,200+ teams, 12 minutes, free tier).
- Primary CTA removes friction ("no credit card"); secondary CTA offers low-commitment alternative.

## Email Subject Line Examples

```markdown
- "Your deploy just broke 3 tests — here's the fix" (urgency + specificity)
- "How Stripe's team cut deploy failures by 60%" (social proof + number)
- "You're 1 step from real-time error alerts" (progress + benefit)
```

## Output Contract

Deliver:

1. Final copy draft (plus one variant)
2. Copy rationale mapped to audience pains
3. Suggested A/B test ideas for top sections

## Quality Gates

- Core value is clear in first screenful.
- Every major claim has evidence.
- CTA language is concrete and intent-matched.
- Copy aligns with current positioning and ICP.

## Pre-Publish Checklist

- [ ] Headline states an outcome the buyer cares about, not a feature name.
- [ ] Subhead adds specificity (who, how, or quantified benefit).
- [ ] Page has exactly one primary CTA; secondary CTA is visually subordinate.
- [ ] Every claim or statistic has a source or proof point nearby.
- [ ] No vague adjectives remain ("powerful", "seamless", "robust") without evidence.
- [ ] Copy passes the "so what?" test — each sentence earns its place.
- [ ] Tone and vocabulary match the brand voice guide.
- [ ] Above-the-fold content works without scrolling on mobile.
- [ ] Objection handling is present for the top 1-2 buyer hesitations.
- [ ] A/B variant is prepared for at least the headline or CTA.
- [ ] Copy has been read aloud to catch awkward phrasing.
- [ ] Legal/compliance review completed if claims involve numbers or guarantees.

## Anti-Patterns

- Generic slogans without buyer context.
- Multiple competing CTAs above the fold.
- Feature dumping without relevance framing.
- Headline that only makes sense if you already know the product.
- Social proof without specifics ("trusted by thousands").
- Wall-of-text paragraphs with no visual hierarchy.

## Escalation Rules

- If positioning or differentiation is unclear, hand off to `positioning-brand-system`.
- If conversion metrics need analysis, hand off to `analytics-tracking`.
- If page layout or visual hierarchy is the problem, hand off to `page-cro`.

