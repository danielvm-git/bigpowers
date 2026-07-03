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

**Open** — registered 2026-07-03 from PLAN-AUDIT red-team gap list (P2 #9).
