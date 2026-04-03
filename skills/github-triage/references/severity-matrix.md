# Severity Matrix

Decision tree for determining issue severity and priority, including edge cases and modifier rules.

---

## Severity Decision Tree

```
Is there data loss, corruption, or a security vulnerability?
  ├── YES ──> severity: critical
  └── NO
       Is a major feature completely broken with no workaround?
         ├── YES ──> severity: high
         └── NO
              Is a feature broken but a workaround exists?
              OR is there significant UX degradation?
                ├── YES ──> severity: medium
                └── NO
                     Is it cosmetic, a minor inconvenience, or a rare edge case?
                       ├── YES ──> severity: low
                       └── NO ──> Reclassify (may not be a bug)
```

---

## Severity Definitions

### Critical

- **Data loss or corruption**: User data is destroyed, overwritten, or made inaccessible
- **Security vulnerability**: Authentication bypass, privilege escalation, data exposure, injection
- **Complete service outage**: Application is entirely unusable for all or most users
- **Response target**: Same day -- drop everything

**Examples:**
- Database migration deletes user records
- API returns other users' data
- Application crashes on startup for all users

### High

- **Major feature broken**: A primary workflow is unusable
- **No workaround**: Users cannot accomplish the task by any other means
- **Response target**: 2 business days

**Examples:**
- Payment processing fails for a specific payment method
- File upload silently drops files over a certain size
- Search returns no results for valid queries

### Medium

- **Feature broken with workaround**: The happy path fails but users can accomplish the task another way
- **Significant UX degradation**: Feature works but with noticeable performance, layout, or usability issues
- **Response target**: 1 week

**Examples:**
- Export works but produces incorrectly formatted CSV (manually fixable)
- Page takes 15 seconds to load instead of 2
- Form validation error messages are misleading

### Low

- **Cosmetic issues**: Typos, misaligned elements, wrong colors
- **Minor inconvenience**: Extra clicks required, non-blocking annoyance
- **Rare edge case**: Only affects unusual configurations or uncommon inputs
- **Response target**: Best effort

**Examples:**
- Tooltip appears in the wrong position on one browser
- Timezone displayed as UTC instead of local (data is correct)
- Button text truncated on a specific screen resolution

---

## Priority Modifiers

Priority modifiers can upgrade a severity by one level. Apply only one upgrade even if multiple modifiers match.

| Modifier | Evidence | Effect |
|---|---|---|
| **Wide impact** | >10 thumbs-up reactions, multiple duplicate reports, or analytics show >10% of users affected | Upgrade one level |
| **Recent regression** | Bug was introduced in the last 2 releases (check git blame / changelog) | Upgrade one level |
| **Blocks downstream** | A downstream integration, partner, or dependency is blocked by this issue | Upgrade one level |
| **Affects onboarding** | New users hit this bug during first-run or setup flow | Upgrade one level |

**Cap rule:** Low + modifier = Medium. Medium + modifier = High. High + modifier = Critical. Critical cannot be upgraded further.

---

## Enhancement/Improvement Severity

For non-bug issues, severity reflects business impact rather than breakage:

| Severity | Enhancement criteria |
|---|---|
| `severity: critical` | Blocking a signed contract, regulatory deadline, or security requirement |
| `severity: high` | Top-requested feature by users, significant competitive gap |
| `severity: medium` | Valuable improvement, moderate user demand |
| `severity: low` | Nice to have, low user demand, or speculative |

---

## Edge Cases

| Scenario | Resolution |
|---|---|
| Bug only in development, not production | Low (unless it blocks CI or other developers) |
| Bug in deprecated feature | Low + add `wontfix` candidate note |
| Performance degradation without hard failure | Medium (upgrade to High if >3x slower than baseline) |
| Accessibility violation (WCAG A) | High (upgrade to Critical if it blocks screen reader users) |
| Accessibility violation (WCAG AA/AAA) | Medium |
| Intermittent / hard to reproduce | Start at Medium, upgrade if reproduction confirms wide impact |
| Feature request disguised as bug | Reclassify to `type: enhancement`, then apply enhancement severity |

---

## Severity vs Priority

Severity is objective (what is the impact?) while priority is subjective (when should we fix it?). This matrix handles severity. Priority is determined by the team during sprint planning, factoring in:

- Severity level
- Strategic alignment
- Resource availability
- Dependencies and blockers

A `severity: low` issue may become high priority if it is trivial to fix and improves user trust. A `severity: high` issue may be deprioritized if a workaround is communicated and a larger initiative is underway.
