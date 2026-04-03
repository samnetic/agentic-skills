# Routing Matrix

| Request Pattern | Primary Skill | Secondary Skill | Typical Output |
|---|---|---|---|
| "Write a PRD" | `business-analysis` | `technical-writing` | PRD with FR/NFR + metrics |
| "Define system design" | `software-architecture` | `technical-writing` | Architecture design doc + ADR delta |
| "Refactor this long spec" | `technical-writing` | `business-analysis` | Shortened spec with preserved requirements |
| "Need both product and engineering views" | `business-analysis` | `technical-writing` | Primary spec + engineering appendix |
| "Need decision between architectures" | `software-architecture` | `business-analysis` | Option analysis + recommendation memo |

Selection rules:
- If request is mainly "what/why", route BA-led.
- If request is mainly "how/system trade-offs", route architecture-led.
- If request is mainly "clarity/structure/length", route writing-led.
