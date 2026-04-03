# Triage Comment Template

Standardized comment format posted to every issue after triage. Copy and fill in the relevant sections.

---

## Full Template

```markdown
## Triage Summary

**Type:** `{bug | enhancement | improvement | question | docs}`
**Severity:** `{critical | high | medium | low}`
**Routed to:** `{ready-for-agent | ready-for-human | needs-info | wontfix}`

### Classification
{1-2 sentences explaining why this type label was chosen.}

### Severity Rationale
{1-2 sentences explaining the severity assessment. Note any modifiers applied.}

### Investigation
{For bugs: reproduction result, root cause area, affected component.}
{For enhancements: scope estimate (small/medium/large), affected area.}
{For questions: answer or pointer to relevant docs.}

### Related Issues
- {#123 — brief description of relationship}
- {#456 — brief description of relationship}

### Next Steps
{What needs to happen next. For needs-info: what information is missing. For ready-for-agent: suggested approach. For ready-for-human: what decision is needed.}
```

---

## Shortened Template (for low/trivial issues)

```markdown
## Triage Summary

**Type:** `{type}` | **Severity:** `{severity}` | **Routed to:** `{destination}`

{1-2 sentence summary of classification, investigation, and next step.}
```

---

## Template for Duplicates

```markdown
## Duplicate

This issue is a duplicate of #{original_issue_number}.

Closing in favor of the original. Please add any additional context as a comment on #{original_issue_number}.
```

---

## Template for Stale Needs-Info (14-day warning)

```markdown
## Needs Information

This issue was marked `needs-info` {N} days ago. We are still missing:

- {List of missing information}

If no response is received within 30 days of the original request, this issue will be closed automatically. You can always reopen it later with the requested details.
```

---

## Template for Stale Needs-Info (30-day close)

```markdown
## Closing — No Response

This issue has been waiting for information for over 30 days. Closing due to inactivity.

If you have the requested details, please reopen this issue or create a new one with complete reproduction steps.
```

---

## Template for Wontfix

```markdown
## Closing — Won't Fix

**Reason:** `{out of scope | by design | cost/benefit}`

{2-3 sentences explaining the decision. Be respectful and specific.}

If you believe this decision should be reconsidered, please comment with additional context about the use case and impact.
```

---

## Guidelines for Writing Triage Comments

1. **Be specific** -- avoid generic phrases like "we will look into it"
2. **Be respectful** -- the author took time to file the issue
3. **Be actionable** -- every comment should make clear what happens next
4. **Mention labels** -- reference the labels you applied so the author understands the state
5. **Link evidence** -- if you reproduced a bug, link the reproduction steps or test
6. **Use the template** -- consistency helps both authors and maintainers
