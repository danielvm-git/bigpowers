#!/usr/bin/env node
// story: e38s08
// bigpowers CLI — detects install state, runs setup on demand.
// No npm lifecycle scripts needed → bypasses npm v10+ allow-scripts gate.

const { execSync } = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');

const ROOT = path.dirname(path.dirname(__filename));
const SKILLS_MARKER = path.join(os.homedir(), '.claude', 'skills', 'survey-context');
const pkg = require(path.join(ROOT, 'package.json'));
const { readPackageVersion } = require(path.join(ROOT, 'scripts', 'lib', 'cli-version'));

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
  if (process.env.BIGPOWERS_SKIP_SELF_UPDATE === '1') {
    console.log('bigpowers: BIGPOWERS_SKIP_SELF_UPDATE=1 — re-syncing the installed version instead.');
    return;
  }
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
  // `update` has no choices to make, so it never prompts: it replays the recorded
  // install (scripts/lib/install-state.js) and installs without a menu. Prompting
  // here meant, with no TTY, drawing a menu nobody could answer and exiting 0
  // without installing anything (BUG-2026-11-03-cli-nontty-silent-noop).
  selfUpdateGlobalPackage();
  if (!isInstalled() && !fs.existsSync(path.join(os.homedir(), '.bigpowers', 'install-state.json'))) {
    console.error('bigpowers: nothing installed yet. Run: bigpowers setup');
    process.exit(1);
  }
  process.env.BIGPOWERS_NONINTERACTIVE = '1';
  const setupScript = path.join(ROOT, 'bin', 'setup.js');
  require(setupScript);
  return;
}

if (cmd === 'status') {
  if (isInstalled()) {
    const count = fs.readdirSync(path.join(os.homedir(), '.claude', 'skills'))
      .filter(d => fs.lstatSync(path.join(os.homedir(), '.claude', 'skills', d)).isSymbolicLink())
      .length;
    const version = readPackageVersion(ROOT);
    console.log(`bigpowers v${version} — ${count} skills installed`);
    const latest = latestPublishedVersion();
    if (latest && latest !== version) {
      console.log(`\n⬆️  A newer release is available: v${latest} (you have v${version}).`);
      console.log('   Upgrade: bigpowers update');
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
  bigpowers setup    Install skills into ~/.claude/skills/ (interactive; see --yes below)
  bigpowers init     Provision the CURRENT project: scripts/ link + specs/ scaffolding (run per project)
  bigpowers update   Fetch the latest release (global installs) + re-sync and refresh symlinks
  bigpowers status   Show installed version and skill count (warns if a newer release exists)
  bigpowers help     This message

Non-interactive (no TTY: agents, CI, a pipe on stdin):
  bigpowers setup --yes --tools=claude,pi --scope=global
  bigpowers setup --help        Full flag list

Without a TTY the installer never prompts: it uses --yes, or exits 2 with the
command to run. bigpowers update never prompts at all.
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
