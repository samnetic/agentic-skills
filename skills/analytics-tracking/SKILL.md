---
name: analytics-tracking
description: >-
  Analytics tracking design and implementation for software growth systems. Use
  when defining event schemas, setting up GA4/GTM tracking, validating funnel
  instrumentation, or fixing measurement gaps for experiments and GTM. Triggers:
  analytics setup, event tracking, GA4, GTM, conversion tracking, UTM strategy,
  instrumentation audit, measurement plan.
license: MIT
metadata:
  author: samnetic
  version: "1.0"
---

# Analytics Tracking

Create trustworthy instrumentation that supports decision-making.
Every tracked event must answer a business question -- if it does not,
it is noise that erodes data trust and wastes engineering effort.

---

## Core Principles

| Principle | Meaning |
|---|---|
| **Question-first instrumentation** | Never add tracking without a written business question it answers. "What will we decide differently?" must have a clear answer |
| **Single source of truth** | One canonical event schema, one naming convention, one tracking plan document. Duplicated definitions cause drift |
| **Validate before launch** | No experiment or feature ships until its events fire correctly in staging. Broken instrumentation is worse than no instrumentation |
| **Minimal viable tracking** | Track the fewest events that answer your questions. Over-tracking inflates cost, slows pages, and overwhelms analysts |
| **Attribution is a first-class citizen** | UTM params, referrer, session/user identity, and consent state must be captured consistently on every conversion event |
| **Schema versioning** | Event contracts change over time. Version them explicitly so downstream consumers can handle transitions |

---

## Workflow

```
1. DEFINE    → Business questions and required metrics
2. DESIGN    → Event taxonomy, naming standards, property schemas
3. MAP       → Events to funnel stages, KPIs, and segments
4. IMPLEMENT → Tracking code, GTM tags, data layer pushes
5. QA        → Validate in staging + production, dedup checks
6. PUBLISH   → Dashboards, data contracts, team documentation
7. MONITOR   → Drift detection, broken-event alerts, coverage audits
```

**Why this order matters:**
- You cannot measure what you have not defined
- You cannot trust data you have not validated
- You cannot act on dashboards built from broken events

---

## Decision Tree: Choosing Your Analytics Approach

Use this tree when starting a new tracking initiative or re-evaluating an existing setup.

```
Is this a new product/feature or fixing existing tracking?
├── NEW product/feature
│   ├── Do you have a written measurement plan?
│   │   ├── YES → Proceed to event taxonomy design (Step 2)
│   │   └── NO  → Start with business questions (Step 1)
│   ├── What is the tracking stack?
│   │   ├── GA4 only → Use gtag.js or GTM with GA4 event tags
│   │   ├── GA4 + CDP (Segment, RudderStack) → Instrument via CDP SDK, forward to GA4
│   │   └── Warehouse-first (BigQuery, Snowflake) → Instrument via CDP, replicate to warehouse
│   └── Client-side or server-side?
│       ├── Marketing pages, funnels → Client-side (GTM or gtag.js)
│       ├── Transactional events (purchase, subscription) → Server-side (Measurement Protocol)
│       └── Both → Hybrid: client for UI interactions, server for conversions
├── FIXING existing tracking
│   ├── Run an instrumentation audit first
│   │   ├── Missing events? → Add to tracking plan and implement
│   │   ├── Duplicate events? → Deduplicate, pick canonical source
│   │   ├── Wrong property values? → Fix at source, add validation
│   │   └── Naming inconsistencies? → Migrate to standard naming, deprecate old names
│   └── Prioritize by business impact: fix conversion events first, engagement events second
```

---

## Required Inputs

- Product funnel and key conversion events
- Tracking stack (GA4, GTM, CDP, warehouse)
- Current naming conventions and known issues
- Owners for implementation and QA
- Consent management approach (GDPR/CCPA requirements)

---

## Progressive Disclosure Map

| Reference | Path | When to read |
|---|---|---|
| Event taxonomy | [references/event-library.md](references/event-library.md) | When designing event names and properties for a new funnel or feature |
| GA4 guidance | [references/ga4-implementation.md](references/ga4-implementation.md) | When configuring GA4 data streams, custom dimensions, conversions, or debugging |
| GTM guidance | [references/gtm-implementation.md](references/gtm-implementation.md) | When setting up tag/trigger/variable structure, data layer, or consent mode in GTM |
| Tracking plan template | [references/tracking-plan-template.md](references/tracking-plan-template.md) | When creating a new tracking plan document or auditing an existing one |

---

## Execution Protocol

### 1) Define Measurement Scope

- One objective metric per initiative (north star for this project)
- Supporting diagnostic metrics and guardrails
- Explicit segment and timeframe definitions
- Document what is intentionally NOT tracked and why

### 2) Standardize Instrumentation

- Consistent event names: `object_action` format (e.g., `form_submitted`, `checkout_started`)
- Required context properties on every event: `user_id`, `session_id`, `timestamp`, `page_url`
- Attribution properties on conversion events: `utm_source`, `utm_medium`, `utm_campaign`, `referrer`
- Explicit versioning for schema changes (e.g., `schema_version: "2.1"`)

### 3) Implement Tracking

Below is a concrete implementation pattern for a type-safe analytics layer
that works with GA4 via gtag.js and can be extended to any downstream destination.

