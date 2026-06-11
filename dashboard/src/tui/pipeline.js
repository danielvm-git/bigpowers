const { STEPS } = require('../loaders/pipeline-map');

const STEP_ABBR = ['sur','pla','kic','tdd','ver','aud','com','rel'];

function renderPipeline(box, stateData) {
  if (!box || typeof box.setContent !== 'function') {
    return;
  }

  if (!stateData) {
    box.setContent('{gray-fg}state.yaml not loaded{/gray-fg}');
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
      return `{gray-fg}${i + 1} ${step}{/gray-fg}`;
    }
  }).join(' {gray-fg}›{/gray-fg} ');

  const stepLabel = currentIdx >= 0 && currentIdx < STEPS.length
    ? `{gray-fg}step{/gray-fg} {cyan-fg}${currentIdx + 1}{/cyan-fg}{gray-fg}/${STEPS.length}{/gray-fg}  {gray-fg}—{/gray-fg}  ${STEPS[currentIdx]}`
    : '{gray-fg}no active step{/gray-fg}';

  box.setContent(stepLabel + '\n\n' + strip);
}

module.exports = { renderPipeline };
