---
name: content-strategy
description: >-
  Content strategy for software products to drive qualified traffic, demand
  capture, and trust. Use when planning content pillars, topic clusters,
  editorial priorities, distribution plans, or measurement frameworks. Triggers:
  content strategy, editorial plan, topic clusters, content roadmap, blog
  strategy, thought leadership plan, SEO content planning.
---

# Content Strategy

Prioritize content work that maps directly to business outcomes. Every piece of
content must answer a real buyer question and have a clear path to revenue.

## Core Principles

| Principle | Meaning |
|---|---|
| Buyer-question first | Every content item starts from a real question your ICP asks, not a keyword or trend |
| Funnel clarity | Each piece has an explicit funnel stage and a single job: educate, convert, or retain |
| Distribution before drafting | Plan where and how content reaches the audience before writing the first word |
| Measure what matters | Track leading indicators (engagement, pipeline influence) alongside lagging ones (revenue, CAC) |
| Compound returns | Favor evergreen clusters that build authority over one-off viral attempts |
| Ruthless refresh | Retire or rewrite underperforming content quarterly; dead pages dilute domain authority |

## Workflow

1. Define content objective and funnel role.
2. Map ICP pains and buying questions.
3. Build topic clusters and content formats.
4. Prioritize using impact, confidence, and effort.
5. Plan distribution and repurposing.
6. Measure outcomes and refresh quarterly.

## Required Inputs

- ICP and positioning context
- Target funnel stage(s)
- Existing content inventory and performance
- Team bandwidth and publishing cadence

## Decision Tree — Choosing Content Approach

Use this tree to select the right content motion for the situation.

```
START
 |
 +-- Do you have an existing content library (>20 published pieces)?
 |    |
 |    YES --> Is organic traffic declining or flat quarter-over-quarter?
 |    |        |
 |    |        YES --> Run a content audit first (see §Execution 4).
 |    |        |       Prioritize refresh/consolidate over new creation.
 |    |        |
 |    |        NO  --> Are conversion rates from content < 1%?
 |    |                 |
 |    |                 YES --> Fix CTAs and conversion paths before new content.
 |    |                 NO  --> Expand clusters — add supporting posts and new formats.
 |    |
 |    NO  --> Do you have clear ICP and positioning documented?
 |             |
 |             YES --> Build 3-5 pillar clusters. Start with BOFU "vs" and
 |             |       "how-to-choose" content to capture existing demand.
 |             |
 |             NO  --> Run positioning work first (see positioning-brand-system skill).
 |                     Content without positioning is noise.
```

### Quick-Reference: Content Type by Funnel Stage

| Funnel Stage | Content Types | Primary Goal |
|---|---|---|
| TOFU (Awareness) | Blog posts, podcasts, social threads, infographics | Attract and educate |
| MOFU (Consideration) | Comparison guides, case studies, webinars, templates | Build trust and preference |
| BOFU (Decision) | Product demos, ROI calculators, free trials, "vs" pages | Capture demand and convert |
| Post-Sale (Retention) | Onboarding guides, changelog digests, community content | Reduce churn and expand |

## Progressive Disclosure Map

| Reference | Path | When to Read |
|---|---|---|
| Strategy canvas | [references/content-strategy-canvas.md](references/content-strategy-canvas.md) | When starting a new content strategy or quarterly refresh |
| Editorial calendar template | [references/editorial-calendar-template.md](references/editorial-calendar-template.md) | When building or updating the 6-8 week publishing schedule |

## Execution Protocol

### 1) Content-Pain Mapping

- List top buyer pains and questions by stage.
- Map each to a content type and distribution channel.
- Validate against real search queries, sales call transcripts, and support tickets.

### 2) Build Clusters

- Anchor pages for strategic topics (pillar content, 1500-3000 words).
- Supporting posts for long-tail queries and objections (800-1200 words).
- Conversion pathways from content to offer (inline CTAs, content upgrades).
- Internal linking plan connecting supporting posts back to pillar pages.

### 3) Prioritize

- Score ideas by business impact and execution cost.
- Keep a rolling 6-8 week content queue.
- Use the ICE framework (Impact, Confidence, Ease) on a 1-10 scale per item.

### 4) Content Audit (for existing libraries)

- Tag every piece by cluster, funnel stage, and performance tier (A/B/C/D).
- A-tier (top 10% traffic or conversions): refresh and expand.
- B-tier: optimize headlines, CTAs, and internal links.
- C-tier: consolidate with related content (301 redirect).
- D-tier: unpublish or noindex.

## Topic Cluster Blueprint Template

Use this YAML template when planning a new topic cluster:

