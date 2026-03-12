---
name: security-analysis
description: >-
  Application security analysis, code review, and penetration testing expertise. Use when
  reviewing code for security vulnerabilities, conducting OWASP Top 10 (2025) assessments,
  auditing authentication/authorization (including passkeys/WebAuthn), checking for
  injection attacks (SQL, XSS, CSRF, command injection, prompt injection), reviewing
  secrets management, implementing modern CSP (nonce-based, strict-dynamic),
  configuring security headers (Permissions-Policy, COOP, COEP), auditing dependency
  vulnerabilities and supply chain security (SLSA, SBOM, Sigstore), reviewing JWT
  implementations, implementing input validation, designing secure API endpoints,
  reviewing Docker security, checking for hardcoded credentials, implementing RBAC/ABAC,
  reviewing encryption patterns, conducting threat modeling (STRIDE), assessing AI/LLM
  security risks (OWASP LLM Top 10), or preparing security reports with severity
  classifications.
  Triggers: security, vulnerability, OWASP, injection, XSS, CSRF, SQL injection,
  authentication, authorization, JWT, secrets, CSP, rate limiting, dependency audit,
  penetration test, pentest, CVE, hardcoded credentials, SAST, DAST, threat model,
  STRIDE, encryption, hashing, RBAC, security review, audit, passkeys, WebAuthn,
  supply chain, SLSA, SBOM, prompt injection, LLM security, Permissions-Policy,
  COOP, COEP, Socket.dev, GitHub Advanced Security, API security, session management,
  CORS, CI/CD security pipeline, HMAC, rate limiting, GraphQL security.
---

# Security Analysis Skill

Find vulnerabilities before attackers do. Review code systematically using OWASP
standards, threat modeling, and defense-in-depth. Report with severity, evidence,
and actionable remediation.

---

## Core Principles

| Principle | Meaning |
|---|---|
| **Defense in depth** | Multiple layers of security. Never rely on a single control |
| **Least privilege** | Minimum permissions needed. Default deny |
| **Fail secure** | Errors should deny access, not grant it |
| **Input is hostile** | Validate, sanitize, and escape everything from external sources |
| **Secrets never in code** | Environment variables -> secret managers -> never in git |
| **Log security events** | Auth attempts, access denials, data changes — structured, redacted |

---

## Workflow: Security Review

1. **SCOPE** — Define what is being reviewed and threat model context
2. **AUTOMATED** — Run SAST tools, dependency scanners, secret scanners
3. **MANUAL REVIEW** — Code review against OWASP Top 10 checklist
4. **FINDINGS** — Document each with severity, evidence, and remediation
5. **VERIFY** — Confirm fixes do not introduce new vulnerabilities

### Quick-Reference Commands

```bash
# Secret scanning
gitleaks detect --source .
# SAST
semgrep scan --config=auto .
# Dependency scanning
npm audit --audit-level=high
trivy fs --severity HIGH,CRITICAL .
# Container scanning
trivy image myapp:latest
hadolint Dockerfile
```

---

## Decision Trees

### Choosing a Security Review Approach

```
What's being reviewed?
├─ New feature / PR?
│  └─ Code review + SAST scan (quick, focused)
├─ Entire application?
│  ├─ Pre-launch? → Full audit: SAST + DAST + dependency scan + manual review
│  └─ Periodic review? → OWASP Top 10 checklist + dependency scan + secrets scan
├─ Third-party dependency?
│  └─ Dependency audit: known CVEs + license + maintainer trust + SBOM
├─ Infrastructure / deployment?
│  └─ CIS Benchmarks + misconfig scanning + secrets in env/config
└─ Incident response?
   └─ Triage → Contain → Investigate → Remediate → Post-mortem
```

### Authentication Method Selection

```
Application type?
├─ Server-rendered web app (Next.js, Rails)?
│  └─ Session cookies (HttpOnly, Secure, SameSite=Lax)
├─ SPA + API backend?
│  ├─ Same domain? → Session cookies (BFF pattern)
│  └─ Cross-domain? → Short-lived JWT (access) + HttpOnly cookie (refresh)
├─ Machine-to-machine API?
│  └─ API keys (hashed, rotatable) or OAuth2 client credentials
└─ Mobile app?
   └─ OAuth2 PKCE + secure storage (Keychain / Keystore)
```

---

## OWASP Top 10 (2025) — Summary

> **2025 update**: Focus shifted from symptoms to root causes. SSRF merged into A01. A10 is a new category for exception handling failures. Supply chain expanded from vulnerable components.

