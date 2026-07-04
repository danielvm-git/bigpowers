import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { getRepoRoot, getGraphPath } from "../config.js";
import { discoverSkills, readSkillFile } from "../lib/skill-parser.js";
import { phaseForSkill } from "../lib/phase-map.js";
import { buildGraphFromSkills } from "../lib/graph/builder.js";
import { loadGraph, saveGraph, searchNodes, openNodes, getForwardDeps, getReverseDeps, getHandoffChain, getConventions } from "../lib/graph/store.js";
import type { SkillGraph } from "../lib/graph/types.js";
import { getGitContext, isGitRepo } from "../lib/git-context.js";
import { validateSkillConventions } from "../lib/validate-skill.js";
import { z } from "zod";

export interface ServerContext {
  repoRoot: string;
  graphPath: string;
  graph: SkillGraph;
}

export function createContext(): ServerContext {
  const repoRoot = getRepoRoot();
  const graphPath = getGraphPath(repoRoot);
  return { repoRoot, graphPath, graph: loadGraph(graphPath) };
}

function jsonResult(data: unknown) {
  return {
    content: [{ type: "text" as const, text: JSON.stringify(data, null, 2) }],
  };
}

function toolError(message: string) {
  return {
    content: [{ type: "text" as const, text: JSON.stringify({ error: message }) }],
    isError: true,
  };
}

export function registerTools(server: McpServer, ctx: ServerContext): void {
  // story: e32s01
  server.registerTool(
    "index_skills",
    {
      description: "Discover all skills/*/SKILL.md files with name, path, and lifecycle phase",
      inputSchema: z.object({}).optional(),
    },
    async () => {
      const skills = discoverSkills(ctx.repoRoot, phaseForSkill);
      return jsonResult({ count: skills.length, skills });
    },
  );

  server.registerTool(
    "read_skill",
    {
      description: "Parse a SKILL.md via remark — returns frontmatter, headings, code blocks, sections, links",
      inputSchema: z.object({
        name: z.string().describe("Skill directory name (verb-noun, kebab-case)"),
      }),
    },
    async ({ name }) => {
      try {
        const parsed = readSkillFile(ctx.repoRoot, name);
        return jsonResult(parsed);
      } catch (err) {
        return toolError(err instanceof Error ? err.message : String(err));
      }
    },
  );

  // story: e32s02
  server.registerTool(
    "build_skill_graph",
    {
      description: "Build entity-relation graph from parsed SKILL.md data and persist to graph.jsonl",
      inputSchema: z.object({
        force: z.boolean().optional().describe("Rebuild even if graph exists"),
      }),
    },
    async ({ force }) => {
      const index = discoverSkills(ctx.repoRoot, phaseForSkill);
      const parsed = index.map((s) => readSkillFile(ctx.repoRoot, s.name));
      ctx.graph = buildGraphFromSkills(parsed);
      saveGraph(ctx.graphPath, ctx.graph);
      return jsonResult({
        entities: ctx.graph.entities.size,
        relations: ctx.graph.relations.length,
        graphPath: ctx.graphPath,
        force: force ?? false,
      });
    },
  );

  server.registerTool(
    "read_graph",
    {
      description: "Return the full skill knowledge graph (entities + relations)",
      inputSchema: z.object({}).optional(),
    },
    async () => {
      if (ctx.graph.entities.size === 0) {
        ctx.graph = loadGraph(ctx.graphPath);
      }
      return jsonResult({
        entities: [...ctx.graph.entities.values()],
        relations: ctx.graph.relations,
      });
    },
  );

  server.registerTool(
    "search_nodes",
    {
      description: "Search graph entities by name, type, or observation text",
      inputSchema: z.object({ query: z.string() }),
    },
    async ({ query }) => {
      if (ctx.graph.entities.size === 0) ctx.graph = loadGraph(ctx.graphPath);
      return jsonResult({ results: searchNodes(ctx.graph, query) });
    },
  );

  server.registerTool(
    "open_nodes",
    {
      description: "Open specific graph entities by name",
      inputSchema: z.object({ names: z.array(z.string()) }),
    },
    async ({ names }) => {
      if (ctx.graph.entities.size === 0) ctx.graph = loadGraph(ctx.graphPath);
      return jsonResult({ entities: openNodes(ctx.graph, names) });
    },
  );

  // story: e32s03
  server.registerTool(
    "search_skills",
    {
      description: "Search skills by name, description, model, or effort (case-insensitive substring)",
      inputSchema: z.object({
        query: z.string(),
        exact: z.boolean().optional(),
      }),
    },
    async ({ query, exact }) => {
      const index = discoverSkills(ctx.repoRoot, phaseForSkill);
      const q = query.toLowerCase();
      const results = index
        .map((entry) => {
          let parsed;
          try {
            parsed = readSkillFile(ctx.repoRoot, entry.name);
          } catch {
            return null;
          }
          const fm = parsed.frontmatter;
          const hay = [
            entry.name,
            entry.phase,
            String(fm.description ?? ""),
            String(fm.model ?? ""),
            String(fm.effort ?? ""),
          ]
            .join(" ")
            .toLowerCase();
          const match = exact ? entry.name.toLowerCase() === q : hay.includes(q);
          const score = exact ? (match ? 100 : 0) : (hay.match(new RegExp(q.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), "g")) ?? []).length;
          return match ? { ...entry, frontmatter: fm, score } : null;
        })
        .filter((r): r is NonNullable<typeof r> => r !== null)
        .sort((a, b) => b.score - a.score);
      return jsonResult({ count: results.length, results });
    },
  );

  // story: e32s03
  server.registerTool(
    "get_dependencies",
    {
      description: "Forward/reverse deps, handoff chain, and conventions for a skill",
      inputSchema: z.object({ name: z.string() }),
    },
    async ({ name }) => {
      if (ctx.graph.entities.size === 0) ctx.graph = loadGraph(ctx.graphPath);
      return jsonResult({
        skill: name,
        depends_on: getForwardDeps(ctx.graph, name),
        depended_by: getReverseDeps(ctx.graph, name),
        handoff_chain: getHandoffChain(ctx.graph, name),
        conventions: getConventions(ctx.graph, name),
      });
    },
  );

  // story: e32s04
  server.registerTool(
    "get_git_context",
    {
      description: "Git change awareness scoped to skills/ and specs/ — status, log, or diff",
      inputSchema: z.object({
        action: z.enum(["status", "log", "diff"]).default("status"),
      }),
    },
    async ({ action }) => {
      if (!isGitRepo(ctx.repoRoot)) {
        return toolError("Not a git repository");
      }
      try {
        return jsonResult(getGitContext(ctx.repoRoot, action));
      } catch (err) {
        return toolError(err instanceof Error ? err.message : String(err));
      }
    },
  );

  // story: e32s05
  server.registerTool(
    "validate_skill",
    {
      description: "Check a SKILL.md against bigpowers conventions",
      inputSchema: z.object({ name: z.string() }),
    },
    async ({ name }) => {
      try {
        const parsed = readSkillFile(ctx.repoRoot, name);
        const report = validateSkillConventions(parsed, ctx.repoRoot);
        return jsonResult(report);
      } catch (err) {
        return toolError(err instanceof Error ? err.message : String(err));
      }
    },
  );
}
