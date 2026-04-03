# Setup Best Practices

Best practices for agentic coding project configuration.

## File Structure

| File | Purpose | Volatility | Required |
|---|---|---|---|
| `CLAUDE.md` | Project-specific agent instructions | Stable | Yes |
| `AGENTS.md` | Symlink to CLAUDE.md for multi-agent compat | Stable | Recommended |
| `CONTEXT.md` | Current project state and session context | Volatile | Optional |
| `SPEC.md` | Application specification and requirements | Stable | For new projects |
| `TASKS.md` | Active task tracking | Volatile | Optional |
| `DESIGN_SYSTEM.md` | UI/design system rules | Stable | For UI projects |
| `RUNBOOK.md` | Deployment and operations procedures | Stable | For production apps |
| `docs/adr/` | Architecture Decision Records | Stable | Recommended |

## What Belongs in CLAUDE.md

**Include (project-specific conventions):**
- Architecture decisions unique to this project
- Database conventions (PK strategy, naming, timestamp types)
- API design patterns specific to this project
- Team workflow rules (PR process, branch naming)
- Non-obvious coding patterns unique to this codebase
- Integration and deployment constraints
- Pointers to other docs ("see docs/adr/ for architecture decisions")

**Exclude (waste of context window):**
- Default agent behavior (formatting, naming, error handling)
- Generic coding advice ("write tests", "use descriptive names")
- Anything already covered by installed skills
- One-off patches for specific past bugs
- Vague instructions ("write clean code", "follow best practices")
- Language/framework basics the agent already knows

## The Context Window Rule

Every instruction in CLAUDE.md consumes context window space. The cost of
a useless instruction is not zero — it:

1. Takes up tokens that could hold actual code context
2. May conflict with skill instructions, causing non-deterministic behavior
3. Adds noise that dilutes important instructions
4. May cause the agent to over-index on that instruction

**Rule of thumb:** If removing an instruction wouldn't change agent behavior,
remove it.

## Symlink Conventions

```bash
# AGENTS.md should symlink to CLAUDE.md (not be a copy)
ln -s CLAUDE.md AGENTS.md

# Why symlink, not copy:
# - Single source of truth
# - No drift between files
# - Works with OpenCode, Codex, and other multi-agent tools
# - Git tracks the symlink, not a duplicate file
```

## CLAUDE.md vs Skills — Where Rules Live

```
Is this rule project-specific?
├─ YES → CLAUDE.md
│  Example: "Use UUIDv7 for all primary keys in this project"
│  Example: "Deploy to us-east-1 Kubernetes cluster"
└─ NO (general best practice)
   ├─ Is there a skill for this domain?
   │  ├─ YES → the skill handles it, don't duplicate in CLAUDE.md
   │  │  Example: "Use Zod for validation" → typescript-engineering skill
   │  │  Example: "Test pyramid: unit > integration > E2E" → qa-testing skill
   │  └─ NO → consider adding it to CLAUDE.md or requesting a new skill
   └─ Is this default agent behavior?
      ├─ YES → don't write it anywhere
      │  Example: "Use descriptive variable names"
      │  Example: "Handle errors properly"
      └─ NO → CLAUDE.md (with specific, testable criteria)
```

## Context Management Strategy

```
CLAUDE.md (stable — project lifetime)
├── Project identity and architecture
├── Non-obvious conventions
└── Pointers to other docs

CONTEXT.md (volatile — per-session/sprint)
├── Current sprint goals
├── Recent decisions not yet in ADRs
├── Active blockers
└── Session handover notes

TASKS.md (volatile — archived when done)
├── Current task list
├── Task status and dependencies
└── Archived to docs/archived/ when complete

.claude/memory/ (auto-managed)
├── User preferences
├── Project learnings
└── Reviewed periodically for staleness

docs/pipeline/ (per-feature)
├── Pipeline status files
├── Artifacts from each stage
└── Cleaned up after feature ships
```

## Hook Hygiene

1. Every hook MUST have a comment explaining WHY it exists
2. Hook behavior must not contradict CLAUDE.md instructions
3. Review hooks quarterly — remove hooks for solved problems
4. Test hooks locally: `echo '{"tool_name":"Bash","tool_input":{"command":"rm -rf /"}}' | bash .claude/hooks/pre-tool-use.sh`
5. Hooks should be fail-open (exit 0 by default) to avoid blocking work

## Maintenance Cadence

| Task | Frequency | Trigger |
|---|---|---|
| Run `agent-setup-audit` | Monthly | Or after major feature completion |
| Archive stale TASKS.md entries | Weekly | When tasks complete |
| Review CONTEXT.md freshness | Per session | At session start |
| Review .claude/memory/ | Monthly | During audit |
| Update CLAUDE.md | On architecture change | When conventions change |
| Verify AGENTS.md symlink | After git operations | May break on some platforms |

## Anti-Patterns

| Pattern | Problem | Fix |
|---|---|---|
| Instruction hoarding | Context window bloat, conflicting rules | Regular audits, aggressive pruning |
| Copy-paste AGENTS.md | Drift from CLAUDE.md | Symlink instead |
| Skill duplication in CLAUDE.md | Contradictions, wasted context | Let skills handle their domain |
| Stale CONTEXT.md | Agent uses outdated information | Update or delete per session |
| No ADRs | Architecture decisions lost | Create docs/adr/ with numbered records |
| Hooks without comments | Nobody knows why they exist | Add WHY comment to every hook |
