#!/usr/bin/env bash
# story: e41s01
# story: e83s03
# build-receipts.sh — aggregate all quality evidence into specs/receipts.json.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/python-env.sh"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "build-receipts: not inside a git repo" >&2; exit 1; }
OUTFILE="${RECEIPTS_OUT:-$ROOT/specs/receipts.json}"
TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
receipts_emit_json() {
  $PYTHON -c "
import json, sys, os, subprocess, glob as gb
sections = {}

# compliance
comp = '$ROOT/specs/verifications/features/'
if os.path.isdir(comp):
    try:
        r = subprocess.run(['bash','scripts/audit-compliance.sh','specs/verifications/features/','--dry-run'],
            cwd='$ROOT', capture_output=True, text=True, timeout=30)
        score = None
        for line in r.stdout.splitlines():
            if 'SCORE:' in line and '%' in line:
                p = line.split('SCORE:')[1].strip()
                s = p.split('%')[0].strip()
                try: score = int(s)
                except ValueError: pass
                break
        if score is not None:
            sections['compliance'] = {'value':score,'generated_at':'$TIMESTAMP','source':'measured','command':'bash scripts/audit-compliance.sh specs/verifications/features/'}
        else:
            sections['compliance'] = {'source':'absent','generated_at':'$TIMESTAMP','command':'bash scripts/audit-compliance.sh specs/verifications/features/'}
    except Exception as e:
        print(f'build-receipts: compliance error: {e}', file=sys.stderr)
        sections['compliance'] = {'source':'absent','generated_at':'$TIMESTAMP','command':'bash scripts/audit-compliance.sh specs/verifications/features/'}
else:
    sections['compliance'] = {'source':'absent','generated_at':'$TIMESTAMP','command':'bash scripts/audit-compliance.sh specs/verifications/features/'}

# golden
gd = '$ROOT/specs/benchmarks/reports/'
if os.path.isdir(gd):
    reports = sorted(gb.glob(os.path.join(gd, 'GOLDEN-*.yaml')))
    if reports:
        try:
            with open(reports[-1]) as f:
                import yaml; data = yaml.safe_load(f)
            sm = data.get('deterministic',{})
            verdict = (data.get('summary') or {}).get('combined_verdict','unknown')
            sections['golden_suite'] = {'value':{'pass_rate':sm.get('pass_rate'),'passed':sm.get('passed'),'total':sm.get('total'),'overall':verdict,'timestamp':data.get('timestamp',''),'commit':data.get('git_commit','')},'generated_at':'$TIMESTAMP','source':'measured','command':'specs/benchmarks/reports/GOLDEN-*.yaml (latest)'}
        except Exception as e:
            print(f'build-receipts: golden error: {e}', file=sys.stderr)
            sections['golden_suite'] = {'source':'absent','generated_at':'$TIMESTAMP','command':'specs/benchmarks/reports/GOLDEN-*.yaml'}
    else:
        sections['golden_suite'] = {'source':'absent','generated_at':'$TIMESTAMP','command':'specs/benchmarks/reports/GOLDEN-*.yaml'}
else:
    sections['golden_suite'] = {'source':'absent','generated_at':'$TIMESTAMP','command':'specs/benchmarks/reports/GOLDEN-*.yaml'}

# metrics (e83s03): read the cycle-time ledger, label the source by what was measured
mf = '$ROOT/specs/metrics/cycle-times.yaml'
mcmd = 'specs/metrics/cycle-times.yaml'
if os.path.isfile(mf):
    try:
        import yaml, datetime
        stories = (yaml.safe_load(open(mf)) or {}).get('stories') or []
        st = {'measured':0,'estimated':0,'backfilled':0}
        te = 0.0; tb = 0; last = None
        def parse_end(v):
            d = datetime.datetime.fromisoformat(str(v).replace('Z','+00:00'))
            return d if d.tzinfo else d.replace(tzinfo=datetime.timezone.utc)
        last_dt = None
        for e in stories:
            try:
                mins = float(e.get('cycle_minutes') or 0); bc = int(e.get('bcps') or 0)
            except (TypeError, ValueError):
                print(f'build-receipts: skipping ledger row {e.get(\"id\")}: bad number', file=sys.stderr)
                continue
            src = e.get('source')
            st['measured' if src == 'measured' else 'backfilled' if src == 'backfilled' else 'estimated'] += 1
            te += mins / 60; tb += bc
            try:
                ed = parse_end(e.get('end'))
                if last_dt is None or ed > last_dt: last_dt = ed
            except (TypeError, ValueError):
                pass
        last = last_dt.isoformat() if last_dt else None
        n = sum(st.values())
        if n == 0:
            sections['metrics'] = {'source':'absent','generated_at':'$TIMESTAMP','command':mcmd}
        else:
            label = ('measured' if st['measured'] == n else 'mixed' if st['measured'] > 0 else
                     'backfilled' if st['backfilled'] == n else 'estimated')
            stale_days = None; stale = True
            if last:
                stale_days = (datetime.datetime.now(datetime.timezone.utc) - last_dt).days
                stale = stale_days > 30
            if stale: print(f'build-receipts: WARNING cycle-time ledger is stale (last entry {last})', file=sys.stderr)
            sections['metrics'] = {'value':{'story_count':n,'total_effort_hours':round(te,1),'total_bcps':tb,'source_breakdown':st,'last_entry':last,'stale_days':stale_days,'stale':stale},'generated_at':'$TIMESTAMP','source':label,'command':mcmd}
    except Exception as e:
        print(f'build-receipts: metrics error: {e}', file=sys.stderr)
        sections['metrics'] = {'source':'absent','generated_at':'$TIMESTAMP','command':mcmd}
else:
    sections['metrics'] = {'source':'absent','generated_at':'$TIMESTAMP','command':mcmd}

# traceability
tf = '$ROOT/specs/traceability-matrix.json'
if os.path.isfile(tf):
    try:
        with open(tf) as f: matrix = json.load(f)
        stories = matrix.get('stories',[])
        ts = len(stories); ls = sum(1 for s in stories if s.get('link_count',0)>0); lc = sum(s.get('link_count',0) for s in stories)
        sections['traceability'] = {'value':{'total_stories':ts,'linked_stories':ls,'total_links':lc,'coverage_pct':round(ls/ts*100,1) if ts>0 else 0,'generated_at':matrix.get('generated_at','')},'generated_at':'$TIMESTAMP','source':'measured','command':'specs/traceability-matrix.json (trace-matrix.py)'}
    except Exception as e:
        print(f'build-receipts: trace error: {e}', file=sys.stderr)
        sections['traceability'] = {'source':'absent','generated_at':'$TIMESTAMP','command':'specs/traceability-matrix.json'}
else:
    sections['traceability'] = {'source':'absent','generated_at':'$TIMESTAMP','command':'specs/traceability-matrix.json'}

with open('$OUTFILE','w') as f: json.dump(sections,f,indent=2)
print(f'build-receipts: wrote {len(sections)} sections to specs/receipts.json')
for key, sec in sections.items(): print(f'  {key}: source={sec.get(\"source\",\"?\")}')
"
}
echo "build-receipts: aggregating quality evidence..."
receipts_emit_json
echo "build-receipts: done — $(date -u +%H:%M:%SZ)"
exit 0
