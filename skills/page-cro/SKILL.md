---
name: page-cro
description: >-
  Conversion rate optimization for software marketing pages. Use when improving
  homepage, landing page, feature page, or pricing page conversion via better
  messaging, offer structure, trust signals, and friction reduction. Triggers:
  CRO, conversion lift, landing page optimization, low signup rate, weak CTA,
  page funnel drop-off, offer testing.
---

# Page CRO

Improve conversion by turning page diagnosis into prioritized experiments.

## Core Principles

| Principle | Meaning |
|---|---|
| One page, one job | Every page has a single primary action; secondary actions must not compete with it |
| Evidence over opinion | Design decisions are validated by data (analytics, heatmaps, user tests), never by stakeholder preference alone |
| Smallest testable change | Isolate one variable per experiment so you can attribute causation, not just correlation |
| Friction is invisible to builders | The team that built the page cannot objectively see its friction; use external heuristic review or real user recordings |
| Message-market fit first | No amount of button color optimization compensates for a headline that does not resonate with the visitor's intent |
| Compounding gains | A 5% lift per quarter compounds to 22% annually; prioritize consistent small wins over moonshots |
| Guardrails protect revenue | Every test must define a stop-loss metric (e.g., revenue per visitor) to avoid optimizing one metric at the expense of another |

## Decision Tree — Choosing the Right CRO Approach

Use this tree to pick the highest-leverage starting point for any page.

```
Is the page getting enough traffic for A/B testing (>1 000 uniques/week)?
├─ YES
│   Is the bounce rate above 60%?
│   ├─ YES → Start with ABOVE-THE-FOLD AUDIT (clarity + relevance)
│   │         Fix headline, hero visual, and message-market fit before testing CTAs.
│   └─ NO
│       Is the primary CTA click-through rate below 3%?
│       ├─ YES → Start with CTA & OFFER EXPERIMENTS
│       │         Test copy, placement, contrast, and value proposition framing.
│       └─ NO
│           Is the form/signup completion rate below 40%?
│           ├─ YES → Start with FRICTION REDUCTION
│           │         Reduce fields, add progress indicators, remove distractions.
│           └─ NO → Start with TRUST & PROOF OPTIMIZATION
│                     Add social proof, case studies, security badges near decision points.
├─ NO (low traffic)
│   Use QUALITATIVE methods first:
│   ├─ 5-second tests (usabilityhub / maze)
│   ├─ Session recordings (hotjar / clarity)
│   └─ Heuristic expert review using the Diagnostic Pass below
```

## Workflow

1. Define page goal, audience, and target action.
2. Diagnose friction across clarity, relevance, trust, and actionability.
3. Identify highest-leverage hypotheses.
4. Design experiments with instrumentation and guardrails.
5. Execute and measure.
6. Roll out winners and update the backlog.

## Required Inputs

- Target page URL and audience
- Current baseline metrics (visit-to-action, bounce, depth)
- Existing offer and CTA strategy
- Available dev/design capacity

## Progressive Disclosure Map

| Reference | When to read |
|---|---|
| [references/experiments.md](references/experiments.md) | When you need concrete A/B test ideas organized by page type (homepage, pricing, landing, feature, demo request) |
| [references/page-cro-audit-template.md](references/page-cro-audit-template.md) | When starting a new audit — copy and fill in the template before generating hypotheses |

## Execution Protocol

### 1) Diagnostic Pass

- Message clarity above the fold
- Proof and trust placement
- CTA prominence and alignment with intent
- Form and interaction friction
- Visual hierarchy and scannability
- Page load performance (LCP < 2.5s, CLS < 0.1)

### 2) Hypothesis Formation

Use:

`If [audience] sees [change], then [conversion metric] will change by [delta], because [mechanism].`

Rank hypotheses using ICE scoring:

| Factor | Scale | Question |
|---|---|---|
| Impact | 1-10 | How much will this move the primary metric? |
| Confidence | 1-10 | How strong is the evidence supporting this hypothesis? |
| Ease | 1-10 | How quickly can engineering + design ship this? |

Priority = Impact x Confidence x Ease. Run highest-score hypotheses first.

### 3) Experiment Plan

- Select one primary metric
- Set guardrails and stop conditions
- Ensure event instrumentation is valid
- Calculate minimum sample size before launch
- Define test duration (minimum 1 full business cycle, typically 2 weeks)

### 4) Concrete Implementation Example

Below is a high-converting hero CTA pattern that applies several CRO principles at once: specificity in the headline, social proof adjacent to the action, and friction-reducing microcopy below the button.

