// Browser sensor — collects computed styles inside Puppeteer page.
// Returns raw JSON. No classification logic here.

export function collect(page) {
  return page.evaluate(() => {
    const styles = [];
    const title = document.title || '';

    // Collect computed styles from every visible element
    document.querySelectorAll('body, body *').forEach(el => {
      const cs = getComputedStyle(el);
      const tag = el.tagName.toLowerCase();
      const rect = el.getBoundingClientRect();

      if (rect.width === 0 && rect.height === 0 && tag !== 'body') return;

      styles.push({
        tag,
        text: (el.textContent || '').trim().slice(0, 100),
        backgroundColor: cs.backgroundColor,
        color: cs.color,
        borderColor: cs.borderColor,
        fontFamily: cs.fontFamily,
        fontSize: cs.fontSize,
        fontWeight: cs.fontWeight,
        lineHeight: cs.lineHeight,
        letterSpacing: cs.letterSpacing,
        padding: cs.padding,
        margin: cs.margin,
        gap: cs.gap,
        borderRadius: cs.borderRadius,
        boxShadow: cs.boxShadow,
        backdropFilter: cs.backdropFilter,
        cursor: cs.cursor,
        zIndex: cs.zIndex,
        width: rect.width,
        height: rect.height,
        isButton: tag === 'button' || el.getAttribute('role') === 'button',
        isInput: tag === 'input' || tag === 'textarea' || tag === 'select',
        isHeading: /^h[1-6]$/.test(tag),
      });
    });

    // Collect declared fonts from <link> tags
    const declaredFonts = [];
    document.querySelectorAll('link[rel="stylesheet"]').forEach(l => {
      declaredFonts.push(l.href);
    });

    // Collect @font-face declarations from stylesheets
    const fontFaceFamilies = new Set();
    try {
      for (const sheet of document.styleSheets) {
        try {
          for (const rule of sheet.cssRules || []) {
            if (rule.constructor.name === 'CSSFontFaceRule' && rule.style) {
              const family = rule.style.getPropertyValue('font-family');
              if (family) fontFaceFamilies.add(family.replace(/['"]/g, '').trim());
            }
          }
        } catch {
          // Cross-origin stylesheets can't be inspected — skip
        }
      }
    } catch {
      // Some browsers throw on styleSheets access — skip
    }

    return { title, styles, declaredFonts, fontFaceFamilies: [...fontFaceFamilies] };
  });
}

/**
 * Collect pseudo-state variants for detected component elements.
 * Forces :hover state and reads computed styles.
 * @param {Object} page — Puppeteer page
 * @param {Array<Object>} componentStyles — array of { styleSignature, componentName }
 * @returns {Promise<Record<string, Object>>} — variant component tokens
 */
export async function collectPseudoStates(page, componentStyles) {
  const variants = {};

  for (const comp of componentStyles) {
    // Hover state
    try {
      const hoverStyles = await page.evaluate((signature) => {
        const elements = document.querySelectorAll('body, body *');
        for (const el of elements) {
          const cs = getComputedStyle(el);
          const bg = cs.backgroundColor;
          const rect = el.getBoundingClientRect();
          const w = Math.round(rect.width);
          const h = Math.round(rect.height);

          if (bg === signature.bg &&
              Math.abs(w - signature.width) < 10 &&
              Math.abs(h - signature.height) < 10) {
            return {
              index: Array.from(document.querySelectorAll('body, body *')).indexOf(el),
              exists: true,
            };
          }
        }
        return { exists: false };
      }, { bg: comp.backgroundColor, width: comp.width || 0, height: comp.height || 0 });

      if (hoverStyles.exists) {
        // Use Puppeteer's hover API (not page.evaluate for pseudo-classes)
        const elements = await page.$$('body, body *');
        const el = elements[hoverStyles.index];
        if (el) {
          await el.hover();
          await page.waitForTimeout(100); // Wait for transition

          const hoverComputed = await page.evaluate((idx) => {
            const els = document.querySelectorAll('body, body *');
            const target = els[idx];
            if (!target) return null;
            const cs = getComputedStyle(target);
            return { backgroundColor: cs.backgroundColor, color: cs.color, borderColor: cs.borderColor, boxShadow: cs.boxShadow };
          }, hoverStyles.index);

          if (hoverComputed) {
            const changed = {};
            if (hoverComputed.backgroundColor !== comp.backgroundColor && hoverComputed.backgroundColor !== 'rgba(0, 0, 0, 0)') {
              changed.backgroundColor = hoverComputed.backgroundColor;
            }
            if (hoverComputed.color !== comp.textColor) {
              changed.textColor = hoverComputed.color;
            }
            if (hoverComputed.borderColor !== comp.borderColor) {
              changed.borderColor = hoverComputed.borderColor;
            }
            if (Object.keys(changed).length > 0) {
              variants[`${comp.componentName}-hover`] = changed;
            }
          }

          // Move mouse away to reset
          await page.mouse.move(0, 0);
        }
      }
    } catch {
      // Pseudo-state detection is best-effort. Skip on failure.
    }
  }

  return variants;
}
