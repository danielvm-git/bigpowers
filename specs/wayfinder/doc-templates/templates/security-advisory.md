<!-- wayfinder resolution artifact — T14 (security-review), closed -->
<!-- GATE — draft this ONLY when a specs/security/REVIEW.md verdict is severity HIGH or CRITICAL
     AND status is fixed. Never draft (let alone submit) for an unfixed finding — that is the
     exact responsible-disclosure violation this split exists to prevent. Most reviews (PASS,
     LOW, MEDIUM) never get one of these; this is the strict gate, not "on the shelf" optional. -->
<!-- NOT a docs/ page. This does not render on the Astro/Starlight site — it is a staging draft
     for GitHub's own native Security Advisory feature (GHSA), submitted via `gh api repos/
     {owner}/{repo}/security-advisories` or the GitHub UI, which hosts and publishes it
     separately. Fields below match GitHub's real REST API schema (verified against
     docs.github.com/en/rest/security-advisories/repository-advisories), not invented. -->
<!-- REDACTION RULE: translate REVIEW.md's internal findings into these fields — do not copy
     file:line detail, code snippets, or the raw exploit trace. `description` should be enough
     for an affected user to assess impact and act, not enough to reconstruct the exploit. -->

# Security Advisory draft — {short title, matches `summary` below}

**Source review:** {link to the internal specs/security/REVIEW.md — never linked from the
published advisory itself, this is for the maintainer's own traceability}
**Verdict required to draft this:** severity HIGH or CRITICAL, status FIXED — {confirm both before continuing}

---

## GitHub Advisory fields

- **summary** (required, short): {one line}
- **description** (required, in-depth — redacted, see rule above): {what was affected, general
  cause category, what users should do — not the exploit mechanics}
- **severity**: {critical | high} — or **cvss_vector_string** if calculated (pick one, not both)
- **cve_id**: {null, or the assigned CVE if this advisory requested one}
- **cwe_ids**: [{CWE-NNN from REVIEW.md's finding category}]
- **vulnerabilities**:
  - **package**: {name}, **ecosystem**: {npm | pip | rubygems | maven | nuget | composer | go | rust | erlang | actions | pub | swift | other}
  - **vulnerable_version_range**: {e.g. "< 1.2.3"}
  - **patched_versions**: {e.g. "1.2.3"}
  - **vulnerable_functions**: [{only if genuinely useful to an affected user, omit if it aids exploitation}]
- **credits**: [{login, type: reporter | finder | analyst | remediation_developer | ...}]
- **state**: `draft` until ready — flip to `published` only after the fix has actually shipped

---

{Submit via `gh api repos/{owner}/{repo}/security-advisories -X POST` with the fields above as
JSON, or paste into the GitHub UI's "New security advisory" form. This markdown file stays as
the internal drafting record; the advisory itself lives and renders on GitHub, not this repo's
docs site.}
