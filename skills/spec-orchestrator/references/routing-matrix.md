# Routing Matrix

| Request Pattern | Primary Skill | Secondary Skill | Typical Output |
|---|---|---|---|
| "Write a PRD" | `business-analysis` | `technical-writing` | PRD with FR/NFR + metrics |
| "Define system design" | `software-architecture` | `technical-writing` | Architecture design doc + ADR delta |
| "Refactor this long spec" | `technical-writing` | `business-analysis` | Shortened spec with preserved requirements |
| "Need both product and engineering views" | `business-analysis` | `technical-writing` | Primary spec + engineering appendix |
| "Need decision between architectures" | `software-architecture` | `business-analysis` | Option analysis + recommendation memo |

| "Create a Plan-Ready PRD" | `prd-writer` | `business-analysis` | Plan-Ready PRD with FR IDs, dependencies, AFK hints |
| "Turn PRD into plan" | `prd-to-plan` | `software-architecture` | Vertical-slice implementation plan |
| "Create issues from plan" | `plan-to-issues` | `git-workflows` | GitHub issues with AFK/HITL labels |
| "Build this end to end" | `delivery-pipeline` | all pipeline skills | Full feature delivery pipeline |
| "Stress-test this idea" | `grill-session` | — | Stress Test Report with confidence ratings |

Selection rules:
- If request is mainly "what/why", route BA-led.
- If request is mainly "how/system trade-offs", route architecture-led.
- If request is mainly "clarity/structure/length", route writing-led.
- If request is "build/implement/plan/issues", route pipeline-led.
- If request is "grill/challenge/pressure-test", route to `grill-session`.
