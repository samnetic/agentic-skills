---
name: business-analysis
description: >-
  Business analysis and requirements engineering expertise. Use when writing Product
  Requirements Documents (PRDs), defining user stories with acceptance criteria,
  eliciting requirements from stakeholders, creating data flow diagrams, performing
  stakeholder mapping, prioritizing features (MoSCoW, RICE, WSJF), designing user
  journey maps, writing functional and non-functional specifications, creating
  wireframe specifications, defining MVP scope, writing technical specifications
  from business requirements, creating process flow diagrams, defining success
  metrics and KPIs, conducting gap analysis, or translating business needs into
  technical requirements.
  Triggers: PRD, product requirements, user story, acceptance criteria, stakeholder,
  requirements, specification, MVP, scope, prioritization, MoSCoW, RICE, user journey,
  data flow, wireframe, KPI, success metric, gap analysis, business requirement,
  functional requirement, non-functional requirement, use case.
---

# Business Analysis Skill

Bridge the gap between business needs and technical implementation. Clear requirements
prevent building the wrong thing. Ambiguity is the enemy — make everything explicit.

---

## Core Principles

| Principle | Meaning |
|---|---|
| **Start with the problem, not the solution** | Understand WHY before defining WHAT |
| **Users, not features** | Who benefits and how? Not just "add feature X" |
| **Measurable outcomes** | Every requirement has acceptance criteria you can test |
| **Explicit over assumed** | Write down what seems obvious. Assumptions cause bugs |
| **MVP is the smallest thing that tests the hypothesis** | Not the smallest complete product |
| **Iterate on understanding** | Requirements evolve. Plan for revision, not perfection |

---

## Workflow: Requirements to Implementation

```
1. DISCOVER  → Understand the problem, users, and context
2. DEFINE    → Write requirements with acceptance criteria
3. PRIORITIZE → Rank by value/effort, define MVP scope
4. SPECIFY   → Detailed specs, data flows, edge cases
5. VALIDATE  → Review with stakeholders, confirm understanding
```

---

## Product Requirements Document (PRD) Template

```markdown
# PRD: [Feature Name]

## Problem Statement
What problem are we solving? For whom? Why now?
[2-3 sentences. Focus on the user's pain, not the solution]

## Users
| User Type | Description | Need |
|-----------|-------------|------|
| End user | ... | ... |
| Admin | ... | ... |

## Goals & Success Metrics
| Goal | Metric | Target | Measurement |
|------|--------|--------|-------------|
| Reduce manual work | Time spent on task X | -50% | Time tracking |
| Improve accuracy | Error rate | <1% | Error logs |
| Increase adoption | DAU of feature | 500 | Analytics |

## Scope

### In Scope (MVP)
1. [Must have — core functionality]
2. [Must have — essential for usability]

### In Scope (Post-MVP)
1. [Nice to have — enhances experience]
2. [Nice to have — optimization]

### Out of Scope
1. [Explicitly excluded — and why]
2. [Deferred to future iteration — and why]

## User Stories
[See format below]

## Non-Functional Requirements
- Performance: API response < 200ms P95
- Security: Role-based access, audit logging
- Scalability: Support 10x current user base
- Accessibility: WCAG 2.2 AA compliance

## Dependencies
- [External API: Payment provider sandbox access]
- [Team: Design team delivers mockups by date]

## Risks & Mitigations
| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| API rate limits | Medium | High | Implement caching + queue |

## Timeline
| Phase | Scope | Target Date |
|-------|-------|-------------|
| MVP | Core features | Week 4 |
| v1.1 | Polish + feedback | Week 6 |

## Open Questions
1. [Question that needs stakeholder answer]
2. [Technical decision that needs investigation]
```

---

## User Stories

### Format

```
As a [type of user],
I want to [action/capability],
so that [benefit/outcome].
```

### Acceptance Criteria (Given-When-Then)

```markdown
### Story: User can filter products by category

As a shopper,
I want to filter products by category,
so that I can quickly find what I'm looking for.

**Acceptance Criteria:**

GIVEN I am on the products page
WHEN I select "Electronics" from the category filter
THEN only products in the "Electronics" category are displayed
AND the URL updates to include the filter parameter
AND the product count updates to show filtered total

GIVEN I have a category filter applied
WHEN I click "Clear filters"
THEN all products are displayed
AND the URL parameter is removed

GIVEN I am on a filtered product list
WHEN I refresh the page
THEN the filter is preserved from the URL
AND the same filtered results are shown

**Edge Cases:**
- Category with no products shows "No products found" message
- Multiple categories can be selected simultaneously
- Filter works with search query combined
```

