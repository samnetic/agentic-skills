# Progress Tracking Template

Use this template to create and maintain the pipeline status file at `docs/pipeline/{pipeline-id}/status.md`.

---

## How to Use

1. **Create** the status file when the pipeline starts (after entry point detection)
2. **Update** after every stage transition
3. **Read** when resuming a pipeline across sessions

### Pipeline ID Format

`{feature-slug}-{YYYYMMDD}`

Examples:
- `user-notifications-20260403`
- `checkout-flow-v2-20260401`
- `api-rate-limiting-20260328`

### File Location

```
docs/pipeline/{pipeline-id}/status.md
```

Create the `docs/pipeline/` directory if it does not exist.

---

## Template

Copy the template below and fill in the values. Replace all `{placeholders}` with actual data.

````markdown
# Pipeline Status: {Feature Name}

## Metadata
- **Pipeline ID:** {pipeline-id}
- **Created:** {YYYY-MM-DD}
- **Last Updated:** {YYYY-MM-DD}
- **Current Stage:** {stage number}. {Stage Name}
- **Entry Point:** {which stage the pipeline started at}

## Stage Progress

| Stage | Status | Artifact | Date |
|---|---|---|---|
| 1. Ideation | {status} | {artifact path or "—"} | {date or "—"} |
| 2. Discovery | {status} | {artifact path or "—"} | {date or "—"} |
| 3. Specification | {status} | {artifact path or "—"} | {date or "—"} |
| 4. Planning | {status} | {artifact path or "—"} | {date or "—"} |
| 5. Issues | {status} | {artifact path or "—"} | {date or "—"} |
| 6. Implementation | {status} | {artifact path or "—"} | {date or "—"} |
| 7. Review | {status} | {artifact path or "—"} | {date or "—"} |
| 8. Ship | {status} | {artifact path or "—"} | {date or "—"} |

## Open Blockers

- [ ] {Blocker description, e.g., "Issue #105 (HITL) needs design decision on notification format"}

## Parallel Execution Status

| Issue | Agent | Status | PR |
|---|---|---|---|
| #{issue} | agent-{n} | {status} | #{pr or "—"} |

## Artifacts Index

| Artifact | Path | Stage |
|---|---|---|
| Stress Test Report | {path} | 1. Ideation |
| Discovery Notes | {path} | 2. Discovery |
| Plan-Ready PRD | {path} | 3. Specification |
| Implementation Plan | {path} | 4. Planning |
| GitHub Issues | {issue URLs} | 5. Issues |
| Pull Requests | {PR URLs} | 6. Implementation |

## Decisions Log

| Date | Decision | Rationale | Stage |
|---|---|---|---|
| {date} | {what was decided} | {why} | {stage} |

## Notes

{Any session handover notes, context for next session, or things the next agent should know.}
````

---

## Status Values

Use these status values consistently:

| Status | Symbol | Meaning |
|---|---|---|
| Complete | `✅ Complete` | Stage finished, exit criteria met, artifact produced |
| In Progress | `🔄 In Progress` | Stage currently executing |
| Blocked | `🚫 Blocked` | Stage cannot proceed — blocker documented |
| Pending | `⏳ Pending` | Stage not yet started |
| Skipped | `⏭️ Skipped` | Stage not applicable (e.g., entered pipeline at a later stage) |

---

## Update Protocol

After every stage transition, update the status file with:

1. **Stage row:** change status from `🔄 In Progress` to `✅ Complete`, add artifact path and date
2. **Next stage row:** change from `⏳ Pending` to `🔄 In Progress`
3. **Current Stage** in metadata: update to the new stage
4. **Last Updated** in metadata: update to today's date
5. **Artifacts Index:** add any new artifacts
6. **Decisions Log:** add any decisions made during the stage
7. **Open Blockers:** add or resolve blockers

---

## Resumption Checklist

When resuming a pipeline from a status file:

1. Read the **Current Stage** to know where to pick up
2. Check **Open Blockers** — resolve before proceeding
3. Read the **Artifacts Index** to locate all prior outputs
4. Read the **Notes** section for session handover context
5. Validate the last completed stage's artifact still meets exit criteria (code may have changed)
6. Continue from the current stage

---

## Example: Completed Pipeline

```markdown
# Pipeline Status: User Notifications

## Metadata
- **Pipeline ID:** user-notifications-20260403
- **Created:** 2026-04-03
- **Last Updated:** 2026-04-04
- **Current Stage:** 8. Ship (Complete)
- **Entry Point:** 1. Ideation

## Stage Progress

| Stage | Status | Artifact | Date |
|---|---|---|---|
| 1. Ideation | ✅ Complete | docs/pipeline/user-notifications-20260403/stress-test-report.md | 2026-04-03 |
| 2. Discovery | ✅ Complete | (internal to prd-writer) | 2026-04-03 |
| 3. Specification | ✅ Complete | docs/prd-user-notifications.md | 2026-04-03 |
| 4. Planning | ✅ Complete | plans/user-notifications-plan.md | 2026-04-03 |
| 5. Issues | ✅ Complete | #101, #102, #103, #104, #105, #106, #107, #108 | 2026-04-03 |
| 6. Implementation | ✅ Complete | PR #201, #202, #203, #204, #205, #206, #207, #208 | 2026-04-04 |
| 7. Review | ✅ Complete | All PRs approved | 2026-04-04 |
| 8. Ship | ✅ Complete | Deployed to production | 2026-04-04 |

## Open Blockers

(none)

## Parallel Execution Status

| Issue | Agent | Status | PR |
|---|---|---|---|
| #101 | agent-1 | ✅ Complete | #201 |
| #102 | agent-2 | ✅ Complete | #202 |
| #103 | agent-3 | ✅ Complete | #203 |
| #104 | agent-1 | ✅ Complete | #204 |
| #105 | agent-2 | ✅ Complete | #205 |
| #106 | agent-3 | ✅ Complete | #206 |
| #107 | agent-1 | ✅ Complete | #207 |
| #108 | agent-2 | ✅ Complete | #208 |

## Artifacts Index

| Artifact | Path | Stage |
|---|---|---|
| Stress Test Report | docs/pipeline/user-notifications-20260403/stress-test-report.md | 1. Ideation |
| Plan-Ready PRD | docs/prd-user-notifications.md | 3. Specification |
| Implementation Plan | plans/user-notifications-plan.md | 4. Planning |
| GitHub Issues | #101-#108 | 5. Issues |
| Pull Requests | #201-#208 | 6. Implementation |

## Decisions Log

| Date | Decision | Rationale | Stage |
|---|---|---|---|
| 2026-04-03 | Use WebSocket for real-time notifications | Lower latency than polling, supported by existing infra | 3. Specification |
| 2026-04-03 | Mark issue #105 as HITL | Touches PII (notification preferences with email) | 5. Issues |

## Notes

Feature shipped successfully. All 8 issues implemented via 3 parallel agents in 2 waves.
Wave 1: #101-#103 (foundation). Wave 2: #104-#108 (features + integration).
```
