---
name: software-architecture
description: >-
  System design & software architecture expertise. Use when designing new systems, evaluating
  architecture trade-offs, creating Architecture Decision Records (ADRs), choosing between
  monolith/microservices/modular monolith/cell-based architecture, applying Domain-Driven
  Design (DDD), defining bounded contexts, designing event-driven systems, implementing
  CQRS/event sourcing, hexagonal/clean/onion architecture, applying SOLID/GRASP principles,
  drawing C4 model diagrams, capacity planning, defining non-functional requirements (NFRs),
  designing APIs at the system level (REST, GraphQL federation, tRPC, gRPC-Web), evaluating
  CAP theorem trade-offs, planning data consistency strategies, designing for fault tolerance
  and resilience, AI-native architecture (RAG, vector databases, LLM gateways, agent
  orchestration, inference infrastructure), edge computing patterns, durable workflow
  orchestration (Temporal, Inngest), data mesh, zero-trust architecture, platform engineering
  (IDP, golden paths), sustainability/green computing, evolutionary architecture with fitness
  functions, or performing architecture reviews.
  Triggers: architecture, system design, ADR, DDD, bounded context, microservices, monolith,
  CQRS, event sourcing, hexagonal, clean architecture, C4 model, scalability, resilience,
  distributed systems, high availability, tech stack selection, NFR, RAG, vector database,
  LLM gateway, AI architecture, edge computing, data mesh, zero trust, platform engineering,
  cell-based architecture, tRPC, GraphQL federation, durable workflows, Temporal, Inngest.
---

# Software Architecture Skill

Design systems that are simple enough to understand, resilient enough to survive production,
and flexible enough to evolve. Favor the simplest architecture that meets current requirements
with clear extension points for known future needs.

---

## Core Principles

| Principle | Meaning |
|---|---|
| **Start simple, evolve intentionally** | Monolith first. Extract when you have evidence, not speculation |
| **Make decisions reversible** | Prefer strategies that allow course correction |
| **Explicit over implicit** | Document trade-offs. No "it's obvious" allowed |
| **Fitness functions** | Every NFR must be measurable and automated |
| **Conway's Law is real** | System structure will mirror team structure. Design both together |
| **Delay decisions responsibly** | Defer irreversible choices until the last responsible moment |
| **Reduce coupling, increase cohesion** | Components should have one reason to change |

---

## Workflow: Every Architecture Task

```
1. UNDERSTAND   → Clarify the problem, constraints, quality attributes
2. EXPLORE      → Identify candidate patterns and evaluate trade-offs
3. DECIDE       → Select approach, document rationale in an ADR
4. COMMUNICATE  → C4 diagrams, component specs, integration contracts
5. VALIDATE     → Fitness functions, threat model, failure mode analysis
```

---

## Step 1 — Understand Requirements

### Functional Requirements
- Core user journeys and use cases
- Data entities and relationships
- Integration points (third-party APIs, legacy systems)
- Multi-tenancy needs

### Non-Functional Requirements (Quality Attributes)

| Quality Attribute | Key Questions | Measurable Target Example |
|---|---|---|
| **Performance** | P95 latency? Throughput? | API: <200ms P95, 1000 rps |
| **Scalability** | Expected growth? Traffic patterns? | 10x users in 12 months |
| **Availability** | Uptime SLA? RPO/RTO? | 99.9% (8.7h downtime/year) |
| **Security** | Auth model? Compliance? Data sensitivity? | SOC 2 Type II, GDPR |
| **Maintainability** | Team size? Skill level? Deployment frequency? | Deploy daily, 4-dev team |
| **Observability** | Debug production issues? Audit trail? | Distributed tracing, structured logs |
| **Cost** | Budget constraints? Hosting model? | <$500/mo cloud spend |

### Constraint Identification
- **Technical**: Existing tech stack, legacy integrations, team expertise
- **Business**: Budget, timeline, regulatory, compliance
- **Organizational**: Team size, geographic distribution, autonomy level

---

## Step 2 — Architecture Pattern Selection

### Decision Tree: System Architecture Style

```
How many teams will own this system?
├── 1 team (≤8 people)
│   ├── Simple CRUD app? → Modular Monolith
│   ├── Complex domain? → Modular Monolith with DDD
│   └── Event-heavy (notifications, workflows)? → Modular Monolith + Event Bus
├── 2-4 teams
│   ├── Clear bounded contexts? → Modular Monolith → extract services at boundaries
│   └── Different scaling needs per domain? → Service-Oriented Architecture
└── 5+ teams
    ├── Independent deployment critical? → Microservices
    └── Shared deployment OK? → Modular Monolith (still works at scale)
```

### Pattern Trade-offs Matrix

| Pattern | When To Use | When NOT To Use | Complexity |
|---|---|---|---|
| **Modular Monolith** | Single team, shared DB, fast iteration | Different scaling per module needed | Low |
| **Microservices** | Independent teams, independent deploy/scale | Small team, shared data model | Very High |
| **Cell-Based** | Blast-radius isolation, multi-region, high scale | Small system, single region, <3 teams | Very High |
| **Event-Driven** | Loose coupling, async workflows, audit trail | Simple CRUD, strong consistency needed | High |
| **CQRS** | Read/write models diverge significantly | Simple CRUD with uniform access | Medium-High |
| **Hexagonal/Ports+Adapters** | Testability critical, multiple I/O adapters | Rapid prototyping, simple scripts | Medium |
| **Serverless** | Sporadic traffic, event processing, cost-sensitive | Latency-sensitive, long-running processes | Medium |
| **Edge-First** | Global users, low-latency reads, personalization | Heavy write workloads, complex transactions | Medium-High |
| **Monolith** | MVP, prototype, single developer | Multiple teams, independent scaling | Lowest |

