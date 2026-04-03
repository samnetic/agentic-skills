---
name: agent-setup-audit
description: >-
  Audit and optimize agentic coding setup — CLAUDE.md, AGENTS.md, skills,
  agents, hooks, and context files. Finds contradictions, redundancy, vague
  instructions, default-behavior bloat, and one-off patches. Spawns parallel
  reviewers for consensus, then produces a cleaned-up configuration. Use when
  setup feels messy, agent outputs are inconsistent, or periodically for
  maintenance. Triggers: audit my setup, audit CLAUDE.md, review my agent
  config, clean up my instructions, optimize my agentic setup, agent audit,
  setup review, lint my config.
license: MIT
metadata:
  author: samnetic
  version: "1.0"
---

# Agent Setup Audit

Find and fix contradictions, redundancy, and vagueness in your agentic coding configuration.

## Core Principles

| Principle | Meaning |
|---|---|
| Read everything first | Scan ALL instruction files before making any judgment — context matters |
| Every instruction earns its place | If a rule restates default behavior, it wastes context window and adds noise |
| Contradictions are silent bugs | Two conflicting rules cause non-deterministic agent behavior — find and resolve them |
| One-off patches decay | Instructions added to fix one bad output often cause new problems elsewhere — identify and generalize or remove |
| Vagueness breeds inconsistency | "Write good code" means something different every invocation — make instructions specific and testable |
| Consensus over opinion | Spawn multiple reviewer perspectives before recommending changes |
| Symlink hygiene | CLAUDE.md and AGENTS.md should be in sync (symlinked); skills and agents directories should mirror correctly |

## Workflow

1. **Inventory** — scan all instruction files, skills, agents, hooks, context files.
2. **Per-Rule Analysis** — evaluate each instruction against 5 criteria.
3. **Cross-File Analysis** — find contradictions and duplications across files.
4. **Consensus Review** — spawn 3 parallel reviewers for independent assessment.
5. **Synthesis** — merge reviewer findings into recommendations.
6. **Report & Cleanup** — produce audit report + cleaned-up configuration files.

## Required Inputs

- A project with agentic coding configuration (CLAUDE.md, skills, agents, hooks, etc.).
- Access to read all project files (no write access needed until cleanup phase).

Optional:
- Specific pain points ("agent keeps doing X wrong", "outputs are inconsistent").
- Which files to prioritize if the full audit scope is too large.

## Progressive Disclosure Map

| Reference | Path | When to read |
|---|---|---|
| Audit criteria | [references/audit-criteria.md](references/audit-criteria.md) | Phase 2: before evaluating each instruction |
| File inventory checklist | [references/file-inventory-checklist.md](references/file-inventory-checklist.md) | Phase 1: what files to look for |
| Report template | [references/audit-report-template.md](references/audit-report-template.md) | Phase 6: when generating the report |
| Best practices | [references/setup-best-practices.md](references/setup-best-practices.md) | Phase 5: when recommending fixes |

## Trigger Conditions

**Mandatory triggers** — always activate the audit:
- "audit my setup"
- "audit CLAUDE.md"
- "agent audit"

**Strong triggers** — activate when the question involves agentic configuration:
- "review my agent config"
- "clean up my instructions"
- "optimize my agentic setup"
- "setup review"
- "lint my config"

**Do NOT trigger on:**
- Code review (use `code-review` skill)
- Security audit (use `security-analysis` skill)
- Skill creation (use skill-creator workflows)
- General project review or architecture review (use `software-architecture` skill)

## Execution Protocol

### Phase 1: Inventory

Read `references/file-inventory-checklist.md`. Scan the project for ALL instruction files:

```
Project root:
├── CLAUDE.md          — primary agent instructions
├── AGENTS.md          — multi-agent compatibility (should symlink to CLAUDE.md)
├── .claude/
│   ├── settings.json  — tool permissions and hooks
│   ├── settings.local.json — local overrides
│   ├── skills/        — installed skills
│   ├── agents/        — installed agents
│   └── hooks/         — hook scripts
├── .cursor/rules/     — Cursor rule files
├── .codex/
│   ├── skills/        — Codex skills
│   └── agents/        — Codex agents
├── codex.md           — Codex legacy instructions
├── .opencode/
│   ├── skills/        — OpenCode skills
│   └── agents/        — OpenCode agents
├── CONTEXT.md         — project context (optional)
├── SPEC.md            — project specification (optional)
├── TASKS.md           — task tracking (optional)
├── DESIGN_SYSTEM.md   — UI/design rules (optional)
└── docs/
    └── adr/           — architecture decision records
```

