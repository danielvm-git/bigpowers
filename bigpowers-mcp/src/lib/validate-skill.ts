import fs from "node:fs";
import path from "node:path";
import type { ParsedSkill } from "./skill-parser.js";
import { resolveSkillPath } from "./paths.js";

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

const VERB_NOUN = /^[a-z]+-[a-z]+(-[a-z]+)*$/;
const CRITICAL_PATH_PHASES = new Set(["Build", "Verify", "Release"]);

export function validateSkillConventions(
  parsed: ParsedSkill,
  repoRoot: string,
): ValidationReport {
  const checks: ValidationCheck[] = [];
  const fm = parsed.frontmatter;
  const name = parsed.name;

  checks.push({
    id: "verb-noun-naming",
    pass: VERB_NOUN.test(name),
    message: VERB_NOUN.test(name)
      ? "Skill name is verb-noun kebab-case"
      : `Skill name '${name}' is not verb-noun kebab-case`,
    remediation: "Rename directory to two-word kebab-case (e.g. develop-tdd)",
  });

  for (const field of ["name", "description"]) {
    checks.push({
      id: `frontmatter-${field}`,
      pass: Boolean(fm[field]),
      message: fm[field] ? `Has frontmatter.${field}` : `Missing frontmatter.${field}`,
      remediation: `Add ${field} to YAML frontmatter block`,
    });
  }

  const hasVerify =
    parsed.rawProse.includes("→ verify:") ||
    parsed.rawProse.includes("verify:") ||
    parsed.codeBlocks.some((b) => b.value.includes("verify:"));
  checks.push({
    id: "verify-command",
    pass: hasVerify,
    message: hasVerify ? "Has verify command reference" : "Missing verify command",
    remediation: "Add a → verify: block with a runnable check",
  });

  const lineCount = fs.readFileSync(resolveSkillPath(repoRoot, name), "utf8").split("\n").length;
  const isCritical = CRITICAL_PATH_PHASES.has(
    String(fm.effort ?? "") === "heavy" ? "Build" : "Build",
  );
  const cap = isCritical ? 150 : 120;
  checks.push({
    id: "size-cap",
    pass: lineCount <= cap,
    message:
      lineCount <= cap
        ? `Within size cap (${lineCount}/${cap} lines)`
        : `Exceeds size cap (${lineCount}/${cap} lines)`,
    remediation: "Split content into REFERENCE.md or reduce prose",
  });

  for (const link of parsed.links) {
    if (link.url.startsWith("skills/")) {
      const target = link.url.replace(/^skills\//, "").replace(/\/SKILL\.md$/, "");
      const targetPath = path.join(repoRoot, "skills", target, "SKILL.md");
      const ok = fs.existsSync(targetPath);
      checks.push({
        id: `link-${target}`,
        pass: ok,
        message: ok ? `Link to ${link.url} resolves` : `Broken link: ${link.url}`,
        remediation: ok ? undefined : `Create skills/${target}/SKILL.md or fix link`,
      });
    }
  }

  const pass = checks.every((c) => c.pass);
  return { skill: name, pass, checks };
}
