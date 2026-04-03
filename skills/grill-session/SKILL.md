---
name: grill-session
description: >-
  Deep-dive interrogation that stress-tests proposals, designs, and ideas by
  exploring decision branches one at a time. Extracts hidden assumptions,
  probes weaknesses depth-first, and produces a Stress Test Report with
  confidence ratings. Use when you need to pressure-test thinking before
  committing. Triggers: grill me, grill this, stress-test this, challenge
  this, devil's advocate, what am I missing, poke holes, interrogate this.
license: MIT
metadata:
  author: samnetic
  version: "1.0"
---

# Grill Session

Stress-test one proposal depth-first — surface hidden assumptions, probe each
one sequentially with counter-arguments and recommended answers, and deliver a
Stress Test Report with confidence ratings.

## Core Principles

| Principle | Meaning |
|---|---|
| Depth over breadth | Explore one assumption branch fully before moving to the next — shallow passes across many branches produce shallow answers |
| Assumptions are the target | Every proposal contains hidden beliefs taken as fact; the job is to surface them and test whether they hold |
| Recommended answers | Always provide your own suggested answer alongside each question — don't just interrogate, help the user think through it |
| Codebase-aware | Proactively explore the codebase when a question could be answered by code inspection — avoid unnecessary back-and-forth |
| Steel-man before attacking | Understand and articulate the strongest version of the idea before poking holes — this earns trust and sharpens the critique |
| Completion over exhaustion | Stop when every assumption is validated or invalidated, not when you run out of questions — respect the user's time |
| Actionable output | End with a structured Stress Test Report containing ratings, risks, and mitigations — not just a conversation |

## Workflow

1. **Accept Thesis** — receive the proposal/design/idea to interrogate; reframe it as a testable statement.
2. **Assumption Mining** — extract 5–7 critical assumptions embedded in the thesis.
3. **Branch-by-Branch Interrogation** — for each assumption: present strongest counter-argument, ask user to defend, probe deeper with follow-ups. Provide recommended answers. Check the codebase when relevant.
4. **Synthesis** — assess confidence level (HIGH / MEDIUM / LOW) for each assumption based on the interrogation.
5. **Stress Test Report** — produce the structured output file with risk heat map, findings, and mitigations.

## Required Inputs

- A proposal, design, or idea to stress-test (not a factual question).
- As much context as possible: motivation, constraints, alternatives considered, timeline.

Optional:
- Specific files, docs, or prior decisions to include in context.
- Which assumptions the user is already uncertain about (prioritize these).

## Progressive Disclosure Map

| Reference | Path | When to read |
|---|---|---|
| Assumption extraction | [references/assumption-extraction-patterns.md](references/assumption-extraction-patterns.md) | Phase 2: before mining assumptions |
| Interrogation techniques | [references/interrogation-techniques.md](references/interrogation-techniques.md) | Phase 3: before starting branch interrogation |
| Report template | [references/stress-test-report-template.md](references/stress-test-report-template.md) | Phase 5: when generating the final report |

## Trigger Conditions

**Mandatory triggers** — always activate the grill session:
- "grill me"
- "grill this"
- "stress-test this"
- "interrogate this"

**Strong triggers** — activate when the message involves a proposal or design decision:
- "challenge this"
- "devil's advocate"
- "what am I missing"
- "poke holes"
- "pressure-test"
- "what could go wrong"

**Do NOT trigger on:**
- Factual lookups or simple yes/no questions
- Code generation or implementation tasks
- Council-style multi-option decisions (use the `council` skill instead)
- Casual creation tasks (write an email, draft a post)
- Questions where the user wants validation, not interrogation

## Execution Protocol

### Phase 1: Accept Thesis

Before any interrogation begins, establish exactly what is being tested:

1. If the user provided a clear proposal, proceed. If vague, ask one clarifying
   question to scope the thesis.
2. Check for `CLAUDE.md` in the workspace — extract project context, conventions,
   and constraints.
3. Check for `memory/` or `.claude/memory/` — extract relevant prior decisions.
4. Scan for files the user referenced or that relate to the proposal (READMEs,
   architecture docs, existing implementations).
5. Reframe the thesis into a clear testable statement:

```
THESIS
======
You believe that [X]
because [Y],
and therefore [Z].
```

6. Present the framed thesis to the user and **confirm before proceeding**.
   Do not start mining assumptions until the user agrees the framing is correct.
   If they adjust it, re-frame and confirm again.

### Phase 2: Assumption Mining

1. Read `references/assumption-extraction-patterns.md`.
2. Extract 5–7 critical assumptions across these categories:
   - **Technical Feasibility** — can this actually be built as described?
   - **User Behavior** — will users act the way the proposal assumes?
   - **Market / Timing** — is the window, demand, or competitive landscape correct?
   - **Resource / Effort** — are the time, cost, and staffing estimates realistic?
   - **Dependencies** — are external systems, APIs, or teams reliable?
   - **Scalability / Performance** — will this hold at 10x or 100x scale?
3. Present the assumptions as a numbered list with their categories:

```
ASSUMPTIONS TO TEST
===================
1. [Technical] The existing auth system can support passkey login without
   a major rewrite.
2. [User] Enterprise buyers will accept a 30-day trial instead of a POC.
3. [Resource] Two engineers can ship the MVP in 6 weeks.
...
```

4. Ask the user to **confirm, add, or remove** assumptions before proceeding.
   This is a checkpoint — do not skip it.

### Phase 3: Branch-by-Branch Interrogation

