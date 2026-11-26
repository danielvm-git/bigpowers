// story: BUG-2026-11-03-cli-nontty-silent-noop
// install-uninstall.js — the interactive uninstall flow, lifted out of
// bin/setup.js so the entry point stays inside the file-size cap. Behaviour is
// unchanged; only the dependencies are injected.

'use strict';

/**
 * Ask which tools to uninstall from, confirm, then remove the links.
 * @param ctx {{clack, catalogue, supportedIds, uninstallTool, root, c}}
 */
async function runUninstallInteractive(ctx) {
  const { clack, catalogue, supportedIds, uninstallTool, root, c } = ctx;
  const { multiselect, confirm, spinner, outro, isCancel } = await clack();

  const toolOptions = catalogue
    .filter((t) => supportedIds.has(t.id))
    .map((tool) => ({ value: tool.id, label: tool.name, hint: `(${tool.globalPath})` }));

  const selectedToolIds = await multiselect({
    message: 'Uninstall from which tools?',
    options: toolOptions,
    initialValues: ['claude'],
    required: true,
  });
  if (isCancel(selectedToolIds)) {
    outro('Cancelled.');
    process.exit(0);
  }

  const plural = selectedToolIds.length > 1 ? 's' : '';
  const yes = await confirm({
    message: `Remove symlinks from ${selectedToolIds.length} tool${plural}?`,
    initialValue: true,
  });
  if (!yes || isCancel(yes)) {
    outro('Cancelled.');
    process.exit(0);
  }

  const s = await spinner();
  s.start('Removing...');
  const results = [];
  for (const toolId of selectedToolIds) {
    const tool = catalogue.find((t) => t.id === toolId);
    try {
      uninstallTool(toolId, root);
      results.push({ name: tool.name, ok: true });
    } catch (err) {
      results.push({ name: tool.name, ok: false, error: err.message });
    }
  }
  s.stop('Done.');

  console.log('');
  for (const r of results) {
    const icon = r.ok ? c.green('✓') : c.red('✗');
    const detail = r.ok ? c.dim('removed') : c.red(r.error);
    console.log(`  ${icon} ${r.name} — ${detail}`);
  }
  console.log('');
  outro('Uninstall complete.');
}

module.exports = { runUninstallInteractive };
