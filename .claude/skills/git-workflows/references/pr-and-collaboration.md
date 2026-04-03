# PR Best Practices & Collaboration

---

## PR Size Guide

| Size | Lines Changed | Review Time | Quality |
|---|---|---|---|
| Tiny | <50 | Minutes | Best feedback |
| Small | 50-200 | < 1 hour | Good feedback |
| Medium | 200-400 | 1-2 hours | Adequate |
| Large | 400-1000 | Half day | Diminishing returns |
| Huge | 1000+ | Days | Rubber stamp risk |

**Target: <400 lines changed per PR.**

---

## PR Template

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

---

## CODEOWNERS

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
