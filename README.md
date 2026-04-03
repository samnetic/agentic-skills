# Agentic Skills

> End-to-end delivery pipeline + expert domain skills + specialized agents for Claude Code, OpenCode, Cursor, and Codex.

Go from raw idea to production-deployed feature using structured workflows, parallel agent execution, and deep domain expertise. Includes a complete delivery pipeline (ideation → spec → plan → issues → implementation → review → ship) with AFK/HITL classification for autonomous agent execution.

## Install

### One Command

```bash
curl -sSL https://raw.githubusercontent.com/samnetic/agentic-skills/main/install.sh | bash
```

The installer **auto-detects** which coding agent CLIs are on your `$PATH` (`claude`, `codex`, `opencode`, `cursor`) and installs to all of them. If nothing is detected, it defaults to Claude Code.

To target a specific platform:

```bash
bash <(curl -sSL https://raw.githubusercontent.com/samnetic/agentic-skills/main/install.sh) --codex --force
```

### From a Local Clone

```bash
git clone https://github.com/samnetic/agentic-skills.git
cd your-project && bash /path/to/agentic-skills/install.sh
```

### Lifecycle CLI

Use the wrapper for `install`, `update`, `self-update`, `disable`, `enable`, `status`, `doctor`, `version`, and `uninstall`:

```bash
bash /path/to/agentic-skills/agentic-skills.sh install --claude --force
bash /path/to/agentic-skills/agentic-skills.sh update --all
bash /path/to/agentic-skills/agentic-skills.sh self-update --all --yes
bash /path/to/agentic-skills/agentic-skills.sh status
bash /path/to/agentic-skills/agentic-skills.sh doctor
bash /path/to/agentic-skills/agentic-skills.sh uninstall --path .claude --force
```

### Disable / Enable

Reversible toggles. Default: skills only.

```bash
bash agentic-skills.sh disable --path .codex
bash agentic-skills.sh enable --path .codex

# All components for one target
bash agentic-skills.sh disable --path .claude --all-components

# Everything everywhere
bash agentic-skills.sh disable --all --all-components
bash agentic-skills.sh enable --all --all-components
```

Notes:
- Codex CLI supports skills/agents toggling, but not hooks.
- Toggle state is stored under `.agentic-skills-disabled/` inside each install target.

### Interactive Installer

Running `bash install.sh` in a terminal shows an interactive menu. The installer detects installed CLIs and sets the default selection accordingly:

```
  ✓ Detected: Codex CLI, Claude Code

  Install to:
    1. Claude Code — this project
    2. Claude Code — global
    3. OpenCode — this project
    4. OpenCode — global
    5. Cursor — this project
    6. Codex CLI — this project
    7. Codex CLI — global
    8. Codex markdown — legacy
    9. Cross-client — this project
   10. Cross-client — global

  Select [6]:
```

### Non-Interactive Flags

```bash
bash install.sh --claude --force          # Claude Code (project)
bash install.sh --claude-global --force   # Claude Code (global)
bash install.sh --opencode --force        # OpenCode (project)
bash install.sh --opencode-global --force # OpenCode (global)
bash install.sh --cursor --force          # Cursor
bash install.sh --codex --force           # Codex CLI (project)
bash install.sh --codex-global --force    # Codex CLI (global)
bash install.sh --codex-md --force        # Legacy codex.md export
bash install.sh --skills-only --force     # Skills only, no agents/hooks
bash install.sh --dry-run                 # Preview without writing
```

### Uninstall

```bash
bash uninstall.sh
```

Removes only what was installed — your custom skills and agents are untouched.

### Verify Installation

```bash
claude -p "List directory names under ./skills only. Format: SKILLS:name1,name2,..."
codex exec --skip-git-repo-check "List directory names under ./.codex/skills only. Format: SKILLS:name1,name2,..."
opencode run "List directory names under ./skills only. Format: SKILLS:name1,name2,..."
```

## Delivery Pipeline — Idea to Production

The delivery pipeline chains skills together for complete feature delivery. Start at any stage:

```
 IDEATION ──→ DISCOVERY ──→ SPECIFICATION ──→ PLANNING ──→ ISSUES ──→ IMPLEMENTATION ──→ REVIEW ──→ SHIP
     │             │              │               │            │             │               │         │
 grill-session  prd-writer    spec-orchestrator  prd-to-     plan-to-    [domain skills   code-    devops-
 + council                    + software-arch    plan        issues      + qa-testing]    review    cicd
```

### Quick Start — Building a Full-Stack App from Scratch

