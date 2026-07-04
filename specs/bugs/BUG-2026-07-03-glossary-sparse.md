---
bug_id: BUG-2026-07-03-glossary-sparse
status: fixed
severity: medium
scope: specs
title: "GLOSSARY_LATEST.yaml remains sparse — key domain terms missing"
---

# BUG-2026-07-03T135000: GLOSSARY_LATEST.yaml remains sparse — key domain terms missing

## Problem

**Actual behavior:** `specs/GLOSSARY_LATEST.yaml` is sparse. The OKF authority doc now anchors OKF terminology, but BCP, WSJF, golden-story, and other bigpowers-native terms have no glossary entries. This is carried over from previous audit warnings.

**Expected behavior:** Every domain term used in specs/, SKILL.md frontmatter, and conventions has a glossary entry with: term, definition, source, and related_terms.

**How to reproduce:**
1. `cat specs/GLOSSARY_LATEST.yaml` — sparse
2. Search for "BCP" across the codebase — used extensively, no glossary definition
3. Search for "WSJF" — used in every epic, no glossary definition
4. Search for "golden-story" — used in e31/e37, no glossary definition

## Root Cause Analysis

The GLOSSARY was created as an artifact but never systematically populated. Terms entered the codebase organically (BCP from BMAD's method, WSJF from SAFe, golden-story from bigpowers' own e31 design) and were never backfilled into the glossary. The OKF authority doc (`docs/references/okf.md`) anchors OKF terminology but the general domain glossary remains empty.

**Risk level:** LOW — no functional defect. The risk is onboarding friction and inconsistent terminology across docs.

## TDD Fix Plan

### 1. Audit missing terms
**GREEN:** Scan all SKILL.md, CONVENTIONS.md, specs/, and docs/references/ for capitalized/acronymed terms not in GLOSSARY_LATEST.yaml. Produce a candidate list.
**verify:** `wc -l /tmp/glossary-candidates.txt | awk '{if($1>0) print "OK: "$1" candidates found"}'`

### 2. Populate core entries
**GREEN:** Add entries for at minimum: BCP (Bigpowers Complexity Points), WSJF (Weighted Shortest Job First), golden-story, OKF (Open Knowledge Format), HARD GATE, soft gate, handoff, capsule, train, BCP sizing scale.
**verify:** `grep -c 'term:' specs/GLOSSARY_LATEST.yaml | awk '{if($1>=10) print "OK: "$1" entries"; else print "FAIL: "$1}'`

### 3. Link glossary into CONVENTIONS.md
**GREEN:** Add reference to GLOSSARY_LATEST.yaml in CONVENTIONS.md's terminology section, establishing it as the authority for domain terms.
**verify:** `grep -q 'GLOSSARY_LATEST' CONVENTIONS.md && echo OK`

## Acceptance Criteria

- [ ] GLOSSARY_LATEST.yaml has ≥10 entries covering core domain terms
- [ ] BCP, WSJF, OKF, golden-story, HARD GATE all have entries
- [ ] Each entry includes term, definition, source reference, and related_terms
- [ ] CONVENTIONS.md references GLOSSARY_LATEST.yaml as authoritative
- [ ] CI does not break (glossary is documentation, not structurally gated)

## Resolution

**Fixed** — 2026-07-04. `specs/product/GLOSSARY_LATEST.yaml` was already populated
in an earlier session (its own trailing `note:` field confirms it was done as
part of this bug) with 19 entries — well past the ≥10 threshold — covering BCP,
WSJF, OKF, golden story, HARD GATE, soft gate, handoff, capsule, train, and more,
each with term/definition/source/related_terms. `CONVENTIONS.md` line 104
references `GLOSSARY_LATEST.yaml` as the authoritative glossary location. Only
gap was the bug file/registry status not being updated to reflect the work
already done — closed here.

**Verify:** `grep -c 'term:' specs/product/GLOSSARY_LATEST.yaml` → 19 (≥10);
all of BCP/WSJF/OKF/golden story/HARD GATE present; `grep -q 'GLOSSARY_LATEST'
CONVENTIONS.md` → match.
