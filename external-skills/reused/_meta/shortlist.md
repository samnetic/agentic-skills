# Reusable Skill Shortlist (Installed)

Installed on 2026-03-01 from `coreyhaines31/marketingskills` into `external-skills/reused/`.

## Selection Criteria

- Favor skills with narrow scope and clear trigger boundaries.
- Favor operational workflows over generic advice.
- Cover the highest leverage SaaS growth surface area first.
- Keep total count small and focused (10 skills).

## Installed Skills (10)

1. `product-marketing-context`
   - Why: Shared context foundation for all downstream marketing tasks.
2. `pricing-strategy`
   - Why: Packaging, value metric, and monetization decisions.
3. `seo-audit`
   - Why: Technical/on-page diagnosis and remediation workflow.
4. `programmatic-seo`
   - Why: Scalable SEO page systems with quality constraints.
5. `schema-markup`
   - Why: Structured data implementation and validation guidance.
6. `copywriting`
   - Why: Core messaging and conversion copy execution.
7. `page-cro`
   - Why: Landing/home/pricing page conversion optimization.
8. `analytics-tracking`
   - Why: Instrumentation and measurement foundations.
9. `launch-strategy`
   - Why: Product/feature launch planning and channel sequencing.
10. `content-strategy`
    - Why: Topic planning and editorial execution structure.

## Upstream Source

- Repository: `https://github.com/coreyhaines31/marketingskills`
- Installed via: `/home/sasik/.codex/skills/.system/skill-installer/scripts/install-skill-from-github.py`

## Refresh Command

Re-run this command to fetch the same 10 paths into a fresh destination:

```bash
python3 /home/sasik/.codex/skills/.system/skill-installer/scripts/install-skill-from-github.py \
  --repo coreyhaines31/marketingskills \
  --path \
    skills/product-marketing-context \
    skills/pricing-strategy \
    skills/seo-audit \
    skills/programmatic-seo \
    skills/schema-markup \
    skills/copywriting \
    skills/page-cro \
    skills/analytics-tracking \
    skills/launch-strategy \
    skills/content-strategy \
  --dest /absolute/path/to/skills-destination
```
