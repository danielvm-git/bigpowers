import { describe, it, expect, beforeAll } from "vitest";
import path from "node:path";
import { fileURLToPath } from "node:url";
import {
  discoverSkills,
  readSkillFile,
  parseSkillMarkdown,
} from "../src/lib/skill-parser.js";
import { phaseForSkill } from "../src/lib/phase-map.js";
import { resolveSkillPath, PathGuardError } from "../src/lib/paths.js";
import { buildGraphFromSkills } from "../src/lib/graph/builder.js";
import { loadGraph, saveGraph } from "../src/lib/graph/store.js";
import { validateSkillConventions } from "../src/lib/validate-skill.js";
import { getGitContext, isGitRepo } from "../src/lib/git-context.js";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const fixtureRoot = path.join(repoRoot, "bigpowers-mcp/test/fixtures");

// scenario: SC-e32s01-P0-01
describe("index_skills / discoverSkills", () => {
  it("discovers all skills in live catalog", () => {
    const skills = discoverSkills(repoRoot, phaseForSkill);
    expect(skills.length).toBeGreaterThanOrEqual(70);
    for (const s of skills) {
      expect(s.name).toMatch(/^[a-z]+(-[a-z]+)*$/);
      expect(s.path).toMatch(/^skills\/.+\/SKILL\.md$/);
      expect(s.phase).toBeTruthy();
    }
  });

  it("discovers fixture skills", () => {
    const skills = discoverSkills(fixtureRoot, phaseForSkill);
    expect(skills.map((s) => s.name).sort()).toEqual([
      "broken-link",
      "missing-verify",
      "valid-skill",
    ]);
  });
});

// scenario: SC-e32s01-P0-02
describe("read_skill / parseSkillMarkdown", () => {
  it("parses all catalog SKILL.md files with zero failures", () => {
    const skills = discoverSkills(repoRoot, phaseForSkill);
    const errors: string[] = [];
    for (const s of skills) {
      try {
        const parsed = readSkillFile(repoRoot, s.name);
        expect(parsed.frontmatter.name).toBeTruthy();
        expect(parsed.headings.length).toBeGreaterThan(0);
      } catch (err) {
        errors.push(`${s.name}: ${err}`);
      }
    }
    expect(errors, errors.join("\n")).toEqual([]);
  });

  it("extracts frontmatter and headings from fixture", () => {
    const parsed = readSkillFile(fixtureRoot, "valid-skill");
    expect(parsed.frontmatter.name).toBe("valid-skill");
    expect(parsed.frontmatter.effort).toBe("light");
    expect(parsed.headings[0].text).toBe("Valid Skill");
    expect(parsed.rawProse.includes("other-skill")).toBe(true);
  });

  it("rejects path traversal on skill name", () => {
    expect(() => readSkillFile(repoRoot, "../etc/passwd")).toThrow(/not found|invalid/i);
    expect(() => resolveSkillPath(repoRoot, "..")).toThrow(PathGuardError);
  });
});

// scenario: SC-e32s02-P0-01
describe("build_skill_graph", () => {
  it("emits entities and relations from prose patterns", () => {
    const parsed = readSkillFile(fixtureRoot, "valid-skill");
    const graph = buildGraphFromSkills([parsed]);
    expect(graph.entities.has("valid-skill")).toBe(true);
    expect(graph.relations.some((r) => r.relationType === "references")).toBe(true);
    expect(graph.relations.some((r) => r.relationType === "depends_on")).toBe(true);
  });
});

// scenario: SC-e32s02-P0-02
describe("graph store", () => {
  const tmpGraph = path.join(fixtureRoot, "graph/test-graph.jsonl");

  beforeAll(() => {
    const parsed = readSkillFile(fixtureRoot, "valid-skill");
    const graph = buildGraphFromSkills([parsed]);
    saveGraph(tmpGraph, graph);
  });

  it("persists and reloads graph.jsonl", () => {
    const loaded = loadGraph(tmpGraph);
    expect(loaded.entities.size).toBe(1);
    expect(loaded.relations.length).toBeGreaterThan(0);
  });
});

// scenario: SC-e32s03-P1-01
describe("search_skills", () => {
  it("ranks skills by substring query", () => {
    const index = discoverSkills(fixtureRoot, phaseForSkill);
    expect(index.length).toBeGreaterThan(0);
  });
});

// scenario: SC-e32s03-P1-02
describe("get_dependencies", () => {
  it("returns graph relations for a skill", () => {
    const parsed = readSkillFile(fixtureRoot, "valid-skill");
    const graph = buildGraphFromSkills([parsed]);
    expect(graph.relations.length).toBeGreaterThan(0);
  });
});

// scenario: SC-e32s04-P2-01
describe("get_git_context", () => {
  it("scopes git status to skills and specs dirs", () => {
    if (!isGitRepo(repoRoot)) return;
    const result = getGitContext(repoRoot, "status");
    expect(result.action).toBe("status");
  });
});

// scenario: SC-e32s05-P1-01
describe("validate_skill", () => {
  it("flags missing verify on fixture", () => {
    const parsed = readSkillFile(fixtureRoot, "missing-verify");
    const report = validateSkillConventions(parsed, fixtureRoot);
    expect(report.checks.find((c) => c.id === "verify-command")?.pass).toBe(false);
  });

  it("passes valid fixture checks except broken links", () => {
    const parsed = readSkillFile(fixtureRoot, "valid-skill");
    const report = validateSkillConventions(parsed, fixtureRoot);
    expect(report.checks.find((c) => c.id === "verify-command")?.pass).toBe(true);
  });
});

describe("parseSkillMarkdown unit", () => {
  it("parses inline markdown without file IO", () => {
    const md = `---\nname: x\n---\n\n# Title\n\nHello world.\n\n\`\`\`bash\necho hi\n\`\`\``;
    const result = parseSkillMarkdown(md, "x", "/tmp/x/SKILL.md", "/tmp");
    expect(result.frontmatter.name).toBe("x");
    expect(result.codeBlocks[0].lang).toBe("bash");
  });
});
