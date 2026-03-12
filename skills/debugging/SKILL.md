---
name: debugging
description: >-
  Systematic debugging and root cause analysis expertise. Use when debugging errors,
  investigating failing tests, analyzing stack traces, troubleshooting performance issues,
  diagnosing memory leaks, debugging network requests, analyzing production incidents,
  using git bisect to find regressions, profiling CPU/memory usage, debugging async code,
  investigating race conditions, reading error logs, debugging Docker containers,
  debugging database query performance, or writing post-mortem reports.
  Triggers: debug, error, bug, exception, traceback, stack trace, troubleshoot, not working,
  crash, fix, broken, undefined, null, NaN, timeout, hang, freeze, memory leak, race
  condition, flaky, intermittent, regression, post-mortem, incident, root cause.
license: MIT
metadata:
  author: samnetic
  version: "1.0"
---

# Debugging Skill

Debug systematically, not by guessing. Reproduce first, isolate second, fix third.
Every debugging session should make you smarter about the system.

---

## Core Principles

| Principle | Meaning |
|---|---|
| **Reproduce before you fix** | If you can't reproduce it, you can't verify the fix |
| **One change at a time** | Changing multiple things hides the actual cause |
| **Read the error message** | The answer is often in the first line of the error |
| **Question your assumptions** | "That can't be the problem" is where bugs hide |
| **Binary search the problem space** | Cut the search space in half with each test |
| **Leave the code better** | Add the test that would have caught this bug |

---

## Workflow: Every Debugging Session

```
1. REPRODUCE    -> Get the exact error on your machine
2. ISOLATE      -> Find the smallest input/path that triggers it
3. HYPOTHESIZE  -> Form ONE specific, falsifiable hypothesis
4. TEST         -> Verify or disprove with evidence
5. FIX          -> Apply the minimal correct fix
6. VERIFY       -> Run original reproduction + regression test
7. PREVENT      -> Add test, improve error handling, document
```

**Never skip step 1.** If you can't reproduce, you need more information.

---

### Step 1: Reproduce

**Information to gather:**

```markdown
## Bug Report Checklist
- [ ] Error message (exact text, full stack trace)
- [ ] Steps to reproduce (1, 2, 3...)
- [ ] Expected behavior vs actual behavior
- [ ] Environment (OS, Node version, browser, Docker?)
- [ ] When did it start? (commit, deploy, config change?)
- [ ] Frequency (always, sometimes, once?)
- [ ] Input data that triggers it
- [ ] Relevant logs (application, database, network)
```

**Reproduction strategies:**

| Scenario | Strategy |
|---|---|
| Always reproducible | Write a failing test immediately |
| Only in production | Check logs, replicate data/config locally |
| Intermittent | Add logging, look for timing/race conditions |
| Only under load | Load test with k6/artillery |
| Only on specific OS/browser | Docker container or BrowserStack |
| "Works on my machine" | Check env vars, versions, data differences |

---

### Step 2: Isolate

**Git bisect -- find the exact commit:**

```bash
# Manual bisect
git bisect start
git bisect bad                     # Current version has the bug
git bisect good v1.2.0             # This version was fine
# Git checks out middle commit -- test it, mark bad/good, repeat
git bisect reset                   # Return to original state

# Automated bisect with a test
git bisect start HEAD v1.2.0
git bisect run npm test -- --filter "test_name"
```

**Minimize the reproduction:**

```
Working system with bug
    -> Remove feature A -> Still broken? Keep removing
    -> Remove feature A -> Bug gone? Feature A is involved
        -> Remove half of A -> Still broken?
        -> Continue until you find the exact line/function
```

---

### Step 3-4: Hypothesize and Test

**The Falsifiability Principle:** Every hypothesis MUST be falsifiable -- define what evidence would DISPROVE your hypothesis, not just what would confirm it.

```
Hypothesis: "The bug is caused by a race condition in the payment service"

Falsifiable prediction: "If I add a mutex around the payment processing,
the bug will stop occurring under concurrent load"

If the bug persists WITH the mutex -> hypothesis disproven -> move on
If the bug stops WITH the mutex -> hypothesis supported -> find the specific race
```

**One variable at a time.** Never change two things between tests.

