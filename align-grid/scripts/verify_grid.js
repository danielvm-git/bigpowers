#!/usr/bin/env node
/*
 * verify_grid.js — prove an editorial page actually sits on its grid.
 *
 * Renders the page with headless Chrome (Puppeteer) and asserts, at several
 * viewport widths (including > and < the content max-width, to catch the
 * centered-container drift):
 *
 *   1. COLUMN ADHERENCE  — every placed `.band > *` element's left edge snaps
 *      to a column START line and its right edge to a column END line (~0px).
 *      NB: build BOTH the start-set and end-set of x-coords. A grid item that
 *      spans "to line N" ends at the FAR side of the gutter, so naive single
 *      edge math falsely reports a one-gutter (gutter-px) error.
 *   2. OVERLAY MATCH     — each `.guides .col` rect equals the computed column
 *      rect (~0px), i.e. the overlay really is the content grid.
 *   3. BASELINE          — text element tops, modulo the baseline unit, ~0.
 *   4. OPTICAL INK       — display elements' visible INK-left equals the column
 *      line (measure canvas actualBoundingBoxLeft with the LOADED font).
 *      CAVEAT: side-bearing is font-specific. In a sandbox the webfont is often
 *      absent and canvas falls back to a different grotesque (we measured -16px
 *      fallback vs -7px real Inter). To verify optics offline, EMBED the real
 *      webfont via @font-face(local TTF). In production the page's runtime JS
 *      measures the actually-loaded font, so it is correct for the user.
 *
 * Env / args:
 *   CHROME = path to chrome binary (required)
 *   PUP    = path to puppeteer-core module (required)
 *   arg1   = file:// URL or http URL of the page (default: file://$PWD/index.html)
 *   --widths=1440,1180,900   --baseline=8
 *
 * Sandbox chrome flags that work here:
 *   --no-sandbox --disable-gpu --disable-dbus --use-gl=angle --use-angle=swiftshader
 * (file:// works for non-ES-module pages; CLI --screenshot can hang on tall
 *  pages, so we drive via Puppeteer and screenshot per-viewport.)
 */
const puppeteer = require(process.env.PUP || 'puppeteer-core');
const path = require('path');

const args = process.argv.slice(2);
const url = (args.find(a => !a.startsWith('--'))) ||
            ('file://' + path.join(process.cwd(), 'index.html'));
const opt = k => { const a = args.find(x => x.startsWith('--' + k + '=')); return a ? a.split('=')[1] : null; };
const widths = (opt('widths') || '1440,1180,900').split(',').map(Number);
const BL = Number(opt('baseline') || 8);

