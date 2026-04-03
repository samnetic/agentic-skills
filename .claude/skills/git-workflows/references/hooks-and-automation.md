# Hooks, Signing & Release Automation

## Table of Contents

- [Git Hooks with Husky + lint-staged](#git-hooks-with-husky--lint-staged)
- [Lefthook (Modern Alternative)](#lefthook-modern-alternative)
- [Husky vs Lefthook Comparison](#husky-vs-lefthook-comparison)
- [Signed Commits](#signed-commits)
  - [GPG Signing](#gpg-signing)
  - [SSH Key Signing](#ssh-key-signing)
  - [Enforce in CI](#enforce-in-ci)
- [Semantic Release (Automated Versioning)](#semantic-release-automated-versioning)
- [commitlint Configuration](#commitlint-configuration)

---

## Git Hooks with Husky + lint-staged

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

---

## Lefthook (Modern Alternative)

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

---

## Husky vs Lefthook Comparison

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

### SSH Key Signing

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

## commitlint Configuration

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