### Acceptance Criteria Patterns — Advanced

Write acceptance criteria that cover not just the happy path, but edge cases, boundary conditions, and error states.

```markdown
### Pattern: Boundary Conditions

GIVEN a user enters a username
WHEN the username is exactly 3 characters (minimum)
THEN the username is accepted

WHEN the username is 2 characters (below minimum)
THEN an inline error shows "Username must be at least 3 characters"

WHEN the username is exactly 50 characters (maximum)
THEN the username is accepted

WHEN the username is 51 characters (above maximum)
THEN input is truncated to 50 characters
AND a character counter shows "50/50"

### Pattern: Concurrent Access

GIVEN two users are editing the same document
WHEN User A saves changes
THEN User B sees a notification "Document updated by User A"
AND User B can choose to "Reload" or "Keep editing"

WHEN User B chooses "Keep editing" and saves
THEN a conflict resolution screen shows both versions
AND User B can choose which changes to keep

### Pattern: Error Recovery

GIVEN a user is submitting a multi-step form
WHEN the network fails during submission
THEN the form data is preserved in localStorage
AND an error message shows "Submission failed. Your data has been saved."
AND a "Retry" button is displayed

WHEN the user clicks "Retry"
THEN the previously entered data is restored
AND submission is attempted again

### Pattern: Empty States

GIVEN a new user with no projects
WHEN they navigate to the Projects page
THEN a helpful empty state shows:
  - Illustration/icon
  - "No projects yet" heading
  - "Create your first project to get started" description
  - A prominent "Create Project" button
```

### Story Sizing (INVEST Criteria)

| Criteria | Question |
|---|---|
| **I**ndependent | Can this story be implemented without other stories? |
| **N**egotiable | Can scope be discussed with stakeholders? |
| **V**aluable | Does it deliver value to a user? |
| **E**stimable | Can the team estimate the effort? |
| **S**mall | Can it be completed in one sprint? |
| **T**estable | Can we write acceptance criteria? |

---

## Prioritization Frameworks

### MoSCoW Method

| Priority | Meaning | Guideline |
|---|---|---|
| **Must** | Without this, the release is a failure | ~60% of effort |
| **Should** | Important but not critical | ~20% of effort |
| **Could** | Nice to have, easy wins | ~20% of effort |
| **Won't** | Agreed to not do (this time) | Document for transparency |

### RICE Score

```
RICE = (Reach x Impact x Confidence) / Effort

Reach: How many users per quarter? (number)
Impact: How much per user? (3=massive, 2=high, 1=medium, 0.5=low, 0.25=minimal)
Confidence: How sure? (100%, 80%, 50%)
Effort: Person-months (0.5, 1, 2, 3...)
```

| Feature | Reach | Impact | Confidence | Effort | RICE |
|---------|-------|--------|------------|--------|------|
| Auth with Google | 5000 | 2 | 80% | 1 | 8000 |
| Dark mode | 3000 | 0.5 | 100% | 0.5 | 3000 |
| Export to PDF | 500 | 2 | 80% | 2 | 400 |

### WSJF — Weighted Shortest Job First

SAFe prioritization framework. Prioritize items that deliver the most value in the least time.

```
WSJF = Cost of Delay / Job Duration

Where Cost of Delay = Business Value + Time Criticality + Risk Reduction/Opportunity Enablement

Scale each factor 1-10 (use Fibonacci: 1, 2, 3, 5, 8, 13):
- Business Value: How much revenue/user value does this deliver?
- Time Criticality: Does value decrease if we wait? Is there a deadline?
- Risk Reduction: Does this reduce risk or enable future opportunities?
- Job Duration: How long will this take? (relative sizing)
```

| Feature | Business Value | Time Criticality | Risk Reduction | Job Duration | WSJF |
|---------|---------------|------------------|----------------|-------------|------|
| Payment gateway | 8 | 8 | 5 | 3 | 7.0 |
| GDPR compliance | 3 | 13 | 13 | 5 | 5.8 |
| Dark mode | 3 | 1 | 1 | 2 | 2.5 |
| Mobile app | 8 | 3 | 3 | 13 | 1.1 |

