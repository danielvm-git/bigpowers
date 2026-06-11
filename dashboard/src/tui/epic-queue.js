function renderEpicQueue(box, epics, executionStatus) {
  if (!box || typeof box.setContent !== 'function') {
    return;
  }

  if (!epics || epics.length === 0) {
    box.setContent('{dim}no epic shards found{/dim}');
    return;
  }

  const statusMap = executionStatus?.epics || new Map();
  const doneStatuses = new Set(['done', 'complete', 'completed', 'released']);
  const activeStatuses = new Set(['in_progress', 'running', 'active']);

  function dot(id) {
    const s = statusMap.get(id) || '';
    if (doneStatuses.has(s)) return '{green-fg}●{/green-fg}';
    if (activeStatuses.has(s)) return '{yellow-fg}●{/yellow-fg}';
    return '{dim}·{/dim}';
  }

  function epicDot(epic) {
    const s = statusMap.get(epic.id) || '';
    if (doneStatuses.has(s)) return '{green-fg}●{/green-fg}';
    if (activeStatuses.has(s)) return '{yellow-fg}●{/yellow-fg}';
    const stories = epic.stories || [];
    if (stories.length > 0 && stories.every(st => doneStatuses.has(statusMap.get(st.id) || ''))) {
      return '{green-fg}●{/green-fg}';
    }
    return '{dim}·{/dim}';
  }

  const lines = [];
  let grandTotalBcps = 0;
  const perEpicBcp = [];

  epics.forEach(epic => {
    lines.push(`${epicDot(epic)} {bold}${epic.id}{/bold} {dim}·{/dim} ${epic.title || '—'}`);

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
        : `{dim}${bcp} BCP{/dim}`;
      lines.push(`  ${dot(story.id)} {dim}${story.id}{/dim} ${story.title || '—'}  ${bcpStr}`);
    });

    perEpicBcp.push({ id: epic.id, bcps: epicBcpTotal });

    const bcpProgressStr = epicBcpDone > 0
      ? `{green-fg}${epicBcpDone}{/green-fg}{dim}/${epicBcpTotal} BCP{/dim}`
      : `{dim}0/${epicBcpTotal} BCP{/dim}`;
    lines.push(`  {dim}${epicStoriesDone}/${stories.length} done · ${bcpProgressStr}`);
    lines.push('');
  });

  // Release baseline footer
  lines.push('{dim}─────────────────────────{/dim}');
  lines.push(`{dim}release baseline{/dim}`);
  lines.push(`{dim}total: {/dim}{yellow-fg}${grandTotalBcps} BCPs{/yellow-fg}`);
  lines.push(perEpicBcp.map(e => `{dim}${e.id}: ${e.bcps} BCP{/dim}`).join('  '));
  lines.push(`{dim}target: {/dim}{bold}v2.0.0{/bold}`);

  box.setContent(lines.join('\n'));
}

module.exports = { renderEpicQueue };
