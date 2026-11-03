# Handoff: run the hard A/B tasks 100 times (k=100)

Paste everything below the line into the agent (pi via Orca). It is self-contained.

---

You are running a benchmark in the bigpowers repo. Measure only. Do not change the runner, the
tasks, the skills or any spec. Do not push.

## Where

- Worktree: `/Users/danielvm/Developer/bigpowers/.claude/worktrees/bigpowers-bug-investigation-9fa73c`
- Branch: `danielvm-git/bigpowers-evaluation-roadmap-4d0758`, at or after the commit that adds the `pi` adapter (e58s06)
- Run every command from the worktree root. Read `specs/benchmarks/SCHEMA.md` (section "A/B outcome
  eval") first. It explains arms, tasks, hidden tests, `score` and the report fields.

## What

Run the A/B eval on the two hard tasks with k=100 per arm:

- Tasks: `ab-11` (ledger rounding bug) and `ab-13` (orders module split)
- Arms: `vanilla` and `bigpowers`
- Adapter: `pi` (the default; OpenCode Go provider, credential already in `~/.pi/agent/auth.json`).
  Each run uses an isolated pi config folder, so your global pi settings and packages never load.
- Model: `opencode-go/deepseek-v4.1-flash`
- Total: 2 tasks × 2 arms × 100 = **400 agent runs**

Expect about $3–8 of Go quota and 8–9 hours if run one after another. Run in shards instead (below).

## Preflight checks (stop and report if any fails)

```bash
pi auth check --provider opencode-go | grep -q ready
python3 tests/test_ab_score.py
bash scripts/run-ab-eval.sh --dry-run --tasks ab-11,ab-13 --k 1 | grep -q "adapter 'pi'"
```

## Run in shards

The runner is sequential, so run 10 shards in parallel (5 per task, k=20 each), each with its own
output folder. Shards must never share an `--out` folder: report files are named by date.

```bash
OUT=/tmp/bp-ab-k100; mkdir -p "$OUT"
for task in ab-11 ab-13; do
  for shard in 1 2 3 4 5; do
    bash scripts/run-ab-eval.sh --model opencode-go/deepseek-v4.1-flash \
      --tasks "$task" --k 20 --arms vanilla,bigpowers --out "$OUT/$task-$shard" \
      > "$OUT/$task-$shard.log" 2>&1 &
  done
done
wait
grep -h '^EXIT\|Wrote' "$OUT"/*.log; ls "$OUT"/*/ab-runs-*.jsonl | wc -l   # expect 10
```

(5 shards × k=20 = 100 per task and arm. Run indices repeat across shards (1–20 each), so the
evolution block reads "runs<=N" per shard: 5 × N runs per task and arm.)

## Show the evolution while it runs (required)

Every 20 minutes, and once more at the end, run the progress view over all shards and paste its
whole output into the conversation, with one line on what changed since the last one:

```bash
python3 scripts/lib/ab_progress.py "$OUT"/ab-11-* "$OUT"/ab-13-*
```

It shows runs, pass rate, score, cost and agent errors per task and arm, each arm's delta
against vanilla with a 95% CI, and the "evolution" block: how the delta and its CI moved as runs
accumulated (runs<=5, <=10, <=20, …). Runs are interleaved, so every snapshot is fair to both arms.
Say plainly when a CI still crosses zero. Transcripts land in `"$OUT"/<shard>/traces/`.

**Stop rule:** if the `errors` column passes 10% of the runs for any task and arm (usually rate
limiting or quota), kill the shards (`pkill -f run-ab-eval`), wait 15 minutes, and rerun only the
missing shards with 3 in parallel instead of 10. Never mix runs from two different models.

## Merge the shards into one report

```bash
python3 - <<'EOF'
import glob, json, sys
from datetime import datetime, timezone
from pathlib import Path
sys.path.insert(0, "scripts/lib")
from ab_report import BOOTSTRAP_RESAMPLES, BOOTSTRAP_SEED, aggregate, bigpowers_sha, print_summary, write_reports

records = [json.loads(l) for f in sorted(glob.glob("/tmp/bp-ab-k100/*/ab-runs-*.jsonl")) for l in open(f)]
arms, tasks = ["vanilla", "bigpowers"], ["ab-11", "ab-13"]
for a in arms:
    for t in tasks:
        n = sum(1 for r in records if r["arm"] == a and r["task"] == t)
        print(f"{t} {a}: {n} runs")   # expect 100 each
result = aggregate(records, arms, tasks)
meta = {"generated_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "bigpowers_sha": bigpowers_sha(), "adapter": "pi", "model": "opencode-go/deepseek-v4.1-flash",
        "k": 100, "tasks": tasks, "arms": arms, "shards": "10 shards (5 per task) x k=20, merged",
        "ci_method": f"bootstrap over runs, {BOOTSTRAP_RESAMPLES} resamples, seed {BOOTSTRAP_SEED}"}
out = Path("/tmp/bp-ab-k100/merged")
write_reports(out, meta, result, records)
print_summary(result)
EOF
```

If any task/arm has fewer than 100 runs, say so in the summary. Do not top it up with runs from
another model or another day's code.

## Pin the result (the only files you may add)

Copy under model-specific names. **Never write into `specs/benchmarks/reports/` with the default
names**: `AB-<date>.yaml` there may already be a pinned baseline.

```bash
D=$(date +%F)
cp /tmp/bp-ab-k100/merged/AB-*.yaml     "specs/benchmarks/reports/AB-$D-deepseek-v4.1-flash-k100-hard.yaml"
cp /tmp/bp-ab-k100/merged/ab-runs-*.jsonl "specs/benchmarks/reports/ab-runs-$D-deepseek-v4.1-flash-k100-hard.jsonl"
git add specs/benchmarks/reports/*k100-hard*
git commit -m "docs(benchmarks): pin k=100 A/B run on ab-11 and ab-13, deepseek-v4.1-flash (e58)"
```

Do not push. Do not edit any other file.

## Report back

Give a short summary with:

1. Per task and arm: pass rate, mean `score`, mean cost, mean turns, tamper rate, agent-error rate.
2. `delta` (bigpowers − vanilla) for pass rate and score, each with its 95% CI, overall and per task.
3. Vanilla's pass rate per task. A task is only useful for comparing arms if vanilla passes it
   20–80% of the time: say which tasks are inside that range.
4. Total cost and wall-clock time.
5. Anything unusual: shards that failed, errors, runs that timed out, tampering.

Prior results for context (the k=10 and smoke runs used the opencode CLI; this run uses pi, so
compare deltas, not absolute rates):
- k=10 on all 8 easy tasks (same model): bigpowers 0.97 vs vanilla 0.96, delta +0.01
  [−0.05, +0.06].
- k=1 smoke on these two tasks: vanilla passed both. bigpowers passed ab-13 and scored 17/18 on
  ab-11.
