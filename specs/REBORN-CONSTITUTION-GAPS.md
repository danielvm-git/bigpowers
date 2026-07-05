# Constitution Gap Report — bigpowers (reborn)

> **Status:** Applied to `reborn-constitution.md` on 2026-07-04. Report retained for audit trail.
> Index: [`REBORN-DOC-INDEX.md`](REBORN-DOC-INDEX.md)

All 7 findings are tightening — no structural change needed. Each includes the specific line(s) to add and where.

---

## Cross-reference: constitution blocks → reborn plan sections

| Constitution block | Reborn plan section(s) |
|---|---|
| B0 (Token/Context Substrate) | §1 primitives table (context engineering), Context Engineering doctrine |
| B1 (Agent-Grade Craftsmanship) | §1 (SRP, deep modules, grep-ability, remediation — all survivors); Part III conventions |
| B2 (Think-First Behavior) | §1 (Karpathy patterns — survivor); §4 loop (assumptions before code) |
| B3 (Skill Primitive) | §1 primitives table ("KEEP but purify"); §5 skill corpus (`effort`/`spawn`/`risk`/`verify`) |
| B4 (Spec-as-Contract) | §1 (spec-as-source-of-truth — survivor); §4 loop (spec as fixed point); §12 OKF doc model |
| B5 (Risk-Tiered Verification) | §1 (risk-tiered gates — replacement); §4 fast/full lane; §5 risk tiers |
| B6 (Gates & Hard-Stops) | §1 (hard gates — kept, scaled); §4 gate types; Part IV gate table |
| B7 (Context Isolation) | §1 (`next_skill` — survivor); §4 handoff chain |
| B8 (Self-Describing Artifacts / OKF) | §8 (M0 cockpit freeze); §12 (OKF universal envelope, `_LATEST` abolished) |
| B9 (Effort Accounting / BCP) | §1 primitives table ("KEEP"); §7 metrics (BCP primary + quality ledger); §12 (spec→count pipeline, native `count-bcp`) |
| B10 (The Synthesis) | §4 loop (5 fractal movements, spec-anchored); §8 build sequence |
| ★ Capstone (Outcome Evals) | §1 (94% gate — REPLACE); §7 (with/without-skill Δ); §11 compliance projection |

---

## G1 · B3: `next_skill` is absent from the Skill Primitive

**Finding:** B7 correctly stores `handoff.next_skill` in the cockpit, but B3 doesn't state that *every skill must write it*. The reborn plan §1 calls `next_skill` a "KEEP — genuine differentiator; survives interruption." A skill's contract isn't just its verify — it's also the handoff it writes so the next agent resumes cleanly.

**Proposed text — add to B3 rules list:**

```
- every skill writes `handoff.next_skill` to the cockpit as its last action before returning; a skill that finishes without a next_skill is incomplete by definition
```

**Where:** After "every skill declares `effort`, `spawn`, `risk`, and a **behavioral** `verify:`" — before the closing bullet.

---

## G2 · B4: Spec-as-Contract is thin — the mechanism is missing

**Finding:** B4 says "every epic has a spec with scope, ubiquitous-language glossary, and Gherkin acceptance criteria" — true but incomplete. The reborn plan §4 defines a full loop with 5 named movements; §5 maps every skill to a movement; §12 defines the countable-story format (20-section input body → BCP-count output). B4 should anchor to these mechanisms rather than just the idea.

**Proposed text — add to B4 rules list:**

```
- the story body follows a structured format designed for unambiguous input to the counter (complete coverage, explicit acceptance criteria tied to Gherkin `Scenario:` blocks, no pre-partitioning into dimensions — the counter's Element Router owns that); the story is the bridge between intent (B4) and accounting (B9)
- every acceptance criterion is a verifiable assertion with a runnable `verify:` command — no tautological checks, no self-reported "done"
```

**Where:** After the existing "acceptance criteria map to runnable verifications" — expand it.

---

## G3 · B9: BCP block is adjacent to OKF block but not connected

**Finding:** B8 says every generated file is an OKF bundle; B9 says stories are input and bcp-count is output — but neither block cross-references the other. The plan §12 connects them: `okf_kind: story` → `okf_kind: bcp-count` via native `count-bcp`. The connection makes it clear that the bcp-count is *derived* from a validated OKF story, not free-floating.

**Proposed text — add to B9 rules, after the first bullet group:**

```
- every `bcp-count` is an OKF bundle (see B8) and carries `okf_kind: bcp-count` + `okf_version` + provenance; its validity gate checks `okf_kind` and structure, never the BCP number
- every story that feeds a `bcp-count` is itself an OKF bundle (`okf_kind: story`); the validate-okf gate on the story precedes the counter run, so the counter never counts a structurally-invalid spec
```

