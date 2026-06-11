function renderEpicQueue(box, epics, executionStatus) {
  if (!box || typeof box.setContent !== 'function') {
    return;
  }

  if (!epics || epics.length === 0) {
    box.setContent('{gray-fg}no epic shards found{/gray-fg}');
    return;
  }

  const statusMap = executionStatus?.epics || new Map();
  const doneStatuses = new Set(['done', 'complete', 'completed', 'released']);
  const activeStatuses = new Set(['in_progress', 'running', 'active']);

  function dot(id) {
    const s = statusMap.get(id) || '';
    if (doneStatuses.has(s)) return '{green-fg}●{/green-fg}';
    if (activeStatuses.has(s)) return '{yellow-fg}●{/yellow-fg}';
    return '{gray-fg}·{/gray-fg}';
  }

  function epicDot(epic) {
    const s = statusMap.get(epic.id) || '';
    if (doneStatuses.has(s)) return '{green-fg}●{/green-fg}';
    if (activeStatuses.has(s)) return '{yellow-fg}●{/yellow-fg}';
    const stories = epic.stories || [];
    if (stories.length > 0 && stories.every(st => doneStatuses.has(statusMap.get(st.id) || ''))) {
      return '{green-fg}●{/green-fg}';
    }
    return '{gray-fg}·{/gray-fg}';
  }

  const lines = [];
  let grandTotalBcps = 0;
  const perEpicBcp = [];

  epics.forEach(epic => {
    lines.push(`${epicDot(epic)} {bold}${epic.id}{/bold} {gray-fg}·{/gray-fg} ${epic.title || '—'}`);

    const stories = epic.stories || [];
    let epicBcpDone = 0;
    let epicBcpTotal = 0;
    let epicStoriesDone = 0;

    stories.forEach(story => {
      const bcp = story.bcps || 0;
      epicBcpTotal += bcp;
      grandTotalBcps += bcp;
      const isDone = doneStatuses.has(statusMap.get(story.id) || '');
      if (isDone) { epicBcpDone += bcp; epicStoriesDone++; }

      const bcpStr = isDone
        ? `{green-fg}${bcp} BCP{/green-fg}`
        : `{gray-fg}${bcp} BCP{/gray-fg}`;
      lines.push(`  ${dot(story.id)} {gray-fg}${story.id}{/gray-fg} ${story.title || '—'}  ${bcpStr}`);
    });

    perEpicBcp.push({ id: epic.id, bcps: epicBcpTotal });

    const bcpProgressStr = epicBcpDone > 0
      ? `{green-fg}${epicBcpDone}{/green-fg}{gray-fg}/${epicBcpTotal} BCP{/gray-fg}`
      : `{gray-fg}0/${epicBcpTotal} BCP{/gray-fg}`;
    lines.push(`  {gray-fg}${epicStoriesDone}/${stories.length} done · ${bcpProgressStr}`);
    lines.push('');
  });

  // Release baseline footer
  lines.push('{gray-fg}─────────────────────────{/gray-fg}');
  lines.push(`{gray-fg}release baseline{/gray-fg}`);
  lines.push(`{gray-fg}total: {/gray-fg}{yellow-fg}${grandTotalBcps} BCPs{/yellow-fg}`);
  lines.push(perEpicBcp.map(e => `{gray-fg}${e.id}: ${e.bcps} BCP{/gray-fg}`).join('  '));
  lines.push(`{gray-fg}target: {/gray-fg}{bold}v2.0.0{/bold}`);

  box.setContent(lines.join('\n'));
}

module.exports = { renderEpicQueue };