```
"Build a task management app with real-time updates"

Step 1 → grill-session     Stress-test the idea, surface hidden assumptions
Step 2 → prd-writer        Interactive PRD creation with codebase validation
Step 3 → prd-to-plan       Vertical-slice plan with tracer bullet Phase 0
Step 4 → plan-to-issues    GitHub issues with AFK/HITL tags + dependencies
Step 5 → (agents)          Parallel agents execute AFK issues via TDD
Step 6 → code-review       Automated review + security scan
Step 7 → devops-cicd       Deploy and verify
```

Or use the orchestrator for full automation:
```
@pipeline-orchestrator Build a task management app with real-time updates
```

### AFK vs HITL — Autonomous Execution

Every task is classified:
- **AFK** (Away From Keyboard) — agent can implement and PR autonomously
- **HITL** (Human In The Loop) — needs human judgment (auth, payments, PII, ambiguous scope)

AFK issues run in parallel via sub-agents. HITL issues are flagged for your review.

### Pipeline Skills

| Skill | Purpose |
|-------|---------|
| `grill-session` | Stress-test proposals by interrogating assumptions depth-first |
| `prd-writer` | Interactive Plan-Ready PRD creation with codebase validation |
| `prd-to-plan` | Vertical-slice implementation plan with tracer-bullet Phase 0 |
| `plan-to-issues` | GitHub issues with AFK/HITL classification + dependency links |
| `delivery-pipeline` | Master orchestrator — routes work through all stages |
| `agent-setup-audit` | Audit CLAUDE.md, skills, hooks for contradictions and bloat |

### Maintaining Your Setup

Run periodic audits to keep your agentic configuration clean:

```
"Audit my setup" → agent-setup-audit

Checks: contradictions, redundancy, vague instructions, stale context,
        CLAUDE.md ↔ AGENTS.md sync, skill overlap, hook conflicts
```

### Recommended Project File Structure

| File | Purpose | Volatility |
|------|---------|-----------|
| `CLAUDE.md` | Project-specific agent instructions | Stable (project lifetime) |
| `AGENTS.md` | Symlink to CLAUDE.md for multi-agent compat | Stable |
| `SPEC.md` | Application specification and requirements | Stable (updated with features) |
| `CONTEXT.md` | Current project context for agent sessions | Volatile (per-session) |
| `TASKS.md` | Active task tracking | Volatile (archived when done) |
| `docs/adr/` | Architecture Decision Records | Stable |
| `docs/pipeline/` | Pipeline status files (per-feature) | Per-feature lifecycle |

## Domain Skills

| Skill | Lines | Description |
|-------|-------|-------------|
| `observability` | 1730+ | OpenTelemetry, structured logging (pino/structlog), Prometheus, SLOs, alerting, dashboards, incident response |
| `nextjs-react` | 2000+ | Next.js 15+, App Router, RSC, Server Actions, caching, React 19, performance |
| `auth-authz` | 1190+ | OAuth2/OIDC, sessions, JWT, passkeys/WebAuthn, RBAC/ABAC, multi-tenancy, MFA, password handling |
| `rest-api-design` | 1500+ | REST API design, RFC 9457 errors, pagination, idempotency, OpenAPI 3.1, webhooks |
| `security-analysis` | 1570+ | OWASP Top 10 2025, OWASP API Top 10, STRIDE, supply chain, LLM security, CI/CD pipeline |
| `linux-server-hardening` | 1400+ | VPS setup, SSH hardening, UFW/nftables, fail2ban, sysctl, systemd, Lynis, backups |
| `qa-testing` | 1450+ | Testing pyramid, TDD, Vitest, Playwright, Testcontainers, Clock API, visual regression |
| `postgres-db` | 1200+ | Schema design, PG 18, query optimization, partitioning, RLS, migrations, PgBouncer |
| `nodejs-engineering` | 1470+ | Node.js 22+, event loop, Express 5/Fastify 5, AsyncLocalStorage, Error.cause, worker threads |
| `devops-cicd` | 1450+ | GitHub Actions, reusable workflows, OIDC, deployment strategies, Terraform CI/CD, monitoring, Dagger |
| `trigger-dev-self-hosted` | 80+ | Trigger.dev tasks and AI workflows, self-hosting runbook, queue/idempotency/retry guardrails, Kubernetes production baseline |
| `frontend-development` | 1250+ | Modern CSS, :has(), subgrid, accessibility WCAG 2.2, design systems, Core Web Vitals |
| `software-architecture` | 1000+ | C4 model, ADRs, DDD, modular monolith, AI-native architecture, deep modules |
| `typescript-engineering` | 1100+ | TypeScript 5.8/5.9, Zod v4, branded types, discriminated unions, Effect-TS, monorepo |
| `data-modeling` | 900+ | Normalization, relationships, temporal data, hierarchies, audit trails |
| `python-engineering` | 1130+ | Python 3.13+, Pydantic v2, match/case, async, pytest, free-threading, uv/ruff/mypy |
| `cloudflare` | 880+ | DNS, CDN, WAF, Workers, Pages, R2, Zero Trust, Terraform, caching |
| `performance-optimization` | 840+ | Bundle optimization, caching, N+1 prevention, Core Web Vitals, profiling |
| `debugging` | 830+ | Systematic root cause analysis, scientific debugging, git bisect, Sentry |
| `bash-scripting` | 810+ | Modern bash, ShellCheck, awk/sed/jq, BATS testing, signal handling, Docker entrypoints |
| `git-workflows` | 730+ | Branching strategies, conventional commits, changesets, signed commits, monorepo |
| `business-analysis` | 680+ | PRDs, user stories, vertical-slice decomposition, RICE/MoSCoW/WSJF |
| `code-simplification` | 690+ | Refactoring patterns, SOLID principles, complexity reduction, cognitive load |
| `code-review` | 620+ | Severity-labeled feedback, review checklists, PR templates, review automation |
| `technical-writing` | 1680+ | Diátaxis, README templates, API docs, JSDoc/TSDoc, ADRs, changelogs, runbooks, onboarding |
| `docker-production` | 620+ | Multi-stage builds, security hardening, compose patterns, container scanning |
| `excalidraw-diagram` | 160+ | Visual-argument Excalidraw diagrams with optional Mermaid bootstrap, sectioned JSON generation, semantic palettes, lint checks, and PNG render validation loop |

