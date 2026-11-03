// story: e82s03
// extensions/omp-hooks.ts
// bigpowers — Single OMP extension entry exposing source skills through the
// bigpowers_skill LLM tool and enforcing safety policy guards. Pi prompt
// templates own slash-command registration so each workflow appears once.
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { execSync } from "node:child_process";
import { readdirSync, readFileSync, statSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

// Skills live at skills/<name>/SKILL.md — scan inside that directory, so
// only truly foreign entries (e.g. a stray node_modules symlink) need exclusion.
const EXCLUDED_DIRS = new Set([".git", "node_modules"]);

// ---------------------------------------------------------------------------
// Git argv normalization (BUG-2026-11-03-guard-git-flag-normalize, #184).
//
// Literal substring patterns cannot see a global flag in front of the
// subcommand (`git -C repo reset --hard`), a flag between the subcommand and the
// destructive option (`git reset -q --hard`), or an alternative spelling of the
// same act (`git checkout -- .`, `git branch --delete --force`). Tokenize the
// command, drop the global options, then judge (subcommand, arguments).
//
// scripts/lib/git-argv.py is the same rule table in Python for the shell hooks;
// scripts/test-guard-git-normalize.sh fails if the two disagree on any fixture.
// ---------------------------------------------------------------------------

/** Quote-aware split; a quoting error degrades to whitespace splitting, never to eval. */
export function tokenizeArgs(command: string): string[] {
  const tokens: string[] = [];
  let current = "";
  let quote: '"' | "'" | null = null;
  let hasToken = false;
  for (let i = 0; i < command.length; i++) {
    const ch = command[i];
    if (quote) {
      if (ch === quote) quote = null;
      else current += ch;
      continue;
    }
    if (ch === '"' || ch === "'") {
      quote = ch as '"' | "'";
      hasToken = true;
      continue;
    }
    if (/\s/.test(ch)) {
      if (hasToken) {
        tokens.push(current);
        current = "";
        hasToken = false;
      }
      continue;
    }
    current += ch;
    hasToken = true;
  }
  if (hasToken) tokens.push(current);
  return tokens;
}

// Global options that consume the next token as their value.
const GIT_VALUE_FLAGS = new Set([
  "-C", "-c", "--exec-path", "--git-dir", "--work-tree", "--namespace",
  "--super-prefix", "--config-env",
]);

// Global options that stand alone.
const GIT_BARE_FLAGS = new Set([
  "-p", "--paginate", "--no-pager", "--bare", "--no-replace-objects",
  "--literal-pathspecs", "--glob-pathspecs", "--icase-pathspecs",
  "--no-optional-locks", "--version", "--help",
]);

const SEPARATORS = new Set([";", "&&", "||", "|", "&", "(", ")", "\n"]);

function shortFlagHas(args: string[], letter: string): boolean {
  return args.some((a) => a.startsWith("-") && !a.startsWith("--") && a.slice(1).includes(letter));
}

/** Block reason for one normalized git invocation, or null. Mirror git-argv.py. */
export function classifyGitInvocation(sub: string, args: string[]): string | null {
  if (sub === "reset" && args.includes("--hard")) return "git reset --hard discards uncommitted work";
  if (sub === "clean" && (shortFlagHas(args, "f") || args.includes("--force"))) {
    return "git clean -f deletes untracked files";
  }
  if (sub === "branch") {
    const forced =
      args.includes("-D") ||
      (args.includes("--delete") && (args.includes("--force") || shortFlagHas(args, "f")));
    if (forced) return "git branch -D deletes an unmerged branch";
  }
  if (sub === "checkout") {
    if (args.includes("-f") || args.includes("--force")) return "git checkout -f discards local changes";
    if (args.includes(".")) return "git checkout . discards local changes";
  }
  if (sub === "restore" && (args.includes("--worktree") || args.includes("."))) {
    return "git restore discards local changes";
  }
  if (sub === "push") {
    const leased = args.some((a) => a === "--force-with-lease" || a.startsWith("--force-with-lease="));
    const forced =
      args.includes("-f") ||
      args.includes("--force") ||
      args.some((a) => a.startsWith("+") && !a.startsWith("++"));
    if (forced && !leased) return "force push rewrites remote history";
  }
  return null;
}

/** Every (subcommand, args) pair in a command, with global options stripped. */
export function gitInvocations(tokens: string[]): Array<{ sub: string; args: string[] }> {
  const found: Array<{ sub: string; args: string[] }> = [];
  let i = 0;
  while (i < tokens.length) {
    const token = tokens[i];
    if (token.split("/").pop() !== "git") {
      i += 1;
      continue;
    }
    let j = i + 1;
    while (j < tokens.length) {
      const opt = tokens[j];
      if (SEPARATORS.has(opt)) break;
      const name = opt.split("=")[0];
      if (GIT_VALUE_FLAGS.has(name)) {
        j += opt.includes("=") ? 1 : 2;
        continue;
      }
      if (GIT_BARE_FLAGS.has(name) || (opt.startsWith("-") && !opt.startsWith("--") && opt.length > 1)) {
        j += 1;
        continue;
      }
      break;
    }
    if (j >= tokens.length || SEPARATORS.has(tokens[j])) {
      i = j + 1;
      continue;
    }
    const sub = tokens[j];
    const args: string[] = [];
    let k = j + 1;
    while (k < tokens.length && !SEPARATORS.has(tokens[k])) {
      args.push(tokens[k]);
      k += 1;
    }
    found.push({ sub, args });
    i = k;
  }
  return found;
}

/** The normalized verdict for a whole shell command: a reason to block, or null. */
export function dangerousGitCommand(command: string): string | null {
  for (const { sub, args } of gitInvocations(tokenizeArgs(command))) {
    const reason = classifyGitInvocation(sub, args);
    if (reason) return reason;
  }
  return null;
}


// Conventional Commits specifies `type(scope)!:`, but many repositories write
// `type!(scope):`. Accept both; the leading type is what matters.
const CONVENTIONAL_RE =
  /^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)!?(?:\([^)]+\))?!?:\s.+/;

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

