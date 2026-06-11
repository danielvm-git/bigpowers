const chalk = require('chalk');

function renderStateYaml(box, stateData) {
  if (!box || typeof box.setContent !== 'function') {
    return;
  }

  if (!stateData) {
    box.setContent(chalk.dim('{center}state.yaml not found{/center}'));
    return;
  }

  const lines = [];
  lines.push('{bold}{cyan}state.yaml{/cyan}{/bold}');
  lines.push('');

  const pairs = [
    { key: 'active_flow', value: stateData.active_flow },
    { key: 'active_epic', value: stateData.active_epic },
    { key: 'active_story', value: stateData.active_story },
    { key: 'current_step', value: stateData.current_step },
    { key: 'next_skill', value: stateData.next_skill },
    { key: 'git.branch', value: stateData.git?.branch },
    { key: 'metrics.story_start', value: stateData.metrics?.story_start },
  ];

  pairs.forEach(({ key, value }) => {
    let displayValue = String(value || '—');

    // Color rules
    if (key === 'git.branch') {
      if (displayValue === 'main') {
        displayValue = chalk.green(displayValue);
      } else if (displayValue.startsWith('feat/')) {
        displayValue = chalk.yellow(displayValue);
      }
    }

    if (key === 'next_skill' && value) {
      displayValue = chalk.green(displayValue);
    }

    lines.push(`  {dim}${key}:{/dim} ${displayValue}`);
  });

  box.setContent(lines.join('\n'));
}

module.exports = { renderStateYaml };
