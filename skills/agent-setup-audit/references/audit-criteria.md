# Audit Criteria

Detailed evaluation criteria for the 5-test assessment applied to every instruction
in an agentic coding configuration. Read this before Phase 2 (Per-Rule Analysis).

---

## Test 1: Default Behavior

**Question:** "If I removed this instruction, would the agent behave differently?"

If the answer is **no**, the instruction is bloat. It wastes context window, adds
noise, and can conflict with future additions.

### Common Default-Behavior Instructions to Cut

| Instruction | Why it's default | When to keep |
|---|---|---|
| "Use descriptive variable names" | All modern LLMs do this unprompted | Never — this is universal default behavior |
| "Follow best practices" | Too vague to be actionable AND default | Never — fails both the default and vagueness tests |
| "Write tests for your code" | Default when a testing skill is installed or TDD is established | Keep only if the agent consistently skips tests without it |
| "Use TypeScript strict mode" | Depends on project — not universally default | Keep if the project's tsconfig doesn't enforce it and the agent skips it |
| "Format code consistently" | Default when a formatter (Prettier, Black) is configured | Keep only if no formatter is configured and the agent produces inconsistent formatting |
| "Add error handling" | LLMs add try/catch by default in most contexts | Keep only for specific error-handling patterns (e.g., "use Result types, not exceptions") |
| "Use async/await instead of callbacks" | Default in modern JS/TS/Python projects | Never — no modern LLM generates callback-style code unprompted |
| "Comment your code" | LLMs add comments by default (often too many) | Only if you want a SPECIFIC commenting style (e.g., "JSDoc on all exports, no inline comments") |
| "Use meaningful commit messages" | Default when conventional commits skill is active | Keep only to specify a specific format (e.g., "conventional commits with scope") |
| "Handle edge cases" | LLMs attempt edge case handling by default | Keep only for specific edge cases the agent consistently misses |

### How to Verify

1. Mentally remove the instruction.
2. Generate 3 hypothetical prompts that would be affected.
3. Would the agent's output be meaningfully different without the instruction?
4. If yes on at least 2/3 prompts → KEEP. If no → CUT.

---

## Test 2: Contradictions

**Question:** "Does this instruction conflict with another instruction in ANY file?"

Contradictions are the worst kind of configuration bug. They cause non-deterministic
behavior because the agent randomly picks which rule to follow on each invocation.

### Common Contradiction Patterns

| Rule A | Rule B | Why it's a contradiction |
|---|---|---|
| "Use functional programming" | "Use OOP with classes" | Directly opposing paradigms — agent oscillates between styles |
| "Keep functions short (under 20 lines)" | Skill that encourages comprehensive inline implementations | The skill implicitly encourages long functions |
| "Never use `any` in TypeScript" | A skill file that uses `any` in its examples | Agent sees `any` as acceptable because a trusted source uses it |
| Hook blocks a command | Instruction tells agent to use that command | Agent tries to follow the instruction, hook rejects it, agent is confused |
| "Use squash-and-merge" | "Preserve detailed commit history" | Squash destroys the detailed history |
| "Always use server components" | "Use client components for interactivity" | Without clear boundaries, agent guesses wrong on each component |
| "Minimize dependencies" | "Use X library for Y" (for something achievable without it) | Contradicts the minimization principle |

### Detection Method

For each rule:
1. Extract the topic/domain (e.g., "error handling", "state management", "testing").
2. Search ALL other files for instructions on the same topic.
3. Compare stances — do they agree, complement, or conflict?
4. If conflict → flag with both file paths and line numbers.

### Resolution Strategies

- **Pick one and remove the other** — when rules are truly opposed.
- **Add scope/context** — "Use FP for data transformations; use classes for stateful services."
- **Defer to the skill** — if a skill covers the topic, remove the CLAUDE.md rule and let the skill handle it.
- **Update the hook** — if a hook contradicts an instruction, fix whichever is wrong.

---

## Test 3: Duplication

**Question:** "Is this instruction already covered by another file?"

Duplication wastes context window AND creates a maintenance hazard. When one copy
is updated and the other isn't, they drift into contradiction.

### Common Duplication Patterns

| CLAUDE.md Rule | Already Covered By | Resolution |
|---|---|---|
| Database conventions (schema, naming, etc.) | `postgres-db` skill | Remove from CLAUDE.md; keep in skill |
| Git commit format rules | `git-workflows` skill | Remove from CLAUDE.md; keep in skill |
| Testing patterns and strategies | `qa-testing` skill | Remove from CLAUDE.md; keep in skill |
| TypeScript coding standards | `typescript-engineering` skill | Remove from CLAUDE.md; keep project-specific overrides only |
| API design conventions | `rest-api-design` skill | Remove from CLAUDE.md; keep in skill |
| CSS/accessibility rules | `frontend-development` skill | Remove from CLAUDE.md; keep in skill |
| Security practices | `security-analysis` skill | Remove from CLAUDE.md; keep in skill |

