---
name: code-simplification
description: >-
  Code simplification, refactoring, and clean code expertise. Use when reducing code
  complexity, applying SOLID principles, extracting functions or classes, removing dead
  code, simplifying conditional logic, reducing cyclomatic complexity, applying design
  patterns appropriately, performing refactoring (rename, extract, inline, move),
  simplifying error handling, reducing nesting depth, eliminating code duplication
  with appropriate abstractions, identifying over-engineering, applying YAGNI principle,
  reducing cognitive load, or reviewing code for unnecessary complexity.
  Triggers: simplify, refactor, clean code, complexity, SOLID, YAGNI, DRY, KISS,
  dead code, code smell, cyclomatic complexity, extract function, inline, nesting,
  over-engineering, abstraction, design pattern, single responsibility, dependency
  injection, clean architecture, technical debt, readability.
---

# Code Simplification Skill

The best code is the code you don't write. The second best is code that's so simple
it obviously has no bugs, rather than code so complex it has no obvious bugs.

---

## Core Principles

| Principle | Meaning |
|---|---|
| **KISS** | Keep It Simple. The simplest solution that works is the best solution |
| **YAGNI** | You Aren't Gonna Need It. Don't build for hypothetical futures |
| **Rule of Three** | Duplicate once. Abstract on the third occurrence |
| **Reduce cognitive load** | Reader should understand any function in <30 seconds |
| **Delete > Refactor > Write** | Removing code is the best improvement |
| **Boring code is good code** | Clever code is a liability |

---

## Workflow: Simplification

```
1. IDENTIFY  → What's complex? (metrics, code smells, gut feel)
2. QUESTION  → Is this complexity necessary? Can we delete it?
3. PLAN      → What's the minimal change to reduce complexity?
4. REFACTOR  → Apply one refactoring at a time, tests green after each
5. VERIFY    → Is it actually simpler? (fewer lines, less nesting, clearer names)
```

---

## Decision Trees

### Should I Refactor This Code?

```
Is the code actively causing bugs or blocking a feature?
├─ YES → Refactor now (it's blocking value delivery)
└─ NO
   ├─ Will you modify this code in the current task?
   │  ├─ YES → Apply Boy Scout Rule (leave it better than you found it)
   │  └─ NO → Don't touch it (YAGNI — refactoring stable code adds risk)
   └─ Is test coverage sufficient to refactor safely?
      ├─ YES → Refactor in a separate PR (don't mix with feature work)
      └─ NO → Write characterization tests first, then refactor
```

### Which Refactoring Pattern?

```
What's the code smell?
├─ Long function (>30 lines) → Extract Method
├─ Deep nesting (>3 levels) → Early Return / Guard Clauses
├─ Switch on type → Replace Conditional with Polymorphism
├─ Duplicated logic (3+ copies) → Extract and parameterize
├─ God class (>300 lines) → Extract Class by responsibility
├─ Feature envy (method uses another object's data) → Move Method
├─ Primitive obsession (raw strings for IDs, emails) → Value Object / Branded Type
└─ Shotgun surgery (one change touches 5+ files) → Inline / consolidate
```

---

## Code Smells → Refactoring

| Code Smell | Sign | Refactoring |
|---|---|---|
| **Long function** (>30 lines) | Scrolling, multiple responsibilities | Extract functions with descriptive names |
| **Deep nesting** (>3 levels) | Arrow code, complex conditions | Early returns, guard clauses |
| **Primitive obsession** | Passing 5 strings that belong together | Create a value object / type |
| **Long parameter list** (>3 params) | Hard to call, easy to mix up | Options object |
| **Feature envy** | Method uses another object's data more than its own | Move method to that object |
| **Dead code** | Unreachable, commented-out, unused | Delete it. Git has history |
| **Magic numbers** | `if (status === 3)` | Named constant: `if (status === OrderStatus.SHIPPED)` |
| **Boolean parameters** | `createUser(data, true, false)` — what do they mean? | Options object or separate functions |
| **Shotgun surgery** | Change one feature = edit 10 files | Consolidate related code into one module |
| **God class/module** | 500+ lines, does everything | Extract focused modules |

---

## Refactoring Patterns

### 1. Replace Nested Conditionals with Guard Clauses

