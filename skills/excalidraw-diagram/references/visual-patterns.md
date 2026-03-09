# Visual Patterns

Use structure as meaning. Choose the minimum pattern set that teaches the concept clearly.

## Pattern Catalog

| Pattern | Best For | Quick Shape |
|---|---|---|
| Fan-out | One-to-many distribution | center -> many |
| Convergence | Many-to-one aggregation | many -> center |
| Timeline spine | Ordered sequences and events | line + marker dots |
| Tree | Hierarchy and taxonomy | trunk + branches |
| Cycle | Feedback loops and iteration | ring/loop arrows |
| Assembly line | Input -> transform -> output | before -> process -> after |
| Side-by-side | Comparisons and trade-offs | parallel columns |
| Layered stack | System layers and boundaries | horizontal bands |
| Swimlanes | Responsibility split by actor/team | vertical columns |

## Selection Heuristics

- Causality and ordered events: timeline or assembly line.
- Ownership/responsibility differences: swimlanes.
- Conceptual hierarchy: tree.
- Feedback and repeated optimization: cycle.
- Distribution hub: fan-out.
- Consolidation/funnel: convergence.

## Container Discipline

- Default to free-floating text for labels and annotations.
- Use containers only when shape conveys meaning.
- Timeline/tree diagrams should rely on `line` + `text` more than box stacks.

## Multi-Zoom Rule (Comprehensive Diagrams)

Include all three levels:

1. Summary flow: one glance overview.
2. Section boundaries: grouped phases or domains.
3. Detail evidence: concrete snippets and payloads.

## Evidence Artifacts

For technical diagrams, include at least one of:

- real code snippet
- actual JSON payload
- real event sequence names
- realistic UI/result mockup
- concrete input/output examples

Avoid placeholder text like `Sample Data` when exact structures are available.

