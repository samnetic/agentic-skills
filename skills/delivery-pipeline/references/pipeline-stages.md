# Pipeline Stages Reference

Detailed entry/exit criteria for every stage in the delivery pipeline.

---

## Stage 1: IDEATION

- **Purpose:** Stress-test the idea before investing in discovery and specification.
- **Required skills:** `grill-session` (mandatory), `council` (optional, for high-stakes decisions)
- **Input artifact:** Raw idea, problem statement, or user request
- **Output artifact:** Stress Test Report (`docs/pipeline/{id}/stress-test-report.md`)
- **Entry criteria:**
  - User has described a problem, idea, or feature request
  - The request is non-trivial (not a simple bug fix or config change)
- **Exit criteria:**
  - Stress Test Report exists with all assumptions listed
  - Every assumption rated medium or high confidence
  - If any assumption rated LOW: user has been consulted and made an explicit decision (accept risk, pivot, or abandon)
  - Problem statement is crisp, bounded, and agreed upon
- **AFK eligibility:** Partially. Grill-session can run autonomously, but LOW-confidence assumptions require HITL.
- **Typical duration:** 15-30 minutes

---

## Stage 2: DISCOVERY

- **Purpose:** Gather requirements through structured interview and codebase analysis.
- **Required skills:** `prd-writer` (Phases 1-3)
- **Input artifact:** Validated idea + Stress Test Report from Stage 1
- **Output artifact:** Discovery notes (internal to prd-writer, carried into Stage 3)
- **Entry criteria:**
  - Stress Test Report exists with no unresolved LOW-confidence assumptions
  - Problem statement is clear and bounded
- **Exit criteria:**
  - User personas defined with goals and pain points
  - Functional requirements enumerated (even if not yet assigned IDs)
  - Non-functional requirements enumerated with measurable targets
  - Scope boundaries agreed (explicit in/out list)
  - Open questions resolved or explicitly deferred with rationale
- **AFK eligibility:** No. Discovery requires user interview and decision-making.
- **Typical duration:** 30-60 minutes (depends on domain complexity)

---

## Stage 3: SPECIFICATION

- **Purpose:** Produce a Plan-Ready PRD that can be mechanically decomposed into an implementation plan.
- **Required skills:** `prd-writer` (Phases 4-5), `spec-orchestrator` (for complex multi-audience specs)
- **Input artifact:** Discovery notes from Stage 2
- **Output artifact:** Plan-Ready PRD (`docs/prd-{feature}.md`)
- **Entry criteria:**
  - Discovery complete: personas, requirements, and scope are defined
  - No unresolved open questions that block specification
- **Exit criteria:**
  - Plan-Ready PRD exists with YAML metadata header
  - Every functional requirement has a unique ID (FR-001, FR-002, ...)
  - Every FR has acceptance criteria (Given/When/Then or equivalent)
  - Dependencies mapped between FRs
  - AFK/HITL hints annotated on each FR
  - Non-functional requirements have measurable targets (e.g., "p95 < 200ms")
  - PRD reviewed by user (or auto-approved for AFK pipelines)
- **AFK eligibility:** Partially. PRD synthesis is autonomous, but user review is recommended for scope validation.
- **Typical duration:** 30-60 minutes

---

## Stage 4: PLANNING

- **Purpose:** Decompose the PRD into a phased, vertical-slice implementation plan with dependency ordering.
- **Required skills:** `prd-to-plan`
- **Input artifact:** Plan-Ready PRD from Stage 3
- **Output artifact:** Implementation plan (`plans/{feature}-plan.md`)
- **Entry criteria:**
  - Plan-Ready PRD exists with FR IDs and acceptance criteria
  - PRD has YAML metadata with `status: approved` or user has verbally approved
- **Exit criteria:**
  - Implementation plan exists in `plans/`
  - Work decomposed into vertical slices (each slice delivers user-visible value)
  - Phases sequenced with dependency graph
  - Each slice has estimated complexity (S/M/L)
  - Each slice classified as AFK or HITL
  - No circular dependencies in the graph
