#!/usr/bin/env python3
# story: e39s04
"""Add cross-references from skill-graph.json into OKF concept files."""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path


def main() -> int:
    graph_json = Path(sys.argv[1])
    wiki_skills = Path(sys.argv[2])

    with open(graph_json, encoding="utf-8") as f:
        graph = json.load(f)

    edges = graph.get("edges", [])
    nodes = {n.get("id") or n.get("name") for n in graph.get("nodes", [])}
    nodes.discard(None)

    refs: dict[str, list[dict[str, str]]] = {}
    for edge in edges:
        src = edge.get("from") or edge.get("source")
        tgt = edge.get("to") or edge.get("target")
        rel = edge.get("relationType") or edge.get("relation") or "references"
        if src in nodes and tgt in nodes:
            refs.setdefault(src, []).append({"concept": tgt, "type": rel})

    skill_names = {f.stem for f in wiki_skills.glob("*.md")}
    count_updated = 0

    for path in wiki_skills.glob("*.md"):
        name = path.stem
        content = path.read_text(encoding="utf-8")
        concept_refs = list(refs.get(name, []))

        desc_match = re.search(r'description:\s*"(.*?)"', content, re.DOTALL)
        if desc_match:
            desc = desc_match.group(1)
            for skill_name in skill_names:
                if (
                    skill_name != name
                    and skill_name in desc
                    and not any(r["concept"] == skill_name for r in concept_refs)
                ):
                    concept_refs.append({"concept": skill_name, "type": "references"})

        seen: set[tuple[str, str]] = set()
        unique_refs: list[dict[str, str]] = []
        for ref in concept_refs:
            key = (ref["concept"], ref["type"])
            if key not in seen:
                seen.add(key)
                unique_refs.append(ref)

        if unique_refs:
            ref_lines = []
            for ref in unique_refs:
                ref_lines.append(f'  - concept: {ref["concept"]}')
                ref_lines.append(f'    type: {ref["type"]}')
            ref_block = "\n".join(ref_lines)
            content = re.sub(r"references:\s*\[\]", f"references:\n{ref_block}", content)
        else:
            content = re.sub(
                r"references:\s*\[\]",
                "references:\n  - concept: skills-wiki\n    type: belongs_to",
                content,
            )
        count_updated += 1
        path.write_text(content, encoding="utf-8")

    print(f"  concepts with cross-references: {count_updated}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
