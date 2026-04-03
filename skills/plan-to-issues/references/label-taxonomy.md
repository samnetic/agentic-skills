# Label Taxonomy

Standardized labels for pipeline-generated issues. Apply consistently for filtering and automation.

## Required Labels (every issue gets these)

### Phase Labels

| Label | Color | Description |
|---|---|---|
| `phase:0` | `#e1f5fe` | Tracer bullet phase |
| `phase:1` | `#fff9c4` | Feature phase 1 |
| `phase:2` | `#ffe0b2` | Feature phase 2 |
| `phase:3` | `#f8bbd0` | Feature phase 3 |
| `phase:N` | — | Continue pattern for additional phases |

### Classification Labels

| Label | Color | Description |
|---|---|---|
| `agent:afk` | `#c8e6c9` | Can be completed autonomously by an agent |
| `agent:hitl` | `#ffcdd2` | Requires human judgment or review |
| `agent:afk-review` | `#fff9c4` | Agent can implement, but PR needs careful human review |

### Type Labels

| Label | Color | Description |
|---|---|---|
| `type:feature` | `#c5cae9` | New functionality |
| `type:refactor` | `#d1c4e9` | Code restructuring without behavior change |
| `type:infra` | `#b0bec5` | Infrastructure, CI/CD, deployment |
| `type:test` | `#dcedc8` | Test-only changes |
| `type:docs` | `#f0f4c3` | Documentation only |

## Optional Labels

### Complexity Labels

| Label | Color | Description |
|---|---|---|
| `effort:s` | `#e8f5e9` | Small (< 1 hour) |
| `effort:m` | `#fff3e0` | Medium (1-4 hours) |
| `effort:l` | `#fbe9e7` | Large (4-8 hours) |
| `effort:xl` | `#ffebee` | Extra large (> 8 hours — consider splitting) |

### Domain Labels (apply based on codebase)

| Label | Color | Description |
|---|---|---|
| `domain:db` | `#e8eaf6` | Database and migrations |
| `domain:api` | `#e0f7fa` | API endpoints |
| `domain:ui` | `#fce4ec` | Frontend and UI |
| `domain:auth` | `#fff8e1` | Authentication and authorization |
| `domain:payments` | `#efebe9` | Payment processing |

### Status Labels

| Label | Color | Description |
|---|---|---|
| `status:ready` | `#c8e6c9` | No blockers, can be started |
| `status:blocked` | `#ffcdd2` | Waiting on dependency |
| `status:in-progress` | `#bbdefb` | Currently being worked on |
| `status:review` | `#fff9c4` | PR submitted, awaiting review |

## Label Creation Script

Before creating issues, ensure all required labels exist in the repo. This script is idempotent — safe to run multiple times.

```bash
# Phase labels
gh label create "phase:0" --color "e1f5fe" --description "Tracer bullet phase" --force
gh label create "phase:1" --color "fff9c4" --description "Feature phase 1" --force
gh label create "phase:2" --color "ffe0b2" --description "Feature phase 2" --force
gh label create "phase:3" --color "f8bbd0" --description "Feature phase 3" --force

# Classification labels
gh label create "agent:afk" --color "c8e6c9" --description "Can be completed autonomously" --force
gh label create "agent:hitl" --color "ffcdd2" --description "Requires human judgment" --force
gh label create "agent:afk-review" --color "fff9c4" --description "Agent implements, human reviews" --force

# Type labels
gh label create "type:feature" --color "c5cae9" --description "New functionality" --force
gh label create "type:refactor" --color "d1c4e9" --description "Code restructuring" --force
gh label create "type:infra" --color "b0bec5" --description "Infrastructure and CI/CD" --force
gh label create "type:test" --color "dcedc8" --description "Test-only changes" --force
gh label create "type:docs" --color "f0f4c3" --description "Documentation only" --force

# Effort labels
gh label create "effort:s" --color "e8f5e9" --description "Small: < 1 hour" --force
gh label create "effort:m" --color "fff3e0" --description "Medium: 1-4 hours" --force
gh label create "effort:l" --color "fbe9e7" --description "Large: 4-8 hours" --force
gh label create "effort:xl" --color "ffebee" --description "Extra large: > 8 hours" --force

# Domain labels
gh label create "domain:db" --color "e8eaf6" --description "Database and migrations" --force
gh label create "domain:api" --color "e0f7fa" --description "API endpoints" --force
gh label create "domain:ui" --color "fce4ec" --description "Frontend and UI" --force
gh label create "domain:auth" --color "fff8e1" --description "Authentication and authorization" --force
gh label create "domain:payments" --color "efebe9" --description "Payment processing" --force

# Status labels
gh label create "status:ready" --color "c8e6c9" --description "No blockers, can be started" --force
gh label create "status:blocked" --color "ffcdd2" --description "Waiting on dependency" --force
gh label create "status:in-progress" --color "bbdefb" --description "Currently being worked on" --force
gh label create "status:review" --color "fff9c4" --description "PR submitted, awaiting review" --force
```

## Filtering Examples

```bash
# Find all AFK issues ready to assign to agents
gh issue list --label "agent:afk" --label "status:ready"

# Find all Phase 0 issues (tracer bullet)
gh issue list --label "phase:0"

# Find blocked issues that need dependency resolution
gh issue list --label "status:blocked"

# Find HITL issues needing human attention
gh issue list --label "agent:hitl"

# Find large issues that might need splitting
gh issue list --label "effort:xl"

# Find all database-related issues
gh issue list --label "domain:db"

# Find AFK issues in Phase 1 ready to start
gh issue list --label "agent:afk" --label "phase:1" --label "status:ready"

# Count issues by classification
gh issue list --label "agent:afk" --state open --json number --jq length
gh issue list --label "agent:hitl" --state open --json number --jq length
```

## Label Application Rules

1. **Minimum required labels per issue:** phase + classification + type (3 labels)
2. **Status label:** always apply `status:ready` or `status:blocked` at creation time
3. **Effort label:** apply when the plan includes effort estimates; omit if unknown
4. **Domain labels:** apply all that are relevant (an issue can have multiple domains)
5. **Never invent ad-hoc labels** — use only labels from this taxonomy. If a new category is needed, add it here first.
