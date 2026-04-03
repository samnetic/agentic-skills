# CI/CD Security Pipeline & Tooling — Detailed Reference

## Table of Contents

- [CI/CD Security Pipeline](#cicd-security-pipeline)
- [Pre-commit Hook (Local Secret Scanning)](#pre-commit-hook-local-secret-scanning)
- [Pipeline Stage Summary](#pipeline-stage-summary)
- [Automated Scanning Commands](#automated-scanning-commands)
- [GitHub Advanced Security](#github-advanced-security)
- [Security Tooling Overview](#security-tooling-overview)
- [Subresource Integrity (SRI)](#subresource-integrity-sri)
- [Security.txt (RFC 9116)](#securitytxt-rfc-9116)
- [Security Review Report Template](#security-review-report-template)

---

## CI/CD Security Pipeline

A comprehensive security pipeline integrates multiple scanning tools at different stages of the development lifecycle.

```yaml
# .github/workflows/security-pipeline.yml
name: Security Pipeline

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  release:
    types: [published]

permissions:
  contents: read
  security-events: write
  pull-requests: write

jobs:
  # Stage 1: Secret scanning — catch leaked credentials before merge
  secret-scanning:
    name: Secret Scanning (Gitleaks)
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0              # Full history for scanning all commits in PR
      - uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

  # Stage 2: SAST — static analysis for vulnerability patterns
  sast:
    name: SAST (Semgrep)
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: returntocorp/semgrep-action@v1
        with:
          config: >-
            p/default
            p/owasp-top-ten
            p/nodejs
            p/typescript
            p/react
          generateSarif: "1"
      - uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: semgrep.sarif

  # Stage 3: Dependency audit — check for known vulnerabilities
  dependency-audit:
    name: Dependency Audit
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - run: npm ci --ignore-scripts
      - run: npm audit --audit-level=high
      - uses: actions/dependency-review-action@v4
        if: github.event_name == 'pull_request'
        with:
          fail-on-severity: high
          deny-licenses: GPL-3.0, AGPL-3.0

  # Stage 4: Container scanning — scan built images for vulnerabilities
  container-scanning:
    name: Container Scanning (Trivy)
    runs-on: ubuntu-latest
    if: github.event_name == 'push' || github.event_name == 'release'
    needs: [secret-scanning, sast, dependency-audit]
    steps:
      - uses: actions/checkout@v4
      - name: Build container image
        run: docker build -t ${{ github.repository }}:${{ github.sha }} .
      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: '${{ github.repository }}:${{ github.sha }}'
          format: 'sarif'
          output: 'trivy-results.sarif'
          severity: 'CRITICAL,HIGH'
          exit-code: '1'             # Fail on critical/high
      - uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: trivy-results.sarif

  # Stage 5: DAST — dynamic scanning against staging environment
  dast:
    name: DAST (OWASP ZAP Baseline)
    runs-on: ubuntu-latest
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    needs: [container-scanning]
    steps:
      - uses: actions/checkout@v4
      - name: Deploy to staging
        run: echo "Deploy to staging environment here"
      - name: OWASP ZAP Baseline Scan
        uses: zaproxy/action-baseline@v0.12.0
        with:
          target: 'https://staging.example.com'
          rules_file_name: '.zap/rules.tsv'    # Custom rule config
          fail_action: true                     # Fail on alerts
          allow_issue_writing: false
      - name: Upload ZAP report
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: zap-report
          path: report_html.html

  # Stage 6: SBOM generation — create Software Bill of Materials on release
  sbom:
    name: SBOM Generation
    runs-on: ubuntu-latest
    if: github.event_name == 'release'
    needs: [container-scanning]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - run: npm ci --ignore-scripts
      - name: Generate CycloneDX SBOM
        run: npx @cyclonedx/cyclonedx-npm --output-file sbom.cdx.json
      - name: Generate SPDX SBOM
        uses: anchore/sbom-action@v0
        with:
          format: spdx-json
          output-file: sbom.spdx.json
      - name: Attach SBOMs to release
        uses: softprops/action-gh-release@v2
        with:
          files: |
            sbom.cdx.json
            sbom.spdx.json
```

---

## Pre-commit Hook (Local Secret Scanning)

```bash
# Install gitleaks as pre-commit hook
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.21.2
    hooks:
      - id: gitleaks

# Or install directly:
# brew install gitleaks
# gitleaks protect --staged   # Scan only staged changes
```

---

## Pipeline Stage Summary

| Stage | Tool | Runs On | Catches |
|---|---|---|---|
| **Pre-commit** | Gitleaks | Developer machine | Hardcoded secrets before they reach git |
| **PR — Secret Scan** | Gitleaks Action | Pull request | Secrets in any commit in the PR |
| **PR — SAST** | Semgrep | Pull request | Code-level vulnerabilities (injection, auth bypass) |
| **PR — Dep Audit** | npm audit + Dependency Review | Pull request | Known CVEs in dependencies, license violations |
| **Build — Container** | Trivy | Push to main | OS/library vulnerabilities in container image |
| **Staging — DAST** | OWASP ZAP | After deploy to staging | Runtime vulnerabilities (XSS, CSRF, misconfig) |
| **Release — SBOM** | CycloneDX + Syft | On release publish | Compliance — full dependency inventory for auditing |

---

## Automated Scanning Commands

```bash
# Secret scanning
gitleaks detect --source .                    # Scan for hardcoded secrets
trufflehog filesystem .                       # Alternative scanner

# SAST (Static Application Security Testing)
semgrep scan --config=auto .                  # Multi-language SAST
npx eslint --plugin security .                # ESLint security rules

# Dependency scanning
npm audit --audit-level=high
trivy fs --severity HIGH,CRITICAL .
npx socket optimize                           # Socket.dev — supply chain risk analysis

# Supply chain security
npx @cyclonedx/cyclonedx-npm --output-file sbom.json  # Generate SBOM
cosign sign --yes myregistry.io/app:latest             # Sign container image
cosign verify myregistry.io/app:latest                 # Verify signature

# Docker security
trivy image myapp:latest
docker scout cves myapp:latest
hadolint Dockerfile

# Infrastructure scanning
trivy config .                                # Scan Dockerfiles, Terraform, K8s manifests
```

---

## GitHub Advanced Security

### Secret Protection

```yaml
# .github/workflows/security.yml
# Secret scanning is automatically enabled for public repos
# Push protection blocks commits containing detected secrets

# For private repos, enable via repository settings:
# Settings > Code security and analysis > GitHub Advanced Security
```

**Secret scanning push protection**: Blocks `git push` if known secret patterns are detected (API keys, tokens, passwords). Developers must either remove the secret or explicitly bypass (which is logged).

### Code Security

```yaml
# Enable CodeQL code scanning
name: CodeQL Analysis
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  analyze:
    runs-on: ubuntu-latest
    permissions:
      security-events: write
    steps:
      - uses: actions/checkout@v4
      - uses: github/codeql-action/init@v3
        with:
          languages: javascript-typescript
      - uses: github/codeql-action/analyze@v3

# Copilot Autofix: Automatically generates fix suggestions for code scanning alerts
# Enable in repository settings > Code security and analysis
```

### Dependency Review

```yaml
# Block PRs that introduce vulnerable dependencies
- uses: actions/dependency-review-action@v4
  with:
    fail-on-severity: high
    deny-licenses: GPL-3.0, AGPL-3.0   # Block copyleft if needed
```

---

## Security Tooling Overview

| Tool | Purpose | Integration |
|---|---|---|
| **GitHub Secret Scanning** | Detect leaked secrets in code | Built-in, push protection blocks commits |
| **GitHub CodeQL** | SAST — find vulnerabilities in code | GitHub Actions, Copilot Autofix for remediation |
| **GitHub Dependency Review** | Block vulnerable deps in PRs | GitHub Actions |
| **Socket.dev** | Detect typosquatting, install scripts, supply chain risks | GitHub App, npm CLI plugin |
| **Gitleaks** | Secret scanning (self-hosted alternative) | Pre-commit hook, CI |
| **Semgrep** | Multi-language SAST with custom rules | CI, IDE plugins |
| **Trivy** | Container, filesystem, IaC scanning | CI, Docker |

---

## Subresource Integrity (SRI)

When loading scripts or stylesheets from CDNs or third-party origins, use SRI to ensure the file hasn't been tampered with. The browser verifies the hash before executing.

```html
<!-- Generate hash: openssl dgst -sha384 -binary script.js | openssl base64 -A -->
<script
  src="https://cdn.example.com/lib@4.0.0/dist/lib.min.js"
  integrity="sha384-oqVuAfXRKap7fdgcCY5uykM6+R9GqQ8K/uxy9rx7HNQlGYl1kPzQho1wx4JwY8wC"
  crossorigin="anonymous"
></script>

<link
  rel="stylesheet"
  href="https://cdn.example.com/css@2.0/styles.css"
  integrity="sha384-Gn5384xqQ1aoWXA+058RXPxPg6fy4IWvTNh0E263XmFcJlSAwiGgFAW/dAiS6JXm"
  crossorigin="anonymous"
/>
```

**Key rules:**
- Always include `crossorigin="anonymous"` with SRI — required for CORS-enabled requests
- Use `sha384` (recommended) or `sha512` — `sha256` is minimum
- Update hashes when upgrading CDN dependency versions
- If the hash doesn't match, the browser blocks the resource entirely (fail-safe)
- Generate with: `shasum -b -a 384 file.js | awk '{ print $1 }' | xxd -r -p | base64`
- Or use https://www.srihash.org/ for quick generation

---

## Security.txt (RFC 9116)

Place a `security.txt` file at `/.well-known/security.txt` to help security researchers report vulnerabilities responsibly.

```text
# /.well-known/security.txt
Contact: mailto:security@example.com
Contact: https://example.com/security/report
Expires: 2026-12-31T23:59:59.000Z
Encryption: https://example.com/.well-known/pgp-key.txt
Acknowledgments: https://example.com/security/hall-of-fame
Preferred-Languages: en
Canonical: https://example.com/.well-known/security.txt
Policy: https://example.com/security/policy
```

**Required fields:**
- `Contact` — email, URL, or phone for reporting vulnerabilities
- `Expires` — MUST be present, forces periodic review (max 1 year recommended)

**In Next.js:** Place in `public/.well-known/security.txt` or serve via route handler.

---

## Security Review Report Template

```markdown
# Security Review Report

## Scope
- Application: [name]
- Version/Commit: [hash]
- Review Date: [date]
- Reviewer: [name]

## Findings Summary
| # | Severity | Title | Status |
|---|----------|-------|--------|
| 1 | Critical | SQL injection in search endpoint | Open |
| 2 | High | Missing rate limiting on auth | Open |

## Detailed Findings

### Finding 1: SQL Injection in Search Endpoint
- **Severity**: Critical
- **Location**: `src/routes/search.ts:42`
- **Description**: User input interpolated directly into SQL query
- **Evidence**: [code snippet, request/response]
- **Impact**: Full database read/write access
- **Remediation**: Use parameterized query
- **References**: OWASP A05, CWE-89
```
