#!/usr/bin/env node
/**
 * e33s02 — Generate Starlight content from repo sources.
 * DO NOT hand-edit website/src/content/docs/* — edit sources and re-run prebuild.
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const WEBSITE_ROOT = path.resolve(__dirname, '..');
const REPO_ROOT = path.resolve(WEBSITE_ROOT, '..');
const DOCS_ROOT = path.join(WEBSITE_ROOT, 'src/content/docs');
const SITE_BASE = '/bigpowers';
const SITE_URL = 'https://danielvm-git.github.io/bigpowers';

const PHASE_ORDER = [
	'Discover',
	'Design',
	'Plan',
	'Build',
	'Verify',
	'Release',
	'Sustain',
];

const PHASE_SLUG = {
	Discover: 'discover',
	Design: 'design',
	Plan: 'plan',
	Build: 'build',
	Verify: 'verify',
	Release: 'release',
	Sustain: 'sustain',
};

const FALLBACK_PHASE = {
	'gate-trace': 'Verify',
	'plan-tests': 'Plan',
};

function read(filePath) {
	return fs.readFileSync(filePath, 'utf8');
}

function write(filePath, content) {
	fs.mkdirSync(path.dirname(filePath), { recursive: true });
	fs.writeFileSync(filePath, content, 'utf8');
}

function rmDir(dir) {
	if (fs.existsSync(dir)) {
		fs.rmSync(dir, { recursive: true, force: true });
	}
}

function parseFrontmatter(text) {
	const start = text.indexOf('---');
	if (start === -1) {
		throw new Error('Missing YAML frontmatter block');
	}
	const rest = text.slice(start);
	const match = rest.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n([\s\S]*)$/);
	if (!match) {
		throw new Error('Missing YAML frontmatter block');
	}
	const raw = match[1];
	const body = match[2];
	const fields = {};
	for (const line of raw.split('\n')) {
		const m = line.match(/^([A-Za-z0-9_-]+):\s*(.*)$/);
		if (!m) continue;
		let value = m[2].trim();
		if (
			(value.startsWith('"') && value.endsWith('"')) ||
			(value.startsWith("'") && value.endsWith("'"))
		) {
			value = value.slice(1, -1);
		}
		fields[m[1]] = value;
	}
	return { fields, body };
}

function escapeYaml(value) {
	return JSON.stringify(String(value));
}

function firstHeading(markdown) {
	const match = markdown.match(/^#\s+(.+)$/m);
	return match ? match[1].trim() : path.basename(markdown, path.extname(markdown));
}

function stripTopHeading(markdown) {
	return markdown.replace(/^#\s+[^\n]+\n+/, '');
}

function rewriteLinks(markdown) {
	return markdown
		.replace(/\]\((\.\/)?docs\/([^)]+)\)/g, '](/guides/$2)')
		.replace(/!\[([^\]]*)\]\((\.\/)?docs\/images\/([^)]+)\)/g, '![$1](/images/$3)')
		.replace(/\]\((\.\/)?SKILL-INDEX\.md\)/g, '](/reference/skill-index/)')
		.replace(/\]\((\.\/)?README\.md\)/g, '](/)')
		.replace(/\]\((\.\/)?skills\/([^)]+)\)/g, '](/skills/$2/)');
}

/** Prevent MDX from treating angle brackets as JSX (preserve fenced code blocks). */
function escapeMdxBody(markdown) {
	return markdown
		.split(/(```[\s\S]*?```)/g)
		.map((part, index) => (index % 2 === 1 ? part : part.replace(/</g, '&lt;')))
		.join('');
}

function loadPhaseMap() {
	const indexPath = path.join(REPO_ROOT, 'SKILL-INDEX.md');
	const text = read(indexPath);
	const phaseMap = new Map();
	const rowRe = /\|\s*\d+\s*\|\s*(\w+)\s*\|\s*`([^`]+)`/g;
	for (const match of text.matchAll(rowRe)) {
		phaseMap.set(match[2], match[1]);
	}
	return phaseMap;
}

function listSkillSources() {
	return fs
		.readdirSync(path.join(REPO_ROOT, 'skills'))
		.map((name) => path.join(REPO_ROOT, 'skills', name, 'SKILL.md'))
		.filter((filePath) => fs.existsSync(filePath))
		.sort((a, b) => a.localeCompare(b));
}

function clearGeneratedContent() {
	rmDir(DOCS_ROOT);
	fs.mkdirSync(DOCS_ROOT, { recursive: true });
}

function generateLandingPage() {
	const readme = read(path.join(REPO_ROOT, 'README.md'));
	const lede =
		'Agent skills synthesizing 17 years of software engineering discipline into a prescriptive methodology for solo developers.';
	let body = stripTopHeading(readme);
	body = rewriteLinks(body);
	body = escapeMdxBody(body);
	const content = `---
