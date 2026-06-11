const STEPS = [
  'survey-context',
  'plan-work',
  'kickoff-branch',
  'develop-tdd',
  'verify-work',
  'audit-code',
  'commit-message',
  'release-branch'
];

function stepIndex(currentStep) {
  return STEPS.indexOf(currentStep);
}

function stepLabel(index) {
  if (index < 0 || index >= STEPS.length) {
    return '-';
  }
  return STEPS[index];
}

function allSteps() {
  return [...STEPS];
}

module.exports = {
  stepIndex,
  stepLabel,
  allSteps,
  STEPS
};