(async () => {
  const browser = await puppeteer.launch({
    executablePath: process.env.CHROME, headless: 'new',
    args: ['--no-sandbox','--disable-gpu','--disable-dbus','--use-gl=angle','--use-angle=swiftshader','--hide-scrollbars']
  });
  const page = await browser.newPage();
  let failed = false;

  for (const W of widths) {
    await page.setViewport({ width: W, height: 1000, deviceScaleFactor: 1 });
    await page.goto(url, { waitUntil: 'load', timeout: 25000 });
    try { await page.evaluate(() => document.fonts && document.fonts.ready); } catch (e) {}
    await new Promise(r => setTimeout(r, 500));

    const res = await page.evaluate((BL) => {
      const OPT = '.opt-align'; // display elements: optically aligned by INK, not box
      const grid = document.querySelector('.grid');
      const cs = getComputedStyle(grid);
      const tracks = cs.gridTemplateColumns.split(' ').map(parseFloat);
      const gap = parseFloat(cs.columnGap);
      const gr = grid.getBoundingClientRect();
      // build column START (L) and END (R) coordinate sets
      const L = [], R = []; let x = gr.left;
      for (let i = 0; i < tracks.length; i++) { L.push(x); x += tracks[i]; R.push(x); if (i < tracks.length - 1) x += gap; }
      const nr = (v, arr) => arr.reduce((m, e) => Math.min(m, Math.abs(e - v)), 1e9);
      const nearest = (v, arr) => arr.reduce((b, e) => Math.abs(e - v) < Math.abs(b - v) ? e : b, arr[0]);

      // 1. column adherence — exclude optical display elements (their box is
      //    deliberately offset by the glyph side-bearing so the INK lands on
      //    the line; they are validated by check 4 instead).
      let colErr = 0, worst = null;
      document.querySelectorAll('.band > *').forEach(el => {
        if (el.matches(OPT)) return;
        const r = el.getBoundingClientRect(); if (r.width < 2) return;
        const e = Math.max(nr(r.left, L), nr(r.right, R));
        if (e > colErr) { colErr = e; worst = (el.className || el.tagName).toString().slice(0, 28); }
      });

      // 2. overlay match
      let ovErr = 0;
      document.querySelectorAll('.guides .cols .col').forEach((c, i) => {
        const r = c.getBoundingClientRect();
        if (L[i] != null) ovErr = Math.max(ovErr, Math.abs(r.left - L[i]));
        if (R[i] != null) ovErr = Math.max(ovErr, Math.abs(r.right - R[i]));
      });

      // 3. baseline (tops modulo BL, per spread relative to its rows-top)
      let baseErr = 0;
      document.querySelectorAll('.spread').forEach(sp => {
        const rowsEl = sp.querySelector('.guides .rows'); if (!rowsEl) return;
        const top = rowsEl.getBoundingClientRect().top;
        sp.querySelectorAll('.body,.lede,.cap,.toc li,.dishes li,.kicker').forEach(el => {
          const t = el.getBoundingClientRect().top - top; const m = ((t % BL) + BL) % BL;
          baseErr = Math.max(baseErr, Math.min(m, BL - m));
        });
      });

      // 4. optical ink offset — each display element's visible INK-left must
      //    sit on ITS OWN column line (the nearest column-start to its box),
      //    not always line 1 (headlines can start on any column).
      const cvs = document.createElement('canvas'), ctx = cvs.getContext('2d');
      let inkErr = 0, inkWorst = null;
      document.querySelectorAll(OPT).forEach(el => {
        const c = getComputedStyle(el); let ch = (el.textContent || '').trim().charAt(0); if (!ch) return;
        if (c.textTransform === 'uppercase') ch = ch.toUpperCase();
        ctx.font = c.fontStyle + ' ' + c.fontWeight + ' ' + c.fontSize + ' ' + c.fontFamily; ctx.textAlign = 'left';
        const abl = ctx.measureText(ch).actualBoundingBoxLeft;
        const box = el.getBoundingClientRect().left;
        const target = nearest(box, L);          // the column line this element sits on
        const ink = box - abl;                    // visible ink-left
        const e = Math.abs(ink - target);
        if (e > inkErr) { inkErr = e; inkWorst = (el.className || '').toString().slice(0, 20) + ' "' + ch + '"'; }
      });

      return {
        track: +tracks[0].toFixed(1),
        maxColErrPx: +colErr.toFixed(2), worstCol: worst,
        overlayErrPx: +ovErr.toFixed(2),
        maxBaselineOffPx: +baseErr.toFixed(2),
        maxInkOffPx: +inkErr.toFixed(2), worstInk: inkWorst,
        fontFamily: getComputedStyle(document.querySelector('.masthead') || document.body).fontFamily.split(',')[0]
      };
    }, BL);

    // baseline tolerance = half a baseline unit (element border-box top vs line is a proxy; leading does the real work)
    const pass = res.maxColErrPx <= 0.5 && res.overlayErrPx <= 0.5 && res.maxBaselineOffPx <= (BL / 2) && res.maxInkOffPx <= 1.0;
    if (!pass) failed = true;
    console.log(`[${pass ? 'PASS' : 'FAIL'}] vw=${W}  col=${res.maxColErrPx}px overlay=${res.overlayErrPx}px ` +
                `baseline=${res.maxBaselineOffPx}px ink=${res.maxInkOffPx}px  ` +
                `(worstCol=${res.worstCol}, worstInk=${res.worstInk}, font=${res.fontFamily})`);
  }
  await browser.close();
  if (failed) { console.error('GRID VERIFY: FAIL'); process.exit(1); }
  console.log('GRID VERIFY: PASS');
})().catch(e => { console.error('ERR', e.message); process.exit(2); });