```
Test 1: Original input + original config -> Bug present
Test 2: Modified input + original config -> Bug present? (isolates input)
Test 3: Original input + modified config -> Bug present? (isolates config)
```

---

## Decision Tree: Common Bug Categories

| Category | Symptoms | Investigation |
|---|---|---|
| **Null/Undefined** | `Cannot read property X of undefined` | Trace data flow backward from crash point |
| **Type mismatch** | Unexpected behavior, `NaN`, `[object Object]` | Check types at each step, add logging |
| **Async/timing** | Intermittent failures, race conditions | Look for missing `await`, shared mutable state |
| **State mutation** | Inconsistent UI, stale data | Check if state is being mutated directly |
| **Off-by-one** | Wrong number of items, boundary errors | Check loop bounds, array indexes, pagination |
| **Encoding** | Garbled text, wrong characters | Check UTF-8 everywhere, URL encoding |
| **Environment** | Works locally, fails in CI/production | Check env vars, file paths, permissions |
| **Dependency** | Broke after update | Check changelog, lock file diff |
| **Network** | Timeout, wrong response | Check request/response in network tab |
| **Database** | Wrong data, constraint violations | Check query, indexes, transactions |

**Quick diagnostic techniques:**

```typescript
// Strategic logging (not console.log spam)
console.log('=== DEBUG: before processOrder ===');
console.log('Input:', JSON.stringify(order, null, 2));
console.log('User:', { id: user.id, role: user.role });

const result = processOrder(order, user);

console.log('Output:', JSON.stringify(result, null, 2));
console.log('=== DEBUG: after processOrder ===');
// Clean up: remove ALL debug logs before committing

// Node.js debugging
node --inspect src/server.js      // Chrome DevTools debugger
node --inspect-brk src/server.js  // Break on first line
```

---

## Common Debugging Scenarios

### Memory Leaks

```bash
# Node.js -- take heap snapshots
node --inspect src/server.js
# In Chrome DevTools: Memory tab -> Take Heap Snapshot
# Compare snapshots over time to find growing objects

# Common causes:
# - Event listeners not removed
# - Closures capturing large objects
# - Growing arrays/maps (caches without eviction)
# - Timers not cleared (setInterval without clearInterval)
# - Circular references preventing GC
```

> Deep-dive patterns, code fixes, and heap snapshot walkthrough: see `references/debugging-tools-and-techniques.md`

### Race Conditions

```typescript
// Symptoms: works sometimes, fails sometimes, order-dependent

// Common pattern: read-modify-write without locking
// BAD
const count = await getCount();   // Another request reads same value
await setCount(count + 1);         // Both increment from same base

// FIX: Atomic operation
await db.query('UPDATE counters SET value = value + 1 WHERE id = $1', [id]);

// FIX: Optimistic locking
const item = await db.findOne({ id, version: 5 });
const updated = await db.update({ id, version: 5 }, { ...changes, version: 6 });
if (updated.count === 0) throw new ConflictError('Item was modified');
```

### Slow Queries

```sql
-- PostgreSQL: Find slow queries
SELECT query, calls, mean_exec_time, total_exec_time
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 20;

-- Explain a specific query
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT * FROM orders WHERE user_id = 42 ORDER BY created_at DESC LIMIT 10;

-- Look for: Seq Scan (missing index), Nested Loop (N+1), Sort (missing index for ORDER BY)
```

### Docker Container Debugging

```bash
# See what's happening inside a running container
docker compose logs -f app                     # Follow logs
docker compose exec app sh                     # Shell into container
docker compose exec app node -e "console.log(process.env)"  # Check env
docker compose exec app cat /etc/hosts         # Check networking

# Container won't start?
docker compose logs app 2>&1 | head -50        # Check startup errors
docker compose run --rm app sh                 # Start fresh container with shell
docker inspect $(docker compose ps -q app)     # Full container details
```

---

## Cognitive Biases in Debugging

| Bias | How It Hurts | Counter |
|---|---|---|
| **Confirmation bias** | Only looking for evidence that supports your theory | Actively try to disprove your hypothesis |
| **Anchoring** | First idea sticks, ignore alternatives | Write down 3 hypotheses before testing any |
| **Recency bias** | Blame the last change you made | Use git bisect, not intuition |
| **Availability bias** | "Last time it was X, so it must be X again" | Start fresh, don't assume same root cause |
| **Sunk cost** | "I've spent hours on this theory, it must be right" | Time spent does not equal correctness. Abandon failing hypotheses |