```html
<!-- High-converting hero CTA block -->
<section class="hero" aria-labelledby="hero-heading">
  <h1 id="hero-heading">Cut deployment time by 80% — ship with confidence</h1>
  <p class="subheadline">
    The CI/CD platform trusted by 4,200+ engineering teams.
  </p>

  <form class="hero-cta" action="/signup" method="POST">
    <label for="work-email" class="sr-only">Work email</label>
    <input
      id="work-email"
      type="email"
      name="email"
      placeholder="you@company.com"
      required
      autocomplete="email"
    />
    <button type="submit">Start free trial</button>
  </form>
  <p class="microcopy">No credit card required · Setup in 2 minutes</p>

  <ul class="logo-bar" aria-label="Trusted by">
    <li><img src="/logos/stripe.svg" alt="Stripe" width="80" height="28" /></li>
    <li><img src="/logos/vercel.svg" alt="Vercel" width="80" height="28" /></li>
    <li><img src="/logos/linear.svg" alt="Linear" width="80" height="28" /></li>
  </ul>
</section>

<style>
  .hero {
    max-width: 640px;
    margin: 0 auto;
    padding: 4rem 1.5rem;
    text-align: center;
  }
  .hero h1 {
    font-size: clamp(1.75rem, 4vw, 2.5rem);
    line-height: 1.2;
    margin-bottom: 0.75rem;
  }
  .hero .subheadline {
    color: #555;
    margin-bottom: 2rem;
  }
  .hero-cta {
    display: flex;
    gap: 0.5rem;
    justify-content: center;
    flex-wrap: wrap;
  }
  .hero-cta input {
    padding: 0.75rem 1rem;
    border: 1px solid #ccc;
    border-radius: 6px;
    min-width: 240px;
    font-size: 1rem;
  }
  .hero-cta button {
    padding: 0.75rem 1.5rem;
    background: #2563eb;
    color: #fff;
    border: none;
    border-radius: 6px;
    font-weight: 600;
    font-size: 1rem;
    cursor: pointer;
  }
  .microcopy {
    font-size: 0.85rem;
    color: #777;
    margin-top: 0.5rem;
  }
  .logo-bar {
    display: flex;
    gap: 2rem;
    justify-content: center;
    list-style: none;
    padding: 0;
    margin-top: 2.5rem;
    opacity: 0.6;
  }
</style>
```

**Why this converts:** The headline leads with a quantified outcome (80%), not a feature. The inline email field reduces one click of friction versus a separate signup page. Microcopy pre-handles the two biggest objections (cost and time). Logo bar provides immediate social proof without requiring scroll.

## Output Contract

Deliver:

1. CRO audit worksheet (filled template)
2. Prioritized experiment queue with ICE scores
3. Test result readout with decision (roll out / iterate / reject)

## Quality Gates

- Every recommendation maps to a measurable metric.
- Hypotheses are explicit and testable.
- Tests include guardrails and success thresholds.
- Implementation complexity is estimated before launch.
- Sample size calculation is documented for every A/B test.

## CRO Launch Checklist

Use before launching any experiment:

- [ ] Primary conversion metric defined and instrumented in analytics
- [ ] Guardrail metrics identified (revenue per visitor, bounce rate, page load time)
- [ ] Minimum sample size calculated (use a significance calculator; target p < 0.05, power 80%)
- [ ] Test duration set to at least one full business cycle (7+ days minimum)
- [ ] Hypothesis written in the standard format with expected delta
- [ ] QA completed: variant renders correctly on mobile, tablet, and desktop
- [ ] QA completed: variant is accessible (keyboard nav, screen reader, color contrast)
- [ ] Analytics events fire correctly in both control and variant (verify in real-time reports)
- [ ] Redirect and flicker prevention confirmed (anti-flicker snippet or server-side split)
- [ ] Stakeholders informed of test start date, expected duration, and decision criteria
- [ ] Stop-loss threshold documented (e.g., "halt if revenue per visitor drops > 10%")
- [ ] Post-test action plan drafted: what happens on win, loss, or inconclusive result

## Anti-Patterns

| Anti-Pattern | Why It Fails | What to Do Instead |
|---|---|---|
| Full redesign without incremental tests | Cannot attribute which change drove results; high risk of regression | Break into isolated, testable components |
| CTA changes without message-problem fit checks | Button tweaks are meaningless if the headline does not resonate | Fix above-the-fold clarity first |
| Relying on aesthetics-only feedback | "Looks nice" is not a conversion signal | Use quantitative metrics or structured user tests |
| Ending tests too early | Results look significant due to random variance; novelty effect inflates early numbers | Run for minimum calculated duration regardless of interim results |
| Testing on low-traffic pages | Test never reaches statistical significance; months wasted | Use qualitative methods (5-second tests, session recordings) instead |
| Copying competitor pages blindly | Their context, audience, and funnel differ from yours | Use competitor patterns as hypothesis inspiration, then test locally |
| Optimizing micro-conversions in isolation | Newsletter signups rise but demo requests fall | Always pair a micro-metric with a macro guardrail |