// Command-aware branch resolution: `git commit|push` in a bash command must
// be judged against the repo it will actually run in, not the agent process
// cwd (which is the session root — often a different repository).
// Resolve the directory: the last `cd <path>` before it (within the command
// prefix), overridden by the last `git -C <path>` anywhere in the command.
// Fail-closed: unresolvable paths fall back to the process cwd — previous
// behavior, over-blocks, never under-blocks.
function commandGitCwd(command: string, upTo: number, fallback: string): string {
  const head = command.slice(0, upTo);
  const cdMatches = [
    ...head.matchAll(/\bcd\s+(?:"([^"]+)"|'([^']+)'|([^&|;<(`$][^\s&|;<>]*))/g),
  ];
  const cMatches = [
    ...command.matchAll(/\bgit\s+-C\s+(?:"([^"]+)"|'([^']+)'|([^&|;<(`$][^\s&|;<>]*))/g),
  ];
  const m = cMatches.length
    ? cMatches[cMatches.length - 1]
    : cdMatches.length
      ? cdMatches[cdMatches.length - 1]
      : null;
  if (!m) return fallback;
  const p = m[1] ?? m[2] ?? m[3];
  if (!p || p.includes("$") || p.includes("`")) return fallback;
  try {
    const abs = resolve(fallback, p);
    return statSync(abs).isDirectory() ? abs : fallback;
  } catch {
    return fallback;
  }
}

function inGitRepo(cwd?: string): boolean {
  try {
    execSync("git rev-parse --git-dir", {
      cwd,
      encoding: "utf-8",
      timeout: 3000,
      stdio: "ignore",
    });
    return true;
  } catch {
    return false;
  }
}

function currentBranch(cwd: string): string {
  // Probing a directory that is not a repository makes git print
  // "fatal: not a git repository (or any of the parent directories): .git".
  // execSync inherits fd 2 when no stdio option is given, so that message is
  // painted straight over the TUI input line and vanishes on the next redraw
  // (BUG-2026-11-03-omp-hooks-stderr-leak, issue #189). Ask inGitRepo() first —
  // it is silent — so a non-repo target spawns no git process at all.
  if (!inGitRepo(cwd)) return "unknown";
  try {
    return execSync("git rev-parse --abbrev-ref HEAD", {
      encoding: "utf-8",
      timeout: 3000,
      cwd,
      stdio: ["ignore", "pipe", "ignore"],
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
  // NOTE: Do not call action methods (setLabel, sendUserMessage, setModel, …)
  // in the factory body. pi installs throwing stubs for them during extension
  // loading and only binds real implementations afterward — a load-time call
  // aborts the whole pi startup (BUG-2026-09-05, #119). Only registration
  // methods (registerCommand/registerTool/on/registerFlag) are valid here;
  // perform actions inside event/command handlers via the runtime-bound `pi`.

  // Discover skills from skills/ in the installed plugin package root.
  const skills = discoverSkills(join(pluginRoot(), "skills"));

  // ----- bigpowers_skill tool --------------------------------------------

  pi.registerTool({
    name: "bigpowers_skill",
    label: "Bigpowers Skill",
    description:
      "Interact with bigpowers source skills. Use 'list' to enumerate available skills, 'get' to retrieve a skill's full markdown, and 'run' to activate a skill with arguments.",
    parameters: Type.Object({
      action: Type.Union(
        [Type.Literal("list"), Type.Literal("get"), Type.Literal("run")],
        {
          description:
            "Operation: list all skills, get one skill, or run a skill with arguments",
        },
      ),
      skill: Type.Optional(
        Type.String({
          description: "Skill name — required for 'get' and 'run' actions",
        }),
      ),
      args: Type.Optional(
        Type.String({
          description: "User arguments passed to the skill — only used with 'run'",
        }),
      ),
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

    const gitReason = dangerousGitCommand(command);
    if (gitReason) {
      return {
        block: true,
        reason: `BLOCKED: ${gitReason}. Use a safer approach or ask the user.`,
      };
    }

    const sessionRoot = process.cwd();
    if (!inGitRepo(sessionRoot)) return;
    const pushBranch = currentBranch(commandGitCwd(command, command.length, sessionRoot));

    if (/git\s+push/.test(command) && protectedPushTarget(command, pushBranch)) {
      return {
        block: true,
        reason:
          "BLOCKED: Direct push to protected branch. Use kickoff-branch + release-branch.",
      };
    }

    if (/git\s+commit/.test(command)) {
      const commitBranches = [...command.matchAll(/\bgit\s+commit\b/g)].map((m) =>
        currentBranch(commandGitCwd(command, m.index ?? 0, sessionRoot)),
      );
      const hit = commitBranches.find((b) =>
        (PROTECTED_BRANCHES as readonly string[]).includes(b),
      );
      if (hit) {
        return {
          block: true,
          reason: `BLOCKED: Direct commits to '${hit}' are forbidden. Use a feature branch.`,
        };
      }
      const msg = extractCommitMessage(command);
      if (msg) {
        if (!CONVENTIONAL_RE.test(msg)) {
          return {
            block: true,
            reason: `BLOCKED: Commit subject '${msg.split("\n")[0]}' must follow Conventional Commits: <type>(<scope>): <subject>.`,
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