For each file found, record:
- **Path** — absolute or project-relative path
- **Size** — file size in bytes (large files may need special handling)
- **Last modified** — helps identify stale instructions
- **Purpose** — what this file is for in the agentic setup
- **Platform** — which CLI tool(s) use this file (Claude Code, Codex, Cursor, OpenCode)

Present the inventory as a table before proceeding to Phase 2.

### Phase 2: Per-Rule Analysis

Read `references/audit-criteria.md`. For EVERY instruction/rule in CLAUDE.md and other instruction files, evaluate against 5 criteria:

1. **Default behavior?** — Is this something the agent already does without being told?
   - Example of bloat: "Use descriptive variable names" (agents do this by default)
   - Keep only if the agent demonstrably gets this wrong without the instruction

2. **Contradicts another rule?** — Does this conflict with another instruction anywhere?
   - Check across ALL files (CLAUDE.md, skills, hooks, settings)
   - Flag the specific contradiction with file paths and line numbers

3. **Duplicates another rule?** — Is this already covered elsewhere?
   - Same rule in CLAUDE.md and a skill file = waste of context
   - Same rule worded differently in two places = confusion risk

4. **One-off patch?** — Does this read like it was added to fix one specific bad output?
   - Signs: very specific, references a specific incident, doesn't generalize
   - These decay fastest and cause the most unintended side effects

5. **Too vague?** — Would you interpret this differently on different invocations?
   - "Write clean code" = vague (no testable criteria)
   - "Functions must be under 50 lines" = specific (testable)

Produce a per-rule assessment table:

| # | Rule (summary) | File | Default? | Contradicts? | Duplicates? | One-off? | Vague? | Verdict |
|---|---|---|---|---|---|---|---|---|

Verdicts: **KEEP** (essential, well-written), **CUT** (remove — default behavior or harmful), **FIX** (rewrite — vague, contradictory, or too specific), **MERGE** (combine with another rule and keep in one place).

### Phase 3: Cross-File Analysis

Look for systemic issues across all files:

1. **CLAUDE.md <> AGENTS.md sync** — are they symlinked or identical? If different, which is authoritative?
2. **CLAUDE.md <> skills overlap** — are there instructions in CLAUDE.md that duplicate what installed skills already handle?
3. **Hook <> instruction conflicts** — does a hook enforce something that contradicts a CLAUDE.md instruction?
4. **Settings <> instruction conflicts** — do settings.json permissions conflict with stated workflows?
5. **Stale references** — do instructions reference files, functions, or patterns that no longer exist in the codebase?
6. **Missing coverage** — are there important project conventions NOT documented anywhere?

For each finding, note:
- **Files involved** — which files conflict or overlap
- **Severity** — CRITICAL (causes wrong behavior), WARNING (causes confusion), INFO (minor)
- **Recommended resolution** — specific fix

### Phase 4: Consensus Review

Spawn 3 parallel sub-agents (in a SINGLE message) for independent assessment. Use the platform's sub-agent tool (`Agent` in Claude Code, `spawn_agent` in Codex CLI, `task` in OpenCode):

**Reviewer 1: The Minimalist**
- System instruction: "You are The Minimalist. Your goal is to REMOVE as much as possible from this agentic setup. Every instruction must justify its existence with evidence that the agent behaves differently with vs without it. If in doubt, cut it. For each rule, assign one verdict: KEEP (essential — agent breaks without this), CUT (remove — default behavior, bloat, or harmful), MERGE (combine with another rule). Be ruthless. Respond with a markdown table of all rules and your verdicts, followed by a summary of your top 5 most impactful cuts."
- Input: all instruction file contents + Phase 2 per-rule assessment table

**Reviewer 2: The Consistency Expert**
- System instruction: "You are The Consistency Expert. Your goal is to find every contradiction, ambiguity, and inconsistency across this entire agentic setup. Check: cross-file contradictions, hook behaviors vs stated rules, skill overlap with CLAUDE.md, settings.json permissions vs stated workflows, and stale references to files/functions that may not exist. For each issue, assign severity: CRITICAL (causes wrong agent behavior), WARNING (causes confusion or inconsistency), INFO (minor style issue). Respond with a numbered list of all issues found, sorted by severity, with specific file paths and line numbers."
- Input: all instruction file contents + Phase 2 per-rule assessment table

**Reviewer 3: The Best Practices Architect**
- System instruction: "You are The Best Practices Architect. Your goal is to evaluate this agentic setup against best practices for agentic coding configuration. Check: file structure conventions (symlinks, directory layout), context management (what's stable vs volatile), skill coverage gaps, hook completeness, agent persona alignment, and maintenance hygiene. For each gap or violation, assign priority: MUST-FIX (significantly impacts agent quality), SHOULD-FIX (improves reliability), NICE-TO-HAVE (polish). Respond with a structured assessment covering: structure, content quality, coverage gaps, and maintenance readiness."
- Input: all instruction file contents + setup-best-practices.md reference content

