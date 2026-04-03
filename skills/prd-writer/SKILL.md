---
name: prd-writer
description: >-
  Interactive PRD creation through structured discovery, codebase validation,
  and module design. Produces Plan-Ready PRDs with dependency markers,
  AFK-eligibility hints, and vertical-slice suggestions consumable by
  prd-to-plan. Use when starting a new feature, product, or major enhancement.
  Triggers: write a PRD, create PRD, new feature PRD, product requirements,
  write requirements for, spec out, define the feature.
license: MIT
metadata:
  author: samnetic
  version: "1.0"
---

# PRD Writer

Create Plan-Ready PRDs through structured discovery that feed directly into
implementation planning.

## Core Principles

| Principle | Meaning |
|---|---|
| Discovery before documentation | Understand the problem through conversation before writing anything. Premature documentation locks in wrong assumptions. |
| Codebase-grounded | Validate every assumption against the actual codebase — don't spec features that already exist or conflict with current architecture. |
| Deep modules | Design modules with small interfaces hiding significant complexity (Ousterhout's principle). Fewer, deeper modules beat many shallow wrappers. |
| Plan-ready output | Every PRD includes structured metadata (FR IDs, dependency markers, AFK hints) that downstream tools can consume without human translation. |
| Progressive refinement | Start coarse, refine through targeted questions, freeze only when confident. Requirements evolve — fight the urge to over-specify early. |
| Testable everything | If you cannot write an acceptance test for a requirement, it is a wish, not a requirement. Remove it or make it concrete. |
| Scope is a weapon | Explicitly documenting "out of scope" prevents more rework than any amount of in-scope detail. Force at least 3 out-of-scope items. |

## Workflow

1. **Problem Discovery** — gather user context about the problem space through open-ended questions.
2. **Codebase Analysis** — explore the repo to validate assumptions, find existing patterns, identify constraints.
3. **Requirements Interview** — conduct structured questioning to fill knowledge gaps with testable requirements.
4. **Module Design** — identify major modules, assess depth and complexity, suggest boundaries.
5. **PRD Synthesis** — produce the Plan-Ready PRD document with all pipeline metadata.

## Progressive Disclosure Map

Load references only when needed. Reading them all up front wastes context.

| Reference | Path | When to read |
|---|---|---|
| Discovery interview script | [references/discovery-interview-script.md](references/discovery-interview-script.md) | Phase 1-3: question bank for requirements elicitation |
| Plan-Ready PRD template | [references/plan-ready-prd-template.md](references/plan-ready-prd-template.md) | Phase 5: when synthesizing the final PRD |
| Module depth analysis | [references/module-depth-analysis.md](references/module-depth-analysis.md) | Phase 4: when designing module boundaries |

## Trigger Conditions

**Mandatory triggers** — always activate this skill:
- "write a PRD"
- "create PRD"
- "write requirements for"
- "PRD for [feature]"

**Strong triggers** — activate when the context involves defining a new feature:
- "new feature"
- "spec out"
- "define the feature"
- "product requirements"
- "feature spec"
- "requirements document"

**Do NOT trigger on:**
- Bug reports or incident post-mortems
- Code review or refactoring tasks
- Architecture decisions without a feature context (use `software-architecture`)
- General business analysis without a specific feature target (use `business-analysis`)
- Implementation planning for an existing PRD (use `prd-to-plan`)

## Execution Protocol

### Phase 1: Problem Discovery

**Goal:** Understand the problem space before proposing any solutions.

1. Start with three open-ended questions:
   - What specific problem are you solving?
   - Who experiences this problem most acutely?
   - What does success look like?
2. Listen for and capture:
   - **User personas** — who are the people affected and what is their context?
   - **Pain points** — what hurts today and how badly?
   - **Existing workarounds** — how are users solving this now (reveals hidden requirements)?
   - **Business drivers** — why build this now? What changed?
   - **Desired outcomes** — what measurable change do we want to see?
3. Synthesize a draft **Problem Statement** (2-3 sentences) and confirm with the user.
4. **Do NOT** discuss solutions, architecture, or implementation yet. If the user
   jumps ahead, acknowledge it and steer back: "Good thought — I'll capture that
   for Phase 3. First, let me make sure I understand the problem fully."

**Exit criterion:** User confirms the problem statement is accurate.

### Phase 2: Codebase Analysis

**Goal:** Ground the PRD in reality by understanding what already exists.

1. Scan the project for:
   - **Tech stack** — framework, language version, major dependencies
   - **Directory structure** — how is the code organized?
   - **Existing models/entities** — database schemas, types, interfaces relevant to the feature
   - **API patterns** — REST/GraphQL, authentication, error handling conventions
   - **Test patterns** — testing framework, fixture patterns, coverage approach
2. Identify and report:
   - **What already exists** that is relevant to the proposed feature
   - **What constraints** the codebase imposes (e.g., "the API uses cursor pagination everywhere — new endpoints should follow suit")
   - **What patterns to follow** (e.g., "services use the repository pattern with dependency injection")
   - **What conflicts** exist between the proposed feature and current architecture
3. Present findings to the user:
   > "Based on your codebase, I see [existing patterns]. This means [implication]
   > for the feature. I also found [potential conflict] that we should address in
   > the requirements."
4. If no codebase is available (greenfield project), skip to Phase 3 and note
   "Codebase Context: Greenfield — no existing constraints" in the PRD.

**Exit criterion:** Codebase findings documented; user acknowledges constraints.

### Phase 3: Requirements Interview

**Goal:** Fill all knowledge gaps with testable, prioritized requirements.

1. Read `references/discovery-interview-script.md` for the full question bank.
2. Conduct targeted questions organized by category:
   - **Functional:** What are the core user actions? What are the edge cases? What happens on failure?
   - **Non-functional:** What are the performance, scale, and security requirements?
   - **Integration:** What existing systems does this interact with? What APIs are involved?
   - **Scope:** What is explicitly NOT part of this feature? What is "Phase 2"?
3. For each functional requirement identified:
   - Assign a unique ID: `FR-001`, `FR-002`, etc.
   - Propose acceptance criteria in **Given/When/Then** format
   - Confirm with the user: "For FR-003, I'd write the acceptance as: Given [X], When [Y], Then [Z]. Does that match your expectation?"
   - Assign priority: `Must` / `Should` / `Could` / `Won't`
4. For each non-functional requirement:
   - Demand a **numeric target** with unit: "P95 latency < 250ms", not "should be fast"
   - Specify a **validation method**: "Load test with k6 at 500 concurrent users"
5. Mark dependencies between FRs: "FR-003 depends on FR-001 (user must exist before they can configure preferences)"
6. Assess **AFK eligibility** for each FR:
   - `AFK Eligible = Yes`: The requirement can be implemented by an autonomous agent without human decision-making during implementation (clear inputs, clear outputs, no ambiguous UX decisions)
   - `AFK Eligible = No`: Requires human judgment during implementation (UX design decisions, ambiguous business rules, novel algorithm design)
7. Force an **out-of-scope** section with a minimum of 3 items. If the user says
   "nothing is out of scope," push back: "Every feature has boundaries. What
   would you cut if you had half the time?"

**Exit criterion:** All FRs have IDs, acceptance criteria, priorities, and AFK
assessments. All NFRs have numeric targets. Out-of-scope has 3+ items.

### Phase 4: Module Design

**Goal:** Identify major implementation modules and assess their depth.

1. Read `references/module-depth-analysis.md` for the depth assessment framework.
2. Based on the requirements gathered, identify 2-5 major modules the feature
   requires. A module is a cohesive unit of functionality with a defined
   interface.
3. For each module, assess:
   - **Interface size** — how many public methods/endpoints/props does it expose?
   - **Implementation complexity** — what does it hide internally (validation, state management, caching, error handling, external API calls)?
   - **Depth rating:**
     - **Deep** (good): small interface hiding significant complexity
     - **Shallow** (warning): large interface with little hidden complexity — consider merging with an adjacent module
4. Map FRs to modules: each FR should belong to exactly one module.
5. Suggest **vertical slices** — combinations of FRs that span the full stack
   (DB + API + UI + Test) and can be implemented end-to-end:
   - **Phase 0 (tracer bullet):** The thinnest possible slice that proves the architecture works. Usually 1-2 FRs spanning all layers.
   - **Phase 1-N:** Subsequent slices that build on the tracer bullet.
6. Present module design to the user for validation.

**Exit criterion:** Module design validated; FRs mapped to modules; vertical
slices identified.

### Phase 5: PRD Synthesis

**Goal:** Produce the complete Plan-Ready PRD document.

1. Read `references/plan-ready-prd-template.md` for the full template.
2. Populate every section of the template:
   - **Metadata** — author, date, status, pipeline ID
   - **Problem and Outcome** — from Phase 1
   - **Users and Jobs-to-be-Done** — from Phase 1
   - **Codebase Context** — from Phase 2
   - **Functional Requirements** — full table with ID, requirement, priority, acceptance criteria, dependencies, AFK eligibility, vertical slice
   - **Non-Functional Requirements** — full table with attribute, metric, target, validation method
   - **Module Design** — from Phase 4
   - **Scope** — in-scope and out-of-scope
   - **Dependencies, Risks, Assumptions** — from all phases
   - **Success Metrics** — with baseline and target
   - **Vertical Slice Suggestions** — from Phase 4
   - **Open Questions** — anything unresolved
   - **Next Actions** — immediate next steps with owners
3. Run all quality gates (see below).
4. Ask the user: "Where should I save this? Options: (a) markdown file in the
   project, (b) GitHub issue, (c) display inline."
5. Save or display as requested and share the file path or issue URL.

**Exit criterion:** PRD passes all quality gates; saved to user's preferred
location.

## Quality Gates

A Plan-Ready PRD is not complete unless all checks pass.

- [ ] Problem statement is clear, concise, and user-confirmed
- [ ] Codebase was analyzed and findings incorporated (or marked greenfield)
- [ ] All functional requirements have acceptance criteria in Given/When/Then format
- [ ] All non-functional requirements have numeric targets with units and validation methods
- [ ] Each FR has a unique ID (`FR-001`, `FR-002`, ...)
- [ ] Dependencies between FRs are explicitly marked (`FR-003 depends on FR-001`)
- [ ] AFK eligibility assessed for every FR with rationale
- [ ] Module design assessed for depth (no unexplained shallow modules)
- [ ] Out-of-scope section has at least 3 items
- [ ] Success metrics defined with baseline and target values
- [ ] Vertical slices identified with a Phase 0 tracer bullet
- [ ] No vague adjectives remain ("fast", "easy", "scalable") without numbers
- [ ] Terminology is consistent — each domain concept uses exactly one term throughout
- [ ] Pipeline ID assigned for downstream tool consumption

## Anti-Patterns

| Anti-Pattern | Why It's Dangerous | Fix |
|---|---|---|
| Solution-first discovery | Jumping to "how" before understanding "what" and "why" locks in wrong solutions. Users describe solutions when asked about problems — your job is to extract the real need. | Always complete Phase 1 before discussing implementation. Redirect solution talk with "Good thought — let me capture that. First, what problem does this solve?" |
| Codebase-blind requirements | Writing requirements without checking what exists leads to specifying features that already exist, conflicting with established patterns, or ignoring constraints. | Always run Phase 2 codebase scan. If the feature partially exists, document what to extend vs. build new. |
| Fuzzy acceptance criteria | "The system should be fast" or "the UI should be intuitive" cannot be tested, cannot be verified, and will be interpreted differently by every engineer. | Every NFR needs a number: "P95 latency < 250ms". Every FR needs Given/When/Then. If you cannot write the test, it is not a requirement. |
| Everything is MVP | Failing to cut scope creates unbounded features. When "everything is must-have," nothing gets shipped. | Force an out-of-scope section with at least 3 items. Ask: "What would you cut if you had half the time?" |
| Missing dependency markers | FRs that secretly depend on each other cause implementation paralysis — teams discover mid-sprint that FR-005 can't start until FR-002 is done. | Explicitly mark dependencies in the FR table. Ask for each FR: "Can this be built independently, or does it need something else first?" |
| Ignoring existing patterns | Proposing a new auth system when one already exists, or a new API style that conflicts with the existing convention, creates unnecessary tech debt. | Phase 2 codebase scan catches this. Match existing patterns unless there's a documented reason to deviate. |
| Shallow module design | Many small modules with large interfaces create coordination overhead and leak abstraction. A feature with 8 modules each exposing 5 methods is harder to build than 3 deep modules. | Apply the depth analysis framework. Merge shallow modules into adjacent deep ones. Prefer fewer, deeper abstractions. |

## Delivery Checklist

Run this checklist before sharing the final PRD.

- [ ] Problem discovery completed with user confirmation
- [ ] Codebase analyzed for relevant patterns and constraints
- [ ] Requirements interview conducted with all categories covered
- [ ] Module design validated with depth assessment
- [ ] Plan-Ready PRD generated with all sections populated
- [ ] All quality gates pass
- [ ] PRD saved to file or GitHub issue
- [ ] File path or issue URL shared with user

## Handoff Rules

- If architecture trade-offs dominate the discussion, hand off to
  `software-architecture` for an ADR, then resume PRD writing with the decision.
- If the user already has a PRD and wants an implementation plan, hand off to
  `prd-to-plan`.
- If the feature is small enough that a PRD is overkill (single FR, no
  dependencies, < 1 day of work), suggest a GitHub issue with acceptance criteria
  instead.
- If document quality or structure needs polish, hand off to
  `technical-writing` for a final pass.
