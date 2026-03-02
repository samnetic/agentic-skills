# Skills Quality Rubric

Use this rubric to keep the skill portfolio high quality and intentionally small.

## Scoring Model

Score each dimension from 0 to 5.

| Dimension | What to Measure |
|---|---|
| Trigger precision | Description clearly states when to use and when not to use |
| Workflow rigor | Step-by-step process with concrete outputs |
| Decision quality | Explicit quality gates, thresholds, and anti-patterns |
| Progressive disclosure | Lean SKILL.md with references/scripts loaded only when needed |
| Reusability | Templates, scripts, or assets that reduce repeated work |
| Validation | Built-in checks, test guidance, or measurable completion criteria |

Total score: `0-30`

## Grade Bands

- `A (26-30)`: Keep and promote
- `B (22-25)`: Keep and improve
- `C (18-21)`: Keep only if high strategic value
- `D (<18)`: Retire, merge, or redesign

## Portfolio Rules

- Keep active skills small and focused by job-to-be-done.
- Prefer one strong skill per problem over many overlapping skills.
- Require explicit trigger boundaries before adding a new skill.
- Reuse external skills only after local quality review.

## Intake Checklist for Third-Party Skills

1. Verify source quality and maintenance activity.
2. Verify trigger wording and overlap with existing skills.
3. Verify workflow is actionable (not generic advice).
4. Verify evidence quality for claims in high-stakes topics.
5. Add local notes for any customization required by your stack.

## Maintenance Cadence

- Monthly: fast-moving domains (SEO, paid growth, AI channels)
- Quarterly: slower strategic domains (positioning, pricing, GTM)
- After major launches: refresh relevant skill references and templates

## Validation Commands

Internal skills:

```bash
python3 scripts/check-skill-quality.py skills/<skill-name> --profile internal --strict-frontmatter --verbose
```

Third-party candidate skills:

```bash
python3 scripts/check-skill-quality.py external-skills/reused --profile third-party
```
