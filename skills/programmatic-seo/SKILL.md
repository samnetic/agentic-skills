---
name: programmatic-seo
description: >-
  Programmatic SEO strategy and execution for software products creating pages at
  scale. Use when designing template-based landing pages, directory pages,
  integration pages, alternatives pages, or location/use-case pages with data
  pipelines and quality controls. Triggers: programmatic SEO, pages at scale,
  template pages, SEO templates, directory pages, integration pages, landing
  page generation, scalable SEO.
license: MIT
metadata:
  author: samnetic
  version: "1.0"
---

# Programmatic SEO

Scale organic growth with templated pages that remain useful and indexable.

## Core Principles

| Principle | Meaning |
|-----------|---------|
| Value-first volume | Every generated page must answer a real query better than what already ranks. Volume without utility triggers quality filters. |
| Data completeness | A page is only as good as its data. Missing fields produce thin content; stale data erodes trust. Gate publishing on field coverage. |
| Template as product | Treat each template like a product: design, test, iterate. The template defines UX, not just layout. |
| Controlled rollout | Launch in batches, measure indexation and engagement, then expand. Never ship 10k pages on day one. |
| Prune ruthlessly | Low-traffic, low-quality pages dilute crawl budget and domain authority. Define prune criteria before launch. |
| Canonical clarity | Every page needs an unambiguous canonical. Overlapping query targets cause self-cannibalization. |
| Internal link architecture | Programmatic pages must be reachable via hub/spoke linking, not orphaned in a sitemap only. |

## Workflow

1. Define page archetypes and search intent.
2. Build data model and template system.
3. Implement quality and uniqueness rules.
4. Launch in controlled batches.
5. Measure, prune, and iterate.
6. Operationalize publishing and maintenance.

## Required Inputs

- Target query classes and intent clusters
- Source datasets and freshness guarantees
- Template capabilities and CMS constraints
- Measurement plan and crawl/index monitoring

## Decision Tree: Choosing Your pSEO Approach

Use this tree to decide whether pSEO is appropriate and which playbook to pick.

```
START: Do you have a repeatable query pattern with >50 keyword variations?
 ├─ NO  → pSEO is not the right approach. Write individual pages or clusters.
 └─ YES → Do you have (or can you build) a structured dataset for those variations?
      ├─ NO  → Invest in data sourcing first. No data = thin pages = penalty risk.
      └─ YES → Is each generated page meaningfully different from the others?
           ├─ NO  → Redesign the template to pull unique data per page.
           │        Add unique stats, reviews, images, or comparison angles.
           └─ YES → Does the page provide value a searcher cannot get from
                    the top 3 current results?
                ├─ NO  → Add a unique value layer: proprietary data, tooling,
                │        interactive elements, or deeper analysis.
                └─ YES → PROCEED. Pick playbook by asset type:
                         ├─ Proprietary data     → Stats / Directory / Profiles
                         ├─ Integration ecosystem → Integration pages
                         ├─ Multi-segment users   → Persona pages
                         ├─ Local footprint        → Location pages
                         ├─ Competitor landscape   → Comparison / Alternatives
                         ├─ Educational authority  → Glossary / Curation
                         └─ Creative product       → Templates / Examples
```

## Progressive Disclosure Map

| Reference | Path | When to read |
|-----------|------|--------------|
| Playbooks (12 archetypes) | [references/playbooks.md](references/playbooks.md) | When selecting a page archetype or combining multiple playbooks |
| Launch checklist | [references/pseo-launch-checklist.md](references/pseo-launch-checklist.md) | Before deploying any batch; use as a gate review |

## Execution Protocol

### 1) Strategy and Coverage

- Pick query patterns where templating creates user value.
- Validate search volume and intent per pattern using keyword tools.
- Avoid pages with no distinct utility or intent match.
- Map each archetype to a funnel stage (awareness, consideration, decision).

### 2) Template and Data Design

- Define required content blocks per page type.
- Validate data completeness and fallback behavior.
- Set a **minimum field coverage threshold** (e.g., 80% of fields populated) before a page is published.
- Design mobile-first; programmatic pages often have high mobile share.

### 3) Implementation Example

Below is a minimal Next.js pattern for generating integration pages at build time. Adapt the data source and template to your stack.