### The Modular Monolith (Default Choice)

```
src/
├── modules/
│   ├── users/                  # Bounded context
│   │   ├── api/                # HTTP handlers (inbound port)
│   │   ├── domain/             # Business logic, entities, value objects
│   │   ├── application/        # Use cases / services
│   │   ├── infrastructure/     # DB repos, external APIs (outbound adapters)
│   │   └── index.ts            # Public API — ONLY this is importable by other modules
│   ├── orders/
│   │   ├── api/
│   │   ├── domain/
│   │   ├── application/
│   │   ├── infrastructure/
│   │   └── index.ts
│   └── shared/                 # Cross-cutting: auth, logging, events
├── infrastructure/             # Framework glue, server setup
└── main.ts
```

**Rules:**
- Modules communicate ONLY through their public API (index.ts exports)
- No direct database access across module boundaries
- Shared module has no business logic — only utilities
- Each module owns its database tables (logical separation)
- Cross-module communication via events for async, direct calls for sync

---

## Step 3 — Architecture Decision Records (ADRs)

### ADR Template

```markdown
# ADR-{NNN}: {Decision Title}

## Status
Proposed | Accepted | Deprecated | Superseded by ADR-XXX

## Context
What is the issue that we're seeing that is motivating this decision?
What are the forces at play (technical, business, political)?

## Decision
What is the change that we're proposing and/or doing?

## Consequences

### Positive
- What becomes easier?

### Negative
- What becomes harder?
- What new risks are introduced?

### Risks & Mitigations
| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|

## Alternatives Considered

### Option A: {name}
- Pros: ...
- Cons: ...
- Why rejected: ...

### Option B: {name}
- Pros: ...
- Cons: ...
- Why rejected: ...
```

**ADR Rules:**
1. Write an ADR for every significant architectural decision
2. ADRs are immutable once accepted — supersede, don't edit
3. Store in `docs/adr/` in the repo
4. Number sequentially: `0001-use-postgresql.md`
5. Include rejected alternatives with reasoning

---

## Step 4 — C4 Model Communication

### Level 1 — System Context
Who uses the system? What external systems does it interact with?

```
[User] → [Our System] → [Payment Provider]
                       → [Email Service]
                       → [Analytics Platform]
```

### Level 2 — Container Diagram
What are the deployable units? (Web app, API, database, message queue, etc.)

```
[SPA/Web App] → [API Server] → [PostgreSQL]
                             → [Redis Cache]
                             → [Message Queue] → [Worker Service]
```

### Level 3 — Component Diagram
Inside a container, what are the major structural blocks?

### Level 4 — Code (optional)
Class/module level. Usually the code IS the documentation at this level.

**Use Mermaid for all diagrams** — version-controllable, diff-friendly.

---

## Step 5 — Validate

### Failure Mode Analysis

For every external dependency and critical path:

| Component | Failure Mode | Impact | Detection | Mitigation |
|-----------|-------------|--------|-----------|------------|
| Database | Connection pool exhausted | All writes fail | Pool metrics alert | Circuit breaker, queue writes |
| Payment API | Timeout >5s | Checkout blocked | Latency P99 alert | Async with retry, idempotency keys |
| Redis cache | Eviction storm | DB overload | Cache hit ratio alert | Cache-aside with fallback to DB |

### Fitness Functions (Automated Architecture Tests)

```
# Dependency direction: modules don't import from sibling internals
lint-rule: "modules/users/** cannot import from modules/orders/infrastructure/**"

# Response time: API P95 < 200ms
load-test: k6 run --threshold 'http_req_duration{p(95)<200}' script.js

# Deployment: can deploy independently
ci-check: each module's tests pass without other modules running

# Coupling: no circular dependencies
tool: madge --circular --extensions ts src/
```

---

## Domain-Driven Design (DDD) Quick Reference

### Strategic DDD

| Concept | Definition |
|---|---|
| **Bounded Context** | A boundary within which a model is consistent and terms have specific meaning |
| **Ubiquitous Language** | Shared vocabulary between devs and domain experts within a bounded context |
| **Context Map** | How bounded contexts relate: Shared Kernel, Customer-Supplier, Anti-Corruption Layer |
| **Subdomain** | Core (competitive advantage), Supporting (necessary but not differentiating), Generic (buy/outsource) |

### Tactical DDD

| Building Block | Purpose | Rule |
|---|---|---|
| **Entity** | Has identity, mutable over time | Identified by ID, not attributes |
| **Value Object** | Defined by attributes, immutable | No ID. Equality by value. Always valid |
| **Aggregate** | Cluster of entities with consistency boundary | One Aggregate Root. Transactional boundary |
| **Domain Event** | Something that happened in the domain | Past tense: `OrderPlaced`, `PaymentReceived` |
| **Repository** | Collection-like interface for aggregates | One repo per aggregate root |
| **Domain Service** | Logic that doesn't belong to a single entity | Stateless. Operates on multiple aggregates |
| **Application Service** | Orchestrates use cases | Thin. Delegates to domain layer |

### Aggregate Design Rules
1. Protect business invariants within aggregate boundaries
2. Design small aggregates (prefer single entity + value objects)
3. Reference other aggregates by ID only (not object reference)
4. Use eventual consistency between aggregates
5. One transaction = one aggregate

---

## Distributed Systems Patterns

### CAP Theorem Practical Guide

```
Need strong consistency + availability?
├── Single region: PostgreSQL with synchronous replication
├── Multi-region: Accept higher latency OR partition tolerance trade-off
└── AP system needed? → Eventually consistent with conflict resolution (CRDTs, last-write-wins)
```

