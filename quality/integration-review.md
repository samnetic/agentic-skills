# External Skill Integration Review

Review date: 2026-03-01

Source candidate set: `external-skills/reused/` (10 skills)

## Decision Model

- Promote to core if strategic fit is high and quality can be normalized quickly.
- Keep as candidate if overlap is high or refactor cost is not justified yet.

## Promoted to Core

These are integrated in `skills/` with internal-standard wrappers:

1. `product-marketing-context`
2. `pricing-strategy`
3. `seo-audit`
4. `page-cro`
5. `analytics-tracking`
6. `schema-markup`
7. `copywriting`
8. `content-strategy`
9. `launch-strategy`
10. `programmatic-seo`

## Candidate Status

No remaining candidates from this batch.

## Ongoing Promotion Criteria

Future candidates are promoted when:

- Internal quality score is `A` or `B` under `--profile internal`
- Output contract and quality gates are explicit
- At least one local template/checklist is included

## Core Skill Refactor (Documentation/Specs)

Refactor date: 2026-03-01

Updated core skills:

1. `business-analysis`
2. `technical-writing`
3. `software-architecture`
4. `spec-orchestrator`
5. `agent-browser`

Refactor outcomes:

- Reduced each `SKILL.md` to lean orchestration (<500 lines) with progressive disclosure.
- Added explicit `Workflow`, `Output Contract`, and `Quality Gates` sections.
- Added audience modes (`exec`, `product`, `engineering`, plus domain-specific modes).
- Added hard word budgets to prevent overlong specifications.
- Added reusable templates/checklists under each skill's `references/` folder.
- Added top-level routing skill (`spec-orchestrator`) to select the correct
  spec/doc workflow with minimal overlap.
- Added browser automation core skill (`agent-browser`) with upstream content
  vendored under `skills/agent-browser/references/upstream/`.
- Added sync automation:
  `bash scripts/sync-agent-browser-skill.sh` (also available as
  `npm run skills:sync:agent-browser`).

Validation:

- `python3 scripts/check-skill-quality.py skills/business-analysis skills/technical-writing skills/software-architecture --profile internal --strict-frontmatter --fail-on-warn`
- `npm run skills:quality`