```typescript
// analytics.ts — Type-safe analytics layer with GA4 + extensible destinations

// -- Event schema definitions --
interface BaseProperties {
  page_url: string;
  session_id: string;
  user_id?: string;
  schema_version: string;
}

interface SignupStartedEvent extends BaseProperties {
  event: "signup_started";
  signup_method: "email" | "google" | "github";
  referrer: string;
  utm_source?: string;
  utm_medium?: string;
  utm_campaign?: string;
}

interface CheckoutCompletedEvent extends BaseProperties {
  event: "checkout_completed";
  order_id: string;
  revenue: number;
  currency: string;
  item_count: number;
  payment_method: string;
}

type AnalyticsEvent = SignupStartedEvent | CheckoutCompletedEvent;

// -- Core tracking function --
function track(event: AnalyticsEvent): void {
  // 1. Validate required fields at runtime
  if (!event.page_url || !event.session_id) {
    console.error(`[analytics] Missing required context for ${event.event}`);
    return;
  }

  // 2. Enrich with global context
  const enriched = {
    ...event,
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV ?? "development",
  };

  // 3. Send to GA4 via gtag
  if (typeof window !== "undefined" && window.gtag) {
    const { event: eventName, ...params } = enriched;
    window.gtag("event", eventName, params);
  }

  // 4. Send to server-side destination (CDP, warehouse)
  if (process.env.ANALYTICS_ENDPOINT) {
    fetch(process.env.ANALYTICS_ENDPOINT, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(enriched),
    }).catch((err) => console.error("[analytics] Server send failed:", err));
  }
}

// -- Usage examples --
track({
  event: "signup_started",
  signup_method: "google",
  referrer: document.referrer,
  page_url: window.location.href,
  session_id: getSessionId(),
  schema_version: "1.0",
});

track({
  event: "checkout_completed",
  order_id: "ord_abc123",
  revenue: 49.99,
  currency: "USD",
  item_count: 3,
  payment_method: "stripe",
  page_url: window.location.href,
  session_id: getSessionId(),
  user_id: getCurrentUserId(),
  schema_version: "1.0",
});
```

**Key patterns in this implementation:**
- Discriminated union types enforce valid event/property combinations at compile time
- Runtime validation catches missing context before sending
- Single `track()` entry point fans out to multiple destinations
- Schema version travels with every event for downstream compatibility

### 4) QA and Monitoring

- Validate events in staging and production (GA4 DebugView, GTM Preview mode)
- Check deduplication: same user action must not fire the same event twice
- Check sequencing: funnel events must fire in expected order
- Add broken-event alerts: monitor for missing events, null properties, sudden volume drops
- Run weekly drift checks: compare actual events against tracking plan

---

## Output Contract

Deliver:

1. **Tracking plan document** — KPI-to-event mapping, event contracts, attribution policy
2. **Event/property schema contract** — typed definitions with version, required/optional fields
3. **QA checklist and monitoring setup** — staging validation results, production alert rules
4. **Dashboard or report** — at minimum one dashboard showing funnel conversion rates from tracked events

---

## Quality Gates

- Every KPI maps to one or more specific events with documented properties
- Events and properties have clear written definitions in the tracking plan
- QA is completed in staging before experiment or feature launch
- Known instrumentation gaps have assigned owners and resolution ETAs
- Consent state is respected: no tracking fires before user consent where required
- Event volume is monitored: sudden drops or spikes trigger alerts

---

## Anti-Patterns

| Anti-Pattern | Why It Hurts | Better Approach |
|---|---|---|
| Track everything, decide later | Inflates costs, slows pages, overwhelms analysts | Start from business questions, track only what answers them |
| Inconsistent naming across teams | Breaks dashboards, makes cross-team analysis impossible | Enforce a single naming convention in the tracking plan |
| Launching tests without verified instrumentation | Experiment results are unreliable, decisions are wrong | QA gate: no launch until events verified in staging |
| Client-side only for revenue events | Ad blockers, network failures cause data loss | Server-side tracking for all conversion/revenue events |
| No schema versioning | Breaking changes silently corrupt downstream pipelines | Version every event schema, document migration path |
| Copy-pasting tracking code per page | Drift, duplication, maintenance burden | Centralized analytics module (see implementation above) |

---

## Checklist

Use this checklist when planning, implementing, or auditing analytics tracking.

### Planning
- [ ] Business questions documented for each tracked event
- [ ] KPI-to-event mapping completed in tracking plan
- [ ] Event naming convention defined and shared with all teams
- [ ] Attribution strategy documented (UTM policy, session identity, conversion windows)
- [ ] Consent requirements identified (GDPR, CCPA, ePrivacy)

### Implementation
- [ ] Event schema typed with required and optional properties
- [ ] Schema version included on every event payload
- [ ] Global context (session_id, page_url, timestamp) attached automatically
- [ ] Conversion events fire server-side (not only client-side)
- [ ] Data layer pushes verified for GTM-based implementations
- [ ] Consent mode configured: no tracking before user consent

### QA
- [ ] Events fire in expected sequence in staging environment
- [ ] Required properties are populated (no nulls or empty strings)
- [ ] No duplicate events for a single user action
- [ ] GA4 DebugView shows correct event names and parameters
- [ ] GTM Preview mode confirms correct tag firing and variable values
- [ ] Cross-browser testing completed (Chrome, Firefox, Safari, mobile)

### Post-Launch Monitoring
- [ ] Dashboard shows funnel conversion rates from tracked events
- [ ] Alerts configured for missing events or sudden volume changes
- [ ] Weekly drift check scheduled: actual events vs. tracking plan
- [ ] Data reconciliation: dashboard totals match raw event counts
- [ ] Tracking plan updated when events are added, changed, or deprecated
