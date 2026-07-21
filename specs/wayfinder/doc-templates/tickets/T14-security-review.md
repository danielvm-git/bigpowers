<!-- wayfinder:grilling -->
# T14 — security-review

**Type:** Grilling (HITL) · **Status:** CLOSED · **Claim:** driver
**Blocks:** the security-review slot in the survivor set · **Blocked by:** T1 (doctrine, closed)

## Question

No TGDP pack exists for security review (confirmed — none of the user's original 26 folders was
security-related). Does `REVIEW.md` need a template at all, and does anything need to be public?

## Resolution

**Not a template collision — a responsible-disclosure boundary.** Verified against the real
`security-review` skill and a live `REVIEW.md`: per-diff findings, file:line detail, CWE-mapped,
exploit-scenario level detail, gates `verify-work` (blocks merge on HIGH findings ≥8 confidence).
Unlike T9/T11/T13's mechanical-record-vs-curated-layer pattern (where the internal record was
just uninteresting to a reader), publishing this verbatim would be actively harmful — a HIGH
finding's exploit path, published the moment it's found, before a fix ships, is exactly what
responsible disclosure prevents.

**Three distinct things, not one document:**
1. `SECURITY.md` (Wave 1, resolved in T6) — how to report a vuln, always visible.
2. `REVIEW.md` (unchanged, no new template) — **never auto-published.** The one deliberate
   exception to "everything dissolves into `docs/`, all visible" from earlier in this session —
   for a specific, well-understood reason, not an arbitrary carve-out.
3. **New: Security Advisory draft** — gated strictly on severity HIGH/CRITICAL *and* status
   fixed (user-confirmed ruling — build now, gate hard, not "on the shelf" loose-optional like
   T9/T11's curated layers).

**Fields verified against GitHub's real REST API schema** (context7 → `docs.github.com/en/rest/
security-advisories/repository-advisories`, not assumed): `summary`, `description`, `severity`/
`cvss_vector_string`, `cve_id`, `cwe_ids`, `vulnerabilities[]` (package/ecosystem/version range/
patched versions), `credits[]`, `state` (draft/published/closed).

**Novel category for this map:** this artifact does not render on the Astro/Starlight site at
all — unlike every other template so far, it's a staging draft submitted to GitHub's own native
Security Advisory feature (`gh api .../security-advisories` or the GH UI), which hosts and
publishes it separately. A redaction rule is baked into the template: translate findings into
what an affected user needs to assess impact and act, never the raw exploit mechanics.

**Artifact:** [`templates/security-advisory.md`](../templates/security-advisory.md).