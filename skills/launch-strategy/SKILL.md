---
name: launch-strategy
description: >-
  Software launch strategy for product releases, major features, and GTM
  campaigns. Use when planning phased launch execution, channel sequencing,
  launch messaging, stakeholder readiness, or post-launch momentum. Triggers:
  launch plan, GTM launch, feature launch, Product Hunt launch, release campaign,
  early access rollout, launch checklist.
license: MIT
metadata:
  author: samnetic
  version: "1.0"
---

# Launch Strategy

Plan launches as multi-phase systems, not one-day events. A launch is a
coordinated sequence of preparation, activation, and amplification — each
phase builds on the previous one. Treat every launch as a cross-functional
operation with clear owners, measurable outcomes, and feedback loops.

---

## Core Principles

| Principle | Meaning |
|---|---|
| **Phases over events** | Launches have prelaunch, launch day, and postlaunch phases — skipping any phase degrades results |
| **Audience before channel** | Define who you are reaching and why before choosing where to reach them |
| **Metrics before motion** | Set success criteria and measurement windows before any work starts |
| **Ownership at every node** | Every task, asset, and decision has exactly one accountable owner |
| **Operational readiness first** | Sales, support, infrastructure, and docs must be ready before external activation |
| **Feedback loops close fast** | Capture signals during and after launch — feed them back within days, not quarters |
| **Momentum compounds** | Post-launch follow-through (case studies, community, iteration) matters more than day-one traffic |

---

## Workflow

1. **Define launch scope** — Clarify launch type, goals, success metrics, and measurement windows.
2. **Segment audience** — Identify primary and secondary segments; map their needs and objections.
3. **Choose channel mix** — Match channels to audience segments; assign owners and message angles.
4. **Build phased plan** — Structure prelaunch, launch day, and postlaunch tasks with owners and deadlines.
5. **Prepare assets and enablement** — Create all assets; brief sales, support, and partners.
6. **Execute with monitoring** — Activate channels in sequence; watch leading indicators in real time.
7. **Run post-launch review** — Analyze results vs. goals within 7 days; capture learnings and next actions.

---

## Required Inputs

- Launch type (new product, major feature, repositioning, market expansion, pricing change)
- Target segments and primary message per segment
- Available channels and team owners
- Commercial goals, measurement windows, and baseline metrics
- Known constraints (budget, timeline, team capacity, dependencies)

---

## Launch Approach Decision Tree

```
What are you launching?
|
+-- New product (no existing users)?
|   |
|   +-- B2B / high-ACV?
|   |   -> Private beta -> Waitlist -> Invite-only -> Public launch
|   |   -> Focus: case studies, sales enablement, targeted outreach
|   |
|   +-- B2C / PLG / self-serve?
|       -> Closed beta -> Product Hunt / HN -> Public launch -> Paid amplification
|       -> Focus: activation flow, onboarding, community seeding
|
+-- Major feature for existing product?
|   |
|   +-- Breaking change or migration required?
|   |   -> Feature flag rollout -> Early access opt-in -> Staged migration -> GA
|   |   -> Focus: migration docs, support readiness, rollback plan
|   |
|   +-- Additive feature (no migration)?
|       -> Internal dogfood -> Beta flag -> Announce to users -> GA
|       -> Focus: in-app discovery, changelog, upgrade nudge
|
+-- Repositioning or pricing change?
|   -> Internal alignment -> Existing customer comms -> Public update
|   -> Focus: FAQ, objection handling, grandfathering policy
|
+-- Market expansion (new geo, new vertical)?
    -> Localization -> Partner/channel activation -> Regional launch
    -> Focus: local proof points, compliance, partner enablement
```

**Key trade-offs:**

| Factor | Lean toward staged/phased | Lean toward big-bang |
|---|---|---|
| Risk tolerance | Low — unknown market fit, breaking changes | High — proven demand, additive feature |
| Audience size | Large or diverse segments | Small, well-understood segment |
| Operational complexity | High — cross-team, multi-geo | Low — single team, single channel |
| Feedback dependency | Need early signal to iterate | Confident in positioning and readiness |

---

## Execution Protocol

### 1) Prelaunch (T−4 to T−1 weeks)

- Clarify positioning, offer, and primary message per segment
- Finalize asset plan with owners and deadlines
- Validate operational readiness (support scripts, infra scaling, monitoring)
- Brief sales and support with objection-handling playbook
- Seed anticipation: waitlist, teaser content, early-access invites
- Run internal dry-run or rehearsal for complex launches

### 2) Launch Day (T+0)

- Activate channels in planned sequence (stagger, not simultaneous)
- Monitor leading indicators: traffic, signups, activation rate, error rate
- Staff rapid-response for support, social, and community channels
- Respond to objections and questions within SLA (aim for < 1 hour)
- Escalate blockers to pre-assigned escalation owner

### 3) Postlaunch (T+1 to T+14 days)

- Analyze results against goals and baseline metrics
- Publish internal post-launch review within 7 days
- Capture learnings: what worked, what didn't, what to repeat
- Feed insights to product roadmap and growth backlog
- Sustain momentum: case studies, follow-up content, community engagement
- Schedule next iteration or follow-up campaign

---

## Launch Plan Template

Use this structure to document every launch. Fill in all sections before moving to execution.