**Interpretation:** Payment gateway has the highest WSJF — high value, time-critical, and relatively quick. GDPR compliance is next due to extreme time criticality (regulatory deadline) and risk reduction. Mobile app, despite high value, scores low because of its large job duration.

### ICE Scoring

Simple, fast prioritization for when you need a quick ranking.

```
ICE = Impact x Confidence x Ease

Impact:     1-10 (How much will this move the needle?)
Confidence: 1-10 (How sure are we about impact and ease estimates?)
Ease:       1-10 (How easy is this to implement? 10 = trivial)
```

| Feature | Impact | Confidence | Ease | ICE |
|---------|--------|------------|------|-----|
| Add search bar | 8 | 9 | 7 | 504 |
| Redesign dashboard | 7 | 5 | 3 | 105 |
| Email notifications | 6 | 8 | 8 | 384 |
| AI recommendations | 9 | 3 | 2 | 54 |

**When to use ICE vs RICE:**
- ICE: Quick backlog grooming, internal features, smaller decisions
- RICE: Quarterly planning, customer-facing features, need justification for stakeholders
- WSJF: SAFe organizations, program-level prioritization, time-sensitive decisions

---

## Stakeholder Mapping

### Power/Interest Grid

```
                    High Power
          ┌─────────────┬─────────────┐
          │   MANAGE     │    KEEP     │
          │   CLOSELY    │  SATISFIED  │
          │              │             │
          │ Key players  │ Decision    │
          │ Daily/weekly │ makers with │
          │ engagement   │ low interest│
          │              │ Regular     │
          │ Examples:    │ updates     │
          │ Product      │             │
          │ owner, CTO   │ Examples:   │
          │              │ CFO, Legal  │
    High  ├─────────────┼─────────────┤  Low
  Interest│    KEEP      │   MONITOR   │  Interest
          │  INFORMED    │  (MINIMAL   │
          │              │   EFFORT)   │
          │ Engaged      │             │
          │ supporters   │ Low-touch   │
          │ Status       │ stakeholders│
          │ updates,     │ Inform only │
          │ newsletters  │ on major    │
          │              │ changes     │
          │ Examples:    │             │
          │ Dev team,    │ Examples:   │
          │ QA team      │ Other teams │
          └─────────────┴─────────────┘
                    Low Power
```

### Stakeholder Communication Plan

| Stakeholder | Power | Interest | Strategy | Cadence |
|---|---|---|---|---|
| Product Owner | High | High | Co-create requirements, review every decision | Daily standups, weekly reviews |
| CTO | High | Low | Escalate architectural decisions, brief on progress | Bi-weekly summary |
| Dev Team | Low | High | Detailed specs, involve in estimation, share context | Sprint planning, daily |
| Legal/Compliance | High | Low | Consult on data/privacy requirements | As needed, gate reviews |
| End Users | Low | High | User research, beta feedback, usability testing | Monthly sessions |

---

## RACI Matrix

Define clear ownership for every deliverable. Without RACI, either everyone thinks someone else is doing it, or three people do the same thing.

```
R = Responsible  (Does the work)
A = Accountable  (Approves the work — only ONE person per task)
C = Consulted    (Provides input before the work)
I = Informed     (Notified after the work is done)
```

| Deliverable | Product Owner | Tech Lead | Developer | Designer | QA |
|---|---|---|---|---|---|
| PRD | A | C | I | C | I |
| Technical Design | C | A | R | I | C |
| UI Design | C | I | I | A/R | C |
| Implementation | I | A | R | C | I |
| Test Plan | I | C | C | I | A/R |
| Code Review | I | A/R | R | I | I |
| Deployment | I | A | R | I | C |
| User Acceptance | A/R | I | C | C | R |

**Rules:**
- Only ONE "A" per row (one person is accountable)
- At least one "R" per row (someone does the work)
- Minimize "C" — too many consulted = slow decisions
- "A" and "R" can be the same person for small teams
- Review RACI at project kickoff — everyone must agree

---

## Data Flow Diagrams

### How to Specify Data Flows for Engineering Teams

Data Flow Diagrams (DFDs) show how data moves through a system. They are the bridge between business requirements and technical implementation.

### Level 0: Context Diagram

```
                    ┌─────────────────────┐
  Customer ────────>│                     │────────> Payment Provider
  (orders,         │   Order Management  │          (charges)
   payments)       │       System        │
                   │                     │<──────── Payment Provider
  Customer <───────│                     │          (confirmations)
  (confirmations,  │                     │
   tracking)       └─────────────────────┘
                          │       ^
                          v       │
                    Admin (reports, management)
```

