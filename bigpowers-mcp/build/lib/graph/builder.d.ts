import type { ParsedSkill } from "../skill-parser.js";
import type { SkillGraph } from "./types.js";
export declare function buildGraphFromSkills(parsedSkills: ParsedSkill[]): SkillGraph;
export declare function mergeGraphs(base: SkillGraph, incoming: SkillGraph): SkillGraph;