title: Getting Started
description: ${escapeYaml(lede)}
template: splash
hero:
  tagline: Agent skills for spec-driven, test-first development with AI agents.
  actions:
    - text: Browse skills
      link: /skills/
      icon: right-arrow
    - text: View on GitHub
      link: https://github.com/danielvm-git/bigpowers
      icon: external
      variant: minimal
---

${body}
`;
	write(path.join(DOCS_ROOT, 'index.mdx'), content);
}

function generateSkills(phaseMap) {
	const skillSources = listSkillSources();
	const byPhase = Object.fromEntries(PHASE_ORDER.map((phase) => [phase, []]));

	for (const skillPath of skillSources) {
		const dirName = path.basename(path.dirname(skillPath));
		let parsed;
		try {
			parsed = parseFrontmatter(read(skillPath));
		} catch (error) {
			throw new Error(`Failed to parse frontmatter for ${dirName}: ${error.message}`);
		}
		const name = parsed.fields.name || dirName;
		const description = parsed.fields.description || `${name} skill`;
		const phase =
			phaseMap.get(name) || FALLBACK_PHASE[name] || (console.warn(`WARN: no phase mapping for ${name}, using Sustain`), 'Sustain');

		const outPath = path.join(DOCS_ROOT, 'skills', `${name}.mdx`);
		const page = `---
title: ${name}
description: ${escapeYaml(description)}
---

${escapeMdxBody(parsed.body.trim())}
`;
		write(outPath, page);
		byPhase[phase].push({ name, description });
	}

	for (const phase of PHASE_ORDER) {
		byPhase[phase].sort((a, b) => a.name.localeCompare(b.name));
	}

	const indexLines = [
		'---',
		'title: Skills',
		'description: "All bigpowers agent skills grouped by lifecycle phase."',
		'---',
		'',
		'# Skills',
		'',
		`Browse **${skillSources.length}** skills by lifecycle phase.`,
		'',
	];

	for (const phase of PHASE_ORDER) {
		const items = byPhase[phase];
		if (!items.length) continue;
		indexLines.push(`## ${phase}`, '');
		for (const item of items) {
			const safeDescription = escapeMdxBody(item.description);
			indexLines.push(`- [${item.name}](/skills/${item.name}/) — ${safeDescription}`);
		}
		indexLines.push('');
	}

	write(path.join(DOCS_ROOT, 'skills/index.mdx'), indexLines.join('\n'));
	return { skillSources, byPhase };
}

function generateGuides() {
	const docsDir = path.join(REPO_ROOT, 'docs');
	const outDir = path.join(DOCS_ROOT, 'guides');
	const entries = fs.readdirSync(docsDir, { withFileTypes: true });
	for (const entry of entries) {
		if (!entry.isFile() || !entry.name.endsWith('.md')) continue;
		const source = path.join(docsDir, entry.name);
		const markdown = read(source);
		const title = firstHeading(markdown);
		const body = stripTopHeading(markdown);
		const page = `---
title: ${escapeYaml(title)}
description: ${escapeYaml(title)}
---

${escapeMdxBody(body.trim())}
`;
		write(path.join(outDir, entry.name.replace(/\.md$/, '.md')), page);
	}
}

function generateDecisions() {
	const adrDir = path.join(REPO_ROOT, 'specs/adr');
	const outDir = path.join(DOCS_ROOT, 'decisions');
	const files = fs
		.readdirSync(adrDir)
		.filter((name) => name.endsWith('.md'))
		.sort((a, b) => b.localeCompare(a, undefined, { numeric: true }));

	const sidebarItems = [];
	for (const fileName of files) {
		const source = path.join(adrDir, fileName);
		const markdown = read(source);
		const title = firstHeading(markdown);
		const slug = fileName.replace(/\.md$/, '');
		const page = `---
title: ${escapeYaml(title)}
description: ${escapeYaml(title)}
---

${escapeMdxBody(markdown.trim())}
`;
		write(path.join(outDir, `${slug}.md`), page);
		sidebarItems.push({ label: title, slug: `decisions/${slug}` });
	}
	return sidebarItems;
}

function generateSkillIndex() {
	const markdown = read(path.join(REPO_ROOT, 'SKILL-INDEX.md'));
	const body = stripTopHeading(markdown);
	const page = `---
title: Skill Index
description: "Auto-generated catalog of all bigpowers skills."
---

${escapeMdxBody(body.trim())}
`;
	write(path.join(DOCS_ROOT, 'reference/skill-index.md'), page);
}

