<!-- wayfinder:grilling -->
# T22 — design-and-spike

**Type:** Grilling (HITL) · **Status:** CLOSED · **Claim:** driver
**Blocks:** the last two items in the Analysis fog group · **Blocked by:** T1 (doctrine, closed)

## Question

`extract-design`'s DESIGN.md and `spike-prototype`'s SPIKE-*.md — both were listed in the
original fog and never pulled. Any collision, any external constraint?

## Resolution

**DESIGN.md defers to an external spec — does not get an invented template.** Checked
`extract-design`'s skill + REFERENCE.md: it implements **Google's own published `design.md`
format**, validated by `npx @google/design.md lint`. The 8 body sections (colors, typography,
spacing, rounded, components, plus AI-generated Overview/Do's-and-Don'ts prose) are that external
spec's authority, not bigpowers'. Writing a hand-authored 8-section template here would risk
drifting from what the real linter expects — same reasoning as T14 deferring to GitHub's real API
schema instead of inventing security-advisory fields. The template only layers on bigpowers-
specific additions: OKF envelope, and the `<!-- AGENT NOTE: uncertain -->` flagging convention
(kept, genuinely bigpowers-specific).

**Checked and confirmed DESIGN.md does NOT need T13's mechanical-vs-curated split.** Unlike
`tech-stack.md` (terse "Long-Term Memory," wrong register for a reader), DESIGN.md's prose is
generated *from* extracted tokens specifically to be read by humans and agents — already the
right register. Applying T13's pattern here would have been over-fitting a precedent rather than
checking whether it actually applies.

**SPIKE-*.md is per-target** (confirmed: live naming is already `SPIKE-<name>.md`, no `_LATEST`
singleton). **Deliberately flexible, not rigid** — checked 5 real live spikes: most follow the
skill's documented Question/Result/Findings/Evidence shape, but `SPIKE-frameworks.md` is a full
comparison matrix against 6 external references — a broader form the exploration genuinely
warranted. The template preserves the documented shape as the default without forcing every
spike into it, consistent with the skill's own resistance to heavy process for throwaway work.

**Artifacts:** [`templates/design.md`](../templates/design.md) (deferral template, not a full
reproduction), [`templates/spike.md`](../templates/spike.md).