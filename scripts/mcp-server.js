#!/usr/bin/env node
// bigpowers MCP server — exposes 68 skills as MCP tools via stdio transport
// Zero dependencies — raw JSON-RPC over stdio with Content-Length framing

'use strict';

const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const SKILLS_LOCK = path.join(ROOT, 'skills-lock.json');
const STATE_YAML = path.join(ROOT, 'specs', 'state.yaml');

// Phase map — mirrors generate-skill-index.sh PHASE_MAP
const PHASE_MAP = {
  'survey-context': 'Discover', 'research-first': 'Discover', 'search-skills': 'Discover',
  'using-bigpowers': 'Discover', 'map-codebase': 'Discover', 'elaborate-spec': 'Discover',
  'model-domain': 'Design', 'define-language': 'Design', 'grill-me': 'Design',
  'grill-with-docs': 'Design', 'deepen-architecture': 'Design', 'design-interface': 'Design',
  'define-success': 'Design',
  'scope-work': 'Plan', 'slice-tasks': 'Plan', 'plan-work': 'Plan', 'plan-release': 'Plan',
  'plan-refactor': 'Plan', 'assess-impact': 'Plan', 'change-request': 'Plan',
  'run-planning': 'Plan', 'seed-conventions': 'Plan',
  'develop-tdd': 'Build', 'kickoff-branch': 'Build', 'execute-plan': 'Build',
  'build-epic': 'Build', 'spike-prototype': 'Build', 'craft-skill': 'Build',
  'quick-fix': 'Build', 'setup-environment': 'Build', 'wire-observability': 'Build',
  'wire-ci': 'Build', 'publish-package': 'Build', 'align-grid': 'Build',
  'orchestrate-project': 'Build', 'guard-git': 'Build', 'hook-commits': 'Build',
  'deploy': 'Build', 'smoke-test': 'Build', 'validate-contracts': 'Build',
  'verify-work': 'Verify', 'validate-fix': 'Verify', 'audit-code': 'Verify',
  'enforce-first': 'Verify', 'run-evals': 'Verify', 'investigate-bug': 'Verify',
  'diagnose-root': 'Verify', 'fix-bug': 'Verify', 'inspect-quality': 'Verify',
  'request-review': 'Verify', 'respond-review': 'Verify', 'trace-requirement': 'Verify',
  'release-branch': 'Release', 'commit-message': 'Release',
  'session-state': 'Sustain', 'terse-mode': 'Sustain', 'compose-workflow': 'Sustain',
  'delegate-task': 'Sustain', 'dispatch-agents': 'Sustain', 'edit-document': 'Sustain',
  'evolve-skill': 'Sustain', 'migrate-spec': 'Sustain', 'organize-workspace': 'Sustain',
  'reset-baseline': 'Sustain', 'simulate-agents': 'Sustain', 'stocktake-skills': 'Sustain',
  'write-document': 'Sustain',
};

function loadSkillsCatalog() {
  const lock = JSON.parse(fs.readFileSync(SKILLS_LOCK, 'utf8'));
  return Object.entries(lock.skills).map(([name, meta]) => ({
    name,
    description: meta.description,
    path: meta.path,
    phase: PHASE_MAP[name] || 'Other',
  }));
}

function getSkillContent(skillName) {
  const catalog = loadSkillsCatalog();
  const skill = catalog.find(s => s.name === skillName);
  if (!skill) return null;
  const skillPath = path.join(ROOT, skill.path);
  if (!fs.existsSync(skillPath)) return null;
  return fs.readFileSync(skillPath, 'utf8');
}

function searchSkills(query) {
  const terms = query.toLowerCase().split(/\s+/).filter(Boolean);
  const catalog = loadSkillsCatalog();
  return catalog
    .map(skill => {
      const haystack = `${skill.name} ${skill.description} ${skill.phase}`.toLowerCase();
      const score = terms.reduce((s, t) => s + (haystack.includes(t) ? 1 : 0), 0);
      return { skill, score };
    })
    .filter(({ score }) => score > 0)
    .sort((a, b) => b.score - a.score)
    .map(({ skill }) => skill);
}

