---
name: plan-to-issues
description: >-
  Convert implementation plans into GitHub issues with dependency links,
  AFK/HITL classification, and standardized labels. Creates issues in
  dependency order via gh CLI, maximizing parallelism for autonomous agent
  execution. Use when you have an implementation plan and need trackable
  issues. Triggers: create issues from plan, plan to issues, break plan into
  issues, create GitHub issues, convert plan to tickets, file issues for this.
license: MIT
metadata:
  author: samnetic
  version: "1.0"
---

# Plan to Issues

Convert implementation plans into dependency-ordered GitHub issues that agents can execute autonomously.

## Core Principles

| # | Principle | Rationale |
|---|-----------|-----------|
| 1 | **Dependency order** | Issues are created in topological order — blockers first, dependents after. This ensures every issue reference (`#N`) resolves correctly at creation time and agents never start blocked work. |
| 2 | **AFK by default** | Tag issues as AFK (autonomous) unless they meet HITL criteria. Maximize what agents can do without human intervention — only escalate when the decision tree demands it. |
| 3 | **Thin issues** | Each issue is one vertical slice — small enough to implement in a single session. If an issue spans multiple layers, it still delivers one observable behavior end to end. |
| 4 | **Self-contained** | Every issue includes enough context to be worked on independently. No "see issue #X for context" — duplicate relevant context instead. An agent picking up the issue cold must be able to start immediately. |
| 5 | **Labels are API** | Standardized labels enable automation, filtering, and dashboard reporting. Labels are not decoration — they are the interface between issue creation and downstream tooling. |
| 6 | **Durable descriptions** | Describe behaviors and acceptance criteria, not file paths or line numbers. Code locations change; behaviors and contracts do not. |

## Workflow

```
┌─────────────┐    ┌──────────────────┐    ┌──────────────┐
│ 1. Ingest   │───▶│ 2. Validate      │───▶│ 3. Draft     │
│    Plan      │    │    Completeness   │    │    Issues    │
└─────────────┘    └──────────────────┘    └──────────────┘
                                                   │
                                                   ▼
┌─────────────┐    ┌──────────────────┐    ┌──────────────┐
│ 6. Summary  │◀───│ 5. Create        │◀───│ 4. Classify  │
│    Report    │    │    Issues (gh)    │    │    AFK/HITL  │
└─────────────┘    └──────────────────┘    └──────────────┘
```

1. **Ingest Plan** — Accept implementation plan from prd-to-plan output, file path, or pasted content
2. **Validate Completeness** — Check all phases and slices have required fields; flag gaps
3. **Draft Issues** — Generate issue body for each slice using the issue template
4. **Classify AFK/HITL** — Apply decision tree to each issue; override plan tags if warranted
5. **Create Issues** — Use `gh issue create` in dependency order, linking dependencies via comments
6. **Summary Report** — Present created issues with URLs, dependency map, and next-step suggestions

## Progressive Disclosure Map

| Reference | Path | When to read |
|---|---|---|
| AFK classification tree | `references/afk-classification-decision-tree.md` | Phase 4: before classifying issues |
| Issue template | `references/issue-template.md` | Phase 3: when drafting issue bodies |
| Label taxonomy | `references/label-taxonomy.md` | Phase 5: when applying labels |

> **Read references lazily.** Only load a reference file when you reach the phase that needs it.

## Trigger Conditions

### Mandatory triggers (always activate this skill)
- "create issues from plan"
- "plan to issues"
- "convert plan to tickets"

### Strong triggers (activate with high confidence)
- "break plan into issues"
- "create GitHub issues"
- "file issues for this"
- "turn this plan into trackable work"

### Do NOT trigger on
- PRD creation → use `prd-writer`
- Plan creation → use `prd-to-plan`
- Issue triage or prioritization → use `github-triage`
- Individual issue creation without a plan → just use `gh issue create` directly

## Execution Protocol

### Phase 1: Ingest Plan

Accept the plan from one of:
- A file path (e.g., `docs/plan.md`)
- Pasted content in the conversation
- Output from a prior `prd-to-plan` run

Parse the plan and extract:
- **Phases** — numbered groups of work (Phase 0, Phase 1, ...)
- **Slices** — individual vertical slices within each phase
- **Functional requirements** — FR IDs covered by each slice
- **Dependencies** — which slices depend on which
- **AFK/HITL tags** — if the plan already classified them
- **Acceptance criteria** — per-slice success conditions
- **Layer details** — database, backend, frontend, test specifics

Confirm with the user:
> "This plan has **{N} phases** with **{M} slices** total. {K} slices have dependencies. Shall I create issues?"

### Phase 2: Validate Completeness

For each slice, verify it has:
- [ ] Name and description
- [ ] At least one functional requirement covered
- [ ] Acceptance criteria (Given/When/Then or equivalent)
- [ ] Layer details (what to build at each layer)

Validate dependency integrity:
- [ ] No circular dependencies
- [ ] No references to nonexistent slices
- [ ] Dependency graph is a valid DAG

Flag gaps interactively:
> "Slice '{name}' is missing acceptance criteria. Should I draft them based on the FRs it covers?"

Do NOT proceed to Phase 3 until all slices pass validation or the user explicitly approves gaps.

### Phase 3: Draft Issues

Read `references/issue-template.md` for the standard template.

