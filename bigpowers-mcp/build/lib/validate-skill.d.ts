import type { ParsedSkill } from "./skill-parser.js";
export interface ValidationCheck {
    id: string;
    pass: boolean;
    message: string;
    remediation?: string;
}
export interface ValidationReport {
    skill: string;
    pass: boolean;
    checks: ValidationCheck[];
}
export declare function validateSkillConventions(parsed: ParsedSkill, repoRoot: string): ValidationReport;