### Key Patterns

| Pattern | Use Case | Implementation |
|---|---|---|
| **Circuit Breaker** | Prevent cascade failures | Open after N failures, half-open to probe recovery |
| **Retry with Backoff** | Transient failures | Exponential backoff + jitter. Max 3 retries |
| **Saga** | Distributed transactions | Orchestration (central coordinator) or Choreography (events) |
| **Idempotency** | Safe retries | Idempotency key in request header, dedup on server |
| **Bulkhead** | Isolate failure blast radius | Separate thread pools/connections per dependency |
| **Rate Limiter** | Protect resources | Token bucket or sliding window at API gateway |
| **CQRS** | Separate read/write scaling | Write to primary, read from replicas/projections |
| **Event Sourcing** | Full audit trail, temporal queries | Store events, derive state. Snapshots for performance |
| **Outbox Pattern** | Reliable event publishing | Write event to outbox table in same transaction, poll+publish |

---

## AI-Native Architecture

### Decision Tree: Do You Need AI/LLM Integration?

```
Does your feature require natural language understanding, generation, or search?
├── Yes
│   ├── Structured data lookup? → Traditional DB queries, NOT LLM
│   ├── Semantic search over unstructured content? → RAG architecture
│   ├── Multi-step reasoning with tool use? → AI agent orchestration
│   ├── Content generation with domain knowledge? → RAG + fine-tuned prompts
│   └── Real-time conversation? → Streaming LLM with context management
└── No → Don't add AI. Seriously.
```

### RAG (Retrieval Augmented Generation) Architecture

```
[User Query]
    ↓
[Embedding Model] → query vector
    ↓
[Vector Database] → top-K relevant chunks
    ↓
[Prompt Assembly] → system prompt + retrieved context + user query
    ↓
[LLM] → grounded response
    ↓
[Post-processing] → citation extraction, safety filters, caching
```

**RAG Component Decisions:**

| Component | Options | Trade-offs |
|---|---|---|
| **Embedding model** | OpenAI `text-embedding-3-small`, Cohere `embed-v4`, local (BAAI/bge) | Cost vs. latency vs. privacy. Local = no data leaves your infra |
| **Vector database** | pgvector (PostgreSQL), Qdrant, Pinecone, Weaviate, Chroma | pgvector = simplest (reuse existing PG). Dedicated = better at scale |
| **Chunking strategy** | Fixed-size, semantic, document-structure-aware | Smaller chunks = precision. Larger = context. Overlap prevents boundary loss |
| **Retrieval** | Dense (vector), sparse (BM25), hybrid (both) | Hybrid consistently outperforms single-method retrieval |
| **Reranking** | Cross-encoder reranker after initial retrieval | Adds ~100ms latency but significantly improves relevance |

**pgvector Decision Matrix — When to Stay vs. When to Graduate:**

| Factor | pgvector (stay) | Dedicated vector DB (graduate) |
|---|---|---|
| Vectors | <5M embeddings | >5M embeddings |
| Query pattern | Combined SQL + vector search | Pure vector similarity at scale |
| Ops team | Small, already runs PostgreSQL | Can operate another stateful service |
| Filtering | Complex metadata filters with joins | Simple metadata pre-filtering |
| Updates | Frequent upserts alongside relational data | Batch-oriented ingestion |

### Embedding Pipeline Architecture

```
[Source Data] → [Extractor] → [Chunker] → [Embedding Model] → [Vector DB]
     │              │             │              │                  │
     │         PDF/HTML/MD    Semantic or     Batch or          Upsert with
     │         extraction     structural      streaming         metadata
     │
     └── Change Detection: only re-embed modified content (hash comparison)
```

**Rules:**
- Store chunk text alongside embeddings — you will need it for debugging
- Track embedding model version per chunk — re-embed on model upgrade
- Implement content hashing to avoid re-embedding unchanged content
- Use background jobs (Inngest/Temporal) for embedding pipelines, not request-time

### LLM Gateway / Proxy Pattern

```
[Application Code]
    ↓
[LLM Gateway] ← single integration point
    ├── Rate limiting & cost controls
    ├── Request/response logging (PII-filtered)
    ├── Model routing (GPT-4o for complex, Haiku for simple)
    ├── Fallback chains (primary model → fallback model)
    ├── Caching (semantic cache for repeated queries)
    ├── Prompt versioning & A/B testing
    └── Usage tracking & cost attribution per team/feature
    ↓
[LLM Providers] → OpenAI, Anthropic, local models, etc.
```

**Implementation options:** LiteLLM (open-source proxy), Portkey, Helicone, or custom gateway.

**Key rule:** Application code should never call LLM providers directly. Always go through the gateway.

### AI Agent Orchestration Patterns

| Pattern | Description | When To Use |
|---|---|---|
| **Single agent + tools** | One LLM with access to functions/APIs | Simple automation, <5 tools |
| **Router agent** | Classifies intent, delegates to specialized agents | Multi-domain system, clear task categories |
| **Pipeline (chain)** | Sequential agents, each transforms output | Document processing, data enrichment |
| **Orchestrator-worker** | Central planner dispatches to worker agents | Complex multi-step tasks, parallel execution |
| **Evaluator-optimizer** | Generator + critic loop until quality threshold met | Content generation, code writing |

**Agent reliability rules:**
1. Every tool call must be idempotent
2. Set hard limits: max iterations, max tokens, max cost per request
3. Log full agent traces (input, reasoning, tool calls, output)
4. Use durable execution (Temporal/Inngest) for multi-step agents — LLM calls fail
5. Human-in-the-loop for destructive actions (deletes, payments, external emails)

