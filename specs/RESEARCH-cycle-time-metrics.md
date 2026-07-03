# RESEARCH: Honest Cycle-Time / Effort Metrics for bigpowers

**Date:** 2026-07-03
**Author:** research agent (primary-source investigation)
**Status:** research — feeds a future decision on replacing hand-computed `cycle_minutes` / `bcp_per_hour`

## Problem statement

Today bigpowers derives per-story delivery metrics from two agent-written timestamps: `survey-context` writes `metrics.story_start` to `specs/state.yaml` at story start (`skills/survey-context/SKILL.md:115-117`), and `release-branch` writes `metrics.story_end`, then **hand-computes** `cycle_minutes = story_end - story_start` and `bcp_per_hour = story_bcps / (cycle_minutes/60)` and appends a row to `specs/metrics/cycle-times.yaml` (`skills/release-branch/REFERENCE.md:45-56`). This is unreliable for two reasons. (a) It is **agent self-reported and hand-arithmetic** — trivially fabricated, backfilled, or mis-subtracted (the sample data in `specs/metrics/cycle-times.yaml` is suspicious: dozens of stories at a flat `cycle_minutes: 45`). (b) Even if honest, wall-clock elapsed time between two ISO timestamps includes **overnight sleep, weekends, and the human UAT wait**, so it measures *calendar latency*, not *effort* — yet it is labelled throughput (`bcp_per_hour`). This document investigates how honest, git-derived, gate-able alternatives are built in the OSS world, reading the algorithms from source.

---

## RQ1 — Git-derived effort estimation (idle-gap stripping)

The dominant OSS pattern for "how long did coding take, from commits alone" is **session-clustering with an idle threshold**: sort a person's commit timestamps, and any gap **below** a threshold counts as continuous work (add the gap); any gap **above** the threshold ends the session, and a fixed "first-commit" constant is added to approximate the invisible work before the session's first commit.

### git-hours (kimmobrunfeldt/git-hours) — the canonical implementation

Read directly from source in `src/index.js`. The defaults are declared as:

