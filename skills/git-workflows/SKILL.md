---
name: git-workflows
description: >-
  Git version control and collaboration workflow expertise. Use when setting up branching
  strategies (trunk-based, GitFlow, GitHub Flow), writing conventional commits, configuring
  semantic versioning and automated releases, creating PR templates, setting up code owners,
  configuring branch protection rules, resolving merge conflicts, performing interactive
  rebase, writing .gitignore files, setting up git hooks (husky, lint-staged, lefthook),
  reviewing PR quality, implementing squash-and-merge vs rebase workflows, managing monorepo
  git strategies, cherry-picking, git bisect for debugging, configuring changesets for
  monorepo versioning, setting up signed commits, or designing release processes.
  Triggers: git, branch, commit, merge, rebase, PR, pull request, code review, GitFlow,
  trunk-based, conventional commits, semantic versioning, semver, release, tag, git hook,
  husky, lint-staged, lefthook, .gitignore, CODEOWNERS, branch protection, cherry-pick,
  bisect, merge conflict, squash, monorepo, changesets, signed commits.
---

# Git Workflows Skill

Use git as a communication tool, not just version control. Every commit tells a story. Every branch has a purpose. Every PR is a conversation.

---

## Core Principles

| Principle | Meaning |
|---|---|
| **Commit messages are documentation** | Future you reads them. Make them count |
| **Small PRs, fast reviews** | <400 lines. Reviewed in <24 hours |
| **Main is always deployable** | Never break main. Use branch protection |
| **Linear history when possible** | Squash-and-merge or rebase for clean history |
| **Automate conventions** | Hooks enforce what documentation can't |

---

## 1. Choose a Branching Strategy

```
Team size and deploy frequency?
├── Solo / small team, deploy daily+
│   └── Trunk-Based Development
│       main ← feature branches (short-lived, <1 day)
│       Deploy from main continuously
│
├── Small-medium team, deploy weekly
│   └── GitHub Flow (recommended default)
│       main ← feature/xxx branches (1-3 days)
│       PR + review + merge to main → deploy
│
└── Large team, scheduled releases
    └── GitFlow (complex, use only if needed)
        main ← develop ← feature/xxx
        release/x.y.z branches for stabilization
        hotfix branches from main
```

### GitHub Flow (Recommended Default)

```
main ─────●─────●─────●─────●─────●─────●──→
           \         ↗   \         ↗
            ●───●───●     ●───●───●
           feat/login    feat/search
```

**Rules:**
1. `main` is always deployable
2. Branch from `main` for every change
3. Branch names: `feat/`, `fix/`, `chore/`, `docs/`, `refactor/`
4. Open PR early (draft if WIP)
5. Get review, address feedback
6. Squash-and-merge to main
7. Deploy from main

---

## 2. Write Conventional Commits

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Commit Types

| Type | When | Example |
|---|---|---|
| `feat` | New feature for the user | `feat(auth): add OAuth2 login with Google` |
| `fix` | Bug fix for the user | `fix(cart): prevent negative quantity` |
| `docs` | Documentation only | `docs(api): add rate limiting section` |
| `style` | Formatting, no code change | `style: format with prettier` |
| `refactor` | Neither fix nor feature | `refactor(users): extract validation logic` |
| `perf` | Performance improvement | `perf(db): add index for user lookups` |
| `test` | Adding/fixing tests | `test(auth): add JWT expiration tests` |
| `chore` | Build, CI, tooling | `chore(deps): update eslint to v9` |
| `ci` | CI/CD changes | `ci: add caching to GitHub Actions` |
| `build` | Build system changes | `build: switch to esbuild bundler` |

### Breaking Changes

```
feat(api)!: change authentication to bearer tokens

BREAKING CHANGE: API now requires Bearer token in Authorization header.
Basic auth is no longer supported. Migrate by adding `Authorization: Bearer <token>`
header to all requests.
```

### Commit Message Rules

1. Imperative mood: "add feature" not "added feature" or "adds feature"
2. No period at the end of subject
3. Subject line max 72 characters
4. Body wraps at 72 characters
5. Body explains WHY, not WHAT (the diff shows what)
6. Reference issues: `Closes #123`, `Fixes #456`

---

## 3. Set Up Git Hooks

Automate commit linting, formatting, and tests before code leaves your machine.

**Quick start with Husky:**

```bash
npm install -D husky lint-staged
npx husky init
```

```json
// package.json
{
  "lint-staged": {
    "*.{ts,tsx}": ["eslint --fix", "prettier --write"],
    "*.{json,md,yml,yaml}": ["prettier --write"]
  }
}
```

**Quick start with Lefthook (faster, language-agnostic):**

```yaml
# lefthook.yml
pre-commit:
  parallel: true
  commands:
    lint:
      glob: "*.{ts,tsx}"
      run: npx eslint {staged_files}
    format:
      glob: "*.{ts,tsx,css,json}"
      run: npx prettier --check {staged_files}
```

> Deep-dive: Full hook configs, commitlint, Husky vs Lefthook comparison, and signed commits -- see `references/hooks-and-automation.md`

---

## 4. Configure Branch Protection

```yaml
# Recommended settings for main branch:
branch_protection:
  required_reviews: 1
  dismiss_stale_reviews: true
  require_code_owner_reviews: true
  require_status_checks:
    - ci / lint
    - ci / test
    - ci / security
  require_branches_up_to_date: true
  require_linear_history: true
  allow_force_push: false
  allow_deletions: false
```

---

