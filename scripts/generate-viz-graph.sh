#!/usr/bin/env bash
# story: e45s04
# generate-viz-graph.sh — build specs/viz.html from bigpowers-mcp/graph.jsonl
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/python-env.sh"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GRAPH="$ROOT/bigpowers-mcp/graph.jsonl"
OUT="$ROOT/specs/viz.html"

ENTITIES_JSON=$($PYTHON -c "
import json, sys
entities = []
with open('$GRAPH') as f:
    for line in f:
        obj = json.loads(line)
        if obj.get('type') == 'entity':
            entities.append(obj)
print(json.dumps(entities))
")

EDGES_JSON=$($PYTHON -c "
import json, sys
edges = []
with open('$GRAPH') as f:
    for line in f:
        obj = json.loads(line)
        if obj.get('type') == 'relation':
            edges.append({'from': obj['from'], 'to': obj['to'], 'relationType': obj.get('relationType','')})
print(json.dumps(edges))
")

$PYTHON - "$ENTITIES_JSON" "$EDGES_JSON" "$OUT" << 'PY'
import sys, json

entities_json = sys.argv[1]
edges_json = sys.argv[2]
out_path = sys.argv[3]

entities = json.loads(entities_json)
edges = json.loads(edges_json)

html = f'''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>bigpowers — Skill Graph</title>
<style>
* {{ margin: 0; padding: 0; box-sizing: border-box; }}
body {{ background: #0d1117; color: #c9d1d9; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; overflow: hidden; }}
#graph {{ width: 100vw; height: 100vh; }}
.node {{ cursor: pointer; }}
.node circle {{ stroke-width: 1.5px; }}
.node text {{ font-size: 10px; fill: #c9d1d9; pointer-events: none; }}
.link {{ stroke: #30363d; stroke-opacity: 0.6; }}
.tooltip {{
  position: absolute; background: #161b22; border: 1px solid #30363d;
  border-radius: 6px; padding: 10px 14px; font-size: 12px; max-width: 320px;
  pointer-events: none; opacity: 0; transition: opacity 0.15s;
  box-shadow: 0 4px 12px rgba(0,0,0,0.4); z-index: 100;
}}
.tooltip .name {{ font-weight: 600; font-size: 14px; color: #58a6ff; margin-bottom: 4px; }}
.tooltip .meta {{ color: #8b949e; font-size: 11px; margin-bottom: 4px; }}
.tooltip .desc {{ color: #c9d1d9; font-size: 11px; line-height: 1.4; }}
.legend {{ position: absolute; top: 16px; right: 16px; background: #161b22; border: 1px solid #30363d; border-radius: 6px; padding: 10px 14px; font-size: 11px; z-index: 100; }}
.legend-item {{ display: flex; align-items: center; gap: 6px; margin: 4px 0; }}
.legend-swatch {{ width: 12px; height: 12px; border-radius: 50%; }}
header {{ position: absolute; top: 16px; left: 16px; z-index: 100; }}
header h1 {{ font-size: 18px; color: #58a6ff; margin: 0; }}
header p {{ font-size: 11px; color: #8b949e; margin: 2px 0 0; }}
</style>
</head>
<body>
<div id="graph"></div>
<div class="tooltip" id="tooltip"></div>
<header><h1>bigpowers Skill Graph</h1><p>{len(entities)} skills · {len(edges)} relationships</p></header>
<div class="legend">
  <div class="legend-item"><span class="legend-swatch" style="background:#58a6ff"></span> light</div>
  <div class="legend-item"><span class="legend-swatch" style="background:#3fb950"></span> standard</div>
  <div class="legend-item"><span class="legend-swatch" style="background:#d29922"></span> heavy</div>
</div>
<script src="https://d3js.org/d3.v7.min.js"></script>
<script>
const ENTITIES = {json.dumps(entities)};
const EDGES = {json.dumps(edges)};

const effortColors = {{ light: '#58a6ff', standard: '#3fb950', heavy: '#d29922' }};
const effortRadii = {{ light: 8, standard: 12, heavy: 16 }};

const nodes = ENTITIES.map(e => {{
  const obs = (e.observations || []).join(' ');
  const effortMatch = obs.match(/effort:\\s*(\\w+)/);
  const effort = effortMatch ? effortMatch[1] : 'standard';
  const descMatch = obs.match(/description:\\s*(.+?)(?:\\]|$)/);
  const desc = descMatch ? descMatch[1] : '';
  const modelMatch = obs.match(/model:\\s*(\\w+)/);
  const model = modelMatch ? modelMatch[1] : '';
  return {{ id: e.name, type: e.entityType, effort, model, description: desc, radius: effortRadii[effort] || 12, color: effortColors[effort] || '#8b949e' }};
}});

const nodeIds = new Set(nodes.map(n => n.id));
const links = EDGES.filter(e => nodeIds.has(e.from) && nodeIds.has(e.to))
  .map(e => ({{ source: e.from, target: e.to, type: e.relationType }}));

const width = window.innerWidth, height = window.innerHeight;
const svg = d3.select('#graph').append('svg').attr('width', width).attr('height', height);
const g = svg.append('g');
const tooltip = d3.select('#tooltip');
svg.call(d3.zoom().scaleExtent([0.2, 4]).on('zoom', (e) => g.attr('transform', e.transform)));

const simulation = d3.forceSimulation(nodes)
  .force('link', d3.forceLink(links).id(d => d.id).distance(80))
  .force('charge', d3.forceManyBody().strength(-200))
  .force('center', d3.forceCenter(width / 2, height / 2))
  .force('collision', d3.forceCollide().radius(d => d.radius + 4));

g.append('g').selectAll('line').data(links).join('line')
  .attr('class', 'link').attr('stroke-width', 1);

const node = g.append('g').selectAll('g').data(nodes).join('g')
  .attr('class', 'node')
  .call(d3.drag()
    .on('start', (e, d) => {{ if (!e.active) simulation.alphaTarget(0.3).restart(); d.fx = d.x; d.fy = d.y; }})
    .on('drag', (e, d) => {{ d.fx = e.x; d.fy = e.y; }})
    .on('end', (e, d) => {{ if (!e.active) simulation.alphaTarget(0); d.fx = null; d.fy = null; }}));

node.append('circle').attr('r', d => d.radius).attr('fill', d => d.color).attr('stroke', '#30363d');
node.append('text').attr('dy', d => d.radius + 12).attr('text-anchor', 'middle').text(d => d.id);

node.on('mouseenter', (e, d) => {{
  tooltip.style('opacity', 1)
    .html('<div class="name">' + d.id + '</div><div class="meta">' + d.type + ' · ' + d.effort + (d.model ? ' · model: ' + d.model : '') + '</div><div class="desc">' + d.description.slice(0, 200) + '</div>');
}}).on('mousemove', (e) => {{
  tooltip.style('left', (e.pageX + 14) + 'px').style('top', (e.pageY - 10) + 'px');
}}).on('mouseleave', () => tooltip.style('opacity', 0));

simulation.on('tick', () => {{
  svg.selectAll('.link').attr('x1', d => d.source.x).attr('y1', d => d.source.y).attr('x2', d => d.target.x).attr('y2', d => d.target.y);
  node.attr('transform', d => 'translate(' + d.x + ',' + d.y + ')');
}});
</script>
</body>
</html>'''

with open(out_path, 'w') as f:
    f.write(html)
print(f"generate-viz-graph: {len(entities)} entities + {len(edges)} edges -> {out_path}")
PY
