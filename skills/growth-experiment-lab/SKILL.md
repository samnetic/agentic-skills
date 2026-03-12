---
name: growth-experiment-lab
description: >-
  Growth experimentation operating system for SaaS products. Use when creating
  experiment backlogs, prioritizing growth ideas, designing tests for landing
  pages, onboarding, pricing, lifecycle messaging, or SEO, and producing
  decision-grade readouts. Triggers: growth experiments, ICE, RICE, A/B test
  design, experimentation backlog, growth loop, conversion lift, experiment
  readout, hypothesis testing, growth strategy execution.
---

# Growth Experiment Lab

Run a disciplined growth system that turns ideas into measured decisions.

---

## Core Principles

| Principle | Meaning |
|---|---|
| **One metric per experiment** | Every test maps to exactly one target metric; secondary metrics are guardrails, not goals |
| **Pre-register decisions** | Define success criteria, stop rules, and rollout thresholds before launch |
| **Baseline before build** | Never design a test without a measured baseline and minimum detectable effect |
| **Reversibility first** | Favor experiments that can be rolled back in minutes, not days |
| **Negative results are results** | Failed hypotheses prune the search space; document and share them equally |
| **Small batches, fast cycles** | One- to two-week experiment cycles expose learning faster than quarterly bets |
| **Instrumentation is a prerequisite** | If you cannot measure it, you cannot run it; verify tracking before launch |
| **Concurrency discipline** | Never overlap experiments that touch the same funnel step or user segment |

---

## Decision Tree — Choosing Experiment Approach

Use this tree to pick the right test type for a given growth idea.

```
Is the change visible to users?
├── YES
│   ├── Can you split traffic evenly?
│   │   ├── YES
│   │   │   ├── Expected effect size > 5%?
│   │   │   │   ├── YES → Simple A/B test (2 variants, 1–2 weeks)
│   │   │   │   └── NO  → A/B test with larger sample / longer runtime
│   │   │   └── (consider multivariate only if traffic > 50k/week)
│   │   └── NO
│   │       ├── Can you use a holdout group?
│   │       │   ├── YES → Holdout test (launch to 90%, hold 10%)
│   │       │   └── NO  → Pre/post analysis with interrupted time series
│   │       └── (flag in readout: weaker causal evidence)
│   └── Is this a pricing or packaging change?
│       ├── YES → Geo-split or cohort test (avoid within-market price discrimination)
│       └── NO  → Standard A/B
└── NO (backend, algorithm, infrastructure)
    ├── Can you measure downstream metric directly?
    │   ├── YES → Shadow test or switchback experiment
    │   └── NO  → Proxy-metric A/B with explicit proxy-to-target mapping
    └── Document proxy validity in the experiment brief
```

**Quick reference:**

| Scenario | Recommended approach | Minimum traffic |
|---|---|---|
| Landing page headline | A/B test | 1,000 visitors/variant/week |
| Onboarding flow rewrite | A/B with activation guardrail | 500 signups/variant/week |
| Pricing tier change | Geo-split or new-cohort test | 200 new customers/geo/month |
| Email subject line | A/B send-split | 5,000 recipients/variant |
| Search ranking algorithm | Interleaving or switchback | 10,000 queries/day |
| Backend latency optimization | Shadow test + proxy metric | N/A (measure p95 latency) |

---

## Workflow

1. Define one growth objective and baseline metrics.
2. Build a hypothesis backlog with explicit assumptions.
3. Prioritize experiments with a consistent scoring model.
4. Design tests with guardrails, instrumentation, and stop rules.
5. Execute in short cycles and publish readouts.
6. Roll out winners, retire losers, and update the backlog.

---

## Required Inputs

- North-star metric and supporting funnel metrics
- Current baseline by step (visit, signup, activation, conversion, retention)
- Experiment constraints (traffic, engineering bandwidth, legal constraints)
- Owner and decision cadence

---

## Progressive Disclosure Map

| Reference | Path | When to read |
|---|---|---|
| Experiment brief template | [references/experiment-brief-template.md](references/experiment-brief-template.md) | Before designing any new experiment |
| Channel priority playbook | [references/channel-priority-playbook.md](references/channel-priority-playbook.md) | When choosing which growth channel to test first |
| Readout template | [references/experiment-readout-template.md](references/experiment-readout-template.md) | After an experiment concludes, before the decision meeting |
| RICE scoring script | [scripts/rice_score.py](scripts/rice_score.py) | During backlog prioritization to rank hypotheses consistently |

---

## Execution Protocol

### 1) Define Objective and Baseline

- Pick one objective metric for this cycle.
- Capture baseline and minimum detectable effect.
- Define downside guardrails (for example churn or refund rate limits).

### 2) Build Hypothesis Backlog

Use the format:

`If [segment] sees [change], then [metric] will move by [delta] in [time], because [mechanism].`

### 3) Prioritize with RICE

- Score every hypothesis with Reach, Impact, Confidence, Effort.
- Use `scripts/rice_score.py` to keep scoring consistent.
- Favor experiments that are high-confidence and reversible.

**Example RICE input CSV:**

