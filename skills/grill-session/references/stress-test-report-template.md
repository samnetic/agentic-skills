# Stress Test Report Template

Use this template during Phase 5 to generate the final report. Replace all
`{placeholders}` with actual content from the grill session.

---

```markdown
# Stress Test Report — {Thesis Title}

**Date:** {YYYY-MM-DD HH:mm}
**Proposal by:** {user or team name if known}
**Interrogated by:** Grill Session

---

## Thesis

{The framed thesis statement from Phase 1, in the format:
"You believe that [X] because [Y], and therefore [Z]."}

---

## Assumptions Tested

### Assumption 1: {Short name}

- **Category:** {Technical Feasibility / User Behavior / Market & Timing / Resource & Effort / Dependencies / Scalability & Performance}
- **Statement:** {The assumption as stated during Phase 2}
- **Counter-argument:** {The strongest opposing view presented during interrogation}
- **User's defense:** {Summary of how the user defended this assumption}
- **Codebase findings:** {What was discovered by inspecting the code, if applicable. "N/A — not a codebase question" if not.}
- **Assessment:** {Your evaluation synthesizing the counter-argument, defense, and evidence}
- **Confidence:** **{HIGH / MEDIUM / LOW}**

### Assumption 2: {Short name}

- **Category:** {category}
- **Statement:** {statement}
- **Counter-argument:** {counter-argument}
- **User's defense:** {defense}
- **Codebase findings:** {findings or N/A}
- **Assessment:** {assessment}
- **Confidence:** **{HIGH / MEDIUM / LOW}**

{Repeat for all assumptions — typically 5–7 total. Include any new assumptions
that emerged during interrogation, marked with "(Emerged during interrogation)"
after the short name.}

---

## Risk Heat Map

| # | Assumption | Confidence | Impact if Wrong | Risk Level |
|---|---|---|---|---|
| 1 | {Short name} | {HIGH/MED/LOW} | {HIGH/MED/LOW} | {CRITICAL/HIGH/MEDIUM/LOW} |
| 2 | {Short name} | {HIGH/MED/LOW} | {HIGH/MED/LOW} | {CRITICAL/HIGH/MEDIUM/LOW} |
| ... | ... | ... | ... | ... |

**Risk Level calculation:**
- CRITICAL = LOW confidence + HIGH impact
- HIGH = LOW confidence + MEDIUM impact, or MEDIUM confidence + HIGH impact
- MEDIUM = MEDIUM confidence + MEDIUM impact
- LOW = HIGH confidence (any impact)

---

## Key Findings

### Highest Risk

{The 1–2 assumptions with the lowest confidence and highest impact. Explain why
these are the most dangerous — what happens if they're wrong, and why they
weren't adequately defended.}

### Unexpected Strengths

{Assumptions or aspects of the proposal that held up better than expected.
Highlight what evidence or reasoning made them strong. This section prevents the
report from being purely negative.}

### Emerged Assumptions

{New assumptions that were discovered during interrogation but were not in the
original list. Explain how they surfaced and their preliminary assessment.
"None" if no new assumptions emerged.}

---

## Recommendation

**Verdict: {PROCEED / PROCEED WITH MITIGATIONS / RECONSIDER / STOP}**

{2–3 sentences explaining the verdict. Be direct. Reference the confidence
distribution and highest-risk findings.}

**Confidence distribution:**
- HIGH: {count} assumptions
- MEDIUM: {count} assumptions
- LOW: {count} assumptions

---

## Suggested Mitigations

{One specific, actionable mitigation for each MEDIUM or LOW confidence
assumption. Each mitigation should be something the user can do in the next
1–2 weeks to validate or de-risk the assumption.}

| # | Assumption | Confidence | Mitigation | Effort |
|---|---|---|---|---|
| 1 | {Short name} | {MED/LOW} | {Specific action to validate or de-risk} | {Hours/days estimate} |
| 2 | {Short name} | {MED/LOW} | {Specific action to validate or de-risk} | {Hours/days estimate} |
| ... | ... | ... | ... | ... |

---

## Appendix: Session Metadata

- **Assumptions tested:** {total count}
- **Emerged during session:** {count of new assumptions}
- **Codebase inspections:** {count of times code was checked}
- **Techniques used:** {list of interrogation techniques applied}
- **Session duration:** {approximate}
```

---

## Template Usage Notes

1. **Every section is mandatory.** Do not skip sections even if the content is
   brief. An empty section signals something was missed.

2. **Confidence ratings must match Phase 3.** Do not change ratings during
   report generation — the report reflects the interrogation, not a re-evaluation.

3. **Impact assessment is new in the report.** During interrogation, you rated
   confidence. In the Risk Heat Map, you also assess impact. Use this rubric:
   - **HIGH impact:** If wrong, the project fails, ships late, or causes serious harm
   - **MEDIUM impact:** If wrong, significant rework or scope change is needed
   - **LOW impact:** If wrong, minor adjustments suffice

4. **The recommendation must be one of four values:**
   - **PROCEED** — all or nearly all assumptions are HIGH confidence
   - **PROCEED WITH MITIGATIONS** — some MEDIUM assumptions exist but are
     addressable; no LOW with HIGH impact
   - **RECONSIDER** — one or more LOW confidence + HIGH impact assumptions;
     the proposal needs fundamental changes
   - **STOP** — multiple CRITICAL-risk assumptions; the proposal as stated
     is not viable

5. **Mitigations must be specific and time-bound.** "Do more research" is not
   a mitigation. "Run a 2-hour load test against the staging database with
   synthetic data matching the expected query pattern" is a mitigation.

6. **File naming convention:** `stress-test-report-{YYYYMMDD-HHmmss}.md`
   Write to the user's working directory (not inside the skill directory).
