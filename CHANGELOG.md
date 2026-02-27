# Changelog

All notable changes to this project will be documented in this file.

## [1.2.0] — 2026-02-26

### Changed

**Hooks Upgrade — All Command Hooks (3 → 7):**

Replaced fragile prompt hooks with deterministic bash command hooks. Prompt hooks (Haiku-powered) sometimes returned plain text instead of JSON, causing "JSON validation failed" errors. All hooks are now zero-dependency bash scripts.

- **Replaced**: Stop prompt hook → `stop.sh` command hook (transcript backup + stop_hook_active guard)
- **Replaced**: PreToolUse (Write|Edit) prompt hook → `pre-tool-use.sh` command hook (rm -rf guard + .env blocking, now on Bash matcher)
- **Replaced**: SessionStart:compact inline echo → `session-start-compact.sh` command hook (dynamic skill/agent discovery)
- **Added**: `session-start.sh` — Git status + CONTEXT.md/TODO.md injection at session start
- **Added**: `pre-compact.sh` — Transcript backup before context compaction
- **Added**: `post-tool-use.sh` — Shellcheck/ruff lint warnings after Write/Edit (non-blocking)
- **Added**: `post-tool-use-failure.sh` — Structured error logging to `.claude/hooks/logs/tool_failures.jsonl`
- **Updated**: `settings.local.json` — All hooks now use `type: "command"` referencing bash scripts
- **Updated**: `install.sh` — Copies hook scripts, creates logs/backups directories, updated banner/manifest
- **Updated**: `uninstall.sh` — Surgical removal of hook scripts, logs, and backups

## [1.1.0] — 2026-02-25

### Added

**7 New Domain Skills (18 → 25):**
- `observability` — OpenTelemetry SDK setup, structured logging (pino/structlog), Prometheus metrics, SLOs/SLIs, alerting rules, Grafana dashboards, incident response runbooks
- `auth-authz` — OAuth2/OIDC flows, session vs JWT trade-offs, passkeys/WebAuthn, RBAC/ABAC, multi-tenancy isolation, MFA, password hashing (argon2/scrypt)
- `rest-api-design` — REST design, RFC 9457 problem details, cursor pagination, idempotency keys, OpenAPI 3.1, webhooks, rate limiting, versioning
- `linux-server-hardening` — VPS setup, SSH hardening, UFW/nftables, fail2ban, sysctl tuning, systemd services, CIS benchmarks, Lynis auditing
- `cloudflare` — DNS (proxy vs DNS-only), CDN caching, WAF rules, Workers/Pages/R2, Zero Trust, Terraform provider
- `technical-writing` — Diátaxis framework, README templates, API docs (JSDoc/TSDoc), ADRs, changelogs, runbooks, onboarding guides
- `bash-scripting` — Modern bash patterns, ShellCheck, awk/sed/jq, BATS testing, signal handling, Docker entrypoints

### Improved

**Gap Analysis — 8 Skills Updated to State-of-the-Art:**

- `typescript-engineering` — Added Zod v4 (`.check()` API, Standard Schema), TS 5.8 `erasableSyntaxOnly`/`--isolatedDeclarations`, TS 5.9 `NoInfer<T>`, Effect-TS `Effect.gen` with short generators
- `python-engineering` — Added match/case structural patterns (class, mapping, guard, OR), PEP 735 `[dependency-groups]`, Pydantic functional validators (`BeforeValidator`/`AfterValidator`/`@computed_field`), ruff TC/PERF/SIM/PTH rules with `runtime-evaluated-base-classes`, mypy per-module overrides, pytest `pytest.param`/`monkeypatch`/`capsys`
- `nodejs-engineering` — Added `Error.cause` with updated `AppError` constructor, `AsyncLocalStorage` for request context, Express 5 breaking changes (named wildcards, path-to-regexp v8), Fastify 5 TypeBox type provider, `node:test` MockTimers + coverage thresholds + snapshot testing, `process.loadEnvFile()`, expanded Web Crypto API (ECDSA sign/verify, SHA-256 digest), `structuredClone` for worker threads, fixed `node:sqlite` (added `--experimental-sqlite` flag, named params, query methods), fixed Permission Model (removed false `--allow-net`, added `process.permission.has()`)
- `security-analysis` — Added OWASP API Security Top 10 (2023) table with BOLA/BFLA/BOPLA code examples, completed OWASP LLM Top 10 (2025) from 6→10 categories, added SSRF cloud metadata IP blocking with IMDSv2 note
- `devops-cicd` — Added deployment strategies (rolling with docker-rollout, blue-green deploy script, canary weighted routing), Terraform CI/CD workflow (plan on PR, apply on merge), `secrets: inherit` for reusable workflows, Python/uv and Rust cache examples, actionlint + zizmor workflow linting
- `docker-production` — Added BuildKit `--mount=type=cache` in Dockerfile template, Grype as alternative CVE scanner, multi-platform builds (`--platform`, `$BUILDPLATFORM`), Chainguard images
- `rest-api-design` — Fixed OpenAPI 3.1 `nullable: true` → `type: [string, 'null']`
- `observability` — Fixed broken Pydantic import path, added structlog `FilterBoundLogger` type annotation

