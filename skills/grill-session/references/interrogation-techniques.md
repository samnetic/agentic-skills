# Interrogation Techniques

Use these techniques during Phase 3 (Branch-by-Branch Interrogation) to probe
each assumption depth-first. Choose the technique based on the user's response
pattern — different situations call for different tools.

## Technique 1: Socratic Method

**What it is:** A cycle of question, answer, deeper question that guides the user
to discover gaps in their own reasoning without being told.

**When to use:**
- The user gave a surface-level answer and needs to go deeper
- You want the user to arrive at the conclusion themselves (higher buy-in)
- The user said "I think" or "probably" — uncertainty that needs unpacking

**When NOT to use:**
- The user already gave a well-reasoned, evidence-backed answer
- The question can be answered by checking the codebase (check code instead)
- You're past the third follow-up — diminishing returns

**Question templates:**
- "You said [X]. What would need to be true for [X] to hold?"
- "What evidence do you have for [X], and how recent is it?"
- "If [X] turned out to be wrong, how would you know?"
- "What's the weakest link in your reasoning from [premise] to [conclusion]?"

**Example flow:**
```
User: "Our API can handle the load."
Q1: "What's the current peak QPS, and what QPS does this feature add?"
User: "About 500 QPS peak, and maybe 200 more."
Q2: "Has the system been tested at 700 QPS? What broke last time it was stressed?"
User: "We haven't load tested recently."
Q3: "What's the cheapest way to validate this before committing to the design?"
```

## Technique 2: Steel-Manning

**What it is:** Constructing the strongest possible version of the opposing
argument before presenting it. The opposite of a straw man.

**When to use:**
- At the start of interrogating each assumption (Step 2 in the protocol)
- When you need to earn trust before challenging — showing you understand the
  strongest opposition makes the user take the challenge seriously
- When the user has been dismissive of risks

**When NOT to use:**
- The assumption is clearly valid and well-supported
- You can't construct a genuinely strong counter-argument (don't force it)

**Question templates:**
- "The strongest case against this assumption is [detailed argument]. How do you
  respond to that?"
- "A smart critic would say [argument]. They'd point to [evidence]. What's your
  counter?"
- "If I were arguing against this, my best move would be [X]. Where does that
  argument break down?"

**Example:**
```
Assumption: "Users will migrate from v1 to v2 within 3 months."
Steel-man opposition: "The strongest case against this: migration requires
  every user to update their integration code. History shows that even with
  deprecation notices, Stripe took 2 years to sunset API versions, and they
  have dedicated developer relations. Your team has neither a migration tool
  nor a developer advocate. What makes you confident your users will move
  faster than Stripe's?"
```

## Technique 3: Pre-Mortem

**What it is:** Imagining the project has already failed and working backward to
identify what went wrong. Shifts the framing from "will this work?" (optimism
bias) to "why did this fail?" (analytical).

**When to use:**
- The user is overly optimistic and not engaging with risks
- You've finished testing an assumption and want to check for blind spots
- The user's defense was strong — pre-mortem can catch things neither of you
  considered

**When NOT to use:**
- The user is already anxious or overwhelmed — this will amplify negativity
- The assumption is clearly low-risk

**Question templates:**
- "It's 6 months from now and this failed. What went wrong?"
- "Your team shipped this, and adoption is 10% of what you projected. Why?"
- "Imagine the post-mortem doc. What's the root cause listed?"
- "If this feature gets rolled back in 3 months, what's the most likely reason?"

**Example:**
```
"It's Q3 and the migration is at 15% instead of 100%. You're writing the
post-mortem. What does it say? My guess: 'We underestimated the effort users
needed to update their integration code, and we didn't provide a migration
tool until month 2.' Does that ring true, or would the post-mortem say
something different?"
```

## Technique 4: 5 Whys

**What it is:** Repeatedly asking "why?" (up to 5 times) to drill from a
surface statement to the root cause or core belief.

