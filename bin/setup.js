#!/usr/bin/env node
// story: e60s01
// story: e74s02
// bigpowers setup — interactive installer
// Combines GSD simplicity with BMAD visual polish.

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const { installGlobal, installLocal, uninstallTool, detectExistingInstall } = require('../scripts/lib/install-helpers');

const ROOT = path.resolve(path.dirname(__filename), '..');
const pkg = require(path.join(ROOT, 'package.json'));

// ── ANSI helpers ─────────────────────────────────────────────────────────────
const c = {
  cyan: (s) => `\x1b[36m${s}\x1b[0m`,
  green: (s) => `\x1b[32m${s}\x1b[0m`,
  red: (s) => `\x1b[31m${s}\x1b[0m`,
  dim: (s) => `\x1b[2m${s}\x1b[0m`,
  bold: (s) => `\x1b[1m${s}\x1b[0m`,
};

// ── ASCII banner ─────────────────────────────────────────────────────────────
const BANNER = `
${c.cyan('╔════════════════════════════════════════════════════════════════════════════╗')}
${c.cyan('║')}                                                                            ${c.cyan('║')}
${c.cyan('║')}   ${c.bold(c.cyan('██████╗ ██╗ ██████╗ ██████╗  ██████╗ █      █ ███████╗██████╗ ███████╗'))}   ${c.cyan('║')}
${c.cyan('║')}   ${c.bold(c.cyan('██╔══██╗██║██╔════╝ ██╔══██╗██╔═══██╗█      █ ██╔════╝██╔══██╗██╔════╝'))}   ${c.cyan('║')}
${c.cyan('║')}   ${c.bold(c.cyan('██████╔╝██║██║  ███╗██████╔╝██║   ██║█  ██  █ █████╗  ██████╔╝███████╗'))}   ${c.cyan('║')}
${c.cyan('║')}   ${c.bold(c.cyan('██╔══██╗██║██║   ██║██╔═══╝ ██║   ██║█ ████ █ ██╔══╝  ██╔══██╗╚════██║'))}   ${c.cyan('║')}
${c.cyan('║')}   ${c.bold(c.cyan('██████╔╝██║╚██████╔╝██║     ╚██████╔╝███  ███ ███████╗██║  ██║███████║'))}   ${c.cyan('║')}
${c.cyan('║')}   ${c.bold(c.cyan('╚═════╝ ╚═╝ ╚═════╝ ╚═╝      ╚═════╝ ╚═╝  ╚═╝ ╚══════╝╚═╝  ╚═╝╚══════╝'))}   ${c.cyan('║')}
${c.cyan('║')}                                                                            ${c.cyan('║')}
${c.cyan('║')}           ${c.dim('Spec-Driven & Test-First Skills for Solo Developers')}              ${c.cyan('║')}
${c.cyan('║')}           ${c.dim(`v${pkg.version}`)}                                                          ${c.cyan('║')}
${c.cyan('╚════════════════════════════════════════════════════════════════════════════╝')}
`;

// ── Tool definitions ─────────────────────────────────────────────────────────
const TOOLS = [
  { id: 'claude', name: 'Claude Code', globalPath: '~/.claude', localPath: '.claude' },
  { id: 'antigravity', name: 'Antigravity', globalPath: '~/.gemini/antigravity-cli/skills', localPath: '.agents/skills' },
  { id: 'augment', name: 'Augment', globalPath: '~/.augment', localPath: '.augment' },
  { id: 'cline', name: 'Cline', globalPath: '.clinerules', localPath: '.clinerules' },
  { id: 'codebuddy', name: 'CodeBuddy', globalPath: '~/.codebuddy', localPath: '.codebuddy' },
  { id: 'codex', name: 'Codex', globalPath: '~/.codex', localPath: '.codex' },
  { id: 'copilot', name: 'Copilot', globalPath: '~/.copilot', localPath: '.copilot' },
  { id: 'cursor', name: 'Cursor', globalPath: '~/.cursor', localPath: '.cursor' },
  { id: 'gemini', name: 'Gemini', globalPath: '~/.gemini', localPath: '.gemini' },
  { id: 'hermes', name: 'Hermes Agent', globalPath: '~/.hermes', localPath: '.hermes' },
  { id: 'mimo', name: 'MiMo Code', globalPath: '~/.mimocode', localPath: '.mimocode' },
  { id: 'kilo', name: 'Kilo', globalPath: '~/.config/kilo', localPath: '.config/kilo' },
  { id: 'opencode', name: 'OpenCode', globalPath: '~/.config/opencode', localPath: '.config/opencode' },
  { id: 'pi', name: 'pi', globalPath: '~/.pi/agent/skills', localPath: '.pi/agent/skills' },
  { id: 'qwen', name: 'Qwen Code', globalPath: '~/.qwen', localPath: '.qwen' },
  { id: 'trae', name: 'Trae', globalPath: '~/.trae', localPath: '.trae' },
  { id: 'windsurf', name: 'Windsurf', globalPath: '~/.codeium/windsurf', localPath: '.codeium/windsurf' },
  { id: 'zcode', name: 'ZCode', globalPath: '~/.zcode', localPath: '.zcode' },
];
const SUPPORTED_IDS = new Set(['claude', 'gemini', 'pi', 'hermes', 'mimo', 'zcode', 'cursor', 'codex', 'antigravity', 'agy']);
const UNSUPPORTED_HINT = '(TODO)';

