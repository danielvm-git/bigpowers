export interface SkillIndexEntry {
    name: string;
    path: string;
    phase: string;
}
export interface ParsedSkill {
    name: string;
    path: string;
    frontmatter: Record<string, unknown>;
    headings: Array<{
        depth: number;
        text: string;
    }>;
    codeBlocks: Array<{
        lang: string | null;
        value: string;
    }>;
    sections: Array<{
        heading: string | null;
        prose: string;
    }>;
    links: Array<{
        text: string;
        url: string;
    }>;
    rawProse: string;
    truncated?: boolean;
}
export declare function discoverSkills(repoRoot: string, phaseFn: (n: string) => string): SkillIndexEntry[];
export declare function readSkillFile(repoRoot: string, skillName: string, maxBytes?: number): ParsedSkill;
export declare function parseSkillMarkdown(raw: string, skillName: string, skillPath: string, repoRoot: string): ParsedSkill;
