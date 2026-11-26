// story: BUG-2026-11-03-cli-nontty-silent-noop
// install-run.js — the steps every install path shares (clean, sync, link,
// report). Extracted from bin/setup.js so the interactive and the
// non-interactive paths cannot drift, and so the file stays within the size cap.

'use strict';

const fs = require('fs');
const path = require('path');

/** Non-interactive progress: plain lines instead of a spinner. */
function consoleUi() {
  return {
    start: (m) => console.log(`  ${m}`),
    message: (m) => console.log(`  ${m}`),
    stop: (m) => console.log(`  ${m}`),
  };
}

/** @param spinner the @clack/prompts spinner factory */
function spinnerUi(spinner) {
  let handle = null;
  return {
    start: (m) => { handle = spinner(); handle.start(m); },
    message: (m) => handle && handle.message(m),
    stop: (m) => handle && handle.stop(m),
  };
}

function skillCount(root) {
  const dir = path.join(root, 'skills');
  return fs.readdirSync(dir).filter((d) => fs.existsSync(path.join(dir, d, 'SKILL.md'))).length;
}

/**
 * Remove stale links for the selected tools, sync the rendered artifacts, then
 * link each tool. Returns [{name, path, ok, error?}] — never throws for one
 * tool's failure, so the caller can report partial success honestly.
 */
async function syncAndInstall({ scope, tools }, ctx) {
  const { root, catalogue, installGlobal, installLocal, uninstallTool, runInheritedAsync, ui, hadExisting } = ctx;

  ui.start('Preparing installation...');
  if (hadExisting) {
    ui.message('Cleaning old symlinks...');
    for (const toolId of tools) {
      try {
        uninstallTool(toolId, root);
      } catch {
        // Tool may not be installed yet — nothing to clean.
      }
    }
  }

  ui.message('Syncing skills...');
  try {
    const output = await runInheritedAsync('bash scripts/sync-skills.sh --distribute-only');
    const summary = output.trim().split('\n').find((l) => l.includes('skills synced'));
    if (summary) ui.message(summary.trim());
  } catch (err) {
    ui.stop('Sync failed.');
    throw err;
  }

  const results = [];
  for (const toolId of tools) {
    const tool = catalogue.find((t) => t.id === toolId);
    ui.message(`Installing ${tool.name}...`);
    try {
      if (scope === 'global') installGlobal(tool, root);
      else installLocal(tool, root);
      results.push({ name: tool.name, path: scope === 'global' ? tool.globalPath : tool.localPath, ok: true });
    } catch (err) {
      results.push({ name: tool.name, path: tool.globalPath, ok: false, error: err.message });
    }
  }
  ui.stop('Installation complete.');
  return results;
}

function reportResults(results, { tools, root, c }) {
  console.log('');
  for (const r of results) {
    const icon = r.ok ? c.green('✓') : c.red('✗');
    console.log(`  ${icon} ${r.name} — ${r.ok ? c.dim(r.path) : c.red(r.error)}`);
  }
  if (tools.includes('cursor') && results.some((r) => r.name === 'Cursor' && r.ok)) {
    console.log(`  ${c.dim('NOTE: Cursor does not scan ~/.cursor/rules globally — also symlink into each project:')}`);
    console.log(`  ${c.dim('  ln -sfn ' + path.join(root, '.cursor', 'rules') + ' .cursor/rules')}`);
  }
  console.log('');
}

module.exports = { consoleUi, spinnerUi, skillCount, syncAndInstall, reportResults };
