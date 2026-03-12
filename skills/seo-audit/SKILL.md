---
name: seo-audit
description: >-
  Technical and on-page SEO audit workflow for software websites. Use when
  diagnosing ranking issues, crawl/indexation problems, metadata quality, site
  architecture weaknesses, or Core Web Vitals performance blockers. Triggers:
  SEO audit, technical SEO, indexation, crawlability, ranking drop, metadata
  review, search performance, site health check.
---

# SEO Audit

Run audits that produce prioritized, implementation-ready actions.
Every audit should leave the site measurably healthier in search.

---

## Core Principles

| Principle | Meaning |
|---|---|
| **Evidence over opinion** | Every finding needs reproducible proof — a URL, a screenshot, a metric |
| **Crawl before content** | Fix crawlability and indexation blockers before touching titles or copy |
| **Measure before and after** | Define baseline metrics upfront; validate fixes with the same metrics |
| **Prioritize by business impact** | A broken canonical on the money page outweighs a missing alt on a blog image |
| **Render like a bot** | Check what Googlebot actually sees, not what your browser renders |
| **One root cause, many symptoms** | Trace duplicate findings back to the shared underlying issue |

---

## Decision Tree: Choosing the Audit Approach

```
What triggered the audit?
├─ Sudden ranking drop?
│  ├─ After a deployment or migration?
│  │  └─ Migration audit → focus on redirects, canonicals, robots.txt changes
│  ├─ After a Google algorithm update?
│  │  └─ Content quality audit → focus on E-E-A-T, thin content, intent match
│  └─ Unknown cause?
│     └─ Full audit → crawl + technical + on-page (start at Foundations)
├─ New site or pre-launch review?
│  └─ Technical baseline audit → crawlability, indexation config, Core Web Vitals
├─ Specific page underperforming?
│  └─ Page-level audit → metadata, internal links, SERP intent analysis
└─ Routine health check?
   └─ Crawl + coverage delta → compare against last audit baseline
```

---

## Workflow

1. Define business goals, pages, and keyword scope.
2. Check crawlability and indexation foundations.
3. Audit technical performance and page experience.
4. Audit on-page metadata and content intent alignment.
5. Prioritize issues by impact and implementation effort.
6. Publish remediation backlog with owners and deadlines.

---

## Required Inputs

- Target pages and target query clusters
- Search Console and analytics access (if available)
- CMS/platform constraints
- Recent migrations or structural changes

---

## Quick-Reference Commands

### Crawl and indexation checks

```bash
# Fetch a page as Googlebot and inspect rendered HTML
curl -sA "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)" \
  "https://example.com/page" | head -100

# Validate robots.txt syntax and test a URL against it
npx robots-txt-guard test https://example.com/robots.txt /pricing

# Generate a sitemap diff against a previous crawl
diff <(curl -s https://example.com/sitemap.xml | grep '<loc>' | sort) \
     previous-sitemap-urls.txt

# Run Lighthouse CI for Core Web Vitals (performance + SEO categories)
npx lighthouse https://example.com \
  --only-categories=performance,seo \
  --output=json --output-path=./audit-report.json

# Check HTTP status codes for a list of URLs
while IFS= read -r url; do
  status=$(curl -o /dev/null -s -w "%{http_code}" "$url")
  printf "%s %s\n" "$status" "$url"
done < urls.txt
```

### Structured data validation

```bash
# Fetch rendered HTML and extract JSON-LD blocks
curl -sA "Googlebot" "https://example.com/page" \
  | grep -oP '<script type="application/ld\+json">.*?</script>' \
  | sed 's/<[^>]*>//g' | jq .

# Validate structured data via Google Rich Results Test API (requires API key)
curl -s "https://searchconsole.googleapis.com/v1/urlTestingTools/mobileFriendlyTest:run" \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com/page"}'
```

### Meta tag inspection

```html
<!-- Minimal SEO-complete head for a product page -->
<head>
  <title>Product Name — Short Benefit | Brand</title>
  <meta name="description" content="120-155 char description matching search intent." />
  <link rel="canonical" href="https://example.com/product" />
  <meta name="robots" content="index, follow" />
  <meta property="og:title" content="Product Name — Short Benefit" />
  <meta property="og:description" content="Matching description for social sharing." />
  <meta property="og:image" content="https://example.com/og-product.jpg" />
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "Product",
    "name": "Product Name",
    "description": "Product description.",
    "offers": { "@type": "Offer", "price": "49", "priceCurrency": "USD" }
  }
  </script>
</head>
```

---

## Execution Protocol

### 1) Foundations