```typescript
// BEFORE — deep nesting
function processOrder(order: Order): Result {
  if (order) {
    if (order.items.length > 0) {
      if (order.status === 'pending') {
        if (order.payment) {
          // ... actual logic buried 4 levels deep
          return { success: true };
        } else {
          return { error: 'No payment' };
        }
      } else {
        return { error: 'Not pending' };
      }
    } else {
      return { error: 'No items' };
    }
  } else {
    return { error: 'No order' };
  }
}

// AFTER — guard clauses (flat, readable)
function processOrder(order: Order): Result {
  if (!order) return { error: 'No order' };
  if (order.items.length === 0) return { error: 'No items' };
  if (order.status !== 'pending') return { error: 'Not pending' };
  if (!order.payment) return { error: 'No payment' };

  // Actual logic at the top level — clear path
  return { success: true };
}
```

### 2. Extract Function by Intent

```typescript
// BEFORE — one function doing everything
function handleCheckout(cart: Cart, user: User) {
  // 20 lines validating cart
  // 15 lines calculating total with discounts
  // 10 lines processing payment
  // 15 lines sending confirmation email
  // 10 lines updating inventory
}

// AFTER — each function has one job, named by what it DOES
function handleCheckout(cart: Cart, user: User) {
  validateCart(cart);
  const total = calculateTotal(cart, user.discounts);
  const payment = processPayment(user.paymentMethod, total);
  sendConfirmation(user.email, payment);
  updateInventory(cart.items);
}
```

### 3. Replace Boolean Parameters with Named Options

```typescript
// BEFORE — what do these booleans mean?
createUser(data, true, false, true);

// AFTER — self-documenting
createUser(data, {
  sendWelcomeEmail: true,
  requireEmailVerification: false,
  isAdmin: true,
});
```

### 4. Replace Switch with Map

```typescript
// BEFORE — growing switch statement
function getStatusLabel(status: string): string {
  switch (status) {
    case 'pending': return 'Pending Review';
    case 'approved': return 'Approved';
    case 'rejected': return 'Rejected';
    case 'cancelled': return 'Cancelled';
    default: return 'Unknown';
  }
}

// AFTER — data-driven
const STATUS_LABELS: Record<string, string> = {
  pending: 'Pending Review',
  approved: 'Approved',
  rejected: 'Rejected',
  cancelled: 'Cancelled',
} as const;

function getStatusLabel(status: string): string {
  return STATUS_LABELS[status] ?? 'Unknown';
}
```

### 5. Simplify Complex Conditions

```typescript
// BEFORE — what does this condition mean?
if (user.age >= 18 && user.email && user.verified && !user.banned && user.subscription !== 'expired') {
  // ...
}

// AFTER — named condition
const canAccessContent = isEligibleUser(user);

function isEligibleUser(user: User): boolean {
  const isAdult = user.age >= 18;
  const hasVerifiedEmail = Boolean(user.email) && user.verified;
  const isInGoodStanding = !user.banned && user.subscription !== 'expired';
  return isAdult && hasVerifiedEmail && isInGoodStanding;
}
```

### 6. Remove Dead Code

```typescript
// DELETE all of these:
// - Commented-out code (git has history)
// - Unused imports
// - Unused variables and functions
// - Feature flags for features launched 6+ months ago
// - Deprecated API endpoints nobody calls
// - TODO comments without linked issues

// KEEP:
// - Code that's used in production
// - Code that tests reference
// - Config for different environments
```

### 7. Replace Conditional with Polymorphism

The most important refactoring for reducing complex branching logic. When you see a switch/if chain that operates on a "type" field, replace it with a strategy map or polymorphic dispatch.

```typescript
// BEFORE: switch on type — every new type means editing this function
function getPrice(item: Item): number {
  switch (item.type) {
    case 'book': return item.basePrice * 0.9;
    case 'electronics': return item.basePrice * 1.15;
    case 'food': return item.basePrice;
  }
}

function getShippingCost(item: Item): number {
  switch (item.type) {
    case 'book': return 2.99;
    case 'electronics': return 9.99;
    case 'food': return 14.99; // refrigerated
  }
}

// Problem: Adding a new type means editing EVERY function that switches on type.
// This violates Open/Closed principle and causes shotgun surgery.

// AFTER: polymorphism via strategy map
type ItemType = 'book' | 'electronics' | 'food';

interface PricingStrategy {
  getPrice(basePrice: number): number;
  getShippingCost(): number;
}

const pricingStrategies: Record<ItemType, PricingStrategy> = {
  book: {
    getPrice: (base) => base * 0.9,
    getShippingCost: () => 2.99,
  },
  electronics: {
    getPrice: (base) => base * 1.15,
    getShippingCost: () => 9.99,
  },
  food: {
    getPrice: (base) => base,
    getShippingCost: () => 14.99,
  },
};

// Adding a new type = adding one object. No existing code changes.
function getPrice(item: Item): number {
  return pricingStrategies[item.type].getPrice(item.basePrice);
}

function getShippingCost(item: Item): number {
  return pricingStrategies[item.type].getShippingCost();
}
```

