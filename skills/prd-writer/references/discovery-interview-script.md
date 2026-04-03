# Discovery Interview Script

Structured question bank for PRD requirements elicitation. Use these questions
progressively — do not dump all questions at once. Ask 2-3 at a time, listen,
then follow up based on what you learned.

## Interview Principles

1. **Ask open questions first, closed questions later.** Start with "Tell me
   about..." and narrow to "Is it X or Y?" only when refining.
2. **Echo back what you heard.** After each answer, restate it in your words and
   confirm: "So what I'm hearing is [X]. Is that right?"
3. **Follow the energy.** When the user gets animated about a topic, probe
   deeper — that's where the real requirements hide.
4. **Capture the workaround.** Today's workaround is tomorrow's requirement.
   Every manual process users have built reveals what the system must do.
5. **Name the persona.** Don't say "the user." Say "the warehouse manager" or
   "the API consumer." Specificity forces clarity.

---

## Phase 1: Problem Space

Start here. Do not skip these questions — they ground everything that follows.

### Opening Questions (ask all three)

1. **What specific problem are you solving?**
   - Follow-up: "How do you know this is a real problem? What evidence do you have?"
   - Follow-up: "How long has this been a problem?"

2. **Who experiences this problem most acutely?**
   - Follow-up: "What is their role? How often do they hit this problem?"
   - Follow-up: "Are there secondary users who are also affected?"

3. **What does success look like in 3 months?**
   - Follow-up: "How would you measure that success? What number changes?"
   - Follow-up: "What does failure look like? What happens if we build this wrong?"

### Deepening Questions (pick 2-3 based on answers)

4. **How are users solving this today?**
   - Probe: "Walk me through the exact steps they take right now."
   - Probe: "What tools or workarounds are they using?"
   - Probe: "Where does the current process break down?"

5. **What triggered the decision to build this now?**
   - Probe: "Is there a deadline, a customer commitment, or a competitive threat?"
   - Probe: "What happens if we delay this by 3 months?"

6. **What has been tried before?**
   - Probe: "Was there a previous attempt? Why did it fail or get shelved?"
   - Probe: "Are there third-party solutions you considered?"

---

## Phase 2: Users and Personas

Map the people who will interact with this feature.

7. **Who are the primary users?**
   - Probe: "What is their technical sophistication level?"
   - Probe: "How many of them are there? (10? 1,000? 100,000?)"

8. **Who are the secondary users?**
   - Probe: "Are there admins, operators, or support staff who interact with this?"
   - Probe: "Are there API consumers or downstream systems?"

9. **What is the user's workflow before, during, and after using this feature?**
   - Probe: "What triggers them to start? What do they do when they're done?"
   - Probe: "What context do they have when they arrive? (Are they already logged in? Do they have data ready?)"

10. **What are their top 3 frustrations with the current state?**
    - Probe: "Rank them. Which one, if solved, would make them happiest?"
    - Probe: "Are there frustrations they've stopped complaining about because they've given up?"

---

## Phase 3: Functional Requirements

Extract the specific capabilities the system must provide.

### Core Actions

11. **What are the 3-5 core actions a user must be able to perform?**
    - Probe: "For each action, what is the happy path — what happens when everything goes right?"
    - Probe: "What are the most common failure modes?"

12. **What data does the user need to see? Create? Modify? Delete?**
    - Probe: "What fields are required vs. optional?"
    - Probe: "Are there computed or derived fields?"
    - Probe: "What is the data lifecycle — does anything expire or archive?"

### Edge Cases and Error States

13. **What happens when things go wrong?**
    - Probe: "If the external API is down, what does the user see?"
    - Probe: "If the user submits invalid data, what happens?"
    - Probe: "Is there a rollback or undo capability?"
    - Probe: "What error messages should the user see? (Not 'an error occurred' — what specifically?)"

14. **Are there time-sensitive or real-time requirements?**
    - Probe: "Does the user need to see updates immediately, or is eventual consistency acceptable?"
    - Probe: "Are there any operations that must complete within a deadline?"

