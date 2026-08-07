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

  // Regression: every tool the uninstall menu offers must have a real uninstall
  // path. Before this, qwen/codebuddy/cline/kilo/trae/windsurf/opencode/copilot
  // had install cases but no uninstall case — uninstall reported success while
  // leaving every symlink in place.
  installGlobal({ id: 'qwen', name: 'Qwen Code' }, ROOT);
  const qwenSkills = path.join(tmpHome, '.qwen', 'skills');
  const qwenSample = fs.existsSync(qwenSkills)
    && fs.readdirSync(qwenSkills).find((n) => {
      try { return fs.lstatSync(path.join(qwenSkills, n)).isSymbolicLink(); } catch { return false; }
    });
  assert.ok(qwenSample, 'qwen install must create at least one skill symlink');
  uninstallTool('qwen', ROOT);
  assert.ok(
    !fs.existsSync(path.join(qwenSkills, qwenSample)),
    'uninstallTool(qwen) must remove repo-rooted skill symlinks'
  );

  // copilot writes AGENTS.md as a plain copy (not a symlink); uninstall must
  // still remove it via removeManagedFile.
  installGlobal({ id: 'copilot', name: 'Copilot' }, ROOT);
  const copilotAgents = path.join(tmpHome, '.copilot', 'AGENTS.md');
  const copilotHadAgents = fs.existsSync(copilotAgents);
  uninstallTool('copilot', ROOT);
  if (copilotHadAgents) {
    assert.ok(!fs.existsSync(copilotAgents), 'uninstallTool(copilot) must remove copied AGENTS.md');
  }
  const copilotSkills = path.join(tmpHome, '.copilot', 'skills');
  if (fs.existsSync(copilotSkills)) {
    const leftover = fs.readdirSync(copilotSkills).find((n) => {
      try { return fs.lstatSync(path.join(copilotSkills, n)).isSymbolicLink(); } catch { return false; }
    });
    assert.ok(!leftover, 'uninstallTool(copilot) must remove skill symlinks');
  }

  // Regression: uninstallTool() only ever touched homeDir. The interactive
  // Uninstall menu (bin/setup.js handleUninstall) never asks global-vs-local
  // and calls uninstallTool(toolId, ROOT) unconditionally — so a *local*
  // install (`bigpowers install` → Local) was reported "removed" while every
  // local symlink survived, for every tool. Verify local install/uninstall
  // round-trips for tools spanning each install shape: skill-symlink dir
  // (pi, claude), single linked dir (cursor, gemini), and a linked file
  // (codex AGENTS.md).
  const { installLocal } = require('../scripts/lib/install-helpers.js');
  const savedCwd = process.cwd();
  const tmpCwd = mkdtempSync(path.join(os.tmpdir(), 'bp-install-helpers-local-'));
  try {
    process.chdir(tmpCwd);

    installLocal({ id: 'pi', name: 'pi' }, ROOT);
    const localPiSkills = path.join(tmpCwd, '.pi', 'agent', 'skills');
    const localPiSample = fs.readdirSync(localPiSkills).find((n) => {
      try { return fs.lstatSync(path.join(localPiSkills, n)).isSymbolicLink(); } catch { return false; }
    });
    assert.ok(localPiSample, 'local pi install must create at least one skill symlink');
    uninstallTool('pi', ROOT);
    assert.ok(
      !fs.existsSync(path.join(localPiSkills, localPiSample)),
      'uninstallTool(pi) must also remove LOCAL (cwd) skill symlinks, not just global'
    );

    installLocal({ id: 'claude', name: 'Claude Code' }, ROOT);
    const localClaudeSkills = path.join(tmpCwd, '.claude', 'skills');
    const localClaudeSample = fs.readdirSync(localClaudeSkills).find((n) => {
      try { return fs.lstatSync(path.join(localClaudeSkills, n)).isSymbolicLink(); } catch { return false; }
    });
    assert.ok(localClaudeSample, 'local claude install must create at least one skill symlink');
    uninstallTool('claude', ROOT);
    assert.ok(
      !fs.existsSync(path.join(localClaudeSkills, localClaudeSample)),
      'uninstallTool(claude) must also remove LOCAL (cwd) skill symlinks, not just global'
    );

    installLocal({ id: 'cursor', name: 'Cursor' }, ROOT);
    const localCursorRules = path.join(tmpCwd, '.cursor', 'rules');
    assert.ok(fs.lstatSync(localCursorRules).isSymbolicLink(), 'local cursor install must symlink .cursor/rules');
    uninstallTool('cursor', ROOT);
    assert.ok(!fs.existsSync(localCursorRules), 'uninstallTool(cursor) must remove LOCAL .cursor/rules symlink');

    installLocal({ id: 'gemini', name: 'Gemini' }, ROOT);
    const localGeminiExt = path.join(tmpCwd, '.gemini', 'extensions', 'bigpowers');
    assert.ok(fs.lstatSync(localGeminiExt).isSymbolicLink(), 'local gemini install must symlink extensions/bigpowers');
    uninstallTool('gemini', ROOT);
    assert.ok(!fs.existsSync(localGeminiExt), 'uninstallTool(gemini) must remove LOCAL extensions/bigpowers symlink');

    installLocal({ id: 'codex', name: 'Codex' }, ROOT);
    const localCodexAgents = path.join(tmpCwd, '.codex', 'AGENTS.md');
    assert.ok(fs.lstatSync(localCodexAgents).isSymbolicLink(), 'local codex install must symlink AGENTS.md');
    uninstallTool('codex', ROOT);
    assert.ok(!fs.existsSync(localCodexAgents), 'uninstallTool(codex) must remove LOCAL AGENTS.md symlink');
  } finally {
    process.chdir(savedCwd);
    rmSync(tmpCwd, { recursive: true, force: true });
  }

  // Guard against future drift: assert the menu's supported set matches the
  // uninstall switch. Any id in SUPPORTED_IDS with no uninstall case regresses
  // this bug (silent no-op reported as success).
  const helpersSrc = fs.readFileSync(path.join(ROOT, 'scripts', 'lib', 'install-helpers.js'), 'utf8');
  const uninstallBody = helpersSrc.slice(helpersSrc.indexOf('function uninstallTool'));
  const setupText = fs.readFileSync(path.join(ROOT, 'bin/setup.js'), 'utf8');
  const supportedLine = setupText.match(/const SUPPORTED_IDS = new Set\(\[([^\]]*)\]\)/);
  assert.ok(supportedLine, 'SUPPORTED_IDS must be declarable from bin/setup.js');
  const supportedIds = supportedLine[1].match(/'([^']+)'/g).map((s) => s.replace(/'/g, ''));
  for (const id of supportedIds) {
    assert.ok(
      new RegExp(`case '${id}':`).test(uninstallBody),
      `uninstallTool must handle '${id}' (listed in SUPPORTED_IDS) — else uninstall silently no-ops`
    );
  }

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

  // story: BUG-2026-08-07-gemini-hooks-missing-npm-package
  // The npm tarball must ship every path the installer hard-links from the
  // package root. .npmignore edits that strip installer-referenced paths are
  // regressions (Gemini hooks "Hook source missing" on global npm installs).
  {
    const npmignore = fs
      .readFileSync(path.join(ROOT, '.npmignore'), 'utf8')
      .split(/\r?\n/)
      .map((l) => l.trim())
      .filter(Boolean);
    const critical = [
      '.gemini/extensions/bigpowers/hooks/session-start',
      '.gemini/extensions/bigpowers/hooks/run-hook.cmd',
      '.gemini/extensions/bigpowers/hooks/before-tool-git-guard.sh',
      '.cursor/rules',
      '.pi/skills',
      'skills/audit-code/SKILL.md',
    ];
    const isIgnored = (p) =>
      npmignore.some((pat) => {
        const pp = pat.replace(/\/+$/, '');
        return p === pp || p.startsWith(pp + '/') || p.split('/').includes(pp);
      });
    for (const p of critical) {
      assert.ok(
        !isIgnored(p),
        `.npmignore must not exclude installer-referenced path: ${p} (BUG-2026-08-07)`
      );
    }
  }

  console.log('test-install-helpers: ALL PASS');
} finally {
  rmSync(tmpHome, { recursive: true, force: true });
}