**When to apply this pattern:**
- Multiple switch/if chains branch on the same type/discriminator
- Adding a new variant requires editing multiple functions
- Each variant has distinct behavior across several operations

**When NOT to apply:**
- Only one switch statement exists (a simple map suffices)
- The branching logic is trivial (2-3 simple cases)
- The types are unlikely to change

---

## SOLID Principles (Practical, Not Dogmatic)

| Principle | Practical Meaning | When To Apply |
|---|---|---|
| **S** — Single Responsibility | A function/class should have one reason to change | When a function does 2+ unrelated things |
| **O** — Open/Closed | Extend behavior without modifying existing code | When you keep adding cases to a switch/if chain |
| **L** — Liskov Substitution | Subtypes must be substitutable for their base types | When using inheritance (prefer composition) |
| **I** — Interface Segregation | Don't force clients to depend on methods they don't use | When interfaces get >5 methods |
| **D** — Dependency Inversion | Depend on abstractions, not concrete implementations | When you need to swap implementations (DB, email, etc.) |

**Important**: SOLID is a tool, not a religion. Apply when it reduces complexity. Don't apply when it adds complexity for no benefit.

---

## Coupling Reduction

### Dependency Injection

```typescript
// BEFORE: tightly coupled — hard to test, hard to swap
class OrderService {
  async createOrder(data: OrderInput): Promise<Order> {
    const order = await prisma.order.create({ data });       // Direct DB dependency
    await sendgrid.send({ to: data.email, ... });            // Direct email dependency
    await stripe.charges.create({ amount: data.total, ... }); // Direct payment dependency
    return order;
  }
}

// AFTER: dependency injection — testable, swappable
interface OrderRepository {
  create(data: OrderInput): Promise<Order>;
}
interface EmailSender {
  send(to: string, subject: string, body: string): Promise<void>;
}
interface PaymentProcessor {
  charge(amount: number, method: PaymentMethod): Promise<PaymentResult>;
}

class OrderService {
  constructor(
    private repo: OrderRepository,
    private email: EmailSender,
    private payment: PaymentProcessor,
  ) {}

  async createOrder(data: OrderInput): Promise<Order> {
    const paymentResult = await this.payment.charge(data.total, data.paymentMethod);
    const order = await this.repo.create({ ...data, paymentId: paymentResult.id });
    await this.email.send(data.email, 'Order Confirmed', `Order #${order.id}`);
    return order;
  }
}

// In tests: pass mock implementations
// In production: pass real implementations
// Swapping email provider: change one line, not OrderService
```

### Interface Segregation in Practice

```typescript
// BEFORE: fat interface — every consumer depends on everything
interface UserService {
  getUser(id: string): Promise<User>;
  updateUser(id: string, data: UpdateUser): Promise<User>;
  deleteUser(id: string): Promise<void>;
  listUsers(filter: Filter): Promise<User[]>;
  getUserPermissions(id: string): Promise<Permission[]>;
  exportUsersToCSV(): Promise<Buffer>;
  sendPasswordReset(email: string): Promise<void>;
  verifyEmail(token: string): Promise<void>;
}

// AFTER: focused interfaces — consumers depend only on what they use
interface UserReader {
  getUser(id: string): Promise<User>;
  listUsers(filter: Filter): Promise<User[]>;
}

interface UserWriter {
  updateUser(id: string, data: UpdateUser): Promise<User>;
  deleteUser(id: string): Promise<void>;
}

interface UserAuth {
  sendPasswordReset(email: string): Promise<void>;
  verifyEmail(token: string): Promise<void>;
}

// A component that only reads users depends on UserReader, not the whole service.
// Changes to UserAuth don't affect components that only read users.
```

### Reducing Circular Dependencies

```typescript
// Symptom: Module A imports from Module B, Module B imports from Module A
// Fix 1: Extract shared types/interfaces into a third module
// Fix 2: Use events/callbacks instead of direct imports
// Fix 3: Dependency inversion — depend on abstractions

// BEFORE: circular
// user.service.ts imports from order.service.ts
// order.service.ts imports from user.service.ts

// AFTER: event-based decoupling
// user.service.ts — no knowledge of orders
class UserService {
  constructor(private events: EventEmitter) {}

  async deleteUser(id: string) {
    await this.repo.delete(id);
    this.events.emit('user.deleted', { userId: id });
  }
}