## [1.0.0] — 2025-02-24

### Added

**18 Domain Skills:**
- `software-architecture` — System design, ADRs, DDD, modular monolith, cell-based architecture, AI-native architecture, deep modules, evolutionary architecture
- `postgres-db` — Schema design, query optimization, indexing, RLS, migrations, PgBouncer, pg_stat_statements
- `data-modeling` — Normalization, relationships, temporal data, hierarchies, audit trails, UUIDv7
- `typescript-engineering` — Strict mode, Zod, branded types, discriminated unions, Effect-TS, Standard Schema, test data patterns
- `python-engineering` — Python 3.12+, Pydantic v2, async patterns, pytest, uv/ruff/mypy
- `nodejs-engineering` — Event loop, graceful shutdown, streams, Express 5/Fastify, structured logging
- `nextjs-react` — Next.js 15+, App Router, RSC serialization rules, Server Actions, caching, React 19 hooks, React Compiler, performance patterns, self-hosting, metadata/OG generation
- `frontend-development` — Modern CSS (container queries, layers, nesting, scope, anchor positioning), WCAG 2.2, Tailwind v4, typography micro-rules, touch/interaction patterns
- `security-analysis` — OWASP Top 10 (2025), STRIDE, supply chain security (SLSA, SBOM), passkeys/WebAuthn, SRI, security.txt, AI/LLM security
- `devops-cicd` — GitHub Actions, wave-based parallel CI, deployment strategies, monitoring, Terraform, AI model profiles
- `docker-production` — Multi-stage builds, security hardening, compose patterns, CI/CD integration
- `qa-testing` — Testing pyramid, vertical-slice TDD, Vitest, Playwright, Testcontainers, property-based testing, mutation testing, SDK-style interfaces
- `git-workflows` — Branching strategies, conventional commits, husky, semantic-release
- `debugging` — Systematic root cause analysis, scientific debugging methodology, git bisect, cognitive biases
- `performance-optimization` — Bundle optimization, caching strategies, N+1 prevention, Core Web Vitals
- `code-review` — Severity-labeled feedback, review checklists, PR templates
- `code-simplification` — Refactoring patterns, SOLID principles, complexity reduction
- `business-analysis` — PRDs, user stories, vertical-slice issue decomposition, RICE/MoSCoW, gray area identification

**8 Specialized Agents:**
- `software-architect` (opus) — System design, architecture decisions
- `security-auditor` (opus) — Security review, vulnerability assessment
- `pr-reviewer` (opus) — Code review with severity labels
- `db-architect` (opus) — Schema design, query optimization
- `devops-engineer` (sonnet) — CI/CD, GitHub Actions
- `qa-engineer` (sonnet) — Test strategy, implementation
- `ba-analyst` (sonnet) — Requirements, PRDs
- `git-flow-expert` (sonnet) — Branching, git hooks

**Infrastructure:**
- Quality gate hooks (Stop, PreCompact, PreToolUse)
- `npx skills add` distribution support
- `install.sh` for full installation (agents + hooks)
- Cross-platform compatibility (Claude Code, Cursor, Codex)
