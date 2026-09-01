// story: e82s03
// extensions/omp-hooks.ts
// bigpowers — Single OMP extension entry exposing every source skill as a
// slash command, a bigpowers_skill LLM tool, and safety policy guards.
import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";
import { execSync } from "node:child_process";
import { readdirSync, readFileSync, statSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

// Skills live at skills/<name>/SKILL.md — scan inside that directory, so
// only truly foreign entries (e.g. a stray node_modules symlink) need exclusion.
const EXCLUDED_DIRS = new Set([".git", "node_modules"]);

const DANGEROUS_PATTERNS = [
  /git\s+reset\s+--hard/,
  /git\s+clean\s+-f/,
  /git\s+branch\s+-D/,
  /git\s+checkout\s+\./,
  /git\s+restore\s+\./,
  /push\s+--force/,
  /push\s+-f(?:\s|$)/,
];

const CONVENTIONAL_RE =
  /^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([^)]+\))?!?:\s.+/;

const PROTECTED_BRANCH_RE = /(?:^|\s|[:])(?:main|master)(?:\s|$)/;
const PROTECTED_BRANCHES = ["main", "master"] as const;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface SkillMeta {
  name: string;
  description: string;
  /** Filesystem path to the skill's SKILL.md. */
  path: string;
  /** Full SKILL.md content (body only, frontmatter stripped). */
  markdown: string;
}

// ---------------------------------------------------------------------------
// YAML frontmatter
// ---------------------------------------------------------------------------

/**
 * Conservatively reads the `name` and `description` keys from YAML-style
 * frontmatter delimited by `---`.  Only single-line values are handled;
 * a multi-line YAML value silently yields the directory name as fallback.
 */
function parseFrontmatter(
  content: string,
  dirName: string,
): { name: string; description: string } {
  const lines = content.split("\n");
  if (lines[0]?.trim() !== "---") {
    return { name: dirName, description: "" };
  }

  const endIdx = lines.indexOf("---", 1);
  if (endIdx === -1) {
    return { name: dirName, description: "" };
  }

  let name = dirName;
  let description = "";

  for (let i = 1; i < endIdx; i++) {
    const line = lines[i];
    const nameMatch = line.match(/^name:\s*(.+)$/);
    if (nameMatch) {
      name = nameMatch[1].trim();
      continue;
    }
    const descMatch = line.match(/^description:\s*(.+)$/);
    if (descMatch) {
      description = descMatch[1].trim();
      continue;
    }
  }

  return { name, description };
}

/** Returns the SKILL.md body below the closing `---` frontmatter line. */
function stripFrontmatter(content: string): string {
  const lines = content.split("\n");
  if (lines[0]?.trim() !== "---") return content;
  const endIdx = lines.indexOf("---", 1);
  if (endIdx === -1) return content;
  // Skip both `---` lines and one blank line if present.
  let start = endIdx + 1;
  if (lines[start]?.trim() === "") start++;
  return lines.slice(start).join("\n");
}

// ---------------------------------------------------------------------------
// Skill discovery
// ---------------------------------------------------------------------------

function collectSkillMd(dirPath: string): string | null {
  const mdPath = join(dirPath, "SKILL.md");
  try {
    const st = statSync(mdPath);
    if (!st.isFile()) return null;
    return readFileSync(mdPath, "utf-8");
  } catch {
    return null;
  }
}

/**
 * Scans `skillsRoot` (expected: `<package-root>/skills/`) for immediate
 * subdirectories that contain a SKILL.md file.
 */
function discoverSkills(skillsRoot: string): SkillMeta[] {
  const entries = readdirSync(skillsRoot);
  const result: SkillMeta[] = [];

  for (const entry of entries) {
    if (EXCLUDED_DIRS.has(entry)) continue;

    const absPath = join(skillsRoot, entry);
    let st;
    try {
      st = statSync(absPath);
    } catch {
      continue;
    }
    if (!st.isDirectory()) continue;

    const content = collectSkillMd(absPath);
    if (content === null) continue;

    const { name, description } = parseFrontmatter(content, entry);
    const markdown = stripFrontmatter(content);

    result.push({ name, description, path: join(absPath, "SKILL.md"), markdown });
  }

  return result;
}

function pluginRoot(): string {
  return dirname(dirname(fileURLToPath(import.meta.url)));
}

// ---------------------------------------------------------------------------
// Git safety helpers
// ---------------------------------------------------------------------------

function currentBranch(): string {
  try {
    return execSync("git rev-parse --abbrev-ref HEAD", {
      encoding: "utf-8",
      timeout: 3000,
    }).trim();
  } catch {
    return "unknown";
  }
}

function protectedPushTarget(command: string, branch: string): boolean {
  if (PROTECTED_BRANCH_RE.test(command)) return true;
  const trimmed = command.trim();
  return (
    branch === "main" &&
    (trimmed === "git push" || trimmed === "git push origin")
  );
}

function extractCommitMessage(command: string): string | null {
  const dq = command.match(/-m\s+"([^"]+)"/);
  if (dq) return dq[1];
  const sq = command.match(/-m\s+'([^']+)'/);
  return sq ? sq[1] : null;
}

// ---------------------------------------------------------------------------
// Prompt builder
// ---------------------------------------------------------------------------

function buildSkillPrompt(skill: SkillMeta, args: string): string {
  const header = [
    `Activate skill: ${skill.name}`,
    `Description: ${skill.description}`,
    "",
    "--- SKILL.md ---",
  ].join("\n");

  const body = skill.markdown;

  let footer = "";
  if (args.trim()) {
    footer = `\n\n--- USER ARGUMENTS ---\n${args.trim()}`;
  }

  return `${header}\n${body}${footer}`;
}

