#!/usr/bin/env node
// story: e60s01
// story: e61s02
// story: e64s02
// story: e76s02
// story: e69s02
// story: e74s02
// story: e65s02
// install-helpers.js — symlink helpers for bigpowers setup

const fs = require('fs');
const path = require('path');

function linkSkills(skillsDir, targetDir) {
  for (const entry of fs.readdirSync(skillsDir, { withFileTypes: true })) {
    if (!entry.isDirectory()) continue;
    if (!fs.existsSync(path.join(skillsDir, entry.name, 'SKILL.md'))) continue;

    const src = path.join(skillsDir, entry.name);
    const dst = path.join(targetDir, entry.name);

    // Remove existing symlink or directory
    try {
      fs.rmSync(dst, { force: true, recursive: true });
    } catch {}

    fs.symlinkSync(src, dst);
  }
}

function linkDir(src, dst) {
  if (!fs.existsSync(src)) {
    throw new Error(
      `Link source missing: ${src} (run bash scripts/sync-skills.sh first)`
    );
  }
  // Remove existing symlink or directory
  try {
    fs.rmSync(dst, { force: true, recursive: true });
  } catch {}
  fs.symlinkSync(src, dst);
}

function linkFile(src, dst) {
  // Remove existing symlink or file
  try {
    fs.rmSync(dst, { force: true });
  } catch {}
  fs.symlinkSync(src, dst);
}

function linkRenderedSkills(renderedDir, targetDir) {
  if (!fs.existsSync(renderedDir)) return;
  fs.mkdirSync(targetDir, { recursive: true });
  for (const entry of fs.readdirSync(renderedDir, { withFileTypes: true })) {
    if (!entry.isDirectory()) continue;
    if (!fs.existsSync(path.join(renderedDir, entry.name, 'SKILL.md'))) continue;
    linkDir(path.join(renderedDir, entry.name), path.join(targetDir, entry.name));
  }
}

function bridgeHermesConfig(configPath) {
  fs.mkdirSync(path.dirname(configPath), { recursive: true });
  if (fs.existsSync(configPath)) {
    const existing = fs.readFileSync(configPath, 'utf8');
    if (/^instructions:/m.test(existing)) return;
  }
  fs.writeFileSync(configPath, 'instructions: AGENTS.md\n');
}

function linkHook(src, dst) {
  if (!fs.existsSync(src)) {
    throw new Error(
      `Hook source missing: ${src} (expected under repo skills/ or scripts/hooks/; fix path or restore file)`
    );
  }
  // Remove existing symlink or file
  try {
    fs.rmSync(dst, { force: true });
  } catch {}
  fs.symlinkSync(src, dst);
  try { fs.chmodSync(src, 0o755); } catch {}
}

// ── Install per tool ─────────────────────────────────────────────────────────

