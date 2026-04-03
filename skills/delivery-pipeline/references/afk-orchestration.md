# AFK Orchestration Reference

Guide for running multiple agents in parallel during Stage 6 (Implementation) and Stage 7 (Review).

---

## When to Parallelize

Parallelize when ALL of the following are true:

1. **Multiple issues are ready** — at least 2 issues have `status:ready` + `agent:afk`
2. **No mutual dependencies** — the ready issues do not block each other
3. **Distinct file scopes** — the issues modify different files or modules (minimal merge conflict risk)

```
Can these issues run in parallel?
├─ Issue A blocks Issue B? → NO, run sequentially
├─ Issue A and B modify the same files? → NO, run sequentially (or carefully)
├─ Issue A is agent:hitl? → NO for A, but B can run if it's agent:afk
├─ Both agent:afk, no dependency, different files? → YES, parallelize
└─ More than 5 ready issues? → Batch into groups of 3-5
```

---

## Maximum Parallel Agents

**Recommended: 3-5 concurrent agents.**

| Count | Guidance |
|---|---|
| 1-2 | Always safe. Use when issues touch overlapping code. |
| 3-5 | Optimal. Balances throughput with resource usage and merge conflict risk. |
| 6+ | Not recommended. Increases merge conflicts, resource contention, and makes failure recovery harder. Batch into waves of 3-5 instead. |

---

## Platform-Specific Parallel Execution

### Claude Code

Spawn multiple Agent tools in a **single message**. Each agent gets its own context and executes independently.

```
In a single response, invoke multiple Agent tool calls:

Agent 1: "Implement issue #101 — [paste issue body]. Write failing tests first (TDD).
          Create a branch feat/101-{slug}, implement, push, and create a PR linking to #101."

Agent 2: "Implement issue #102 — [paste issue body]. Write failing tests first (TDD).
          Create a branch feat/102-{slug}, implement, push, and create a PR linking to #102."

Agent 3: "Implement issue #103 — [paste issue body]. Write failing tests first (TDD).
          Create a branch feat/103-{slug}, implement, push, and create a PR linking to #103."
```

Key: all Agent tool calls in the same message execute in parallel.

### OpenCode

Use task spawning to run multiple tasks concurrently:

```
Spawn separate tasks for each issue, each with its own instruction set.
Each task operates independently and reports back on completion.
```

### Codex

Use `spawn_agent` for each independent issue:

```
For each ready issue, call spawn_agent with:
- The issue body as context
- TDD instruction prefix
- Branch naming convention
- PR creation instruction
```

---

## Context to Pass to Each Sub-Agent

Every sub-agent MUST receive:

### Required Context

| Context | Why |
|---|---|
| **Issue body** (full text) | Contains acceptance criteria, implementation hints, and scope |
| **Branch naming convention** | `feat/{issue-number}-{slug}` to avoid conflicts |
| **TDD instruction** | "Write failing tests FIRST, then implement to make them pass" |
| **PR template** | Link to issue, describe changes, include test summary |
| **Codebase patterns** | Existing patterns for imports, error handling, naming conventions |

### Optional Context (pass if available)

| Context | Why |
|---|---|
| **Related PRs** | If another issue in the same batch is in a related area |
| **Test patterns** | How existing tests are structured (describe/it, fixtures, factories) |
| **Architecture notes** | Module boundaries, dependency injection patterns |

### Sub-Agent Instruction Template

```
You are implementing GitHub issue #{number}: {title}

## Issue
{full issue body}

## Instructions
1. Create branch: feat/{number}-{slug}
2. Write FAILING tests first that cover the acceptance criteria
3. Commit the failing tests
4. Implement the minimum code to make all tests pass
5. Verify all tests pass (run the test suite)
6. Create a PR linking to #{number}
7. PR title: "feat: {description} (#{number})"

## Codebase Patterns
- Import style: {describe}
- Error handling: {describe}
- Test framework: {describe}
- Naming conventions: {describe}

## Constraints
- Do NOT modify files outside the scope of this issue
- Do NOT merge the PR — leave it for review
- If you encounter a blocker, document it in the PR description and stop
```

---

## Collecting Results

After all sub-agents complete, verify:

### Completion Checklist

```
For each sub-agent:
├─ PR created? → Check GitHub for PR linked to issue
├─ Tests exist? → Check PR diff for test files
├─ Tests pass? → Check CI status on PR
├─ Branch exists? → Verify branch naming convention
└─ No scope creep? → PR only touches files relevant to the issue
```

### How to Check

1. List all PRs created in the batch: `gh pr list --label agent:afk --state open`
2. For each PR, verify CI status: `gh pr checks {pr-number}`
3. For each PR, verify issue linkage: PR body contains `Closes #{issue-number}`
4. Update pipeline status file with PR numbers and statuses

---

## Handling Failures

### Sub-Agent Failure Modes

| Failure | Impact | Recovery |
|---|---|---|
| **Tests won't pass** | Single issue blocked | Do NOT block other agents. Flag the issue, move on. Re-attempt after other agents complete. |
| **Merge conflict** | Branch can't merge cleanly | Rebase onto main after earlier PRs merge. This is expected when batching. |
| **Scope creep** | PR modifies unexpected files | Review in Stage 7. If it touches another issue's scope, flag for manual resolution. |
| **Sub-agent hangs** | No PR created | Set a timeout expectation. If no PR after reasonable time, flag and re-attempt. |
| **Blocker discovered** | Issue can't be implemented as specified | Sub-agent documents blocker in PR description. Pipeline orchestrator surfaces to user. |

### Failure Recovery Protocol

```
After parallel execution completes:
├─ All succeeded? → Proceed to Stage 7 (Review)
├─ Some failed?
│  ├─ Failures independent of successes? → Proceed with successes, retry failures
│  ├─ Failure blocks other work? → Fix blocker first, then retry dependent issues
│  └─ Fundamental blocker? → Surface to user, pause pipeline
└─ All failed? → Something systemic is wrong. Check: test setup, CI config, branch conflicts
```

---

## TDD Enforcement

Every sub-agent MUST follow Test-Driven Development:

```
1. RED    — Write a failing test that describes the acceptance criteria
2. GREEN  — Write the minimum code to make the test pass
3. REFACTOR — Clean up while keeping tests green
```

### Verification

- Check git log on the PR branch: the first commit should be test files only
- If implementation and tests are in the same commit, flag for review (acceptable but not ideal)
- If no test files exist in the PR, reject — send back to implementation

### What to Test

| Issue Type | Test Strategy |
|---|---|
| New API endpoint | Request/response tests, validation tests, error cases |
| New UI component | Render tests, interaction tests, accessibility tests |
| Business logic | Unit tests for pure functions, integration tests for workflows |
| Data model change | Migration tests, query tests, constraint tests |
| Configuration change | Validation tests, default value tests |

---

## Wave Execution Pattern

For large features with many issues, execute in waves:

```
Wave 1 (Phase 1 issues, no dependencies):
  ├─ Agent 1: Issue #101
  ├─ Agent 2: Issue #102
  └─ Agent 3: Issue #103

Wait for Wave 1 to complete. Merge PRs.

Wave 2 (Phase 2 issues, depend on Phase 1):
  ├─ Agent 1: Issue #104
  ├─ Agent 2: Issue #105
  └─ Agent 3: Issue #106

Wait for Wave 2 to complete. Merge PRs.

Wave 3 (Phase 3 issues, depend on Phase 2):
  └─ Agent 1: Issue #107
```

This respects the dependency graph while maximizing parallelism within each phase.
