import path from "node:path";

export class PathGuardError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "PathGuardError";
  }
}

/** Resolve userPath strictly within allowedRoot; reject traversal. */
export function resolveWithin(allowedRoot: string, userPath: string): string {
  const normalized = userPath.replace(/\\/g, "/").trim();
  if (!normalized || normalized.startsWith("/") || normalized.includes("..")) {
    throw new PathGuardError(`Invalid path: ${userPath}`);
  }

  const resolved = path.resolve(allowedRoot, normalized);
  const rootWithSep = allowedRoot.endsWith(path.sep)
    ? allowedRoot
    : allowedRoot + path.sep;

  if (!resolved.startsWith(rootWithSep) && resolved !== allowedRoot) {
    throw new PathGuardError(`Path escapes allowed root: ${userPath}`);
  }
  return resolved;
}

/** Resolve a skill name to skills/<name>/SKILL.md under repo root. */
export function resolveSkillPath(repoRoot: string, skillName: string): string {
  const name = skillName.trim();
  if (!name || name.includes("/") || name.includes("\\") || name.includes("..")) {
    throw new PathGuardError(`Invalid skill name: ${skillName}`);
  }
  const skillsDir = path.join(repoRoot, "skills");
  const skillDir = resolveWithin(skillsDir, name);
  return path.join(skillDir, "SKILL.md");
}

export function isSecretPath(filePath: string): boolean {
  const base = path.basename(filePath);
  return (
    base.startsWith(".env") ||
    /\.pem$/i.test(base) ||
    /secret/i.test(base) ||
    /credentials/i.test(base)
  );
}