## Agents (13)

Specialized personas that combine multiple skills for focused tasks:

| Agent | Model | Purpose |
|-------|-------|---------|
| `pipeline-orchestrator` | opus | End-to-end feature delivery — routes ideation through ship |
| `design-explorer` | opus | Parallel competing API/module designs with depth scoring |
| `software-architect` | opus | System design, architecture decisions, trade-off analysis |
| `security-auditor` | opus | Security review, vulnerability assessment, OWASP compliance |
| `pr-reviewer` | opus | Comprehensive code review with severity-labeled feedback |
| `simplify` | opus | Reuse/quality/efficiency review in parallel, then direct cleanup fixes |
| `db-architect` | opus | Schema design, query optimization, migration planning |
| `devops-engineer` | sonnet | CI/CD pipelines, GitHub Actions, deployment automation |
| `trigger-dev-expert` | sonnet | Trigger.dev tasks/workflows, self-hosted production guidance |
| `qa-engineer` | sonnet | Test strategy, test implementation, coverage analysis |
| `ba-analyst` | sonnet | Requirements gathering, PRDs, user stories |
| `issue-triager` | sonnet | GitHub issue triage, classification, severity routing |
| `git-flow-expert` | sonnet | Branching strategy, git hooks, release automation |

Use agents with `@agent-name` in Claude Code:

```
@pipeline-orchestrator Build a full-stack task management app from scratch
@software-architect Design a notification system for 100k users
@security-auditor Review this authentication module
@pr-reviewer Review the changes in this PR
@simplify Review and simplify my current git diff, then apply fixes
```

## Hooks

Claude Code includes 7 deterministic bash command hooks in `.claude/hooks/` (configured via `settings.json` and `settings.local.json`):

| Hook | Event | Purpose |
|------|-------|---------|
| `stop.sh` | Stop | Transcript backup, stop_hook_active guard |
| `session-start.sh` | SessionStart | Git status + context file injection |
| `session-start-compact.sh` | SessionStart:compact | Skill/agent awareness re-injection |
| `pre-compact.sh` | PreCompact | Transcript backup before compaction |
| `pre-tool-use.sh` | PreToolUse:Bash | Block rm -rf + .env access |
| `post-tool-use.sh` | PostToolUse:Write\|Edit | Shellcheck/ruff lint warnings |
| `post-tool-use-failure.sh` | PostToolUseFailure | Structured error logging |

OpenCode uses a plugin bridge (`.opencode/plugins/agentic-skills-hooks.js`) that mirrors the highest-value safeguards:
- Session context injection on `session.created`
- Skill/agent reinjection on `session.compacted`
- Bash guard for dangerous `rm -rf` and direct `.env` reads
- Session error logging to `.opencode/hooks/logs/tool_failures.jsonl`

## How Skills Work

Skills activate automatically based on trigger words in your prompts:

- "Design the database schema" → `postgres-db` + `data-modeling`
- "Set up CI/CD" → `devops-cicd`
- "Review this PR" → `code-review`
- "Write E2E tests" → `qa-testing`
- "Debug this issue" → `debugging`

Each skill contains:
1. **YAML frontmatter** with trigger-word-rich description
2. **Decision trees** for choosing between approaches
3. **Anti-patterns table** — what to avoid and why
4. **Production-ready code examples**
5. **Checklists** — verification steps before completion
6. **Constraints** — non-negotiable rules

## Cross-Platform Compatibility