15. **Are there bulk or batch operations?**
    - Probe: "What is the maximum batch size?"
    - Probe: "What happens if some items in a batch succeed and others fail?"

### Access and Permissions

16. **Who can do what?**
    - Probe: "Are there different permission levels? (viewer, editor, admin)"
    - Probe: "Can permissions be delegated?"
    - Probe: "Are there multi-tenancy considerations?"

---

## Phase 4: Non-Functional Requirements

Every NFR must have a number. Push back on vague answers.

### Performance

17. **What is the expected load?**
    - Probe: "How many concurrent users? Requests per second? Data volume?"
    - Probe: "What does the peak look like vs. average?"
    - Probe: "Are there seasonal spikes?"

18. **What is the acceptable latency?**
    - Probe: "What is the P50 (typical) and P95 (worst acceptable) latency?"
    - Probe: "Are there specific operations that must be faster than others?"
    - If vague: "Is 100ms acceptable? 500ms? 2 seconds? Where's the line?"

### Reliability and Availability

19. **What is the uptime requirement?**
    - Probe: "Is this 99.9% (8.7 hours downtime/year) or 99.99% (52 minutes/year)?"
    - Probe: "Are there maintenance windows?"
    - Probe: "What happens if this feature is down — is it blocking or degradable?"

20. **Are there data durability requirements?**
    - Probe: "Can we ever lose data? What is the recovery point objective (RPO)?"
    - Probe: "What is the recovery time objective (RTO)?"

### Compliance and Security

21. **Are there compliance or regulatory constraints?**
    - Probe: "GDPR? HIPAA? SOC 2? PCI-DSS?"
    - Probe: "Are there data residency requirements?"

22. **Are there data retention or deletion requirements?**
    - Probe: "How long must data be kept? When must it be deleted?"
    - Probe: "Is there a right-to-be-forgotten requirement?"

---

## Phase 5: Integration and Dependencies

Map the feature's connections to the outside world.

23. **What existing systems does this need to interact with?**
    - Probe: "Internal services? External APIs? Databases?"
    - Probe: "Are there rate limits or quotas on those systems?"

24. **Are there external APIs or third-party services involved?**
    - Probe: "What are their SLAs? What happens when they're down?"
    - Probe: "Do they charge per API call? What is the cost model?"

25. **What authentication and authorization model applies?**
    - Probe: "Is there an existing auth system to integrate with?"
    - Probe: "Are there SSO or OAuth requirements?"

26. **Are there existing database tables or models to extend?**
    - Probe: "What is the current schema? What migrations are needed?"
    - Probe: "Are there shared tables that other teams own?"

---

## Phase 6: Scope Control

This is where you prevent scope creep. Be firm.

27. **What is explicitly NOT part of this feature?**
    - Probe: "If someone asked for [obvious extension], would you say no?"
    - Probe: "What adjacent features are you intentionally deferring?"
    - Require: Minimum 3 out-of-scope items.

28. **What would a "Phase 2" look like?**
    - Probe: "What would you add in 3 months if Phase 1 succeeds?"
    - Probe: "Are there features you wish you could include but know you shouldn't?"

29. **What is the minimum viable version that delivers value?**
    - Probe: "If you could only ship 2 of the 5 core actions, which 2?"
    - Probe: "What is the smallest thing you could ship and learn from?"

30. **What would you cut if you had half the time?**
    - Probe: "Which requirements are 'must have' vs. 'nice to have'?"
    - Probe: "Is there a manual workaround that buys time for any of the 'should have' items?"

---

## Closing Protocol

After completing the relevant interview sections:

1. **Summarize findings:** Present a 1-paragraph problem statement and a bullet
   list of key requirements discovered.
2. **Identify gaps:** List any areas where you still lack confidence.
3. **Confirm readiness:** "I have enough information to draft the PRD. Are there
   any topics we haven't covered that you think are critical?"
4. **Transition:** Move to Phase 4 (Module Design) or Phase 5 (PRD Synthesis)
   depending on complexity.
