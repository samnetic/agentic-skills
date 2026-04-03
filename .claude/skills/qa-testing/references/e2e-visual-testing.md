# E2E & Visual Testing Reference

## Table of Contents

- [Playwright E2E Tests](#playwright-e2e-tests)
  - [Basic E2E Pattern](#basic-e2e-pattern)
  - [Best Practices](#best-practices)
  - [Test Tagging and Filtering](#test-tagging-and-filtering)
- [Playwright Advanced Features](#playwright-advanced-features)
  - [Clock API (Time-Dependent Tests)](#clock-api-time-dependent-tests)
  - [toPass for Retrying Assertions](#topass-for-retrying-assertions)
  - [API Testing with Playwright](#api-testing-with-playwright)
  - [Component Testing (Experimental)](#component-testing-experimental)
  - [Accessibility Assertions](#accessibility-assertions)
  - [Visual Comparisons](#visual-comparisons)
  - [UI Mode for Debugging](#ui-mode-for-debugging)
- [Visual Regression Testing](#visual-regression-testing)
  - [Playwright Screenshot Comparison](#playwright-screenshot-comparison)
  - [Chromatic (Storybook Visual Testing)](#chromatic-storybook-visual-testing)
- [Accessibility Testing Automation](#accessibility-testing-automation)
  - [axe-core with Playwright](#axe-core-with-playwright)
  - [Built-in Accessibility Assertions](#built-in-accessibility-assertions)

---

## Playwright E2E Tests

### Basic E2E Pattern

```typescript
import { test, expect } from '@playwright/test';

test.describe('User Registration', () => {
  test('completes full registration flow', async ({ page }) => {
    await page.goto('/register');

    // Fill form
    await page.getByLabel('Email').fill('newuser@test.com');
    await page.getByLabel('Password').fill('SecurePass123!');
    await page.getByLabel('Confirm Password').fill('SecurePass123!');
    await page.getByRole('button', { name: 'Create Account' }).click();

    // Verify redirect to dashboard
    await expect(page).toHaveURL('/dashboard');
    await expect(page.getByText('Welcome')).toBeVisible();
  });

  test('shows validation errors for invalid input', async ({ page }) => {
    await page.goto('/register');
    await page.getByRole('button', { name: 'Create Account' }).click();

    await expect(page.getByText('Email is required')).toBeVisible();
    await expect(page.getByText('Password is required')).toBeVisible();
  });
});
```

### Best Practices

| Practice | Why |
|---|---|
| Use role-based locators | `getByRole('button', { name: '...' })` — resilient to CSS changes |
| Use `getByLabel` for forms | Accessible and stable |
| Avoid `data-testid` when possible | Role/label locators test accessibility too |
| No `page.waitForTimeout()` | Use `expect().toBeVisible()` or `waitForResponse` |
| Test file per feature | Not per page — user flows cross pages |
| Parallel execution | `fullyParallel: true` in config |
| Visual regression | `expect(page).toHaveScreenshot()` for UI consistency |

### Test Tagging and Filtering

Use tags to categorize tests and run subsets in CI or locally.

```typescript
// Tag tests with @tag syntax in the test name
test('user can add item to cart @smoke @e2e', async ({ page }) => {
  await page.goto('/products');
  await page.getByRole('button', { name: 'Add to Cart' }).first().click();
  await expect(page.getByTestId('cart-count')).toHaveText('1');
});

test('user can complete checkout flow @e2e', async ({ page }) => {
  // ... full checkout test
});

test('search returns relevant results @smoke', async ({ page }) => {
  await page.goto('/');
  await page.getByPlaceholder('Search').fill('laptop');
  await page.keyboard.press('Enter');
  await expect(page.getByRole('list')).toBeVisible();
});

// Run tagged subsets:
// npx playwright test --grep @smoke          # Only smoke tests
// npx playwright test --grep @e2e            # Only E2E tests
// npx playwright test --grep-invert @slow    # Skip slow tests

// Playwright also supports tag-based annotations:
test('admin dashboard loads @admin @slow', {
  tag: ['@admin', '@slow'],
}, async ({ page }) => {
  await page.goto('/admin');
  await expect(page.getByRole('heading', { name: 'Dashboard' })).toBeVisible();
});
```

**Tagging strategy for CI:**
- `@smoke` — critical paths, run on every PR (fast)
- `@e2e` — full user journeys, run on merge to main
- `@slow` — performance-sensitive tests, run nightly
- `@flaky` — known flaky tests, quarantined and tracked

---

## Playwright Advanced Features

### Clock API (Time-Dependent Tests)

The Clock API lets you control time in E2E tests — install a fake clock, fast-forward, and assert time-dependent behavior without waiting.

```typescript
test('shows countdown timer', async ({ page }) => {
  // Install fake clock at a specific time
  await page.clock.install({ time: new Date('2025-01-01T00:00:00') });
  await page.goto('/countdown');

  // Fast-forward 1 hour
  await page.clock.fastForward('01:00:00');
  await expect(page.locator('.timer')).toHaveText('23:00:00');
});

test('shows relative time correctly', async ({ page }) => {
  await page.clock.install({ time: new Date('2025-06-15T10:00:00') });
  await page.goto('/posts/1');

  // Post was created "2 hours ago" at the installed time
  await expect(page.getByText('2 hours ago')).toBeVisible();

  // Fast-forward 1 day
  await page.clock.fastForward('24:00:00');
  await expect(page.getByText('1 day ago')).toBeVisible();
});

test('session expires after inactivity', async ({ page }) => {
  await page.clock.install({ time: new Date('2025-01-01T09:00:00') });
  await page.goto('/dashboard');
  await expect(page.getByText('Welcome')).toBeVisible();

  // Fast-forward past session timeout (30 minutes)
  await page.clock.fastForward('00:31:00');

  // Trigger a UI update (clock alone won't re-render)
  await page.locator('body').click();
  await expect(page.getByText('Session expired')).toBeVisible();
});
```

**Clock API methods:**
- `page.clock.install({ time })` — install fake clock at a specific point in time
- `page.clock.fastForward(ms | timestring)` — advance time (triggers timers)
- `page.clock.setFixedTime(time)` — freeze time at a fixed point
- `page.clock.resume()` — resume real-time clock progression

### toPass for Retrying Assertions

```typescript
// Retry an assertion block until it passes (useful for eventual consistency)
await expect(async () => {
  const response = await page.request.get('/api/status');
  expect(response.status()).toBe(200);
  const data = await response.json();
  expect(data.processed).toBe(true);
}).toPass({
  timeout: 30_000,         // Max wait time
  intervals: [1000, 2000, 5000],  // Retry intervals
});
```

### API Testing with Playwright

```typescript
import { test, expect } from '@playwright/test';

test.describe('API Tests', () => {
  test('creates and retrieves a user', async ({ request }) => {
    // POST — create user
    const createResponse = await request.post('/api/users', {
      data: { email: 'test@example.com', name: 'Test User' },
    });
    expect(createResponse.ok()).toBeTruthy();
    const user = await createResponse.json();
    expect(user.id).toBeDefined();

    // GET — retrieve user
    const getResponse = await request.get(`/api/users/${user.id}`);
    expect(getResponse.ok()).toBeTruthy();
    expect(await getResponse.json()).toMatchObject({
      email: 'test@example.com',
      name: 'Test User',
    });
  });
});
```

### Component Testing (Experimental)

```typescript
import { test, expect } from '@playwright/experimental-ct-react';
import { Button } from './Button';

test.use({ colorScheme: 'dark' });

test('renders button with label', async ({ mount }) => {
  const component = await mount(<Button label="Click me" />);

  await expect(component).toContainText('Click me');
  await expect(component).toHaveScreenshot();   // Visual comparison
  await component.click();
});
```

### Accessibility Assertions

```typescript
import { test, expect } from '@playwright/test';

test('button has correct accessible properties', async ({ page }) => {
  await page.goto('/form');

  const submitBtn = page.getByRole('button', { name: 'Submit' });

  // Built-in accessibility assertions
  await expect(submitBtn).toHaveAccessibleName('Submit');
  await expect(submitBtn).toHaveAccessibleDescription('Submit the form');
  await expect(submitBtn).toHaveRole('button');
});

// ARIA snapshot testing — validate accessibility tree structure
test('navigation has correct ARIA structure', async ({ page }) => {
  await page.goto('/');
  await expect(page.getByRole('navigation')).toMatchAriaSnapshot(`
    - navigation:
      - link "Home"
      - link "Products"
      - link "About"
  `);
});
```

### Visual Comparisons

```typescript
// Full page screenshots
await expect(page).toHaveScreenshot('homepage.png', {
  fullPage: true,
  maxDiffPixelRatio: 0.01,   // Allow 1% pixel difference
});

// Element screenshots
await expect(page.getByTestId('chart')).toHaveScreenshot('chart.png', {
  animations: 'disabled',     // Freeze animations for consistency
});

// Update snapshots: npx playwright test --update-snapshots
```

### UI Mode for Debugging

```bash
# Launch interactive UI mode — watch, debug, time-travel
npx playwright test --ui

# Trace viewer for CI failures
npx playwright test --trace on    # Record traces
npx playwright show-trace trace.zip  # View locally
```

---

## Visual Regression Testing

Visual regression testing catches unintended UI changes by comparing screenshots against approved baselines.

### Playwright Screenshot Comparison

```typescript
import { test, expect } from '@playwright/test';

// Full page visual comparison
test('homepage matches baseline', async ({ page }) => {
  await page.goto('/');
  await expect(page).toHaveScreenshot('homepage.png', {
    fullPage: true,
    maxDiffPixelRatio: 0.01,     // Allow 1% pixel difference
  });
});

// Component-level comparison
test('pricing cards match baseline', async ({ page }) => {
  await page.goto('/pricing');
  const cards = page.locator('.pricing-cards');
  await expect(cards).toHaveScreenshot('pricing-cards.png', {
    animations: 'disabled',       // Freeze CSS animations
    mask: [page.locator('.dynamic-date')],  // Mask dynamic content
  });
});

// Responsive visual testing
for (const viewport of [
  { width: 375, height: 667, name: 'mobile' },
  { width: 768, height: 1024, name: 'tablet' },
  { width: 1440, height: 900, name: 'desktop' },
]) {
  test(`homepage renders correctly on ${viewport.name}`, async ({ page }) => {
    await page.setViewportSize(viewport);
    await page.goto('/');
    await expect(page).toHaveScreenshot(`homepage-${viewport.name}.png`);
  });
}

// Update baselines:
// npx playwright test --update-snapshots
```

### Chromatic (Storybook Visual Testing)

```bash
# Install Chromatic
npm install --save-dev chromatic

# Run visual tests against Storybook
npx chromatic --project-token=<token>
```

```yaml
# CI integration — run Chromatic on every PR
jobs:
  visual-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0        # Required for Chromatic to detect changes
      - run: npm ci
      - uses: chromaui/action@latest
        with:
          projectToken: ${{ secrets.CHROMATIC_PROJECT_TOKEN }}
          exitZeroOnChanges: true   # Don't fail CI — review in Chromatic UI
```

**Visual regression strategy:**
- Use Playwright `toHaveScreenshot()` for E2E visual tests (page-level)
- Use Chromatic/Storybook for component-level visual testing (isolated)
- Mask dynamic content (dates, avatars, ads) to avoid false positives
- Run visual tests on a single OS/browser to avoid cross-platform diffs
- Review and approve visual changes explicitly — never auto-approve

---

## Accessibility Testing Automation

### axe-core with Playwright

```typescript
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test.describe('Accessibility', () => {
  test('homepage has no a11y violations', async ({ page }) => {
    await page.goto('/');

    const results = await new AxeBuilder({ page }).analyze();
    expect(results.violations).toEqual([]);
  });

  test('form page meets WCAG AA', async ({ page }) => {
    await page.goto('/contact');

    const results = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa', 'wcag22aa'])  // WCAG 2.2 AA
      .exclude('.third-party-widget')                  // Skip third-party
      .analyze();

    expect(results.violations).toEqual([]);
  });

  test('keyboard navigation works', async ({ page }) => {
    await page.goto('/');

    // Tab through interactive elements
    await page.keyboard.press('Tab');
    await expect(page.getByRole('link', { name: 'Home' })).toBeFocused();

    await page.keyboard.press('Tab');
    await expect(page.getByRole('link', { name: 'Products' })).toBeFocused();
  });
});
```

### Built-in Accessibility Assertions

```typescript
// Assert accessible name, description, and role
await expect(page.getByTestId('submit-btn')).toHaveAccessibleName('Submit form');
await expect(page.getByTestId('submit-btn')).toHaveAccessibleDescription('Submits the contact form');
await expect(page.getByTestId('submit-btn')).toHaveRole('button');

// ARIA snapshot — validate full accessibility tree
await expect(page.getByRole('navigation')).toMatchAriaSnapshot(`
  - navigation:
    - link "Home"
    - link "Products"
    - link "About"
`);
```
