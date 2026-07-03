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

const cmd = process.argv[2];

if (cmd === 'setup' || cmd === 'install') {
  // Explicit setup — always run
  console.log('🚀 bigpowers — setting up...\n');
  run('bash scripts/sync-skills.sh');
  run('bash scripts/install.sh');
  console.log('\n✅ bigpowers setup complete!');
  console.log('   Skills installed in ~/.claude/skills/');
  console.log('   Run again anytime to update: bigpowers setup\n');
  process.exit(0);
}

if (cmd === 'update') {
  console.log('🔄 Updating bigpowers...\n');
  run('bash scripts/sync-skills.sh');
  run('bash scripts/install.sh');
  console.log('\n✅ bigpowers updated!\n');
  process.exit(0);
}

if (cmd === 'status') {
  if (isInstalled()) {
    const pkg = require(path.join(ROOT, 'package.json'));
    const count = fs.readdirSync(path.join(os.homedir(), '.claude', 'skills'))
      .filter(d => fs.lstatSync(path.join(os.homedir(), '.claude', 'skills', d)).isSymbolicLink())
      .length;
    console.log(`bigpowers v${pkg.version} — ${count} skills installed`);
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
  bigpowers update   Re-run sync and install (after npm update -g bigpowers)
  bigpowers status   Show installed version and skill count
  bigpowers help     This message
`);
  process.exit(0);
}

// Default: check state and guide
if (isInstalled()) {
  const pkg = require(path.join(ROOT, 'package.json'));
  console.log(`bigpowers v${pkg.version} — already installed.`);
  console.log('Commands: bigpowers {setup|update|status|help}');
} else {
  console.log('🚀 bigpowers — skills not yet installed.');
  console.log('   Run: bigpowers setup');
  process.exit(1);
}
