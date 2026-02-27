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

Use git as a communication tool, not just version control. Every commit tells a story.
Every branch has a purpose. Every PR is a conversation.

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

## Branching Strategy Decision

```
Team size and deploy frequency?
├── Solo / small team, deploy daily+
│   └── Trunk-Based Development
│       main ← feature branches (short-lived, <1 day)
│       Deploy from main continuously
│
├── Small-medium team, deploy weekly
│   └── GitHub Flow
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

## Conventional Commits

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Types

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
3. Subject ≤ 72 characters
4. Body wraps at 72 characters
5. Body explains WHY, not WHAT (the diff shows what)
6. Reference issues: `Closes #123`, `Fixes #456`

---

## PR Best Practices

### PR Size Guide

| Size | Lines Changed | Review Time | Quality |
|---|---|---|---|
| Tiny | <50 | Minutes | Best feedback |
| Small | 50-200 | < 1 hour | Good feedback |
| Medium | 200-400 | 1-2 hours | Adequate |
| Large | 400-1000 | Half day | Diminishing returns |
| Huge | 1000+ | Days | Rubber stamp risk |

**Target: <400 lines changed per PR.**

### PR Template

```markdown
<!-- .github/pull_request_template.md -->
## What

Brief description of changes.

## Why

Link to issue/ticket. Explain the motivation.

## How

Key technical decisions and trade-offs.

## Testing

- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing performed
- [ ] Edge cases considered

## Screenshots (if UI changes)

Before | After
-------|------
  img  |  img

## Checklist

- [ ] Self-reviewed the diff
- [ ] No console.log or debug code
- [ ] No hardcoded secrets
- [ ] Types are correct (no `any`)
- [ ] Error handling is appropriate
- [ ] Documentation updated (if needed)
```

### CODEOWNERS

```
# .github/CODEOWNERS
# Default owner for everything
* @team-lead

# Frontend
/src/components/ @frontend-team
/src/styles/ @frontend-team

# Backend
/src/api/ @backend-team
/src/db/ @backend-team @dba-team

# Infrastructure
/terraform/ @devops-team
/.github/workflows/ @devops-team
/Dockerfile @devops-team
/compose.yaml @devops-team

# Security-sensitive files require security review
/src/auth/ @security-team
/src/middleware/auth* @security-team
```

---

## Branch Protection Rules

```yaml
# Recommended settings for main branch:
branch_protection:
  required_reviews: 1                    # At least 1 approval
  dismiss_stale_reviews: true            # Re-review after new pushes
  require_code_owner_reviews: true       # CODEOWNERS must approve
  require_status_checks:
    - ci / lint
    - ci / test
    - ci / security
  require_branches_up_to_date: true      # Must be current with main
  require_linear_history: true           # Squash or rebase only
  require_signed_commits: false          # Nice-to-have, not required
  allow_force_push: false                # Never on main
  allow_deletions: false                 # Never delete main
```

---

## Git Hooks (Husky + lint-staged)

```bash
# Install
npm install -D husky lint-staged
npx husky init
```

```json
// package.json
{
  "lint-staged": {
    "*.{ts,tsx}": ["eslint --fix", "prettier --write"],
    "*.{json,md,yml,yaml}": ["prettier --write"],
    "*.{ts,tsx,js,jsx}": ["vitest related --run"]
  }
}
```

```bash
# .husky/pre-commit
npx lint-staged

# .husky/commit-msg
npx commitlint --edit $1
```

```javascript
// commitlint.config.js
export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'subject-max-length': [2, 'always', 72],
    'body-max-line-length': [2, 'always', 72],
  },
};
```

---

## Lefthook (Modern Alternative to Husky)

Lefthook is a fast, zero-dependency git hooks manager written in Go. It supports parallel execution, glob-based file filtering, and works with any language — no Node.js required.

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
    typecheck:
      run: npx tsc --noEmit

commit-msg:
  commands:
    commitlint:
      run: npx commitlint --edit {1}

pre-push:
  commands:
    test:
      run: npx vitest run
```

```bash
# Install lefthook
npm install -D lefthook    # Or: brew install lefthook
npx lefthook install       # Set up git hooks
```

**Lefthook vs Husky:**

| Feature | Husky | Lefthook |
|---|---|---|
| **Speed** | Node.js startup per hook | Go binary, near-instant |
| **Parallel execution** | Via lint-staged | Built-in `parallel: true` |
| **File filtering** | Via lint-staged | Built-in `glob`, `{staged_files}` |
| **Language agnostic** | Requires Node.js | Works with any language |
| **Config format** | Shell scripts + package.json | Single YAML file |
| **Zero deps** | Needs Node.js runtime | Standalone binary |

**When to use Lefthook:** polyglot repos (Go + TS + Python), teams wanting faster hooks, or projects that want to avoid Node.js dependency for git hooks.

---

## Signed Commits

Signed commits prove that a commit was actually made by the claimed author. Required for high-security environments and verified badges on GitHub.

### GPG Signing

```bash
# Generate a GPG key (if you don't have one)
gpg --full-generate-key        # Choose RSA 4096, set email to match GitHub