| # | Category | Key Defense |
|---|---|---|
| **A01** | Broken Access Control (incl. SSRF) | Authorization on every endpoint; IDOR testing; URL allowlists |
| **A02** | Security Misconfiguration | CSP nonce/strict-dynamic; Permissions-Policy; COOP/COEP; HSTS |
| **A03** | Software Supply Chain Failures | `npm ci`; SBOM; Sigstore; Socket.dev; scoped private packages |
| **A04** | Cryptographic Failures | bcrypt cost 12+; TLS 1.2+; no deprecated algorithms |
| **A05** | Injection (SQL, XSS, command) | Parameterized queries; DOMPurify; `execFile()` not `exec()` |
| **A06** | Insecure Design | STRIDE threat model; rate limiting; MFA |
| **A07** | Authentication Failures | JWT algorithm whitelist; passkeys/WebAuthn; short-lived tokens |
| **A08** | Software and Data Integrity | SRI on CDN scripts; lock files; CI/CD integrity |
| **A09** | Security Logging and Monitoring | Structured logs; mask PII; never log passwords/tokens |
| **A10** | Mishandling of Exceptional Conditions | Fail closed; no empty catch; correlation IDs; no stack traces in prod |

---

## Threat Modeling (STRIDE)

| Threat | Description | Example | Mitigation |
|---|---|---|---|
| **S**poofing | Impersonating another user | Stolen credentials | MFA, strong auth |
| **T**ampering | Modifying data in transit/rest | Modified API request | HTTPS, input validation, checksums |
| **R**epudiation | Denying an action occurred | "I didn't delete that" | Audit logs, immutable logs |
| **I**nformation Disclosure | Exposing sensitive data | Error messages leak DB schema | Error handling, data classification |
| **D**enial of Service | Making system unavailable | Flood of requests | Rate limiting, CDN, auto-scaling |
| **E**levation of Privilege | Gaining unauthorized access | Normal user -> admin | Least privilege, RBAC, input validation |

---

## Finding Severity Classification

| Severity | Criteria | Example | Response Time |
|---|---|---|---|
| **Critical** | Remote code execution, data breach, auth bypass | SQL injection, hardcoded admin password | Immediate |
| **High** | Significant data exposure, privilege escalation | IDOR, XSS with session theft | 24 hours |
| **Medium** | Limited data exposure, requires conditions | CSRF on non-critical action, info disclosure | 1 week |
| **Low** | Minor issues, defense-in-depth | Missing security headers, verbose errors | Sprint |
| **Info** | Best practice recommendations | Using SHA-256 where Argon2 is better | Backlog |

---

## Anti-Patterns

| Anti-Pattern | Why It's Dangerous | Fix |
|---|---|---|
| Secrets in source code | Leaked in git history forever | Environment variables -> secret manager |
| `cors: { origin: '*' }` | Any site can make API calls | Specific origin whitelist |
| `JWT algorithm: 'none'` | Authentication bypass | Whitelist specific algorithms |
| Password in URL/query string | Logged in access logs, browser history | POST body + HTTPS |
| `eval(userInput)` | Remote code execution | Never eval user input |
| Error stack traces in production | Information disclosure | Generic error messages + correlation IDs |
| `SELECT * FROM users WHERE id = ${id}` | SQL injection | Parameterized queries |
| `httpOnly: false` on session cookie | XSS can steal session | Always `httpOnly: true` |
| No rate limiting on login | Brute force attacks | Rate limit: 5/min per IP+email |
| `bcrypt` with cost < 10 | Too fast to brute force | Cost >= 10 minimum, 12+ preferred |
| LLM output in SQL/shell unsanitized | Injection via AI output | Treat LLM output as untrusted input |
| Secrets in system prompts | LLM can leak them via prompt injection | Use environment variables, never embed secrets |
| Empty catch blocks | Errors silently swallowed, failures go undetected | Handle errors explicitly, fail closed |
| `catch { return true }` in auth | Fails open when auth service is unavailable | Always `return false` in auth catch blocks |
| Reflecting Origin header in CORS | Any origin can make credentialed requests | Validate against allowlist |
| API keys without expiry | Leaked keys remain valid forever | Set expiry (90 days), rotate regularly |
| `npm install` in CI | Ignores lockfile, may fetch different versions | Always use `npm ci` |
| No SBOM for releases | Cannot audit deployed dependencies | Generate SBOM with CycloneDX or Syft |
| Missing COOP/COEP headers | Vulnerable to Spectre/side-channel attacks | Set `same-origin` / `require-corp` |
| No `Permissions-Policy` header | Browser features available to third-party scripts | Restrict camera, microphone, geolocation, payment |

