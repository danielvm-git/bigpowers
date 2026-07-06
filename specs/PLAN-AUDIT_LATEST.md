# Plan Audit — Epic Redesign (6 → 3)
**Date:** 2026-07-06 · **Auditor:** Cursor Agent
**Verdict:** READY with 3 conditions (add to execution checklist before proceeding)

**Ingested:**
- `/Users/danielvm/.cursor/plans/epic_redesign_c386989e.plan.md`
- `specs/release-plan.yaml`, `specs/state.yaml`, `CLAUDE.md`, `CONVENTIONS.md`
- `specs/epics/e37-bcp-plus-counting/epic.yaml` (+ story files)
- `specs/epics/e45-okf-completion/epic.yaml`
- `specs/epics/e48-prior-art-audit/epic.yaml`
- `specs/epics/e49-wiki-rendering-target/epic.yaml`
- `specs/epics/e50-codex-reach/epic.yaml` (+ story files)
- `specs/epics/e52-integration-registry/epic.yaml` (+ story files)
- `specs/product/SCOPE_LATEST.yaml`

---

## Lens 1 — Principles Alignment

| Check | Status | Note |
|-------|--------|------|
| Vertical slices | ✅ | This is a spec-surgery operation, not a feature. Deliverables are file creates/deletes/edits — each independently verifiable. |
| Scope bounded — in_scope | ✅ | 6 capsule dirs deleted, 3 new capsule dirs created, 3 YAML files updated, 5 stray docs deleted. |
| Scope bounded — out_of_scope | ⚠️ | Not explicitly stated. `execution-status.yaml`, `scripts/verify-install.sh`, `docs/references/`, and skill source files are implicitly untouched — should be listed. |
| Success criteria defined | ⚠️ | Files-to-delete and files-to-create are listed but no runnable "done" assertion. Missing: `bash scripts/validate-specs-yaml.sh && echo PASS` as the terminal gate. |
| HARD GATE candidates | ⚠️ | `validate-specs-yaml.sh` is the natural gate after YAML edits; not mentioned in the plan. `trace-stories.sh --strict` would also flag any orphaned story tags — not mentioned. |
| Domain language | ✅ | Epic IDs, BCP, WSJF, capsule dir, story ID — all established bigpowers terminology used correctly. |
| Number reuse coherence | ✅ | e37/e45/e48 reused from freed numbers; e49/e50/e52 retired without allocating new high-water marks. Clean. |

---

## Lens 2 — Conventions Completeness

| Check | Status | Note |
|-------|--------|------|
| `CLAUDE.md` exists | ✅ | Present. References e38s08, e51s05 story tags. |
| `CONVENTIONS.md` exists | ✅ | Present and current (e51 Always Green block included). |
| `specs/` directory layout | ✅ | `state.yaml`, `release-plan.yaml`, `execution-status.yaml`, `epics/`, `product/` all in place. |
| Conventional Commits documented | ✅ | Fully documented in CONVENTIONS.md §Conventional Commits. |
| Git workflow mode identified | ✅ | Solo-git via `scripts/land-branch.sh`. |
| Traceability mandate | ✅ | All 6 upcoming epics are `status: todo` — no implementation code written yet. No `# story: e50sXX` or `# story: e52sXX` tags exist in code files. Renumbering to new IDs carries zero traceability debt. |

---

## Lens 3 — Bigpowers Pre-flight

| Command | Value |
|---------|-------|
| Test | N/A (Markdown/Bash project) |
| Build / sync | `bash scripts/sync-skills.sh` |
| Lint | `bash scripts/sync-skills.sh` (validates SKILL.md syntax) |
| Validate specs YAML | `bash scripts/validate-specs-yaml.sh` |
| Preflight | `npm run compliance && bash scripts/run-verification-gates.sh` |
| Traceability gate | `bash scripts/trace-stories.sh --strict` |
| CI platform | GitHub Actions |
| Solo or team | Solo (solo-git via `land-branch.sh`) |
| Language + framework | Markdown / Bash |
| Greenfield or existing | Existing — spec surgery only, no code changes |

**Key finding — validate-specs-yaml.sh not in plan:**
The plan creates and edits YAML files (`epic.yaml` ×3, `release-plan.yaml`, `state.yaml`, `SCOPE_LATEST.yaml`) but does not include a validation pass. This is the highest-risk gap — a malformed YAML key would break the entire specs cockpit silently.

**Key finding — execution-status.yaml not addressed:**
`specs/execution-status.yaml` is the "sole SoT for story state" (CONVENTIONS.md). It currently carries `todo` entries for old story IDs (e50s05, e52s01, etc.). After deletion, those keys become orphans. The plan must include a cleanup pass on this file.

**Key finding — out_of_scope section missing from plan:**
The following files are implicitly NOT touched but this is unstated:
- `scripts/verify-install.sh` (updated later in e37s04 story, not as part of restructuring)
- `docs/references/agent-config-files-and-okf.md`
- All `skills/*/SKILL.md` files
- `.cursor/rules/`, `.gemini/`, `.pi/` (generated artifacts)
- `specs/execution-status.yaml` — BUT see condition below; it IS implicitly affected

---

## Open Gaps — Conditions Before Proceeding

- [ ] **C1 — Add validation gate as final step:** After all edits, run `bash scripts/validate-specs-yaml.sh && bash scripts/run-verification-gates.sh && bash scripts/trace-stories.sh --strict`. If any gate fails, treat as a hard block.
- [ ] **C2 — Clean up execution-status.yaml:** Remove (or mark `archived`) the old story ID keys for e37/e45/e48/e49/e50/e52 stories. Add placeholder `todo` entries for the new e37/e45/e48 story IDs once the new epics are written.
- [ ] **C3 — Add explicit out_of_scope to the plan:** List `execution-status.yaml` (requires cleanup, not untouched), `docs/references/`, `skills/`, and generated artifact dirs as out of scope for this restructuring pass.

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Malformed YAML after edits | Medium | High — breaks validate-specs-yaml.sh gate | C1 validation gate |
| Orphaned story IDs in execution-status.yaml | High — guaranteed if not addressed | Low (CI traceability works on code tags, not this file) | C2 cleanup pass |
| Story tag conflicts (old e37 reused) | Low — all e50/e52 stories are `todo`, no code tags exist | High if it happened | Zero risk: confirmed no code tags for todo stories |
| Strategy doc deletion loses useful content | Low — content is now encoded in new epic capsules | Low | Stray docs are untracked; git history irrelevant |

---

## Verdict

**READY** — proceed to execution with the 3 conditions incorporated as steps in the execution checklist.

The plan is structurally sound: the number reuse is clean, the story content mapping is complete (all e50/e52/e48/e45/e49/e37 work is accounted for in the three new epics), and there is no traceability debt since all stories are `todo`.

Add conditions C1–C3 to the bottom of the execution sequence before marking done.

**Next skill:** Execute the plan (`execute-plan` style — step by step with human checkpoint after each capsule is created).