# List your keys
gpg --list-secret-keys --keyid-format=long

# Configure git to sign commits
git config --global commit.gpgsign true
git config --global tag.gpgsign true
git config --global user.signingkey YOUR_KEY_ID

# Export public key and add to GitHub (Settings > SSH and GPG keys)
gpg --armor --export YOUR_KEY_ID
```

### SSH Key Signing (Simpler)

```bash
# Use your existing SSH key — no GPG needed
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519.pub
git config --global commit.gpgsign true
git config --global tag.gpgsign true

# Create allowed signers file for local verification
echo "$(git config user.email) $(cat ~/.ssh/id_ed25519.pub)" >> ~/.config/git/allowed_signers
git config --global gpg.ssh.allowedSignersFile ~/.config/git/allowed_signers

# Verify a signed commit
git log --show-signature -1
```

**SSH signing benefits:**
- No GPG installation or key management
- Reuse existing SSH key from GitHub
- Simpler setup — 3 commands vs GPG's multi-step process
- GitHub shows "Verified" badge on commits signed with SSH keys

### Enforce in CI

```yaml
# Branch protection rule: require signed commits
branch_protection:
  require_signed_commits: true     # All commits must be signed

# Verify in CI workflow
steps:
  - uses: actions/checkout@v4
    with:
      fetch-depth: 0
  - name: Verify commit signatures
    run: |
      git log --format='%H %G?' origin/main..HEAD | while read hash status; do
        if [ "$status" != "G" ] && [ "$status" != "E" ]; then
          echo "Unsigned commit: $hash"
          exit 1
        fi
      done
```

---

## Semantic Release (Automated Versioning)

```json
// .releaserc.json
{
  "branches": ["main"],
  "plugins": [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    "@semantic-release/changelog",
    ["@semantic-release/npm", { "npmPublish": false }],
    "@semantic-release/github",
    ["@semantic-release/git", {
      "assets": ["package.json", "CHANGELOG.md"],
      "message": "chore(release): ${nextRelease.version}"
    }]
  ]
}
```

**How it works:**
- `fix:` -> patch bump (1.0.0 -> 1.0.1)
- `feat:` -> minor bump (1.0.0 -> 1.1.0)
- `BREAKING CHANGE:` -> major bump (1.0.0 -> 2.0.0)

---

## Changesets (Monorepo Versioning)

Changesets is an alternative to semantic-release, designed for monorepos. Each PR includes a "changeset" file describing what changed and the semver impact. Versions and changelogs are updated in a single batch.

### Setup

```bash
# Install
npm install -D @changesets/cli
npx changeset init     # Creates .changeset/ directory
```

### Daily Workflow

```bash
# 1. After making changes, create a changeset
npx changeset
# Interactive prompts:
#   Which packages changed? (select from list)
#   Semver bump type? (major/minor/patch)
#   Summary of changes? (goes into CHANGELOG)
# Creates .changeset/<random-name>.md

# 2. Commit the changeset file with your code
git add .changeset/
git commit -m "feat(auth): add OAuth2 login"

# 3. When ready to release (usually automated in CI):
npx changeset version    # Updates package.json versions + CHANGELOGs
npx changeset publish    # Publishes to npm
```

### Changeset File Example

```markdown
<!-- .changeset/brave-dogs-dance.md -->
---
"@myorg/auth": minor
"@myorg/ui": patch
---

Add OAuth2 login support. The auth package gets a new `loginWithOAuth`
method. The UI package adds a Google login button component.
```

### CI Automation with Changesets

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    branches: [main]

permissions:
  contents: write
  pull-requests: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: npm
      - run: npm ci

      # Creates a "Version Packages" PR that batches all changesets
      # When merged, publishes to npm automatically
      - uses: changesets/action@v1
        with:
          publish: npx changeset publish
          version: npx changeset version
          commit: "chore(release): version packages"
          title: "chore(release): version packages"
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

**Changesets vs semantic-release:**

| Feature | semantic-release | Changesets |
|---|---|---|
| **Best for** | Single packages | Monorepos |
| **Versioning** | Automated from commits | Explicit per-PR changeset files |
| **Changelog** | Auto-generated from commits | Written by developer per changeset |
| **Monorepo** | Needs plugins, complex | First-class monorepo support |
| **Developer intent** | Inferred from commit types | Explicitly declared |
| **Release flow** | Immediate on merge | Batched via "Version Packages" PR |

---

## Monorepo Git Strategies

### Trunk-Based with Feature Flags

The simplest monorepo strategy. All packages live on `main`, features are gated behind flags.

```
main ─────●─────●─────●─────●──→
          │     │     │     │
          all packages on one branch
          feature flags gate releases
