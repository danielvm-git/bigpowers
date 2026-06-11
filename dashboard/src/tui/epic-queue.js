const { gateIcon, gateColor } = require('../loaders/gate-status');

function renderEpicQueue(box, epics, executionStatus) {
  if (!box || typeof box.setContent !== 'function') {
    return;
  }

  if (!epics || epics.length === 0) {
    box.setContent('{dim}no epic shards found{/dim}');
    return;
  }

  let lines = [];
  lines.push('{bold}EPIC QUEUE{/bold}');
  lines.push('');
  let totalBcps = 0;

  epics.forEach(epic => {
    const epicStatusIcon = gateIcon[epic.status] || '?';
    lines.push(`${epicStatusIcon} ${epic.id} ${epic.title}`);

    if (epic.stories && epic.stories.length > 0) {
      epic.stories.forEach(story => {
        const storyStatusIcon = gateIcon[story.status] || '?';
        const bcpCount = story.bcps || 0;
        totalBcps += bcpCount;
        lines.push(`  ${storyStatusIcon} ${story.id} ${story.title} (${bcpCount} BCPs)`);
      });
    }
  });

  lines.push('');
  lines.push(`Total: ${totalBcps} BCPs`);

  box.setContent(lines.join('\n'));
}

module.exports = { renderEpicQueue };
