<!-- wayfinder:grilling -->
# T18 — agents-and-conventions

**Type:** Grilling (HITL) · **Status:** CLOSED · **Claim:** driver
**Blocks:** the authoring/agent-bootstrap slot in the survivor set · **Blocked by:** T1
(doctrine, closed), T6 (Wave assignment — §3.11 already placed these in Wave 2)

## Question

CLAUDE.md and CONVENTIONS.md — collapse into one constitution.md (per bigspec's aggressive
single-file model), or something more surgical?

## Resolution

**Not a full merge — `big-docs` already built the exact, more surgical answer.** Found a real
template at `big-docs/archive/snapshot-2026-07-14/bigpowers/docs/templates/AGENTS.md` (79 lines).
It proves three things bigpowers' own live CLAUDE.md (hundreds of lines) got wrong by comparison:

1. **AGENTS.md is canonical; CLAUDE.md/GEMINI.md are filesystem symlinks to it** — zero
   divergence possible by construction (§3.11, already established). Not a merge into one file;
   a clean two-file split with one direction of reference.
2. **The ~250 lines of RTK/sqz/bts command tables are completely absent from the real template**
   — confirming they're tool-usage reference material (TGDP `reference/` shape, per T13's
   established pattern), not agent-bootstrap content. Extracted to a new page.
3. **Learned User Preferences / Workspace Facts stay in AGENTS.md as fenced, tool-regenerated
   sections** (`<!-- BEGIN/END bigpowers:learned-preferences -->`) — dynamic content templated
   in place (the `e45s21` "self-installing fenced markers" story), not hand-mixed prose.

**Real overlap found and cut:** bigpowers' live CLAUDE.md carries a full duplicate **"Pre-Merge
Checklist"** section, restating CONVENTIONS.md's **"Pre-Merge Verification Gates"** — the same
restatement pattern this session keeps catching (S6, the wiki family, T10's glossary). The real
template's answer: one `Preflight` row in the Commands table, nothing more. Same fix applied to
CLAUDE.md's "Never" list overlapping CONVENTIONS.md's "Risk Tiers P0" / "Banned dismissive
phrases" — kept as a short, project-specific "Never" list in AGENTS.md; the deep rule taxonomy
stays CONVENTIONS.md's alone.

**CONVENTIONS.md itself is unchanged** — same treatment as `tech-stack.md` (T13) and `TEST_PLAN`
(T15): already a good, working source; this round reconciles what points to it, not its own
content.

**Artifacts:** [`templates/agents.md`](../templates/agents.md) (canonical, thin, symlink target),
[`templates/agent-tooling.md`](../templates/agent-tooling.md) (extracted RTK/sqz/bts reference,
conditional — only populated if a project actually has such tooling, unlike AGENTS.md which is
mandatory scaffolding).