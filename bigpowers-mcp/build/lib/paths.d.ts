export declare class PathGuardError extends Error {
    constructor(message: string);
}
/** Resolve userPath strictly within allowedRoot; reject traversal. */
export declare function resolveWithin(allowedRoot: string, userPath: string): string;
/** Resolve a skill name to skills/<name>/SKILL.md under repo root. */
export declare function resolveSkillPath(repoRoot: string, skillName: string): string;
export declare function isSecretPath(filePath: string): boolean;
