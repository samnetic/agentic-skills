# Agentic Skills — Portable Claude Code Skill Pack

This repository contains a curated set of high-quality skills and agents for Claude Code.
Skills live in `skills/` (for `npx skills add` distribution) and agents in `agents/`.
Use `install.sh` from a target project to copy agents and hooks, or install skills via `npx skills add <owner>/agentic-skills`.

## Repository Structure

```
skills/           → 25 skill directories, each containing SKILL.md (npx distribution root)
agents/           → 8 agent .md files
.claude/          → Mirror of skills + agents + hooks (for local development)
.claude/hooks/    → 7 bash command hook scripts
install.sh        → Installer script (copies agents + hooks to target project)
CHANGELOG.md      → Release history
```

## Available Skills (25)

| Skill | Lines | Triggers |
|-------|-------|----------|
| `observability` | 1730+ | OpenTelemetry, Prometheus, structured logging, SLOs, alerting, dashboards |
| `auth-authz` | 1190+ | OAuth2/OIDC, sessions, JWT, passkeys, RBAC/ABAC, multi-tenancy, MFA |
| `nextjs-react` | 2000+ | Next.js 15, App Router, Server Components, Server Actions, RSC |
| `rest-api-design` | 1500+ | REST API, pagination, idempotency, OpenAPI, versioning, rate limiting |
| `security-analysis` | 1570+ | OWASP 2025, OWASP API Top 10, STRIDE, supply chain, LLM security |
| `linux-server-hardening` | 1400+ | VPS, SSH hardening, firewall, sysctl, CIS benchmarks, Lynis |
| `qa-testing` | 1450+ | unit tests, integration tests, E2E, TDD, Playwright, Vitest |
| `postgres-db` | 1200+ | schema, query optimization, indexes, RLS, migrations, PgBouncer |
| `nodejs-engineering` | 1470+ | Node.js 22+, event loop, Express 5/Fastify 5, AsyncLocalStorage, Error.cause |
| `devops-cicd` | 1450+ | GitHub Actions, CI/CD, deployment strategies, Terraform CI/CD, monitoring |
| `frontend-development` | 1250+ | CSS, accessibility, WCAG, responsive design, Core Web Vitals |
| `software-architecture` | 1000+ | system design, ADR, architecture review, C4 model, DDD |
| `typescript-engineering` | 1100+ | TypeScript 5.8/5.9, tsconfig, Zod v4, branded types, Effect-TS |
| `data-modeling` | 900+ | entity design, normalization, relationships, temporal data, audit trails |
| `python-engineering` | 1130+ | Python 3.13+, Pydantic v2, match/case, pytest, async, uv/ruff/mypy |
| `cloudflare` | 880+ | DNS, CDN, WAF, Workers, Pages, R2, Zero Trust, caching |
| `performance-optimization` | 840+ | bundle size, caching, N+1, load testing, Core Web Vitals |
| `debugging` | 830+ | root cause analysis, git bisect, memory leaks, race conditions |
| `bash-scripting` | 810+ | Modern bash, ShellCheck, awk/sed/jq, BATS testing, signal handling |
| `git-workflows` | 730+ | branching strategy, conventional commits, husky, semantic-release |
| `business-analysis` | 680+ | PRD, user stories, acceptance criteria, MoSCoW, RICE |
| `code-simplification` | 690+ | refactoring, SOLID, code smells, complexity reduction |
| `code-review` | 620+ | PR review, code quality, review checklist, severity labels |
| `technical-writing` | 1680+ | Diátaxis, README, API docs, JSDoc/TSDoc, ADRs, changelogs, runbooks |
| `docker-production` | 620+ | Dockerfile, compose, multi-stage builds, container security |

## Available Agents (8)

| Agent | Model | Purpose |
|-------|-------|---------|
| `software-architect` | opus | System design, architecture decisions, trade-off analysis |
| `security-auditor` | opus | Security review, vulnerability assessment, OWASP compliance |
| `pr-reviewer` | opus | Comprehensive code review with severity-labeled feedback |
| `db-architect` | opus | Schema design, query optimization, migration planning |
| `devops-engineer` | sonnet | CI/CD pipelines, GitHub Actions, deployment automation |
| `qa-engineer` | sonnet | Test strategy, test implementation, coverage analysis |
| `ba-analyst` | sonnet | Requirements gathering, PRDs, user stories |
| `git-flow-expert` | sonnet | Branching strategy, git hooks, release automation |

## Conventions

- **Architecture**: Default to modular monolith; justify microservices with evidence
- **Database**: PostgreSQL with `timestamptz`, `text`, `bigint`/UUIDv7 PKs
- **Testing**: Testing pyramid — unit > integration > E2E; TDD for new features
- **Git**: Conventional commits, squash-and-merge, semantic-release
- **Security**: OWASP Top 10 compliance; no hardcoded secrets; validate at boundaries
- **TypeScript**: Strict mode, Zod for runtime validation, discriminated unions over enums
- **CSS**: Mobile-first, container queries, prefer native CSS over utility frameworks
