# Third-Party Notices

This file credits the upstream sources that the `simple-english` skill absorbs
and synthesizes. The bigpowers repository is MIT-licensed (see [LICENSE](LICENSE),
© 2026 Daniel VM). The works below retain their original copyright notices under
their MIT licenses.

## skills/simple-english — ASD-STE100 Simplified Technical English synthesis

The `simple-english` skill is a synthesis of three MIT-licensed skills. It
combines the strongest parts of each into one canonical skill, rewritten to
pass this repo's own STE gate and adapted to the bigpowers skill format.

### AminBlg/SimpleEnglish

- Source: https://github.com/AminBlg/SimpleEnglish
- License: MIT — Copyright (c) 2026 AminBlg
- Absorbed: the 53-rule catalog, the slop-to-simple substitution table, the
  modal ladder, the doc-type adaptations, and the `ste_lint.py` regex checks
  (sentence length, contractions, banned modals, perfect tense, "-ing"
  clauses, semicolons, Latin abbreviations, slop words, trailing conditions,
  synonym rotation).

### JuanMarchetto/doc-standards-skill

- Source: https://github.com/JuanMarchetto/doc-standards-skill
- License: MIT — Copyright (c) 2026 Juan Marchetto
- Absorbed: the terminology-drift synonym-set detector, the Vale handoff
  pattern, the structural checks (heading hierarchy, non-descriptive link
  text), and the AI-readability / retrieval rules.

### cfcosta/writing-styles

- Source: https://github.com/cfcosta/writing-styles
- License: MIT — Copyright 2026 Cainã Costa
  <github.writing-styles@cfcosta.com>
- Absorbed: the core-limits table, the word-selection decision flow, and the
  dictionary entry format conventions.

### Inspiration only (no text reproduced)

- cicorias/skills (`simplified-technical-english`): the Write / Rewrite /
  Review output-mode concept informed the check-mode report format. No text
  was copied. The upstream repository declares no license; all rights are
  reserved by default, so it is treated as inspiration only.

## ASD-STE100 trademark and scope

ASD-STE100 Simplified Technical English is a registered trademark of ASD
(AeroSpace and Defence Industries Association of Europe). The standard is
maintained by the STEMG (Simplified Technical English Maintenance Group).

The `simple-english` skill is an unofficial aid. It is not affiliated with or
endorsed by ASD or STEMG. The 53 writing rules are paraphrased from
ASD-STE100 Issue 9 (2025-01-15) for educational use. No spec text is
reproduced. The official ASD-STE100 dictionary (about 900 approved words and
about 1200 unapproved words with alternatives) is copyrighted and is **not**
reproduced or distributed in this repository.

No tool can guarantee ASD-STE100 compliance. Final approval rests with the
writer. The official standard is a free download at
https://asd-ste100.org.
