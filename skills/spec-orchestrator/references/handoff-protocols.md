# Handoff Protocols

Machine-readable artifact format for passing work between pipeline stages.

## Artifact Header

Every pipeline artifact includes a YAML metadata header:

```yaml
---
pipeline-id: {feature-id-YYYYMMDD}
pipeline-stage: {ideation|discovery|specification|planning|issues|implementation|review|ship}
input-from: {previous stage or "user"}
output-to: {next stage}
created: {YYYY-MM-DD}
status: {draft|in-progress|complete|blocked}
---
```

## Stage-to-Stage Requirements

### IDEATION → DISCOVERY
**Artifact:** Stress Test Report
**Required fields:**
- Thesis statement (validated)
- Assumption confidence ratings (all must be medium or high)
- Risk heat map
- Recommendation (proceed / proceed with mitigations / reconsider)

**Validation:** If any assumption is rated LOW, the pipeline pauses for user decision.

### DISCOVERY → SPECIFICATION
**Artifact:** Discovery Notes
**Required fields:**
- Problem statement
- Target user personas
- Scope boundaries (in/out)
- Key requirements gathered
- Codebase context findings

**Validation:** Problem statement must be confirmed by user.

### SPECIFICATION → PLANNING
**Artifact:** Plan-Ready PRD
**Required fields:**
- FR table with IDs (FR-001, FR-002...)
- Acceptance criteria in Given/When/Then for every FR
- NFR table with numeric targets
- Dependency markers between FRs
- AFK-eligibility hints per FR
- Module design with depth ratings
- Out-of-scope section (minimum 3 items)

**Validation:** All FRs must have IDs and acceptance criteria. Missing items block the transition.

### PLANNING → ISSUES
**Artifact:** Implementation Plan
**Required fields:**
- Phase table with all slices
- Per-slice layer details (DB, API, UI, tests)
- Dependency graph (mermaid)
- AFK/HITL classification per slice
- Phase 0 tracer bullet defined

**Validation:** Every slice must cover all layers. Phase 0 must exist.

### ISSUES → IMPLEMENTATION
**Artifact:** GitHub Issues
**Required fields:**
- Issue URLs for all slices
- Labels applied (phase, AFK/HITL, type, effort)
- Dependencies linked between issues
- At least one issue with `status:ready` + `agent:afk`

**Validation:** No orphan slices (every plan slice has a corresponding issue).

### IMPLEMENTATION → REVIEW
**Artifact:** Pull Requests
**Required fields:**
- PR per issue (linked via "Closes #N")
- All tests passing
- No regressions

**Validation:** Every issue must have a corresponding PR. CI must be green.

### REVIEW → SHIP
**Artifact:** Approved PRs
**Required fields:**
- All PRs approved (code review + security scan if applicable)
- No blocking review comments unresolved

**Validation:** HITL PRs must have explicit human approval.

## Handling Validation Failures

When a handoff validation fails:

1. **Identify the gap** — which required fields are missing?
2. **Suggest the fix** — which skill should be re-run to fill the gap?
3. **Do not proceed** — never skip a validation failure
4. **Surface to user** — present the gap and recommended action

Example:
```
⚠ Handoff validation failed: SPECIFICATION → PLANNING
Missing: FR-003 has no acceptance criteria
Fix: Re-run prd-writer Phase 3 (Requirements Interview) for FR-003
```