**Where:** After "BCP is counted natively via `count-bcp`, never delegated to an external tool."

---

## G4 · B9: counting contracts must be named — natively, not as external dependency

**Finding:** The reborn plan §12 identifies three integration points: Element Router, knowledge bundle as ground truth, calibration_id segmentation. Applied as native `count-bcp` contracts (see constitution B9).

**Proposed text — add to B9 rules, after the Domain-as-ground-truth line:**

```
- `big-counter` integration is three contracts: (1) the Element Router owns dimension classification — the story is input, never pre-partitioned; (2) the knowledge bundle from B4's glossary is the counter's domain ground truth (entities feed dims 6/7, roles feed dim 5, NFR baselines feed dims 11–13); (3) `calibration_id` provenance ties every count to a specific model version — velocity series segment by it, and mixed-calibration charts are prohibited
```

**Where:** After "define-language/model-domain output is authored as an OKF knowledge bundle…"

---

## G5 · B10: The loop movements are named but not defined

**Finding:** B10 drops "Frame → Specify → Plan → Build → Prove → ship" as assumed terms, but the constitution reader hasn't encountered them before. The reborn plan §4 defines each movement with its purpose and skills. B10 should at minimum list them with a one-line purpose each, so the synthesis reads as more than a slogan.

**Proposed text — add to B10, before "the loop (Frame → Specify…":**

```
- **Frame** — understand the problem and the existing context (what exists, what's known, what's ambiguous)
- **Specify** — turn intent into a durable, testable spec (scope, glossary, Gherkin acceptance criteria)
- **Plan** — decompose into tasks, risk-tier (P0–P3), estimate (BCP), and order
- **Build** — TDD vertical slices in isolated worktrees; the spec is the contract, tests are the proof
- **Prove** — verify by the risk tier assigned in Plan (full gauntlet for P0, fast lane for P3), then ship
```

**Where:** Replace the single-line "the loop (Frame → Specify → Plan → Build → Prove → ship) runs…" with the definitions followed by that sentence.

---

## G6 · No principle linking skills to movements

**Finding:** The plan §5 groups every skill under its movement (Meta, Frame, Specify, Plan, Build, Prove, Sustain). The constitution doesn't need the inventory (that's a living catalog, not a rule), but it should state the structural principle: skills are authored against a movement, and the orchestrator dispatches by movement. Without this, B3 (skills) and B10 (loop) don't connect.

**Proposed text — add to B3 rules:**

```
- every skill declares its movement (`movement: frame | specify | plan | build | prove | sustain`) in its frontmatter; the orchestrator dispatches by (movement, current cockpit state), not by hard-coded chain
```

**Where:** After the existing `effort`/`spawn`/`risk`/`verify` bullet — make it part of the frontmatter contract.

---

## G7 · Constitution versioning is asserted but not defined

**Finding:** "The constitution is versioned; skills are authored against a constitution version" — good rule, but what's the scheme? Neither the constitution nor the reborn plan define it. Simplest and most durable: SemVer in a frontmatter field, bumped by the ADR that amends it.

**Proposed text — add a versioning block at the top of the constitution (before Part I):**

```
> **Version:** `1.0.0` (SemVer). Bumped by the ADR that amends this file. Every skill declares `constitution_version` in its frontmatter to declare compatibility.
```

**Where:** In the header block, after the Authority line, before Part I.

**Proposed text — add to the Amendment rule in the header:**

```
> **Amendment:** changing any block below requires (1) an ADR in `specs/adr/` documenting the rationale, (2) a passing `constitution-lint`, and (3) a SemVer bump of the `constitution_version` frontmatter field. The amendment ADR must state the old version and the new version.
```

---

## Summary

| Gap | Severity | Type | Lines to add |
|-----|----------|------|--------------|
| G1 — `next_skill` missing from B3 | Medium | Missing protocol | 2 lines |
| G2 — B4 too thin (missing story format, verify mechanism) | High | Incomplete definition | 3 lines |
| G3 — B9 not cross-referenced to B8 (OKF) | Low | Missing cross-ref | 3 lines |
| G4 — B9 counting contracts (native `count-bcp`, not external tool) | High | Missing specificity | Applied |
| G5 — B10 loop movements undefined | Medium | Missing definition | 6 lines |
| G6 — No skill→movement principle | Medium | Missing structural rule | 2 lines |
| G7 — Versioning scheme not defined | Low | Missing metadata | 2 lines |

**Total: ~22 lines** of additions across 7 edits. No deletions, no structural reorganization. The block numbering (B0–B10) and ordering are correct and unchanged.

---

*All seven findings (G1–G7) applied 2026-07-04. **Pivot 2026-07-04:** `big-counter` is spec-only — B9/`count-bcp` native implementation replaces external tool dependency.*
