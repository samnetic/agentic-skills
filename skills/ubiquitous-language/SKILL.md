---
name: ubiquitous-language
description: >-
  Extract and maintain a DDD ubiquitous language glossary from codebase and
  conversations. Identifies domain terms, resolves ambiguities, flags
  modeling smells, and produces a structured glossary organized by bounded
  context. Use when establishing domain terminology, onboarding to a domain,
  or hardening a domain model. Triggers: ubiquitous language, domain glossary,
  DDD terminology, domain model terms, build a glossary, domain language.
license: MIT
metadata:
  author: samnetic
  version: "1.0"
---

# Ubiquitous Language Skill

Extract, organize, and maintain a DDD ubiquitous language glossary from code,
conversations, and domain artifacts. The glossary becomes the single source of
truth for domain terminology across bounded contexts.

## Core Principles

1. **Domain language over code language** — Use the words domain experts use, not
   programmer abstractions. If the business says "shipment" don't call it `Item`.
2. **One canonical term per concept** — Synonyms are ambiguity. Pick one term and
   redirect all others to it.
3. **Ambiguity is a bug** — Every term with two possible meanings must be split
   into two explicit terms or resolved to one.
4. **Glossary is living** — Updated as understanding evolves. A stale glossary is
   worse than no glossary.
5. **Organized by bounded context** — The same word can mean different things in
   different contexts. `Account` in Billing is not `Account` in Identity.
6. **Code must match glossary** — Variable names, class names, API fields, DB
   columns, and documentation must use glossary terms exactly.

## Workflow

### Phase 1: Scan Sources

Gather domain terms from all available sources:

- **Code**: class/type/interface names, method names, database columns, API
  field names, enum values, module/package names
- **Documentation**: READMEs, ADRs, wiki pages, onboarding guides
- **Conversations**: Slack threads, meeting notes, issue descriptions, PR
  discussions (if provided)
- **Domain artifacts**: user stories, acceptance criteria, PRDs, event storming
  outputs

Use `references/term-extraction-patterns.md` for extraction heuristics.

### Phase 2: Extract Terms

For each candidate term, capture:

| Field | Description |
|-------|-------------|
| **Term** | The canonical name (singular, PascalCase for types, snake_case for fields) |
| **Definition** | One sentence a domain expert would agree with |
| **Bounded Context** | Which subdomain owns this term |
| **Aliases** | Synonyms found in code or conversation |
| **Examples** | 1-2 concrete examples showing correct usage |
| **Related Terms** | Links to other glossary entries with relationship type |

### Phase 3: Resolve Ambiguities

For every term that appears with multiple meanings or in multiple contexts:

1. **Split or merge** — Determine if it is truly one concept or two
2. **Context-qualify** — If two contexts legitimately use the same word
   differently, prefix with context: `Billing.Account` vs `Identity.Account`
3. **Flag for domain expert** — If the assistant cannot resolve, mark as
   `AMBIGUOUS — needs domain expert input` with the competing definitions
4. **Document the decision** — Record why a term was split, merged, or kept

Check against `references/modeling-smells.md` for language anti-patterns.

### Phase 4: Organize by Context

Group terms into bounded contexts. For each context:

- List all terms owned by that context
- Identify terms shared across context boundaries (these need explicit mapping)
- Document context relationships: Shared Kernel, Customer-Supplier,
  Conformist, Anti-Corruption Layer
- Flag terms that leak across boundaries without explicit mapping

### Phase 5: Produce Glossary

Generate `docs/ubiquitous-language.md` using the template in
`references/glossary-template.md`. The output includes:

1. **Header** — Project name, date, version, contributors
2. **Context Map** — ASCII or Mermaid diagram of bounded contexts and their
   relationships
3. **Term Tables** — One table per bounded context with all fields from Phase 2
4. **Cross-Context Mappings** — Where the same real-world concept has different
   representations in different contexts
5. **Ambiguity Log** — Unresolved terms needing domain expert input
6. **Code Alignment Report** — Where code names diverge from glossary terms
   (rename candidates)

## Quality Checks

Before finalizing the glossary:

- [ ] Every type/class in the domain layer has a glossary entry
- [ ] No synonyms remain — each concept has exactly one term
- [ ] All ambiguous terms are either resolved or explicitly flagged
- [ ] Cross-context terms have explicit mappings documented
- [ ] Definitions are written in domain language, not implementation language
- [ ] Related terms form a connected graph (no orphan concepts)
- [ ] Code alignment report lists zero unexplained divergences

## When to Update the Glossary

- New feature introduces new domain concepts
- Domain expert corrects a misunderstanding
- Bounded context boundaries shift
- Code review reveals a naming inconsistency
- Onboarding conversation reveals a term that "everyone knows" but isn't documented

## References

- `references/glossary-template.md` — Output format template
- `references/term-extraction-patterns.md` — Code and text extraction heuristics
- `references/modeling-smells.md` — DDD language anti-patterns to detect

## Output Location

```
docs/ubiquitous-language.md
```

If `docs/` does not exist, create it. If a glossary already exists, merge new
terms and flag conflicts rather than overwriting.
