# Reused Skills Quality Audit

Audit date: 2026-03-01

## Command

```bash
python3 scripts/check-skill-quality.py external-skills/reused --profile third-party
```

## Result Summary

- Skills audited: 10
- Fails: 0
- Warnings: 30

## Scores

| Skill | Grade | Score | Notes |
|---|---|---:|---|
| analytics-tracking | B | 86 | Strong structure, light validation/output detail |
| schema-markup | B | 86 | Strong structure, light validation/output detail |
| copywriting | C | 79 | Missing explicit quality gates/output contract |
| page-cro | C | 79 | Missing explicit quality gates/output contract |
| pricing-strategy | C | 79 | Missing explicit workflow heading/quality gates |
| product-marketing-context | C | 79 | Missing explicit workflow heading/output contract |
| programmatic-seo | C | 79 | Missing explicit quality gates/output contract |
| seo-audit | C | 79 | Missing explicit workflow heading/output contract |
| content-strategy | C | 72 | Weaker structure under strict internal rubric |
| launch-strategy | C | 72 | Weaker structure under strict internal rubric |

## Promotion Policy

- Promote `B` grade skills for direct usage.
- Keep `C` grade skills in candidate state until wrapped with local execution checklists.
- Do not copy-edit upstream files directly; add local overlays under `_meta/` to preserve update path.
