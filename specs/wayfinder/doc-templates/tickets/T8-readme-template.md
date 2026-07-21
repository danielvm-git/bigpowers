<!-- wayfinder:grilling -->
# T8 — readme-template

**Type:** Grilling (HITL) · **Status:** CLOSED · **Claim:** driver
**Blocks:** the README Wave-1 file bigpowers generates for every project · **Blocked by:** T7 (closed)

## Question

Four candidate README templates exist — GitHub's own minimal default, TGDP's `readme/` pack
(`big-docs/docs/readme/template_readme.md`), `big-kickass-readme`'s fixed 15-section
per-stack skeleton, and whatever bigpowers currently emits. Compose the ONE template bigpowers
will use going forward: which sections come from which source, in what order.

## Decision output

A single `readme.md` template (structure only — section list + one-line purpose per section, plus
source attribution per section) that becomes the canonical README bigpowers generates for every
project, GitHub-native and stack-agnostic.

## Resolution

**User-confirmed composition**, 12 sections, one source per section:

| # | Section | Source |
|---|---|---|
| 1 | Title + badges (inline row) | GitHub-native + `big-kickass-readme` |
| 2 | One-line value statement | bigpowers' prior README pattern |
| 3 | **"How to read this README" nav table** | bigpowers original — kept; neither TGDP nor kickass-readme has this |
| 4 | Quick Start | all 3 sources agree |
| 5 | Prerequisites (short; link out if long) | TGDP + kickass-readme |
| 6 | Features | TGDP + kickass-readme |
| 7 | Who this is for | TGDP |
| 8 | **Learn more** (link block → `docs/concept`, `docs/reference`, `docs/how-to`, `docs/tutorial`) | new — replaces the old deep-dive sections per T1's doctrine (README = router, not encyclopedia) |
| 9 | Contributing (one line + link to root `CONTRIBUTING.md`) | TGDP's linking instruction |
| 10 | How to get help (link to `SUPPORT.md`) | TGDP |
| 11 | License (link to `LICENSE`) | all 3 |
| 12 | Acknowledgements | bigpowers original, optional |

**Dropped:** kickass-readme's separate "Build status"/"Code style" sections (folded into the badge row);
TGDP's Table of Contents section (superseded by the nav table, and GitHub auto-generates one anyway).

**Net effect:** README gets shorter — philosophy/hierarchy-of-truth/MCP-setup/pi-support/maintenance,
which the *current* bigpowers README crams in, move to their proper `docs/` homes (future one-by-one
rounds), replacing duplication with links (matches TGDP's own instruction and the no-mirror invariant).

**Artifact:** [`templates/readme.md`](../templates/readme.md) — the composed template, ready for the
future migration epic to adopt. Not yet applied to bigpowers' own live `README.md` (that's forward
work outside this wayfinding session's scope).
