# Countable Story Format

The canonical format for stories and bug-fix specs that need to be **countable** — i.e., readable by automated counters that score scope, sizing, and non-functional coverage. Every spec-producing skill in bigpowers writes output in this format.

This is a structural contract. Counters key off the exact section names and order. Section omissions are not equivalent to "no content here" — they make the spec uncountable. Use `Not applicable` instead.

---

## Hard rules

1. **Every section must be present.** Empty sections are written as `Not applicable` with a one-line reason. Deleting a section caps maturity at 3.
2. **Section names and order are fixed.** Do not rename, merge, or reorder. Counters do not infer location.
3. **Sections 14, 15, 16 are tagged `*NFR*`** in their heading. The NFR ratio = (§14 + §15 + §16 content) / total content. The tag must be present even when the section is `Not applicable`.
4. **Sizing uses Fibonacci only.** XS=1, S=2, M=3, L=5, XL=8. Any other value is invalid.
5. **Acceptance criteria are Gherkin only** (`Scenario / Given / When / Then`) and live in §17.
6. **Acceptance criteria must cover the main flow (§5) plus every alternative/exception listed in §6.** One scenario per branch, minimum.
7. **Multiple occurrences of the same dimension are listed separately**, each with its own one-line rationale. Do not collapse.

## Maturity rubric (self-score in the header)

| Score | Label | Definition |
|------|-------|------------|
| 1 | Napkin | Only §1, §2, §17 populated. |
| 2 | Sketch | §1–§6 populated; data model implicit. |
| **3** | **Countable** | **§1–§16 populated. Counter runs cleanly. Wording may still be loose.** |
| 4 | Refined | §1–§20 populated. Gherkin covers every business rule. Open questions tracked but non-blocking. |
| 5 | Implementation-ready | All sections final. Data model precise enough for codegen. No open questions. References complete. |

**Sprint commitment gate:** maturity ≥ 4 recommended. Anything below 3 is blocked from sprint commit unless risk is explicitly accepted.

---

## Header block (mandatory)

```
STORY KEY: <PROJECT-NNN>
TITLE:     <short imperative title>
TYPE:      Story | Spike | Bug | Enabler
PARENT:    <epic key or N/A>
STATUS:    Draft | Ready for refinement | Refined | Counted | In sprint
AUTHOR:    <name>           DATE: <YYYY-MM-DD>
MATURITY:  <self-score 1-5>
SIZE:      XS | S | M | L | XL   (Fibonacci 1/2/3/5/8)
```

`SIZE` is optional at maturity 3; required at maturity 4+.

---

## The 20 sections

Headings appear verbatim, including the numbers.

### 1. Business narrative

Two to four paragraphs of plain business prose. No solution language. No `As a / I want` phrasing — that belongs in §2. Describe the situation, the friction, and the desired outcome from the business point of view.

### 2. Value statement

A single line:
```
As a <actor>, I want <capability>, so that <outcome>.
```
Retained for portfolio-level skim. One line, no expansion.

### 3. Actors and permissions

List of actors and what they are allowed to do. Mark each as `internal | external | system`.

### 4. Trigger and preconditions

What event starts this flow. What must be true before it can run.

### 5. Main flow and business logic

Numbered steps describing the happy path. Decision points are explicit. Include the line `Interruption point: <where the flow can be paused/resumed or N/A>`.

### 6. Alternative flows and exceptions

Numbered list of every branch and every error path. Each entry must be referenced by a Gherkin scenario in §17.

### 7. Interface elements

```
Context: new | existing
Static elements:  <list>
Dynamic elements: <list>
```
Max five elements per cluster. If more, split into clusters.

### 8. Domain model

Entities touched, entities created, relationships changed. Reference `specs/CONTEXT.md` and `specs/UBIQUITOUS_LANGUAGE.md` where applicable.

### 9. Integrations and boundaries

Each integration tagged `perennial | ethereal` and `direction: in | out | both`.

### 10. Background processes

Each tagged `event | scheduled | manual+scheduled | external`.

### 11. Notifications

One entry per notification: channel, recipient, trigger event.

### 12. Audit and logging

Audited entities and the audit fields captured.

### 13. Solution variabilities

For each parameter: source (`config | tenant | feature flag | role`) and behaviour per value.

### 14. Quality attributes *NFR*

Concrete service-level targets: p95 latency, uptime, scale ceiling, reliability. Numbers only — no adjectives.

### 15. Security and compliance *NFR*

AuthN method, AuthZ model, data classification, applicable regulations, controls in place.

### 16. UX and accessibility *NFR*

WCAG level, i18n scope, supported modalities, branding constraints.

### 17. Acceptance criteria

Gherkin scenarios:
```
Scenario: <name>
  Given <precondition>
  When  <action>
  Then  <outcome>
```
At least one scenario for the main flow (§5) and one per branch in §6.

### 18. Out of scope