// Tool handlers
const TOOLS = {
  bigpowers_list_skills: {
    description: 'List all bigpowers skills with name, description, and lifecycle phase. Optionally filter by phase.',
    inputSchema: {
      type: 'object',
      properties: {
        phase: {
          type: 'string',
          description: 'Filter by lifecycle phase: Discover, Design, Plan, Build, Verify, Release, Sustain',
        },
      },
    },
    handler({ phase } = {}) {
      let skills = loadSkillsCatalog();
      if (phase) skills = skills.filter(s => s.phase.toLowerCase() === phase.toLowerCase());
      return skills.map(({ name, description, phase: p }) => ({ name, description, phase: p }));
    },
  },

  bigpowers_get_skill: {
    description: 'Get the full SKILL.md content for a specific bigpowers skill by name.',
    inputSchema: {
      type: 'object',
      properties: {
        name: { type: 'string', description: 'Skill name (kebab-case, e.g. "survey-context")' },
      },
      required: ['name'],
    },
    handler({ name }) {
      const content = getSkillContent(name);
      if (!content) return { error: `Skill "${name}" not found` };
      return { name, content };
    },
  },

  bigpowers_search_skills: {
    description: 'Search bigpowers skills by keyword or intent. Returns matching skills ranked by relevance.',
    inputSchema: {
      type: 'object',
      properties: {
        query: { type: 'string', description: 'Natural language query or keywords, e.g. "deploy to production"' },
      },
      required: ['query'],
    },
    handler({ query }) {
      return searchSkills(query).map(({ name, description, phase }) => ({ name, description, phase }));
    },
  },

  bigpowers_get_state: {
    description: 'Get the current bigpowers project state (active flow, epic, story, step) from specs/state.yaml.',
    inputSchema: { type: 'object', properties: {} },
    handler() {
      if (!fs.existsSync(STATE_YAML)) return { error: 'specs/state.yaml not found' };
      return { content: fs.readFileSync(STATE_YAML, 'utf8') };
    },
  },

  bigpowers_invoke_skill: {
    description: 'Get the full instructions for a skill in context. Returns SKILL.md content suitable for agent invocation.',
    inputSchema: {
      type: 'object',
      properties: {
        name: { type: 'string', description: 'Skill name to invoke (kebab-case)' },
        context: { type: 'string', description: 'Optional context or arguments to pass with the skill invocation' },
      },
      required: ['name'],
    },
    handler({ name, context }) {
      const content = getSkillContent(name);
      if (!content) return { error: `Skill "${name}" not found` };
      const result = { name, instructions: content };
      if (context) result.context = context;
      return result;
    },
  },
};

// ─── MCP stdio transport ──────────────────────────────────────────────────────

let inputBuffer = Buffer.alloc(0);

process.stdin.on('data', chunk => {
  inputBuffer = Buffer.concat([inputBuffer, chunk]);
  processBuffer();
});

process.stdin.on('end', () => process.exit(0));

function processBuffer() {
  while (true) {
    const headerEnd = inputBuffer.indexOf('\r\n\r\n');
    if (headerEnd === -1) break;

    const header = inputBuffer.slice(0, headerEnd).toString();
    const match = header.match(/Content-Length:\s*(\d+)/i);
    if (!match) { inputBuffer = inputBuffer.slice(headerEnd + 4); continue; }

    const contentLength = parseInt(match[1], 10);
    const bodyStart = headerEnd + 4;
    if (inputBuffer.length < bodyStart + contentLength) break;

    const body = inputBuffer.slice(bodyStart, bodyStart + contentLength).toString();
    inputBuffer = inputBuffer.slice(bodyStart + contentLength);

    try { handleMessage(JSON.parse(body)); } catch (_) {}
  }
}

function send(msg) {
  const body = JSON.stringify(msg);
  process.stdout.write(`Content-Length: ${Buffer.byteLength(body, 'utf8')}\r\n\r\n${body}`);
}

function handleInitialize(id) {
  send({
    jsonrpc: '2.0', id,
    result: {
      protocolVersion: '2024-11-05',
      capabilities: { tools: {} },
      serverInfo: { name: 'bigpowers', version: '1.0.0' },
    },
  });
}

function handleToolsList(id) {
  send({
    jsonrpc: '2.0', id,
    result: {
      tools: Object.entries(TOOLS).map(([name, tool]) => ({
        name,
        description: tool.description,
        inputSchema: tool.inputSchema,
      })),
    },
  });
}

function handleToolCall(id, params) {
  const { name, arguments: args } = params;
  const tool = TOOLS[name];
  if (!tool) {
    send({ jsonrpc: '2.0', id, error: { code: -32601, message: `Unknown tool: ${name}` } });
    return;
  }
  try {
    const result = tool.handler(args || {});
    send({
      jsonrpc: '2.0', id,
      result: { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] },
    });
  } catch (err) {
    send({ jsonrpc: '2.0', id, error: { code: -32603, message: err.message } });
  }
}

function handleMessage(msg) {
  const { id, method, params } = msg;
  if (method === 'initialize') { handleInitialize(id); return; }
  if (method === 'notifications/initialized') return;
  if (method === 'tools/list') { handleToolsList(id); return; }
  if (method === 'tools/call') { handleToolCall(id, params); return; }
  if (id !== undefined) {
    send({ jsonrpc: '2.0', id, error: { code: -32601, message: `Method not found: ${method}` } });
  }
}

// Allow require() without starting the server (for testing)
if (require.main === module) {
  process.stderr.write('bigpowers MCP server started (stdio)\n');
}
