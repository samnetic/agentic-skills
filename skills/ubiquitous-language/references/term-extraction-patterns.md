# Term Extraction Patterns

Heuristics and patterns for extracting domain terms from code, conversations, and documentation.

---

## Code Extraction Patterns

### Model Layer (Highest Signal)

| Pattern | What to extract | Example |
|---|---|---|
| Class/interface names in domain model | Entity and value object terms | `class Order`, `interface PaymentMethod` |
| Enum names and values | Domain states and categories | `enum OrderStatus { PENDING, CONFIRMED, SHIPPED }` |
| Aggregate root names | Core domain concepts | `class ShoppingCart extends AggregateRoot` |
| Method names on entities | Domain actions and behaviors | `order.confirm()`, `cart.addItem()` |
| Constructor/factory parameters | Required attributes of a concept | `new Order({ customerId, lineItems, shippingAddress })` |
| Type aliases and branded types | Domain-specific value types | `type OrderId = string & { __brand: 'OrderId' }` |

### Service Layer (Medium Signal)

| Pattern | What to extract | Example |
|---|---|---|
| Service class names | Domain operations and processes | `class PaymentProcessingService` |
| Method names on services | Use cases and workflows | `processRefund()`, `calculateShipping()` |
| Command/query object names | User intents | `PlaceOrderCommand`, `GetOrderStatusQuery` |
| Event names | Domain state transitions | `OrderPlacedEvent`, `PaymentFailedEvent` |
| Error/exception names | Domain failure modes | `InsufficientStockError`, `InvalidCouponError` |

### Database Schema (Medium Signal)

| Pattern | What to extract | Example |
|---|---|---|
| Table names | Persisted entities | `orders`, `customers`, `products` |
| Column names | Entity attributes | `shipping_address`, `discount_amount` |
| Foreign key relationships | Entity relationships | `order_id` in `order_lines` table |
| Enum columns | Domain categories | `status VARCHAR CHECK (status IN ('active', 'suspended'))` |
| Junction tables | Many-to-many relationships | `product_categories` linking products and categories |

### API Layer (Lower Signal -- may use simplified terms)

| Pattern | What to extract | Example |
|---|---|---|
| Endpoint nouns | Public-facing domain concepts | `GET /api/orders`, `POST /api/subscriptions` |
| Request/response field names | Attributes exposed to clients | `{ "orderId", "lineItems", "totalAmount" }` |
| Query parameter names | Filtering and search concepts | `?status=active&category=premium` |

---

## Conversation Extraction Patterns

### High-Signal Phrases

| Phrase pattern | What it reveals | Action |
|---|---|---|
| "When a {noun} is {verb}ed..." | Entity + domain event | Add noun as entity, verb as event |
| "A {noun} can only {verb} if..." | Business rule / invariant | Add noun, document the rule |
| "We call that a {noun}" | Explicit domain term | Add immediately -- domain expert is naming it |
| "That's not the same as a {noun}" | Disambiguation | Record both terms, note the difference |
| "Actually, we stopped calling it {X}, now it's {Y}" | Term evolution | Deprecate X, add Y |
| "It depends on whether it's a {X} or a {Y}" | Specialization / subtype | Add both, document the distinction |
| "Every {X} has exactly one {Y}" | Relationship constraint | Document cardinality |
| "A {X} can have many {Y}s" | One-to-many relationship | Document relationship |
| "{X} and {Y} are basically the same thing" | Synonym candidate | Pick canonical term, add alias |

### Red Flags in Conversations

| Signal | What it means | Action |
|---|---|---|
| Different people use different words for the same thing | Unresolved synonym | Stop and align on one term |
| Someone corrects another's terminology | The corrector likely has the right term | Record the correction |
| Long explanation needed for a simple concept | Missing abstraction | The concept needs a name |
| "It's like a {X} but not exactly" | Missing specialization | Create a new term for the specific concept |
| Hand-waving or "you know what I mean" | Implicit knowledge | Make it explicit -- name it |

---

## Documentation Extraction Patterns

### Source Priority

| Source | Signal strength | Watch out for |
|---|---|---|
| Domain expert presentations/slides | Very high | Informal language that may not match code |
| Business process documents | High | Outdated terms from previous system |
| PRDs and user stories | High | Product language may differ from domain language |
| API documentation | Medium | Simplified or developer-centric terms |
| README and onboarding docs | Medium | Often stale or oversimplified |
| Comments in code | Low | Often explain "how" not "what" in domain terms |
| Commit messages | Low | Too terse, but useful for term archaeology |

### Extraction Checklist for Documents

- [ ] Highlight every noun that refers to a business concept
- [ ] Highlight every verb that represents a domain action
- [ ] Mark adjective-noun pairs that distinguish subtypes (e.g., "premium customer")
- [ ] Note any term that is defined or explained inline (suggests it is non-obvious)
- [ ] Flag terms used inconsistently across sections
- [ ] Record the exact phrasing -- do not normalize yet

---

## Term Validation Checklist

After extracting a candidate term, validate it:

| Check | Question | If no |
|---|---|---|
| Domain relevance | Would a domain expert recognize this term? | May be a technical artifact -- skip or flag |
| Specificity | Does the term mean something precise? | Too vague -- refine or split |
| Uniqueness | Is there already a term for this concept? | Synonym -- pick canonical form |
| Stability | Has this term been used consistently for >1 month? | May be temporary jargon -- flag for review |
| Actionability | Does knowing this term help you model the domain? | May be trivia -- skip |
