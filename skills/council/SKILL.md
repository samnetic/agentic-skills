---
name: council
description: >-
  LLM Council for high-stakes decisions. Spawns 5 independent advisors with
  different thinking styles, runs anonymous peer review, and synthesizes a
  verdict you can trust. Use when you need multiple perspectives on a decision
  where being wrong is expensive. Triggers: council this, run the council,
  pressure-test this, war room this, get multiple perspectives, validate this
  decision.
license: MIT
metadata:
  author: samnetic
  version: "1.0"
---

# LLM Council

Force 5 AI advisors to argue about your question, anonymously review each
other's work, and hand you a verdict you can actually trust.

## Core Principles

| Principle | Meaning |
|---|---|
| Independence first | Advisors respond in parallel with no knowledge of each other's answers — spawn all 5 in a single message |
| Anonymized review | Peer reviewers see shuffled letter labels (A–E), not persona names — prevents deference bias |
| Disagreement is signal | Clashes between advisors reveal genuine uncertainty; never smooth them away |
| Concrete over clever | Every recommendation must end with a specific next action, not a framework |
| Context enrichment | Scan workspace for relevant files before framing the question — richer input produces sharper output |
| Peer review is mandatory | The "what did everyone miss" question catches insights no individual advisor produces |

## Workflow

1. **Context Enrichment** — scan workspace, reframe question with stakes.
2. **Advisor Convening** — spawn 5 parallel sub-agents (one per persona).
3. **Anonymous Peer Review** — shuffle responses to A–E, spawn 5 parallel neutral reviewers.
4. **Chairman Synthesis** — synthesize verdict from all advisor + reviewer output.
5. **Report Generation** — write HTML visual report + markdown transcript.

## Required Inputs

- A decision question with real tradeoffs (not a factual lookup).
- As much context as possible: constraints, stakes, prior attempts, timeline.

Optional:
- Specific files or docs to include in context enrichment.
- Preference for which output format to prioritize (HTML, markdown, or inline).

## Progressive Disclosure Map

| Reference | Path | When to read |
|---|---|---|
| Advisor personas | [references/advisor-personas.md](references/advisor-personas.md) | Phase 2: before spawning advisor sub-agents |
| Reviewer briefing | [references/reviewer-briefing.md](references/reviewer-briefing.md) | Phase 3: before spawning peer review sub-agents |
| Chairman protocol | [references/chairman-protocol.md](references/chairman-protocol.md) | Phase 4: before writing the synthesis |
| Report template | [references/report-template.html](references/report-template.html) | Phase 5: when generating the HTML report |

## Trigger Conditions

**Mandatory triggers** — always activate the council:
- "council this"
- "run the council"
- "war room this"
- "pressure-test this"

**Strong triggers** — activate when the question involves real tradeoffs:
- "should I X or Y"
- "which option"
- "validate this decision"
- "get multiple perspectives"

**Do NOT trigger on:**
- Factual lookups or simple yes/no questions
- Code generation or implementation tasks
- Casual creation tasks (write an email, draft a post)
- Questions where the user already knows the answer and just wants validation

## Execution Protocol

### Phase 1: Context Enrichment

Before the advisors see anything, enrich the raw question:

1. Check for `CLAUDE.md` in the workspace — extract project context.
2. Check for `memory/` or `.claude/memory/` — extract relevant prior decisions.
3. Scan for files the user referenced or that relate to the question.
4. Reframe the user's raw question into a **Decision Brief**:

```
DECISION BRIEF
==============
Core question: [The actual decision to be made]
Context: [Relevant background from workspace scan]
Stakes: [What happens if you get this wrong]
Constraints: [Timeline, budget, resources, dependencies]
Known options: [Options the user has already identified]
```

Save this brief — it becomes the input for all advisors and appears in the
final transcript.

### Phase 2: Advisor Convening

