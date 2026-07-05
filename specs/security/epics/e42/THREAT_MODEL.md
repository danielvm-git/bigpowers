# Threat Model: e42 — Golden Story Suite

**Date:** 2026-07-05
**Epic:** e42 — Golden Story Suite (Agent-Driven)
**Stories:** e42s02, e42s03, e42s04
**Risk Level:** LOW

## Surface Area

| Component | Type | Exposure |
|-----------|------|----------|
| specs/benchmarks/fixtures/minimal-api/ | Static fixture (Node.js) | None — local filesystem only |
| specs/benchmarks/golden/g-*.yaml | Benchmark definitions | None — static YAML config |
| scripts/run-golden-suite.sh | Shell script | Internal CI invocation; gh-aw CLI for agent execution |

## Vulnerability Categories Assessed

| Category | Finding | Confidence | Rationale |
|----------|---------|------------|-----------|
| SQLi | None | — | No database interaction. Fixture uses zero dependencies. |
| XSS | None | — | No HTML rendering. Output is CLI exit codes. |
| SSRF | None | — | No outbound HTTP from fixture. gh-aw calls DeepSeek API (known endpoint). |
| Command injection | Low | 6/10 | run-golden-suite.sh parses user-provided YAML paths. Path validation via shell glob limits injection surface. |
| Auth bypass | None | — | No authentication at any layer. |
| Unsafe deserialization | None | — | YAML parsed by Python yaml.safe_load in gate (task 5 of e42s03). |
| Path traversal | Low | 5/10 | Fixture path hardcoded; no user-controlled path in scope. |
| Secrets exposure | None | — | No secrets in fixture. DeepSeek API key managed by gh-aw (out of scope). |

## Risk Assessment

**Overall: LOW** — No HIGH or CRITICAL findings. This epic operates entirely on benchmark infrastructure with no production data paths, no network endpoints, and no auth boundary.

## Mitigation Guidance

1. **run-golden-suite.sh YAML path handling** — ensure shell expansion is bounded to `specs/benchmarks/golden/g-*.yaml`. Avoid `eval` or unvalidated variable expansion.
2. **DeepSeek API key** — managed by gh-aw, not by this script. Verify gh-aw key storage is secure (GitHub secrets or encrypted store).
3. **Fixture mutability** — golden-run agent gets a throwaway copy of the fixture (designed in e42s04). Ensure `cp -r` or `rsync` to a temp dir, not in-place mutation.

## BCP Plus Note

Per the NFR Gate rule, standard-expectation security items (no SQLi, no XSS, etc.) score 0 with rationale. No non-standard security requirements exist for this epic. Dimension 12 (Security & Compliance) = 0.