```yaml
# launch-plan.yaml
launch:
  name: "Q3 2026 — Project Atlas Public Launch"
  type: "new-product"          # new-product | major-feature | repositioning | market-expansion | pricing-change
  owner: "Jane Kim (PM)"
  launch_date: "2026-09-15"

goals:
  - metric: "Signups (first 14 days)"
    baseline: 0
    target: 2500
    window: "14 days"
  - metric: "Activation rate (completed onboarding)"
    baseline: null
    target: "40%"
    window: "30 days"
  - metric: "Revenue (MRR)"
    baseline: "$0"
    target: "$12,000"
    window: "60 days"

audience:
  primary:
    segment: "Series A–B SaaS founders"
    message: "Ship faster without hiring a platform team"
    channels: ["LinkedIn", "founder Slack communities", "email list"]
  secondary:
    segment: "DevOps leads at mid-market companies"
    message: "Production-grade infra in minutes, not months"
    channels: ["HN", "Dev Twitter/X", "Reddit r/devops"]

phases:
  prelaunch:
    - task: "Finalize landing page and pricing"
      owner: "Design + PM"
      deadline: "2026-08-25"
    - task: "Record demo video (90 sec)"
      owner: "Marketing"
      deadline: "2026-09-01"
    - task: "Brief support team with FAQ and escalation runbook"
      owner: "Support Lead"
      deadline: "2026-09-10"
    - task: "Seed waitlist via early-access emails"
      owner: "Growth"
      deadline: "2026-09-08"

  launch_day:
    - task: "Publish Product Hunt listing at 00:01 PT"
      owner: "Marketing"
    - task: "Send launch email to waitlist"
      owner: "Growth"
    - task: "Post on LinkedIn, HN, Reddit"
      owner: "Founder + Marketing"
    - task: "Monitor error rate and infra dashboards"
      owner: "Engineering on-call"

  postlaunch:
    - task: "Send Day-3 follow-up email to new signups"
      owner: "Growth"
      deadline: "2026-09-18"
    - task: "Publish post-launch review"
      owner: "PM"
      deadline: "2026-09-22"
    - task: "Create 2 customer case studies"
      owner: "Marketing"
      deadline: "2026-10-01"

channel_matrix:
  - channel: "Product Hunt"
    message_angle: "New category — infra-as-a-service for startups"
    asset: "PH listing, maker comment, demo GIF"
    owner: "Marketing"
  - channel: "Email (waitlist)"
    message_angle: "You're in — early access is live"
    asset: "Launch email sequence (3 emails)"
    owner: "Growth"
  - channel: "LinkedIn"
    message_angle: "Founder story — why we built this"
    asset: "Long-form post + carousel"
    owner: "Founder"

escalation:
  owner: "CTO"
  war_room: "#launch-war-room (Slack)"
  rollback_plan: "Feature flag kill-switch, status page update"
```

---

## Launch Readiness Checklist

Use before every launch. Do not proceed to launch day until all critical items are checked.

### Critical (must be complete)

- [ ] Positioning and primary message finalized and approved
- [ ] Launch assets created, reviewed, and mapped to channels
- [ ] Landing page / pricing page live and QA-checked (all breakpoints, forms, payments)
- [ ] Sales and support briefed with objection-handling playbook
- [ ] Monitoring dashboard prepared (traffic, signups, errors, activation)
- [ ] Escalation owner assigned and war-room channel created
- [ ] Rollback / kill-switch plan documented and tested
- [ ] Post-launch review meeting scheduled (within 7 days)

### Important (should be complete)

- [ ] Email sequences loaded and tested (preview + deliverability)
- [ ] Social posts drafted and scheduled with correct UTM parameters
- [ ] Partner and channel notifications sent (if applicable)
- [ ] Documentation and changelog updated
- [ ] Internal announcement sent to all-hands or relevant teams
- [ ] Load testing completed for expected traffic spike

### Nice to have

- [ ] Press or analyst briefing scheduled
- [ ] Community seeding plan active (beta users, ambassadors)
- [ ] Paid amplification campaigns prepared and paused (ready to activate)
- [ ] Customer testimonials or case studies ready for social proof

---

## Output Contract

Every launch engagement must deliver:

1. **Launch plan by phase** — Tasks, owners, and deadlines for prelaunch, launch day, and postlaunch (use YAML template above)
2. **Channel-asset matrix** — Every channel mapped to message angle, asset, and owner
3. **Success metrics table** — Metric, baseline, target, and measurement window
4. **Readiness checklist** — All critical items checked before launch day
5. **Post-launch review** — Results vs. goals, learnings, and decisions within 7 days

---

## Quality Gates

- Success metrics and thresholds are explicit before work begins.
- Every launch activity has exactly one owner and a deadline.
- Sales and support are enabled and briefed before launch day.
- Rollback or kill-switch plan is documented and tested.
- Channel activation is sequenced, not simultaneous.
- Post-launch review is completed within 7 days of launch.
- Learnings are fed back to product and growth backlogs with tickets.

---

## Anti-Patterns

| Anti-Pattern | Why it fails | Fix |
|---|---|---|
| **Announcement-only launch** | Posting without activation/retention follow-through | Build full 3-phase plan with postlaunch tasks |
| **Channel-first thinking** | Choosing channels before understanding audience | Start with audience segments, then match channels |
| **No metrics until after launch** | Cannot evaluate success without pre-set criteria | Define metrics, baselines, and targets upfront |
| **Single-owner everything** | Bottleneck and single point of failure | Assign distributed ownership with clear RACI |
| **No feedback loop** | Launch outcomes never reach the roadmap | Schedule review, create tickets, close the loop |
| **Big-bang for risky launches** | All-or-nothing on unproven positioning | Use staged rollout: beta -> early access -> GA |
| **Skipping support enablement** | Support team blindsided on launch day | Brief support with FAQ and escalation runbook T−1 week |

---

## Progressive Disclosure Map

| Reference | When to read |
|---|---|
| [references/launch-plan-template.md](references/launch-plan-template.md) | When you need the raw markdown template to fill in for a specific launch |
| [references/launch-readiness-checklist.md](references/launch-readiness-checklist.md) | When running final QA before launch day — use as a gate review |
