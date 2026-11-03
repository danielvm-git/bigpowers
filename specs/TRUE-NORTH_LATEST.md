# bigpowers — Evaluation and True North (November 2026)

**Date:** 2026-11-02 · **Version evaluated:** bigpowers v2.89.0 (main @ 1877cc56)
**Question:** Better models and the growth of spec-driven development (SDD) split opinion. One camp says a harness like bigpowers is no longer needed. The other says software engineering discipline matters more than ever. What does the evidence say, how does bigpowers measure up, and what should it aim at next?
**Method:** Web research (papers, practitioner blogs, Hacker News, classic computer-science essays, vendor playbooks), then a check of this repo's own history, metrics and roadmap. Limits are listed at the end.

---

## 1. Bottom line

1. **Both camps are right, about different layers.** The evidence splits the "harness" into two parts that are moving in opposite directions:
   - **Process prose is losing value.** This means instructions that tell a capable model *how to think*: how to plan, how to do TDD, which phase it is in. Models now carry most of this knowledge. Simon Willison says the four words "Use red/green TDD" are enough. Long instruction files add cost and give little or no gain in accuracy.
   - **Verification and intent are gaining value.** This means deterministic checks, hooks, CI, evals, feedback loops, and a durable record of *what* to build and *why*. When code is cheap, review and proof become the bottleneck. OpenAI's "harness engineering" team, DORA 2025 and the review-bottleneck data all point to the same thing.
2. **bigpowers is strong on the second part but spends most of its effort on the first.** It already has the right parts: the git-native YAML record, Always Green, traceability, a RED-commit verifier, and an honest red-team habit. But 80 skills (~45k words), a 399-line `CLAUDE.md`, an 8-step story cycle, a 94% self-compliance gate and ~16 integration epics are the kind of process prose that new models make less useful.
3. **bigpowers has no proof that it helps.** There is no with-vs-without comparison, the golden suite is saturated at 8/8, and `specs/metrics/cycle-times.yaml` has **0** story entries. The project cannot answer the question the user asked: *does a developer do better with bigpowers than with vanilla Claude Code?*
4. **The project already knows most of this.** `specs/BIGPOWERS-REBORN.md` concluded to cut to ~28 procedures, drop the copy-paste sync pipeline, and replace the 94% gate with outcome evals. Those epics (e56, e58) are still `scoped`, while integration epics shipped. The gap is in execution and focus, not in insight.

**Proposed true north:**

> **"Prove it or delete it."** bigpowers is the smallest harness that lets a solo developer and an agent ship software that is *verified* and *understood*. Each part of it must do one of these: (a) enforce something deterministically, (b) record human intent the model cannot infer, or (c) show a measured gain over vanilla in bigpowers' own public evals. Anything else goes.

This position stays useful whichever way the debate goes. If models get good enough that a skill stops helping, the evals show it and the skill is deleted. If engineering discipline keeps mattering, the verification layer keeps it in place.

---

## 2. What the evidence says

### 2.1 The "you don't need a harness" camp

