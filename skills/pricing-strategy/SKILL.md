---
name: pricing-strategy
description: >-
  SaaS pricing and packaging strategy with decision-grade outputs. Use when
  defining pricing metrics, packaging tiers, price points, discounts, free
  trial/freemium policy, price increase plans, or pricing experiments. Triggers:
  pricing tiers, packaging, monetization, value metric, willingness to pay,
  freemium, trial design, price increase, ARPU optimization.
---

# Pricing Strategy

Design pricing that aligns value capture with customer outcomes.

---

## Core Principles

| Principle | Meaning |
|---|---|
| **Value-metric alignment** | The unit of charge must track the unit of value the customer receives |
| **Willingness to pay > cost-plus** | Price from demand evidence, not internal cost models |
| **Simplicity wins** | If a buyer cannot estimate their bill in 30 seconds, the model is too complex |
| **Reversible defaults** | Launch with guardrails that let you course-correct without brand damage |
| **Segment by behavior, not demographics** | Tiers should reflect usage patterns and outcomes, not company size alone |
| **Expansion > acquisition** | Net revenue retention above 120 % is more durable than new-logo growth |
| **Test before you commit** | Every material pricing change should have a pre-registered experiment or phased rollout |
| **Transparent anchoring** | Published pricing builds trust; hidden pricing creates friction in self-serve funnels |

---

## Workflow

1. Define business objective (growth, margin, retention, expansion).
2. Lock ICP and buying context from product-marketing context.
3. Select value metric and packaging structure.
4. Set price points using evidence and market constraints.
5. Define rollout and experiment plan.
6. Publish decisions with risk controls.

---

## Required Inputs

- ICP and segment economics
- Existing conversion, ARPU, churn, expansion metrics
- Competitor and alternative pricing context
- Sales motion (self-serve, sales-led, hybrid)

---

## Progressive Disclosure Map

| Reference | When to read |
|---|---|
| [Research methods](references/research-methods.md) | Before collecting willingness-to-pay data or running Van Westendorp / Gabor-Granger surveys |
| [Tier structures](references/tier-structure.md) | When designing or restructuring packaging tiers and feature gating |
| [Decision memo template](references/pricing-decision-template.md) | When writing the final pricing recommendation for stakeholder review |

---

## Pricing Model Decision Tree

```
What is your primary growth motion?
│
├─ Self-serve / PLG?
│  │
│  ├─ Users consume a clear, measurable resource (API calls, seats, storage)?
│  │  → Usage-based or per-seat pricing
│  │  → Offer a free tier or trial to reduce activation friction
│  │
│  └─ Value is binary (access vs no access)?
│     → Flat-rate or good/better/best tiers
│     → Free trial (14 days) over freemium to force evaluation
│
├─ Sales-led / enterprise?
│  │
│  ├─ Deal sizes > $50k ACV?
│  │  → Custom / negotiated pricing with published list price as anchor
│  │  → Value metric still matters for expansion (seat, usage, or outcome)
│  │
│  └─ Deal sizes $5k–$50k ACV?
│     → Published tiers with optional annual discount
│     → Sales assists on upgrade, not initial purchase
│
└─ Hybrid (self-serve entry, sales-led expansion)?
   → Free or low-cost entry tier (PLG funnel)
   → Usage-based growth tier auto-triggers sales touch at threshold
   → Enterprise tier with negotiated terms above threshold
```

---

## Execution Protocol

### 1) Choose the Value Metric

- Prefer metrics that scale with realized customer value.
- Reject metrics easy to game or hard to explain.
- Validate with the "napkin test": can a prospect estimate their monthly cost on the back of a napkin?
- Common SaaS value metrics ranked by alignment strength:

| Metric type | Example | Alignment strength |
|---|---|---|
| Outcome-based | Revenue generated, messages sent | High |
| Usage-based | API calls, GB stored, compute hours | Medium-high |
| Per-seat | Named users, active users | Medium |
| Flat-rate | Single price for access | Low |

### 2) Define Tier Logic

- Create clear boundaries between entry, growth, and premium tiers.
- Gate by outcomes, not arbitrary feature clutter.
- Each tier should have a distinct ICP persona and an obvious reason to upgrade.
- Limit to 3-4 tiers for self-serve; use a "Contact us" tier for enterprise.

Example tier matrix in YAML:

```yaml
# pricing-tiers.yaml — B2B SaaS collaboration tool example
tiers:
  - name: Free
    price: $0/mo
    value_metric: up to 5 users
    includes:
      - Core collaboration features
      - 1 GB storage
      - Community support
    upgrade_trigger: Team exceeds 5 members or needs integrations
    target_persona: Small team evaluating the product

  - name: Pro
    price: $12/user/mo (billed annually) | $15/user/mo (billed monthly)
    value_metric: unlimited users
    includes:
      - Everything in Free
      - Unlimited integrations
      - 100 GB storage
      - Priority email support
      - Advanced analytics
    upgrade_trigger: Needs SSO, audit logs, or dedicated support
    target_persona: Growing team (10-50 users) with active daily use

  - name: Business
    price: $28/user/mo (billed annually)
    value_metric: unlimited users
    includes:
      - Everything in Pro
      - SSO (SAML/OIDC)
      - Audit logs and compliance exports
      - 1 TB storage
      - Dedicated CSM above 50 seats
    upgrade_trigger: Needs custom contracts, SLAs, or data residency
    target_persona: Mid-market company (50-500 users) with compliance needs

  - name: Enterprise
    price: Custom
    value_metric: negotiated
    includes:
      - Everything in Business
      - Custom SLA (99.99 %)
      - Data residency options
      - Dedicated infrastructure
      - Premium support with SLA
    target_persona: Large organization (500+ users) with procurement process
```