### Architecture for AI Workloads

**Model Serving Patterns:**

| Pattern | When To Use | Implementation |
|---|---|---|
| **API-based (hosted)** | Prototyping, variable load, no GPU infra | OpenAI/Anthropic APIs behind LLM gateway |
| **Self-hosted inference** | Data privacy, predictable cost at scale, custom models | vLLM, TGI on GPU instances behind load balancer |
| **Edge inference** | Latency-critical, offline-capable | ONNX Runtime, TFLite on device |
| **Batch inference** | Periodic bulk processing, non-real-time | Scheduled jobs, Temporal workflows, spot instances |

**Prompt Management:**
- Version prompts like code — store in repo or prompt registry
- Separate prompt templates from application logic
- A/B test prompt variants with evaluation metrics
- Include few-shot examples in retrieval, not hardcoded in prompts
- Monitor prompt drift: same input, different output over time (model updates)

---

## Edge Computing Patterns

### Decision Tree: Edge vs. Origin

```
Where should this logic run?
├── Needs database writes or transactions? → Origin server
├── Auth token validation / JWT verification? → Edge (fast, close to user)
├── A/B testing / feature flags? → Edge (no round-trip to origin)
├── Personalization with cached data? → Edge + KV store
├── Geolocation-based routing/content? → Edge (has geo headers)
├── API with complex business logic? → Origin server
├── Static asset serving / ISR? → CDN / Edge cache
└── Global low-latency reads? → Edge + distributed data (Turso, KV)
```

### Edge Architecture Components

```
[User] → [CDN / Edge Network]
              ├── Edge Functions (Cloudflare Workers, Vercel Edge)
              │     ├── Auth validation
              │     ├── Request routing
              │     ├── A/B testing
              │     └── Response transformation
              ├── Edge KV Store (Cloudflare KV, Vercel Edge Config)
              ├── Edge Database (Turso/LibSQL, Neon serverless driver)
              └── Cache (stale-while-revalidate pattern)
              ↓ (only when needed)
         [Origin Server] → [Primary Database]
```

**Edge data locality rules:**
- Read-heavy, latency-sensitive data → replicate to edge (Turso, Cloudflare D1)
- Write-heavy data → origin server with optimistic UI updates
- Session/auth tokens → edge KV with short TTL
- Never put write-primary databases at the edge — conflict resolution is painful

**Framework fit:**
| Framework | Edge Runtime | Best For |
|---|---|---|
| **Hono** | Native (built for edge) | APIs, lightweight servers, multi-runtime |
| **Next.js** | Edge + Node hybrid | Full-stack apps with selective edge rendering |
| **Remix** | Cloudflare Workers adapter | Full-stack with progressive enhancement |
| **Astro** | Cloudflare/Vercel edge adapters | Content-heavy sites with islands of interactivity |

---

## Modern Event-Driven Patterns

### CloudEvents Standard

All events across services should use the CloudEvents envelope (CNCF graduated project):

```json
{
  "specversion": "1.0",
  "id": "unique-event-id",
  "source": "/orders/service",
  "type": "com.myapp.order.placed",
  "subject": "order-123",
  "time": "2025-10-15T12:00:00Z",
  "datacontenttype": "application/json",
  "dataschema": "https://schema.myapp.com/order-placed/v1",
  "data": { "orderId": "123", "total": 99.99 }
}
```

**Why CloudEvents over ad-hoc events:**
- Interoperability across services, languages, and cloud providers
- Standard SDKs for serialization/deserialization in every language
- Protocol bindings for HTTP, Kafka, AMQP, NATS, MQTT
- Aligns with data mesh — events become queryable data products

### Event Mesh Architecture

```
[Service A] ←→ [Event Mesh] ←→ [Service B]
                    ↕
               [Service C]

Event Mesh = intelligent routing layer (not just a broker)
- Dynamic topic-based routing
- Protocol bridging (HTTP → Kafka → MQTT)
- Schema registry integration
- Event filtering and transformation at the mesh level
```

**When event mesh vs. simple broker:**
- Simple broker (Redis Pub/Sub, pg-boss): <5 services, single protocol
- Event mesh (Solace, Confluent, EventBridge): >10 services, multi-protocol, cross-cloud

### Outbox Pattern — Modern Implementation

```
BEGIN TRANSACTION
  INSERT INTO orders (id, ...) VALUES (...);
  INSERT INTO outbox (id, aggregate_type, aggregate_id, event_type, payload)
    VALUES (uuid, 'Order', '123', 'OrderPlaced', '{...}');
COMMIT;

-- Delivery options (pick one):
-- 1. CDC-based (Debezium): streams outbox table changes to Kafka — lowest latency
-- 2. Poll-and-publish: cron polls outbox table, publishes, marks delivered — simplest
-- 3. Listen/Notify (PostgreSQL): NOTIFY on insert, subscriber publishes — middle ground
```

**2025 improvement — Transactional outbox with Inngest/Trigger.dev:**
Instead of managing outbox infrastructure, send events directly to Inngest from your transaction callback. Inngest handles delivery, retries, and fan-out, eliminating the need for outbox polling infrastructure.

---

## Durable Workflow Orchestration

### Decision Tree: When Do You Need Durable Workflows?

```
Does your process span multiple steps with potential failures?
├── Single API call with retry? → Simple retry middleware
├── 2-5 steps, all idempotent? → Inngest (zero-infra, event-driven)
├── Long-running (hours/days), human-in-the-loop? → Temporal (full orchestration)
├── Complex branching, compensations, timers? → Temporal
├── Serverless-first, event-triggered? → Inngest or Trigger.dev
└── Simple cron jobs? → pg-boss, Inngest scheduled functions, or node-cron
```