**Critical:** All 3 must be spawned in one message. Sequential spawning allows later reviewers to be influenced by earlier results, destroying independence.

### Phase 5: Synthesis

Read `references/setup-best-practices.md`. Merge all 3 reviewer reports using these rules:

- **2/3 agree CUT** → recommend removal (high confidence)
- **2/3 flag contradiction** → recommend resolution (include both proposed fixes, pick the better one)
- **2/3 agree on a gap** → recommend addition (include suggested text)
- **Split decisions** → present as "Reviewers split on..." with both arguments (let the user decide)
- **Unanimous agreement** → mark as highest priority

Produce a synthesized recommendation list sorted by priority:
1. P0 — Critical contradictions and rules causing wrong behavior
2. P1 — Important removals and fixes (high reviewer consensus)
3. P2 — Nice-to-have improvements and gap fills
4. Split — Items where reviewers disagreed (user decision needed)

### Phase 6: Report & Cleanup

Read `references/audit-report-template.md`. Generate:

#### 1. Audit Report

Full findings document with:
- Executive summary and health score (A/B/C/D/F)
- File inventory table
- Per-rule assessment table with verdicts
- Contradictions and duplications found
- Missing coverage gaps
- Reviewer consensus breakdown
- Prioritized recommended changes

Save to `docs/agent-setup-audit-{YYYYMMDD}.md` in the project directory.

#### 2. Cleaned-Up CLAUDE.md

Rewritten version of CLAUDE.md with all accepted recommendations applied:
- Removed default-behavior rules
- Resolved contradictions (picked the correct side)
- Merged duplicates (kept in the most appropriate location)
- Generalized one-off patches into principles (or removed them)
- Made vague instructions specific and testable
- Added missing conventions identified by the reviewers

**Do NOT auto-apply.** Present the cleaned-up version and ask for explicit user permission before overwriting.

#### 3. Action Items

Prioritized checklist of changes that go beyond CLAUDE.md:
- Hook fixes (with exact commands)
- Settings.json changes (with exact JSON patches)
- Symlink fixes (with exact commands)
- Skill installation/removal recommendations
- Files to create, rename, or archive

Present the action items inline and offer to execute them one by one.

## Quality Gates

- [ ] All instruction files inventoried (nothing missed)
- [ ] Every rule evaluated against all 5 criteria
- [ ] Cross-file contradictions identified with file paths and line numbers
- [ ] 3 parallel reviewers spawned and completed independently
- [ ] Consensus synthesized with priority levels
- [ ] Audit report generated with per-rule verdicts and health score
- [ ] Cleaned-up CLAUDE.md proposed (not applied without explicit permission)
- [ ] Action items prioritized and presented

## Anti-Patterns

| Anti-Pattern | Why It's Dangerous | Fix |
|---|---|---|
| Auditing one file in isolation | Contradictions live BETWEEN files — you miss the worst bugs by reading only CLAUDE.md | Read everything first; cross-file analysis is mandatory |
| Keeping "just in case" rules | Every unnecessary instruction consumes context window and can conflict with future additions | If it's default behavior, cut it — the agent already does it |
| Trusting vague instructions | "Write good tests" means different things every invocation, causing inconsistent outputs | Make instructions specific and testable, or remove them |
| Ignoring hooks | Hooks enforce behavior that may directly conflict with CLAUDE.md instructions | Audit hooks alongside instruction files — they are part of the config |
| Only removing, never adding | The audit should also identify MISSING conventions that would improve outputs | Check for gaps in coverage — missing rules cause drift too |
| Applying changes without review | Auto-applying a rewritten CLAUDE.md can break working configurations | Always show the diff and ask for explicit permission before writing |
| Single-reviewer bias | One perspective misses what another catches — the audit needs diversity | Always spawn 3 parallel reviewers for independent assessment |

## Delivery Checklist

- [ ] Full file inventory completed and presented as a table
- [ ] Per-rule analysis done for every instruction across all files
- [ ] Cross-file analysis completed (contradictions, duplications, stale refs)
- [ ] 3 independent reviewers completed in parallel
- [ ] Consensus synthesized with priority levels (P0/P1/P2/Split)
- [ ] Audit report saved to `docs/agent-setup-audit-{YYYYMMDD}.md`
- [ ] Cleaned-up CLAUDE.md proposed (diff shown, not auto-applied)
- [ ] Action items shared with exact commands for each fix