## 5. Set Up PR Workflow

**Target: <400 lines per PR.** Small PRs get better reviews and ship faster.

Create a PR template at `.github/pull_request_template.md` with sections: What, Why, How, Testing, Checklist.

Create a `CODEOWNERS` file to route reviews to the right teams per directory.

> Deep-dive: Full PR template, CODEOWNERS example, size guide, .gitignore template, and useful git commands -- see `references/pr-and-collaboration.md`

---

## 6. Automate Releases

### Single Package: semantic-release

Commit types drive version bumps automatically:
- `fix:` -> patch (1.0.0 -> 1.0.1)
- `feat:` -> minor (1.0.0 -> 1.1.0)
- `BREAKING CHANGE:` -> major (1.0.0 -> 2.0.0)

### Monorepo: Changesets

Each PR includes an explicit changeset file declaring the semver impact per package. A CI bot batches them into a "Version Packages" PR.

```bash
npx changeset           # Create changeset (interactive)
npx changeset version   # Apply version bumps + changelogs
npx changeset publish   # Publish to npm
```

> Deep-dive: Full semantic-release config, Changesets CI workflow, monorepo strategies, workspace-aware CI -- see `references/monorepo-and-versioning.md`

---

## Decision Tree

```
What do you need?
│
├── Setting up a new project's git workflow?
│   └── Follow Steps 1-6 in order above
│
├── Choosing branching strategy?
│   └── Step 1: GitHub Flow unless you have a strong reason for GitFlow
│
├── Enforcing commit quality?
│   └── Step 2 (conventions) + Step 3 (hooks with commitlint)
│
├── Setting up code review process?
│   └── Step 4 (branch protection) + Step 5 (PR workflow)
│   └── Read: references/pr-and-collaboration.md
│
├── Automating releases?
│   ├── Single package → semantic-release (Step 6)
│   └── Monorepo → Changesets
│       └── Read: references/monorepo-and-versioning.md
│
├── Configuring git hooks?
│   └── Step 3 (quick start) or references/hooks-and-automation.md (full setup)
│
├── Setting up signed commits?
│   └── Read: references/hooks-and-automation.md#signed-commits
│
└── Managing a monorepo?
    └── Read: references/monorepo-and-versioning.md
```

---

## Anti-Patterns

| Anti-Pattern | Why It's Dangerous | Fix |
|---|---|---|
| Committing directly to main | Bypasses review, breaks CI | Branch protection + PR workflow |
| "WIP" or "fix" commit messages | No context for future readers | Conventional commits |
| Giant PRs (1000+ lines) | Rubber stamp reviews, hidden bugs | Break into smaller PRs |
| Long-lived branches (weeks+) | Merge conflicts, drift from main | Short-lived branches (<3 days) |
| Force push to shared branches | Overwrites teammates' work | Only force push your own branches |
| `.env` committed to repo | Secrets in git history forever | `.gitignore` + `.env.example` |
| No branch protection | Anyone can push to main | Require reviews + status checks |
| Merge commits everywhere | Noisy history, hard to bisect | Squash-and-merge for PRs |
| No CODEOWNERS | Wrong people review critical code | Define owners per directory |
| Manual version bumping | Forgotten, inconsistent | semantic-release or Changesets |
| Unsigned commits in prod | No proof of authorship | GPG or SSH commit signing |
| Full CI on every package change | Slow, expensive monorepo CI | Workspace-aware CI with paths-filter |

---

## Progressive Disclosure Map

| Topic | Reference | When to read |
|---|---|---|
| Git hooks (Husky, Lefthook) | `references/hooks-and-automation.md` | Setting up pre-commit hooks, commitlint, comparing hook managers |
| Signed commits (GPG, SSH) | `references/hooks-and-automation.md#signed-commits` | Enabling commit signing, CI enforcement of signatures |
| Semantic release config | `references/hooks-and-automation.md#semantic-release-automated-versioning` | Configuring automated single-package releases |
| commitlint setup | `references/hooks-and-automation.md#commitlint-configuration` | Enforcing conventional commit format via hooks |
| Changesets workflow | `references/monorepo-and-versioning.md` | Monorepo versioning, per-package changelogs |
| Monorepo CI strategies | `references/monorepo-and-versioning.md#monorepo-git-strategies` | Workspace-aware CI, Turborepo, paths-filter |
| PR templates & size guide | `references/pr-and-collaboration.md` | Creating PR templates, optimizing review process |
| CODEOWNERS & branch protection | `references/pr-and-collaboration.md#codeowners` | Routing reviews, protecting main branch |
| .gitignore & git commands | `references/pr-and-collaboration.md#gitignore-template` | Setting up ignores, useful daily git commands |

---

## Checklist: Git Workflow Setup

- [ ] Branching strategy documented and agreed upon
- [ ] Branch protection on main (reviews + CI required)
- [ ] Conventional commits enforced (commitlint + husky/lefthook)
- [ ] PR template exists
- [ ] CODEOWNERS file defines reviewers
- [ ] `.gitignore` covers all generated/sensitive files
- [ ] lint-staged runs on pre-commit (via husky or lefthook)
- [ ] Release automation configured (semantic-release or Changesets)
- [ ] CI runs on every PR (lint, test, security)
- [ ] No secrets in git history (gitleaks scan)
- [ ] Signed commits enabled for team (GPG or SSH)
- [ ] Monorepo strategy defined (if applicable): changesets, workspace-aware CI
- [ ] Git hooks manager chosen and configured (Husky or Lefthook)
