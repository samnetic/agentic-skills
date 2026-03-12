# Refactoring Patterns & Coupling Reduction

## Table of Contents

- [Refactoring Patterns](#refactoring-patterns)
  - [1. Replace Nested Conditionals with Guard Clauses](#1-replace-nested-conditionals-with-guard-clauses)
  - [2. Extract Function by Intent](#2-extract-function-by-intent)
  - [3. Replace Boolean Parameters with Named Options](#3-replace-boolean-parameters-with-named-options)
  - [4. Replace Switch with Map](#4-replace-switch-with-map)
  - [5. Simplify Complex Conditions](#5-simplify-complex-conditions)
  - [6. Remove Dead Code](#6-remove-dead-code)
  - [7. Replace Conditional with Polymorphism](#7-replace-conditional-with-polymorphism)
- [Coupling Reduction](#coupling-reduction)
  - [Dependency Injection](#dependency-injection)
  - [Interface Segregation in Practice](#interface-segregation-in-practice)
  - [Reducing Circular Dependencies](#reducing-circular-dependencies)
- [Incremental Refactoring](#incremental-refactoring)
  - [Strangler Fig Pattern](#strangler-fig-pattern)
  - [Feature Flag Refactoring](#feature-flag-refactoring)
  - [Parallel Implementation](#parallel-implementation)

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