### Temporal vs. Inngest Decision Matrix

| Factor | Temporal | Inngest |
|---|---|---|
| **Complexity** | High (cluster, workers, task queues) | Low (serverless, no infra) |
| **Best for** | Enterprise orchestration, long-running sagas | Background jobs, event-driven steps |
| **Hosting** | Self-hosted or Temporal Cloud | Managed SaaS or self-hosted |
| **Language support** | Go, Java, Python, TypeScript, .NET | TypeScript, Python, Go |
| **Workflow duration** | Minutes to months | Seconds to days |
| **Debugging** | Temporal Web UI, event history replay | Inngest dashboard, step-level traces |
| **Learning curve** | Steep (deterministic constraints, replay semantics) | Gentle (just functions with steps) |
| **When to pick** | >20 workflow types, compliance needs, long sagas | <20 workflow types, fast iteration, serverless |

### Inngest Pattern (Recommended Starting Point)

```typescript
// Durable function: each step retries independently
inngest.createFunction(
  { id: "process-order" },
  { event: "order/placed" },
  async ({ event, step }) => {
    const validated = await step.run("validate", () =>
      validateOrder(event.data.orderId)
    );
    const payment = await step.run("charge", () =>
      chargePayment(validated.total)
    );
    await step.run("fulfill", () =>
      createShipment(event.data.orderId)
    );
    await step.run("notify", () =>
      sendConfirmation(event.data.email)
    );
  }
);
```

### Temporal Pattern (When You Graduate)

```typescript
// Workflow: deterministic orchestration
async function processOrderWorkflow(orderId: string): Promise<void> {
  const validated = await activities.validateOrder(orderId);
  const payment = await activities.chargePayment(validated.total);
  try {
    await activities.createShipment(orderId);
  } catch {
    await activities.refundPayment(payment.id); // compensation
    throw ApplicationFailure.create({ message: "Shipment failed" });
  }
  await activities.sendConfirmation(validated.email);
}
```

---

## Cell-Based Architecture

### What Is a Cell?

A cell is a self-contained, independently deployable unit that includes all services and data stores needed to handle a subset of traffic. Unlike microservices (which split by function), cells split by workload partition (tenant, region, shard).

```
                    [Global Router / Cell Router]
                   /            |             \
            [Cell A]       [Cell B]       [Cell C]
           Tenants 1-100  Tenants 101-200  Tenants 201-300
           ┌──────────┐   ┌──────────┐   ┌──────────┐
           │ API      │   │ API      │   │ API      │
           │ Workers  │   │ Workers  │   │ Workers  │
           │ Database │   │ Database │   │ Database │
           │ Cache    │   │ Cache    │   │ Cache    │
           │ Queue    │   │ Queue    │   │ Queue    │
           └──────────┘   └──────────┘   └──────────┘
```

### Cell-Based vs. Microservices

| Dimension | Microservices | Cell-Based |
|---|---|---|
| **Split axis** | By function (orders, payments, users) | By workload partition (tenant, region) |
| **Blast radius** | One service down = feature unavailable | One cell down = subset of users affected |
| **Data ownership** | Each service owns its domain tables | Each cell owns a full copy of all schemas |
| **Scaling** | Scale individual services independently | Scale by adding more cells |
| **Cross-cutting changes** | Deploy one service | Deploy to all cells (rolling) |
| **Complexity driver** | Service-to-service communication | Cell routing and data partitioning |

**When to consider cells:**
- You need blast-radius isolation (outage affects only a fraction of users)
- Multi-region with data locality requirements
- Regulatory requirements for data residency
- Already running microservices and hitting coordination overhead
- Real-world adopters: DoorDash, Slack, AWS (availability zones are cells)

**When NOT to use cells:**
- <100K users or <5 teams
- Single region deployment
- The operational cost of running N copies of everything outweighs the benefit

---

## Modern API Patterns

### Decision Tree: API Style Selection

```
Who consumes this API?
├── Same TypeScript monorepo (frontend + backend)?
│   └── tRPC — zero schema, full type inference, RPC-style
├── Multiple clients with different data needs (mobile, web, partner)?
│   └── GraphQL — client-driven queries, federation for multi-team
├── Public API / third-party integrations?
│   └── REST (OpenAPI spec) — universally understood, cacheable
├── Internal service-to-service, high throughput?
│   └── gRPC — binary protocol, streaming, code-gen from .proto
├── Browser client calling internal gRPC services?
│   └── gRPC-Web — gRPC in browser via proxy (Envoy)
└── Mixed? → REST for public, tRPC/GraphQL for internal frontend
```

### API Pattern Trade-offs

| Pattern | Strengths | Weaknesses | Best Fit |
|---|---|---|---|
| **REST** | Universal, cacheable, tooling-rich | Over/under-fetching, versioning burden | Public APIs, CRUD-heavy |
| **tRPC** | Zero schema overhead, full type safety, tiny bundle | TypeScript-only, no API contract for external consumers | TS monorepos |
| **GraphQL** | Client-driven queries, strong typing, federation | Complexity, N+1 risk, caching harder | Multi-client, multi-team |
| **GraphQL Federation** | Compose supergraph from team-owned subgraphs | Operational overhead (gateway, schema registry) | 5+ teams, domain-per-subgraph |
| **gRPC** | Fast binary, streaming, code-gen | Not browser-native, debugging harder | Service-to-service, high-perf |
| **gRPC-Web** | gRPC from browser via Envoy proxy | Extra infrastructure (proxy layer) | Browser client to gRPC backend |

