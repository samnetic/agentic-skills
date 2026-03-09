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

## Workflow

1. Define one growth objective and baseline metrics.
2. Build a hypothesis backlog with explicit assumptions.
3. Prioritize experiments with a consistent scoring model.
4. Design tests with guardrails, instrumentation, and stop rules.
5. Execute in short cycles and publish readouts.
6. Roll out winners, retire losers, and update the backlog.

## Required Inputs

- North-star metric and supporting funnel metrics
- Current baseline by step (visit, signup, activation, conversion, retention)
- Experiment constraints (traffic, engineering bandwidth, legal constraints)
- Owner and decision cadence

## Progressive Disclosure Map

- Experiment brief: [references/experiment-brief-template.md](references/experiment-brief-template.md)
- Channel playbook: [references/channel-priority-playbook.md](references/channel-priority-playbook.md)
- Readout template: [references/experiment-readout-template.md](references/experiment-readout-template.md)
- Prioritization script: [scripts/rice_score.py](scripts/rice_score.py)

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

### 4) Design Test

- Define test and control conditions.
- Define instrumentation requirements before launch.
- Define stop rules and sample-size assumptions.

### 5) Publish Readout

- Use the readout template.
- Record outcome, confidence interval, and decision.
- Track whether the result changed roadmap priorities.

### 6) Operationalize

- Roll out validated winners.
- Archive failed experiments with lessons.
- Refresh backlog from new insights and constraints.

## Output Contract

Deliver these artifacts per cycle:

1. Prioritized backlog with scoring
2. Experiment brief for each launched test
3. Readout with decision and next action

## Quality Gates

- Every experiment maps to one target metric.
- Instrumentation is verified before launch.
- Decision rules are pre-registered.
- Readout includes negative findings, not only wins.
- Repeatability and risk are documented for rollouts.

## Anti-Patterns

- Running tests without baseline or guardrail metrics.
- Changing experiment scope mid-flight without logging.
- Treating non-significant movement as a win.
- Running too many concurrent experiments on the same funnel step.

## Hand-off Guidance

- Use `analytics-tracking` from `external-skills/reused/` if instrumentation is weak.
- Use `page-cro`, `pricing-strategy`, and `seo-audit` from `external-skills/reused/` for channel-specific execution.