function installGlobal(tool, repoRoot) {
  const homeDir = require('os').homedir();
  const skillsDir = path.join(repoRoot, 'skills');

  switch (tool.id) {
    case 'claude': {
      const targetDir = path.join(homeDir, '.claude', 'skills');
      fs.mkdirSync(targetDir, { recursive: true });
      linkSkills(skillsDir, targetDir);

      const hooksDir = path.join(homeDir, '.claude', 'hooks');
      fs.mkdirSync(hooksDir, { recursive: true });
      linkHook(
        path.join(repoRoot, 'skills', 'guard-git', 'scripts', 'block-dangerous-git.sh'),
        path.join(hooksDir, 'block-dangerous-git.sh')
      );
      // story: e63 — hook sources SCRIPT_DIR/lib/git-guardrails-core.sh
      linkDir(
        path.join(repoRoot, 'skills', 'guard-git', 'scripts', 'lib'),
        path.join(hooksDir, 'lib')
      );
      linkHook(
        path.join(repoRoot, 'scripts', 'hooks', 'rtk-rewrite.sh'),
        path.join(hooksDir, 'rtk-rewrite.sh')
      );
      break;
    }
    case 'gemini': {
      const extSrc = path.join(repoRoot, '.gemini', 'extensions', 'bigpowers');
      const extDst = path.join(homeDir, '.gemini', 'config', 'plugins', 'bigpowers');
      fs.mkdirSync(path.dirname(extDst), { recursive: true });
      linkDir(extSrc, extDst);
      const hooksSrc = path.join(extSrc, 'hooks');
      const hooksDst = path.join(homeDir, '.gemini', 'hooks');
      fs.mkdirSync(hooksDst, { recursive: true });
      for (const hookFile of [
        'session-start',
        'run-hook.cmd',
        'before-tool-git-guard.sh',
        'before-tool-rtk.sh',
        'before-tool-token-mgmt.sh',
      ]) {
        linkHook(path.join(hooksSrc, hookFile), path.join(hooksDst, hookFile));
      }
      break;
    }
    case 'pi': {
      const targetDir = path.join(homeDir, '.pi', 'agent', 'skills');
      fs.mkdirSync(targetDir, { recursive: true });
      linkSkills(skillsDir, targetDir);
      break;
    }
    case 'hermes': {
      const renderedDir = path.join(repoRoot, '.hermes', 'skills');
      const targetDir = path.join(homeDir, '.hermes', 'skills');
      linkRenderedSkills(renderedDir, targetDir);
      bridgeHermesConfig(path.join(homeDir, '.hermes', 'config.yaml'));
      const hookSrc = path.join(repoRoot, 'scripts', 'hooks', 'hermes', 'gateway', 'session-log');
      const hookDst = path.join(homeDir, '.hermes', 'hooks', 'session-log');
      if (fs.existsSync(hookSrc)) {
        fs.mkdirSync(path.dirname(hookDst), { recursive: true });
        linkDir(hookSrc, hookDst);
      }
      break;
    }
    case 'zcode': {
      const renderedDir = path.join(repoRoot, '.zcode', 'skills');
      const targetDir = path.join(homeDir, '.zcode', 'skills');
      linkRenderedSkills(renderedDir, targetDir);
      const agentsSrc = path.join(repoRoot, 'AGENTS.md');
      const agentsDst = path.join(homeDir, '.zcode', 'AGENTS.md');
      fs.mkdirSync(path.dirname(agentsDst), { recursive: true });
      linkFile(agentsSrc, agentsDst);
      break;
    }
    case 'mimo': {
      const renderedDir = path.join(repoRoot, '.mimocode', 'skills');
      const targetDir = path.join(homeDir, '.mimocode', 'skills');
      linkRenderedSkills(renderedDir, targetDir);
      const agentsSrc = path.join(repoRoot, 'AGENTS.md');
      const agentsDst = path.join(homeDir, '.mimocode', 'AGENTS.md');
      fs.mkdirSync(path.dirname(agentsDst), { recursive: true });
      linkFile(agentsSrc, agentsDst);
      break;
    }
    case 'antigravity':
    case 'agy': {
      const renderedDir = path.join(repoRoot, '.agents', 'skills');
      const targetDir = path.join(homeDir, '.gemini', 'antigravity-cli', 'skills');
      linkRenderedSkills(renderedDir, targetDir);
      break;
    }
    case 'cursor': {
      const rulesSrc = path.join(repoRoot, '.cursor', 'rules');
      const rulesDst = path.join(homeDir, '.cursor', 'rules');
      fs.mkdirSync(path.dirname(rulesDst), { recursive: true });
      linkDir(rulesSrc, rulesDst);
      break;
    }
    case 'codex': {
      const templatePath = path.join(repoRoot, 'templates', 'codex', 'AGENTS.md');
      const targetPath = path.join(homeDir, '.codex', 'AGENTS.md');
      fs.mkdirSync(path.dirname(targetPath), { recursive: true });
      linkFile(templatePath, targetPath);
      break;
    }
  }
}

