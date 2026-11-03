# Harder A/B tasks — candidate catalog (e58)

Status: proposal, 2026-11-02. Nothing here is built yet.

## Why the current suite cannot tell the arms apart

The k=10 run on `opencode-go/deepseek-v4.1-flash` (`reports/AB-2026-11-02-deepseek-v4.1-flash-k10.yaml`)
put six of eight tasks at 10/10 on both arms. Delta +0.01, 95% CI [-0.05, +0.06]. The suite is at
its ceiling. Three causes:

1. **Prescriptive prompts.** Each prompt states the exact rule to implement ("exactly one @, a dot
   in the domain…"). A process that finds requirements has nothing to find. The agentv benchmark
   proposal reports the same: workflow plugins gained least (+4.5pp) on prescriptive SWE tasks.
2. **Small surface.** One file, 10–60 lines of change. There is no room for regressions, so
   discipline (tests first, reading callers) never pays off.
3. **Binary grading.** Pass/fail per run throws away how close a run got. One hidden test missed
   in a 30-test suite scores the same as nothing done.

The one task bigpowers won (ab-06 step-down refactor: 10/10 vs 7/10) is the one with a hidden
behaviour-preservation requirement and a structure requirement. That is the shape to scale up.

## Design rules for new tasks

- **Spec as a document, not a sentence.** The prompt points at `SPEC.md` (or an issue thread) with
  10–25 requirements, some implied by examples, a few only stated once.
- **Existing app, 300–1500 LOC, 5–15 files.** Feature work that touches several modules, with
  conventions the agent has to read (error shape, logging, layering).
- **Hidden regression tests.** About half the hidden tests check behaviour that already works and
  must keep working.
- **Partial credit.** Grade = share of hidden tests passing (see runner change below), plus the
  binary `pass` (all hidden tests green).
- **Own content, no copies.** Write fixtures ourselves. Public sets (Exercism, CodeCrafters,
  SWE-bench) are likely in training data, and some have licence limits. Borrow shapes, not text.
- **Node, no dependencies.** Same as ab-01..ab-08: `node:test`, `node:http`, `node:fs`. Keeps runs
  offline and fast.
- **Budget:** a vanilla run of 3–10 minutes on a flash model. Timeout 1800 s.

## Runner change needed first: partial credit

Add `score` to each run record: passed / total hidden tests, parsed from `node --test` TAP
summary (`# pass N`, `# fail M`). Report per-arm mean score and a bootstrap CI on the score delta,
next to the pass-rate delta. Without it, hard tasks return 0/10 vs 0/10 and say nothing.

`task.yaml` gets one optional key: `score: tap` (default `none` keeps today's behaviour).

## Candidate tasks

Each entry: what the fixture holds, what the prompt says, what the hidden tests check, and what
a disciplined process should win on. Sizes are estimates.

### ab-09 · Inventory API: add reservations (feature, existing app)

- **Fixture:** `node:http` inventory service, ~700 LOC: router, `items` repository on a JSON file,
  validation helpers, error middleware that returns `{error:{code,message}}`, 25 visible tests.
- **Prompt:** "Implement the reservations feature described in `docs/SPEC-reservations.md`."
- **Spec (16 reqs):** `POST /reservations` holds stock for 15 min; `available = stock − active
  holds`; expired holds release automatically (clock injected via `src/clock.js`); confirming a hold
  decrements stock; cancelling twice is idempotent; 409 on insufficient stock with the existing
  error shape; `GET /items/:id` gains `available`.
- **Hidden (≈30):** 16 spec checks, 14 regression checks on existing endpoints and error shape.
- **Rewards:** reading conventions, using the injected clock (not `Date.now()`), not breaking
  `GET /items`.

### ab-10 · Markdown subset renderer from a spec table (build from spec)

- **Fixture:** empty `src/render.js` stub, `SPEC.md` with a table of 40 input → output examples
  (headings, emphasis, nested lists, code spans, links, escaping, HTML-escape of `<`).
- **Prompt:** "Implement `render(markdown)` so it follows SPEC.md."
- **Hidden (≈60):** the 40 examples plus 20 unseen combinations of the same rules (nesting,
  emphasis inside links, edge whitespace).
- **Rewards:** turning examples into tests first, generalising rules instead of pattern-matching
  examples. Partial credit is essential here.

### ab-11 · Ledger: fix a reported bug without breaking reconciliation (bug, multi-file)

- **Fixture:** double-entry ledger library, ~500 LOC over 6 files (accounts, journal, currency
  rounding, reports). Bug report in `ISSUE.md` written by a user: "monthly report is off by a cent
  sometimes", with one screenshot-style table.
- **Prompt:** "Fix the issue described in ISSUE.md."
- **Root cause:** rounding per line instead of per total in `reports.js`; a tempting wrong fix in
  `currency.js` breaks 6 other hidden tests.
- **Hidden (≈25):** the reported case, 4 similar cases, 20 regression checks incl. currency.
- **Rewards:** reproducing before fixing, root-cause analysis (investigate-bug / diagnose-root).

### ab-12 · CLI todo app: three staged requirements in one prompt (long horizon)

- **Fixture:** small CLI (`bin/todo.js`, ~250 LOC) storing tasks in a JSON file, 12 visible tests.
- **Prompt:** an issue thread with 3 comments: (1) add due dates and `todo list --overdue`;
  (2) a later comment changes the date format to ISO-8601 and asks for `--json` output;
  (3) the maintainer asks that old data files without due dates keep loading.
- **Hidden (≈28):** each stage, the format change applied everywhere, migration of old files.
- **Rewards:** tracking changing requirements, not missing the third comment, data compatibility.

### ab-13 · Refactor a god module behind a stable API (refactor, structure)

- **Fixture:** `src/orders.js`, ~600 lines, one file doing parsing, pricing, tax, discounts and
  formatting, with 30 visible tests that only call the public API.
- **Prompt:** "Split orders.js into modules with one responsibility each. The public API and all
  behaviour must stay the same."
- **Hidden (≈35):** oracle comparison on 200 generated orders (copy of the original, as in ab-06),
  structure checks (no file > 200 lines, no module both prices and formats, public exports
  unchanged).
- **Rewards:** the ab-06 discipline at 4× the size. The strongest expected bigpowers signal.

### ab-14 · Rate-limited job queue (concurrency, build from spec)

- **Fixture:** stub `src/queue.js`, `SPEC.md` with 14 requirements: concurrency limit, per-key
  ordering, retry with backoff for failures marked retryable, cancellation, `drain()` promise,
  no unhandled rejections.
- **Hidden (≈30):** deterministic with an injected scheduler (no wall-clock timing — learned from
  ab-07/ab-08 flakiness).
- **Rewards:** edge cases (cancel during retry, drain on empty queue), test-first on async code.

### ab-15 · Config loader with precedence and validation (feature, ambiguity)

- **Fixture:** app with `src/config.js` reading one JSON file, used from 5 modules.
- **Prompt:** "Support env vars and a `--config` flag. See docs/CONFIG.md for precedence."
- **Spec:** precedence flag > env > file > defaults; `APP_DB__HOST` maps to `db.host`; type
  coercion for numbers and booleans; unknown keys are errors with the key path in the message.
  One rule (empty env var = unset) is only shown in an example.
- **Hidden (≈26):** precedence matrix, coercion, error paths, the example-only rule, and all 5
  callers still work.
- **Rewards:** reading the whole spec including examples, checking callers (assess-impact).

### ab-16 · Static site generator: add tags and an RSS feed (feature, small website)

- **Fixture:** ~400 LOC generator: reads `content/*.md` with front matter, renders HTML pages
  and an index with a tiny template engine. 15 visible tests on output files.
- **Prompt:** "Add tag pages and an RSS 2.0 feed as described in docs/SPEC-tags-rss.md."
- **Hidden (≈32):** tag pages, slugging of tags with spaces and accents, RSS validity (XML
  escaping, RFC-822 dates, sorted by date, limited to 20), drafts excluded everywhere, existing
  pages byte-identical.
- **Rewards:** byte-identical regressions, escaping edge cases, following an output standard.

## Suggested build order

1. Runner: `score: tap` partial credit (small, unblocks everything).
2. ab-13 and ab-11 first: biggest expected difference between arms, and cheapest to grade.
3. ab-09, ab-15, ab-16: realistic feature work in existing apps.
4. ab-10, ab-12, ab-14.

Each new task keeps the e58s02 rule: the unit tests prove the fixture fails and the reference
solution passes before any agent runs it. For partial-credit tasks, also record the fixture score
(should be near 0 for build-from-spec, near 0.5 for feature tasks with regression tests).

## Sources

- SWE-EVO — long-horizon, multi-file tasks; agents ~21% vs ~65% on SWE-bench Verified:
  https://arxiv.org/pdf/2512.18470
- FeatureBench — feature tasks averaging ~800 lines of change: referenced in
  https://arxiv.org/pdf/2607.26777 (CodeSpec)
- Tencent WorkBuddy Bench — baseline commit + hidden tests, mostly feature work:
  https://arxiv.org/pdf/2607.20911
- The Scaffold Effect — harness choice as a hidden variable: https://arxiv.org/pdf/2607.22585
- Vibe Code Bench — full web apps from a text spec: https://arxiv.org/html/2603.04601v1
- AppForge — 101 app-from-spec tasks; models trade function for a green build:
  https://arxiv.org/html/2510.07740v1
- SWE-AGI — spec-driven, hidden tests, standards-level specs: https://www.arxiv.org/pdf/2602.09447
- agentv issue — workflow plugins vs baseline, smallest gain on prescriptive SWE tasks:
  https://github.com/EntityProcess/agentv/issues/1100
- Spec-driven vs baseline case study (tokens ~2× for caught bugs):
  https://dev.to/dimwiddle/ai-agents-cant-mark-their-own-homework-case-study-26mk
- SWE-Skills-Bench — skills vs no-skill on ~565 instances: https://arxiv.org/html/2603.15401
- Aider polyglot (Exercism, contamination risk): https://github.com/Aider-AI/polyglot-benchmark
- usamadar/coding-agent-benchmark — hidden-test harness design:
  https://github.com/usamadar/coding-agent-benchmark
