---
name: analytics-tracking
description: >-
  Analytics tracking design and implementation for software growth systems. Use
  when defining event schemas, setting up GA4/GTM tracking, validating funnel
  instrumentation, or fixing measurement gaps for experiments and GTM. Triggers:
  analytics setup, event tracking, GA4, GTM, conversion tracking, UTM strategy,
  instrumentation audit, measurement plan.
---

# Analytics Tracking

Create trustworthy instrumentation that supports decision-making.

## Workflow

1. Define business questions and required metrics.
2. Design event taxonomy and naming standards.
3. Map events to funnel stages and properties.
4. Implement tracking and QA.
5. Publish dashboards and data contracts.
6. Monitor drift and fix broken instrumentation.

## Required Inputs

- Product funnel and key conversion events
- Tracking stack (GA4, GTM, CDP, warehouse)
- Current naming conventions and known issues
- Owners for implementation and QA

## Progressive Disclosure Map

- Event taxonomy: [references/event-library.md](references/event-library.md)
- GA4 guidance: [references/ga4-implementation.md](references/ga4-implementation.md)
- GTM guidance: [references/gtm-implementation.md](references/gtm-implementation.md)
- Tracking plan template: [references/tracking-plan-template.md](references/tracking-plan-template.md)

## Execution Protocol

### 1) Define Measurement Scope

- One objective metric per initiative
- Supporting diagnostic metrics and guardrails
- Explicit segment and timeframe definitions

### 2) Standardize Instrumentation

- Consistent event names and property types
- Required context properties for attribution
- Explicit versioning for schema changes

### 3) QA and Monitoring

- Validate events in staging and production
- Check deduplication and sequencing
- Add broken-event alerts and drift checks

## Output Contract

Deliver:

1. Tracking plan document
2. Event/property schema contract
3. QA checklist and monitoring setup

## Quality Gates

- Every KPI maps to specific events.
- Events and properties have clear definitions.
- QA is completed before experiment launch.
- Known instrumentation gaps have owners and ETA.

## Anti-Patterns

- Tracking everything without clear decision use.
- Inconsistent event naming across teams.
- Launching tests without verified instrumentation.

