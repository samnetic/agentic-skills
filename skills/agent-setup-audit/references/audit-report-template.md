# Audit Report Template

Use this template when generating the audit report in Phase 6.

## Template

```markdown
# Agent Setup Audit Report

**Date:** {YYYY-MM-DD}
**Project:** {project name or path}
**Health Score:** {A/B/C/D/F}

## Health Score Legend
- **A** — Clean, minimal, no contradictions
- **B** — Minor issues, mostly clean
- **C** — Several issues needing attention
- **D** — Significant problems affecting agent behavior
- **F** — Critical contradictions causing unpredictable behavior

## Executive Summary

{2-3 sentences: how many files scanned, how many rules evaluated, how many
issues found, overall assessment.}

- **Files scanned:** {N}
- **Rules evaluated:** {N}
- **Issues found:** {N critical, N warnings, N info}

## Files Inventoried

| File | Found | Size | Last Modified | Notes |
|---|---|---|---|---|
| CLAUDE.md | ✅ | 2.1 KB | 2026-04-01 | Primary instructions |
| AGENTS.md | ❌ | — | — | Missing — should symlink to CLAUDE.md |
| .claude/settings.json | ✅ | 1.4 KB | 2026-03-28 | 3 hooks configured |

## Per-Rule Assessment

| # | Rule (summary) | File:Line | Default? | Contradicts? | Duplicates? | One-Off? | Vague? | Verdict |
|---|---|---|---|---|---|---|---|---|
| 1 | Use TypeScript strict mode | CLAUDE.md:12 | No | — | ts skill | No | No | MERGE |
| 2 | Write descriptive names | CLAUDE.md:15 | Yes | — | — | No | — | CUT |
| 3 | Never use forEach | CLAUDE.md:18 | No | — | — | Yes | No | CUT |

### Verdict Legend
- **KEEP** — rule is valuable and unique
- **CUT** — remove (default behavior, one-off, or too vague)
- **MERGE** — combine with another rule or move to appropriate skill
- **FIX** — resolve contradiction
- **CLARIFY** — make more specific

## Contradictions Found

| # | Rule A | File A | Rule B | File B | Severity | Resolution |
|---|---|---|---|---|---|---|
| 1 | "Use squash merge" | CLAUDE.md:20 | "Preserve commits" | git hook | CRITICAL | Align on one strategy |

## Duplications Found

| # | Rule | Location 1 | Location 2 | Resolution |
|---|---|---|---|---|
| 1 | "Use Zod for validation" | CLAUDE.md:25 | ts-engineering skill | Move to skill only |

## Missing Coverage

| Convention | Importance | Recommended Location |
|---|---|---|
| Error handling patterns | SHOULD-FIX | CLAUDE.md or debugging skill |

## Reviewer Consensus

| # | Finding | Minimalist | Consistency | Best Practices | Consensus |
|---|---|---|---|---|---|
| 1 | Remove default rules | CUT | AGREE | AGREE | CUT (3/3) |
| 2 | Add AGENTS.md symlink | — | MUST-FIX | MUST-FIX | FIX (2/3) |

## Recommended Changes

### P0: Critical (fix immediately)
1. {contradiction or missing critical config}

### P1: Important (fix this session)
1. {redundancy removal, clarification needed}

### P2: Nice-to-Have (next maintenance cycle)
1. {minor improvements, style consistency}

## Proposed Cleaned-Up CLAUDE.md

{Full rewritten CLAUDE.md with all recommendations applied.
Only include if changes are significant enough to warrant a rewrite.}

## Action Items

- [ ] P0: {action}
- [ ] P1: {action}
- [ ] P2: {action}
```

## Scoring Rubric

| Grade | Criteria |
|---|---|
| A | 0 contradictions, 0 duplications, <2 default-behavior rules, AGENTS.md symlinked |
| B | 0 contradictions, ≤3 duplications, ≤5 default-behavior rules |
| C | 1-2 contradictions, ≤5 duplications, or missing AGENTS.md |
| D | 3+ contradictions, or >10 default-behavior rules wasting context |
| F | Critical contradictions causing non-deterministic agent behavior |