```js
maxCommitDiffInMinutes: 2 * 60,        // 120 min — max gap still counted as one session
firstCommitAdditionInMinutes: 2 * 60,  // 120 min — added for each session's first commit
```
(`src/index.js:15,18` — cloned from https://github.com/kimmobrunfeldt/git-hours)

The estimator itself (`src/index.js:38-61`):

```js
function estimateHours(dates) {
  if (dates.length < 2) return 0;
  const sortedDates = dates.sort((a, b) => a - b);   // oldest first
  const allButLast = _.take(sortedDates, sortedDates.length - 1);
  const totalHours = _.reduce(allButLast, (hours, date, index) => {
    const nextDate = sortedDates[index + 1];
    const diffInMinutes = (nextDate - date) / 1000 / 60;
    if (diffInMinutes < config.maxCommitDiffInMinutes) {
      return hours + diffInMinutes / 60;             // same session: add the real gap
    }
    return hours + config.firstCommitAdditionInMinutes / 60;  // new session: add flat 2h
  }, 0);
  return Math.round(totalHours);
}
```

So the **idle threshold is 120 minutes** and the **first-commit padding is 120 minutes**, both CLI-overridable (`-d/--max-commit-diff`, `-a/--first-commit-add`) per the README. The README's own worked example: developers who commit more seldom "might have 4h (240min) pause between commits," so bump `--max-commit-diff 240` (https://github.com/kimmobrunfeldt/git-hours/blob/master/README.md). **Accuracy caveat, stated by the author in the README:** *"Please note that the information might not be accurate enough to be used in billing."* The whole model is a heuristic — the first commit of every session is a pure guess (a flat constant), and a lone commit with no neighbours within the threshold estimates to 0 hours.

### git-time-metric / gtm (git-time-metric/gtm) — editor events, not commits

gtm is a **different class**: it does *not* infer from commit history. Editor plug-ins call `gtm record <file>` to drop timestamped event files into `.gtm/`; at commit time a post-commit hook (`gtm commit`) buckets events into **one-minute epoch windows** (`epoch = (unixtime / 60) * 60`) and allocates each 60-second window to files by their share of events in that window. Its idle rule, quoted from the official wiki: *"idle event time may be added for up to two minutes if no editor events are triggered. Currently the amount of idle event time is not configurable"* (https://github.com/git-time-metric/gtm/wiki/Time-Tracking-Algorithm). So gtm's **idle threshold is 2 minutes**, but it requires an editor plug-in emitting events — it measures real keystroke activity, not commit spacing. There is no npm package (`npm view git-time-metric` → 404); it is a Go binary distributed via GitHub releases.

### git-quick-stats, gitinspector, code-maat, hercules — do NOT estimate effort time

These are commonly cited but, on inspection, **none produce an effort-hours estimate**:

- **git-quick-stats** (Debian package `git-quick-stats`, `apt-cache show`: "simple and efficient way to access various statistics in git repository") — commit counts, per-author/per-day/per-hour histograms, churn. No session-clustering, no hours estimate.
- **gitinspector** (`apt-cache show gitinspector`: "statistical analysis tool for git repositories"; also on PyPI as `gitinspector 0.3.2`) — lines added/removed per author, blame, timelines. No effort-time model.
- **code-maat** (adamtornhill/code-maat) — forensic VCS mining: hotspots, **temporal coupling**, code age, churn. It has a `--temporal-period` switch that treats all commits in a day as one logical change (https://github.com/adamtornhill/code-maat), but that is a *grouping* control for coupling analysis, not effort estimation. It measures *change frequency and co-change*, not *time spent*.
- **hercules** (src-d/hercules) — line-**burndown** over time (how long lines survive), governed by `granularity`/`sampling` day-band parameters (https://github.com/src-d/hercules). Again, code survival, not effort.

**RQ1 conclusion:** if you want effort from commits alone, the git-hours session-clustering model is the state of the art, and the *de facto industry default idle threshold is ~120 minutes* (with git-time-metric using a much tighter 2 min because it has real editor telemetry). Every commit-only estimate is explicitly heuristic and unfit for billing-grade precision.

---

## RQ2 — File metadata / filesystem & editor/OS telemetry

### ActivityWatch (activitywatch/activitywatch) — AFK timeout read from source

ActivityWatch's `aw-watcher-afk` watches keyboard/mouse to bucket time into "afk" vs "not-afk" events. The default config, read directly from source (`aw_watcher_afk/config.py`, https://github.com/ActivityWatch/aw-watcher-afk):

```toml
[aw-watcher-afk]
timeout = 180     # seconds — 3 min with no input → AFK
poll_time = 5     # seconds
```

Per the official docs, *"By default, a period of at least 3 minutes inactivity is flagged as AFK"* and when 3 min pass with no input, *"it is assumed that you've been AFK since the last input was received"* (https://docs.activitywatch.net/en/latest/faq.html). It stores *that* input happened, not *what*. **Idle threshold: 180 s.** Privacy: fully local/open-source, no cloud by default. Requires a running daemon + watchers on the dev machine — heavy for a solo, agent-driven, headless workflow.

### WakaTime — heartbeat + keystroke-timeout model

WakaTime editor plug-ins send **heartbeats**: when the active file changes, on save, and "every 2 mins of typing in the same file" (https://wakatime.com/faq). Heartbeats are joined into **durations** using a **keystroke timeout**, default **15 minutes**: per the official FAQ worked example, "if you typed code for 2 mins, took a 13 min break, then typed code for 1 min, your dashboard shows 16 mins" — i.e. any gap ≤ 15 min is bridged as continuous; longer gaps end the duration. **Idle/bridge threshold: 15 min (default, user-configurable).** The CLI is on PyPI (`wakatime 14.0.1`). Privacy: heartbeats are sent to WakaTime's cloud by default (self-host requires the third-party `wakapi` server). Requires an editor plug-in — same headless problem as gtm.

### RescueTime / IDE plugins

RescueTime is closed-source SaaS OS-activity tracking (foreground app + window title), cloud-hosted — a non-starter for a local, auditable, agent-driven pipeline. IDE plug-ins (WakaTime, gtm, JetBrains time trackers) all share the same precondition: **a human editor emitting events**, which does not exist when work is performed by an agent via file-write tools rather than an IDE.

### Are filesystem timestamps (mtime/ctime/atime) a viable signal? — No, too noisy.

Reasoning against filesystem timestamps as an effort signal:
- **They are not commit-provenanced.** `git checkout`, `git clone`, `git stash`, branch switches, formatters, and CI/build steps all rewrite `mtime` en masse; a fresh checkout sets every file's mtime to "now". So mtime reflects the *last filesystem event*, not authored work.
- **ctime** is inode-change time (permissions, rename, git operations bump it) — even less about content authoring.
- **atime** is frequently disabled (`noatime`/`relatime` mount options are the Linux default) so it is often meaningless.
- **No history.** The filesystem keeps only the *latest* timestamp per file, not a series — you cannot session-cluster over it the way git-hours clusters commit timestamps. Git commit metadata (author date per commit) is a *durable, replayable, tamper-evident-ish* time series; mtime is a single volatile value.

Conclusion: mtime/ctime/atime are unusable as an honest effort signal. The git commit graph is strictly better because it is an append-only, per-change, author-dated log that survives re-checkout.

---

## RQ3 — Open-source DORA implementations (priority)

The critical finding: **every canonical DORA implementation measures aggregate flow/latency (median lead time, cycle time), NOT per-item "effort." None of them strip idle time, and none produce a "hours of work" or "throughput per hour" figure.** They deliberately measure *calendar latency* from a code event to a deploy event, then report the **median/percentile over many items**, never a single story's number as a headline.

### Canonical definition — dora.dev / Accelerate

Lead time for changes is defined in *Accelerate: The Science of Lean Software and DevOps* as *"the time taken to go from code committed to code successfully running in production"* (surfaced via https://dora.dev/guides/dora-metrics/). It measures **commit → production**, explicitly *not* "idea to delivery" nor "work started to work completed." DORA treats it as one of three throughput/stability signals, always aggregated.

### Google Four Keys (dora-team/fourkeys) — read the SQL

`METRICS.md` states the definition verbatim: *"Lead Time for Changes — **Definition**: The median amount of time for a commit to be deployed into production."* The computation, quoted from `queries` in https://github.com/dora-team/fourkeys/blob/main/METRICS.md:

```sql
-- Time to Change, per change:
TIMESTAMP_DIFF(d.time_created, c.time_created, MINUTE) AS time_to_change_minutes
-- from four_keys.deployments d, joined to four_keys.changes c
```
then the median via `PERCENTILE_CONT(..., 0.5)`, bucketed over the last 3 months:
```sql
WHEN median_time_to_change < 24 * 60  then "One day"
WHEN median_time_to_change < 168 * 60 then "One week"
WHEN median_time_to_change < 730 * 60 then "One month"
...
```
Key design points, straight from the source: the timestamp pair is **change (commit) `time_created` → deployment `time_created`**; automated pushes are excluded via `IF(... > 0, ..., NULL)` (a merge that creates a push is "not its own distinct change"); and the reported number is always a **median over a 3-month window**, never a single change's raw duration. No effort/idle handling whatsoever — it is pure wall-clock commit-to-deploy.

### Apache DevLake (apache/incubator-devlake)

DevLake defines *"Lead Time for Changes measures how long it takes from commit to the code running in production"* and computes it as **PR cycle time = PR `deployed_date` − PR's **first commit's** `authored_date`**, pre-computed per PR in `pr_cycle_time` (table `project_pr_metrics`), then reports the **median** as "Median Lead Time for Changes" (https://devlake.apache.org/docs/Metrics/LeadTimeForChanges/, https://devlake.apache.org/docs/DORA/). Requires three entities: pull requests, deployments, incidents. Again: **first-commit → deploy wall clock, median-aggregated, no idle stripping, no per-hour throughput.**

### Sleuth / Faros / GetDX

These are the commercial layer over the same definitions. Sleuth and Faros ingest commits/PRs/deploys and report the same DORA four keys (lead time = commit/PR-open → deploy, aggregated medians). None publish a per-item effort metric; they explicitly frame lead time as *review-test-deploy latency*, not developer effort.

**RQ3 conclusion (the load-bearing finding for bigpowers):** the entire DORA ecosystem — Google, Apache, dora.dev, and the commercial vendors — deliberately measures **calendar latency between a code event and a deploy event, aggregated as a median/percentile over many items**. It never (a) tries to strip idle time, (b) reports a single item's duration as the metric, or (c) computes anything like `bcp_per_hour`. bigpowers' current metric is doing the one thing the industry standard avoids: presenting a single-item wall-clock number as a throughput/effort figure.

---

## RQ4 — Market consensus on the right unit

- **The industry measures latency (lead time / cycle time), aggregated — not effort, not per-item.** DORA/Accelerate, Four Keys, and DevLake all report **median (or p75) over a window**, precisely because any single item's duration is dominated by queue/wait noise (the same overnight/weekend/UAT gaps that break the bigpowers metric). Four Keys hard-codes a 3-month window; DevLake reports "Median Lead Time."
- **Per-story duration is not treated as a stable metric.** It is an input to a distribution, not a headline. This is the flow-metrics consensus (cycle-time scatterplots + percentiles, e.g. Kanban/Actionable Agile), and it is why Four Keys buckets rather than quoting single values.
- **"Active coding time" is a distinct, weaker signal** owned by the time-tracker tools (WakaTime/gtm/ActivityWatch), which the DORA world does not fold into lead time. There is **no single standardized idle threshold** across the field — the observed defaults are: **git-hours 120 min**, **WakaTime 15 min**, **ActivityWatch 180 s**, **gtm 2 min**. The threshold tracks the *signal granularity*: coarse (commits) → large threshold; fine (keystrokes) → small threshold.

---

## Comparison of candidate approaches

| Approach | What it measures | Data source | Idle handling / threshold | Accuracy | OSS example (primary link) |
|---|---|---|---|---|---|
| Current bigpowers | Wall-clock calendar latency (mislabeled as throughput) | 2 agent-written ISO timestamps in `state.yaml` | None — raw `end − start`; includes sleep/weekend/UAT | Poor; self-reported, hand-computed, fabricable | `skills/release-branch/REFERENCE.md:45-56` |
| git-hours session clustering | Estimated coding **effort** hours | Commit author timestamps (git only) | Gap < **120 min** = same session; else +120 min first-commit pad | Heuristic; author says "not accurate enough for billing" | git-hours `src/index.js:15,18,38-61` |
| gtm | Active editing time per file | Editor plug-in events → `.gtm/` | **2 min** idle add, not configurable | Good *if* editor emits events; needs plug-in | git-time-metric/gtm wiki: Time-Tracking-Algorithm |
| WakaTime | Active coding time | Editor heartbeats → cloud | Bridge gaps ≤ **15 min** (default) | Good with plug-in; cloud by default | wakatime.com/faq; PyPI `wakatime 14.0.1` |
| ActivityWatch | Active (non-AFK) OS/editor time | OS input watcher daemon | AFK after **180 s** no input | Good, local; heavy daemon | aw-watcher-afk `config.py` (timeout=180) |
| Filesystem mtime/ctime/atime | Last FS event (NOT authored work) | inode timestamps | N/A — single volatile value | Unusable; rewritten by checkout/format/CI | — |
| DORA lead time (Four Keys) | **Calendar latency** commit → deploy, median | commit `time_created` → deploy `time_created` | None; excludes automated pushes; **median over 3 mo** | Industry standard *as latency*, aggregated | fourkeys `METRICS.md` (PERCENTILE_CONT) |
| DORA lead time (DevLake) | Calendar latency first-commit → deploy, median | PR first commit `authored_date` → `deployed_date` | None; **median** `pr_cycle_time` | Industry standard, aggregated | devlake.apache.org/docs/Metrics/LeadTimeForChanges |

---

## Terminal enumeration (mandatory step — real commands & output)

`gh` is not installed in this workspace, so `gh search repos` was unavailable; GitHub enumeration was done via `git clone` + `web_fetch` of raw source and via `npm view`/`apt-cache`/`pip index` instead.

```
$ which git-hours gtm code-maat gitinspector git-quick-stats hercules
# (no output — none installed)  exit=1

$ npm view git-hours
git-hours@1.5.0 | MIT | deps: 5 | versions: 11
Estimate time spent on a git repository
https://github.com/kimmobrunfeldt/git-hours
keywords: git, time, spent, tracking, clock, hours
bin: git-hours   deps: bluebird, commander, lodash, moment, nodegit
published over a year ago by kimmobrunfeldt   dist-tags: latest 1.5.0

$ npm view git-time-metric version
npm error 404 Not Found   # gtm is a Go binary, not on npm

$ apt-cache search git | grep -iE "hour|time|stat|metric"
git-quick-stats  - simple and efficient way to access various statistics in git repository
git-restore-mtime - set timestamps to the date of a file's last commit
git-sizer        - compute various size metrics for a Git repository
gitinspector     - statistical analysis tool for git repositories
elpa-git-timemachine - walk through git revisions of a file

$ apt-cache search activity | grep -iE "watch|track"
arpwatch, hamster-time-tracker, watchman, webext-lightbeam   # no ActivityWatch pkg
$ apt-cache search dora
# (nothing relevant — no DORA package in Debian)

$ pip index versions gitinspector
gitinspector (0.3.2)   Available versions: 0.3.2
$ pip index versions wakatime
wakatime (14.0.1)      # WakaTime CLI available on PyPI
$ pip index versions aw-core
aw-core (0.5.17)       # ActivityWatch core library available on PyPI

$ git clone --depth 1 https://github.com/kimmobrunfeldt/git-hours.git
# → cloned; algorithm read from src/index.js (see RQ1)

$ web_fetch aw-watcher-afk/config.py  →  timeout = 180, poll_time = 5
$ web_fetch fourkeys/METRICS.md       →  lead time SQL (see RQ3)
```

**Enumeration takeaways:** the only OSS tool that estimates *effort from commits alone* and is trivially installable is **git-hours** (`npm i -g git-hours`, MIT, but drags in the heavy native `nodegit` dependency). Everything else on the effort side (gtm, WakaTime, ActivityWatch) needs a live editor/OS agent that does not exist in a headless, agent-driven pipeline. The DORA tools (Four Keys, DevLake) are not packaged in apt/npm/pip at all — they are deploy-a-service platforms whose *SQL definitions* are the reusable part, not their code.

---

## Recommendation for bigpowers

**Recommendation: replace the two hand-written timestamps and hand-arithmetic with a single, deterministic, git-derived script that computes two clearly-separated per-story fields — an *additive effort estimate* (idle-stripped, whose per-story values sum to a meaningful project total) and a separately-labelled *lead time* (calendar latency). Never let the agent do the subtraction; a script reads the git log at merge time. Gate on the pipeline running, not on the number.**

Rationale against the constraints:

1. **Git is already the source of truth.** bigpowers uses `release-branch` and per-story commits, so a story's commit set is knowable at merge time by trailer/branch/commit-range. No new telemetry, no daemon, no editor plug-in — the exact fit for a headless, agent-driven, solo workflow. gtm/WakaTime/ActivityWatch are ruled out precisely because they need a human-in-an-IDE event stream.

2. **Survives overnight/weekend/UAT gaps by construction — via idle-gap dropping.** Sort commits by author-date; a gap **below 120 minutes** counts as real elapsed effort, a gap **≥ 120 minutes** (overnight/weekend/UAT wait) is dropped. This is git-hours' core insight (`src/index.js:15` `maxCommitDiffInMinutes: 2*60`). This is the single most important property the current metric lacks.

3. **ADDITIVITY (hard constraint: total = Σ per-story). Do NOT run git-hours independently per story and sum — the source algorithm provably does not support it** (confirmed by red-team simulation). Each git-hours run pads its own first commit and drops its own leading gap, so per-story-then-sum leaks *both* directions: it **undercounts** the inter-story gaps a whole-repo run would count, and **overcounts** by re-padding when two stories interleave in one session. Whole-repo git-hours is *not* the sum of its per-story slices. To make Σ(story effort) = total effort an identity, compute effort as a **global partition of the commit stream**:

   a. **Partition every commit into exactly one story bucket** (by branch, commit-range, or a `Story:` trailer). Unattributable commits (main-only, hotfixes, infra) go to an explicit `unattributed` bucket so nothing silently vanishes. Dedupe by commit SHA (cherry-picks); exclude merge commits (`--no-merges`).

   b. **Attribute each inter-commit gap deterministically.** Sort *all* commits globally by author-date. For each adjacent pair with gap `g`: if `g < 120 min`, add `g` to the bucket of the **later** commit (the work that produced it); if `g ≥ 120 min`, contribute **0** to any bucket (the dropped idle gap).

   c. **Apply first-commit padding once per session, globally — not per story.** Add one flat pad per detected session boundary, attributed to that session's first commit's story (or drop padding entirely for simplicity). This guarantees the pad count equals the whole-repo pad count, so no `N×120 min` inflation.

   By construction, `Σ(story effort) = Σ(gaps < 120 min) + (global pads) = whole-repo effort` exactly. **Honesty caveat to document:** when two stories share a single <120-min window, those minutes land in whichever story's commit *closed* each sub-interval — an attribution *convention*, not a physical truth. It is the only way to keep the numbers summable without double-counting.

4. **Lead time is kept per-story but must NEVER be summed — aggregate by median.** Lead time (**first-commit → merge**, computed like Four Keys `TIMESTAMP_DIFF(deploy, commit)` / DevLake `deployed_date − first_commit.authored_date`) is a calendar interval; parallel branches have overlapping intervals, so `Σ(lead times)` double-counts and is meaningless. Label it *lead time (calendar latency)*, aggregate by **median/p75 over many stories** (the DORA consensus), never sum. Retire `bcp_per_hour` as a per-story headline; a ratio is non-additive — if a rate is wanted, report `median(bcp / effort_hours)` over a window (cite: fourkeys `METRICS.md`; devlake LeadTimeForChanges). *Note: Four Keys and DevLake both expose a per-item value internally; what is standardised is that the **reported** metric is a median of calendar latency, never idle-stripped effort.*

5. **Kills fabrication / hand-arithmetic.** The numbers are recomputed from `git log` by a script (`scripts/record-cycle-time.sh` invoked from `release-branch`), so they cannot be back-filled or mis-subtracted — the same discipline Four Keys/DevLake enforce by computing from event timestamps rather than a self-report.

6. **Gate on the pipeline, not the value.** The compliance/golden gate asserts that (a) the script ran and produced a row per merged story, and (b) no row exists without a real `commit_range` in git. Do **not** gate on a specific effort value — a heuristic estimate is not pass/fail, and git-hours' own author warns it is "not accurate enough to be used in billing." Gate on *provenance and freshness*.

**Concrete shape:** deprecate `metrics.story_start`/`story_end` hand-arithmetic in `survey-context`/`release-branch`; at merge, run a script that emits per story: `effort_hours` (global-partition, additive, threshold recorded), `lead_time_minutes` (first-commit → merge, median-aggregated, never summed), `commit_count`, `commit_range`, and an `unattributed` roll-up bucket. Roadmap fit: the effort/lead-time split lands in **e35 (DORA Metrics)**, the provenance gate in **e31 (deterministic gates)**, and a golden-story lock in **e37**. If keystroke-level fidelity is ever wanted, ActivityWatch (local, `timeout=180`) is the only privacy-preserving option — out of scope for a headless agent pipeline today.

---

### Primary sources

- git-hours algorithm & defaults — https://github.com/kimmobrunfeldt/git-hours (README + `src/index.js:15,18,38-61`, cloned & read)
- git-time-metric / gtm idle rule — https://github.com/git-time-metric/gtm/wiki/Time-Tracking-Algorithm
- code-maat — https://github.com/adamtornhill/code-maat ; hercules — https://github.com/src-d/hercules
- ActivityWatch AFK default (`timeout=180`) — https://github.com/ActivityWatch/aw-watcher-afk (`aw_watcher_afk/config.py`) ; docs — https://docs.activitywatch.net/en/latest/faq.html
- WakaTime heartbeat / 15-min timeout — https://wakatime.com/faq
- Four Keys lead-time SQL & definition — https://github.com/dora-team/fourkeys/blob/main/METRICS.md
- Apache DevLake lead time (first-commit → deploy, median) — https://devlake.apache.org/docs/Metrics/LeadTimeForChanges/ , https://devlake.apache.org/docs/DORA/
- DORA canonical definition — https://dora.dev/guides/dora-metrics/
- bigpowers current impl — `skills/survey-context/SKILL.md:115-117`, `skills/release-branch/REFERENCE.md:45-56`, `specs/metrics/cycle-times.yaml`