```javascript
// pages/integrations/[slug].js — Next.js static generation example
import { getIntegrations, getIntegrationBySlug } from "@/lib/data";

export async function getStaticPaths() {
  const integrations = await getIntegrations();
  // Gate: only build pages with sufficient data completeness
  const publishable = integrations.filter(
    (i) => i.fieldCoverage >= 0.8 && i.status === "active"
  );
  return {
    paths: publishable.map((i) => ({ params: { slug: i.slug } })),
    fallback: "blocking", // ISR for new integrations
  };
}

export async function getStaticProps({ params }) {
  const data = await getIntegrationBySlug(params.slug);
  if (!data || data.fieldCoverage < 0.8) return { notFound: true };
  return {
    props: { integration: data },
    revalidate: 86400, // rebuild daily for freshness
  };
}

export default function IntegrationPage({ integration }) {
  return (
    <article>
      <h1>{integration.name} Integration</h1>
      <p>{integration.description}</p>
      <section>
        <h2>What you can do</h2>
        <ul>
          {integration.useCases.map((uc) => (
            <li key={uc.id}>{uc.title} — {uc.summary}</li>
          ))}
        </ul>
      </section>
      <section>
        <h2>Setup</h2>
        <ol>
          {integration.setupSteps.map((step, i) => (
            <li key={i}>{step}</li>
          ))}
        </ol>
      </section>
      {/* Structured data for SEO */}
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{
          __html: JSON.stringify({
            "@context": "https://schema.org",
            "@type": "HowTo",
            name: `Connect ${integration.name}`,
            step: integration.setupSteps.map((s, i) => ({
              "@type": "HowToStep",
              position: i + 1,
              text: s,
            })),
          }),
        }}
      />
    </article>
  );
}
```

Key points in this pattern:
- **Field coverage gate** prevents thin pages from being built.
- **ISR with `revalidate`** keeps data fresh without full rebuilds.
- **Structured data** is embedded per page for rich results.
- **Fallback `"blocking"`** lets new integrations appear without a redeploy.

### 4) Quality Controls

- Enforce uniqueness and thin-content guardrails.
- Run automated checks: title uniqueness, meta description length, H1 presence, minimum word count.
- Validate internal linking and canonical strategy.
- Stage rollout to monitor indexation behavior.
- Set up alerts for sudden drops in indexed page count.

### 5) Internal Linking Architecture

- Build hub pages that link to all child pages in a category.
- Cross-link related programmatic pages (e.g., integration A links to integration B if commonly used together).
- Ensure every programmatic page is reachable within 3 clicks from the homepage.
- Add breadcrumb navigation with BreadcrumbList schema.

### 6) Monitoring and Pruning

- Track per-cohort metrics: indexed %, impressions, clicks, bounce rate.
- Flag pages with zero impressions after 90 days for review.
- Prune or noindex pages below quality thresholds.
- Re-optimize top performers with richer content.

## Output Contract

Deliver:

1. Page archetype map and template spec
2. Data schema and publishing workflow
3. Rollout and monitoring plan with quality thresholds
4. Internal linking map (hub/spoke structure)
5. Pruning rules with owner and review cadence

## Quality Gates

- Every page type serves distinct search intent.
- Thin or duplicate page risk is actively controlled.
- Rollout includes indexed/page-quality monitoring.
- Low-performing page sets have prune rules.
- Field coverage threshold is enforced before publishing.
- Internal links connect programmatic pages to hub pages and to each other.

## Checklist

### Pre-Launch

- [ ] Page archetypes defined with intent mapping for each.
- [ ] Keyword research validates >50 variations with search volume.
- [ ] Data source identified and freshness SLA defined.
- [ ] Field coverage threshold set (recommended: >=80%).
- [ ] Template reviewed for uniqueness across generated pages.
- [ ] Canonical URL strategy documented; no overlapping targets.
- [ ] Internal linking plan: hub pages, cross-links, breadcrumbs.
- [ ] XML sitemap includes only publishable pages.
- [ ] robots.txt and meta robots reviewed for crawl control.
- [ ] Structured data added and validated per page type.
- [ ] Mobile rendering tested on representative pages.
- [ ] Page load performance < 2.5s LCP on sample pages.

### Launch

- [ ] Pilot batch (50-200 pages) deployed first.
- [ ] Google Search Console index coverage monitored daily for 2 weeks.
- [ ] Crawl stats reviewed for anomalies (crawl rate, errors).
- [ ] Analytics events firing correctly on programmatic pages.

### Post-Launch

- [ ] 30-day review: indexed %, impressions, CTR per cohort.
- [ ] 90-day prune review: noindex or remove zero-impression pages.
- [ ] Data freshness audit: are pages showing current data?
- [ ] Expand to next batch only after pilot metrics are acceptable.
- [ ] Quarterly review of overall pSEO portfolio health.

## Anti-Patterns

- Publishing high volume with low user value.
- Ignoring canonical/internal-link design.
- No pruning strategy for weak page cohorts.
- Launching all pages at once instead of batched rollout.
- Swapping only the city name or keyword without adding unique data per page.
- Relying on sitemap alone for discoverability (no internal links).
- Skipping structured data on programmatic page types.