---

## Data Mesh Principles

### Four Principles of Data Mesh

| Principle | What It Means | Architectural Implication |
|---|---|---|
| **Domain ownership** | Teams own their data — both operational and analytical | Each domain publishes data products, not raw tables |
| **Data as a product** | Treat data with product-thinking: SLAs, docs, discoverability | Data products have schemas, owners, quality metrics |
| **Self-serve platform** | Infrastructure team provides tools, not pipelines | Centralized platform for provisioning, ingestion, cataloging |
| **Federated governance** | Global standards, local autonomy | Shared conventions (naming, PII handling) enforced by tooling |

### Data Mesh vs. Traditional Data Architecture

```
Traditional:                    Data Mesh:
[Domain A] → ETL → [Central    [Domain A] → Domain A Data Products
[Domain B] → ETL →  Data       [Domain B] → Domain B Data Products
[Domain C] → ETL →  Warehouse] [Domain C] → Domain C Data Products
                                     ↑              ↑
                                Self-serve data platform (catalog, infra, governance)
```

**When to adopt data mesh:**
- 5+ domains producing data consumed by other domains
- Central data team is a bottleneck
- Domain teams already own their operational databases
- Organization practices DDD with clear bounded contexts

**When NOT to adopt:**
- Small data team (<3 data engineers)
- Single domain / single product
- No organizational appetite for domain teams owning data quality

---

## Zero-Trust Architecture

### Core Principles

| Principle | Application to Software Architecture |
|---|---|
| **Never trust, always verify** | Every request authenticated and authorized, even internal service-to-service |
| **Least-privilege access** | Services get minimum permissions. Time-bound tokens. No standing access |
| **Assume breach** | Design as if the network is compromised. Encrypt in transit AND at rest |
| **Verify explicitly** | Authenticate based on all signals: identity, device, location, behavior |
| **Micro-segmentation** | Network segments per service/workload. No flat internal network |

### Zero-Trust Decision Checklist for Architects

```
For every service boundary, ask:
├── Is service-to-service communication authenticated? (mTLS, service mesh)
├── Are API tokens scoped to minimum required permissions?
├── Is there an identity provider (not shared secrets) for service auth?
├── Are secrets rotated automatically? (Vault, AWS Secrets Manager)
├── Is east-west traffic (internal) encrypted?
├── Are admin/debug endpoints on a separate network?
├── Is production access time-limited and audited? (Just-in-Time access)
└── Can a compromised service escalate to other services? (blast radius)
```

### Implementation Layers

| Layer | Traditional | Zero-Trust |
|---|---|---|
| **Network** | Firewall at perimeter, flat internal | Service mesh (Istio, Linkerd), mTLS everywhere |
| **Identity** | API keys, long-lived tokens | Short-lived JWTs, OIDC, SPIFFE/SPIRE for workload identity |
| **Access control** | Role-based, static permissions | Attribute-based (ABAC), policy-as-code (OPA, Cedar) |
| **Data** | Encrypted at rest | Encrypted at rest + in transit + field-level encryption for PII |
| **CI/CD** | Shared deploy credentials | OIDC federation, ephemeral credentials, signed artifacts |
| **Observability** | Centralized logging | Immutable audit logs, anomaly detection on access patterns |

---

## Platform Engineering

### Internal Developer Platform (IDP) Architecture

```
[Developers]
    ↓ (self-serve portal / CLI / API)
[Internal Developer Platform]
    ├── Service Catalog (Backstage, Port, Cortex)
    │     └── Templates, ownership, docs, API specs, runbooks
    ├── Golden Paths
    │     ├── "Create new service" → scaffold, CI/CD, infra, observability
    │     ├── "Add a database" → provision, configure, connect, backup
    │     └── "Deploy to production" → PR merge → staged rollout
    ├── Infrastructure Abstraction
    │     └── Terraform/Pulumi modules exposed as platform APIs
    ├── Observability Stack
    │     └── Pre-configured dashboards, alerts, SLOs per service
    └── Security & Compliance
          └── Automated scanning, policy enforcement, audit trails
    ↓
[Infrastructure] (cloud, Kubernetes, databases, etc.)
```

### Golden Paths Design Rules

1. **Opinionated by default, escapable by exception** — the happy path covers 80% of use cases
2. **Self-serve** — developers should never file a ticket for standard operations
3. **Encode organizational standards** — naming, tagging, security policies built in
4. **Measurable** — track adoption rate, lead time, developer satisfaction (DORA metrics)
5. **Maintained** — golden paths are products, not one-off scripts. Assign a team

### When to Build an IDP

| Signal | Action |
|---|---|
| Developers spend >30% time on infra/config | Start with golden paths for top 3 workflows |
| 5+ teams, inconsistent tooling across teams | Invest in service catalog + templates |
| "How do I deploy?" is a common question | Standardize deployment as a golden path |
| Security/compliance overhead slows delivery | Encode policies into platform guardrails |
| Single team, simple deployment | NOT yet — premature platform engineering is overhead |

---

## Evolutionary Architecture with Fitness Functions

### Fitness Function Categories

