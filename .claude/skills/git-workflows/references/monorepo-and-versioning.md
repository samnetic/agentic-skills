# Monorepo Strategies & Versioning

## Table of Contents

- [Changesets (Monorepo Versioning)](#changesets-monorepo-versioning)
  - [Setup](#setup)
  - [Daily Workflow](#daily-workflow)
  - [Changeset File Example](#changeset-file-example)
  - [CI Automation with Changesets](#ci-automation-with-changesets)
  - [Changesets vs semantic-release](#changesets-vs-semantic-release)
- [Monorepo Git Strategies](#monorepo-git-strategies)
  - [Trunk-Based with Feature Flags](#trunk-based-with-feature-flags)
  - [Per-Package Versioning with Changesets](#per-package-versioning-with-changesets)
  - [Workspace-Aware CI (Only Build Changed Packages)](#workspace-aware-ci-only-build-changed-packages)
  - [Monorepo Strategy Decision Table](#monorepo-strategy-decision-table)

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

### Changesets vs semantic-release

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

### Monorepo Strategy Decision Table

| Strategy | When |
|---|---|
| **Trunk-based + flags** | Small team, fast deploys, all packages change together |
| **Changesets** | Multiple packages with independent release cycles |
| **Workspace-aware CI** | Large monorepo where full CI is too slow/expensive |
| **Turborepo/Nx** | Complex dependency graphs, need intelligent caching and task scheduling |