// order.service.ts — listens for user events
class OrderService {
  constructor(private events: EventEmitter) {
    this.events.on('user.deleted', ({ userId }) => {
      this.cancelPendingOrders(userId);
    });
  }
}
```

---

## Cognitive Complexity vs Cyclomatic Complexity

### What's the Difference?

```typescript
// Cyclomatic complexity counts decision points (if, else, while, for, &&, ||)
// Cognitive complexity weights NESTED structures higher — matches human difficulty

// Example: Both have cyclomatic complexity ~4, but different cognitive complexity

// LOW cognitive complexity (flat structure, easy to read)
function processA(input: Input): Result {
  if (!input.valid) return { error: 'invalid' };       // +1
  if (!input.data) return { error: 'no data' };        // +1
  if (input.data.length === 0) return { error: 'empty' }; // +1
  return process(input.data);                           // +1 (call)
}
// Cognitive complexity: 3 (flat, no nesting penalty)

// HIGH cognitive complexity (deeply nested, hard to follow)
function processB(input: Input): Result {
  if (input.valid) {                                    // +1
    if (input.data) {                                   // +2 (nesting!)
      if (input.data.length > 0) {                      // +3 (more nesting!)
        return process(input.data);
      }
    }
  }
  return { error: 'failed' };
}
// Cognitive complexity: 6 (nesting penalties compound)
```

### Measuring Complexity

```bash
# ESLint plugin for cognitive complexity (recommended)
npm install -D eslint-plugin-sonarjs

# .eslintrc or eslint.config.js
{
  "plugins": ["sonarjs"],
  "rules": {
    "sonarjs/cognitive-complexity": ["error", 15],  // Max 15 per function
    "complexity": ["error", 10],                     // Cyclomatic max 10
  }
}

# Run:
npx eslint --rule '{"sonarjs/cognitive-complexity": ["error", 15]}' src/

# The sonarjs plugin also catches:
# - Duplicate string literals
# - Identical functions
# - Collapsible if statements
# - Unused collection operations
```

**Targets:**

| Metric | Good | Acceptable | Refactor Now |
|---|---|---|---|
| Cognitive complexity | ≤ 8 | 9-15 | > 15 |
| Cyclomatic complexity | ≤ 5 | 6-10 | > 10 |
| Function length | ≤ 20 lines | 21-30 | > 30 |
| Nesting depth | ≤ 2 | 3 | > 3 |

---

## Incremental Refactoring

### Strangler Fig Pattern

Replace a complex system piece by piece, not all at once.

```typescript
// Original: monolithic function doing 5 things
function handleRequest(req: Request): Response {
  // 1. Parse input (20 lines)
  // 2. Validate (30 lines)
  // 3. Business logic (50 lines)
  // 4. Persist data (20 lines)
  // 5. Send notifications (15 lines)
}

// Step 1: Extract one piece, delegate to it
function handleRequest(req: Request): Response {
  const input = parseInput(req);          // Extracted!
  // 2. Validate (30 lines) — still inline
  // 3. Business logic (50 lines) — still inline
  // 4. Persist data (20 lines) — still inline
  // 5. Send notifications (15 lines) — still inline
}

// Step 2: Extract next piece (one PR per step)
function handleRequest(req: Request): Response {
  const input = parseInput(req);
  validate(input);                        // Extracted!
  // 3. Business logic (50 lines) — still inline
  // 4. Persist data (20 lines) — still inline
  // 5. Send notifications (15 lines) — still inline
}

// Each step: tests pass, deploy, move on.
// Eventually the original function is just a coordinator.
```

### Feature Flag Refactoring

```typescript
// Use feature flags to safely switch between old and new implementations

async function calculatePrice(order: Order): Promise<number> {
  if (featureFlags.isEnabled('new-pricing-engine', { userId: order.userId })) {
    // New implementation — gradually rolling out
    return newPricingEngine.calculate(order);
  }
  // Old implementation — still the default
  return legacyPricingCalculation(order);
}