**When to use:**
- The user gave a confident but shallow answer ("It'll be fine because we've
  done it before")
- You need to find the root assumption underneath a stated assumption
- The user's reasoning has a logical chain you want to test link by link

**When NOT to use:**
- The user already gave a deep, well-reasoned answer
- After the third "why" you're getting circular answers (stop and note it)
- The question is about facts, not reasoning

**Question templates:**
- "Why do you believe [X]?"
- "Why is [the answer they just gave] true?"
- "What makes you confident that [deeper claim] holds?"

**Example flow:**
```
User: "We can ship this in 6 weeks."
Why 1: "Why 6 weeks?" → "That's what the team estimated."
Why 2: "Why did the team estimate 6 weeks?" → "Based on a similar project."
Why 3: "Why is that project comparable?" → "Same tech stack and scope."
Why 4: "Is the scope actually the same? What's different?" → "Well, this one
  has a third-party integration the other didn't..."
Why 5: "How much does that integration add?" → "Honestly, I'm not sure."
```

The root assumption was: "This project is comparable to a past project." Four
whys deep, it broke.

## Technique 5: Reductio ad Absurdum

**What it is:** Taking an assumption to its logical extreme to see if it still
holds. If the extreme case is absurd, the assumption has limits that need to be
defined.

**When to use:**
- The user made a sweeping claim ("All users will...", "This will always...")
- You want to find boundary conditions and edge cases
- The assumption seems too good to be true

**When NOT to use:**
- The user made a carefully scoped claim — don't exaggerate what they said
- The extreme case is so unrealistic it feels like a cheap trick

**Question templates:**
- "If [assumption] is true, then at 100x scale, [extreme consequence]. Does
  that still hold?"
- "Taking this to its logical conclusion: if every user did [X], what happens?"
- "If this assumption is always true, why hasn't [obvious player] already done it?"

**Example:**
```
Assumption: "Free-tier users will convert to paid at 5%."
Reductio: "If that's true, and you scale to 1M free users, you'd have 50K
paying customers at $50/mo — that's $30M ARR from a single funnel. If that
conversion rate were reliable at scale, every SaaS company would just blast
free signups. What makes your funnel different from the ones where conversion
drops to 0.5% at scale?"
```

## Technique 6: Second-Order Thinking

**What it is:** Asking "and then what happens?" to explore consequences beyond
the immediate first-order effect.

**When to use:**
- The user described a positive outcome but didn't think about what comes after
- The proposal has side effects that aren't being considered
- The assumption involves changing user behavior (second-order effects are almost
  always underestimated)

**When NOT to use:**
- The first-order assumption hasn't been validated yet (validate first, then
  explore second-order effects)

**Question templates:**
- "OK, assume [X] works. Then what happens?"
- "If users do [expected behavior], what changes in their workflow? What breaks?"
- "If this succeeds, what new problem does it create?"
- "You ship this and it works. What does the team need to deal with next?"

**Example:**
```
Assumption: "Moving to microservices will improve deployment speed."
Second-order: "OK, deployments are faster. Now each team owns their service.
  Who handles cross-service debugging? Who owns the integration tests? What
  happens to your single staging environment when 5 teams want to deploy
  simultaneously?"
```

## Technique 7: Red Team

**What it is:** Arguing against the proposal as if you were a competitor, a
skeptical investor, a disgruntled user, or a hostile actor.

**When to use:**
- The proposal has market-facing or user-facing implications
- You want to stress-test from an external adversarial perspective
- The user has been thinking internally (how to build) and not externally
  (how this gets attacked or outcompeted)

**When NOT to use:**
- The proposal is purely internal/technical with no external exposure
- The user is already demoralized — adversarial framing will backfire

**Question templates:**
- "If I'm your competitor and I see you launch this, what do I do?"
- "If I'm a user trying to abuse this, how do I exploit it?"
- "If I'm a skeptical investor, what's my first question?"
- "If this gets posted on Hacker News, what's the top critical comment?"

**Example:**
```
Assumption: "Our pricing is competitive."
Red team: "I'm your competitor. I see you charging $50/mo for this feature.
  I can ship 80% of the same functionality as a free add-on to my existing
  product. I announce it the week you launch. What's your response?"
```

## Choosing the Right Technique

| User's Response Pattern | Recommended Technique |
|---|---|
| Surface-level confidence ("it'll be fine") | 5 Whys |
| Sweeping claims ("all users will...") | Reductio ad Absurdum |
| Uncertainty ("I think", "probably") | Socratic Method |
| Optimism without risk awareness | Pre-Mortem |
| First-order only thinking | Second-Order Thinking |
| Internally focused reasoning | Red Team |
| Starting each new assumption | Steel-Manning (always first) |

## Sequencing Within a Branch

For each assumption, follow this recommended sequence:

1. **Steel-man** the opposition first (earns trust, sets the bar)
2. **Socratic method** to explore the user's reasoning (2–3 questions max)
3. **One targeted technique** based on response pattern (see table above)
4. **Your recommended answer** synthesizing everything heard

Do not use more than 3 techniques per assumption. The goal is depth, not
exhaustion.