---

## Progressive Disclosure Map

| Topic | Reference | When to read |
|---|---|---|
| OWASP Top 10 (2025) full details | `references/owasp-top10-2025.md` | Reviewing code against each OWASP category; need vulnerable/secure code examples and per-category checklists |
| API security, rate limiting, HMAC, GraphQL | `references/api-and-session-security.md` | Designing or auditing API endpoints, webhook verification, GraphQL security, or API key management |
| Session management and cookies | `references/api-and-session-security.md` | Implementing session lifecycle, cookie attributes, token storage decisions, or session timeout logic |
| CORS configuration and debugging | `references/api-and-session-security.md` | Setting up or troubleshooting CORS; reviewing CORS misconfigurations |
| CI/CD security pipeline | `references/cicd-pipeline-and-tooling.md` | Building a security pipeline in GitHub Actions; choosing scanning tools per stage |
| GitHub Advanced Security, CodeQL | `references/cicd-pipeline-and-tooling.md` | Enabling secret scanning push protection, CodeQL analysis, or dependency review |
| SRI, security.txt, report template | `references/cicd-pipeline-and-tooling.md` | Adding subresource integrity, setting up security.txt, or writing a security review report |
| AI/LLM security (OWASP LLM Top 10) | `references/llm-security.md` | Securing LLM integrations; prompt injection defense; output validation; human-in-the-loop patterns |

---

## Checklist: Security Review

### OWASP Top 10 (2025)
- [ ] **A01** Access control on every endpoint, IDOR tested, SSRF mitigated
- [ ] **A02** Security headers (CSP nonce/strict-dynamic, Permissions-Policy, COOP, COEP, HSTS)
- [ ] **A03** Supply chain: deps audited, SBOM generated, artifacts signed, no typosquatting
- [ ] **A04** Passwords hashed with bcrypt/argon2, TLS everywhere, no deprecated algorithms
- [ ] **A05** No SQL injection, no XSS, no command injection, no prompt injection
- [ ] **A06** Rate limiting, account lockout, threat model exists
- [ ] **A07** JWT validated properly, cookies httpOnly+secure+sameSite, passkeys offered
- [ ] **A08** SRI on CDN scripts, dependency lock files, CI/CD integrity
- [ ] **A09** Security events logged (without sensitive data)
- [ ] **A10** Exception handling fails closed, no swallowed errors, no info leaks in errors

### Authentication & Session Management
- [ ] Passkeys/WebAuthn offered as primary authentication
- [ ] MFA available for sensitive operations
- [ ] Session ID regenerated after login and privilege escalation
- [ ] Absolute and idle timeouts enforced
- [ ] Cookies: `HttpOnly`, `Secure`, `SameSite=Lax`, `__Host-` prefix
- [ ] Logout destroys server-side session

### API Security
- [ ] Rate limiting on all endpoints (strict on auth/sensitive)
- [ ] API keys hashed, scoped, with expiry
- [ ] Webhook signatures verified (HMAC, constant-time comparison)
- [ ] GraphQL: depth limiting, cost analysis, introspection disabled in prod
- [ ] Request/response size limits
- [ ] CORS: specific origin allowlist, `Vary: Origin`, no `null` origin

### Supply Chain & CI/CD
- [ ] `npm ci` used in CI (not `npm install`)
- [ ] Socket.dev or equivalent for dependency risk analysis
- [ ] Private packages scoped (`@org/package`)
- [ ] Pre-commit: secret scanning (gitleaks)
- [ ] PR: SAST (semgrep/CodeQL) with SARIF upload
- [ ] PR: dependency audit with fail on high/critical
- [ ] Build: container image scanning (trivy)
- [ ] Release: SBOM generation (CycloneDX + SPDX)

### AI/LLM Security
- [ ] Prompt injection defenses in place (input filtering, structured prompts)
- [ ] LLM output treated as untrusted (sanitized before SQL/HTML/shell)
- [ ] Human-in-the-loop for destructive AI-driven actions
- [ ] No secrets embedded in LLM system prompts

### General
- [ ] No secrets in source code (gitleaks clean)
- [ ] Error messages don't leak internals
- [ ] File uploads validated (type, size, scanned)
- [ ] API responses don't include unnecessary fields
- [ ] SRI hashes on all CDN-loaded scripts and stylesheets
- [ ] `/.well-known/security.txt` exists with Contact and Expires fields
