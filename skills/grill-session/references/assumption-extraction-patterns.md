# Assumption Extraction Patterns

Use these patterns during Phase 2 (Assumption Mining) to systematically surface
hidden assumptions in the user's proposal. Every proposal contains beliefs
treated as facts — the goal is to make them explicit so they can be tested.

## Assumptions vs. Requirements

Before extracting, understand the distinction:

| | Assumption | Requirement |
|---|---|---|
| **Nature** | Believed to be true but unverified | Desired outcome or constraint |
| **Example** | "Users will migrate from the old API within 3 months" | "The new API must support pagination" |
| **Risk** | If wrong, the plan fails silently | If unmet, the plan fails visibly |
| **Action** | Test and validate | Implement and verify |

Assumptions are dangerous precisely because they are invisible. Requirements are
stated; assumptions are embedded. The extraction patterns below force them to the
surface.

## Category 1: Technical Feasibility

Hidden belief: "This can be built as described with the technology we have."

**Extraction questions:**

1. "What is the hardest technical part of this proposal, and why do you believe
   it's solvable?" — Forces the user to identify the riskiest technical bet.
2. "Does this require any technology, library, or capability that the team has
   not used before in production?" — Surfaces novelty risk.
3. "What existing system does this depend on, and what happens if that system
   can't support this use case?" — Exposes integration assumptions.
4. "Is there a proof-of-concept or prototype that demonstrates the core
   technical mechanism works?" — Tests whether feasibility is proven or hoped.

**Common hidden assumptions:**
- The database can handle the new query pattern at current scale
- The third-party API has the endpoint/capability we need
- The existing codebase can be extended without a major refactor
- The team has sufficient expertise in the required technology

## Category 2: User Behavior

Hidden belief: "Users will act the way we expect them to."

**Extraction questions:**

1. "How do you know users want this? What evidence exists — interviews, data,
   support tickets, competitor analysis?" — Tests whether user demand is
   validated or assumed.
2. "What does the user have to do differently from today, and why would they
   bother?" — Surfaces adoption friction assumptions.
3. "What's the user's alternative if they don't use this? How painful is the
   status quo?" — Tests whether the problem is acute enough to drive action.
4. "Are you assuming users will discover this feature organically, or does it
   require education/onboarding?" — Exposes distribution assumptions.

**Common hidden assumptions:**
- Users will find and adopt this without significant onboarding
- The target user has the technical skill to use this
- Users care about this problem enough to switch from their current solution
- Usage patterns will match the designed happy path

## Category 3: Market / Timing

Hidden belief: "The market conditions and timing are right for this."

**Extraction questions:**

1. "Why now? What has changed that makes this the right time?" — Tests whether
   timing is intentional or arbitrary.
2. "Who else is doing something similar, and what is your differentiation?" —
   Surfaces competitive assumptions.
3. "If you shipped this 6 months late, would it still matter? What changes?" —
   Tests urgency assumptions.
4. "Is there a market trend or external event you're counting on?" — Exposes
   dependency on external conditions.

**Common hidden assumptions:**
- No competitor will ship something similar first
- The regulatory environment won't change
- The market is large enough to sustain this investment
- Early adopters represent the broader market

## Category 4: Resource / Effort

Hidden belief: "We have enough time, money, and people to do this."

**Extraction questions:**

1. "How did you arrive at the timeline estimate? What's the basis — similar
   past projects, gut feel, or external pressure?" — Tests estimation rigor.
2. "What happens to the team's other commitments while this is being built?" —
   Surfaces opportunity cost assumptions.
3. "What's the most likely thing that would cause a 2x delay, and how would
   you handle it?" — Forces identification of schedule risks.
4. "Does this require hiring, contracting, or cross-team coordination that
   isn't yet confirmed?" — Exposes staffing assumptions.

**Common hidden assumptions:**
- The team can context-switch without productivity loss
- No key person will leave or become unavailable during the project
- The scope won't expand once development begins
- The estimate includes testing, documentation, and deployment — not just coding

## Category 5: Dependencies

Hidden belief: "External systems, teams, and services will be available and
reliable."

**Extraction questions:**

1. "What external APIs, services, or platforms does this depend on? What's
   their uptime and rate-limit history?" — Tests infrastructure assumptions.
2. "Does this require another team to deliver something? Have they committed,
   or is it assumed?" — Surfaces cross-team coordination assumptions.
3. "What happens if a key dependency changes its pricing, API, or terms of
   service?" — Tests vendor lock-in risk.
4. "Are there any regulatory, legal, or compliance approvals needed before
   shipping?" — Exposes governance assumptions.

**Common hidden assumptions:**
- The third-party API will remain available and affordable
- The other team's timeline aligns with ours
- No breaking changes will occur in critical dependencies during development
- Compliance review won't block or significantly delay the launch

## Category 6: Scalability / Performance

Hidden belief: "This will work at the scale we need."

**Extraction questions:**

1. "What's the expected load at launch vs. 12 months out? Have you modeled
   the growth curve?" — Tests whether scale planning exists.
2. "What's the most expensive operation in this design, and how does its cost
   grow with users/data?" — Surfaces O(n) vs O(n^2) style scaling risks.
3. "At what point does this architecture break? What's the ceiling?" — Forces
   identification of scaling limits.
4. "Have you load-tested anything similar, or is the performance expectation
   based on calculation alone?" — Tests whether performance is proven or
   theoretical.

**Common hidden assumptions:**
- Current infrastructure can handle 10x the current load
- The database query pattern scales linearly
- Caching will solve performance problems
- Users won't hit the system in patterns that create hotspots

## Extraction Process

When mining assumptions from a proposal:

1. **Read the proposal carefully** — highlight every verb that implies certainty:
   "will", "can", "should", "is", "are". Each is a potential assumption.
2. **Apply each category's questions** — not all categories apply to every
   proposal. Skip categories that are clearly irrelevant (e.g., market/timing
   for an internal refactor).
3. **Look for "of course" statements** — things the user treats as obvious are
   often the most dangerous assumptions because they've never been questioned.
4. **Check for missing categories** — if the proposal mentions no timeline,
   that's an implicit assumption that time pressure doesn't exist. If it
   mentions no competitors, that's an implicit assumption of a clear field.
5. **Aim for 5–7 total** — fewer than 5 means you're being too conservative;
   more than 7 makes the interrogation unwieldy. Prioritize by risk.