// Rollout plan:
// Week 1: Enable for internal team (test with real data)
// Week 2: Enable for 5% of users (monitor error rates)
// Week 3: Enable for 50% of users (monitor business metrics)
// Week 4: Enable for 100%, remove old code
// Week 5: Remove feature flag (clean up)
```

### Parallel Implementation

```typescript
// Run both implementations, compare results, log discrepancies
async function getOrderTotal(orderId: string): Promise<number> {
  const oldResult = await legacyGetTotal(orderId);

  if (featureFlags.isEnabled('shadow-new-pricing')) {
    try {
      const newResult = await newGetTotal(orderId);
      if (Math.abs(oldResult - newResult) > 0.01) {
        logger.warn({
          event: 'pricing-discrepancy',
          orderId,
          oldResult,
          newResult,
          diff: oldResult - newResult,
        }, 'New pricing engine produced different result');
      }
    } catch (error) {
      logger.error({ err: error, orderId }, 'New pricing engine failed');
    }
  }

  return oldResult; // Always return old result until new is verified
}
```

---

## When NOT to Simplify

| Situation | Leave It Alone |
|---|---|
| Working code with good tests | Don't refactor for aesthetics |
| Performance-critical hot path | Clarity may be traded for speed (with comments explaining why) |
| Domain complexity (not code complexity) | Complex business rules need complex code — simplify the code, not the rules |
| Three similar lines | Don't abstract until the third occurrence |
| External API integration | Adapters are inherently messy — isolate, don't simplify |

### When NOT to Refactor — Expanded

```
DO NOT refactor when:

1. The code works and isn't being changed
   → If nobody is reading or modifying it, refactoring adds risk for zero benefit.
   → "If it ain't broke, don't fix it" applies to stable, tested code.

2. You're creating abstractions for one use case
   → A function called from one place doesn't need an interface.
   → An abstraction is only justified when there are 2+ concrete implementations.
   → "But we might need it later" = YAGNI. Delete and recreate when you actually need it.

3. The refactoring is premature optimization
   → Don't optimize code that runs once during startup.
   → Don't optimize code that takes 1ms when the API call takes 200ms.
   → Profile first. Only optimize actual bottlenecks.

4. You're in the middle of a feature
   → Refactoring and feature work in the same PR = guaranteed merge conflicts.
   → Note it, create a ticket, come back after the feature ships.

5. You don't have tests
   → Refactoring without tests = rolling the dice.
   → Write tests first (characterization tests), then refactor.
```

---

## Complexity Metrics

```bash
# Measure cyclomatic complexity
npx eslint --rule '{"complexity": ["error", 10]}' src/  # Max 10 paths per function

# Count function length
npx eslint --rule '{"max-lines-per-function": ["warn", 30]}' src/

# Count nesting depth
npx eslint --rule '{"max-depth": ["warn", 3]}' src/

# Find duplicate code
npx jscpd src/ --min-lines 5 --min-tokens 50
```

**Targets:**
- Cyclomatic complexity per function: ≤ 10
- Lines per function: ≤ 30
- Nesting depth: ≤ 3
- Parameters per function: ≤ 3
- File length: ≤ 300 lines

---

## Anti-Patterns

| Anti-Pattern | Why It's Dangerous | Fix |
|---|---|---|
| Premature abstraction | Abstracts the wrong thing, harder to change | Wait for the third occurrence |
| Over-engineering | Factories, strategies, decorators for simple code | YAGNI — simplest solution first |
| Clever code | One-liners that take 5 minutes to understand | Write boring, readable code |
| Comments explaining what | `// increment counter` before `counter++` | Self-documenting code, comments for WHY |
| Wrapper hell | Wrapping everything "for flexibility" | Direct usage until wrapper is needed |
| Design patterns as goals | "We need a Strategy pattern here" | Patterns emerge from needs, not vice versa |
| DRY obsession | Abstracting 2 similar but different things | Duplication is cheaper than wrong abstraction |
| Config-driven everything | 200-line config file instead of 20 lines of code | Code is configuration. Use code |
| Big-bang refactoring | Rewriting entire modules in one PR | Incremental: strangler fig, feature flags |
| Refactoring without tests | No safety net to catch regressions | Write characterization tests first |

---

## Checklist: Simplification Review

- [ ] No function exceeds 30 lines
- [ ] No nesting deeper than 3 levels (use guard clauses)
- [ ] No function has more than 3 parameters
- [ ] No dead code, commented-out code, or unused imports
- [ ] No magic numbers (use named constants)
- [ ] No boolean parameters (use options objects or separate functions)
- [ ] Complex conditions extracted into named functions
- [ ] Each module has a clear, single purpose
- [ ] Abstractions are justified by actual usage (not theoretical future use)
- [ ] Code reads top-to-bottom without jumping around
- [ ] Cognitive complexity ≤ 15 per function (eslint-plugin-sonarjs)
- [ ] Switch/if chains on type fields replaced with strategy maps where appropriate
- [ ] Dependencies are injected, not hardcoded (for external services)
- [ ] No circular dependencies between modules
- [ ] Refactoring is incremental (one PR per transformation, not big-bang)
