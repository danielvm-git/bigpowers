#!/usr/bin/env node
// story: e60s01
// Regression selftest for scripts/lib/install-helpers.js (Wave 0 closeout).
'use strict';

const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { mkdtempSync, rmSync } = fs;

const ROOT = path.resolve(__dirname, '..');
const tmpHome = mkdtempSync(path.join(os.tmpdir(), 'bp-install-helpers-'));
process.env.HOME = tmpHome;

const { installGlobal, linkHook } = require('../scripts/lib/install-helpers.js');

try {
  const hookSrc = path.join(ROOT, 'skills', 'guard-git', 'scripts', 'block-dangerous-git.sh');
  assert.ok(fs.existsSync(hookSrc), `Claude guard-git hook source must exist: ${hookSrc}`);

  const rtkSrc = path.join(ROOT, 'scripts', 'hooks', 'rtk-rewrite.sh');
  assert.ok(fs.existsSync(rtkSrc), `rtk-rewrite hook source must exist: ${rtkSrc}`);

  assert.throws(
    () => linkHook(path.join(tmpHome, 'missing-hook.sh'), path.join(tmpHome, 'dst-hook.sh')),
    /Hook source missing/
  );

  const { linkDir, uninstallTool } = require('../scripts/lib/install-helpers.js');
  assert.throws(
    () => linkDir(path.join(tmpHome, 'missing-dir'), path.join(tmpHome, 'dst-dir')),
    /Link source missing/
  );

  const setupSrc = fs.readFileSync(path.join(ROOT, 'bin/setup.js'), 'utf8');
  assert.ok(/id:\s*'pi'/.test(setupSrc), 'bin/setup.js TOOLS must include pi');
  assert.ok(!/const ALL_ID/.test(setupSrc), 'dead ALL_ID constant must be removed');

  installGlobal({ id: 'claude', name: 'Claude Code' }, ROOT);

  const linked = path.join(tmpHome, '.claude', 'hooks', 'block-dangerous-git.sh');
  assert.ok(fs.lstatSync(linked).isSymbolicLink(), 'block-dangerous-git.sh must be symlinked');
  assert.strictEqual(fs.readlinkSync(linked), hookSrc, 'symlink must point at skills/guard-git path');

  const libLinked = path.join(tmpHome, '.claude', 'hooks', 'lib');
  const libSrc = path.join(ROOT, 'skills', 'guard-git', 'scripts', 'lib');
  assert.ok(fs.lstatSync(libLinked).isSymbolicLink(), 'guard-git lib/ must be symlinked for hook runtime');
  assert.strictEqual(fs.readlinkSync(libLinked), libSrc, 'lib symlink must point at skills/guard-git/scripts/lib');
  assert.ok(
    fs.existsSync(path.join(libSrc, 'git-guardrails-core.sh')),
    'git-guardrails-core.sh must exist under linked lib'
  );

  const rtkLinked = path.join(tmpHome, '.claude', 'hooks', 'rtk-rewrite.sh');
  assert.ok(fs.lstatSync(rtkLinked).isSymbolicLink(), 'rtk-rewrite.sh must be symlinked');
  assert.strictEqual(fs.readlinkSync(rtkLinked), rtkSrc, 'rtk-rewrite symlink must point at scripts/hooks source');

  installGlobal({ id: 'pi', name: 'pi' }, ROOT);
  const piSkill = path.join(tmpHome, '.pi', 'agent', 'skills');
  assert.ok(fs.existsSync(piSkill), 'pi skills dir must exist after installGlobal');
  const sample = fs.readdirSync(piSkill).find((n) => {
    try {
      return fs.lstatSync(path.join(piSkill, n)).isSymbolicLink();
    } catch {
      return false;
    }
  });
  assert.ok(sample, 'pi install must create at least one skill symlink');
  assert.ok(
    fs.readlinkSync(path.join(piSkill, sample)).includes(path.join('skills', sample)),
    'pi skill symlink must point into repo skills/'
  );

  uninstallTool('pi', ROOT);
  assert.ok(
    !fs.existsSync(path.join(piSkill, sample)),
    'uninstallTool(pi) must remove repo-rooted skill symlinks'
  );

  const rulesSrc = path.join(ROOT, '.cursor', 'rules');
  assert.ok(fs.existsSync(rulesSrc), '.cursor/rules must exist (run sync-skills)');
  installGlobal({ id: 'cursor', name: 'Cursor' }, ROOT);
  const rulesDst = path.join(tmpHome, '.cursor', 'rules');
  assert.ok(fs.lstatSync(rulesDst).isSymbolicLink(), 'cursor rules must be symlinked');
  assert.strictEqual(fs.readlinkSync(rulesDst), rulesSrc, 'cursor rules symlink must point at repo .cursor/rules');
  uninstallTool('cursor', ROOT);
  assert.ok(!fs.existsSync(rulesDst), 'uninstallTool(cursor) must remove rules symlink');

  const installPaths = [
    path.join(ROOT, 'scripts', 'install.sh'),
    ...fs.readdirSync(path.join(ROOT, 'scripts', 'lib'))
      .filter((n) => n.startsWith('install-targets-') && n.endsWith('.sh'))
      .map((n) => path.join(ROOT, 'scripts', 'lib', n)),
  ];
  const installSh = installPaths.map((p) => fs.readFileSync(p, 'utf8')).join('\n');
  assert.ok(
    installSh.includes('skills/guard-git/scripts/block-dangerous-git.sh'),
    'install surface must use skills/guard-git hook path'
  );
  assert.ok(
    !/REPO_ROOT\/guard-git\//.test(installSh),
    'install surface must not reference bare guard-git/ path'
  );

  console.log('test-install-helpers: ALL PASS');
} finally {
  rmSync(tmpHome, { recursive: true, force: true });
}
