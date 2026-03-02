# Skills Portfolio Plan

Use a three-layer model to keep quality high and overlap low.

## Layer 1: Core Internal Skills (Highest Standard)

Custom skills authored with the internal rubric:

1. `startup-first-principles`
2. `positioning-brand-system`
3. `growth-experiment-lab`
4. `product-marketing-context`
5. `pricing-strategy`
6. `seo-audit`
7. `page-cro`
8. `analytics-tracking`
9. `schema-markup`
10. `copywriting`
11. `content-strategy`
12. `launch-strategy`
13. `programmatic-seo`

Quality command:

```bash
python3 scripts/check-skill-quality.py \
  skills/startup-first-principles \
  skills/positioning-brand-system \
  skills/growth-experiment-lab \
  --strict-frontmatter --profile internal --verbose
```

## Layer 2: Reused Candidate Skills (Curated Imports)

Installed under `external-skills/reused/` from `coreyhaines31/marketingskills`.

Quality command:

```bash
python3 scripts/check-skill-quality.py external-skills/reused --profile third-party
```

## Layer 3: Promotion Workflow

Promote third-party skills into internal standards by:

1. Adding local output contract and quality gates
2. Adding local decision thresholds and anti-patterns
3. Adding local stack-specific templates/checklists

When upgraded, move to internal quality checks (`--profile internal`).

Current state: all selected candidates in the 2026-03-01 batch were promoted to core via internal-standard wrappers.
