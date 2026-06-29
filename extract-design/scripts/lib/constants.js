export const SURFACE_LEVELS = ['surface','surface-dim','surface-bright','surface-container-lowest','surface-container-low','surface-container','surface-container-high','surface-container-highest'];
export const COLOR_ROLES = ['primary','on-primary','primary-container','on-primary-container','secondary','on-secondary','secondary-container','on-secondary-container','tertiary','on-tertiary','tertiary-container','on-tertiary-container','error','on-error','error-container','on-error-container','surface','on-surface','surface-variant','on-surface-variant','outline','outline-variant','inverse-surface','inverse-on-surface','inverse-primary','background','on-background'];
export const TYPOGRAPHY_LEVELS = ['display-lg','display-md','display-sm','headline-lg','headline-md','headline-sm','title-lg','title-md','title-sm','body-lg','body-md','body-sm','label-lg','label-md','label-sm'];
export const CHROME_CI_FLAGS = ['--headless=new','--no-sandbox','--disable-gpu','--disable-dbus','--use-gl=angle','--use-angle=swiftshader'];
export const TIMEOUTS = { PAGE_LOAD_MS: 30_000, PSEUDO_STATE_MS: 10_000 };
export const RETRY_CONFIG = { MAX_ATTEMPTS: 3, BASE_DELAY_MS: 1_000 };
export const COVERAGE_MINIMUMS = { MIN_COLORS: 2, MIN_TYPOGRAPHY_LEVELS: 1 };
export const OUTPUT_PATH = 'specs/tech-architecture/DESIGN_LATEST.md';
export const AGENT_NOTE_LOW_CONFIDENCE = '<!-- AGENT NOTE: Generated from visual analysis. Grill-me should validate. -->';