// ── clack helpers (lazy ESM import from CJS) ─────────────────────────────────
let _clack;
async function clack() {
  if (!_clack) _clack = await import('@clack/prompts');
  return _clack;
}

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

function runInherited(cmd) {
  execSync(cmd, { cwd: ROOT, stdio: 'inherit' });
}



// ── Uninstall flow ──────────────────────────────────────────────────────────
async function handleUninstall() {
  const { multiselect: ms, confirm: cf, spinner: sp, outro: ot, isCancel: ic } = await clack();

  const toolOptions = TOOLS.filter((t) => SUPPORTED_IDS.has(t.id)).map((tool) => {
    return { value: tool.id, label: tool.name, hint: `(${tool.globalPath})` };
  });

  const selectedToolIds = await ms({
    message: 'Uninstall from which tools?',
    options: toolOptions,
    initialValues: ['claude'],
    required: true,
  });

  if (ic(selectedToolIds)) {
    ot('Cancelled.');
    process.exit(0);
  }

  const yes = await cf({
    message: `Remove symlinks from ${selectedToolIds.length} tool${selectedToolIds.length > 1 ? 's' : ''}?`,
    initialValue: true,
  });

  if (!yes || ic(yes)) {
    ot('Cancelled.');
    process.exit(0);
  }

  const s = await sp();
  s.start('Removing...');

  const results = [];
  for (const toolId of selectedToolIds) {
    const tool = TOOLS.find((t) => t.id === toolId);
    try {
      uninstallTool(toolId, ROOT);
      results.push({ name: tool.name, ok: true });
    } catch (err) {
      results.push({ name: tool.name, ok: false, error: err.message });
    }
  }

  s.stop('Done.');

  console.log('');
  for (const r of results) {
    const icon = r.ok ? c.green('✓') : c.red('✗');
    const detail = r.ok ? c.dim('removed') : c.red(r.error);
    console.log(`  ${icon} ${r.name} — ${detail}`);
  }
  console.log('');

  ot('Uninstall complete.');
}