---

## Scientific Debugging Method

```
1. Observe the bug carefully (exact error, conditions, timing)
2. Form at least 2-3 hypotheses
3. For each hypothesis, define:
   - What evidence would CONFIRM it
   - What evidence would DISPROVE it (falsifiability)
4. Design the simplest test that distinguishes hypotheses
5. Change ONE variable at a time
6. Record results -- do not rely on memory
7. If disproved, move to next hypothesis without regret
```

---

## Post-Mortem Template

```markdown
# Incident Post-Mortem: [Title]

## Summary
- **Date**: YYYY-MM-DD
- **Duration**: X hours/minutes
- **Severity**: Critical / High / Medium
- **Impact**: [What users experienced]

## Timeline
| Time | Event |
|------|-------|
| 14:00 | Deploy v2.3.1 to production |
| 14:05 | Error rate spikes to 30% |
| 14:10 | Alert fires, on-call acknowledged |
| 14:15 | Root cause identified: missing DB migration |
| 14:20 | Rolled back to v2.3.0 |
| 14:22 | Error rate returns to normal |

## Root Cause
[Detailed technical explanation]

## What Went Well
- Alert fired within 5 minutes
- Rollback procedure worked smoothly

## What Went Wrong
- Migration not included in deploy checklist
- No pre-deploy validation of DB schema

## Action Items
| Action | Owner | Deadline |
|--------|-------|----------|
| Add migration check to CI | @dev | Next sprint |
| Add deploy checklist to runbook | @ops | This week |
| Add integration test for new endpoint | @dev | Next sprint |

## Lessons Learned
[What we learned that applies beyond this incident]
```

---

## Anti-Patterns

| Anti-Pattern | Why It's Dangerous | Fix |
|---|---|---|
| Guessing without reproducing | Fixes wrong thing, wastes time | Reproduce first, always |
| Changing multiple things at once | Can't tell what fixed it | One change at a time |
| "It works now" without understanding why | Bug will return | Find and understand root cause |
| Leaving debug logging in code | Noise in production, possible data leak | Clean up before commit |
| Debugging in production | Risk of making it worse | Reproduce locally, add logging |
| Ignoring intermittent failures | They always get worse | Investigate race conditions, timing |
| "The tests pass so it's fine" | Tests might not cover the bug scenario | Write the missing test |
| Blaming the framework/library | 99% of the time it's your code | Check your code first |
| No post-mortem for outages | Same bugs repeat | Document and create action items |
| Fixing symptoms, not root cause | Whack-a-mole debugging | Ask "why" five times |

---

## Progressive Disclosure Map

| Topic | Reference | When to read |
|---|---|---|
| Browser DevTools (Performance, Network, Memory tabs), Console API, Node.js memory leak patterns and heap snapshot analysis | `references/debugging-tools-and-techniques.md` | When debugging frontend performance, memory leaks, or need advanced Console API usage |
| Sentry setup, breadcrumbs, source maps, release tracking, OpenTelemetry distributed tracing, structured logging, feature flags, canary deploys, session replay | `references/production-debugging-and-observability.md` | When setting up error tracking, debugging production issues, or configuring distributed tracing |

---

## Checklist: After Every Bug Fix

- [ ] Root cause identified and understood (not just symptoms)
- [ ] Fix is minimal and correct (no unrelated changes)
- [ ] Regression test added (fails without fix, passes with fix)
- [ ] All debug code removed (console.log, debug flags)
- [ ] Related code reviewed for similar issues
- [ ] Post-mortem written (if production incident)
- [ ] Action items created (if systemic issue)
- [ ] Error handling improved (if error was swallowed/unclear)
- [ ] Hypothesis was falsifiable (defined what would disprove it)
- [ ] Only one variable changed between debugging tests
- [ ] At least 2 alternative hypotheses considered before deep-diving
- [ ] Error tracking configured with proper context (Sentry breadcrumbs, tags)
- [ ] Structured logs include enough context to debug without reproducing
