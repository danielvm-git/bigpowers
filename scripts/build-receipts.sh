#!/usr/bin/env bash
# story: e41s01
# build-receipts.sh — aggregate all quality evidence into specs/receipts.json.
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "build-receipts: not inside a git repo" >&2; exit 1; }
OUTFILE="$ROOT/specs/receipts.json"
TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
emit_json() {
  python3 -c "
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
            sm = data.get('summary',{})
            sections['golden_suite'] = {'value':{'pass_rate':sm.get('pass_rate'),'passed':sm.get('passed'),'total':sm.get('total'),'overall':sm.get('overall','unknown'),'timestamp':data.get('timestamp',''),'commit':data.get('git_commit','')},'generated_at':'$TIMESTAMP','source':'measured','command':'specs/benchmarks/reports/GOLDEN-*.yaml (latest)'}
        except Exception as e:
            print(f'build-receipts: golden error: {e}', file=sys.stderr)
            sections['golden_suite'] = {'source':'absent','generated_at':'$TIMESTAMP','command':'specs/benchmarks/reports/GOLDEN-*.yaml'}
    else:
        sections['golden_suite'] = {'source':'absent','generated_at':'$TIMESTAMP','command':'specs/benchmarks/reports/GOLDEN-*.yaml'}
else:
    sections['golden_suite'] = {'source':'absent','generated_at':'$TIMESTAMP','command':'specs/benchmarks/reports/GOLDEN-*.yaml'}

# metrics
md = '$ROOT/specs/metrics/'
if os.path.isdir(md):
    mfs = sorted(gb.glob(os.path.join(md, '*.okf.md')))
    sc = 0; st = {'measured':0,'estimated':0,'backfilled':0}; te = 0.0; tb = 0
    for mf in mfs:
        try:
            with open(mf) as f: content = f.read()
            parts = content.split('---')
            if len(parts) < 3: continue
            import yaml; fm = yaml.safe_load(parts[1])
            if fm is None or fm.get('okf_kind') != 'story-metrics': continue
            sc += 1; src = fm.get('source','absent')
            if src in st: st[src] += 1
            e = (fm.get('effort') or {}).get('effort_hours')
            if e is not None:
                try: te += float(e)
                except: pass
            b = fm.get('bcps')
            if b is not None:
                try: tb += int(b)
                except: pass
        except: pass
    if sc > 0:
        sections['metrics'] = {'value':{'story_count':sc,'total_effort_hours':round(te,1),'total_bcps':tb,'source_breakdown':st},'generated_at':'$TIMESTAMP','source':'measured','command':'specs/metrics/*.okf.md'}
    else:
        sections['metrics'] = {'source':'absent','generated_at':'$TIMESTAMP','command':'specs/metrics/*.okf.md'}
else:
    sections['metrics'] = {'source':'absent','generated_at':'$TIMESTAMP','command':'specs/metrics/*.okf.md'}

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
emit_json
echo "build-receipts: done — $(date -u +%H:%M:%SZ)"
exit 0