1. Read `references/advisor-personas.md`.
2. Spawn **5 parallel sub-agents in a SINGLE message** (parallel execution is
   critical — advisors must not see each other's responses). Use the platform's
   sub-agent tool (`Agent` in Claude Code, `spawn_agent` in Codex CLI,
   `task` in OpenCode):
   - Sub-agent 1: The Contrarian + Decision Brief
   - Sub-agent 2: The First Principles Thinker + Decision Brief
   - Sub-agent 3: The Expansionist + Decision Brief
   - Sub-agent 4: The Outsider + Decision Brief
   - Sub-agent 5: The Executor + Decision Brief
3. Each sub-agent is instructed to respond in 150–300 words, take a clear
   position, no hedging. Include their persona prompt from the reference file.
4. Collect all 5 responses.

**Critical:** All 5 must be spawned in one message. Sequential spawning allows
later agents to be influenced by earlier results, destroying independence.

### Phase 3: Anonymous Peer Review

1. Take the 5 advisor responses and **randomly assign letters A–E** in an order
   different from the advisor order. Record the mapping (e.g., A=Executor,
   B=Contrarian, etc.) but do not share it with reviewers.
2. Strip any self-identifying language from responses (e.g., remove "As The
   Contrarian..." if present, replace with "Response [letter]:").
3. Read `references/reviewer-briefing.md`.
4. Spawn **5 parallel sub-agents in a SINGLE message**. Each reviewer
   receives:
   - All 5 anonymized responses (A–E)
   - The three review questions from the briefing
   - Instruction: 100–200 words total, be specific, cite response letters
5. Collect all 5 review responses.

### Phase 4: Chairman Synthesis

1. Read `references/chairman-protocol.md`.
2. With all 10 responses in hand (5 advisors + 5 reviewers), produce the
   chairman synthesis following the protocol structure:
   - **Where the Council Agrees** — convergent points (high confidence)
   - **Where the Council Clashes** — genuine disagreements with both sides
   - **Blind Spots Caught** — insights from peer review
   - **The Recommendation** — clear position, not "it depends"
   - **One Thing to Do First** — single concrete next step
3. De-anonymize: map letters back to persona names for the final report.
4. If two advisor arguments reinforce each other in a way neither saw alone,
   highlight that compound insight explicitly.

**Present the chairman synthesis directly to the user as your response** before
generating files.

### Phase 5: Report Generation

Generate two artifacts:

#### HTML Report

1. Read `references/report-template.html`.
2. Replace all `{{PLACEHOLDER}}` tokens with actual content:
   - `{{QUESTION_SHORT}}` — short version of the question (for title)
   - `{{QUESTION_FULL}}` — the full decision brief
   - `{{TIMESTAMP}}` — current date/time
   - `{{CONTEXT_SUMMARY}}` — one-line context summary
   - `{{RECOMMENDATION}}` — chairman recommendation text
   - `{{FIRST_ACTION}}` — the "one thing to do first"
   - `{{AGREES_LIST}}` — `<li>` items for agreement points
   - `{{CLASHES_LIST}}` — `<li>` items for clash points
   - `{{BLINDSPOTS_LIST}}` — `<li>` items for blind spots
   - `{{CONTRARIAN_RESPONSE}}` through `{{EXECUTOR_RESPONSE}}` — advisor texts
   - `{{REVIEW_STRONGEST}}`, `{{REVIEW_BLINDSPOT}}`, `{{REVIEW_MISSED}}` —
     aggregated peer review highlights
3. Write to `council-report-{YYYYMMDD-HHmmss}.html` in the working directory.

#### Markdown Transcript

Write a full transcript to `council-transcript-{YYYYMMDD-HHmmss}.md`:

```markdown
# Council Transcript — {question short}
Date: {timestamp}

## Decision Brief
{full decision brief}

## Advisor Responses

### The Contrarian
{response}

### The First Principles Thinker
{response}

### The Expansionist
{response}

### The Outsider
{response}

### The Executor
{response}

## Peer Review (Anonymized)

### Reviewer 1
{response}

### Reviewer 2–5
{responses}

## Letter Mapping
A = {persona}, B = {persona}, ...

## Chairman Synthesis
{full synthesis}
```

## Quality Gates

- [ ] All 5 advisors responded independently (spawned in one parallel message)
- [ ] Peer review was anonymized (letter labels, no persona names visible)
- [ ] At least one peer reviewer identified a blind spot
- [ ] Recommendation takes a clear position (not "it depends" or "consider both")
- [ ] One concrete next step is specified and actionable within a week
- [ ] Both HTML report and markdown transcript were generated
- [ ] HTML report renders correctly (self-contained, no external dependencies)

## Anti-Patterns

| Anti-Pattern | Why It's Dangerous | Fix |
|---|---|---|
| Sequential advisor spawning | Later agents see earlier results, destroying independence and creating groupthink | Always spawn all 5 in a single parallel message |
| Skipping peer review | Misses the highest-signal insights — "what everyone missed" catches things no individual advisor sees | Never skip; the review is the point |
| Hedged recommendation | "Consider both options" defeats the purpose — the user already has uncertainty | Chairman must take a clear position with reasoning |
| Thin context framing | Garbage in, garbage out — advisors with no context produce generic advice | Always run Phase 1 context enrichment before convening |
| Council for simple questions | Overkill wastes time and dilutes trust in the tool | Only trigger on genuine decisions with real tradeoffs |
| Reviewers knowing who wrote what | Deference bias — reviewers go easy on certain perspectives | Anonymize with shuffled letter labels |
| Summarizing instead of deciding | Chairman becomes a neutral reporter instead of a decision-maker | Chairman must synthesize, take a position, and recommend |

## Delivery Checklist

- [ ] Decision brief was framed with context, stakes, and constraints
- [ ] All 5 advisors convened in parallel
- [ ] Responses were anonymized with shuffled letter mapping
- [ ] 5 neutral peer reviewers ran in parallel
- [ ] Chairman synthesis follows the protocol structure
- [ ] Recommendation is direct and actionable
- [ ] HTML report written with all sections populated
- [ ] Markdown transcript written with full record
- [ ] Both file paths reported to user
