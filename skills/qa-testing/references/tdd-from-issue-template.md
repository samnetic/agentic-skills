# TDD from Issue Template

Translate Given/When/Then acceptance criteria from pipeline issues into
executable test code using the Arrange/Act/Assert pattern.

## Mapping: Given/When/Then to Arrange/Act/Assert

| Acceptance Criteria | Test Phase | What It Does |
|---|---|---|
| **Given** (preconditions) | **Arrange** | Set up test data, mocks, initial state |
| **When** (action) | **Act** | Call the function / hit the endpoint / trigger the event |
| **Then** (expected outcome) | **Assert** | Verify the result matches the expected behavior |

## How to Translate an Issue into Tests

1. Copy each acceptance criterion from the issue verbatim as a comment
2. Create one test per criterion (do not combine multiple criteria)
3. Use domain language from the issue in test names and variable names
4. Write all tests first — they must all fail (RED) before any implementation

## Example: TypeScript / Vitest

**Issue acceptance criterion:**
> Given a user with an expired subscription,
> When they attempt to access premium content,
> Then they receive a 403 error with an upgrade prompt.

```typescript
import { describe, it, expect } from 'vitest';
import { accessContent } from '../src/content-access';
import { createUser } from './factories/user-factory';

describe('premium content access', () => {
  it('returns 403 with upgrade prompt for expired subscription', async () => {
    // Arrange — Given a user with an expired subscription
    const user = createUser({
      subscription: { status: 'expired', expiredAt: new Date('2025-01-01') },
    });
    const contentId = 'premium-article-42';

    // Act — When they attempt to access premium content
    const result = await accessContent(user, contentId);

    // Assert — Then they receive a 403 error with an upgrade prompt
    expect(result.status).toBe(403);
    expect(result.body).toMatchObject({
      error: 'subscription_expired',
      upgradeUrl: expect.stringContaining('/upgrade'),
    });
  });
});
```

## Example: Python / pytest

**Issue acceptance criterion:**
> Given a shopping cart with 3 items,
> When the user applies a valid 20% discount code,
> Then the total is reduced by 20% and the discount is shown in the summary.

```python
import pytest
from cart.service import apply_discount
from tests.factories import create_cart, create_discount_code


class TestApplyDiscount:
    def test_valid_discount_reduces_total_by_percentage(self):
        # Arrange — Given a shopping cart with 3 items
        cart = create_cart(items=[
            {"name": "Widget", "price": 25.00},
            {"name": "Gadget", "price": 50.00},
            {"name": "Doohickey", "price": 25.00},
        ])
        code = create_discount_code(percentage=20, code="SAVE20")

        # Act — When the user applies a valid 20% discount code
        result = apply_discount(cart, code)

        # Assert — Then the total is reduced by 20%
        assert result.total == 80.00  # 100.00 * 0.80

        # Assert — and the discount is shown in the summary
        assert result.summary.discount_applied == "SAVE20"
        assert result.summary.discount_amount == 20.00
```

## Checklist Before Writing Implementation

- [ ] Every acceptance criterion from the issue has exactly one test
- [ ] Test names use domain language from the issue (not technical jargon)
- [ ] All tests fail when run (RED phase confirmed)
- [ ] No implementation code exists yet — only interfaces/stubs if needed
- [ ] Tests import from the expected module paths (even if modules don't exist yet)