Explicit non-goals. Phrased as full sentences, not single words.

### 19. Open questions

```
- <question> — owner: <name>, needed by: <YYYY-MM-DD>
```
A non-empty §19 caps maturity at 3.

### 20. References

Links to design docs, RFCs, ADRs, prior stories, datasets, prototypes.

---

## Bug-fix specs (bugs/BUG-*.md)

Bug fixes use the same header block and the same 20 sections. The minimum required for "Countable" on a bug fix:

- §1 — describe actual vs. expected behavior and reproduction.
- §5 — the verified root-cause flow (output of the 4-phase RCA).
- §6 — alternative hypotheses ruled out.
- §17 — Gherkin: at least one regression scenario that fails before the fix and passes after.
- §18 — what this fix deliberately does not change.
- §19 — anything still unverified.

Sections 2–4, 7–16, 20 are marked `Not applicable — <reason>` if the fix is purely behavioral.

---

## Refactors and spikes

Refactors and spikes are not user stories and do **not** use this format. They keep their existing lightweight templates (`specs/REFACTOR.md`, `specs/SPIKE-<name>.md`). They are not counted.

---

## Worked example (minimal countable story)

```
STORY KEY: ACME-101
TITLE:     Self-serve password reset
TYPE:      Story
PARENT:    ACME-EPIC-7
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-05-23
MATURITY:  3
SIZE:      M

### 1. Business narrative
Customer-support handles ~120 password reset tickets per week. Each ticket
costs an average of 8 minutes of agent time. Customers wait 4 hours on
average for a reply. Both numbers are unacceptable for our SLA tier.

### 2. Value statement
As a signed-out customer, I want to reset my own password, so that I can
get back into my account without contacting support.

### 3. Actors and permissions
- Customer (external) — initiate reset, set new password.
- Auth service (system) — issue and verify reset tokens.

### 4. Trigger and preconditions
Trigger: customer clicks "Forgot password" on the sign-in screen.
Precondition: an account with the supplied email exists and is not locked.

### 5. Main flow and business logic
1. Customer submits email.
2. System creates single-use reset token (TTL 30 min).
3. System emails token link to the registered address.
4. Customer opens link and submits new password.
5. System verifies token, updates password hash, invalidates token.
6. System redirects to sign-in.
Interruption point: between steps 3 and 4 (link sent, not yet clicked).

### 6. Alternative flows and exceptions
6a. Email not registered — respond identically to success path (do not leak).
6b. Token expired — display generic "request a new link" message.
6c. Account locked — redirect to support contact page; do not issue token.

### 7. Interface elements
Context: existing.
Static elements: page title, email input, submit button.
Dynamic elements: validation message, throttle banner.

### 8. Domain model
Entities touched: User, AuthCredential. New entity: PasswordResetToken
(user_id, token_hash, expires_at, used_at).

### 9. Integrations and boundaries
- Email provider (perennial, direction: out).

### 10. Background processes
- Token sweeper (scheduled, hourly) — purges expired tokens.

### 11. Notifications
- Email — recipient: registered user — trigger: token issued.

### 12. Audit and logging
Audited entity: PasswordResetToken. Fields: issued_at, used_at, ip.

### 13. Solution variabilities
- TTL (config) — default 30 min, override per tenant.

### 14. Quality attributes *NFR*
- p95 reset-flow end-to-end < 60 s including email delivery.
- 99.9% monthly uptime on the reset endpoint.

### 15. Security and compliance *NFR*
- AuthN: anonymous on request, token-based on completion.
- AuthZ: token bound to user_id; single use.
- Data class: PII (email).
- Controls: rate-limit 5/hour/IP; token-hash at rest.

### 16. UX and accessibility *NFR*
- WCAG 2.1 AA.
- i18n: en, pt-BR at launch.

### 17. Acceptance criteria
Scenario: Happy path
  Given a registered customer at the sign-in screen
  When  the customer requests a password reset for their email
  Then  an email with a single-use link is sent within 60 seconds

Scenario: Unknown email (6a)
  Given an email that is not registered
  When  the customer requests a password reset
  Then  the UI shows the same confirmation as the happy path
  And   no email is sent

Scenario: Expired token (6b)
  Given a reset token older than 30 minutes
  When  the customer opens the link
  Then  the UI shows "request a new link"

Scenario: Locked account (6c)
  Given an account marked locked
  When  the customer requests a password reset
  Then  no token is issued
  And   the UI redirects to the support contact page

### 18. Out of scope
- Passwordless / magic-link sign-in.
- Forced password rotation policy.
- Admin-initiated resets.

### 19. Open questions
- Confirm rate-limit threshold with SecOps — owner: dvm, needed by: 2026-05-30.

### 20. References
- ADR-0014 (token strategy).
- specs/CONTEXT.md (User aggregate).
```

This example scores 3 (Countable). To reach 4, resolve §19 and add NFR coverage for §16 i18n test plan.
