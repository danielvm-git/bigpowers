import type { ParsedSkill } from "../skill-parser.js";
import type { GraphEntity, GraphRelation, SkillGraph } from "./types.js";

const HANDOFF_AFTER = /run\s+(\S+)\s+after\s+(\S+)/gi;
const HARD_GATE = /HARD GATE:\s*(.+)/i;
const SKILL_REF = /see\s+skills\/(\S+)\/SKILL\.md/gi;
const CONVENTIONS_REF = /CONVENTIONS\.md(?:\s*[§#]\s*(\S+))?/gi;

export function buildGraphFromSkills(parsedSkills: ParsedSkill[]): SkillGraph {
  const graph: SkillGraph = { entities: new Map(), relations: [] };

  for (const skill of parsedSkills) {
    const fm = skill.frontmatter;
    const observations: string[] = [];
    if (fm.model) observations.push(`model: ${String(fm.model)}`);
    if (fm.effort) observations.push(`effort: ${String(fm.effort)}`);
    if (fm.description) observations.push(`description: ${String(fm.description)}`);

    const entity: GraphEntity = {
      type: "entity",
      name: skill.name,
      entityType: "Skill",
      observations,
    };
    graph.entities.set(skill.name, entity);

    const prose = skill.rawProse + "\n" + skill.sections.map((s) => s.prose).join("\n");

    let m: RegExpExecArray | null;
    HANDOFF_AFTER.lastIndex = 0;
    while ((m = HANDOFF_AFTER.exec(prose)) !== null) {
      graph.relations.push({
        type: "relation",
        from: m[1],
        to: m[2],
        relationType: "depends_on",
      });
    }

    const gateMatch = HARD_GATE.exec(prose);
    if (gateMatch) {
      const gateText = gateMatch[1].trim();
      const targetMatch = /(\S+-?\S+)/.exec(gateText);
      if (targetMatch) {
        graph.relations.push({
          type: "relation",
          from: skill.name,
          to: targetMatch[1].replace(/[`'"]/g, ""),
          relationType: "gates",
        });
      }
    }

    SKILL_REF.lastIndex = 0;
    while ((m = SKILL_REF.exec(prose)) !== null) {
      graph.relations.push({
        type: "relation",
        from: skill.name,
        to: m[1],
        relationType: "references",
      });
    }

    CONVENTIONS_REF.lastIndex = 0;
    while ((m = CONVENTIONS_REF.exec(prose)) !== null) {
      graph.relations.push({
        type: "relation",
        from: skill.name,
        to: m[1] ? `CONVENTIONS.md §${m[1]}` : "CONVENTIONS.md",
        relationType: "enforces",
      });
    }

    const desc = String(fm.description ?? "");
    const handoffMatch = /handoff.*?(\S+-?\S+)/i.exec(desc);
    if (handoffMatch) {
      graph.relations.push({
        type: "relation",
        from: skill.name,
        to: handoffMatch[1],
        relationType: "handoff_to",
      });
    }
  }

  return graph;
}

export function mergeGraphs(base: SkillGraph, incoming: SkillGraph): SkillGraph {
  for (const [name, entity] of incoming.entities) {
    base.entities.set(name, entity);
  }
  base.relations.push(...incoming.relations);
  return base;
}
