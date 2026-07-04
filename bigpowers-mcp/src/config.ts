import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const packageDir = path.dirname(fileURLToPath(import.meta.url));

/** Repo root: cwd when launched from workspace, else parent of bigpowers-mcp. */
export function getRepoRoot(): string {
  const fromEnv = process.env.BIGPOWERS_ROOT;
  if (fromEnv) return path.resolve(fromEnv);

  const cwd = process.cwd();
  if (isRepoRoot(cwd)) return cwd;

  const parentOfPackage = path.resolve(packageDir, "../..");
  if (isRepoRoot(parentOfPackage)) return parentOfPackage;

  return cwd;
}

function isRepoRoot(dir: string): boolean {
  return (
    fs.existsSync(path.join(dir, "skills")) && fs.existsSync(path.join(dir, "specs"))
  );
}

export function getSkillsDir(repoRoot: string): string {
  return path.join(repoRoot, "skills");
}

export function getGraphPath(repoRoot: string): string {
  return path.join(repoRoot, "bigpowers-mcp", "graph.jsonl");
}

export const MAX_READ_SKILL_BYTES = 512 * 1024;

export const SECRET_DENYLIST = [
  /\.env/i,
  /\.pem$/i,
  /secret/i,
  /credentials/i,
];

export const GIT_SCOPE_DIRS = ["skills", "specs"];