### The Single Source of Truth Rule

Every instruction should live in exactly ONE location:
- **Project-specific conventions** → CLAUDE.md
- **Domain knowledge** → the appropriate skill
- **Behavioral enforcement** → hooks
- **Tool permissions** → settings.json

If you find the same rule in two places, decide which is the authoritative location
and remove the duplicate.

### When Duplication Is Acceptable

- A brief pointer in CLAUDE.md referencing a skill: "See `qa-testing` skill for testing patterns" — this is a reference, not duplication.
- A project-specific OVERRIDE of a skill default: "Override: use Vitest instead of Jest (contrary to qa-testing skill default)" — this is clarification, not duplication.

---

## Test 4: One-Off Patches

**Question:** "Was this instruction added to fix one specific bad output?"

One-off patches are the most insidious form of configuration debt. They typically:
- Fix the immediate symptom but cause side effects elsewhere.
- Are overly specific and don't generalize.
- Decay as the codebase evolves (the original problem may no longer exist).

### Telltale Signs

| Sign | Example | Why it's a problem |
|---|---|---|
| Very specific edge case | "When handling CSV files with BOM headers, strip the BOM first" | Too narrow — applies to one scenario |
| References a past incident | "After the auth bug in March, always check token expiry" | The incident context is lost; the rule looks arbitrary to the agent |
| Negative framing without principle | "Never use forEach on arrays over 1000 items" | Why 1000? What's the principle? |
| Oddly specific thresholds | "Switch statements must have no more than 7 cases" | Arbitrary number with no justification |
| Band-aid for a tooling gap | "Always run lint before committing" | Should be a hook, not an instruction |
| Workaround for agent weakness | "Don't generate more than 3 files at once" | May be fixed in newer agent versions |

### Resolution Strategies

1. **Generalize to a principle:** "Never use forEach on arrays over 1000 items" → "Prefer iterators or streaming for large collections to avoid blocking the event loop."
2. **Move to a hook:** "Always run lint before committing" → add a pre-commit hook.
3. **Remove if obsolete:** If the original problem no longer exists, delete the rule.
4. **Add context:** If the rule IS important, add a comment explaining WHY it exists so future audits understand the reasoning.

---

## Test 5: Vagueness

**Question:** "Could you write an automated test that checks whether this instruction is being followed?"

If you can't write a test — even a conceptual one — the instruction is too vague.
Vague instructions cause inconsistent agent behavior because the agent interprets
them differently on each invocation.

### The Specificity Spectrum

| Vague (cut or rewrite) | Specific (keep) |
|---|---|
| "Write clean code" | "Functions must not exceed 50 lines; extract helper functions when they do" |
| "Follow best practices" | "Use Zod for runtime validation at all API boundaries" |
| "Be careful with performance" | "Database queries must use indexes; flag any query without a WHERE clause on a table over 10K rows" |
| "Write good tests" | "Maintain >80% line coverage; every public function must have at least one unit test" |
| "Handle errors properly" | "Use Result<T, E> types for expected errors; throw only for programming bugs; never catch and ignore" |
| "Keep the UI accessible" | "All interactive elements must have ARIA labels; color contrast must meet WCAG AA (4.5:1)" |
| "Document your code" | "All exported functions must have JSDoc with @param and @returns; no inline comments except for non-obvious business logic" |
| "Use proper types" | "No `any` or `unknown` casts without a // SAFETY comment explaining why; prefer branded types for IDs" |

### Rewriting Vague Instructions

For each vague instruction:
1. Identify the INTENT — what behavior is the author trying to achieve?
2. Define a TESTABLE criterion — what would "pass" vs "fail" look like?
3. Write the SPECIFIC version — include concrete thresholds, tool names, or patterns.
4. If you can't make it specific, the instruction is probably default behavior — cut it.

### The "Show Me" Test

If someone asked "show me a violation of this rule," could you produce one unambiguously?
- "Write clean code" → you can't show a clear violation (what's "unclean"?)
- "Functions must not exceed 50 lines" → you can trivially show a 51-line function

If you can't show a clear violation, the rule isn't actionable.

---

## Verdict Assignment

After applying all 5 tests, assign one verdict:

| Verdict | Criteria | Action |
|---|---|---|
| **KEEP** | Passes all 5 tests: not default, no contradictions, no duplicates, not a one-off, specific enough | No changes needed |
| **CUT** | Fails Test 1 (default behavior) or is a harmful one-off patch | Remove the instruction entirely |
| **FIX** | Fails Test 2 (contradiction), Test 4 (one-off), or Test 5 (vagueness) but has valid intent | Rewrite to be specific, consistent, and principle-based |
| **MERGE** | Fails Test 3 (duplication) — the rule is valid but lives in the wrong place | Move to the authoritative location and remove the duplicate |