// ---------------------------------------------------------------------------

async function injectSkillPrompt(
  pi: ExtensionAPI,
  prompt: string,
): Promise<{ injected: boolean; via: "sendUserMessage" | "sendMessage" | "none" }> {
  try {
    await pi.sendUserMessage(prompt);
    return { injected: true, via: "sendUserMessage" };
  } catch {
    try {
      await pi.sendMessage(
        {
          customType: "bigpowers.skill",
          content: prompt,
          display: true,
          attribution: "user",
        },
        { deliverAs: "nextTurn", triggerTurn: true },
      );
      return { injected: true, via: "sendMessage" };
    } catch {
      return { injected: false, via: "none" };
    }
  }
}

// ---------------------------------------------------------------------------
// Extension factory
// ---------------------------------------------------------------------------

export default function bigpowers(pi: ExtensionAPI) {
  const z = pi.zod;

  pi.setLabel("bigpowers");

  // Discover skills from skills/ in the installed plugin package root.
  const skills = discoverSkills(join(pluginRoot(), "skills"));

  // ----- Slash commands --------------------------------------------------

  for (const skill of skills) {
    pi.registerCommand(skill.name, {
      description: skill.description,
      handler: async (args, _ctx) => {
        const prompt = buildSkillPrompt(skill, args);
        await injectSkillPrompt(pi, prompt);
      },
    });
  }

  // ----- bigpowers_skill tool --------------------------------------------

  pi.registerTool({
    name: "bigpowers_skill",
    label: "Bigpowers Skill",
    description:
      "Interact with bigpowers source skills. Use 'list' to enumerate available skills, 'get' to retrieve a skill's full markdown, and 'run' to activate a skill with arguments.",
    parameters: z.object({
      action: z
        .enum(["list", "get", "run"])
        .describe("Operation: list all skills, get one skill, or run a skill with arguments"),
      skill: z
        .string()
        .optional()
        .describe("Skill name — required for 'get' and 'run' actions"),
      args: z
        .string()
        .optional()
        .describe("User arguments passed to the skill — only used with 'run'"),
    }),
    async execute(_id, params, _signal, _onUpdate, _ctx) {
      const { action, skill: skillName, args } = params;

      switch (action) {
        case "list": {
          const listing = skills.map((s) => ({
            name: s.name,
            description: s.description,
          }));
          return {
            content: [{ type: "text", text: JSON.stringify(listing, null, 2) }],
            details: { skills: listing },
          };
        }

        case "get": {
          if (!skillName) {
            return {
              content: [{ type: "text", text: "Error: 'skill' parameter is required for 'get' action." }],
              details: { error: "missing_skill_param" },
            };
          }
          const found = skills.find((s) => s.name === skillName);
          if (!found) {
            return {
              content: [
                {
                  type: "text",
                  text: `Error: skill '${skillName}' not found. Use 'list' to see available skills.`,
                },
              ],
              details: { error: "skill_not_found", skill: skillName },
            };
          }
          return {
            content: [
              { type: "text", text: `# ${found.name}\n\n${found.description}\n\n---\n\n${found.markdown}` },
            ],
            details: { name: found.name, description: found.description },
          };
        }

        case "run": {
          if (!skillName) {
            return {
              content: [{ type: "text", text: "Error: 'skill' parameter is required for 'run' action." }],
              details: { error: "missing_skill_param" },
            };
          }
          const found = skills.find((s) => s.name === skillName);
          if (!found) {
            return {
              content: [
                {
                  type: "text",
                  text: `Error: skill '${skillName}' not found. Use 'list' to see available skills.`,
                },
              ],
              details: { error: "skill_not_found", skill: skillName },
            };
          }
          const prompt = buildSkillPrompt(found, args ?? "");
          const { injected, via } = await injectSkillPrompt(pi, prompt);
          return {
            content: [{ type: "text", text: prompt }],
            details: { skill: found.name, injected, via },
          };
        }
      }
    },
  });

  // ----- Event handlers --------------------------------------------------

  pi.on("session_start", async (_event, ctx) => {
    const count = skills.length;
    ctx.ui.notify(`bigpowers: ${count} skills loaded`, "info");
  });

  pi.on("tool_call", (event) => {
    if (event.toolName !== "bash") return;
    const { command } = event.input as { command?: string };
    if (!command) return;

    for (const pat of DANGEROUS_PATTERNS) {
      if (pat.test(command)) {
        return {
          block: true,
          reason: `BLOCKED: '${command}' matches dangerous pattern '${pat}'.`,
        };
      }
    }

    const branch = currentBranch();

    if (/git\s+push/.test(command) && protectedPushTarget(command, branch)) {
      return {
        block: true,
        reason:
          "BLOCKED: Direct push to protected branch. Use kickoff-branch + release-branch.",
      };
    }

    if (/git\s+commit/.test(command)) {
      if ((PROTECTED_BRANCHES as readonly string[]).includes(branch)) {
        return {
          block: true,
          reason: `BLOCKED: Direct commits to '${branch}' are forbidden. Use a feature branch.`,
        };
      }
      const msg = extractCommitMessage(command);
      if (msg) {
        if (!CONVENTIONAL_RE.test(msg)) {
          return {
            block: true,
            reason:
              "BLOCKED: Commit message must follow Conventional Commits: <type>(<scope>): <subject>.",
          };
        }
        if (msg.split("\n")[0].length > 72) {
          return {
            block: true,
            reason: "BLOCKED: Commit subject line must be ≤72 characters.",
          };
        }
      }
    }
  });
}
