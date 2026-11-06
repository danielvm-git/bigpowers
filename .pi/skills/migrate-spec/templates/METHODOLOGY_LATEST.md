# Methodology — {{project_name}}

The following analytical lenses should inform `plan-work` and `audit-code` sessions.

## Cost of Delay (CD3)

**CD3 = Value / Duration**

Use this lens when:
- Prioritizing epics by business impact
- Assessing the cost of deferring a story
- Making trade-off decisions between scope and schedule

Example: A feature with $10k business value and 5-day delivery window has CD3 = $10k / 5d = $2k/day.

---

## STRIDE (Security Threats)

Structured threat modeling framework for API, auth, and data-handling code.

- **Spoofing:** Can an attacker impersonate a user or service?
- **Tampering:** Can an attacker modify data in transit or at rest?
- **Repudiation:** Can an attacker deny performing an action?
- **Information Disclosure:** Can an attacker access sensitive data?
- **Denial of Service:** Can an attacker disrupt service availability?
- **Elevation of Privilege:** Can an attacker gain admin or elevated access?

Use STRIDE to review `specs/tech-architecture/TECH_STACK_LATEST.md` and spot-check `develop-tdd` for auth/API changes.

---

## F.I.R.S.T (Test Principles)

Verify that all tests in the codebase are:

- **Fast:** Run in under 5 seconds per test
- **Independent:** No shared state or test interdependencies
- **Repeatable:** Same result every run, no flaky timeouts
- **Self-Validating:** Assert on observable outcomes (return values, API responses, UI state)
- **Timely:** Written alongside code (test-first in `develop-tdd`)

Use F.I.R.S.T to review test suites in `audit-code` step.

---

## Optional: Bayesian Updating

<!--
When evidence is ambiguous, use Bayesian reasoning to update your confidence:

P(hypothesis | evidence) = P(evidence | hypothesis) × P(hypothesis) / P(evidence)

Example: "We think this epic has low risk (10% prior). Code review finds 3 SQL injection opportunities. How does that shift our confidence?"

P(high-risk | code-review-findings) = P(findings | high-risk) × P(high-risk) / P(findings)
                                     = 0.7 × 0.1 / 0.15 = 47%

Update: high risk is now more likely than the 10% prior.
-->

---

## Optional: Threat Modeling (OWASP Top 10)

<!--
For projects with sensitive data or external APIs, model threats per OWASP Top 10:

1. **Injection** — Can attackers inject SQL, NoSQL, command shell, LDAP?
2. **Broken Authentication** — Session management, MFA, password handling?
3. **Sensitive Data Exposure** — Encryption, tokenization, data classification?
4. **XML External Entities (XXE)** — XML parsing, file uploads?
5. **Broken Access Control** — Role-based access, scope, delegation?
6. **Security Misconfiguration** — Default credentials, error messages, headers?
7. **Cross-Site Scripting (XSS)** — Untrusted data, sanitization, CSP?
8. **Insecure Deserialization** — Object deserialization, pickle, YAML?
9. **Using Components with Known Vulnerabilities** — Dependencies, versions?
10. **Insufficient Logging & Monitoring** — Audit trails, alerting, incident response?

Document mitigations in `specs/tech-architecture/TECH_STACK_LATEST.md`.
-->

---

## Using This Document

Before starting a phase:
- Read the relevant sections of this document
- In `plan-work`, ensure every task considers the applicable lens
- In `audit-code`, verify that completed work passes the lens checks

Update this document as new analytical frameworks emerge or prove valuable.
