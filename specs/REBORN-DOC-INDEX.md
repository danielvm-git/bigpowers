# bigpowers Reborn — Document Index

> Greenfield design for a **new repository**. Not a migration from this tree.
> Status: M0 document foundation **complete** (2026-07-04).

---

## The trilogy

| # | Document | Question it answers | Read when |
|---|---|---|---|
| 1 | [`reborn-constitution.md`](reborn-constitution.md) | **What are the rules?** — B0–B10 building blocks, risk tiers, gates, conventions, Capstone evals | Before writing any skill or kernel code |
| 2 | [`reborn-m0-okf-spine.md`](reborn-m0-okf-spine.md) | **What do files look like?** — OKF envelope + 6 core kinds (cockpit, story, glossary, epic, tasks) | Before authoring anything under `specs/` |
| 3 | [`BIGPOWERS-REBORN.md`](BIGPOWERS-REBORN.md) | **How does the system work?** — 7 nouns, fractal loop, ~28 skills, metrics, M0→v1.0 build sequence | After 1–2; before standing up the repo |

**Read order:** constitution → OKF spine → architecture (or architecture first for the big picture, then constitution for rules, spine for contracts).

---

## Cross-reference matrix

| Topic | Constitution | OKF spine | Architecture |
|---|---|---|---|
| Skill = procedure only | B3 | — | §1, §5 |
| BCP sizing (native `count-bcp`) | B9 | story (input), glossary (ground truth), epic (roll-up) | §7, §12 |
| OKF universal envelope | B8 | §1 envelope | §12 |
| Risk tiers P0–P3 | Part II, B5 | epic table column | §4 fast/full lane |
| MCP-last | Part V | cockpit via `bp-yaml` | §2 noun #3, §6, §8 M5 |
| Outcome evals (Capstone) | ★ Capstone | — | §1, §7, §11 |
| Fractal loop | B10 | `current_movement` in cockpit | §4 |
| M0 seed skills | B3 verify contract | all 6 kinds | §8 M0 |
| Building blocks map | Part I (B0–B10) | three shapes rule | §13 |
| Compliance / 8 features | Part III | validate-okf | §11, §13.2 |

---

## Companion documents (this repo only)

| Document | Purpose |
|---|---|
| [`CLEAN-SLATE-ARCHITECTURE.md`](CLEAN-SLATE-ARCHITECTURE.md) | Refactor plan for *this* tree (74→41 skills) — not the greenfield target |
| [`REBORN-CONSTITUTION-GAPS.md`](REBORN-CONSTITUTION-GAPS.md) | Gap analysis — **applied** to `reborn-constitution.md` 2026-07-04 |
| `specs/verifications/features/*.feature` | Principle harness; two steps rewritten for reborn gate model (§11) |

---

## M0 checklist (new repo)

When standing up the empty repository:

- [ ] Copy `reborn-constitution.md` → `constitution.md` (repo root)
- [ ] Copy `reborn-m0-okf-spine.md` → `docs/okf-spine.md` or `kernel/templates/README.md`
- [ ] Copy architecture summary or link to this design pack
- [ ] Implement `validate-okf` against spine kinds
- [ ] Implement `bp-yaml` get/set against `cockpit-state` schema
- [ ] Hand-write 5 seed skills: `survey-context`, `elaborate-spec`, `plan-work`, `develop-tdd`, `verify-work` (`count-bcp` follows in M1)
- [ ] Anchor BCP with 2–3 reference stories in constitution (known-3, known-8)
- [ ] **Do not** add MCP until post-v1.0 (M5)

---

## Amendment protocol

1. Change rules → ADR + SemVer bump of `constitution_version` + `constitution-lint`
2. Change file shapes → bump `okf_version` on affected kinds + update spine + validator
3. Change architecture → update `BIGPOWERS-REBORN.md` + cross-links in this index
