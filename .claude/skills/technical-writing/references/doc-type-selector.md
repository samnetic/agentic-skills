# Doc Type Selector (Diataxis)

Choose exactly one type.

| Type | Use When | Output Shape |
|---|---|---|
| Tutorial | Reader is learning from zero | Guided end-to-end lesson |
| How-To | Reader needs to complete a task now | Preconditions + ordered steps + verification |
| Reference | Reader needs exact facts quickly | Structured tables/parameters/errors |
| Explanation | Reader needs conceptual understanding | Context, rationale, trade-offs |

Decision rule:
- Working now -> How-To or Reference
- Learning now -> Tutorial or Explanation
