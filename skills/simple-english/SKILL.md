---
name: simple-english
model: sonnet
effort: standard
phase: Sustain
description: Write or rewrite technical text with the rules of ASD-STE100 Simplified Technical English so the result is clear, unambiguous, and free of AI slop. Use for documentation, READMEs, runbooks, procedures, error messages, release notes, incident reports, and API guides. Also use when the user says "STE", "Simplified Technical English", "ASD-STE100", "de-slop", "make this readable", "write for non-native readers", or asks for docs that translate well. Enforces the 53 rules of the standard (Issue 9) with a deterministic lint gate.
---

# Simple English

> **HARD GATE** — Do NOT deliver technical text without classifying it first as procedural or descriptive. Every sentence limit and verb form depends on this choice.
>
> **HARD GATE** — Do NOT change code, identifiers, CLI flags, file paths, or quoted error messages. Leave them exact.
>
> **HARD GATE** — Do NOT claim STE compliance. State that final approval rests with the writer.

Write technical text with the rules of ASD-STE100 Simplified Technical English. STE removes long sentences, synonym rotation, and decorative clauses so a tired reader cannot misread an instruction.

## Your task

When asked to write or rewrite technical text, do these steps in order:

1. Select mode (**Pragmatic** default for docs/READMEs; **Strict** when user requests full STE/compliance).
2. Classify each passage as procedural or descriptive.
3. Fix vocabulary before drafting (pick one verb/noun per concept).
4. Apply core limits and rules from REFERENCE.md.
5. Run mandatory self-check before delivery.
6. Leave code, identifiers, and quoted errors untouched.

When asked to CHECK text, report each violation with rule number, offending text, and compliant rewrite.

## Passage classification

| | Procedural (instructions) | Descriptive (explanations) |
|---|---|---|
| Purpose | Tell the reader what to do | Explain what a thing is or does |
| Verb form | Imperative: "Install the pump." | Simple present, past, or future |
| Sentence limit | **20 words** (Rule 5.1) | **25 words** (Rule 6.3) |
| Unit rule | One instruction per sentence (5.2) | One topic per paragraph (6.5), max 6 sentences (6.6) |

## Core limits

| Limit | Rule |
|---|---|
| Max 20 words per procedural sentence / 25 words per descriptive sentence or note | 5.1, 6.3, 5.5 |
| Max 6 sentences per paragraph; multi-word nouns max 3 words | 6.6, 2.1 |
| Approved verbs: infinitive, imperative, simple present/past/future, past participle as adj | 3.2 |
| Active voice; no semicolons; put required conditions before commands | 3.6, 8.1, 5.4 |
| Code, numbers with units, identifiers, quoted text count as 1 word each | 8.6 |

## Approved modals & slop replacements

Approved modals: `can`, `will`, `must`. Replace `should` → `must` (requirement) or delete (recommendation); `may`/`might`/`could` → `can`.

Common slop replacements: `leverage`/`utilize` → `use`; `in order to` → `to`; `prior to` → `before`; `ensure` → `make sure that`; `functionality` → `function`/`feature`. See full table in REFERENCE.md.

## Self-check before delivery

1. Count words in 3 longest sentences (over limit → split).
2. Search draft for contractions, perfect tenses, banned modals, `-ing` verbs after comma, semicolons.
3. Check `if`/`when` placement (must start sentence before command).
4. Verify consistent single term per concept across whole doc.

## Verify

→ verify: `test -x skills/simple-english/scripts/ste_lint.py && python3 skills/simple-english/scripts/ste_lint.py --self-test && echo OK`

## Reference

- [REFERENCE.md](REFERENCE.md) — full 53-rule catalog, slop substitutions, doc-type adaptations, and verification checklist.

