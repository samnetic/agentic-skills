# Tracer Bullet Pattern

## Origin

The tracer bullet concept comes from *The Pragmatic Programmer* by Andrew Hunt and David Thomas. In warfare, tracer rounds are loaded alongside regular ammunition — they glow in flight so the gunner can see the path from gun to target and adjust aim in real time. The tracer bullet in software development serves the same purpose: it lights up the path through all layers of the system so the team can see whether the architecture actually works before committing to building every feature.

---

## Purpose

A tracer bullet proves that **all layers work together** before the team builds features on top of them. It answers the question: *"Can a request travel from the user's browser, through the frontend, through the API, into the database, and back — in production-grade code?"*

If the answer is yes, the team has a working skeleton to build on. If the answer is no, they discover it on day two instead of day sixty.

---

## What a Tracer Bullet IS

- The **thinnest possible end-to-end implementation** through all layers.
- **Production-quality code** — it ships, it is tested, it follows project conventions.
- A **skeleton that real features attach to** — subsequent slices extend this working path.
- **Proof of architecture** — confirms that the chosen frameworks, libraries, and infrastructure actually work together.

## What a Tracer Bullet Is NOT

| Concept | How it differs from a tracer bullet |
|---|---|
| **Prototype** | A prototype is throwaway code built to explore an idea. A tracer bullet is production code that stays. |
| **Spike** | A spike is time-boxed exploratory work to reduce uncertainty. A tracer bullet is committed, tested code. |
| **MVP** | An MVP is the smallest product with market value. A tracer bullet is the smallest end-to-end path — it may not have user value on its own. |
| **Proof of concept** | A POC validates that something is technically possible. A tracer bullet validates that ALL layers integrate correctly. |

---

## The Phase 0 Tracer Bullet Checklist

Every Phase 0 must include:

- [ ] **Database:** At least one table created and migrated
- [ ] **Backend:** At least one API endpoint handling real requests
- [ ] **Frontend:** At least one UI component rendering real data from the API
- [ ] **Tests:** At least one integration test covering the full request path
- [ ] **Deploy:** The tracer bullet deploys successfully to staging/preview environment

If any layer is missing, it is not a tracer bullet — it is a horizontal slice.

---

## How to Pick the Tracer Bullet

### Step 1: Identify the most representative user flow

Choose the flow that touches the most layers and is most central to the application. For a project management tool, this might be "create a project." For an e-commerce site, "view a product page."

### Step 2: Strip to minimum

Take that representative flow and remove everything except the absolute minimum needed to prove the end-to-end path:

| What to keep | What to strip |
|---|---|
| One database table with essential columns | Additional tables, optional columns, indexes |
| One API endpoint (usually POST or GET) | PATCH, DELETE, list endpoints |
| One UI screen with minimal fields | Navigation, multiple views, styling polish |
| One integration test | Exhaustive test coverage, edge cases |
| Basic error handling | Comprehensive error handling, retries |

### Step 3: Validate it is thin enough

Ask: *"Could one developer or agent build this in 1-2 days?"* If not, strip further.

---

## Examples

### E-commerce Application

**Tracer bullet:** View one product page with real data from the database.

| Layer | What to build |
|---|---|
| Database | `products` table with `id`, `name`, `price` — one seed row |
| Backend | `GET /products/:id` returning JSON |
| Frontend | Product page component fetching from API, rendering name and price |
| Tests | Integration test: seed product → GET endpoint → verify response |
| Deploy | Deploys to staging, product page loads with real data |

**NOT a tracer bullet:** Building the entire product catalog, search, and filtering.

### SaaS Dashboard

**Tracer bullet:** Login and see one real metric.

| Layer | What to build |
|---|---|
| Database | `users` table, `metrics` table — seed data for one metric |
| Backend | `POST /auth/login`, `GET /dashboard/summary` |
| Frontend | Login form → dashboard page with one metric card |
| Tests | Integration test: login → fetch metric → verify render |
| Deploy | Deploys to staging, login works, metric displays |

**NOT a tracer bullet:** Building the full dashboard with all charts, date filters, and export.

### API Platform

**Tracer bullet:** One endpoint returning real data with authentication.

| Layer | What to build |
|---|---|
| Database | `api_keys` table, one domain table — seed data |
| Backend | API key middleware, `GET /api/v1/resource` returning JSON |
| Frontend | API key management page (create key, see key) |
| Tests | Integration test: create key → call endpoint with key → verify response |
| Deploy | Deploys to staging, authenticated API call succeeds |

**NOT a tracer bullet:** Building all API endpoints, rate limiting, and usage analytics.

### CLI Tool

**Tracer bullet:** One command that reads input and produces output.

| Layer | What to build |
|---|---|
| Database | Config file or SQLite store with one setting |
| Backend | CLI argument parser, one command handler |
| Frontend | Terminal output formatting for one command |
| Tests | Integration test: run command → verify output |
| Deploy | Publishes to npm/brew/binary, `tool --version` works |

**NOT a tracer bullet:** Building all commands, plugin system, and interactive mode.

---

## Common Mistakes

### Making Phase 0 too fat

**Symptom:** Phase 0 has 5+ API endpoints, 3+ database tables, or takes more than 2 days.

**Fix:** Ask *"What is the ONE user action I need to prove end-to-end?"* — then remove everything else.

### Skipping a layer

**Symptom:** Phase 0 has database + API but no frontend, or API + frontend but no tests.

**Fix:** Every layer must be present. If the project has no frontend (e.g., a library), replace the frontend layer with "consumer example" — a script or test that exercises the API as a real consumer would.

### Confusing tracer bullet with foundation

**Symptom:** Phase 0 sets up auth, logging, error handling, and CI/CD but does not implement any user-visible flow.

**Fix:** Foundation work belongs in Phase 0 only if it is needed by the tracer bullet flow itself. If auth is needed for the tracer bullet, include minimal auth. If it is not, defer it to Phase 1.

### Gold-plating the tracer bullet

**Symptom:** Phase 0 includes form validation, error states, loading skeletons, and responsive design.

**Fix:** The tracer bullet proves the path works. Polish comes in later phases. Use hardcoded values, default styles, and minimal error handling.

---

## Tracer Bullet Verification

After completing Phase 0, verify:

- [ ] A user can perform the representative action end-to-end
- [ ] Data flows from UI → API → database → API → UI
- [ ] The integration test passes in CI
- [ ] The application deploys to a staging/preview environment
- [ ] The team agrees: "the architecture works, we can build on this"
