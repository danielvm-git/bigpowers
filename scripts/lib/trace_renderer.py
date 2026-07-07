# story: e38s01
# trace_renderer.py — Output renderer for traceability matrix data.
import json
from pathlib import Path
from datetime import datetime, timezone

def emit_matrix_json(matrix_json_path: Path, stories: dict, tagged_sids: set, dark_stories: list, orphan_tags: list, stale_tags: list, matrix_stories: list) -> dict:
    matrix = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "matrix_version": "1.0",
        "stories": matrix_stories,
        "summary": {
            "total_stories": len(stories),
            "tagged_stories": len(tagged_sids & set(stories.keys())),
            "dark_stories": dark_stories,
            "dark_count": len(dark_stories),
            "orphan_tags": orphan_tags,
            "orphan_count": len(orphan_tags),
            "stale_tags": stale_tags,
            "stale_count": len(stale_tags),
            "oracle_stats": {
                "high": sum(1 for s in matrix_stories for l in s["links"] if l["confidence"] == "high"),
                "medium": sum(1 for s in matrix_stories for l in s["links"] if l["confidence"] == "medium"),
                "low": sum(1 for s in matrix_stories for l in s["links"] if l["confidence"] == "low")
            }
        }
    }
    matrix_json_path.parent.mkdir(parents=True, exist_ok=True)
    matrix_json_path.write_text(json.dumps(matrix, indent=2), encoding="utf-8")
    return matrix

def emit_trace_md(trace_md_path: Path, stories: dict, tagged_sids: set, dark_stories: list, orphan_tags: list, stale_tags: list, matrix_stories: list, matrix: dict, dev_status: dict) -> None:
    lines = []
    lines.append("# Traceability Matrix")
    lines.append("")
    lines.append(f"**Generated:** {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S UTC')}")
    lines.append(f"**Total stories:** {len(stories)}")
    lines.append(f"**Tagged stories:** {len(tagged_sids & set(stories.keys()))}")
    lines.append(f"**Dark stories:** {len(dark_stories)}")
    lines.append(f"**Orphan tags:** {len(orphan_tags)}")
    lines.append(f"**Stale tags:** {len(stale_tags)}")
    lines.append("")
    lines.append("## Oracle Stats")
    lines.append("")
    lines.append(f"- **High** (explicit tag): {matrix['summary']['oracle_stats']['high']}")
    lines.append(f"- **Medium** (file heuristic): {matrix['summary']['oracle_stats']['medium']}")
    lines.append(f"- **Low** (task reference): {matrix['summary']['oracle_stats']['low']}")
    lines.append("")
    
    # Story coverage table
    lines.append("## Story Coverage")
    lines.append("")
    lines.append("| Story | Title | Epic | BCP | WSJF | Status | Links |")
    lines.append("|-------|-------|------|-----|------|--------|-------|")
    for s in matrix_stories:
        lines.append(f"| {s['id']} | {s['title'][:60]} | {s['epic_id']} | {s['bcp']} | {s['wsjf']} | {s['status']} | {s['link_count']} |")
    lines.append("")
    
    # Findings
    if dark_stories:
        lines.append("## Dark Stories (no code links)")
        lines.append("")
        for ds in dark_stories:
            sinfo = stories.get(ds, {})
            lines.append(f"- **{ds}**: {sinfo.get('title', 'Unknown')} (status: {dev_status.get(ds, '?')})")
        lines.append("")
    
    if orphan_tags:
        lines.append("## Orphan Tags (tag in code, no matching story)")
        lines.append("")
        for ot in orphan_tags:
            lines.append(f"- `{ot}`")
        lines.append("")
    
    if stale_tags:
        lines.append("## Stale Tags (story done, tag still in code)")
        lines.append("")
        for st in stale_tags:
            lines.append(f"- `{st}`")
        lines.append("")
    
    trace_md_path.parent.mkdir(parents=True, exist_ok=True)
    trace_md_path.write_text("\n".join(lines), encoding="utf-8")

def emit_okf_bundle(okf_dir: Path, stories: dict, matrix_stories: list) -> None:
    okf_dir.mkdir(parents=True, exist_ok=True)
    
    # Generate index.md
    idx_lines = []
    idx_lines.append("---")
    idx_lines.append("type: Index")
    idx_lines.append(f"generated_at: {datetime.now(timezone.utc).isoformat()}")
    idx_lines.append(f"total_concepts: {len(stories)}")
    idx_lines.append("---")
    idx_lines.append("")
    idx_lines.append("# Codebase Wiki — Story Traceability")
    idx_lines.append("")
    idx_lines.append("Auto-generated OKF bundle from trace-stories.sh.")
    idx_lines.append("")
    idx_lines.append("| Story | Title | Confidence | Links |")
    idx_lines.append("|-------|-------|------------|-------|")
    for s in matrix_stories:
        confs = {l["confidence"] for l in s["links"]}
        max_conf = "high" if "high" in confs else ("medium" if "medium" in confs else ("low" if confs else "none"))
        idx_lines.append(f"| [{s['id']}](./{s['id']}.md) | {s['title'][:60]} | {max_conf} | {s['link_count']} |")
    idx_lines.append("")
    (okf_dir / "index.md").write_text("\n".join(idx_lines), encoding="utf-8")
    
    # Generate one concept per story
    for s in matrix_stories:
        concept = []
        concept.append("---")
        concept.append(f"type: Story")
        concept.append(f"id: {s['id']}")
        concept.append(f"epic: {s['epic_id']}")
        concept.append(f"bcps: {s['bcp']}")
        concept.append(f"wsjf: {s['wsjf']}")
        concept.append(f"implementation_status: {s['status']}")
        max_confs = set()
        for l in s["links"]:
            max_confs.add(l["confidence"])
        conf = "high" if "high" in max_confs else ("medium" if "medium" in max_confs else ("low" if max_confs else "none"))
        concept.append(f"coverage_status: {'covered' if s['link_count'] > 0 else 'dark'}")
        concept.append(f"confidence: {conf}")
        concept.append("links:")
        for l in s["links"]:
            concept.append(f"  - file: {l['file']}")
            concept.append(f"    line: {l['line']}")
            concept.append(f"    confidence: {l['confidence']}")
            concept.append(f"    method: {l['method']}")
        concept.append("---")
        concept.append("")
        concept.append(f"# {s['id']}: {s['title']}")
        concept.append("")
        concept.append(f"**Epic:** {s['epic_id']} — {s.get('epic_title', 'Unknown')}")
        concept.append(f"**Status:** {s['status']}")
        concept.append(f"**BCP:** {s['bcp']} | **WSJF:** {s['wsjf']}")
        concept.append("")
        if s["links"]:
            concept.append("## Implemented In")
            concept.append("")
            for l in s["links"]:
                concept.append(f"- `{l['file']}` (line {l['line']}, confidence: {l['confidence']}, method: {l['method']})")
        else:
            concept.append("*No code links found — this is a dark story.*")
        concept.append("")
        (okf_dir / f"{s['id']}.md").write_text("\n".join(concept), encoding="utf-8")