```

**Rules:**
- Short-lived branches (<1 day)
- Feature flags for incomplete work
- All packages versioned together or independently (with Changesets)
- CI runs for all packages but skips unchanged ones

### Per-Package Versioning with Changesets

Each package in the monorepo has its own version and changelog. Changesets tracks cross-package dependencies automatically.

```
monorepo/
├── packages/
│   ├── auth/          # @myorg/auth v2.1.0
│   ├── ui/            # @myorg/ui v3.0.1
│   ├── api-client/    # @myorg/api-client v1.5.0
│   └── shared/        # @myorg/shared v1.0.3
├── .changeset/
└── package.json
```

```bash
# Changesets automatically bumps dependents
# If @myorg/shared gets a minor bump, packages that depend on it
# get at least a patch bump in the same release
npx changeset version    # Handles cross-package dependency bumps
```

### Workspace-Aware CI (Only Build Changed Packages)

```yaml
# .github/workflows/ci.yml — only test what changed
jobs:
  detect-changes:
    runs-on: ubuntu-latest
    outputs:
      auth: ${{ steps.filter.outputs.auth }}
      ui: ${{ steps.filter.outputs.ui }}
      api: ${{ steps.filter.outputs.api }}
    steps:
      - uses: actions/checkout@v4
      - uses: dorny/paths-filter@v3
        id: filter
        with:
          filters: |
            auth:
              - 'packages/auth/**'
              - 'packages/shared/**'    # Shared deps trigger downstream
            ui:
              - 'packages/ui/**'
              - 'packages/shared/**'
            api:
              - 'packages/api/**'
              - 'packages/shared/**'

  test-auth:
    needs: detect-changes
    if: ${{ needs.detect-changes.outputs.auth == 'true' }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npm run test --workspace=packages/auth

  test-ui:
    needs: detect-changes
    if: ${{ needs.detect-changes.outputs.ui == 'true' }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npm run test --workspace=packages/ui
```

**Alternative: Turborepo for workspace-aware builds:**

```bash
# Turborepo automatically determines what to build based on changes
npx turbo run build test --filter=...[origin/main]
# Only builds/tests packages affected since diverging from main
```

**Monorepo strategy decision:**

| Strategy | When |
|---|---|
| **Trunk-based + flags** | Small team, fast deploys, all packages change together |
| **Changesets** | Multiple packages with independent release cycles |
| **Workspace-aware CI** | Large monorepo where full CI is too slow/expensive |
| **Turborepo/Nx** | Complex dependency graphs, need intelligent caching and task scheduling |

---

## .gitignore Template

```gitignore
# Dependencies
node_modules/
.pnp.*
vendor/
.venv/
__pycache__/

# Build output
dist/
build/
.next/
out/
*.tsbuildinfo

# Environment (NEVER commit secrets)
.env
.env.local
.env.*.local
*.pem
*.key

# IDE
.vscode/settings.json
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Testing
coverage/
.nyc_output/
playwright-report/

# Logs
*.log
npm-debug.log*

# Docker
docker-compose.override.yml
```

---

## Useful Git Commands

```bash
# Undo last commit (keep changes staged)
git reset --soft HEAD~1

# Amend last commit (not yet pushed)
git commit --amend --no-edit

# Interactive rebase (clean up branch before PR)
git rebase -i main              # Squash/reword/reorder commits

# Find which commit introduced a bug
git bisect start
git bisect bad                  # Current commit is broken
git bisect good v1.0.0          # This version worked
# Git checks out middle commit — test and mark good/bad
git bisect good                 # or: git bisect bad
# Repeat until found, then:
git bisect reset

# Stash with name
git stash push -m "WIP: auth refactor"
git stash list                  # See all stashes
git stash pop stash@{0}         # Apply and remove

# See what changed in a file over time
git log -p --follow -- path/to/file

# Cherry-pick a commit from another branch
git cherry-pick abc1234
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
| Manual version bumping | Forgotten, inconsistent | semantic-release or Changesets automation |
| Unsigned commits in prod | No proof of authorship | GPG or SSH commit signing |
| Full CI on every package change | Slow, expensive monorepo CI | Workspace-aware CI with paths-filter or Turborepo |

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
