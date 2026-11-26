// story: BUG-2026-11-03-cli-nontty-silent-noop
// install-state.js — remember what was installed, so `bigpowers update` can
// replay it without asking a question it cannot ask.
//
// `update` has no choices to make, but nothing recorded *what* was installed:
// detectExistingInstall() only knows the claude marker, so the installer fell
// back to a menu — which, with no TTY, was a silent no-op.

'use strict';

const fs = require('fs');
const os = require('os');
const path = require('path');

function statePath(scope, cwd = process.cwd()) {
  return scope === 'local'
    ? path.join(cwd, '.bigpowers', 'install-state.json')
    : path.join(os.homedir(), '.bigpowers', 'install-state.json');
}

function readInstallState(scope, cwd) {
  try {
    const state = JSON.parse(fs.readFileSync(statePath(scope, cwd), 'utf8'));
    return Array.isArray(state.tools) ? state : null;
  } catch {
    return null;
  }
}

/** Persist the run. A read-only HOME must not fail an otherwise good install. */
function writeInstallState(scope, tools, { version = 'unknown', cwd } = {}) {
  const file = statePath(scope, cwd);
  try {
    fs.mkdirSync(path.dirname(file), { recursive: true });
    const state = { version, scope, tools, installed_at: new Date().toISOString() };
    fs.writeFileSync(file, `${JSON.stringify(state, null, 2)}\n`);
    return true;
  } catch {
    return false;
  }
}

/** Whichever scope was installed last — what `update` should replay. */
function anyInstallState(cwd) {
  for (const scope of ['global', 'local']) {
    const state = readInstallState(scope, cwd);
    if (state) return { scope, tools: state.tools };
  }
  return null;
}

/** Forget `tools` from the recorded run; delete the file when nothing is left. */
function clearInstallState(tools, cwd) {
  const saved = anyInstallState(cwd);
  if (!saved) return true;
  const remaining = saved.tools.filter((id) => !tools.includes(id));
  try {
    if (remaining.length === 0) fs.rmSync(statePath(saved.scope, cwd), { force: true });
    else writeInstallState(saved.scope, remaining, { cwd });
    return true;
  } catch {
    return false;
  }
}

function expandHome(p, home = os.homedir()) {
  return p.startsWith('~') ? path.join(home, p.slice(1)) : p;
}

/**
 * Tools whose skills dir already holds our `survey-context` marker link.
 * `targets` is [{id, globalPath}] — the caller owns the catalogue.
 */
function detectInstalledTools(targets, home = os.homedir()) {
  const found = [];
  for (const tool of targets) {
    if (tool.supported === false) continue;
    const base = expandHome(tool.globalPath, home);
    if (fs.existsSync(path.join(base, 'survey-context')) ||
        fs.existsSync(path.join(base, 'skills', 'survey-context'))) {
      found.push(tool.id);
    }
  }
  return found;
}

/**
 * Resolve {scope, tools}: explicit flags → the last recorded run → what is on
 * disk. Ids the catalogue does not support are dropped, not guessed at.
 */
function resolvePlan(opts, targets, cwd) {
  const supported = new Set(targets.filter((t) => t.supported !== false).map((t) => t.id));
  const saved = anyInstallState(cwd);
  const scope = opts.scope || (saved && saved.scope) || 'global';
  const candidates = opts.tools
    || (saved && saved.scope === scope ? saved.tools : null)
    || detectInstalledTools(targets);
  return { scope, tools: candidates.filter((id) => supported.has(id)) };
}

module.exports = {
  statePath,
  readInstallState,
  writeInstallState,
  clearInstallState,
  anyInstallState,
  expandHome,
  detectInstalledTools,
  resolvePlan,
};
