---
name: schema-markup
description: >-
  Structured data design and validation for search visibility. Use when adding,
  fixing, or auditing JSON-LD/schema.org markup for product, article, FAQ,
  breadcrumb, organization, or software pages. Triggers: schema markup,
  structured data, JSON-LD, rich results, schema.org, search snippets,
  structured data validation.
---

# Schema Markup

Implement structured data that is valid, relevant, and maintainable.

## Workflow

1. Map page types to appropriate schema types.
2. Draft JSON-LD payloads with required properties.
3. Validate against schema and rich-result expectations.
4. Deploy and verify rendered output.
5. Monitor errors/warnings and iterate.

## Required Inputs

- Page inventory and content models
- CMS/template constraints
- Search goals (rich results, knowledge graph clarity)
- Validation tools available

## Progressive Disclosure Map

- Schema patterns and examples: [references/schema-examples.md](references/schema-examples.md)
- Validation checklist: [references/schema-validation-checklist.md](references/schema-validation-checklist.md)

## Execution Protocol

### 1) Type Mapping

- Choose schema types that match real page intent.
- Avoid over-marking unrelated entities.

### 2) Payload Authoring

- Include required and recommended fields.
- Keep data consistent with visible page content.

### 3) Validation

- Validate syntax and type constraints.
- Validate rendered output, not static fetch only.
- Re-check after template/CMS updates.

## Output Contract

Deliver:

1. JSON-LD payload spec per page type
2. Validation report with pass/fail status
3. Rollout and monitoring checklist

## Quality Gates

- Markup matches visible user-facing content.
- Required fields are complete and current.
- Rendered validation is confirmed.
- Ownership exists for ongoing maintenance.

## Anti-Patterns

- Adding schema types solely to “hack” ranking.
- Hardcoding stale values in templates.
- Declaring success without rendered validation.

