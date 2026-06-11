function pad(str, width) {
  const s = String(str);
  return s.length >= width ? s : s + ' '.repeat(width - s.length);
}

function renderLedger(box, cycleTimes) {
  if (!box || typeof box.setContent !== 'function') {
    return;
  }

  if (!cycleTimes || cycleTimes.length === 0) {
    box.setContent('{gray-fg}stories complete here as they land{/gray-fg}');
    return;
  }

  const lines = [];

  // Column widths
  const W = { sid: 12, epic: 6, bcps: 5, min: 8, bhr: 7 };

  // Header
  lines.push(
    `{cyan-fg}{bold}${pad('Story ID', W.sid)}${pad('Epic', W.epic)}${pad('BCPs', W.bcps)}${pad('Minutes', W.min)}${pad('BCP/hr', W.bhr)}{/bold}{/cyan-fg}`
  );
  lines.push('{gray-fg}' + '─'.repeat(W.sid + W.epic + W.bcps + W.min + W.bhr) + '{/gray-fg}');

  let totalBCPs = 0;
  let totalMinutes = 0;

  cycleTimes.forEach(cycle => {
    const storyId = cycle.id || '—';
    const epicId = cycle.epic || '—';
    const bcps = cycle.bcps || 0;
    const minutes = cycle.cycleMin || 0;
    const bph = minutes > 0 ? ((bcps * 60) / minutes).toFixed(1) : '—';

    totalBCPs += bcps;
    totalMinutes += minutes;

    lines.push(
      `{white-fg}${pad(storyId, W.sid)}{/white-fg}` +
      `{gray-fg}${pad(epicId, W.epic)}{/gray-fg}` +
      `{yellow-fg}${pad(bcps, W.bcps)}{/yellow-fg}` +
      `{gray-fg}${pad(minutes, W.min)}{/gray-fg}` +
      `{green-fg}${pad(bph, W.bhr)}{/green-fg}`
    );
  });

  lines.push('{gray-fg}' + '─'.repeat(W.sid + W.epic + W.bcps + W.min + W.bhr) + '{/gray-fg}');

  const avgBph = totalMinutes > 0 ? ((totalBCPs * 60) / totalMinutes).toFixed(1) : '—';
  lines.push(
    `{bold}{yellow-fg}${pad('TOTAL', W.sid)}${pad('—', W.epic)}${pad(totalBCPs, W.bcps)}${pad(totalMinutes, W.min)}${pad(avgBph, W.bhr)}{/yellow-fg}{/bold}`
  );

  box.setContent(lines.join('\n'));
}

module.exports = { renderLedger };
