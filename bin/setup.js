#!/usr/bin/env node
// story: e60s01
// story: e74s02
// story: e71s02
// story: e62s02
// story: e73s02
// story: e70s02
// story: e67s02
// story: e66s02
// story: e72s02
// story: e68s02
// bigpowers setup — interactive installer
// Combines GSD simplicity with BMAD visual polish.

const { execSync, spawn } = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { installGlobal, installLocal, uninstallTool, detectExistingInstall } = require('../scripts/lib/install-helpers');
const { readPackageVersion } = require('../scripts/lib/cli-version');
const { parseArgs, printSetupHelp } = require('../scripts/lib/cli-args');
const {
  anyInstallState, clearInstallState, detectInstalledTools, resolvePlan, writeInstallState,
} = require('../scripts/lib/install-state');
const { consoleUi, spinnerUi, skillCount, syncAndInstall, reportResults } = require('../scripts/lib/install-run');
const { runUninstallInteractive } = require('../scripts/lib/install-uninstall');

const ROOT = path.resolve(path.dirname(__filename), '..');

// ── ANSI helpers ─────────────────────────────────────────────────────────────
const c = {
  cyan: (s) => `\x1b[36m${s}\x1b[0m`,
  green: (s) => `\x1b[32m${s}\x1b[0m`,
  red: (s) => `\x1b[31m${s}\x1b[0m`,
  dim: (s) => `\x1b[2m${s}\x1b[0m`,
  bold: (s) => `\x1b[1m${s}\x1b[0m`,
};

// ── ASCII banner ─────────────────────────────────────────────────────────────
// Version is passed in, read fresh from disk: `bigpowers update` reinstalls this
// package mid-process, so a require() cache from startup would print the version
// that was replaced (BUG-2026-11-03-cli-update-stale-version).
function banner(version) {
  return `
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
${c.cyan('║')}           ${c.dim(`v${version}`)}                                                          ${c.cyan('║')}
${c.cyan('╚════════════════════════════════════════════════════════════════════════════╝')}
`;
}

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
const SUPPORTED_IDS = new Set(['claude', 'gemini', 'pi', 'hermes', 'mimo', 'zcode', 'cursor', 'codex', 'antigravity', 'agy', 'qwen', 'codebuddy', 'cline', 'kilo', 'trae', 'windsurf', 'opencode', 'copilot']);
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

// Async counterpart of runInherited: keeps the event loop free so a clack
// spinner's setInterval can keep animating while the child process runs.
// Output is captured (not inherited) so it can't collide with the spinner's
// own redraw; on failure the caller gets it back to show the user.
function runInheritedAsync(cmd) {
  return new Promise((resolve, reject) => {
    const child = spawn(cmd, { cwd: ROOT, shell: true });
    let output = '';
    child.stdout.on('data', (d) => (output += d));
    child.stderr.on('data', (d) => (output += d));
    child.on('close', (code) => {
      if (code === 0) resolve(output);
      else reject(new Error(output || `${cmd} exited with code ${code}`));
    });
  });
}



// The catalogue with its support flag resolved once, so the state helpers do not
// need to know about SUPPORTED_IDS.
const TARGETS = TOOLS.map((tool) => ({ ...tool, supported: SUPPORTED_IDS.has(tool.id) }));

// ── Non-interactive path ────────────────────────────────────────────────────
// Uninstall without a menu: remove the links for the resolved tools, then forget
// the recorded run so a later `update` does not reinstall what was just removed.
function runUninstallBatch(tools) {
  console.log(`  Removing bigpowers from ${tools.length} runtime(s): ${tools.join(', ')}`);
  let failed = false;
  for (const toolId of tools) {
    const tool = TOOLS.find((t) => t.id === toolId);
    try {
      uninstallTool(toolId, ROOT);
      console.log(`  ${c.green('✓')} ${tool.name} — ${c.dim('removed')}`);
    } catch (err) {
      failed = true;
      console.log(`  ${c.red('✗')} ${tool.name} — ${c.red(err.message)}`);
    }
  }
  clearInstallState(tools);
  console.log(failed ? 'Some removals failed. Check errors above.' : 'Uninstall complete.');
  if (failed) process.exit(1);
}

async function runNonInteractive(opts, version) {
  const plan = resolvePlan(opts, TARGETS);
  const consented = opts.yes || process.env.BIGPOWERS_NONINTERACTIVE === '1';

  if (!consented || plan.tools.length === 0) {
    console.error(`${c.red('bigpowers: no TTY — refusing to prompt.')}`);
    console.error('');
    console.error(`  Run: bigpowers setup --yes --tools=${plan.tools.join(',') || 'claude'}`);
    console.error('  Or run the installer in a terminal for the interactive menu.');
    process.exit(2);
  }

  if (opts.uninstall) {
    runUninstallBatch(plan.tools);
    return;
  }

  console.log(
    `  bigpowers v${version} — installing ${plan.tools.length} runtime(s) (${plan.scope}): ${plan.tools.join(', ')}`
  );
  const results = await syncAndInstall(plan, {
    root: ROOT,
    catalogue: TOOLS,
    installGlobal,
    installLocal,
    uninstallTool,
    runInheritedAsync,
    ui: consoleUi(),
    hadExisting: detectExistingInstall(),
  });
  reportResults(results, { tools: plan.tools, root: ROOT, c });

  const allOk = results.every((r) => r.ok);
  if (allOk) writeInstallState(plan.scope, plan.tools, { version });
  console.log(
    allOk
      ? `bigpowers installed. ${c.dim('Run bigpowers update anytime.')}`
      : 'Some installations failed. Check errors above.'
  );
  if (!allOk) process.exit(1);
}