function installLocal(tool, repoRoot) {
  const skillsDir = path.join(repoRoot, 'skills');
  const cwd = process.cwd();

  switch (tool.id) {
    case 'claude': {
      const targetDir = path.join(cwd, '.claude', 'skills');
      fs.mkdirSync(targetDir, { recursive: true });
      linkSkills(skillsDir, targetDir);
      break;
    }
    case 'gemini': {
      const extSrc = path.join(repoRoot, '.gemini', 'extensions', 'bigpowers');
      const extDst = path.join(cwd, '.gemini', 'extensions', 'bigpowers');
      fs.mkdirSync(path.dirname(extDst), { recursive: true });
      linkDir(extSrc, extDst);
      break;
    }
    case 'pi': {
      const targetDir = path.join(cwd, '.pi', 'agent', 'skills');
      fs.mkdirSync(targetDir, { recursive: true });
      linkSkills(skillsDir, targetDir);
      break;
    }
    case 'hermes': {
      const renderedDir = path.join(repoRoot, '.hermes', 'skills');
      const targetDir = path.join(cwd, '.hermes', 'skills');
      linkRenderedSkills(renderedDir, targetDir);
      bridgeHermesConfig(path.join(cwd, '.hermes', 'config.yaml'));
      break;
    }
    case 'zcode': {
      const renderedDir = path.join(repoRoot, '.zcode', 'skills');
      const targetDir = path.join(cwd, '.zcode', 'skills');
      linkRenderedSkills(renderedDir, targetDir);
      const agentsSrc = path.join(repoRoot, 'AGENTS.md');
      const agentsDst = path.join(cwd, '.zcode', 'AGENTS.md');
      fs.mkdirSync(path.dirname(agentsDst), { recursive: true });
      linkFile(agentsSrc, agentsDst);
      break;
    }
    case 'mimo': {
      const renderedDir = path.join(repoRoot, '.mimocode', 'skills');
      const targetDir = path.join(cwd, '.mimocode', 'skills');
      linkRenderedSkills(renderedDir, targetDir);
      const agentsSrc = path.join(repoRoot, 'AGENTS.md');
      const agentsDst = path.join(cwd, '.mimocode', 'AGENTS.md');
      fs.mkdirSync(path.dirname(agentsDst), { recursive: true });
      linkFile(agentsSrc, agentsDst);
      break;
    }
    case 'antigravity':
    case 'agy': {
      const renderedDir = path.join(repoRoot, '.agents', 'skills');
      const targetDir = path.join(cwd, '.agents', 'skills');
      linkRenderedSkills(renderedDir, targetDir);
      const agentsSrc = path.join(repoRoot, 'AGENTS.md');
      const agentsDst = path.join(cwd, 'AGENTS.md');
      if (!fs.existsSync(agentsDst)) {
        linkFile(agentsSrc, agentsDst);
      }
      break;
    }
    case 'cursor': {
      const rulesSrc = path.join(repoRoot, '.cursor', 'rules');
      const rulesDst = path.join(cwd, '.cursor', 'rules');
      fs.mkdirSync(path.dirname(rulesDst), { recursive: true });
      linkDir(rulesSrc, rulesDst);
      break;
    }
    case 'codex': {
      const templatePath = path.join(repoRoot, 'templates', 'codex', 'AGENTS.md');
      const targetPath = path.join(cwd, '.codex', 'AGENTS.md');
      fs.mkdirSync(path.dirname(targetPath), { recursive: true });
      linkFile(templatePath, targetPath);
      break;
    }
  }
}

// ── Uninstall per tool ───────────────────────────────────────────────────────

