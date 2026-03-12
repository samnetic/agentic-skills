---
name: schema-markup
description: >-
  Structured data design and validation for search visibility. Use when adding,
  fixing, or auditing JSON-LD/schema.org markup for product, article, FAQ,
  breadcrumb, organization, or software pages. Triggers: schema markup,
  structured data, JSON-LD, rich results, schema.org, search snippets,
  structured data validation.
license: MIT
metadata:
  author: samnetic
  version: "1.0"
---

# Schema Markup

Implement structured data that is valid, relevant, and maintainable.

---

## Core Principles

| Principle | Meaning |
|---|---|
| **Accuracy over coverage** | Only mark up what is genuinely present and visible on the page. Misleading markup violates Google guidelines and risks manual actions. |
| **JSON-LD preferred** | Use JSON-LD over Microdata or RDFa. It is decoupled from HTML, easier to maintain, and recommended by Google. |
| **Rendered validation** | Always validate against the rendered DOM, not raw HTML. CSR/SSR hydration can strip or alter script tags. |
| **One source of truth** | Generate schema from the same data source that drives visible content. Never hardcode values that drift from reality. |
| **Minimal viable markup** | Include required and recommended properties. Omit optional fields you cannot keep current. Empty or stale fields hurt more than missing ones. |
| **Test in production context** | Rich result eligibility depends on page quality, site reputation, and markup together. Validate end-to-end. |

---

## Workflow

1. Map page types to appropriate schema types.
2. Draft JSON-LD payloads with required properties.
3. Validate against schema and rich-result expectations.
4. Deploy and verify rendered output.
5. Monitor errors/warnings and iterate.

## Required Inputs

- Page inventory and content models
- CMS/template constraints
- Search goals (rich results, knowledge graph clarity)
- Validation tools available

---

## Schema Type Decision Tree

```
What page are you marking up?
|
+-- Company / Brand homepage or about page?
|   -> Organization + WebSite (with SearchAction if site search exists)
|
+-- Blog post or news article?
|   -> Article or BlogPosting (use NewsArticle only for news publishers)
|   -> Always include author, datePublished, dateModified
|
+-- Product or pricing page?
|   -> Product + Offer
|   -> Include AggregateRating if reviews exist
|   -> SoftwareApplication for SaaS landing pages
|
+-- FAQ section on any page?
|   -> FAQPage (questions must be visible on page)
|   -> Do NOT use if questions are user-generated
|
+-- Step-by-step tutorial or guide?
|   -> HowTo (include totalTime and step list)
|
+-- Local storefront or office?
|   -> LocalBusiness (include address, geo, openingHours)
|
+-- Event, webinar, or conference?
|   -> Event (include startDate, eventAttendanceMode, offers)
|
+-- Any page with breadcrumb navigation?
|   -> BreadcrumbList (always — low effort, high value)
|
+-- Multiple entity types on one page?
    -> Use @graph to combine types with @id cross-references
```

**Key trade-offs by schema type:**

| Type | Rich Result | Effort | Maintenance |
|---|---|---|---|
| **BreadcrumbList** | Breadcrumb trail in SERP | Low | Low (auto-generated from URL) |
| **FAQPage** | Expandable FAQ in SERP | Low | Medium (content must stay in sync) |
| **Article** | Headline, image, date in SERP | Medium | Low (CMS-driven) |
| **Product** | Price, rating, availability stars | Medium | High (prices/stock change) |
| **HowTo** | Step carousel in SERP | Medium | Medium |
| **Event** | Date, location, ticket info | Medium | High (dates expire) |
| **LocalBusiness** | Map pack, hours, address | High | High (hours/locations change) |
| **Organization** | Knowledge panel | Low | Low (rarely changes) |

---

## Concrete Example: Article with BreadcrumbList

A typical blog post page should include both Article and BreadcrumbList markup combined via `@graph`:

```json
{
  "@context": "https://schema.org",
  "@graph": [
    {
      "@type": "Article",
      "@id": "https://example.com/blog/schema-guide#article",
      "headline": "Complete Guide to Schema Markup",
      "image": "https://example.com/images/schema-guide-hero.jpg",
      "datePublished": "2025-09-10T08:00:00+00:00",
      "dateModified": "2025-11-02T14:30:00+00:00",
      "author": {
        "@type": "Person",
        "name": "Jane Doe",
        "url": "https://example.com/authors/jane"
      },
      "publisher": {
        "@id": "https://example.com/#organization"
      },
      "description": "Learn how to implement JSON-LD schema markup for rich results.",
      "mainEntityOfPage": {
        "@type": "WebPage",
        "@id": "https://example.com/blog/schema-guide"
      }
    },
    {
      "@type": "Organization",
      "@id": "https://example.com/#organization",
      "name": "Example Company",
      "url": "https://example.com",
      "logo": {
        "@type": "ImageObject",
        "url": "https://example.com/logo.png"
      }
    },
    {
      "@type": "BreadcrumbList",
      "itemListElement": [
        { "@type": "ListItem", "position": 1, "name": "Home", "item": "https://example.com" },
        { "@type": "ListItem", "position": 2, "name": "Blog", "item": "https://example.com/blog" },
        { "@type": "ListItem", "position": 3, "name": "Schema Guide" }
      ]
    }
  ]
}
```

