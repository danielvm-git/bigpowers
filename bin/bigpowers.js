#!/usr/bin/env node
// story: e38s08
// story: e83s02
// bigpowers CLI — detects install state, runs setup on demand.
// No npm lifecycle scripts needed → bypasses npm v10+ allow-scripts gate.

const { execSync } = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');

const ROOT = path.dirname(path.dirname(__filename));
const SKILLS_MARKER = path.join(os.homedir(), '.claude', 'skills', 'survey-context');
// Version strings come from disk, not from a require cache captured at startup:
// `update` reinstalls this package mid-process (BUG-2026-11-03-cli-update-stale-version).
const { readPackageVersion } = require(path.join(ROOT, 'scripts', 'lib', 'cli-version'));

// A link is bigpowers-owned when it resolves into a `bigpowers/skills` dir (this
// package, or any bigpowers install). Anything else is foreign (e83s02).
function countSkillLinks(dir) {
  let owned = 0;
  let foreign = 0;
  for (const d of fs.readdirSync(dir)) {
    const full = path.join(dir, d);
    if (!fs.lstatSync(full).isSymbolicLink()) continue;
    let real;
    try { real = fs.realpathSync(full); } catch { foreign++; continue; }
    const parent = path.dirname(real);
    const mine = parent === path.join(ROOT, 'skills') ||
      (path.basename(parent) === 'skills' && path.basename(path.dirname(parent)) === 'bigpowers');
    if (mine) owned++; else foreign++;
  }
  return { owned, foreign };
}

function isInstalled() {
  try {
    return fs.lstatSync(SKILLS_MARKER).isSymbolicLink();
  } catch {
    return false;
  }
}

function run(cmd, cwd = ROOT) {
  try {
    execSync(cmd, { cwd, stdio: 'inherit' });
  } catch (e) {
    console.error(`\n❌ Failed: ${cmd}`);
    process.exit(1);
  }
}

// True when this copy runs from the global npm install (not a git clone or npx temp dir).
function isGlobalInstall() {
  try {
    const globalRoot = execSync('npm root -g', { encoding: 'utf8' }).trim();
    return globalRoot && ROOT.startsWith(globalRoot);
  } catch {
    return false;
  }
}

// `bigpowers update` used to only re-sync the already-installed files, so it never fetched
// a newer release. When we're the global install, pull the latest from npm first; the reinstall
// overwrites ROOT in place, so the setup.js required afterwards is the freshly installed one.
function selfUpdateGlobalPackage() {
  if (!isGlobalInstall()) {
    console.log('bigpowers: not a global npm install — skipping package self-update.');
    console.log('  git clone → `git pull && npm run sync && bash scripts/install.sh`');
    console.log('  one-shot  → `npx bigpowers@latest setup`');
    return;
  }
  console.log('bigpowers: fetching the latest release from npm (npm install -g bigpowers@latest)...');
  try {
    execSync('npm install -g bigpowers@latest', { stdio: 'inherit' });
  } catch {
    console.error('bigpowers: `npm install -g bigpowers@latest` failed — re-syncing the installed version instead.');
  }
}

// Best-effort registry check; silent on any failure so offline/slow networks never block a command.
function latestPublishedVersion() {
  try {
    return execSync('npm view bigpowers version', { encoding: 'utf8', timeout: 4000 }).trim();
  } catch {
    return null;
  }
}

const cmd = process.argv[2];

if (cmd === 'setup' || cmd === 'install') {
  // Delegate to interactive installer
  const setupScript = path.join(ROOT, 'bin', 'setup.js');
  require(setupScript);
  return;
}

if (cmd === 'init') {
  // Provision the CURRENT project (cwd): scripts/ link + specs/ scaffolding (#116)
  const initScript = path.join(ROOT, 'bin', 'init.js');
  require(initScript);
  return;
}

if (cmd === 'update') {
  // Pull the newest release first (global installs), then re-sync + refresh symlinks.
  selfUpdateGlobalPackage();
  const setupScript = path.join(ROOT, 'bin', 'setup.js');
  require(setupScript);
  return;
}

if (cmd === 'status') {
  if (isInstalled()) {
    const skillsDir = path.join(os.homedir(), '.claude', 'skills');
    const { owned: count, foreign } = countSkillLinks(skillsDir);
    const version = readPackageVersion(ROOT);
    console.log(`bigpowers v${version} — ${count} skills installed`);
    if (foreign > 0) console.log(`${foreign} foreign skill links (not owned by bigpowers)`);
    const latest = latestPublishedVersion();
    if (latest && latest !== version) {
      console.log(`\n⬆️  A newer release is available: v${latest} (you have v${version}).`);
      console.log('   Upgrade: npm install -g bigpowers@latest && bigpowers update');
    }
  } else {
    console.log('bigpowers not installed. Run: bigpowers setup');
  }
  process.exit(0);
}

if (cmd === '--help' || cmd === '-h' || cmd === 'help') {
  console.log(`
bigpowers — agent skills for spec-driven, test-first development

Commands:
  bigpowers setup    Install skills into ~/.claude/skills/
  bigpowers init     Provision the CURRENT project: scripts/ link + specs/ scaffolding (run per project)
  bigpowers update   Fetch the latest release (global installs) + re-sync and refresh symlinks
  bigpowers status   Show installed version and skill count (warns if a newer release exists)
  bigpowers help     This message
`);
  process.exit(0);
}

// Default: check state and guide
if (isInstalled()) {
  console.log(`bigpowers v${readPackageVersion(ROOT)} — already installed.`);
  console.log('Commands: bigpowers {setup|update|status|help}');
} else {
  console.log(`🚀 bigpowers v${readPackageVersion(ROOT)} — skills not yet installed.`);
  console.log('   Run: bigpowers setup');
  process.exit(1);
}