While designed for Claude Code, these skills work with any AI coding assistant that supports markdown skill files. Use `bash install.sh` and select your platform:

| Platform | Installer Target | What Happens |
|----------|-----------------|-------------|
| **Claude Code** | `--claude` or `--claude-global` | Skills → `.claude/skills/`, agents → `.claude/agents/`, hooks → `settings.json` + `settings.local.json` |
| **OpenCode** | `--opencode` or `--opencode-global` | Skills → `.opencode/skills/` (or `~/.config/opencode/skills/`), agents → `.opencode/agents/` (converted to OpenCode subagent format), hooks → `.opencode/plugins/agentic-skills-hooks.js` |
| **Cursor** | `--cursor` | Each skill/agent as a rule file in `.cursor/rules/` |
| **Codex CLI** | `--codex` or `--codex-global` | Skills → `.codex/skills/` (or `$CODEX_HOME/skills/`), agents → `.codex/agents/` (or `$CODEX_HOME/agents/`) |
| **Codex Legacy** | `--codex-md` | All content concatenated into `codex.md` |
| **Any LLM** | — | Include skill content in system prompt |

## Release

Pushing a version tag triggers CI to validate and create a GitHub release:

```bash
git tag v1.3.0
git push origin v1.3.0
```

## Works With

Agentic Skills provides **deep domain expertise and context engineering** — the knowledge layer that workflow tools build on. Install alongside any of these for best results:

- **[Compound Engineering](https://github.com/troybuilt/compound-engineering)** — Workflow automation, multi-agent code review, parallel task execution. Adds `/lfg`, `/plan`, `/review` workflows. *Agentic Skills provides the domain knowledge each workflow step draws from.*
- **[Superpowers](https://github.com/superpower-labs/superpowers)** — Plan/execute workflows, TDD, brainstorming, git worktrees. Structures development cycles. *Agentic Skills gives each cycle deep expertise in the domain being worked on.*
- **[GSD (Get Stuff Done)](https://github.com/patrickjm/gsd-claude-code)** — Context engineering for Claude Code. Prevents context degradation via fresh-context-per-task spawning and aggressive task atomicity. *Agentic Skills enhances each spawned context with domain-specific knowledge and hooks that survive compaction.*

**What only Agentic Skills provides:**
- Production-grade skill guides with decision trees, anti-patterns, and checklists
- Specialized agents (`@software-architect`, `@security-auditor`, etc.)
- 7 deterministic command hooks — transcript backup, context injection, lint-on-write, rm -rf guard, error logging

## Workflow Lifecycle

### Starting a New Project

```bash
# 1. Install agentic-skills into your project
curl -sSL https://raw.githubusercontent.com/samnetic/agentic-skills/main/install.sh | bash

# 2. Create AGENTS.md symlink for multi-agent compatibility
ln -s CLAUDE.md AGENTS.md

# 3. Start the delivery pipeline
# In Claude Code / OpenCode / Codex:
"Build [your feature description] end to end"
# Or: "Start the pipeline for [feature]"
# Or: @pipeline-orchestrator [feature description]
```

### Feature Development Workflow

```
1. IDEATE    "Grill this idea: [description]"           → Stress Test Report
2. SPECIFY   "Write a PRD for [feature]"                → Plan-Ready PRD
3. PLAN      "Turn this PRD into a plan"                → Vertical-slice plan
4. ISSUES    "Create issues from this plan"             → GitHub issues (AFK/HITL tagged)
5. BUILD     (agents auto-execute AFK issues via TDD)   → PRs with tests
6. REVIEW    "Review these PRs"                         → Approved PRs
7. SHIP      "Deploy and verify"                        → Production
```

### Ongoing Maintenance

```bash
# Audit your agentic setup for contradictions, redundancy, bloat
"Audit my setup"

# Review architecture decisions
@software-architect Review the current architecture

# Security scan
@security-auditor Run a security review

# Simplify code
@simplify Review and simplify my current git diff
```

### Context Management

- **50% context usage** — write handover notes to CONTEXT.md
- **Session restart** — hooks auto-inject git status + CONTEXT.md
- **Pipeline state** — saved in `docs/pipeline/` for cross-session resumption
- **Memory** — `.claude/memory/` persists across conversations

## Contributing

### Adding a New Skill

1. Create `skills/your-skill/SKILL.md`
2. Add YAML frontmatter with `name` and `description` (trigger-word-rich)
3. Follow the structure: Principles → Decision Trees → Patterns → Anti-Patterns → Checklist
4. Keep code examples production-ready (not toy examples)
5. Submit a PR

### Quality Bar

Every skill must have:
- Decision trees for common choices
- Anti-patterns table with "why dangerous" and "fix" columns
- At least 3 production-ready code examples
- A review checklist

## License

MIT — see [LICENSE](LICENSE)