```csv
hypothesis,reach,impact,confidence,effort
"Shorter signup form (3 fields instead of 7)",4000,3,0.8,2
"Add social proof badges to pricing page",12000,2,0.6,1
"Personalized onboarding flow by use-case",2000,3,0.5,5
"Exit-intent discount modal on annual plan page",8000,2,0.7,1
"Restructure trial-to-paid email sequence",3000,2,0.9,3
```

Run with: `python scripts/rice_score.py backlog.csv`

### 4) Design Test

- Define test and control conditions.
- Define instrumentation requirements before launch.
- Define stop rules and sample-size assumptions.

**Example experiment configuration (YAML):**

```yaml
experiment:
  id: exp-2026-03-signup-form
  name: Shorter signup form
  owner: growth-team
  status: draft

hypothesis: >
  If new visitors see a 3-field signup form instead of the current
  7-field form, then signup completion rate will increase by at least
  15% within 14 days, because reducing friction lowers abandonment.

design:
  type: a/b
  variants:
    control: current 7-field form
    treatment: 3-field form (name, email, password)
  allocation: 50/50
  segment: all new visitors, desktop + mobile

metrics:
  primary: signup_completion_rate
  guardrails:
    - name: 7d_activation_rate
      threshold: ">= 0.95x control"    # must not drop activation
    - name: spam_signup_rate
      threshold: "<= 1.10x control"    # must not inflate spam

sample_size:
  baseline_rate: 0.32
  minimum_detectable_effect: 0.15       # relative 15%
  power: 0.80
  significance: 0.05
  required_per_variant: 2_847

stop_rules:
  - "Stop early if guardrail metric degrades by > 20% with p < 0.01"
  - "Do not peek before day 7 or 50% of required sample, whichever comes first"
  - "Auto-stop at day 21 regardless of sample size"

instrumentation:
  events:
    - signup_form_viewed
    - signup_form_field_focused
    - signup_form_submitted
    - signup_form_error
  feature_flag: exp_short_signup_form
  analytics_dashboard: "Growth > Experiments > exp-2026-03-signup-form"
```

### 5) Publish Readout

- Use the readout template.
- Record outcome, confidence interval, and decision.
- Track whether the result changed roadmap priorities.

### 6) Operationalize

- Roll out validated winners.
- Archive failed experiments with lessons.
- Refresh backlog from new insights and constraints.

---

## Output Contract

Deliver these artifacts per cycle:

1. Prioritized backlog with scoring
2. Experiment brief for each launched test
3. Readout with decision and next action

---

## Quality Gates

- Every experiment maps to one target metric.
- Instrumentation is verified before launch.
- Decision rules are pre-registered.
- Readout includes negative findings, not only wins.
- Repeatability and risk are documented for rollouts.

---

## Anti-Patterns

| Anti-pattern | Why it hurts | Fix |
|---|---|---|
| Running tests without baseline or guardrail metrics | No way to measure impact or catch regressions | Always capture baseline + set guardrails in the brief |
| Changing experiment scope mid-flight without logging | Invalidates statistical assumptions | Freeze scope at launch; log any deviations in the readout |
| Treating non-significant movement as a win | Leads to false-positive feature rollouts | Pre-register significance threshold; respect the p-value |
| Running too many concurrent experiments on the same funnel step | Interaction effects corrupt all results | Limit to one experiment per funnel step per cycle |
| Peeking at results before sample size is reached | Inflates false-positive rate | Use sequential testing or enforce a no-peek window |
| Skipping the readout for failed experiments | Organization loses learning value | Every experiment gets a readout, win or lose |

---

## Experiment Launch Checklist

Use this checklist before marking any experiment as "live."

- [ ] Hypothesis written in the standard format (`If [segment] sees [change], then [metric]...`)
- [ ] Single primary metric identified
- [ ] Baseline value measured and recorded in the experiment brief
- [ ] Minimum detectable effect calculated and achievable with available traffic
- [ ] Sample size requirement computed (power >= 0.80, significance <= 0.05)
- [ ] Guardrail metrics defined with explicit thresholds
- [ ] Stop rules documented (early-stop conditions, no-peek window, max duration)
- [ ] Feature flag created and tested in staging
- [ ] All required analytics events firing correctly (verified in dev/staging)
- [ ] Dashboard or report configured to track primary + guardrail metrics
- [ ] Experiment brief reviewed by at least one peer
- [ ] Traffic allocation confirmed (no overlap with other active experiments on same segment)
- [ ] Rollback plan documented (how to disable treatment within 15 minutes)
- [ ] Legal/compliance review completed (if pricing, PII, or regulated content)
- [ ] Launch date and readout date scheduled on team calendar

### Post-Experiment Checklist

- [ ] Readout document completed using the readout template
- [ ] Confidence interval and p-value recorded
- [ ] Guardrail metrics reviewed for regressions
- [ ] Decision recorded: ship, iterate, or kill
- [ ] Feature flag cleaned up (removed or made permanent)
- [ ] Backlog updated with new hypotheses generated from findings
- [ ] Results shared with stakeholders

---

## Hand-off Guidance

- Use `analytics-tracking` from `external-skills/reused/` if instrumentation is weak.
- Use `page-cro`, `pricing-strategy`, and `seo-audit` from `external-skills/reused/` for channel-specific execution.