| Claim | Evidence |
|---|---|
| Models already know the process | Mario Zechner's **pi** runs on four tools and a system prompt under 1,000 tokens, and does well on Terminal-Bench. Zechner says a 10,000-token system prompt does not seem necessary ([pi overview](https://agentic-ai.readthedocs.io/en/latest/AgentHarness/pi-dev/), [AI Engineer talk](https://www.ai.engineer/talks/RjfbvDXpFls-pi-coding-agent)). Armin Ronacher now uses pi almost exclusively ([lucumr](https://lucumr.pocoo.org/2026/1/31/pi/)). |
| The creator of Claude Code uses a vanilla setup | Boris Cherny starts in plan mode, iterates on the plan, then auto-accepts edits. He keeps CLAUDE.md for recurring mistakes and checks in a few slash commands ([summary](https://getpushtoprod.substack.com/p/how-the-creator-of-claude-code-actually)). Builder Methods: "Claude Code is all you need in 2026" ([link](https://buildermethods.com/library/claude-code-is-all-you-need-in-2026)). |
| Bitter lesson: scaffolding loses to model scaling | Browser Use: keep the harness thin and let the agent write what it needs ([post](https://browser-use.com/posts/bitter-lesson-agent-harnesses)). Hugo Bowne-Anderson: simplify the harness continuously as models improve ([post](https://hugobowne.substack.com/p/ai-agent-harness-3-principles-for)). |
| SDD tools have faded | "Ask HN: What Happened to Spec-Driven Development?" (Aug 2026) asks whether everyone decided `/plan` mode was enough. A reply: "Agents are already too good … just start with a plan.md" ([HN](https://news.ycombinator.com/item?id=49182353)). |
| Context files add cost, not accuracy | ETH Zurich (Gloaguen et al., 2026): AGENTS.md-style files gave no gain in task success and raised inference cost by more than 20%. LLM-generated files cut success by about 3%, human-written files added about 4% ([arXiv 2602.11988](https://arxiv.org/abs/2602.11988)). A two-agent ablation found no correctness benefit from generic context files ([arXiv 2607.27250](https://arxiv.org/html/2607.27250v1)). See also [Upsun: your AGENTS.md is probably too long](https://developer.upsun.com/posts/ai/agents-md-less-is-more). |
| The harness changes cost more than success | Scaffold Effect (ICML 2026): harness choice causes a **40× token-cost** difference but moves pass rate by **≤ 8 pp** ([arXiv 2607.22585](https://arxiv.org/pdf/2607.22585)). Arena.ai: similar success rates at up to 5× cost across 21 model-harness pairs ([post](https://arena.ai/blog/coding-agents-harness-tax/)). |
| Skills help software engineering the least | SkillsBench: curated skills add +16.2 pp on average, but only **+4.5 pp for software engineering**, 16 of 84 tasks got worse, and self-generated skills scored −1.3 pp ([arXiv 2602.12670](https://arxiv.org/abs/2602.12670v1)). |

### 2.2 The "engineering still matters" camp

| Claim | Evidence |
|---|---|
| Essential complexity remains | Brooks's essence/accident split, applied to agents: agents are very good at accidental complexity, while the essential part (what to build, correct intent) is still the bottleneck ([O'Reilly: The Mythical Agent-Month](https://www.oreilly.com/radar/the-mythical-agent-month/), [Wes McKinney](https://wesmckinney.com/blog/mythical-agent-month/), [sicpers](https://sicpers.info/posts/2025-11-27/essence-and-accident-in-language-model-assisted-coding/)). |
| Programming is theory building | Naur (1985), applied to agents: agents rebuild their understanding from zero each session, and code nobody holds a theory of is a liability ([Sean Goedecke](https://www.seangoedecke.com/programming-with-ai-agents-as-theory-building), [Carsten](https://carsten-j.github.io/2025/12/17/programming-as-theory-building.html), [ratfactor](https://www.ratfactor.com/cards/naur-vs-llms)). Addy Osmani calls the result "comprehension debt" ([summary](https://www.coderabbit.ai/guides/pr-summary-vs-pr-explainability)). |
| Natural language is not a spec | Dijkstra, EWD 667 (1978). An HN commenter puts it this way: a spec does not fix one implementation, so "the code is the only source of truth" ([HN](https://news.ycombinator.com/item?id=49182353)). Böckeler found Tessl can produce different code from the same spec ([martinfowler.com](https://www.martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html)). |
| Senior voices | Grady Booch calls the claim that software engineering will be automated in 12 months "profoundly wrong" and calls this a "third golden age" ([Pragmatic Engineer](https://newsletter.pragmaticengineer.com/p/the-third-golden-age-of-software)). Karpathy moved from "vibe coding" to "agentic engineering", where a human stays accountable for spec, quality and taste ([summary](https://www.theaiopportunities.com/p/sequoia-ai-ascent-2026-andrej-karpathy)). Kent Beck: agents are an "unpredictable genie" that may delete tests to make them pass. TDD is a "superpower" ([podcast](https://newsletter.pragmaticengineer.com/p/tdd-ai-agents-and-coding-with-kent)). |
| The harness that works is mechanical | OpenAI "harness engineering": about 1M lines with no hand-written code. Engineers "design environments, specify intent, and build feedback loops". Architecture is enforced by **mechanical rules and structural tests**. The bottleneck became **human QA capacity** ([OpenAI](https://openai.com/index/harness-engineering/), [InfoQ](https://www.infoq.com/news/2026/02/openai-harness-engineering-codex)). |
| AI amplifies what is already there | DORA 2025: AI raises throughput but still hurts **stability** unless the foundations are solid ([DORA](https://dora.dev/insights/dora-2025-year-in-review/), [InfoQ](https://www.infoq.com/news/2025/09/dora-state-of-ai-in-dev-2025)). |
| Review is the new bottleneck | Faros (10k+ devs): high-AI teams merge 98% more PRs, but review latency is up 91% and PR size up 154% ([Built In](https://builtin.com/articles/ai-breaking-agile-solutions)). Werner Vogels calls this "verification debt" ([Sonar](https://www.sonarsource.com/resources/library/ai-code-verification-debt/)). |
| Proof will get cheaper | Kleppmann: AI will make formal verification mainstream, and the hard part moves to writing the right specification ([blog](https://martin.kleppmann.com/2025/12/08/ai-formal-verification.html)). |
| Productivity is easy to misjudge | METR 2025: experienced developers were 19% slower with AI but felt 20% faster. METR now calls that result historical, and its 2026 follow-up leans toward a speedup that is not yet reliable ([TechCrunch](https://techcrunch.com/2025/07/11/ai-coding-tools-may-not-speed-up-every-developer-study-shows), [urandom](https://urandom.io/blog/2026-03-01-ai-made-developers-slower-then-december-happened)). Lesson: **measure, do not trust how it feels**. |

### 2.3 What SDD critics say, and how it applies to bigpowers

- **Böckeler (Thoughtworks):** Kiro turned one small bug fix into 4 user stories with 16 acceptance criteria. Spec-kit is the heaviest of the tools she tried and causes "review overload". Most tools are *spec-first* only ([martinfowler.com](https://www.martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html)).
- **"Waterfall strikes back":** Specs go stale, there is "a constant consistency tax", and you end up with "hundreds if not thousands of spec files in MD" ([HN](https://news.ycombinator.com/item?id=45935763)). The counter-argument is that waterfall compressed from months into hours is a different thing.
- **HumanLayer (Dex Horthy):** Research → Plan → Implement works, but monolithic plans grew to 1,000 lines that nobody could review. The fix was smaller plans and deliberate compaction ([summary](https://second-brain-nuxt.vercel.app/no-vibes-allowed-solving-hard-problems-in-complex-codebases)).

bigpowers has the same risk profile. In the [SDD structure ranking](sdd-adequacy-ranking.md), "Evolved bigpowers" scores 50/50 on criteria taken from its own principles. That is a self-assessment and not evidence.

### 2.4 Synthesis

| Layer | Trend | bigpowers today |
|---|---|---|
| Teaching the model *how* to plan, TDD, review (process prose) | ↓ The model already knows it. Each new release reduces the value. | **Very large:** 80 skills, ~45k words, a 6-phase lifecycle, an 8-step cycle |
| Per-tool adapters | ↓ Agent Skills and AGENTS.md became cross-tool standards | **Very large:** about 16 integration epics; generated adapter dirs got about 6.2k file changes |
| Durable intent: scope, decisions, glossary, acceptance criteria | → Stable. Needed as long as humans decide what to build | **Strong:** the specs/ YAML record, ADRs, next_skill handoff |
| Mechanical enforcement: hooks, CI gates, test lock, structural tests | ↑ This is where "harness engineering" pays off | **Partial:** Always Green and traceability exist; the RED verifier is not wired in (e86) |
| Outcome evals per model release | ↑ The only way to settle the debate for a given setup | **Missing:** the 94% gate is self-referential; e58 is still scoped |
| Human comprehension: small diffs, explanation, review aid | ↑ Review and verification debt are the new bottleneck | **Weak:** nothing targets the solo developer's understanding of the code |

---

## 3. bigpowers scorecard (evidence from this repo)

| Fact | Value | Source |
|---|---|---|
| Age and pace | First commit 2026-02-03. 1,071 commits and 239 tags. 631 commits in July, about 27/month from August to October | `git log` |
| Catalog size | 80 skills, ~45k words of SKILL.md. 114 scripts, ~16k lines of Bash | `skills/`, `scripts/` |
| Always-loaded instructions | `CLAUDE.md` 399 lines (above the project's own P2 300-line cap), plus `CONVENTIONS.md` 486 lines | `wc -l` |
| Where the effort went | File changes: `specs/` 9,534, generated adapter dirs (.gemini, .pi, .cursor, .kilocode, .windsurf) 6,159, **`skills/` 629**. The product itself got about 4% of the change volume of specs and adapters combined | `git log --name-only` |
| Outcome evidence | Golden suite 8/8 (saturated, no with/without baseline). `cycle-times.yaml`: **0** stories. Receipts metrics: 1 estimated story | `specs/benchmarks/`, `specs/metrics/`, `specs/receipts.json` |
| Adoption | 288 GitHub stars, 24 forks. npm: 9,415 downloads last month (frequent releases and mirrors inflate this) | GitHub and npm APIs, 2026-11-02 |
| Peers (stars) | Superpowers 311k · spec-kit 145k · OpenSpec 74k · GSD 64k · BMAD 55k | GitHub API, 2026-11-02 |

**Strengths to keep**

- **The git-native, YAML intent record** (`state.yaml`, scope, ADRs, glossary, `next_skill` handoff). This matches Böckeler's "spec-anchored" level and is the most durable idea in SDD.
- **Always Green and fix-or-log.** This is the DORA "solid foundations" condition, written down as doctrine.
- **Story traceability and a CI gate,** a RED-commit verifier, and security-review. This is mechanical enforcement, the part that gains value.
- **A habit of honest self-critique.** The Reborn analysis, red-team passes and value engineering are rare in this space and worth a lot.
- **Harness neutrality as a value.** This is correct, but it should come from standards (Agent Skills, AGENTS.md, git hooks, CI) and not from bespoke adapters.

**Weaknesses to fix**

1. **No falsifiable claim of value.** The README promises "senior-grade quality", but no data compares bigpowers with vanilla.
2. **Too much process prose.** This is the layer that SkillsBench (+4.5 pp for software engineering), the AGENTS.md studies and pi's design show losing value.
3. **Too much ceremony for one developer.** BCP 13D, WSJF, an 8-step cycle and a 6-phase gate: Böckeler's critique of spec-kit applies with more force here.
4. **Effort turned inward.** Most of the work went into the methodology's own repository and adapters, not into the 80 skills users actually run.
5. **The roadmap KPI is another conformance score.** e84–e88 aim at "Anthropic playbook coverage". Playbook coverage, like the 94% gate, measures *conformance*, not *outcomes*.

---

## 4. The roadmap, re-ranked against the true north

Test for every epic: *does it (a) enforce something mechanically, (b) record intent, or (c) produce outcome evidence?* If none of these, pause it.

| Epic | Now | Verdict | Why |
|---|---|---|---|
| **e58** Evals Over Compliance | scoped | **DO FIRST. Expand it.** | Build an A/B runner: about 15 real tasks (from the showcase repo plus brownfield bugs), *vanilla agent vs. bigpowers*, k≥3 runs each. Measure pass rate, tokens and cost, test deletions, escaped defects, and wall time. Publish the results on the receipts page. Retire the 94% gate. |
| **e86** Hooks Enforce | scoped | **DO.** Top-value build epic | Turns prose rules into checks: wire `verify-tdd-red-commit.sh`, protect generated paths, add approval gates. This is the "mechanical rules and structural tests" layer. |
| **e84** AGENTS.md First | scoped | **DO, and make it smaller** | One harness-neutral file. Also cut always-loaded instructions to about 100–150 lines, the size the research supports. Move the RTK, sqz and bts boilerplate out of the always-loaded file. |
| **e83** Truth in the Cockpit | scoped | **DO** (small) | Cockpit metrics that are wrong undermine the receipts. |
| **e56** Reclassify Catalog | scoped | **DO after e58, driven by its data** | Target ≤ 25 procedures. Delete or merge any skill with a delta ≤ 0. Replace skills whose content is general knowledge with a single line (e.g. "Use red/green TDD; confirm RED before GREEN"). |
| **e87** Agent at the PR | scoped | **Change the focus** | Aim at the *human's* understanding: small PRs, a "what changed and why" explanation, risk tier, evidence links. Do not add more agent-to-agent review. |
| **e88** Maintain Loop | scoped | Later | Useful, but only after evals exist to show it helps. |
| **e85** Count BCP the 13D Way | scoped | **Pause or drop** | `cycle-times.yaml` has 0 entries, so the existing sizing system has never been measured. Adding a more detailed procedure adds ceremony without evidence. Keep BCP optional. |
| **e57** OKF Envelope, **e59** bigspec sync | scoped | **Pause** | These reorganize the internals. They add no user-facing value until evals show the core works. |
| **e61, e64, e69, e74, e75, e76** integrations | scoped | **Stop new adapters** | Rely on the Agent Skills format, AGENTS.md, git hooks and CI. Keep one thin adapter only where a tool needs hook wiring. Archive the per-tool epics. |
| **e82** Jujutsu and OMP | scoped | Accept contributions as given | Community health matters, but this is not core. |

### Proposed sequence

1. **Weeks 1–3: Measure.** Build e58 as a with-vs-without runner and run it on the current model. Publish the first honest numbers, even if they are bad. This alone sets bigpowers apart from every peer listed above, none of which publishes such numbers.
2. **Weeks 3–6: Enforce and shrink.** Ship e86, e84 (small) and e83. Cut always-loaded context by more than 60%.
3. **Weeks 6–10: Cut by evidence.** Run e56 on the eval data and go from 80 to ≤ 25 skills. Archive the integration epics. Collapse the 8-step cycle into *intent → plan → red/green → verify → ship*, with risk tiers deciding how much ceremony applies.
4. **On every new frontier model: retest.** Rerun the eval suite and delete anything whose delta reaches zero. This is the bitter lesson built in as a routine, not something to argue about.

### New north-star metrics (replace skill count and the 94% gate)

| Metric | Target |
|---|---|
| Pass-rate delta, bigpowers vs vanilla, on the eval suite | > 0 with a confidence interval; publish it either way |
| Token and cost delta | ≤ +25% for any accuracy gain (the Scaffold Effect shows cost is where harnesses diverge) |
| Escaped defects and test deletions per task | Lower than vanilla |
| Always-loaded instruction lines | ≤ 150 |
| Skills in catalog | ≤ 25, each with a measured reason to exist |
| Time to first value for a new user | ≤ 10 minutes from `npx` to a green first story |

### Positioning for the README (one line)

> *bigpowers is the measured harness for solo developers: it records what you meant, enforces what must hold, and deletes whatever the current model no longer needs — with public before/after evals to prove it.*

---

## 5. Limits of this research

- **Reddit and X:** Reddit is blocked in the research browser, and search engines did not return threads from r/ClaudeAI or X. The community view comes from Hacker News threads and practitioner blogs instead.
- **Secondary sources:** Many claims come from secondary summaries and were not checked against the full papers or talks (SkillsBench numbers per domain, the Karpathy quotes, Faros figures, METR 2026). They are marked as summaries above. Treat the exact numbers as directional.
- **Vendor bias:** Sonar, CodeRabbit, Faros and Augment sell into the review and SDD problem.
- **Star counts** come from the GitHub API on 2026-11-02. npm download counts include mirror and CI traffic.
- **No new experiment was run.** The main recommendation is to run one (e58).
