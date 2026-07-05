# Commit Message: e42 — Golden Story Suite

## Title
```
feat(e42): golden story suite — agent-driven benchmark infrastructure
```

## Body
```
Adds the agent-driven half of the bigpowers benchmark suite (e42).

Stories:
- e42s01 (spike): headless golden-chain harness via gh-aw + DeepSeek v4
  — ANTHROPIC_BASE_URL pattern confirmed viable
- e42s02: minimal-api fixture repo with createUser + failing-ready test
  harness (zero-dependency node:test, 4 scenarios)
- e42s03: 4 golden story YAMLs (g-01, g-02, g-03, g-05) with code
  graders and pass@k 2-of-3 flake policy
- e42s04: --agent mode for run-golden-suite.sh — deterministic gates
  first, then agent-driven stories, combined verdict

BCP: 10 (3+3+4)
Security: LOW (benchmark infrastructure, no user data)
Tests: 4/4 PASS on pristine fixture; failing-ready harness verified
```

## Bump Hint
```
minor
```