Place this inside a `<script type="application/ld+json">` tag in the `<head>`.

---

## Concrete Example: Injecting JSON-LD in Next.js App Router

```html
<!-- app/blog/[slug]/page.tsx — use Next.js metadata API or a direct script tag -->
<script
  type="application/ld+json"
  dangerouslySetInnerHTML={{ __html: JSON.stringify(schema) }}
/>
```

For frameworks without a `<Head>` component, append the script tag at the end of `<body>`. Search engines parse JSON-LD regardless of position.

---

## Execution Protocol

### 1) Type Mapping

- Choose schema types that match real page intent.
- Use the decision tree above to select the right type.
- Avoid over-marking unrelated entities.
- Prefer `@graph` when a page represents multiple entities.

### 2) Payload Authoring

- Include required and recommended fields per Google's documentation.
- Keep data consistent with visible page content.
- Use `@id` references to link related entities instead of duplicating data.
- Generate markup from the same data source that renders the page.

### 3) Validation

- Validate JSON syntax first (malformed JSON silently fails).
- Run through Google Rich Results Test on the live URL.
- Validate rendered output, not static fetch only.
- Check Schema.org validator for spec compliance beyond Google requirements.
- Re-check after template/CMS updates or framework upgrades.

### 4) Deployment and Monitoring

- Deploy to staging and validate before production.
- Monitor Google Search Console > Enhancements for errors and warnings.
- Set up alerts for new validation errors after deployments.
- Review rich result impressions in Search Console Performance report.

---

## Progressive Disclosure Map

| Reference | When to read |
|---|---|
| [references/schema-examples.md](references/schema-examples.md) | When you need copy-paste JSON-LD templates for a specific schema type (Organization, Product, FAQ, HowTo, Event, etc.) |
| [references/schema-validation-checklist.md](references/schema-validation-checklist.md) | Before deploying markup to production, or when auditing existing structured data for correctness |

---

## Output Contract

Deliver:

1. JSON-LD payload spec per page type
2. Validation report with pass/fail status per page
3. Rollout and monitoring checklist
4. Owner assignment for ongoing maintenance

---

## Quality Gates

- Markup matches visible user-facing content.
- Required fields are complete and current.
- JSON-LD is syntactically valid (parseable by `JSON.parse`).
- Rich Results Test passes for every target page type.
- Rendered validation is confirmed (not just source HTML).
- `@id` references resolve correctly within `@graph`.
- Ownership exists for ongoing maintenance.

---

## Pre-Launch Checklist

- [ ] Page inventory is complete with schema type mapped to each template.
- [ ] JSON-LD uses `@graph` with `@id` cross-references where multiple types coexist.
- [ ] Every required property per Google's docs is present.
- [ ] All values match the visible page content exactly (no hidden or misleading data).
- [ ] Markup is generated dynamically from the same data source as the page, not hardcoded.
- [ ] JSON is syntactically valid (`JSON.parse` does not throw).
- [ ] Google Rich Results Test passes on the live rendered URL.
- [ ] Schema.org Validator shows no errors for the chosen types.
- [ ] Staging validation is complete before production deploy.
- [ ] Google Search Console Enhancements panel shows no new errors post-deploy.
- [ ] Monitoring owner is assigned and alert thresholds are configured.
- [ ] Review cadence is set (quarterly minimum) to catch stale or drifted markup.

---

## Anti-Patterns

| Anti-Pattern | Why it hurts |
|---|---|
| Adding schema types solely to "hack" ranking | Violates Google guidelines; risks manual actions and markup removal |
| Hardcoding stale values in templates | Prices, dates, and ratings drift from reality, causing rich result removal |
| Declaring success without rendered validation | CSR apps may not inject JSON-LD until hydration; static checks miss this |
| Marking up content not visible on the page | Google treats this as spammy structured data; can trigger penalties |
| Using Microdata or RDFa for new implementations | Harder to maintain, mixes with HTML, harder to debug than JSON-LD |
| Duplicating entity data instead of using `@id` | Creates inconsistencies when data changes; bloats payload size |
| Skipping `dateModified` on articles | Google prefers fresh content signals; missing modification dates reduce SERP features |

---

## Common Validation Tools

| Tool | Use for |
|---|---|
| [Google Rich Results Test](https://search.google.com/test/rich-results) | Primary validation; shows which rich results are eligible |
| [Schema.org Validator](https://validator.schema.org/) | Spec compliance beyond Google-specific rules |
| [Google Search Console > Enhancements](https://search.google.com/search-console) | Ongoing monitoring of errors and warnings at scale |
| Browser DevTools > Elements | Quick check that JSON-LD script tag is present in rendered DOM |
| `JSON.parse()` in console | Catch syntax errors before deploying |
