# story: e37s07
# Test Design: e37 — Reach: Universal Agent Portability

Epic: e37-reach | Risk owner: plan-tests (e46) | Date: 2026-07-06

---

## 1. Risk Matrix & Scenarios

| Scenario ID | Behavior | Risk | Level | Target |
|-------------|----------|------|-------|--------|
| SC-e37s01-P1-01 | `docs/templates/AGENTS.md` has Preflight + multi-agent preamble | P1 | Integration | `docs/templates/AGENTS.md` |
| SC-e37s01-P1-02 | seed-conventions emits AGENTS.md + CLAUDE.md symlink when opted in | P1 | Manual UAT | `skills/seed-conventions/SKILL.md` |
| SC-e37s04-P2-01 | verify-install.sh asserts AGENTS.md spine shape (Preflight, Test/Lint/Build) | P2 | Integration | `scripts/verify-install.sh` |
| SC-e37s04-P2-02 | Codex assertions skipped when Codex wave absent | P2 | Integration | `scripts/verify-install.sh` |
| SC-e37s05-P1-01 | validate-targets-yaml.sh exits 0 on core P1 registry | P1 | Integration | `scripts/validate-targets-yaml.sh` |
| SC-e37s05-P1-02 | test-adapters.sh smoke-tests all default_on adapters | P1 | Integration | `scripts/test-adapters.sh` |
| SC-e37s06-P1-01 | generate-context-bundle.sh --dry-run references AGENTS.md | P1 | Integration | `scripts/generate-context-bundle.sh` |
| SC-e37s06-P1-02 | wire_context produces CLAUDE.md symlink (or copy fallback) | P1 | Manual UAT | `scripts/lib/context-wire.sh` |
| SC-e37s07-P0-01 | sync-skills.sh loads targets from registry (no hardcoded target loop) | P0 | Integration | `scripts/sync-skills.sh` |
| SC-e37s07-P0-02 | render_skill dispatch populates .cursor/rules/ after sync | P0 | Integration | `scripts/sync-skills.sh` |
| SC-e37s07-P0-03 | Full preflight passes after registry-driven sync | P0 | E2E | `bash scripts/run-verification-gates.sh` |
| SC-e37s08-P1-01 | verify-install.sh --matrix reports PASS for default_on targets | P1 | Integration | `scripts/verify-install.sh` |
| SC-e37s09-P2-01 | goose target row + matrix PASS | P2 | Integration | `scripts/targets.yaml` |
| SC-e37s10-P2-01 | zed/omp/hermes rows + test-adapters.sh per id | P2 | Integration | `scripts/test-adapters.sh` |
| SC-e37s14-P2-01 | seed-conventions REFERENCE Codex TOML block parseable | P2 | Unit | `skills/seed-conventions/REFERENCE.md` |

**Traceability:** Implementing scripts/tests MUST include `// scenario: SC-e37sNN-Px-NN`
comments alongside `// story: e37sNN` tags. gate-trace treats P0 with zero SC refs as CONCERNS.

---

## 2. Test Level Strategy

- **Integration (bash gates):** validate-targets-yaml, test-adapters, sync-skills, verify-install — primary level for this Markdown/Bash project.
- **Manual UAT:** seed-conventions in temp dir (s01), context bundle symlink check (s06), matrix review (s08).
- **Unit:** TOML parse of REFERENCE fenced blocks (s14); yq field extraction in validate-targets-yaml (s05).
- **No browser/E2E** beyond preflight chain.

Default: lowest level that proves behavior.

---

## 3. Validator dependency (G10 closure)

`scripts/validate-targets-yaml.sh` MUST use **`yq` + bash** — not Python pyyaml.
Rationale: yq already used in repo (e38, agent-locks); avoids undeclared CI Python dep.
Prerequisite check: `command -v yq` with install hint on failure.

---

## 4. Per-story verify matrix (summary)

| Phase | Stories | Primary verify |
|-------|---------|----------------|
| Spine | s01–s04 | grep + verify-install.sh |
| Registry | s05–s08 | validate-targets-yaml + test-adapters + sync + matrix |
| Waves | s09–s13 | registry grep + test-adapters per new id |
| Codex (optional) | s14–s16 | seed/install/docs grep |

Full gap notes preserved in §5 below.

---

## 5. Known verification gaps (honest)

| Story | Gap | Mitigation |
|-------|-----|------------|
| s01 | grep does not prove seed runtime | Manual UAT step 1 |
| s02 | no live Cline session | Document in using-bigpowers |
| s07 | grep parity check is proxy | SC-e37s07-P0-03 preflight E2E |
| s10–s11 | grep-only epic verify | test-adapters.sh in story tasks |

---

## 6. Manual UAT steps (P0 and P1)

1. **s01**: seed-conventions in temp dir → AGENTS.md + CLAUDE.md symlink
2. **s04**: `bash scripts/verify-install.sh` exit 0
3. **s05**: `bash scripts/validate-targets-yaml.sh && bash scripts/test-adapters.sh`
4. **s06**: `bash scripts/generate-context-bundle.sh` → CLAUDE.md symlink
5. **s07**: `bash scripts/sync-skills.sh` → .cursor/rules/ populated; preflight green
6. **s08**: `bash scripts/verify-install.sh --matrix` → PASS rows

---

## 7. Hard gates

| Gate | Command | Block? |
|------|---------|--------|
| Preflight | `npm run compliance && bash scripts/run-verification-gates.sh && bash scripts/sync-skills.sh && bash scripts/trace-stories.sh --strict` | Yes |
| Registry schema | `bash scripts/validate-targets-yaml.sh` | Yes |
| Adapter smoke | `bash scripts/test-adapters.sh` | Yes |
| P0 sync | `bash scripts/sync-skills.sh && bash scripts/run-verification-gates.sh` | Yes |
| Matrix | `bash scripts/verify-install.sh --matrix \| grep -q PASS` | Yes |

---

## References

- specs/epics/e37-reach/epic.yaml
- specs/tech-architecture/tech-stack.md § Reach Domain
- specs/adr/0007-agents-md-spine-context-derivatives.md