function generateSidebar(byPhase, decisionItems) {
	const skillGroups = PHASE_ORDER.filter((phase) => byPhase[phase]?.length).map((phase) => ({
		label: phase,
		collapsed: phase !== 'Discover' && phase !== 'Build',
		items: byPhase[phase].map((skill) => ({
			label: skill.name,
			slug: `skills/${skill.name}`,
		})),
	}));

	const sidebar = [
		{ label: 'Getting Started', link: '/' },
		{ label: 'Skills', items: [{ slug: 'skills' }, ...skillGroups] },
		{
			label: 'Guides',
			items: [{ autogenerate: { directory: 'guides' } }],
		},
		{
			label: 'Decisions',
			items: decisionItems.map((item) => ({ label: item.label, slug: item.slug })),
		},
		{
			label: 'Reference',
			items: [{ label: 'Skill Index', slug: 'reference/skill-index' }],
		},
	];

	const file = `// Generated by website/scripts/prebuild.mjs — DO NOT EDIT
export const generatedSidebar = ${JSON.stringify(sidebar, null, '\t')};
`;
	write(path.join(WEBSITE_ROOT, 'sidebar.generated.mjs'), file);
}

function pageUrl(slug) {
	const normalized = slug.replace(/\/$/, '');
	return normalized ? `${SITE_URL}${SITE_BASE}/${normalized}/` : `${SITE_URL}${SITE_BASE}/`;
}

function generateLlmsTxt(byPhase, skillSources) {
	const lines = [
		'# bigpowers',
		'',
		'> Agent skills for spec-driven, test-first development with AI agents.',
		'',
		'## Documentation',
		'',
		`- [Getting Started](${pageUrl('')}): Project overview and quick start`,
		`- [Skills](${pageUrl('skills')}): ${skillSources.length} lifecycle skills`,
		`- [Skill Index](${pageUrl('reference/skill-index')}): Auto-generated catalog`,
		'',
		'## Skills',
		'',
	];

	for (const phase of PHASE_ORDER) {
		const items = byPhase[phase];
		if (!items?.length) continue;
		for (const skill of items) {
			lines.push(
				`- [${skill.name}](${pageUrl(`skills/${skill.name}`)}): ${skill.description}`,
			);
		}
	}

	write(path.join(WEBSITE_ROOT, 'public/llms.txt'), `${lines.join('\n')}\n`);
}

function generateFavicon() {
	const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32" role="img" aria-label="bp">
  <rect width="32" height="32" rx="6" fill="#111827"/>
  <text x="16" y="21" text-anchor="middle" font-family="ui-sans-serif, system-ui, sans-serif" font-size="12" font-weight="700" fill="#ffffff">bp</text>
</svg>
`;
	write(path.join(WEBSITE_ROOT, 'public/favicon.svg'), svg);
}

function assertSkillCount(skillSources) {
	const generated = fs
		.readdirSync(path.join(DOCS_ROOT, 'skills'))
		.filter((name) => name.endsWith('.mdx') && name !== 'index.mdx');
	if (generated.length !== skillSources.length) {
		throw new Error(
			`Skill page count mismatch: generated ${generated.length}, expected ${skillSources.length}`,
		);
	}
}

function main() {
	console.log('prebuild: clearing generated docs content…');
	clearGeneratedContent();

	console.log('prebuild: loading phase map from SKILL-INDEX.md…');
	const phaseMap = loadPhaseMap();

	console.log('prebuild: generating landing page…');
	generateLandingPage();

	console.log('prebuild: generating skill pages…');
	const { skillSources, byPhase } = generateSkills(phaseMap);
	assertSkillCount(skillSources);

	console.log('prebuild: generating guides…');
	generateGuides();

	console.log('prebuild: generating ADRs…');
	const decisionItems = generateDecisions();

	console.log('prebuild: generating skill index…');
	generateSkillIndex();

	console.log('prebuild: generating sidebar config…');
	generateSidebar(byPhase, decisionItems);

	console.log('prebuild: generating llms.txt…');
	generateLlmsTxt(byPhase, skillSources);

	console.log('prebuild: writing favicon…');
	generateFavicon();

	write(path.join(WEBSITE_ROOT, 'public/.nojekyll'), '');
	write(
		path.join(WEBSITE_ROOT, 'public/robots.txt'),
		'User-agent: *\nAllow: /\nSitemap: https://danielvm-git.github.io/bigpowers/sitemap-index.xml\n',
	);

	console.log('prebuild: copying docs images for README assets…');
	copyDocsImages();

	console.log(`prebuild: done — ${skillSources.length} skill pages generated.`);
}

function copyDocsImages() {
	const srcDir = path.join(REPO_ROOT, 'docs/images');
	const destDir = path.join(WEBSITE_ROOT, 'public/images');
	if (!fs.existsSync(srcDir)) return;
	rmDir(destDir);
	fs.cpSync(srcDir, destDir, { recursive: true });
}

try {
	main();
} catch (error) {
	console.error(`prebuild: ${error.message}`);
	process.exit(1);
}