| Category | What It Measures | Example Fitness Function |
|---|---|---|
| **Structural** | Code/module dependencies, coupling | `madge --circular src/` returns 0. No module imports from sibling internals |
| **Performance** | Latency, throughput, resource usage | P95 latency <200ms in load test. Memory <512MB under 1K concurrent users |
| **Security** | Vulnerability exposure, compliance | Zero critical CVEs in `npm audit`. OWASP ZAP scan passes |
| **Operational** | Deployment frequency, MTTR, change failure rate | Deploy in <15 min. Rollback in <5 min |
| **Data integrity** | Schema compatibility, migration safety | Schema migration is backward-compatible (no breaking column drops) |
| **Cost** | Infrastructure spend per transaction | Cost per 1K requests <$0.01. Monthly spend within budget threshold |
| **Sustainability** | Carbon efficiency | Carbon intensity per request tracked. Deferrable jobs run during low-carbon windows |

### Implementing Fitness Functions

```
# CI pipeline fitness functions (run on every PR)
structural:
  - "No circular dependencies: madge --circular --extensions ts src/"
  - "Module boundaries: eslint-plugin-boundaries configured and passing"
  - "Bundle size < 250KB: size-limit check"

performance:
  - "API P95 < 200ms: k6 load test in staging"
  - "Lighthouse score > 90: lighthouse-ci in PR checks"

security:
  - "npm audit --audit-level=critical exits 0"
  - "No secrets in code: gitleaks detect"
  - "Container scan: trivy image --severity CRITICAL"

operational:
  - "Deployment completes in <15 minutes"
  - "Health check returns 200 within 30s of deploy"
  - "Canary: error rate <0.1% for 5 minutes before full rollout"

data:
  - "Migration is backward-compatible: sqlcheck lint on migration files"
  - "No raw SQL in application code: grep check"
```

**Key insight:** Fitness functions are not just tests. They are automated architectural governance. Wire them into CI/CD so architecture degrades only when someone explicitly overrides a check — never silently.

### Evolutionary Architecture Roadmap

```
Phase 1 (Week 1-2):  Add structural fitness functions (circular deps, module boundaries)
Phase 2 (Month 1):   Add performance fitness functions (load tests in CI, bundle size)
Phase 3 (Month 2):   Add security fitness functions (audit, secrets scan, container scan)
Phase 4 (Quarter 2): Add operational fitness functions (deploy time, rollback speed)
Phase 5 (Ongoing):   Review and tighten thresholds quarterly based on production data
```

---

## Sustainability in Architecture (Green Computing)

### Carbon-Aware Architecture Strategies

| Strategy | Description | Implementation |
|---|---|---|
| **Temporal shifting** | Run deferrable workloads when grid carbon intensity is low | Schedule batch jobs using carbon-aware APIs (WattTime, Electricity Maps) |
| **Geographic shifting** | Route workloads to regions with cleaner energy | Multi-region deployment with carbon-weighted routing |
| **Demand shaping** | Reduce work during high-carbon periods | Degrade non-critical features, queue instead of process immediately |
| **Right-sizing** | Eliminate over-provisioned resources | Auto-scaling with scale-to-zero for serverless. Spot instances for batch |
| **Efficient architecture** | Reduce total compute needed | Caching, CDN, edge computing, avoid unnecessary re-computation |

### Sustainability Decision Checklist

```
For every architecture decision, ask:
├── Can this workload be deferred to off-peak/low-carbon windows?
├── Can this computation be cached instead of re-executed?
├── Are resources right-sized or over-provisioned "just in case"?
├── Can this run at the edge (fewer network hops, less data transfer)?
├── Are we using scale-to-zero for intermittent workloads?
├── Is image/asset optimization reducing transfer bytes?
└── Can we measure carbon per request/transaction? (observability)
```

**Practical starting points:**
- Use serverless / scale-to-zero for infrequent workloads (immediate impact)
- Implement aggressive caching — the greenest request is the one you never make
- Compress and optimize assets (images, APIs, payloads)
- Choose cloud regions with higher renewable energy percentage
- Track infrastructure carbon via cloud provider dashboards (AWS Carbon Footprint, GCP Carbon Reporting)

---

## Deep Modules (Ousterhout's "A Philosophy of Software Design")

### The Deep Module Concept

A **deep module** has a simple interface (small surface area) but provides powerful functionality behind it. A **shallow module** has a complex interface relative to the functionality it provides.

```
Deep Module (GOOD):              Shallow Module (BAD):
┌─────────────────┐              ┌─────────────────┐
│  Small Interface │              │ Complex Interface│
│   (2-3 methods)  │              │ (20+ methods,    │
├─────────────────┤              │  many params)    │
│                  │              ├─────────────────┤
│                  │              │                  │
│  Large, Complex  │              │  Thin            │
│  Implementation  │              │  Implementation  │
│                  │              │                  │
│                  │              └─────────────────┘
└─────────────────┘
```

### Evaluation Criteria

| Factor | Deep Module | Shallow Module |
|---|---|---|
| **Interface size** | Few methods, few parameters | Many methods, many parameters |
| **Abstraction** | Hides complexity behind clean API | Leaks implementation details |
| **Information hiding** | Caller doesn't need to know internals | Caller must understand internals |
| **Cognitive load** | Low for users | High for users |
| **Example** | `fs.readFile(path)` | Configuration classes with 30+ setters |
| **Example** | `fetch(url)` | HTTP client requiring manual connection management |

### Applying to Architecture

When designing module boundaries, services, or APIs:

1. **Prefer fewer, deeper modules** over many thin wrapper layers
2. **Pass-through methods are a red flag** — if a method just calls another method with the same params, the abstraction is wrong
3. **Configuration explosion** is a sign of shallow modules — too many knobs = leaking complexity
4. **Default behaviors should be sensible** — deep modules work well out of the box