### Level 1: Major Processes

```
Customer ──[order data]──> 1.0 Validate Order
                                    │
                             [valid order]
                                    │
                                    v
                           2.0 Process Payment ──[charge request]──> Payment Provider
                                    │
                             [payment result]   <──[charge result]──
                                    │
                                    v
                           3.0 Fulfill Order
                                    │
                          [fulfillment data]
                                    │
                                    v
                           4.0 Send Notification ──[email]──> Customer

Data Stores:
  D1: Orders Database
  D2: Inventory Database
  D3: Customer Database
```

### Specification Template for Engineering

```markdown
## Data Flow: [Name]

### Source → Destination
- **Source**: [System/Actor that produces the data]
- **Destination**: [System/Actor that consumes the data]
- **Trigger**: [What initiates this data flow]
- **Frequency**: [Real-time / Batch / On-demand]
- **Volume**: [Expected records/messages per time period]

### Data Structure
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| orderId | UUIDv7 | Yes | Unique order identifier |
| items | Array<OrderItem> | Yes | Line items in the order |
| total | Decimal(10,2) | Yes | Total amount in cents |
| currency | ISO 4217 | Yes | Three-letter currency code |

### Validation Rules
- total must equal sum of item prices
- items array must have at least 1 item
- currency must be supported (USD, EUR, GBP)

### Error Handling
- Invalid data → reject with 400 + specific field errors
- Payment failure → retry 3x with exponential backoff → notify customer
- Downstream service unavailable → queue for retry → alert ops

### SLA
- Processing time: < 500ms P95
- Availability: 99.9%
- Data consistency: Eventually consistent (< 5s)
```

---

## User Journey Map

```
[Trigger] → [Step 1] → [Decision?] → [Step 2a] → [Outcome A]
                            ↓
                        [Step 2b] → [Outcome B]
```

```markdown
## User Journey: First-Time Checkout

1. **Trigger**: User clicks "Buy Now" on product page
2. **Cart Review**: Shows items, quantities, subtotal
   - Can modify quantities or remove items
   - Empty cart → redirect to products page
3. **Shipping**: Enter or select saved address
   - Validates address format
   - Calculates shipping cost
4. **Payment**: Enter card or select saved method
   - Validates card with payment provider
   - Handles declined cards with clear error
5. **Confirmation**: Shows order summary
   - Sends confirmation email
   - Updates inventory
6. **Post-Purchase**: Order tracking page
   - Email with tracking updates
```

### Data Flow Diagram (Simple)

```
User → [Frontend] → [API Gateway] → [Auth Service] → [User DB]
                                   → [Order Service] → [Order DB]
                                                     → [Payment Provider]
                                                     → [Email Service]
```

---

## MVP Definition

### The MVP Test

```
Is this the SMALLEST thing we can build to:
1. Test our core hypothesis?
2. Deliver value to real users?
3. Learn something we didn't know?

If all three: it's an MVP.
If it's just smaller: it's a smaller product, not an MVP.
```

### Scope Reduction Technique

```
Full feature request: "Users can create, edit, share, collaborate on,
export, and version-control documents."

MVP: "Users can create and edit documents."
   → Tests: Do users actually want to create documents here?

v1.1: Add sharing
   → Tests: Do users want to share, or is solo use sufficient?

v1.2: Add collaboration (if sharing data supports it)
```

---

## Requirements Elicitation Questions

### For Stakeholders

| Question | Purpose |
|---|---|
| Who are the users? What are their goals? | Understand the user |
| What problem does this solve? | Validate the need |
| How do users solve this today? | Understand current workflow |
| What does success look like? How will we measure it? | Define metrics |
| What's the deadline and why? | Understand constraints |
| What happens if we don't build this? | Validate priority |
| Who else needs to be involved? | Identify stakeholders |
| What are the biggest risks? | Plan mitigations |

### For Technical Specification

| Question | Purpose |
|---|---|
| What data entities are involved? | Define data model |
| What are the state transitions? | Define workflow |
| What external systems are involved? | Identify integrations |
| What are the volume/scale expectations? | Design for load |
| What are the security/compliance requirements? | Define constraints |
| What happens on error? | Define error handling |
| How is this different from existing feature X? | Avoid duplication |
| What needs to be true for this to be "done"? | Definition of Done |

---

## PRD to Implementation: Vertical-Slice Issue Decomposition

### From PRD to GitHub Issues