### 3) Set and Test Price Points

- Start from willingness-to-pay evidence and alternatives.
- Use Van Westendorp or Gabor-Granger to establish acceptable price range.
- Define test plan: audience, period, guardrails, success criteria.
- A/B test pricing on new visitors only; never show different prices to the same cohort.
- Anchor with the highest tier first (right to left) on the pricing page.

### 4) Plan Rollout

- New customers vs existing customers strategy.
- Grandfather existing customers for 6-12 months or one renewal cycle.
- Notice period and communication plan (minimum 60 days for increases > 10 %).
- Sales and support enablement — battlecards, FAQ, objection handling.
- Monitor leading indicators within 7 days: trial starts, PQL rate, upgrade rate, support tickets about pricing.

---

## Pricing Experiment Framework

### Experiment types

| Type | When to use | Duration |
|---|---|---|
| **Van Westendorp survey** | Pre-launch or major repositioning | 1-2 weeks to collect, instant analysis |
| **Gabor-Granger survey** | Validating a specific price point | 1-2 weeks |
| **A/B price test** | Optimizing conversion on existing product | 4-8 weeks minimum |
| **Cohort rollout** | Price increase for existing customers | 3-6 months phased |
| **Geographic test** | Testing elasticity in new market | 8-12 weeks |

### Guardrails for every experiment

- Pre-register the hypothesis, metric, sample size, and decision rule.
- Set a "stop" threshold: if trial-start rate drops > 15 % or churn spikes > 2x baseline, pause.
- Never test on fewer than 1,000 visitors per variant for conversion experiments.
- Document the decision regardless of outcome.

---

## Freemium vs Free Trial Decision

```
Is the product's value obvious within 14 days?
│
├─ Yes → Free trial (14 days, no credit card required)
│        Better for: clear aha-moment products, sales-assisted conversion
│
└─ No → Freemium with usage cap
         Better for: network-effect products, long consideration cycles
         │
         ├─ Can you define a cap that is useful but creates natural upgrade pressure?
         │  → Yes → Freemium (e.g., 5 users, 100 API calls/day)
         │  → No  → Reverse trial: full features for 14 days, then downgrade to free tier
```

---

## Output Contract

Deliver:

1. **Pricing decision memo** with rationale, evidence sources, and stakeholder sign-off
2. **Tier matrix** with value metric, price points, feature allocation, and upgrade triggers
3. **Experiment or rollout plan** with guardrails, timeline, and success criteria
4. **Communication plan** for customers, sales, and support

---

## Quality Gates

- Value metric aligns with value realization.
- Tier differences are behaviorally meaningful.
- Rollout includes guardrails for churn and conversion.
- Every major assumption has a test or evidence source.
- Pricing page passes the "30-second comprehension" test.
- At least one experiment or evidence source backs each price point.
- Existing customer migration plan includes grandfathering policy.

---

## Anti-Patterns

| Anti-pattern | Why it fails | Fix |
|---|---|---|
| Copying competitor prices without own economics | Your cost structure and value prop differ | Use WTP research on your ICP |
| Over-segmented tiers (5+ plans) | Decision paralysis, support complexity | Consolidate to 3-4 tiers |
| Price changes without pre-registered guardrails | No way to know if the change worked or if you got lucky | Pre-register hypothesis and stop criteria |
| Hiding pricing to force a sales call | Kills self-serve funnel, frustrates buyers | Publish at least starting prices |
| Annual-only billing with no monthly option | High commitment barrier for new customers | Offer monthly with 15-20 % annual discount |
| Charging for table-stakes features | Perceived as nickel-and-diming | Gate by outcomes and scale, not basic functionality |
| Launching globally at one price point | Purchasing-power mismatch kills conversion in emerging markets | Use PPP-adjusted or regional tiers |

---

## Pricing Launch Checklist

- [ ] ICP and segment economics documented
- [ ] Value metric identified and validated with customer evidence
- [ ] Tier matrix complete with clear upgrade triggers per tier
- [ ] Willingness-to-pay data collected (survey or conjoint)
- [ ] Price points set with supporting rationale (not gut feel)
- [ ] Competitor and alternative pricing benchmarked
- [ ] Pricing page copy drafted and passes 30-second comprehension test
- [ ] Free tier or trial policy decided with conversion funnel modeled
- [ ] Annual vs monthly billing and discount structure defined
- [ ] Existing customer migration plan with grandfathering terms
- [ ] Communication plan drafted (email, in-app, support FAQ)
- [ ] Sales enablement materials ready (battlecards, objection handling)
- [ ] Experiment or phased rollout plan with pre-registered guardrails
- [ ] Finance sign-off on revenue impact model
- [ ] Legal review of terms-of-service changes
- [ ] Monitoring dashboard for leading indicators (trial starts, PQLs, upgrade rate, churn)
- [ ] Rollback plan defined in case guardrail thresholds are breached
