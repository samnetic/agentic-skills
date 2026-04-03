# Modeling Smells

Common DDD ubiquitous language anti-patterns with detection heuristics and remediation strategies.

---

## Language Smells

### 1. Synonym Soup

**Smell:** Multiple words used interchangeably for the same domain concept.

**Detection:**
- Code has `Client`, `Customer`, and `User` classes that represent the same entity
- Conversations switch between terms without correction
- API uses "account" while UI uses "profile" for the same thing

**Impact:** Developers build separate models for what should be one concept. Integration bugs emerge when "client" data does not sync with "customer" data.

**Fix:** Convene domain experts and pick ONE canonical term. Deprecate all others. Rename in code, database, API, and UI. Add aliases to the glossary for searchability.

---

### 2. Homonym Collision

**Smell:** One word means different things in different parts of the system.

**Detection:**
- `Account` in billing means "ledger" but in auth means "user profile"
- `Order` in sales means "purchase" but in fulfillment means "shipment instruction"
- Arguments in meetings where both sides are "right" about what a term means

**Impact:** Code in one context breaks assumptions of another. Data flows between contexts corrupt meaning.

**Fix:** Qualify with context: `BillingAccount` vs `UserAccount`. Or use bounded context boundaries -- `Account` means different things in different contexts, and that is fine as long as context boundaries are explicit.

---

### 3. Missing Abstraction

**Smell:** A domain concept exists in behavior but has no name.

**Detection:**
- Long method names trying to describe a concept: `calculateDiscountForLoyalCustomerOnFirstPurchaseOfMonth()`
- Comments explaining "this is the thing that..." without naming it
- Magic strings or numbers representing unnamed states
- Conditional logic that checks multiple flags to determine a concept

**Impact:** Developers cannot talk about the concept. Logic is duplicated because there is no reusable abstraction. New team members cannot discover it.

**Fix:** Name it. Create a class, type, or at minimum a glossary entry. If the domain expert has a word for it, use that word. If not, propose one and validate.

---

### 4. Generic Naming

**Smell:** Terms like "Entity", "Item", "Data", "Info", "Record", "Object", "Thing" used as domain model names.

**Detection:**
- `class DataItem`, `interface RecordInfo`, `type EntityObject`
- Table named `items` with no qualifying context
- Variables named `data`, `info`, `record`, `obj` in domain logic

**Impact:** Names carry no domain meaning. New developers learn nothing from reading the code. Refactoring is impossible because you cannot search for a generic name without thousands of false positives.

**Fix:** Replace with the specific domain term: `DataItem` becomes `Invoice`, `RecordInfo` becomes `PatientHistory`. If you cannot name it specifically, you do not understand the domain well enough -- go back to step 1.

---

### 5. Technical Leakage

**Smell:** Technical implementation terms used where domain terms belong.

**Detection:**
- Domain model has `OrderDTO`, `CustomerRepository`, `PaymentHandler`
- Domain events named `DatabaseUpdatedEvent`, `CacheInvalidatedEvent`
- Business logic references `rows`, `records`, `documents` instead of domain concepts

**Impact:** The domain model becomes coupled to infrastructure. Changing a database to an API breaks domain language. Domain experts cannot read the code.

**Fix:** Separate domain language from technical language. The domain model says `Order`, `Customer`, `Payment`. Infrastructure adapters can use `OrderRow`, `CustomerDocument` internally but never expose those terms to the domain layer.

---

### 6. Verb Blindness

**Smell:** Only nouns are modeled. Domain actions and processes have no names.

**Detection:**
- No command or event classes -- only CRUD operations (`create`, `update`, `delete`)
- Service methods named `processOrder()` or `handlePayment()` -- "process" and "handle" are non-domain verbs
- No domain events -- state changes happen silently

**Impact:** Business processes are invisible in the code. The "what happens when" knowledge lives only in developer heads. Workflows cannot be discussed with domain experts.

**Fix:** Name every significant domain action: `PlaceOrder`, `ConfirmShipment`, `ApplyDiscount`. Name every state transition as a past-tense event: `OrderPlaced`, `ShipmentConfirmed`, `DiscountApplied`.

---

### 7. Primitive Obsession in Domain Terms

**Smell:** Domain concepts represented as raw primitives instead of named types.

**Detection:**
- `orderId: string` instead of `orderId: OrderId`
- `amount: number` instead of `amount: Money`
- `email: string` passed through 10 functions without ever being validated or named
- Business rules checking `if (status === 'active')` with string literals

**Impact:** No type safety for domain concepts. Easy to pass a `customerId` where an `orderId` is expected. Validation logic scattered across the codebase.

**Fix:** Create value objects or branded types for every domain concept that has constraints, formatting, or identity: `OrderId`, `Money`, `EmailAddress`, `OrderStatus`.

---

### 8. Temporal Blindness

**Smell:** Time-dependent domain concepts modeled without temporal awareness.

**Detection:**
- `price: number` with no indication of when that price was valid
- `status` field with no history of transitions
- "Current" assumed everywhere -- no way to ask "what was the state on date X?"
- Audit requirements impossible to meet with current model

**Impact:** Historical queries impossible. Debugging time-sensitive bugs requires log archaeology. Compliance and audit fail.

**Fix:** Model temporal concepts explicitly: `PriceAtTime`, `StatusTransition { from, to, at, by }`. Decide for each concept: do we need point-in-time queries? If yes, model time as a first-class attribute.

---

### 9. Boundary Erosion

**Smell:** Terms from one bounded context leak into another without translation.

**Detection:**
- Fulfillment service imports `SalesOrder` directly instead of having its own `FulfillmentOrder`
- Shared database tables used by multiple contexts
- One context's domain events contain fields only relevant to another context
- No anti-corruption layer or translation mapping between contexts

**Impact:** Contexts become coupled. Changes in one context break another. The "ubiquitous" language becomes a "universal" language (which DDD explicitly warns against).

**Fix:** Define context maps. Create translation layers at boundaries. Each context owns its own model and translates incoming concepts into its own language.

---

## Detection Checklist

Run this checklist against any domain model:

- [ ] Every class in the domain layer has a name a domain expert would recognize
- [ ] No synonyms exist -- each concept has exactly one name
- [ ] Homonyms are resolved with context qualifiers
- [ ] No classes named with generic terms (Entity, Item, Data, Info, Record)
- [ ] Domain actions are named (not just CRUD verbs)
- [ ] Domain events exist for significant state transitions
- [ ] Value objects replace primitives for domain concepts with constraints
- [ ] Bounded context boundaries are explicit
- [ ] No cross-context term leakage without a translation layer
- [ ] Temporal concepts are modeled when time matters to the business
