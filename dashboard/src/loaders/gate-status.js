const COLOR_MAP = {
  ready: 'green',
  blocked: 'red',
  in_progress: 'yellow',
  done: 'green',
  pending: 'dim',
  active: 'cyan'
};

const ICON_MAP = {
  ready: '●',
  blocked: '✕',
  in_progress: '◐',
  done: '✓',
  pending: '○',
  active: '◐'
};

function gateColor(gateStatus) {
  return COLOR_MAP[gateStatus] || 'dim';
}

function gateIcon(gateStatus) {
  return ICON_MAP[gateStatus] || '-';
}

module.exports = {
  gateColor,
  gateIcon,
  COLOR_MAP,
  ICON_MAP
};
