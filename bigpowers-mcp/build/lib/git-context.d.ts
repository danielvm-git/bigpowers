export interface GitContextResult {
    action: string;
    changed_files: Record<string, string[]>;
    commits?: Array<{
        hash: string;
        subject: string;
        files: string[];
    }>;
    diffs?: Record<string, string>;
}
export declare function getGitContext(repoRoot: string, action: "status" | "log" | "diff"): GitContextResult;
export declare function isGitRepo(repoRoot: string): boolean;
