<!-- wayfinder:research -->
# T2 — template-landscape

**Type:** Research (AFK) · **Status:** CLOSED · **Claim:** research-subagent
**Blocks:** informs T1 (doctrine) · **Blocked by:** —

## Question

What do each of these template sources actually provide, and how does each map onto bigpowers'
document types (including the `website/` docs-site source and the `acps-workflow` line)?
- `/Users/danielvm/Developer/big-docs`
- `/Users/danielvm/Developer/big-kickass-readme`
- Good Docs Project / Diátaxis (tutorial / how-to / reference / explanation)
- `/Users/danielvm/Developer/bigspec/` `templates/` + `docs/okf-spine.md` (the B8 per-kind model)

## Decision output

A mapping table: source → what it offers → which bigpowers/acps doc types it best fits → gaps.

## Resolution

**Recommend doctrine (c) hybrid**, and the evidence already exists as a working example.

| Source | Offers | Best fits | Gaps |
|--------|--------|-----------|------|
| `big-docs` | 3 gated waves: (1) GitHub community/governance, (2) TGDP GoodDocs prose packs (concept/how-to/tutorial/reference/troubleshooting/readme/changelog/glossary/style-guide/personas) vendored verbatim, (3) a full bigpowers-shaped `specs/` tree with `<slug>` placeholders | Wave 3 ≈ 1:1 with bigpowers specs (cockpit YAML, epic/story/tasks, ADR, bug, tech-stack, test-plan, security); Wave 2 = the prose doc types; Wave 1 = repo governance | No wiki family, no docs-site content model, no enterprise delivery-command docs; prose bodies carry no OKF frontmatter |
| `big-kickass-readme` | 9 stack-specific README skeletons (Swift/TS/Vue/SvelteKit/Astro/Go/Python/Shell/generic), fixed 15-section body with real toolchain commands | READMEs only — per-language bootstrapping | Everything else; single doc-type, no envelope |
| Good Docs / Diátaxis | A doc-type *taxonomy* (tutorial/how-to/reference/explanation) + TGDP extensions — already vendored into `big-docs` | All human prose: guides, tutorials, reference, README, wiki, docs-site | No machine/YAML model; ADR loses decision/status/consequences; no enterprise PM docs |
| `bigspec` B8 (okf-spine) | Universal YAML envelope (`okf_kind`/version/provenance/supersedes) + 6 spec'd kinds + 3 tool-owned; one `validate-okf`; `_LATEST` abolished | YAML cockpit, epic/story/tasks; envelope generalizes cleanly to ADR/bug/tech-stack/test-plan/security | Template *bodies* for 5 more kinds not written yet; `kernel/templates/` referenced but absent; deliberately silent on human prose |

**Synthesis:** Pure-OKF (a) has no answer for tutorials/how-tos/READMEs; pure-Diátaxis (b) has no answer for cockpit state/epics/BCP counts. **Hybrid (c):** adopt bigspec's OKF envelope + `validate-okf` for all `specs/` machine artifacts (extend its 6 kinds to cover ADR/bug/tech-stack/test-plan/security-review), and TGDP's four-type/nine-family taxonomy for `docs/`, wiki, docs-site, README content (big-kickass-readme as a stack-specific README seed only). `big-docs`' three-wave structure *independently converges on exactly this split* — strong prior-art confirmation. Neither source covers enterprise delivery-command docs (status/capacity/vendor/compliance) — that gap maps to the operations-plugin doc skills, flagged for T4/acps scope.