function uninstallTool(toolId, repoRoot) {
  const homeDir = require('os').homedir();

  switch (toolId) {
    case 'claude': {
      const skillsDir = path.join(homeDir, '.claude', 'skills');
      if (fs.existsSync(skillsDir)) {
        for (const entry of fs.readdirSync(skillsDir, { withFileTypes: true })) {
          if (!entry.isSymbolicLink()) continue;
          const target = fs.readlinkSync(path.join(skillsDir, entry.name));
          if (target.startsWith(repoRoot)) {
            removeSymlink(path.join(skillsDir, entry.name));
          }
        }
      }
      const hooksDir = path.join(homeDir, '.claude', 'hooks');
      removeSymlink(path.join(hooksDir, 'block-dangerous-git.sh'));
      removeSymlink(path.join(hooksDir, 'rtk-rewrite.sh'));
      removeSymlink(path.join(hooksDir, 'lib'));
      break;
    }
    case 'gemini':
      removeSymlink(path.join(homeDir, '.gemini', 'config', 'plugins', 'bigpowers'));
      for (const hookFile of [
        'session-start',
        'run-hook.cmd',
        'before-tool-git-guard.sh',
        'before-tool-rtk.sh',
        'before-tool-token-mgmt.sh',
      ]) {
        removeSymlink(path.join(homeDir, '.gemini', 'hooks', hookFile));
      }
      break;
    case 'pi': {
      const skillsDir = path.join(homeDir, '.pi', 'agent', 'skills');
      if (fs.existsSync(skillsDir)) {
        for (const entry of fs.readdirSync(skillsDir, { withFileTypes: true })) {
          if (!entry.isSymbolicLink()) continue;
          const target = fs.readlinkSync(path.join(skillsDir, entry.name));
          if (target.startsWith(repoRoot)) {
            removeSymlink(path.join(skillsDir, entry.name));
          }
        }
      }
      break;
    }
    case 'hermes': {
      const skillsDir = path.join(homeDir, '.hermes', 'skills');
      if (fs.existsSync(skillsDir)) {
        for (const entry of fs.readdirSync(skillsDir, { withFileTypes: true })) {
          if (!entry.isSymbolicLink()) continue;
          const target = fs.readlinkSync(path.join(skillsDir, entry.name));
          if (target.startsWith(repoRoot) || target.includes('.hermes/skills')) {
            removeSymlink(path.join(skillsDir, entry.name));
          }
        }
      }
      removeSymlink(path.join(homeDir, '.hermes', 'hooks', 'session-log'));
      break;
    }
    case 'zcode': {
      const skillsDir = path.join(homeDir, '.zcode', 'skills');
      if (fs.existsSync(skillsDir)) {
        for (const entry of fs.readdirSync(skillsDir, { withFileTypes: true })) {
          if (!entry.isSymbolicLink()) continue;
          const target = fs.readlinkSync(path.join(skillsDir, entry.name));
          if (target.includes('bigpowers') || target.includes('.zcode/skills')) {
            removeSymlink(path.join(skillsDir, entry.name));
          }
        }
      }
      removeSymlink(path.join(homeDir, '.zcode', 'AGENTS.md'));
      break;
    }
    case 'mimo': {
      const skillsDir = path.join(homeDir, '.mimocode', 'skills');
      if (fs.existsSync(skillsDir)) {
        for (const entry of fs.readdirSync(skillsDir, { withFileTypes: true })) {
          if (!entry.isSymbolicLink()) continue;
          const target = fs.readlinkSync(path.join(skillsDir, entry.name));
          if (target.includes('bigpowers') || target.includes('.mimocode/skills')) {
            removeSymlink(path.join(skillsDir, entry.name));
          }
        }
      }
      removeSymlink(path.join(homeDir, '.mimocode', 'AGENTS.md'));
      break;
    }
    case 'antigravity':
    case 'agy': {
      const skillsDir = path.join(homeDir, '.gemini', 'antigravity-cli', 'skills');
      if (fs.existsSync(skillsDir)) {
        for (const entry of fs.readdirSync(skillsDir, { withFileTypes: true })) {
          if (!entry.isSymbolicLink()) continue;
          const target = fs.readlinkSync(path.join(skillsDir, entry.name));
          if (target.includes('bigpowers') || target.includes('.agents/skills')) {
            removeSymlink(path.join(skillsDir, entry.name));
          }
        }
      }
      break;
    }
    case 'cursor':
      removeSymlink(path.join(homeDir, '.cursor', 'rules'));
      break;
    case 'codex':
      {
        const skillsDir = path.join(homeDir, '.codex', 'skills');
        if (fs.existsSync(skillsDir)) {
          for (const entry of fs.readdirSync(skillsDir, { withFileTypes: true })) {
            if (!entry.isSymbolicLink()) continue;
            removeSymlink(path.join(skillsDir, entry.name));
          }
        }
      }
      removeSymlink(path.join(homeDir, '.codex', 'hooks', 'pre-tool-git-guard.sh'));
      break; // story: e65s02
  }
}

function removeSymlink(p) {
  try {
    const stat = fs.lstatSync(p);
    if (stat.isSymbolicLink()) {
      fs.unlinkSync(p);
      return true;
    }
  } catch {}
  return false;
}

function detectExistingInstall() {
  const homeDir = require('os').homedir();
  const marker = path.join(homeDir, '.claude', 'skills', 'survey-context');
  try {
    const stat = fs.lstatSync(marker);
    return stat.isSymbolicLink();
  } catch {
    return false;
  }
}

module.exports = {
  linkSkills,
  linkDir,
  linkFile,
  linkHook,
  installGlobal,
  installLocal,
  uninstallTool,
  removeSymlink,
  detectExistingInstall,
};
