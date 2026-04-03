# Advanced Testing Patterns Reference

## Table of Contents

- [Property-Based Testing](#property-based-testing)
  - [JavaScript/TypeScript (fast-check)](#javascripttypescript-fast-check)
  - [Python (Hypothesis)](#python-hypothesis)
- [Mutation Testing (Stryker)](#mutation-testing-stryker)
- [Performance Testing with k6](#performance-testing-with-k6)
  - [Load Test Script](#load-test-script)
  - [k6 in CI (GitHub Actions)](#k6-in-ci-github-actions)
- [Vitest Advanced Features](#vitest-advanced-features)
  - [Project-Based Workspace (Monorepo Testing)](#project-based-workspace-monorepo-testing)
  - [Browser Mode](#browser-mode)
  - [vi.hoisted for Mock Setup](#vihoisted-for-mock-setup)
  - [Benchmark Mode](#benchmark-mode)

---

## Property-Based Testing

Instead of writing specific examples, define properties that must always hold. The framework generates hundreds of random inputs.

### JavaScript/TypeScript (fast-check)

```typescript
import { fc, test as fcTest } from '@fast-check/vitest';
import { describe } from 'vitest';

describe('sort', () => {
  fcTest.prop([fc.array(fc.integer())])('output is sorted', (arr) => {
    const sorted = [...arr].sort((a, b) => a - b);
    for (let i = 1; i < sorted.length; i++) {
      expect(sorted[i]).toBeGreaterThanOrEqual(sorted[i - 1]);
    }
  });

  fcTest.prop([fc.array(fc.integer())])('preserves length', (arr) => {
    expect([...arr].sort((a, b) => a - b)).toHaveLength(arr.length);
  });

  fcTest.prop([fc.array(fc.integer())])('preserves elements', (arr) => {
    const sorted = [...arr].sort((a, b) => a - b);
    expect(sorted).toEqual(expect.arrayContaining(arr));
  });
});

// Useful generators:
// fc.string(), fc.uuid(), fc.emailAddress(), fc.date()
// fc.record({ name: fc.string(), age: fc.nat(120) })
// fc.oneof(fc.constant('admin'), fc.constant('user'))
```

### Python (Hypothesis)

```python
from hypothesis import given, strategies as st

@given(st.lists(st.integers()))
def test_sort_is_idempotent(xs):
    assert sorted(sorted(xs)) == sorted(xs)

@given(st.text(min_size=1), st.text(min_size=1))
def test_concat_length(a, b):
    assert len(a + b) == len(a) + len(b)
```

---

## Mutation Testing (Stryker)

Mutation testing modifies your source code (mutants) and checks if tests catch the changes. If a mutant survives, your tests have a gap.

```bash
# Install Stryker for JS/TS
npm install --save-dev @stryker-mutator/core @stryker-mutator/vitest-runner

# stryker.config.mjs
export default {
  testRunner: 'vitest',
  mutate: ['src/**/*.ts', '!src/**/*.test.ts', '!src/**/*.spec.ts'],
  reporters: ['html', 'clear-text', 'progress'],
  thresholds: { high: 80, low: 60, break: 50 },
  // Incremental mode — only test changed files
  incremental: true,
};

# Run: npx stryker run
# Output: mutation score, surviving mutants, and which lines need better tests
```

| Mutation Score | Meaning |
|---|---|
| 80%+ | Excellent — tests catch most code changes |
| 60-80% | Good — some gaps to address |
| <60% | Significant testing gaps |

---

## Performance Testing with k6

### Load Test Script

```javascript
// load-test.js — run with: k6 run load-test.js
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 20 },   // Ramp up to 20 users
    { duration: '1m',  target: 20 },   // Hold at 20 users
    { duration: '30s', target: 100 },  // Spike to 100 users
    { duration: '1m',  target: 100 },  // Hold at 100
    { duration: '30s', target: 0 },    // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<200'],   // 95% of requests < 200ms
    http_req_failed: ['rate<0.01'],     // <1% error rate
  },
};

export default function () {
  const res = http.get('http://localhost:3000/api/users');

  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 200ms': (r) => r.timings.duration < 200,
    'body has users': (r) => JSON.parse(r.body).length > 0,
  });

  sleep(1);  // Think time between requests
}
```

### k6 in CI (GitHub Actions)

```yaml
# Run k6 in CI (GitHub Actions)
jobs:
  load-test:
    runs-on: ubuntu-latest
    services:
      app:
        image: ghcr.io/${{ github.repository }}:${{ github.sha }}
        ports: ['3000:3000']
    steps:
      - uses: grafana/k6-action@v0.3.1
        with:
          filename: load-test.js
          flags: --out json=results.json
      - uses: actions/upload-artifact@v4
        with:
          name: k6-results
          path: results.json
```

---

## Vitest Advanced Features

### Project-Based Workspace (Monorepo Testing)

```typescript
// vitest.config.ts — use projects instead of deprecated defineWorkspace
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    projects: [
      'packages/*/vitest.config.ts',
      {
        test: {
          name: 'api',
          root: './packages/api',
          environment: 'node',
        },
      },
      {
        test: {
          name: 'web',
          root: './packages/web',
          environment: 'jsdom',
        },
      },
    ],
  },
});

// Run all projects:       vitest
// Run specific project:   vitest --project api
```

### Browser Mode

```typescript
// vitest.config.ts — run tests in a real browser
import { defineConfig } from 'vitest/config';
import { playwright } from 'vitest/browsers';

export default defineConfig({
  test: {
    browser: {
      enabled: true,
      provider: playwright(),           // Function call, not string
      instances: [
        { browser: 'chromium' },
      ],
    },
  },
});

// Browser-mode mocking (uses { spy: true } option)
import { vi } from 'vitest';
import * as module from './module.js';

vi.mock('./module.js', { spy: true });  // Spy without replacing
vi.mocked(module.method).mockReturnValue(42);
```

### vi.hoisted for Mock Setup

```typescript
import { expect, vi } from 'vitest';
import { originalMethod } from './path/to/module.js';

// vi.hoisted runs before imports — solve the hoisting problem
const { mockedMethod } = vi.hoisted(() => {
  return { mockedMethod: vi.fn() };
});

vi.mock('./path/to/module.js', () => {
  return { originalMethod: mockedMethod };
});

mockedMethod.mockReturnValue(100);
expect(originalMethod()).toBe(100);
```

### Benchmark Mode

```typescript
// math.bench.ts
import { bench, describe } from 'vitest';

describe('sorting algorithms', () => {
  const data = Array.from({ length: 1000 }, () => Math.random());

  bench('Array.sort', () => {
    [...data].sort((a, b) => a - b);
  });

  bench('custom quicksort', () => {
    quicksort([...data]);
  });
});

// Run: vitest bench
// Compare: vitest bench --outputJson baseline.json
//          vitest bench --compare baseline.json
```

```typescript
// vitest.config.ts — benchmark configuration
export default defineConfig({
  test: {
    benchmark: {
      include: ['**/*.bench.ts'],
      outputJson: 'benchmark-results.json',
    },
  },
});
```
