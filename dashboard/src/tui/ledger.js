const chalk = require('chalk');

function renderLedger(box, cycleTimes) {
  if (!box || typeof box.setContent !== 'function') {
    return;
  }

  if (!cycleTimes || cycleTimes.length === 0) {
    box.setContent(chalk.dim('{center}no completed stories yet{/center}'));
    return;
  }

  const lines = [];
  lines.push('{bold}{cyan}Ledger{/cyan}{/bold}');
  lines.push('');

  // Header row
  lines.push(
    '{bold}' +
    '{cyan}Story ID{/cyan}  ' +
    '{cyan}Epic{/cyan}  ' +
    '{cyan}BCPs{/cyan}  ' +
    '{cyan}Minutes{/cyan}  ' +
    '{cyan}BCP/hr{/cyan}' +
    '{/bold}'
  );

  let totalBCPs = 0;
  let totalMinutes = 0;

  // Data rows
  cycleTimes.forEach((cycle) => {
    const storyId = cycle.story_id || '—';
    const epicPrefix = cycle.epic || '—';
    const bcps = cycle.bcps || 0;
    const minutes = cycle.cycle_minutes || 0;
    const bcpPerHour = minutes > 0 ? ((bcps * 60) / minutes).toFixed(1) : '—';

    totalBCPs += bcps;
    totalMinutes += minutes;

    lines.push(
      `  ${storyId}  ` +
      `${epicPrefix}  ` +
      `${bcps}  ` +
      `${minutes}  ` +
      `${bcpPerHour}`
    );
  });

  lines.push('');

  // Totals row
  const avgBcpPerHour =
    totalMinutes > 0 ? ((totalBCPs * 60) / totalMinutes).toFixed(1) : '—';

  lines.push(
    '{bold}{yellow}' +
    `TOTAL  —  ${totalBCPs}  ${totalMinutes}  ${avgBcpPerHour}` +
    '{/yellow}{/bold}'
  );

  box.setContent(lines.join('\n'));
}

module.exports = { renderLedger };