1. Read `references/interrogation-techniques.md`.
2. For **each assumption** (one at a time, depth-first — do NOT batch them):

   **Step 1: State** — Restate the assumption clearly.

   **Step 2: Steel-man the opposition** — Present the strongest counter-argument
   against this assumption. Frame it as: "The strongest case against this is..."

   **Step 3: Codebase check** — If the assumption can be partially answered by
   inspecting the codebase (e.g., "does X already exist?", "how is Y currently
   implemented?", "what does the schema look like?"), check the code **before**
   asking the user. Report what you found.

   **Step 4: Ask the user to defend** — Present a focused question that forces
   the user to defend their position. Not open-ended; point to the specific
   weakness.

   **Step 5: Follow-up probes** — Based on their response, ask 1–2 follow-up
   questions. Use techniques from the interrogation reference:
   - If they gave a surface answer → use **5 Whys** to go deeper
   - If they seem confident → use **Pre-Mortem** ("imagine this failed...")
   - If the logic seems circular → use **Reductio ad Absurdum**
   - If they said "I think" or "probably" → use **Second-Order Thinking**

   **Step 6: Recommended answer** — Provide your own assessment of this
   assumption. Be direct: "Based on what I see in the codebase and your
   responses, I think this assumption is [strong/shaky/unfounded] because..."

   **Step 7: Rate confidence** —
   - **HIGH** — Assumption validated; evidence supports it
   - **MEDIUM** — Plausible but unverified; needs more data
   - **LOW** — Serious concerns; counter-arguments were not adequately addressed

   **Step 8: Move to next** — Explicitly transition: "Moving to Assumption 2..."

3. If the user says "I don't know" to a question, **do not accept it
   immediately**. Probe deeper with Socratic method:
   - "What would need to be true for this to work?"
   - "Who in your org would know?"
   - "What's the cheapest experiment to find out?"
   Only after probing, if uncertainty remains, record it as LOW confidence.

4. If new assumptions emerge during interrogation, note them and add them to
   the list. Interrogate them after the original set is complete.

### Phase 4: Synthesis

After all assumptions have been interrogated:

1. Tally confidence ratings across all assumptions.
2. Identify the **1–2 highest-risk assumptions** (lowest confidence, highest
   impact if wrong).
3. Identify **unexpected strengths** — assumptions that held up better than
   expected during interrogation.
4. Note any **new assumptions** that emerged during questioning.
5. Present the synthesis to the user as a summary before generating the report:

```
SYNTHESIS
=========
Tested: 7 assumptions
  HIGH confidence:   3
  MEDIUM confidence: 2
  LOW confidence:    2

Highest risk: Assumption 3 (resource estimate) and Assumption 5 (API dependency)
Unexpected strength: Assumption 1 (technical feasibility) — codebase already has
  the foundation in place.
New assumption discovered: The team's familiarity with the new framework is lower
  than assumed.
```

### Phase 5: Stress Test Report

1. Read `references/stress-test-report-template.md`.
2. Generate the report following the template structure.
3. Write the report to `stress-test-report-{YYYYMMDD-HHmmss}.md` in the user's
   working directory.
4. Share the file path with the user.

The report must include all sections from the template:
- Thesis statement
- Every assumption with category, counter-argument, user's defense, assessment,
  and confidence rating
- Risk heat map table
- Key findings (highest risk, unexpected strengths, emerged assumptions)
- Clear recommendation (proceed / proceed with mitigations / reconsider / stop)
- Specific mitigations for each MEDIUM or LOW confidence assumption

## Quality Gates

- [ ] Thesis was explicitly framed and confirmed with user
- [ ] 5–7 assumptions were identified and confirmed
- [ ] Each assumption was interrogated depth-first with counter-arguments
- [ ] Codebase was consulted when questions could be answered by code inspection
- [ ] Recommended answers were provided alongside questions
- [ ] "I don't know" responses were probed deeper before accepting
- [ ] Confidence ratings assigned to every assumption
- [ ] Stress Test Report generated with all sections complete

## Anti-Patterns

| Anti-Pattern | Why It's Dangerous | Fix |
|---|---|---|
| Breadth-first questioning | Asking all questions at surface level produces shallow, non-actionable answers | Go deep on each assumption branch before moving to the next |
| Interrogation without help | Just asking questions makes the user do all the work and feels adversarial | Always provide recommended answers and your own assessment |
| Ignoring the codebase | Asking "does X exist?" when a search could answer instantly wastes user patience | Check code first; ask the user only for judgment calls |
| Turning into a council | Spawning parallel advisors or evaluating multiple options destroys sequential depth | Stay sequential and depth-first; one assumption at a time |
| Grilling for grilling's sake | Endless questioning without convergence wastes time and erodes trust | Stop when confidence is assessed; produce the report |
| Accepting "I don't know" too easily | User uncertainty is exactly where the most value lives | Probe deeper with Socratic method before recording as LOW |
| Skipping the confirmation checkpoints | Mining assumptions without user buy-in leads to interrogating the wrong things | Always confirm thesis framing and assumption list before proceeding |

## Delivery Checklist

- [ ] Thesis framed as testable statement and confirmed with user
- [ ] 5–7 assumptions mined across categories and confirmed
- [ ] All assumptions interrogated sequentially (depth-first)
- [ ] Codebase consulted for answerable questions
- [ ] Recommended answers provided for every assumption
- [ ] Confidence ratings (HIGH / MEDIUM / LOW) assigned to all assumptions
- [ ] Highest-risk assumptions identified
- [ ] Stress Test Report generated with all sections
- [ ] Report file path shared with user
