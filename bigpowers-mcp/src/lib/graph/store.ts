import fs from "node:fs";
import path from "node:path";
import type { GraphEntity, GraphLine, GraphRelation, SkillGraph } from "./types.js";

export function emptyGraph(): SkillGraph {
  return { entities: new Map(), relations: [] };
}

export function loadGraph(graphPath: string): SkillGraph {
  const graph = emptyGraph();
  if (!fs.existsSync(graphPath)) return graph;

  const lines = fs.readFileSync(graphPath, "utf8").split("\n").filter(Boolean);
  for (const line of lines) {
    const parsed = JSON.parse(line) as GraphLine;
    if (parsed.type === "entity") {
      graph.entities.set(parsed.name, parsed);
    } else if (parsed.type === "relation") {
      graph.relations.push(parsed);
    }
  }
  return graph;
}

export function saveGraph(graphPath: string, graph: SkillGraph): void {
  fs.mkdirSync(path.dirname(graphPath), { recursive: true });
  const lines: string[] = [];
  for (const entity of graph.entities.values()) {
    lines.push(JSON.stringify(entity));
  }
  for (const rel of graph.relations) {
    lines.push(JSON.stringify(rel));
  }
  fs.writeFileSync(graphPath, lines.join("\n") + (lines.length ? "\n" : ""));
}

export function searchNodes(graph: SkillGraph, query: string): GraphEntity[] {
  const q = query.toLowerCase();
  return [...graph.entities.values()].filter((e) => {
    const hay = [e.name, e.entityType, ...e.observations].join(" ").toLowerCase();
    return hay.includes(q);
  });
}

export function openNodes(graph: SkillGraph, names: string[]): GraphEntity[] {
  return names
    .map((n) => graph.entities.get(n))
    .filter((e): e is GraphEntity => e !== undefined);
}

export function getRelationsFor(graph: SkillGraph, skillName: string): GraphRelation[] {
  return graph.relations.filter((r) => r.from === skillName || r.to === skillName);
}

export function getForwardDeps(graph: SkillGraph, skillName: string): string[] {
  return graph.relations
    .filter((r) => r.from === skillName && r.relationType === "depends_on")
    .map((r) => r.to);
}

export function getReverseDeps(graph: SkillGraph, skillName: string): string[] {
  return graph.relations
    .filter((r) => r.to === skillName && r.relationType === "depends_on")
    .map((r) => r.from);
}

export function getHandoffChain(graph: SkillGraph, skillName: string): string[] {
  const chain: string[] = [skillName];
  let current = skillName;
  const seen = new Set<string>([skillName]);
  for (let i = 0; i < 20; i++) {
    const next = graph.relations.find(
      (r) => r.from === current && r.relationType === "handoff_to",
    );
    if (!next || seen.has(next.to)) break;
    chain.push(next.to);
    seen.add(next.to);
    current = next.to;
  }
  return chain;
}

export function getConventions(graph: SkillGraph, skillName: string): string[] {
  return graph.relations
    .filter((r) => r.from === skillName && r.relationType === "enforces")
    .map((r) => r.to);
}
