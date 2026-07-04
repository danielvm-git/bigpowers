import fs from "node:fs";
import path from "node:path";
import yaml from "js-yaml";
import { unified } from "unified";
import remarkParse from "remark-parse";
import { MAX_READ_SKILL_BYTES } from "../config.js";
import { PathGuardError, resolveSkillPath } from "./paths.js";
export function discoverSkills(repoRoot, phaseFn) {
    const skillsDir = path.join(repoRoot, "skills");
    if (!fs.existsSync(skillsDir))
        return [];
    return fs
        .readdirSync(skillsDir, { withFileTypes: true })
        .filter((d) => d.isDirectory())
        .map((d) => {
        const skillPath = path.join(skillsDir, d.name, "SKILL.md");
        if (!fs.existsSync(skillPath))
            return null;
        return {
            name: d.name,
            path: path.relative(repoRoot, skillPath),
            phase: phaseFn(d.name),
        };
    })
        .filter((e) => e !== null)
        .sort((a, b) => a.name.localeCompare(b.name));
}
export function readSkillFile(repoRoot, skillName, maxBytes = MAX_READ_SKILL_BYTES) {
    let skillPath;
    try {
        skillPath = resolveSkillPath(repoRoot, skillName);
    }
    catch (err) {
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
export function parseSkillMarkdown(raw, skillName, skillPath, repoRoot) {
    const { yamlBlock, body } = extractFrontmatterBlock(raw);
    const frontmatter = parseFrontmatterYaml(yamlBlock);
    const tree = unified().use(remarkParse).parse(body);
    const headings = [];
    const codeBlocks = [];
    const links = [];
    const proseParts = [];
    let currentHeading = null;
    const sections = [];
    let currentSectionProse = [];
    function flushSection() {
        if (currentSectionProse.length > 0 || currentHeading !== null) {
            sections.push({
                heading: currentHeading,
                prose: currentSectionProse.join("\n").trim(),
            });
            currentSectionProse = [];
        }
    }
    function walk(node, inParagraph = false) {
        if (node.type === "heading") {
            flushSection();
            const h = node;
            const text = extractText(h);
            headings.push({ depth: h.depth, text });
            currentHeading = text;
            return;
        }
        if (node.type === "code") {
            const c = node;
            codeBlocks.push({ lang: c.lang ?? null, value: c.value });
            return;
        }
        if (node.type === "link") {
            const l = node;
            links.push({ text: extractText(l), url: l.url });
        }
        if (node.type === "paragraph") {
            const text = extractText(node);
            if (text) {
                proseParts.push(text);
                currentSectionProse.push(text);
            }
        }
        if ("children" in node && Array.isArray(node.children)) {
            for (const child of node.children) {
                walk(child, node.type === "paragraph");
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
function extractFrontmatterBlock(raw) {
    const start = raw.indexOf("---");
    if (start === -1)
        return { yamlBlock: "", body: raw };
    const lineEnd = raw.indexOf("\n", start);
    if (lineEnd === -1)
        return { yamlBlock: "", body: raw };
    const close = raw.indexOf("\n---", lineEnd);
    if (close === -1)
        return { yamlBlock: "", body: raw };
    const yamlBlock = raw.slice(lineEnd + 1, close);
    const body = raw.slice(close + 4).replace(/^\r?\n/, "");
    return { yamlBlock, body };
}
function parseFrontmatterYaml(yamlBlock) {
    if (!yamlBlock.trim())
        return {};
    try {
        return yaml.load(yamlBlock) ?? {};
    }
    catch {
        const result = {};
        for (const line of yamlBlock.split("\n")) {
            const m = /^([a-zA-Z0-9_-]+):\s*(.+)$/.exec(line.trim());
            if (m)
                result[m[1]] = m[2].replace(/^["']|["']$/g, "");
        }
        return result;
    }
}
function extractText(node) {
    if (!node.children)
        return "";
    return node.children
        .map((c) => {
        if (c.type === "text")
            return c.value;
        if ("children" in c && c.children)
            return extractText(c);
        return "";
    })
        .join("");
}
//# sourceMappingURL=skill-parser.js.map