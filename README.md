# Agentic Skills

> 25 expert-level domain skills + 9 specialized agents for Claude Code, OpenCode, Cursor, and Codex.

Production-grade reference guides with decision trees, anti-patterns, code examples, and checklists. Drop into any project for instant AI-assisted development expertise.

## Install

### One Command

```bash
curl -sSL https://raw.githubusercontent.com/samnetic/agentic-skills/main/install.sh | bash
```

Or with options:

```bash
bash <(curl -sSL https://raw.githubusercontent.com/samnetic/agentic-skills/main/install.sh) --claude --force
```

### From a Local Clone

```bash
git clone https://github.com/samnetic/agentic-skills.git
cd your-project && bash /path/to/agentic-skills/install.sh
```

### Unified CLI (Recommended)

Use the wrapper for a cleaner lifecycle UX (`install`, `update`, `self-update`, `status`, `doctor`, `version`, `uninstall`):

```bash
# Install (example: Claude project)
bash /path/to/agentic-skills/agentic-skills.sh install --claude --force

# Update based on existing manifest settings
bash /path/to/agentic-skills/agentic-skills.sh update --all

# Self-update from latest GitHub main, then run update
bash /path/to/agentic-skills/agentic-skills.sh self-update --all --yes

# Show what is installed
bash /path/to/agentic-skills/agentic-skills.sh status

# Validate installation integrity
bash /path/to/agentic-skills/agentic-skills.sh doctor

# Uninstall
bash /path/to/agentic-skills/agentic-skills.sh uninstall --path .claude --force
```

### npm / npx Command

If published to npm, users can run the toolkit as a command:

```bash
# One-off execution without global install
npx agentic-skills@latest install --claude --force

# Lifecycle commands
npx agentic-skills@latest status
npx agentic-skills@latest doctor
npx agentic-skills@latest update --all
npx agentic-skills@latest self-update --all --yes
```

### Homebrew (macOS/Linux)

If the Homebrew tap is available:

```bash
brew tap samnetic/agentic-skills
brew install agentic-skills
agentic-skills version

# Update / remove
brew upgrade agentic-skills
brew uninstall agentic-skills
```

### Interactive Installer

The installer lets you choose your platform and components:

```
$ bash install.sh

  ╭──────────────────────────────────────╮
  │  Agentic Skills                      │
  │  25 skills · 9 agents · 7 hooks      │
  ╰──────────────────────────────────────╯

  Install to:
    1. Claude Code — this project
    2. Claude Code — global
    3. OpenCode — this project
    4. OpenCode — global
    5. Cursor — this project
    6. Codex CLI — this project

  Components: Skills, Agents, Hooks
```

### Non-Interactive

```bash
# Claude Code (current project, everything)
bash install.sh --claude --force

# Claude Code (global)
bash install.sh --claude-global --force

# OpenCode (current project, everything)
bash install.sh --opencode --force

# OpenCode (global)
bash install.sh --opencode-global --force

# Cursor
bash install.sh --cursor --force

# Skills only, no agents or hooks
bash install.sh --claude --skills-only --force

# Preview without installing
bash install.sh --dry-run
```

### Update Global Claude Installation (One-Liner)

Recommended for existing global installs. `jq` enables automatic hook-configuration merge into existing settings files.

```bash
command -v jq >/dev/null || { echo "Install jq first: brew install jq (macOS) or sudo apt-get install -y jq (Ubuntu/Debian)"; exit 1; }; curl -sSL https://raw.githubusercontent.com/samnetic/agentic-skills/main/install.sh | bash -s -- --claude-global --force
```

### Uninstall

```bash
bash uninstall.sh
```

Removes only what was installed — your custom skills and agents are untouched.

### Test

```bash
# Installer + CLI smoke tests
bash tests/run-all.sh

# Individual suites
bash tests/smoke-installer.sh
bash tests/smoke-manager.sh
bash tests/smoke-clis.sh
```

### Live CLI Verification

Use these to verify each installed coding agent can access skills in this repo:

```bash
claude -p "In this repo, list directory names under ./skills only. Return exactly one line in this format: SKILLS:name1,name2,... sorted alphabetically with no spaces."

codex exec "In this repo, list directory names under ./skills only. Return exactly one line in this format: SKILLS:name1,name2,... sorted alphabetically with no spaces."

opencode run "In this repo, list directory names under ./skills only. Return exactly one line in this format: SKILLS:name1,name2,... sorted alphabetically with no spaces."
```

### Alternative: `npx skills`

```bash
npx skills add samnetic/agentic-skills
```

Installs skills only (no agents or hooks) into `.claude/skills/` in the current project.

## Skills (25)

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

## Agents (9)

Specialized personas that combine multiple skills for focused tasks:

| Agent | Model | Purpose |
|-------|-------|---------|
| `software-architect` | opus | System design, architecture decisions, trade-off analysis |
| `security-auditor` | opus | Security review, vulnerability assessment, OWASP compliance |
| `pr-reviewer` | opus | Comprehensive code review with severity-labeled feedback |
| `simplify` | opus | Reuse/quality/efficiency review in parallel, then direct cleanup fixes |
| `db-architect` | opus | Schema design, query optimization, migration planning |
| `devops-engineer` | sonnet | CI/CD pipelines, GitHub Actions, deployment automation |
| `qa-engineer` | sonnet | Test strategy, test implementation, coverage analysis |
| `ba-analyst` | sonnet | Requirements gathering, PRDs, user stories |
| `git-flow-expert` | sonnet | Branching strategy, git hooks, release automation |

Use agents with `@agent-name` in Claude Code:

```
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
| **Codex CLI** | `--codex` | All content concatenated into `codex.md` |
| **Any LLM** | — | Include skill content in system prompt |

## Maintainer Release Automation

Pushing a version tag triggers GitHub Actions to validate, publish npm, create a GitHub release, and update Homebrew formula metadata in the tap repository.

```bash
# Example
git tag v1.3.0
git push origin v1.3.0
```

Required repository secrets:
- `NPM_TOKEN` for npm publish
- `HOMEBREW_TAP_GITHUB_TOKEN` for pushing formula updates to the Homebrew tap

Optional repository variables:
- `HOMEBREW_TAP_REPO` (default: `samnetic/homebrew-agentic-skills`)
- `HOMEBREW_TAP_BRANCH` (default: `main`)

## Works With

Agentic Skills provides **deep domain expertise and context engineering** — the knowledge layer that workflow tools build on. Install alongside any of these for best results:

- **[Compound Engineering](https://github.com/troybuilt/compound-engineering)** — Workflow automation, multi-agent code review, parallel task execution. Adds `/lfg`, `/plan`, `/review` workflows. *Agentic Skills provides the domain knowledge each workflow step draws from.*
- **[Superpowers](https://github.com/superpower-labs/superpowers)** — Plan/execute workflows, TDD, brainstorming, git worktrees. Structures development cycles. *Agentic Skills gives each cycle deep expertise in the domain being worked on.*
- **[GSD (Get Stuff Done)](https://github.com/patrickjm/gsd-claude-code)** — Context engineering for Claude Code. Prevents context degradation via fresh-context-per-task spawning and aggressive task atomicity. *Agentic Skills enhances each spawned context with domain-specific knowledge and hooks that survive compaction.*

**What only Agentic Skills provides:**
- 25 production-grade skill guides with decision trees, anti-patterns, and checklists
- 9 specialized agents (`@software-architect`, `@security-auditor`, etc.)
- 7 deterministic command hooks — transcript backup, context injection, lint-on-write, rm -rf guard, error logging

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
