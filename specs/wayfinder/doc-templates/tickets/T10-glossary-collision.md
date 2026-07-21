<!-- wayfinder:grilling -->
# T10 — glossary-collision

**Type:** Grilling (HITL) · **Status:** CLOSED · **Claim:** driver
**Blocks:** collision #3 from T7's priority-ordered list · **Blocked by:** T7 (closed)
**Corrects:** T4's ruling that UBIQUITOUS_LANGUAGE merges into GLOSSARY — that was a filename
guess, not a read of the actual `define-language` contract. See below.

## Question

TGDP's `glossary/`+`terminology-system` pack, bigpowers' `GLOSSARY_LATEST.yaml`, and the
`define-language` skill's `UBIQUITOUS_LANGUAGE_LATEST.md` output all look like glossaries.
Which survives?

## Resolution

**Round 1 (superseded — see round 2):** proposed two glossaries — a "methodology glossary"
(BCP/WSJF/OKF, composed from the live YAML + TGDP table) shipped to every consumer app, plus
`define-language`'s domain glossary. **User correction: this repeats the bigpowers-about-itself
mistake (same class as T4 ruling #1, the skill-catalog exclusion).** A consumer app's docs must
never carry bigpowers' own jargon glossary — a contributor to some stranger's e-commerce app has
no reason to see "what is BCP" in their project's public docs.

**Round 2 (final):** **one glossary template, not two.** `GLOSSARY_LATEST.yaml` isn't a second
*kind* of glossary — it's bigpowers' own domain glossary, for bigpowers' own domain (software
methodology). The same template, applied to a retail app, would glossary Order/Customer/Invoice
instead. One doctrine; content varies by which repository runs it on itself.

**Shape:** `define-language`'s existing output contract wins over TGDP's flat table — it expresses
relationships, aliases-to-avoid, and a worked dev↔domain-expert dialogue, none of which a
term/definition table can hold. Kept `related_terms` cross-linking from the live YAML (the same
cross-reference idea from the Karpathy llm-wiki thread). `terminology-system` (Usage/Notes, not
Definition — closer to style-guide territory) does not get its own template; folds as optional,
non-priority guidance.

**Scope correction propagated:** no "methodology glossary" ships in the consumer-app template set,
ever. `GLOSSARY_LATEST.yaml`-as-bigpowers-content stays bigpowers-internal, same rule as the skill
catalog (T4 ruling #1) — it is not a counter-example to that rule, it's confirmation of it.

**Artifact:** [`templates/glossary.md`](../templates/glossary.md).