Transform PRD user stories into vertical-slice GitHub issues that a developer (or AI agent) can pick up and implement end-to-end.

### Step 1: Identify the Discuss Phase

Before writing issues, identify **gray areas** — requirements that seem clear but have hidden ambiguity:

```markdown
## Gray Area Identification Checklist

For each feature in the PRD, ask:
- What happens at the boundaries? (empty states, max limits, concurrent access)
- What's the error experience? (not just "show error" — what specific error, what recovery?)
- What's the migration path? (existing data, existing users, backwards compatibility)
- What's NOT said? (implicit assumptions that need to be explicit)
- Where does the product person need to make a call? (design decisions disguised as tech decisions)
```

### Step 2: Decompose into Tracer-Bullet Slices

Each GitHub issue should be a thin slice through ALL layers:

```markdown
## Issue Template: Vertical Slice

### Title: [User action] — [Expected outcome]
Example: "User can filter products by category — filtered results update in real-time"

### User Story
As a [user type], I want to [action] so that [benefit].

### Acceptance Criteria (Given-When-Then)
GIVEN [precondition]
WHEN [action]
THEN [expected result]

### Technical Slice
- [ ] **Data**: Migration/schema changes needed
- [ ] **Backend**: API endpoint or Server Action
- [ ] **Frontend**: UI component and interaction
- [ ] **Tests**: Unit + integration + E2E for this slice
- [ ] **Edge cases**: [list specific edge cases for this slice]

### Dependencies
- Blocked by: #[issue number] (if any)
- Blocks: #[issue number] (if any)

### Definition of Done
- [ ] All acceptance criteria pass
- [ ] Tests written and passing
- [ ] No TODO/FIXME left
- [ ] Code reviewed
```

### Step 3: Order Issues for Progressive Building

```
Issue 1: Core happy path (simplest end-to-end flow)
Issue 2: Input validation and error handling
Issue 3: Edge cases (empty states, limits, concurrent)
Issue 4: Polish (loading states, animations, accessibility)
Issue 5: Performance (caching, optimization, lazy loading)
```

Each issue builds on the previous one. Issue 1 should be deployable on its own.

---

## Anti-Patterns

| Anti-Pattern | Why It's Dangerous | Fix |
|---|---|---|
| Solution-first thinking | Building the wrong thing | Start with the problem and user need |
| Vague requirements | "Make it better" = unlimited scope | Specific, testable acceptance criteria |
| No acceptance criteria | Can't tell when it's done | Every story has Given-When-Then |
| Feature factory | Ship features, don't measure outcomes | Define success metrics first |
| Scope creep | "While we're at it..." | Strict MVP scope, backlog everything else |
| Stakeholder assumptions | "Users obviously want X" | Validate with data or user research |
| Gold plating | Perfecting before shipping | Ship MVP, iterate based on feedback |
| No "won't do" list | Stakeholders expect everything | Explicit out-of-scope section |
| Untestable requirements | "System should be fast" | "API P95 latency < 200ms" |
| Missing edge cases | Bugs from unconsidered scenarios | List edge cases per story |
| No RACI defined | Unclear ownership, duplicated work | Define RACI at project kickoff |
| Ignoring stakeholder mapping | Wrong people involved at wrong time | Map power/interest, plan communication |

---

## Checklist: Requirements Review

- [ ] Problem statement is clear (what, who, why)
- [ ] Users and personas defined
- [ ] Success metrics are measurable
- [ ] Scope clearly divided: MVP / Post-MVP / Out of Scope
- [ ] User stories follow format with acceptance criteria
- [ ] Acceptance criteria cover happy path, edge cases, and error recovery
- [ ] Non-functional requirements specified with numbers
- [ ] Edge cases documented (boundaries, empty states, concurrent access)
- [ ] Dependencies identified
- [ ] Risks listed with mitigations
- [ ] Open questions listed (not hidden)
- [ ] Stakeholders mapped (power/interest grid)
- [ ] RACI matrix defined for key deliverables
- [ ] Prioritization framework applied (RICE, WSJF, or ICE)
- [ ] Data flows documented for engineering handoff
- [ ] Gray areas identified and discussed before issue creation
- [ ] Issues decomposed as vertical slices (not horizontal layers)
- [ ] Each issue has technical slice checklist (Data, Backend, Frontend, Tests)
- [ ] Issues ordered for progressive building (happy path first)
- [ ] Reviewed with stakeholders
