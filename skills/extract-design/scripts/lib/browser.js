// BrowserExtractor — wraps Puppeteer behind a project-owned interface.
// Uses collect-styles.js for the browser-side sensor logic.

import { log } from './logging.js';
import { withRetry, withTimeout } from './retry.js';
import { collect, collectPseudoStates } from '../collect-styles.js';
import { CHROME_CI_FLAGS, TIMEOUTS } from './constants.js';

export class BrowserExtractor {
  constructor({ puppeteer, chromePath, chromeFlags = [] }) {
    this._puppeteer = puppeteer;
    this._chromePath = chromePath;
    this._chromeFlags = [...CHROME_CI_FLAGS, ...chromeFlags];
    this._browser = null;
    this._page = null;
  }

  /**
   * Launch Chrome and extract styles with dual-pass (light + dark).
   * Also collects pseudo-state variants and font declarations.
   * @param {string} source — file path or URL
   * @returns {Promise<Object>} — { light, dark (nullable), pseudoVariants, fontWarnings }
   */
  async extract(source) {
    log.info('extraction-start', { source, timestamp: new Date().toISOString() });

    try {
      await this._launch();
      const page = await this._openPage(source);
      this._page = page;

      // Light mode pass
      const light = await collect(page);
      log.info('page-loaded', {
        colorCount: Object.keys(light.colors || {}).length,
        styleCount: (light.styles || []).length,
        declaredFonts: light.declaredFonts?.length || 0,
        fontFaceFamilies: light.fontFaceFamilies?.length || 0,
      });

      // Font declared-vs-computed check
      const fontWarnings = this._checkFontDeclarations(light);

      // Dark mode pass
      await this._setColorScheme(page, 'dark');
      const dark = await collect(page);
      const darkDiffers = this._colorsDiffer(light.styles, dark.styles);
      log.info('dark-mode-check', { darkDiffers, darkStyleCount: (dark.styles || []).length });

      return {
        light,
        dark: darkDiffers ? dark : null,
        fontWarnings,
      };
    } finally {
      await this.close();
    }
  }

  /**
   * Detect pseudo-state variants (:hover) for detected components.
   * Must be called while the page is still open (before close()).
   * @param {Array<Object>} components — component objects with backgroundColor, textColor, width, height, componentName
   * @returns {Promise<Record<string, Object>>}
   */
  async detectPseudoStates(components) {
    if (!this._page) return {};
    log.info('pseudo-states', { componentCount: components.length });
    return collectPseudoStates(this._page, components);
  }

  async _launch() {
    const opts = { headless: true, args: this._chromeFlags };
    if (this._chromePath) opts.executablePath = this._chromePath;

    try {
      this._browser = await this._puppeteer.launch(opts);
      log.info('browser-launched');
    } catch (err) {
      if (err.message.includes('chrome') || err.message.includes('Chromium') || err.message.includes('executable')) {
        throw new Error(
          `Chrome/Chromium not found. Install Puppeteer with: npm install puppeteer\n` +
          `Or set CHROME_PATH env var to your Chrome binary. Error: ${err.message}`
        );
      }
      throw err;
    }
  }

  async _openPage(source) {
    const page = await this._browser.newPage();
    await page.setViewport({ width: 1440, height: 900 });

    const goto = () => {
      // Determine if source is a URL or file path
      const isUrl = source.startsWith('http://') || source.startsWith('https://');
      const target = isUrl ? source : `file://${source}`;
      return page.goto(target, {
        waitUntil: 'networkidle0',
        timeout: TIMEOUTS.PAGE_LOAD_MS,
      });
    };

    try {
      await withTimeout(() => withRetry(goto), TIMEOUTS.PAGE_LOAD_MS + 5000);
    } catch (err) {
      if (err.message.includes('Timeout') || err.message.includes('timed out')) {
        throw new Error(
          `Page load timed out after ${TIMEOUTS.PAGE_LOAD_MS}ms.\n` +
          `The prototype may be a SPA or have slow network requests. Error: ${err.message}`
        );
      }
      throw err;
    }

    return page;
  }

  async _setColorScheme(page, mode) {
    await page.emulateMediaFeatures([{ name: 'prefers-color-scheme', value: mode }]);
    await page.evaluate(() => new Promise(r => requestAnimationFrame(r)));
  }

  /**
   * Compare declared fonts (from <link> + @font-face) against computed fontFamily.
   * Returns warnings for fonts that were declared but not rendered.
   */
  _checkFontDeclarations(extraction) {
    const warnings = [];
    const declared = new Set();

    // Parse font names from Google Fonts URLs
    for (const url of (extraction.declaredFonts || [])) {
      const match = url.match(/family=([^:&]+)/);
      if (match) {
        for (const fam of decodeURIComponent(match[1]).split('|')) {
          declared.add(fam.trim());
        }
      }
    }

    // Add @font-face families
    for (const fam of (extraction.fontFaceFamilies || [])) {
      declared.add(fam);
    }

    if (declared.size === 0) return warnings;

    // Get all computed font families
    const computedFamilies = new Set();
    for (const style of (extraction.styles || [])) {
      if (style.fontFamily) {
        // fontFamily may be a stack like "Inter, sans-serif" — take first
        computedFamilies.add(style.fontFamily.split(',')[0].replace(/['"]/g, '').trim());
      }
    }

    // Check each declared font
    for (const font of declared) {
      const found = [...computedFamilies].some(cf =>
        cf.toLowerCase() === font.toLowerCase() ||
        cf.toLowerCase().includes(font.toLowerCase())
      );
      if (!found) {
        warnings.push(
          `Font "${font}" was declared in <link>/@font-face but not rendered. ` +
          `Check font loading (CDN may be blocked, or font name mismatch). ` +
          `Computed fonts: ${[...computedFamilies].join(', ')}`
        );
      }
    }

    if (warnings.length > 0) {
      log.warn('font-mismatch', { declaredCount: declared.size, computedCount: computedFamilies.size, warnings });
    }

    return warnings;
  }

  _colorsDiffer(lightStyles, darkStyles) {
    const lightColors = new Set();
    const darkColors = new Set();

    for (const s of (lightStyles || [])) {
      if (s.backgroundColor && s.backgroundColor !== 'rgba(0, 0, 0, 0)') lightColors.add(s.backgroundColor);
      if (s.color && s.color !== 'rgba(0, 0, 0, 0)') lightColors.add(s.color);
    }
    for (const s of (darkStyles || [])) {
      if (s.backgroundColor && s.backgroundColor !== 'rgba(0, 0, 0, 0)') darkColors.add(s.backgroundColor);
      if (s.color && s.color !== 'rgba(0, 0, 0, 0)') darkColors.add(s.color);
    }

    return JSON.stringify([...lightColors].sort()) !== JSON.stringify([...darkColors].sort());
  }

  async close() {
    if (this._page) {
      this._page = null;
    }
    if (this._browser) {
      await this._browser.close();
      this._browser = null;
      log.info('browser-closed');
    }
  }
}