// ── Main ─────────────────────────────────────────────────────────────────────
async function main() {
  const { intro, outro, select, multiselect, spinner, confirm, isCancel } = await clack();

  console.log(BANNER);
  intro(c.bold(`bigpowers v${pkg.version}`));

  // ── Step 0: Detect existing install ────────────────────────────────────
  const hasExisting = detectExistingInstall();
  let mode = 'install';

  if (hasExisting) {
    mode = await select({
      message: 'Existing installation detected. How would you like to proceed?',
      options: [
        { value: 'install', label: 'Setup / Update', hint: '(reinstall or add tools)' },
        { value: 'uninstall', label: 'Uninstall', hint: '(remove symlinks and hooks)' },
      ],
    });

    if (isCancel(mode)) {
      outro('Cancelled.');
      process.exit(0);
    }
  }

  if (mode === 'uninstall') {
    await handleUninstall();
    return;
  }

  // ── Step 1: Global vs Local ──────────────────────────────────────────────
  const installMode = await select({
    message: 'Where would you like to install?',
    options: [
      { value: 'global', label: 'Global', hint: '(~/.claude/skills/) — available in all projects' },
      { value: 'local', label: 'Local', hint: '(./.claude/skills/) — this project only' },
    ],
  });

  if (isCancel(installMode)) {
    outro('Setup cancelled.');
    process.exit(0);
  }

  // ── Step 2: Tool selection ─────────────────────────────────────────────
  const toolOptions = TOOLS.map((tool) => {
    const p = installMode === 'global' ? tool.globalPath : tool.localPath;
    const supported = SUPPORTED_IDS.has(tool.id);
    return {
      value: tool.id,
      label: supported ? tool.name : c.dim(tool.name),
      hint: supported ? `(${p})` : c.dim(`${UNSUPPORTED_HINT} ${p}`),
    };
  });

  let selectedToolIds = await multiselect({
    message: 'Install for which tools?',
    options: toolOptions,
    initialValues: ['claude'],
    required: true,
  });

  if (isCancel(selectedToolIds)) {
    outro('Setup cancelled.');
    process.exit(0);
  }

  // Filter out TODO tools — they can't be installed yet
  const selectedTools = selectedToolIds.filter((id) => SUPPORTED_IDS.has(id));
  const todoSkipped = selectedToolIds.filter((id) => !SUPPORTED_IDS.has(id));
  if (todoSkipped.length > 0) {
    const names = todoSkipped.map((id) => TOOLS.find((t) => t.id === id)?.name || id);
    console.log(`\n  ${c.dim('TODO (not yet implemented):')} ${names.join(', ')}`);
  }
  if (selectedTools.length === 0) {
    console.log(`\n  ${c.red('No supported tools selected.')}`);
    outro('Setup cancelled.');
    process.exit(0);
  }

  // ── Step 3: Confirm ───────────────────────────────────────────────────
  const skillsDir = path.join(ROOT, 'skills');
  const skillCount = fs
    .readdirSync(skillsDir)
    .filter((d) => fs.existsSync(path.join(skillsDir, d, 'SKILL.md'))).length;

  const yes = await confirm({
    message: `Install ${skillCount} skills to ${selectedTools.length} runtime${selectedTools.length > 1 ? 's' : ''}?`,
    initialValue: true,
  });

  if (!yes || isCancel(yes)) {
    outro('Setup cancelled.');
    process.exit(0);
  }

  // ── Step 4: Clean old symlinks ─────────────────────────────────────────
  const s = await spinner();
  s.start('Preparing installation...');
  await sleep(200);

  // Uninstall existing symlinks for selected tools before reinstalling
  if (hasExisting) {
    s.message('Cleaning old symlinks...');
    for (const toolId of selectedTools) {
      try {
        uninstallTool(toolId, ROOT);
      } catch {
        // Ignore errors during cleanup — tool might not be installed yet
      }
    }
    await sleep(100);
  }

  s.message('Syncing skills...');
  try {
    runInherited('bash scripts/sync-skills.sh');
  } catch {
    s.error('Sync failed.');
    process.exit(1);
  }

  const results = [];
  for (const toolId of selectedTools) {
    const tool = TOOLS.find((t) => t.id === toolId);
    const p = installMode === 'global' ? tool.globalPath : tool.localPath;

    s.message(`Installing ${tool.name}...`);
    await sleep(300);

    try {
      if (installMode === 'global') {
        installGlobal(tool, ROOT);
      } else {
        installLocal(tool, ROOT);
      }
      results.push({ name: tool.name, path: p, ok: true });
    } catch (err) {
      results.push({ name: tool.name, path: p, ok: false, error: err.message });
    }
  }

  s.stop('Installation complete.');

  // ── Step 5: Results ────────────────────────────────────────────────────
  console.log('');
  for (const r of results) {
    const icon = r.ok ? c.green('✓') : c.red('✗');
    const detail = r.ok ? c.dim(r.path) : c.red(r.error);
    console.log(`  ${icon} ${r.name} — ${detail}`);
  }
  if (selectedTools.includes('cursor') && results.some((r) => r.name === 'Cursor' && r.ok)) {
    console.log(
      `  ${c.dim('NOTE: Cursor does not scan ~/.cursor/rules globally — also symlink into each project:')}`
    );
    console.log(`  ${c.dim('  ln -sfn ' + path.join(ROOT, '.cursor', 'rules') + ' .cursor/rules')}`);
  }
  console.log('');

  const allOk = results.every((r) => r.ok);
  if (allOk) {
    outro(`bigpowers installed. ${c.dim('Run bigpowers update anytime.')}`);
  } else {
    outro('Some installations failed. Check errors above.');
    process.exit(1);
  }
}

// ── Run ──────────────────────────────────────────────────────────────────────
main().catch((err) => {
  console.error(`${c.red('Error:')} ${err.message}`);
  process.exit(1);
});
