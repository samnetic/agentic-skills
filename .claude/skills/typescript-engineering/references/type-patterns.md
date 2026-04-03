# TypeScript Type Design Patterns

## Table of Contents

- [Discriminated Unions (State Machines)](#discriminated-unions-state-machines)
- [Branded/Nominal Types](#brandednominal-types)
- [Type Predicates (Custom Type Guards)](#type-predicates-custom-type-guards)
- [Inferred Type Predicates (TS 5.5+)](#inferred-type-predicates-ts-55)
- [Const Assertions and Enums](#const-assertions-and-enums)
- [satisfies Operator Patterns (TS 4.9+)](#satisfies-operator-patterns-ts-49)
- [const Type Parameters (TS 5.0+)](#const-type-parameters-ts-50)
- [NoInfer Utility Type (TS 5.4+)](#noinfer-utility-type-ts-54)
- [Template Literal Types](#template-literal-types)
- [Generic Constraints](#generic-constraints)
- [Type-Safe Builder Pattern](#type-safe-builder-pattern)
- [Generic React Component Patterns](#generic-react-component-patterns)

---

## Discriminated Unions (State Machines)

```typescript
// Make illegal states unrepresentable
type RequestState =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'success'; data: User[] }
  | { status: 'error'; error: Error; retryCount: number };

function handleState(state: RequestState) {
  switch (state.status) {
    case 'idle':
      return renderEmpty();
    case 'loading':
      return renderSpinner();
    case 'success':
      return renderUsers(state.data); // data is available here
    case 'error':
      return renderError(state.error); // error is available here
    // No default — TypeScript errors if a case is missing (exhaustive check)
  }
}
```

---

## Branded/Nominal Types

```typescript
// Prevent mixing up IDs
type UserId = string & { readonly __brand: 'UserId' };
type OrderId = string & { readonly __brand: 'OrderId' };

function createUserId(id: string): UserId {
  if (!id.match(/^usr_/)) throw new Error('Invalid user ID format');
  return id as UserId;
}

function getUser(id: UserId): User { ... }
function getOrder(id: OrderId): Order { ... }

const userId = createUserId('usr_123');
const orderId = createOrderId('ord_456');

getUser(userId);   // OK
getUser(orderId);  // Compile error! Can't pass OrderId where UserId expected
```

---

## Type Predicates (Custom Type Guards)

```typescript
function isNonNullable<T>(value: T): value is NonNullable<T> {
  return value !== null && value !== undefined;
}

function isUser(data: unknown): data is User {
  return (
    typeof data === 'object' &&
    data !== null &&
    'id' in data &&
    'email' in data &&
    typeof (data as User).email === 'string'
  );
}

// Usage — filters with type narrowing
const validUsers = users.filter(isNonNullable);
// Type: User[] (not (User | null)[])
```

---

## Inferred Type Predicates (TS 5.5+)

TypeScript 5.5 automatically infers type predicates for simple guard functions. No more manual `x is T` annotations for obvious cases.

```typescript
// TS 5.5 infers: (x: unknown) => x is number
const isNumber = (x: unknown) => typeof x === 'number';

// TS 5.5 infers: (x: T) => x is NonNullable<T>
const isNonNullish = <T,>(x: T) => x != null;

// .filter() now narrows correctly without manual type predicates
const nums = [1, 2, 3, null, 5].filter(x => x !== null);
// TS 5.4: (number | null)[]
// TS 5.5: number[]  — automatically inferred!

// Still write manual predicates for complex checks
function isAdmin(user: User): user is AdminUser {
  return user.role === 'admin' && 'permissions' in user;
}
```

---

## Const Assertions and Enums

```typescript
// AVOID TypeScript enums — use const objects instead
// Why: enums generate runtime code, have weird behavior with number values

// DO: const object + type derivation
const ORDER_STATUS = {
  PENDING: 'pending',
  CONFIRMED: 'confirmed',
  SHIPPED: 'shipped',
  DELIVERED: 'delivered',
  CANCELLED: 'cancelled',
} as const;

type OrderStatus = typeof ORDER_STATUS[keyof typeof ORDER_STATUS];
// Type: 'pending' | 'confirmed' | 'shipped' | 'delivered' | 'cancelled'

// Also works for lookup maps
const HTTP_STATUS = {
  200: 'OK',
  201: 'Created',
  400: 'Bad Request',
  404: 'Not Found',
  500: 'Internal Server Error',
} as const;

type HttpStatusCode = keyof typeof HTTP_STATUS; // 200 | 201 | 400 | 404 | 500
```

---

## `satisfies` Operator Patterns (TS 4.9+)

`satisfies` validates a value matches a type WITHOUT widening it. You keep literal types and autocomplete.

```typescript
// PROBLEM: type annotation widens — lose literal types
const routes: Record<string, { path: string }> = {
  home: { path: '/' },
  about: { path: '/about' },
};
routes.home.path; // string (wide)
routes.typo;      // no error! any key is valid

// SOLUTION: satisfies — validate shape, keep literals
const routes = {
  home: { path: '/' },
  about: { path: '/about' },
} satisfies Record<string, { path: string }>;
routes.home.path; // "/" (literal)
routes.typo;      // error: Property 'typo' does not exist

// Great for config objects
type Theme = { colors: Record<string, string>; spacing: Record<string, number> };

const theme = {
  colors: { primary: '#3b82f6', danger: '#ef4444' },
  spacing: { sm: 4, md: 8, lg: 16 },
} satisfies Theme;

theme.colors.primary; // "#3b82f6" (literal, not string)
theme.spacing.sm;     // 4 (literal, not number)

// Combine with `as const` for fully immutable + validated
const permissions = {
  admin: ['read', 'write', 'delete'],
  viewer: ['read'],
} as const satisfies Record<string, readonly string[]>;
```

---

## `const` Type Parameters (TS 5.0+)

Forces callers to infer literal types without requiring `as const` at the call site.

```typescript
// WITHOUT const — infers wide types
function getRoutes<T extends Record<string, string>>(routes: T): T {
  return routes;
}
const r1 = getRoutes({ home: '/', about: '/about' });
// Type: { home: string; about: string }  — too wide

// WITH const — infers literal types automatically
function getRoutes<const T extends Record<string, string>>(routes: T): T {
  return routes;
}
const r2 = getRoutes({ home: '/', about: '/about' });
// Type: { readonly home: "/"; readonly about: "/about" }  — precise!

// Useful for builder patterns, config factories, event maps
function defineEvents<const T extends Record<string, (...args: unknown[]) => void>>(events: T): T {
  return events;
}
const events = defineEvents({
  userCreated: (user: User) => {},
  orderPlaced: (order: Order, total: number) => {},
});
// Full type safety on event names AND handler signatures
```

---

## `NoInfer<T>` Utility Type (TS 5.4+)

Prevents TypeScript from inferring a type parameter from a specific position. Forces inference from other arguments.

```typescript
// WITHOUT NoInfer — TypeScript infers from BOTH arguments (union)
function createFSM<S extends string>(states: S[], initial: S) {}
createFSM(['idle', 'loading', 'done'], 'invalid');
// No error! TS infers S as 'idle' | 'loading' | 'done' | 'invalid'

// WITH NoInfer — inference blocked on `initial`, must match `states`
function createFSM<S extends string>(states: S[], initial: NoInfer<S>) {}
createFSM(['idle', 'loading', 'done'], 'invalid');
//                                      ^^^^^^^^^ Error!
// Argument of type '"invalid"' is not assignable to '"idle" | "loading" | "done"'

// Works for default values, fallback configs, etc.
function createStreetLight<C extends string>(
  colors: C[],
  defaultColor?: NoInfer<C>,
) {}
createStreetLight(['red', 'yellow', 'green'], 'blue'); // Error!
```

---

## Template Literal Types

Type-safe string patterns at compile time. Compose unions to generate all valid combinations.

```typescript
// Type-safe API routes
type HttpMethod = 'GET' | 'POST' | 'PUT' | 'DELETE';
type ApiVersion = 'v1' | 'v2';
type Resource = 'users' | 'orders' | 'products';
type ApiEndpoint = `/${ApiVersion}/${Resource}`;
// "/v1/users" | "/v1/orders" | "/v1/products" | "/v2/users" | ...

// CSS utility classes (like Tailwind)
type Size = 'sm' | 'md' | 'lg' | 'xl';
type Side = 'top' | 'right' | 'bottom' | 'left';
type SpacingClass = `${'p' | 'm'}${'' | `${'-' | 'x-' | 'y-' | 't-' | 'b-' | 'l-' | 'r-'}`}${Size}`;

// Type-safe CSS values
type CSSUnit = 'px' | 'rem' | 'em' | '%' | 'vh' | 'vw';
type CSSValue = `${number}${CSSUnit}`;
const width: CSSValue = '100px';  // OK
const bad: CSSValue = '100';      // Error — missing unit

// Event handler pattern — auto-generate "on" + capitalized event
type EventName = 'click' | 'focus' | 'blur';
type EventHandler = `on${Capitalize<EventName>}`;
// "onClick" | "onFocus" | "onBlur"

// Extract route params from URL pattern
type ExtractParams<T extends string> =
  T extends `${infer _}:${infer Param}/${infer Rest}`
    ? Param | ExtractParams<Rest>
    : T extends `${infer _}:${infer Param}`
      ? Param
      : never;

type Params = ExtractParams<'/users/:userId/posts/:postId'>;
// "userId" | "postId"
```

---

## Generic Constraints

```typescript
// Constrained generics
function getProperty<T, K extends keyof T>(obj: T, key: K): T[K] {
  return obj[key];
}

// Generic with default
type ApiResponse<T = unknown> = {
  data: T;
  meta: { timestamp: number; requestId: string };
};

// Conditional types
type ExtractArrayItem<T> = T extends (infer U)[] ? U : never;
type Item = ExtractArrayItem<string[]>; // string

// Illustration of how the built-in Readonly<T> works — use the built-in directly
type ReadonlyIllustration<T> = { readonly [K in keyof T]: T[K] };

// This is the built-in Partial<T>
type PartialIllustration<T> = { [K in keyof T]?: T[K] };

type Nullable<T> = { [K in keyof T]: T[K] | null };
```

---

## Type-Safe Builder Pattern

```typescript
// Functional builder — no `as any`, fully type-safe
interface ConnectionConfig {
  readonly host: string;
  readonly port: number;
  readonly database: string;
}

type Builder<T extends Partial<ConnectionConfig> = {}> = Readonly<T> & {
  host(value: string): Builder<T & { host: string }>;
  port(value: number): Builder<T & { port: number }>;
  database(value: string): Builder<T & { database: string }>;
} & (T extends ConnectionConfig ? { build(): Connection } : {});

function createConnectionBuilder<T extends Partial<ConnectionConfig> = {}>(
  config: T = {} as T
): Builder<T> {
  return {
    ...config,
    host: (value: string) => createConnectionBuilder({ ...config, host: value }),
    port: (value: number) => createConnectionBuilder({ ...config, port: value }),
    database: (value: string) => createConnectionBuilder({ ...config, database: value }),
    ...(isComplete(config) ? { build: () => new Connection(config) } : {}),
  } as Builder<T>;
}

function isComplete(c: Partial<ConnectionConfig>): c is ConnectionConfig {
  return 'host' in c && 'port' in c && 'database' in c;
}

createConnectionBuilder().host('localhost').build();
// Error: Property 'build' does not exist

createConnectionBuilder().host('localhost').port(5432).database('mydb').build();
// Compiles — build() only available when all fields set
```

---

## Generic React Component Patterns

```typescript
// Generic table component
interface Column<T> {
  key: keyof T;
  header: string;
  render?: (value: T[keyof T], row: T) => React.ReactNode;
}

interface DataTableProps<T> {
  data: T[];
  columns: Column<T>[];
  onRowClick?: (row: T) => void;
}

function DataTable<T extends Record<string, unknown>>({
  data, columns, onRowClick,
}: DataTableProps<T>) {
  return (
    <table>
      <thead>
        <tr>{columns.map(col => <th key={String(col.key)}>{col.header}</th>)}</tr>
      </thead>
      <tbody>
        {data.map((row, i) => (
          <tr key={i} onClick={() => onRowClick?.(row)}>
            {columns.map(col => (
              <td key={String(col.key)}>
                {col.render ? col.render(row[col.key], row) : String(row[col.key])}
              </td>
            ))}
          </tr>
        ))}
      </tbody>
    </table>
  );
}

// Usage — T is inferred
<DataTable
  data={users}
  columns={[
    { key: 'name', header: 'Name' },
    { key: 'email', header: 'Email' },
    { key: 'role', header: 'Role', render: (v) => <Badge>{v}</Badge> },
  ]}
/>
```