- **AFK eligibility:** Yes. Planning is deterministic given a well-structured PRD.
- **Typical duration:** 15-30 minutes

---

## Stage 5: ISSUES

- **Purpose:** Create dependency-ordered GitHub issues from the implementation plan.
- **Required skills:** `plan-to-issues`
- **Input artifact:** Implementation plan from Stage 4
- **Output artifact:** GitHub issues with URLs, labels, and dependency links
- **Entry criteria:**
  - Implementation plan exists with vertical slices, phases, and dependency graph
  - GitHub repository accessible
- **Exit criteria:**
  - GitHub issue created for every slice in the plan
  - Labels applied: `agent:afk` or `agent:hitl`
  - Labels applied: `status:ready` (no blockers) or `status:blocked` (has unmet dependencies)
  - Dependencies linked between issues (via issue body or GitHub sub-issues)
  - Issue bodies contain acceptance criteria from the PRD
  - Milestone or project board assigned (if available)
- **AFK eligibility:** Yes. Issue creation is fully automatable.
- **Typical duration:** 10-20 minutes

---

## Stage 6: IMPLEMENTATION

- **Purpose:** Execute issues using TDD, maximizing parallel agent execution for AFK work.
- **Required skills:** `qa-testing` (TDD), domain skills (`typescript-engineering`, `nodejs-engineering`, `nextjs-react`, `python-engineering`, etc.)
- **Input artifact:** GitHub issues from Stage 5
- **Output artifact:** Pull requests linked to issues, each with passing tests
- **Entry criteria:**
  - GitHub issues exist with labels and dependencies
  - At least one issue has `status:ready` + `agent:afk`
  - Codebase is in a clean state (no uncommitted changes on main)
- **Exit criteria:**
  - Every issue has a linked PR
  - Every PR has tests written TDD-style (failing test committed before implementation)
  - All tests pass in CI
  - No unresolved merge conflicts
  - AFK issues executed in parallel where possible
  - HITL issues flagged for human implementation
- **AFK eligibility:** Yes for `agent:afk` issues. HITL issues require human involvement.
- **Typical duration:** 1-4 hours (depends on feature size and parallelism)

---

## Stage 7: REVIEW

- **Purpose:** Code review, security analysis, and simplification of all PRs before merge.
- **Required skills:** `code-review`, `security-analysis`, `simplify`
- **Input artifact:** Pull requests from Stage 6
- **Output artifact:** Reviewed and approved PRs
- **Entry criteria:**
  - All PRs have passing CI
  - No draft PRs (all are ready for review)
- **Exit criteria:**
  - Every PR reviewed by `code-review` skill
  - Security scan passed (`security-analysis`)
  - Simplification pass completed (`simplify`)
  - All review feedback addressed (comments resolved, suggestions applied or rejected with rationale)
  - HITL PRs flagged for human sign-off (security-critical, payment flows, PII handling)
- **AFK eligibility:** Partially. Standard PRs can be auto-reviewed. Security/payment/PII PRs require HITL.
- **Typical duration:** 30-60 minutes

---

## Stage 8: SHIP

- **Purpose:** Merge approved PRs in dependency order, deploy, and verify the feature in production or staging.
- **Required skills:** `devops-cicd`, `git-workflows`
- **Input artifact:** Approved PRs from Stage 7
- **Output artifact:** Deployed feature, updated pipeline status
- **Entry criteria:**
  - All PRs approved and CI green
  - Merge order determined from dependency graph
  - Deployment target identified (staging, production)
- **Exit criteria:**
  - PRs merged in correct dependency order (no broken intermediate states)
  - CI/CD pipeline green after all merges
  - Feature deployed to target environment
  - Smoke tests pass on deployed environment
  - Pipeline status file updated to `complete`
- **AFK eligibility:** Partially. Merge and deploy can be automated. Production deployment may require HITL approval depending on team policy.
- **Typical duration:** 15-30 minutes
