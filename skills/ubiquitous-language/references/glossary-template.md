# Glossary Template

Standard output format for a ubiquitous language glossary. Copy this template and fill in for each bounded context.

---

## Document Header

```markdown
# Ubiquitous Language Glossary

**Project:** {project name}
**Last updated:** {YYYY-MM-DD}
**Reviewed by:** {domain expert name(s)}
**Status:** {draft | reviewed | approved}

---

## Table of Contents

1. [Bounded Context: {Name}](#bounded-context-name)
2. [Bounded Context: {Name}](#bounded-context-name)
3. [Cross-Context Terms](#cross-context-terms)
4. [Deprecated Terms](#deprecated-terms)
5. [Unresolved Ambiguities](#unresolved-ambiguities)
```

---

## Bounded Context Section

```markdown
## Bounded Context: {Name}

**Purpose:** {1-2 sentences describing what this context is responsible for}
**Owner:** {team or person}
**Upstream contexts:** {contexts this one depends on}
**Downstream contexts:** {contexts that depend on this one}

### Terms

| Term | Definition | Aliases | Code Name | Related Terms |
|------|-----------|---------|-----------|---------------|
| {PascalCase} | {Plain-language definition a domain expert would approve} | {Synonyms that map to this term} | {Exact class/type name in code} | {Other terms this relates to} |
| Order | A customer's request to purchase one or more products | Purchase Request | `Order` | OrderLine, Customer, Product |
| OrderLine | A single product and quantity within an Order | Line Item | `OrderLineItem` | Order, Product, Price |

### Entities

| Entity | Identity | Lifecycle |
|--------|---------|-----------|
| {Name} | {What makes it unique -- e.g., "OrderId (UUIDv7)"} | {Created when -> transitions -> terminated when} |
| Order | OrderId (UUIDv7) | Created on checkout -> Confirmed -> Fulfilled -> Closed |

### Value Objects

| Value Object | Definition | Immutability Rule |
|-------------|-----------|-------------------|
| {Name} | {What it represents} | {When/why a new instance is created vs modified} |
| Money | An amount with a currency code | Always create new -- never mutate amount or currency |

### Domain Events

| Event | Emitted When | Consumed By |
|-------|-------------|-------------|
| {PastTenseName} | {Trigger condition} | {Bounded contexts or services that react} |
| OrderPlaced | Customer completes checkout | Fulfillment, Billing, Notification |

### Commands

| Command | Intent | Preconditions |
|---------|--------|---------------|
| {ImperativeName} | {What the actor wants to achieve} | {What must be true before this can execute} |
| PlaceOrder | Customer wants to purchase items in cart | Cart is non-empty, customer is authenticated, payment method valid |
```

---

## Cross-Context Terms

```markdown
## Cross-Context Terms

Terms that appear in multiple bounded contexts with DIFFERENT meanings:

| Term | Context A: {Name} | Context B: {Name} | Resolution |
|------|-------------------|-------------------|------------|
| Account | Sales: a company we sell to | Billing: a ledger of charges and payments | Use "Customer Account" in Sales, "Billing Account" in Billing |
| Product | Catalog: a listing with description and images | Inventory: a SKU with stock levels | Use "Product Listing" in Catalog, "Inventory Item" in Inventory |
```

---

## Deprecated Terms

```markdown
## Deprecated Terms

Terms that were once part of the ubiquitous language but have been removed or replaced:

| Deprecated Term | Replaced By | Reason | Deprecated Date |
|----------------|------------|--------|-----------------|
| {OldTerm} | {NewTerm or "removed"} | {Why the change was made} | {YYYY-MM-DD} |
| Client | Customer | Standardized on "Customer" per domain expert preference | 2025-03-15 |
```

---

## Unresolved Ambiguities

```markdown
## Unresolved Ambiguities

Items that need domain expert review before the glossary is finalized:

| Term | Issue | Options | Status |
|------|-------|---------|--------|
| {Term} | {Description of the ambiguity} | {A: ..., B: ...} | {pending review | scheduled for {date}} |
| Subscription | Used for both recurring billing and notification preferences | A: Split into "BillingSubscription" and "NotificationSubscription" B: Keep as-is with qualifier | Pending review with product team |
```

---

## Relationship Notation

Use these relationship types when documenting term connections:

| Notation | Meaning | Example |
|----------|---------|---------|
| `contains` | Parent has child as part of its structure | Order contains OrderLine |
| `references` | Term points to another term without ownership | OrderLine references Product |
| `becomes` | Term transitions into another over time | Lead becomes Customer |
| `specializes` | Term is a more specific version of another | PremiumCustomer specializes Customer |
| `context-maps-to` | Same real-world concept, different bounded context term | Sales.Customer maps to Billing.Account |
