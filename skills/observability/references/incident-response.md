# Incident Response

## Table of Contents

- [Severity Classification](#severity-classification)
- [Incident Response Workflow](#incident-response-workflow)
- [Incident Commander Responsibilities](#incident-commander-responsibilities)
- [Communication Template (Status Page)](#communication-template-status-page)
- [Blameless Post-Mortem Template](#blameless-post-mortem-template)

---

## Severity Classification

| Severity | User Impact | Response | Examples |
|---|---|---|---|
| **SEV1** | Complete outage or data loss | All hands, war room, exec comms | Service down, data corruption, security breach |
| **SEV2** | Major feature broken, >10% users affected | On-call + team lead, customer comms | Payment failing, auth broken, major degradation |
| **SEV3** | Minor feature broken, <10% users affected | On-call during business hours | Non-critical feature broken, slow performance |
| **SEV4** | Cosmetic or minimal impact | Next sprint | UI glitch, minor inconvenience |

---

## Incident Response Workflow

```
1. DETECT    → Alert fires or user reports issue
2. TRIAGE    → Assign severity, notify incident commander
3. MITIGATE  → Stop the bleeding (rollback, feature flag, scale up)
4. DIAGNOSE  → Find root cause using correlated telemetry
5. FIX       → Deploy permanent fix
6. VERIFY    → Confirm fix resolved the issue, SLOs recovering
7. COMMS     → Status page update, customer notification
8. LEARN     → Schedule post-mortem within 48 hours
```

---

## Incident Commander Responsibilities

```
The Incident Commander (IC) does NOT debug.
The IC is a coordinator:

1. Declare the incident and severity
2. Create the incident channel (#inc-YYYY-MM-DD-short-description)
3. Assign roles:
   - IC: Coordinates, makes decisions
   - Tech Lead: Drives investigation and fix
   - Comms Lead: Updates status page, stakeholders
4. Set a timer for regular status updates (every 15 min for SEV1)
5. Decide: mitigate first (rollback) or diagnose first
6. Escalate if not making progress within 30 minutes
7. Declare resolved when SLOs are back to normal
8. Schedule post-mortem
```

---

## Communication Template (Status Page)

```markdown
## [Investigating] Elevated error rates on Checkout API

**Impact:** ~5% of checkout attempts are failing with timeout errors.
**Start time:** 2026-02-25 14:32 UTC
**Current status:** Investigating. The on-call team has been paged and is
investigating elevated 503 errors on the checkout service.
**Customer impact:** Some users may experience failed checkout attempts.
Please retry in a few minutes.
**Next update:** In 15 minutes or when we have more information.

---

## [Identified] Root cause identified — database connection pool exhaustion

**Update:** Root cause identified as database connection pool exhaustion
caused by a slow query introduced in deploy v2.14.3.
**Mitigation:** Rolling back to v2.14.2.
**ETA to resolution:** ~10 minutes for rollback to complete.

---

## [Resolved] Checkout API restored to normal

**Resolution:** Rolled back to v2.14.2 at 15:01 UTC. All error rates
have returned to normal. SLOs are within target.
**Duration:** 29 minutes
**Follow-up:** Post-mortem scheduled for 2026-02-27.
```

---

## Blameless Post-Mortem Template

```markdown
# Post-Mortem: [Title of Incident]

**Date:** 2026-02-25
**Severity:** SEV2
**Duration:** 29 minutes (14:32 - 15:01 UTC)
**Authors:** [Names]
**Status:** Action items in progress

## Summary
One-paragraph summary of what happened, what the impact was, and how it
was resolved.

## Impact
- **Users affected:** ~5% of checkout attempts (estimated 1,200 users)
- **Revenue impact:** ~$18,000 in delayed orders (all recovered after fix)
- **SLO impact:** Error budget consumed: 3.2% (30-day window)
- **Duration:** 29 minutes

## Timeline (all times UTC)
| Time | Event |
|------|-------|
| 14:30 | Deploy v2.14.3 rolled out (contained slow query) |
| 14:32 | Alert: HighErrorBudgetBurn fired (P1) |
| 14:34 | IC declared, #inc-2026-02-25-checkout created |
| 14:38 | Identified: connection pool exhaustion via DB dashboard |
| 14:42 | Root cause: new query missing index, holding connections |
| 14:45 | Decision: rollback v2.14.3 → v2.14.2 |
| 14:51 | Rollback deployed |
| 15:01 | Error rates returned to normal, incident resolved |

## Root Cause
Deploy v2.14.3 introduced a new database query in the checkout flow that
was missing an index. The query took 8-12 seconds under load, exhausting
the connection pool (max 20 connections). Once the pool was exhausted,
new requests timed out with 503 errors.

## Detection
Detected by multi-burn-rate SLO alert within 2 minutes of impact starting.

## Resolution
Rolled back to v2.14.2 which did not contain the problematic query.

## What Went Well
- Alert fired quickly (2 minutes after impact)
- Rollback procedure was well-documented and fast
- IC was assigned within 2 minutes

## What Went Wrong
- No query performance testing in CI
- Missing index was not caught in code review
- Connection pool metrics were not on the service dashboard

## Action Items
| Action | Owner | Priority | Ticket |
|--------|-------|----------|--------|
| Add slow query detection to CI pipeline | @backend-team | P2 | JIRA-1234 |
| Add DB connection pool metrics to service dashboard | @platform | P2 | JIRA-1235 |
| Create index on orders.customer_id + status | @backend-team | P1 | JIRA-1236 |
| Add connection pool exhaustion runbook | @sre | P3 | JIRA-1237 |
| Review all queries added in last 30 days for missing indexes | @backend-team | P2 | JIRA-1238 |

## Lessons Learned
- Database queries need performance testing, not just correctness testing
- Connection pool size should be monitored and alerted on
- Every deploy should have a fast rollback path
```
