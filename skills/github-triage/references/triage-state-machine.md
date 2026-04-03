# Triage State Machine

Complete label definitions, colors, and valid state transitions for the GitHub issue triage workflow.

---

## Label Definitions

### Type Labels

| Label | Color (hex) | Description |
|---|---|---|
| `type: bug` | `#d73a4a` | Something is broken or behaves contrary to documentation |
| `type: enhancement` | `#a2eeef` | New capability that does not exist today |
| `type: improvement` | `#7057ff` | Better behavior for an existing capability |
| `type: question` | `#d876e3` | User needs help, not a defect or feature request |
| `type: docs` | `#0075ca` | Documentation is missing, incorrect, or unclear |

### Severity Labels

| Label | Color (hex) | Description |
|---|---|---|
| `severity: critical` | `#b60205` | Data loss, security vulnerability, or total outage |
| `severity: high` | `#d93f0b` | Major feature broken, no workaround |
| `severity: medium` | `#fbca04` | Feature broken with workaround, or significant UX degradation |
| `severity: low` | `#0e8a16` | Cosmetic, minor inconvenience, or rare edge case |

### State Labels

| Label | Color (hex) | Description |
|---|---|---|
| `needs-triage` | `#e4e669` | Entered pipeline, awaiting classification and assessment |
| `needs-info` | `#ffffff` | Blocked on author -- missing reproduction steps or details |
| `ready-for-agent` | `#1d76db` | Fully triaged, clear scope, suitable for autonomous work (AFK) |
| `ready-for-human` | `#c2e0c6` | Fully triaged but requires human judgment (HITL) |
| `wontfix` | `#cccccc` | Declined -- out of scope, by design, or cost not justified |
| `duplicate` | `#cfd3d7` | Duplicate of an existing issue |

### Scope Labels (optional, for enhancements/improvements)

| Label | Color (hex) | Description |
|---|---|---|
| `scope: small` | `#bfdadc` | Less than 1 day of work |
| `scope: medium` | `#c5def5` | 1 to 3 days of work |
| `scope: large` | `#d4c5f9` | More than 3 days of work |

---

## State Transition Diagram

```
                           ┌──────────────────────────────────┐
                           │                                  │
  ┌──────────┐      ┌──────────────┐      ┌────────────┐     │
  │ unlabeled│─────>│ needs-triage │─────>│ needs-info │─────┘
  └──────────┘      └──────────────┘      └────────────┘
                           │                     │
                           │                     ├───> ready-for-agent
                           │                     ├───> ready-for-human
                           │                     ├───> wontfix
                           │                     └───> closed (stale, 30d)
                           │
                           ├───> ready-for-agent
                           ├───> ready-for-human
                           ├───> wontfix
                           └───> duplicate ───> closed
```

---

## Valid Transitions

| From | To | Trigger |
|---|---|---|
| `unlabeled` | `needs-triage` | Issue enters pipeline (manual or automation) |
| `needs-triage` | `needs-info` | Issue lacks reproduction steps or required details |
| `needs-triage` | `ready-for-agent` | Fully triaged, clear scope, reproducible bug or well-scoped feature |
| `needs-triage` | `ready-for-human` | Requires architectural decision, security review, or ambiguous scope |
| `needs-triage` | `wontfix` | Out of scope or cost/benefit does not justify |
| `needs-triage` | `duplicate` | Duplicate of existing issue (close immediately) |
| `needs-info` | `needs-triage` | Author provides requested information (re-enter triage) |
| `needs-info` | `closed` | No response for 30+ days |
| `needs-info` | `wontfix` | Author confirms it is not actually an issue |
| `needs-info` | `ready-for-agent` | Author provides info that completes triage |
| `needs-info` | `ready-for-human` | Author provides info but scope remains ambiguous |
| `ready-for-agent` | `closed` | Issue resolved by agent or PR merged |
| `ready-for-human` | `closed` | Issue resolved by human or PR merged |
| `ready-for-human` | `ready-for-agent` | Human clarifies scope, issue now suitable for agent |

---

## Invalid Transitions (guard rails)

- `closed` -> any open state without explicit reopening by a maintainer
- `ready-for-agent` -> `needs-triage` (already triaged; if new info surfaces, comment and re-route)
- `duplicate` -> any state other than `closed`
- Any state -> `unlabeled` (labels are additive, never stripped to empty)

---

## Automation Hooks

These transitions can be automated with GitHub Actions or bots:

| Automation | Trigger | Action |
|---|---|---|
| Auto-label new issues | `issues.opened` event | Add `needs-triage` if no type label present |
| Stale needs-info | Cron (daily) | Comment warning at 14 days, close at 30 days |
| Re-triage on comment | `issue_comment.created` by author on `needs-info` | Remove `needs-info`, add `needs-triage` |
| Close duplicates | Manual `duplicate` label added | Auto-close with comment linking original |
