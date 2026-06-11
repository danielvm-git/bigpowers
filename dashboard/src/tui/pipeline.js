const { STEPS } = require('../loaders/pipeline-map');

function renderPipeline(box, stateData) {
  if (!box || typeof box.setContent !== 'function') {
    return;
  }

  if (!stateData) {
    box.setContent('{dim}state.yaml not loaded{/dim}');
    return;
  }

  const currentStep = stateData.epicCycle?.current_step || null;
  const completedSteps = stateData.epicCycle?.completed_steps || [];

  // Build pipeline visualization
  const lines = [];
  lines.push('{bold}{cyan}Pipeline{/cyan}{/bold}');
  lines.push('');

  // Create step display
  const stepDisplay = STEPS.map((step, index) => {
    const isCompleted = completedSteps.includes(step);
    const isCurrent = step === currentStep;

    let display = `  ${index + 1}. ${step}`;

    if (isCurrent) {
      display = `{reverse}{bold}${display}{/bold}{/reverse}`;
    } else if (isCompleted) {
      display = `{green-fg}${display}{/green-fg}`;
    } else {
      display = `{gray-fg}${display}{/gray-fg}`;
    }

    return display;
  }).join('\n');

  lines.push(stepDisplay);
  lines.push('');
  lines.push(`{dim}Current: ${currentStep || '—'}{/dim}`);

  box.setContent(lines.join('\n'));
}

module.exports = { renderPipeline };