```typescript
// SHALLOW — caller must know about all options
class EmailService {
  connect(host: string, port: number, tls: boolean): void;
  authenticate(user: string, pass: string): void;
  compose(from: string, to: string, subject: string, body: string, cc?: string, bcc?: string): Message;
  send(message: Message, retries: number, timeout: number): Promise<void>;
  disconnect(): void;
}

// DEEP — simple interface, complexity hidden
class EmailService {
  constructor(config: EmailConfig) {} // one-time setup
  async send(to: string, template: string, data: Record<string, unknown>): Promise<void> {
    // Handles connection, retries, templating, CC/BCC from template config, etc.
  }
}
```

### "Design It Twice" Methodology

Before committing to any design:

1. **Design approach A** — your first instinct
2. **Design approach B** — a fundamentally different approach (not just a variation)
3. **Compare on**: interface simplicity, information hiding, performance, evolvability
4. **Pick the deeper design** — the one with the simpler interface and better information hiding
5. **Optional approach C** — hybrid of best aspects of A and B

This takes ~15 minutes but prevents weeks of refactoring. Apply to: API design, module boundaries, data models, state management approaches.

---

## Anti-Patterns

| Anti-Pattern | Why It's Dangerous | Fix |
|---|---|---|
| **Distributed Monolith** | Microservices with tight coupling = worst of both worlds | Ensure independent deployability or stay monolith |
| **Big Bang Rewrite** | High risk, no incremental value | Strangler Fig pattern: migrate incrementally |
| **Golden Hammer** | Using one pattern for everything | Match pattern to problem. Microservices aren't always the answer |
| **Architecture Astronaut** | Over-engineering for theoretical requirements | YAGNI. Design for known needs + 1 level of flexibility |
| **Shared Database** | Coupling between services, schema changes break everything | Each service owns its data. Sync via events |
| **Chatty Services** | N+1 network calls between services | Aggregate data at source, use batch APIs |
| **No ADRs** | Decisions lost, repeated debates | Document every significant decision |
| **Resume-Driven Architecture** | Choosing tech because it's trendy | Boring technology that works > exciting tech you'll regret |
| **Premature Microservices** | Splitting before understanding domain boundaries | Start monolith, extract when boundaries are clear |
| **Anemic Domain Model** | All logic in services, entities are just data holders | Push behavior into domain objects |

---

## Technology Selection Criteria

When evaluating a technology:

1. **Team familiarity** — Can the team be productive in <2 weeks?
2. **Community & ecosystem** — Active maintenance? Stack Overflow answers? Libraries?
3. **Operational maturity** — Production-proven? Observability tools? Deployment patterns?
4. **Total cost of ownership** — License + hosting + team training + operational overhead
5. **Exit strategy** — How hard to migrate away? Vendor lock-in risk?
6. **Security track record** — CVE history? Responsible disclosure process?

**Default "boring" tech stack for most web applications (2025-2026):**
- Language: TypeScript (Node.js) or Python
- Framework: Next.js (full-stack) | Hono (lightweight API / edge) | Express/Fastify (Node server)
- ORM: Drizzle ORM (type-safe, SQL-close) | Prisma (schema-first, great DX)
- Database: PostgreSQL (primary) | Turso/LibSQL (edge-compatible SQLite for read-heavy/global)
- Cache: Redis / Valkey
- Queue: Inngest / Trigger.dev (durable functions, zero-infra) → pg-boss/Graphile Worker (simple) → RabbitMQ/Kafka (high-throughput streaming)
- Workflows: Inngest (serverless-friendly) | Temporal (complex enterprise orchestration)
- Search: PostgreSQL full-text → Elasticsearch/Meilisearch only when needed
- API: REST (default) | tRPC (TypeScript monorepo, shared types) | GraphQL (multi-client, federated)
- Hosting: Single server with Docker → Kubernetes only when needed
- Edge: Cloudflare Workers / Vercel Edge Functions (when latency-critical globally)

---

## Capacity Planning Template

```
| Metric | Current | 6 Months | 12 Months | Design For |
|--------|---------|----------|-----------|------------|
| DAU | ? | ? | ? | ? |
| RPM (requests/min) | ? | ? | ? | ? |
| Storage growth/month | ? | ? | ? | ? |
| P95 latency target | ? | ? | ? | ? |
| Concurrent connections | ? | ? | ? | ? |
```

Rule: Design for 10x current load. Plan for 100x. Don't build for 100x.

---

## Checklist: Architecture Review

- [ ] Requirements documented (functional + NFRs with measurable targets)
- [ ] Architecture pattern justified with ADR
- [ ] C4 Level 1 and Level 2 diagrams exist
- [ ] Bounded contexts identified and boundaries clear
- [ ] Data ownership defined per component/service (data mesh considered if multi-domain)
- [ ] API style selected with rationale (REST/tRPC/GraphQL/gRPC)
- [ ] Failure modes analyzed with mitigations
- [ ] Security threat model exists (zero-trust principles applied)
- [ ] Scaling strategy documented (vertical first, then horizontal, cells if needed)
- [ ] Deployment strategy defined
- [ ] Edge vs. origin decision documented for latency-sensitive paths
- [ ] Monitoring and alerting plan
- [ ] Cost estimate for infrastructure
- [ ] Team structure aligns with architecture (Conway's Law)
- [ ] Fitness functions defined and automatable (structural, performance, security, operational)
- [ ] Workflow orchestration strategy defined for multi-step processes
- [ ] AI components (if any) use LLM gateway, not direct provider calls
- [ ] Sustainability considered (right-sizing, caching, carbon-aware scheduling for batch)
- [ ] Module interfaces evaluated for depth (small interface, powerful functionality)
- [ ] No pass-through methods (each layer adds real value)
- [ ] "Design It Twice" applied for significant design decisions
- [ ] No premature optimization or over-engineering
