#!/usr/bin/env node
// install-helpers.js — symlink helpers for bigpowers setup

const fs = require('fs');
const path = require('path');

function linkSkills(skillsDir, targetDir) {
  for (const entry of fs.readdirSync(skillsDir, { withFileTypes: true })) {
    if (!entry.isDirectory()) continue;
    if (!fs.existsSync(path.join(skillsDir, entry.name, 'SKILL.md'))) continue;

    const src = path.join(skillsDir, entry.name);
    const dst = path.join(targetDir, entry.name);

    try {
      const stat = fs.lstatSync(dst);
      if (stat.isSymbolicLink()) fs.unlinkSync(dst);
    } catch {}

    fs.symlinkSync(src, dst);
  }
}

function linkDir(src, dst) {
  try {
    const stat = fs.lstatSync(dst);
    if (stat.isSymbolicLink()) fs.unlinkSync(dst);
  } catch {}
  fs.symlinkSync(src, dst);
}

function linkFile(src, dst) {
  try {
    const stat = fs.lstatSync(dst);
    if (stat.isSymbolicLink()) fs.unlinkSync(dst);
  } catch {}
  fs.symlinkSync(src, dst);
}

function linkHook(src, dst) {
  if (!fs.existsSync(src)) return;
  try {
    const stat = fs.lstatSync(dst);
    if (stat.isSymbolicLink()) fs.unlinkSync(dst);
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
        path.join(repoRoot, 'guard-git', 'scripts', 'block-dangerous-git.sh'),
        path.join(hooksDir, 'block-dangerous-git.sh')
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
      break;
    }
    case 'pi': {
      const targetDir = path.join(homeDir, '.pi', 'agent', 'skills');
      fs.mkdirSync(targetDir, { recursive: true });
      linkSkills(skillsDir, targetDir);
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
          if (target.includes('bigpowers')) {
            removeSymlink(path.join(skillsDir, entry.name));
          }
        }
      }
      const hooksDir = path.join(homeDir, '.claude', 'hooks');
      removeSymlink(path.join(hooksDir, 'block-dangerous-git.sh'));
      removeSymlink(path.join(hooksDir, 'rtk-rewrite.sh'));
      break;
    }
    case 'gemini':
      removeSymlink(path.join(homeDir, '.gemini', 'config', 'plugins', 'bigpowers'));
      break;
    case 'pi': {
      const skillsDir = path.join(homeDir, '.pi', 'agent', 'skills');
      if (fs.existsSync(skillsDir)) {
        for (const entry of fs.readdirSync(skillsDir, { withFileTypes: true })) {
          if (!entry.isSymbolicLink()) continue;
          const target = fs.readlinkSync(path.join(skillsDir, entry.name));
          if (target.includes('bigpowers')) {
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
      removeSymlink(path.join(homeDir, '.codex', 'AGENTS.md'));
      break;
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
