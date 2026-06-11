const { STEPS } = require('../loaders/pipeline-map');

const STEP_ABBR = ['sur','pla','kic','tdd','ver','aud','com','rel'];

function renderPipeline(box, stateData) {
  if (!box || typeof box.setContent !== 'function') {
    return;
  }

  if (!stateData) {
    box.setContent('{dim}state.yaml not loaded{/dim}');
    return;
  }

  // current_step is a 0-based index (number) in state.yaml
  const rawStep = stateData.epicCycle?.current_step;
  const currentIdx = typeof rawStep === 'number' ? rawStep : STEPS.indexOf(rawStep);

  // Build pipeline strip
  const strip = STEPS.map((step, i) => {
    const abbr = STEP_ABBR[i];
    if (i < currentIdx) {
      return `{green-fg}${i + 1} ${step}{/green-fg}`;
    } else if (i === currentIdx) {
      return `{reverse}{cyan-fg}${i + 1} ${step}{/cyan-fg}{/reverse}`;
    } else {
      return `{dim}${i + 1} ${step}{/dim}`;
    }
  }).join(' {dim}›{/dim} ');

  const stepLabel = currentIdx >= 0 && currentIdx < STEPS.length
    ? `{dim}step{/dim} {cyan-fg}${currentIdx + 1}{/cyan-fg}{dim}/${STEPS.length}{/dim}  {dim}—{/dim}  ${STEPS[currentIdx]}`
    : '{dim}no active step{/dim}';

  box.setContent(stepLabel + '\n\n' + strip);
}

module.exports = { renderPipeline };
