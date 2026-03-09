---
name: seo-audit
description: >-
  Technical and on-page SEO audit workflow for software websites. Use when
  diagnosing ranking issues, crawl/indexation problems, metadata quality, site
  architecture weaknesses, or Core Web Vitals performance blockers. Triggers:
  SEO audit, technical SEO, indexation, crawlability, ranking drop, metadata
  review, search performance, site health check.
---

# SEO Audit

Run audits that produce prioritized, implementation-ready actions.

## Workflow

1. Define business goals, pages, and keyword scope.
2. Check crawlability and indexation foundations.
3. Audit technical performance and page experience.
4. Audit on-page metadata and content intent alignment.
5. Prioritize issues by impact and implementation effort.
6. Publish remediation backlog with owners and deadlines.

## Required Inputs

- Target pages and target query clusters
- Search Console and analytics access (if available)
- CMS/platform constraints
- Recent migrations or structural changes

## Progressive Disclosure Map

- Specialized edge case: [references/ai-writing-detection.md](references/ai-writing-detection.md)
- Action-plan template: [references/seo-remediation-template.md](references/seo-remediation-template.md)

## Execution Protocol

### 1) Foundations

- `robots.txt` and sitemap validity
- Index coverage anomalies
- Canonical consistency

### 2) Technical Layer

- Core Web Vitals and rendering blockers
- Mobile parity and accessibility basics
- Internal linking depth/orphan pages

### 3) On-Page Layer

- Title/meta uniqueness and intent match
- Header hierarchy and content clarity
- Structured data completeness (with rendered checks)

### 4) Prioritization

- Severity = business impact x confidence x effort inverse
- Focus first on indexation and crawl blockers

## Output Contract

Deliver:

1. Prioritized remediation backlog
2. Owner + ETA for each high-severity issue
3. Before/after measurement plan

## Quality Gates

- Top issues include reproducible evidence.
- Prioritization logic is explicit.
- Recommendations are implementation-ready.
- Measurement plan defines expected outcomes.

## Anti-Patterns

- Reporting long issue lists without priority.
- Declaring schema missing from non-rendered fetches only.
- Mixing strategic content advice with urgent technical blockers.