For each slice, generate the issue body containing:
1. **Context** — 1-2 sentence summary from the PRD/plan
2. **Pipeline and phase metadata** — for tracking
3. **Acceptance criteria** — directly from the plan, in Given/When/Then format
4. **Implementation hints** — layer-by-layer table from the plan
5. **Dependencies** — which issues block this one (placeholder until Phase 5 resolves numbers)
6. **Functional requirements covered** — FR IDs
7. **Verification checklist** — standard checks every PR must pass

Keep issue bodies concise but self-contained. An agent reading only this issue must understand what to build and how to verify it.

### Phase 4: Classify AFK/HITL

Read `references/afk-classification-decision-tree.md`.

For each issue:
1. Walk through the 9-question decision tree
2. Assign classification: `AFK (high)`, `AFK (medium)`, or `HITL`
3. Record the rationale (which question determined the classification)

Override rules:
- If the plan already classified an issue, respect it **unless** the decision tree clearly disagrees
- When overriding, document the reason in the issue body:
  > "Plan tagged as AFK, but reclassified to HITL because it touches user session management (Question 1)."
- When in doubt, default to HITL — cheaper to over-review than to miss a security issue

### Phase 5: Create Issues

Read `references/label-taxonomy.md` for the standard label set.

**Pre-flight: ensure labels exist.** Before creating issues, run the label creation commands from the taxonomy. Use `--force` to update existing labels without error.

**Create issues in topological order** (dependencies first):

```bash
# Example: creating a Phase 0 issue with no dependencies
gh issue create \
  --title "[Phase 0] Slice: Tracer bullet — create and display todo item" \
  --body "$ISSUE_BODY" \
  --label "phase:0" \
  --label "agent:afk" \
  --label "type:feature" \
  --label "effort:m" \
  --label "status:ready"
```

After each issue is created:
1. Capture the issue number from `gh` output
2. Replace dependency placeholders in subsequent issues with actual `#N` references
3. For dependent issues, add a comment linking blockers:
   ```bash
   gh issue comment $ISSUE_NUMBER --body "Blocked by #$BLOCKER_NUMBER"
   ```
4. Apply `status:ready` only to issues with no unresolved blockers; use `status:blocked` otherwise

### Phase 6: Summary Report

Present a table of all created issues:

| # | Title | Phase | AFK/HITL | Dependencies | URL |
|---|-------|-------|----------|--------------|-----|
| 1 | [Phase 0] Slice: Tracer bullet | 0 | AFK (high) | None | url |
| 2 | [Phase 1] Slice: User CRUD | 1 | AFK (high) | #1 | url |
| 3 | [Phase 1] Slice: Auth flow | 1 | HITL | #2 | url |

Show the dependency graph:

```
#1 (Tracer bullet)
├── #2 (User CRUD)
│   └── #3 (Auth flow)
│   └── #4 (Profile page)
└── #5 (API error handling)
```

Highlight actionable next steps:
> **Ready now (no blockers):** #1, #5
> **AFK issues assignable to agents:** #1, #2, #5
> **HITL issues needing human attention:** #3

## Quality Gates

- [ ] All plan slices mapped to issues (no orphans)
- [ ] AFK/HITL classification applied to every issue with rationale
- [ ] Dependencies linked correctly (no circular references)
- [ ] Every issue has acceptance criteria in Given/When/Then format
- [ ] Labels applied from standardized taxonomy (phase + classification + type minimum)
- [ ] Issues created in dependency order (blockers before dependents)
- [ ] Summary report generated with URLs and dependency graph
- [ ] `status:ready` / `status:blocked` labels accurate

## Anti-Patterns

| Anti-Pattern | Why It's Dangerous | Fix |
|---|---|---|
| **Fat issues** | An issue covering multiple slices is too large for a single agent session; increases merge conflicts and review burden | One vertical slice per issue — if it takes more than one session, split it |
| **Missing context** | "Implement the payment flow" with no acceptance criteria leaves agents guessing and humans reviewing ambiguous PRs | Every issue is self-contained with Given/When/Then acceptance criteria |
| **File path references** | "Modify `src/controllers/user.ts` line 45" becomes stale after any refactor | Describe behaviors and contracts, not file locations |
| **HITL everything** | Marking all issues as HITL defeats the purpose of autonomous execution and creates a human bottleneck | Use the decision tree honestly; default to AFK unless a specific question triggers HITL |
| **Ignoring dependencies** | Creating issues without linking blockers means agents waste time on work they cannot complete | Topological sort before creation; `status:blocked` labels on dependent issues |
| **Labels as decoration** | Applying labels inconsistently breaks filtering, dashboards, and automation | Use the standardized taxonomy for every issue — phase + classification + type minimum |
| **Stale dependency comments** | Adding "Blocked by #X" but never updating when #X is resolved | Use `status:blocked` / `status:ready` labels as the source of truth; comments are supplementary |

## Delivery Checklist

- [ ] Plan ingested and parsed (phases, slices, dependencies extracted)
- [ ] Completeness validated (all slices have required fields)
- [ ] Issues drafted with full context using standard template
- [ ] AFK/HITL classified for every issue with rationale
- [ ] Labels created in repo (idempotent, safe to re-run)
- [ ] Issues created via `gh issue create` in dependency order
- [ ] Dependencies linked with comments and status labels
- [ ] Summary report with URLs and dependency graph shared with user