// ── Interactive path ────────────────────────────────────────────────────────
async function runInteractive(opts, version) {
  const { intro, outro, select, multiselect, spinner, confirm, isCancel } = await clack();
  intro(c.bold(`bigpowers v${version}`));

  const hasExisting = detectExistingInstall();
  const saved = anyInstallState();
  let mode = opts.uninstall ? 'uninstall' : 'install';

  if (hasExisting && !opts.uninstall) {
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
    await runUninstallInteractive({ clack, catalogue: TOOLS, supportedIds: SUPPORTED_IDS, uninstallTool, root: ROOT, c });
    return;
  }

  const installMode = await select({
    message: 'Where would you like to install?',
    options: [
      { value: 'global', label: 'Global', hint: '(~/.claude/skills/) — available in all projects' },
      { value: 'local', label: 'Local', hint: '(./.claude/skills/) — this project only' },
    ],
    initialValue: (saved && saved.scope) || 'global',
  });
  if (isCancel(installMode)) {
    outro('Setup cancelled.');
    process.exit(0);
  }

  const preselected = (saved && saved.scope === installMode ? saved.tools : null) || detectInstalledTools(TARGETS);
  const toolOptions = TOOLS.map((tool) => {
    const p = installMode === 'global' ? tool.globalPath : tool.localPath;
    const supported = SUPPORTED_IDS.has(tool.id);
    return {
      value: tool.id,
      label: supported ? tool.name : c.dim(tool.name),
      hint: supported ? `(${p})` : c.dim(`${UNSUPPORTED_HINT} ${p}`),
    };
  });

  const selectedToolIds = await multiselect({
    message: 'Install for which tools?',
    options: toolOptions,
    initialValues: preselected.length > 0 ? preselected : ['claude'],
    required: true,
  });
  if (isCancel(selectedToolIds)) {
    outro('Setup cancelled.');
    process.exit(0);
  }

  const tools = selectedToolIds.filter((id) => SUPPORTED_IDS.has(id));
  const todoSkipped = selectedToolIds.filter((id) => !SUPPORTED_IDS.has(id));
  if (todoSkipped.length > 0) {
    const names = todoSkipped.map((id) => TOOLS.find((t) => t.id === id)?.name || id);
    console.log(`\n  ${c.dim('TODO (not yet implemented):')} ${names.join(', ')}`);
  }
  if (tools.length === 0) {
    console.log(`\n  ${c.red('No supported tools selected.')}`);
    outro('Setup cancelled.');
    process.exit(0);
  }

  const count = skillCount(ROOT);
  const yes = await confirm({
    message: `Install ${count} skills to ${tools.length} runtime${tools.length > 1 ? 's' : ''}?`,
    initialValue: true,
  });
  if (!yes || isCancel(yes)) {
    outro('Setup cancelled.');
    process.exit(0);
  }

  const results = await syncAndInstall({ scope: installMode, tools }, {
    root: ROOT,
    catalogue: TOOLS,
    installGlobal,
    installLocal,
    uninstallTool,
    runInheritedAsync,
    ui: spinnerUi(spinner),
    hadExisting: hasExisting,
  });
  reportResults(results, { tools, root: ROOT, c });

  const allOk = results.every((r) => r.ok);
  if (!allOk) {
    outro('Some installations failed. Check errors above.');
    process.exit(1);
  }
  writeInstallState(installMode, tools, { version });
  outro(`bigpowers installed. ${c.dim('Run bigpowers update anytime.')}`);
}

// ── Main ─────────────────────────────────────────────────────────────────────
async function main() {
  const opts = parseArgs(process.argv.slice(2));
  if (opts.help) {
    printSetupHelp();
    return;
  }

  const version = readPackageVersion(ROOT); // fresh: `update` may have replaced it
  console.log(banner(version));

  const interactive = Boolean(process.stdin.isTTY) && !opts.yes && process.env.BIGPOWERS_NONINTERACTIVE !== '1';
  if (interactive) await runInteractive(opts, version);
  else await runNonInteractive(opts, version);
}

// ── Run ──────────────────────────────────────────────────────────────────────
main().catch((err) => {
  console.error(`${c.red('Error:')} ${err.message}`);
  process.exit(1);
});
