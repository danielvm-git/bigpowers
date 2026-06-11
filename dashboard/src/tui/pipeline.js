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

  // Build horizontal pipeline strip
  const steps = STEPS.map((step, index) => {
    const isCompleted = completedSteps.includes(step);
    const isCurrent = step === currentStep;

    let display = `${index + 1} ${step}`;

    if (isCurrent) {
      display = `{reverse}${display}{/reverse}`;
    } else if (isCompleted) {
      display = `{green-fg}${display}{/green-fg}`;
    } else {
      display = `{dim}${display}{/dim}`;
    }

    return display;
  }).join(' {bold}›{/bold} ');

  const lines = [];
  lines.push(`{bold}{cyan}Pipeline{/cyan}{/bold}  step ${STEPS.indexOf(currentStep) + 1} / ${STEPS.length}`);
  lines.push('');
  lines.push(steps);

  box.setContent(lines.join('\n'));
}

module.exports = { renderPipeline };
