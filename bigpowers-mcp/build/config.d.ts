/** Repo root: cwd when launched from workspace, else parent of bigpowers-mcp. */
export declare function getRepoRoot(): string;
export declare function getSkillsDir(repoRoot: string): string;
export declare function getGraphPath(repoRoot: string): string;
export declare const MAX_READ_SKILL_BYTES: number;
export declare const SECRET_DENYLIST: RegExp[];
export declare const GIT_SCOPE_DIRS: string[];