```yaml
cluster:
  name: "Container Security for Startups"
  pillar:
    title: "The Complete Guide to Container Security"
    target_keyword: "container security guide"
    funnel_stage: TOFU
    word_count: 2500
    cta: "Download the Container Security Checklist"
  supporting_posts:
    - title: "Docker vs Podman Security Comparison"
      target_keyword: "docker vs podman security"
      funnel_stage: MOFU
      word_count: 1200
      internal_link_to: pillar
    - title: "How to Set Up Image Scanning in CI/CD"
      target_keyword: "container image scanning ci cd"
      funnel_stage: MOFU
      word_count: 1000
      internal_link_to: pillar
    - title: "Container Runtime Security Tools Compared"
      target_keyword: "container runtime security tools"
      funnel_stage: BOFU
      word_count: 1400
      internal_link_to: pillar
  conversion_content:
    - title: "Container Security Checklist (PDF)"
      type: lead_magnet
      gate: email
      funnel_stage: MOFU
  distribution:
    primary: organic_search
    secondary: [linkedin, dev_to, newsletter]
    repurpose: [twitter_thread, linkedin_carousel]
  success_metrics:
    leading: [organic_sessions, email_signups, time_on_page]
    lagging: [pipeline_influenced, MQLs_generated]
```

## Content Brief Template

Use this markdown template when briefing writers on individual pieces:

```markdown
# Content Brief: [Title]

## Meta
- **Target keyword:** [primary keyword]
- **Search intent:** [informational / commercial / navigational]
- **Funnel stage:** [TOFU / MOFU / BOFU]
- **Word count target:** [range]
- **Owner:** [name]
- **Due date:** [date]

## Audience
- **Who:** [ICP segment and role]
- **Pain:** [specific problem this content solves]
- **Current belief:** [what they think before reading]
- **Desired belief:** [what they should think after reading]

## Outline
1. Hook — [open with the pain or question]
2. Context — [why this matters now]
3. Solution — [the core answer, with evidence]
4. Proof — [data, case study, or example]
5. Next step — [CTA aligned to funnel stage]

## Internal Links
- Link TO: [list pillar and related posts]
- Link FROM: [list posts that should link to this one]

## Competitive Notes
- [Top 3 ranking URLs and what they miss]
```

## Output Contract

Deliver:

1. Content strategy canvas (filled, not blank template)
2. Prioritized 6-8 week editorial backlog with owners and deadlines
3. Measurement plan with leading and lagging indicators per funnel stage
4. At least one fully specified topic cluster blueprint

## Quality Gates

- Every content item maps to a buyer question.
- Distribution plan exists before drafting.
- Success metric defined per content objective.
- Low-performing topics have explicit retire/refresh decisions.
- Topic clusters have at least one pillar page and three supporting posts.
- Internal linking plan connects every supporting post back to its pillar.
- Content briefs include competitive gap analysis for MOFU/BOFU pieces.

## Checklist

Pre-Strategy:

- [ ] ICP profiles documented with pains, goals, and buying triggers
- [ ] Positioning and messaging framework reviewed or created
- [ ] Existing content inventory exported with traffic and conversion data
- [ ] Competitor content audit completed (top 3-5 competitors)
- [ ] Sales and support teams interviewed for recurring buyer questions

Strategy Build:

- [ ] 3-5 topic clusters defined with pillar and supporting post structure
- [ ] Each content item tagged with funnel stage and content type
- [ ] ICE scores assigned to every item in the backlog
- [ ] Distribution channels mapped per content type
- [ ] Conversion paths defined (CTAs, lead magnets, next-step offers)
- [ ] Internal linking architecture planned

Editorial Execution:

- [ ] 6-8 week editorial calendar published with owners and deadlines
- [ ] Content briefs created for the first sprint of content
- [ ] Style guide and brand voice documented or referenced
- [ ] Review/approval workflow defined (draft, review, publish)
- [ ] Repurposing plan for each pillar piece (social, email, slides)

Measurement and Iteration:

- [ ] Analytics dashboards set up for leading and lagging indicators
- [ ] Monthly content performance review scheduled
- [ ] Quarterly audit cadence established (refresh, consolidate, retire)
- [ ] Attribution model defined (first-touch, multi-touch, or pipeline influence)

## Anti-Patterns

| Anti-Pattern | Why It Fails | Fix |
|---|---|---|
| Publishing without strategic objective | Content without purpose wastes resources and dilutes brand | Tag every piece with a funnel stage and success metric before drafting |
| Keyword-volume-only topic selection | High volume often means high competition and low intent | Prioritize buyer-question fit and commercial intent over raw volume |
| No content-to-revenue path | Content becomes a cost center with no measurable ROI | Define conversion paths and CTAs for every funnel stage |
| Cluster-less content | Standalone posts lack topical authority and internal link equity | Group every post into a cluster with a clear pillar page |
| Drafting before distribution plan | Great content fails if nobody sees it | Finalize distribution channels and promotion plan before writing |
| Ignoring existing content | New content competes with your own old pages (keyword cannibalization) | Audit and consolidate before creating new pieces on similar topics |

## Escalation Rules

- If positioning or ICP is unclear, hand off to `positioning-brand-system`.
- If SEO technical issues block content performance, hand off to `seo-audit`.
- If conversion optimization is the bottleneck, hand off to `page-cro`.
- If content needs schema markup for rich results, hand off to `schema-markup`.

