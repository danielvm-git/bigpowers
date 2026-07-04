import fs from "node:fs";
import path from "node:path";
import yaml from "js-yaml";
import { unified } from "unified";
import remarkParse from "remark-parse";
import type { Root, Heading, Code, Link, Paragraph, Text } from "mdast";
import { MAX_READ_SKILL_BYTES } from "../config.js";
import { PathGuardError, resolveSkillPath } from "./paths.js";

export interface SkillIndexEntry {
  name: string;
  path: string;
  phase: string;
}

export interface ParsedSkill {
  name: string;
  path: string;
  frontmatter: Record<string, unknown>;
  headings: Array<{ depth: number; text: string }>;
  codeBlocks: Array<{ lang: string | null; value: string }>;
  sections: Array<{ heading: string | null; prose: string }>;
  links: Array<{ text: string; url: string }>;
  rawProse: string;
  truncated?: boolean;
}

export function discoverSkills(repoRoot: string, phaseFn: (n: string) => string): SkillIndexEntry[] {
  const skillsDir = path.join(repoRoot, "skills");
  if (!fs.existsSync(skillsDir)) return [];

  return fs
    .readdirSync(skillsDir, { withFileTypes: true })
    .filter((d) => d.isDirectory())
    .map((d) => {
      const skillPath = path.join(skillsDir, d.name, "SKILL.md");
      if (!fs.existsSync(skillPath)) return null;
      return {
        name: d.name,
        path: path.relative(repoRoot, skillPath),
        phase: phaseFn(d.name),
      };
    })
    .filter((e): e is SkillIndexEntry => e !== null)
    .sort((a, b) => a.name.localeCompare(b.name));
}

export function readSkillFile(
  repoRoot: string,
  skillName: string,
  maxBytes = MAX_READ_SKILL_BYTES,
): ParsedSkill {
  let skillPath: string;
  try {
    skillPath = resolveSkillPath(repoRoot, skillName);
  } catch (err) {
    if (err instanceof PathGuardError) {
      throw new Error(`Skill not found or invalid: ${skillName}`);
    }
    throw err;
  }

  if (!fs.existsSync(skillPath)) {
    throw new Error(`Skill not found: ${skillName}`);
  }

  let raw = fs.readFileSync(skillPath, "utf8");
  let truncated = false;
  if (Buffer.byteLength(raw, "utf8") > maxBytes) {
    raw = raw.slice(0, maxBytes);
    truncated = true;
  }

  return { ...parseSkillMarkdown(raw, skillName, skillPath, repoRoot), truncated };
}

export function parseSkillMarkdown(
  raw: string,
  skillName: string,
  skillPath: string,
  repoRoot: string,
): ParsedSkill {
  const { yamlBlock, body } = extractFrontmatterBlock(raw);
  const frontmatter = parseFrontmatterYaml(yamlBlock);

  const tree = unified().use(remarkParse).parse(body) as Root;

  const headings: ParsedSkill["headings"] = [];
  const codeBlocks: ParsedSkill["codeBlocks"] = [];
  const links: ParsedSkill["links"] = [];
  const proseParts: string[] = [];

  let currentHeading: string | null = null;
  const sections: ParsedSkill["sections"] = [];
  let currentSectionProse: string[] = [];

  function flushSection() {
    if (currentSectionProse.length > 0 || currentHeading !== null) {
      sections.push({
        heading: currentHeading,
        prose: currentSectionProse.join("\n").trim(),
      });
      currentSectionProse = [];
    }
  }

  function walk(node: Root["children"][number], inParagraph = false): void {
    if (node.type === "heading") {
      flushSection();
      const h = node as Heading;
      const text = extractText(h);
      headings.push({ depth: h.depth, text });
      currentHeading = text;
      return;
    }
    if (node.type === "code") {
      const c = node as Code;
      codeBlocks.push({ lang: c.lang ?? null, value: c.value });
      return;
    }
    if (node.type === "link") {
      const l = node as Link;
      links.push({ text: extractText(l), url: l.url });
    }
    if (node.type === "paragraph") {
      const text = extractText(node as Paragraph);
      if (text) {
        proseParts.push(text);
        currentSectionProse.push(text);
      }
    }
    if ("children" in node && Array.isArray(node.children)) {
      for (const child of node.children) {
        walk(child as Root["children"][number], node.type === "paragraph");
      }
    }
  }

  for (const child of tree.children) {
    walk(child);
  }
  flushSection();

  return {
    name: skillName,
    path: path.relative(repoRoot, skillPath),
    frontmatter,
    headings,
    codeBlocks,
    sections,
    links,
    rawProse: proseParts.join("\n"),
  };
}

function extractFrontmatterBlock(raw: string): { yamlBlock: string; body: string } {
  const start = raw.indexOf("---");
  if (start === -1) return { yamlBlock: "", body: raw };
  const lineEnd = raw.indexOf("\n", start);
  if (lineEnd === -1) return { yamlBlock: "", body: raw };
  const close = raw.indexOf("\n---", lineEnd);
  if (close === -1) return { yamlBlock: "", body: raw };
  const yamlBlock = raw.slice(lineEnd + 1, close);
  const body = raw.slice(close + 4).replace(/^\r?\n/, "");
  return { yamlBlock, body };
}

function parseFrontmatterYaml(yamlBlock: string): Record<string, unknown> {
  if (!yamlBlock.trim()) return {};
  try {
    return (yaml.load(yamlBlock) as Record<string, unknown>) ?? {};
  } catch {
    const result: Record<string, unknown> = {};
    for (const line of yamlBlock.split("\n")) {
      const m = /^([a-zA-Z0-9_-]+):\s*(.+)$/.exec(line.trim());
      if (m) result[m[1]] = m[2].replace(/^["']|["']$/g, "");
    }
    return result;
  }
}

function extractText(node: { children?: Array<{ type: string; value?: string; children?: unknown[] }> }): string {
  if (!node.children) return "";
  return node.children
    .map((c) => {
      if (c.type === "text") return (c as Text).value;
      if ("children" in c && c.children) return extractText(c as typeof node);
      return "";
    })
    .join("");
}