- `robots.txt` and sitemap validity
- Index coverage anomalies (Search Console "Pages" report)
- Canonical consistency (self-referencing canonicals, cross-domain canonicals)
- `noindex` / `nofollow` misuse — check both meta tags and HTTP headers
- Redirect chains and loops (max 2 hops)
- `hreflang` correctness for multi-language sites

### 2) Technical Layer

- Core Web Vitals (LCP < 2.5s, INP < 200ms, CLS < 0.1)
- Rendering blockers — JavaScript-dependent content visible to Googlebot
- Mobile parity and accessibility basics (viewport, tap targets, font size)
- Internal linking depth and orphan pages (every page reachable in <= 3 clicks)
- HTTPS enforcement, mixed content warnings
- HTTP status codes: no soft 404s, proper 410 for removed content

### 3) On-Page Layer

- Title and meta description uniqueness and intent match
- Header hierarchy (`h1` unique per page, logical `h2`-`h3` nesting)
- Content clarity — above-the-fold content addresses the primary query
- Structured data completeness (validate with rendered HTML, not source)
- Image optimization — `alt` text, modern formats (WebP/AVIF), lazy loading
- Internal anchor text — descriptive, not "click here"

### 4) Prioritization

- Severity = business impact x confidence x effort inverse
- Focus first on indexation and crawl blockers
- Group related symptoms under a single root cause
- Tag each issue: `P0-critical`, `P1-high`, `P2-medium`, `P3-low`

---

## SEO Audit Checklist

### Crawlability and Indexation

- [ ] `robots.txt` does not block important pages or resources
- [ ] XML sitemap is valid, submitted, and matches canonical URLs
- [ ] All target pages return `200` status codes
- [ ] Canonical tags are self-referencing and consistent
- [ ] No unintended `noindex` directives (meta tag or HTTP header)
- [ ] Redirect chains are two hops or fewer
- [ ] Search Console index coverage shows no unexpected exclusions

### Technical Performance

- [ ] LCP under 2.5 seconds on mobile (75th percentile)
- [ ] INP under 200 milliseconds on mobile (75th percentile)
- [ ] CLS under 0.1 on mobile (75th percentile)
- [ ] No render-blocking JavaScript hiding primary content from crawlers
- [ ] HTTPS enforced site-wide with no mixed content
- [ ] Mobile viewport and tap targets configured correctly

### On-Page Quality

- [ ] Every target page has a unique `<title>` under 60 characters
- [ ] Every target page has a unique `<meta description>` between 120-155 characters
- [ ] Each page has exactly one `<h1>` that includes the primary keyword
- [ ] Header hierarchy is logical (`h1` > `h2` > `h3`, no skipped levels)
- [ ] Structured data validates in Google Rich Results Test (rendered check)
- [ ] Images have descriptive `alt` text and use modern formats
- [ ] Internal links use descriptive anchor text

### Content and Intent

- [ ] Each target page clearly addresses the primary search intent
- [ ] No thin pages (substantial, useful content on every indexed URL)
- [ ] No keyword cannibalization (one primary keyword per page)
- [ ] Above-the-fold content is relevant, not just navigation or ads

### Post-Audit

- [ ] Remediation backlog created with owner and deadline per issue
- [ ] Baseline metrics recorded (rankings, traffic, CWV scores)
- [ ] Follow-up audit scheduled (30-60 days after fixes deployed)

---

## Output Contract

Deliver:

1. Prioritized remediation backlog (spreadsheet or ticket board)
2. Owner + ETA for each high-severity issue
3. Before/after measurement plan with specific KPIs
4. Executive summary: top 3 wins, top 3 risks, estimated traffic impact

---

## Quality Gates

- Top issues include reproducible evidence (URL, screenshot, metric).
- Prioritization logic is explicit and uses the severity formula.
- Recommendations are implementation-ready (exact fix, not vague advice).
- Measurement plan defines expected outcomes with numeric targets.
- Structured data findings are validated against rendered HTML, not source.

---

## Anti-Patterns

- Reporting long issue lists without priority or grouping.
- Declaring schema missing from non-rendered fetches only.
- Mixing strategic content advice with urgent technical blockers.
- Auditing desktop-only when Google uses mobile-first indexing.
- Recommending keyword changes without verifying search intent.
- Treating all pages equally instead of focusing on revenue-critical URLs.

---

## Progressive Disclosure Map

| Reference | Topic | When to read |
|---|---|---|
| [references/ai-writing-detection.md](references/ai-writing-detection.md) | AI-generated content detection and E-E-A-T implications | When auditing content quality or investigating a "helpful content" ranking drop |
| [references/seo-remediation-template.md](references/seo-remediation-template.md) | Remediation backlog template and severity definitions | When building the final deliverable after audit findings are complete |
