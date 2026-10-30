/* The book on the About page: a realistic opening, then pages that curl and turn like paper.
   The page turns use StPageFlip (assets/vendor/page-flip-2.0.7.browser.js, MIT licence).
   The opening is a 3D sequence: the book lifts out of the page, the hard cover swings open on its
   hinge, and three leaves riffle over to the first spread, with light and shadow following each angle. */
(function () {
  const KD = window.KD, St = window.St;
  if (!St || !document.querySelector('#author')) return;
  KD.bookOwned = true;                       // home.js leaves the book alone when this file is present
  const reduce = KD.reduce;
  const $ = (s, r = document) => r.querySelector(s);
  const $$ = (s, r = document) => [...r.querySelectorAll(s)];
  const BASE = $('meta[name="kd-base"]')?.content || '';
  const B = BASE + 'assets/book/';
  const RATIO = 865 / 560;                   // page height / width
  const clamp = (v, a = 0, b = 1) => Math.min(b, Math.max(a, v));
  const ease = (t) => (t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2);
  const easeOut = (t) => 1 - Math.pow(1 - t, 3);
  const lerp = (a, b, t) => a + (b - a) * t;

  const BOOK = [
    ['book-p15', 'Introduction, first page'], ['book-p16', 'Introduction, second page'],
    ['book-p17', 'Chapter 1, Before I Learned to Build on Paper, opening page'], ['book-p18', 'Chapter 1, second page'],
    ['book-p191', 'Chapter 13, The 100 Decisions, opening page'], ['book-p192', 'Chapter 13, decisions 1 to 6'],
  ];
  const BOOK_CAPS = ['Introduction · Why your home should be built on paper first', 'Chapter 1 · Before I learned to build on paper', 'Chapter 13 · The 100 decisions, decisions 1–6'];
  const HANDBOOKS = {
    building: { title: 'Building with Intention', spread: 'Pages 17 and 58', ratio: 449 / 640, pages: [['building-p1', 'Building with Intention, cover'], ['building-p17', 'Building with Intention, page 17: Where great spaces begin'], ['building-p58', 'Building with Intention, page 58: The journey now divides into two parallel paths']] },
    craft: { title: 'Craft with Intention', spread: 'Pages 14 and 20', ratio: 449 / 640, pages: [['craft-p1', 'Craft with Intention, cover'], ['craft-p14', 'Craft with Intention, page 14: Where your interior journey begins'], ['craft-p20', 'Craft with Intention, page 20: Designing one space at a time']] },
  };

  // one page as StPageFlip expects it, with the gutter shadow a real book has near the spine
  const page = ([n, alt], density = 'soft') => {
    const el = document.createElement('div');
    el.className = 'leafpage';
    el.dataset.density = density;
    el.innerHTML = `<picture><source srcset="${B}${n}.webp" type="image/webp"><img src="${B}${n}.jpg" alt="${alt}" draggable="false"></picture><i class="gutter" aria-hidden="true"></i>`;
    return el;
  };
  const blank = (cls, density = 'hard') => { const el = document.createElement('div'); el.className = `leafpage ${cls}`; el.dataset.density = density; el.innerHTML = '<i class="gutter" aria-hidden="true"></i>'; return el; };

  function makeFlip(host, pages, opts) {
    host.innerHTML = '';
    const book = document.createElement('div');
    host.appendChild(book);
    pages.forEach((p) => book.appendChild(p));
    const pf = new St.PageFlip(book, {
      width: opts.w, height: opts.h, size: 'stretch',
      minWidth: 120, maxWidth: opts.w, minHeight: 120 * (opts.h / opts.w), maxHeight: opts.h,
      showCover: !!opts.cover, usePortrait: true, mobileScrollSupport: true,
      drawShadow: true, maxShadowOpacity: 0.55, flippingTime: reduce ? 1 : 900,
      showPageCorners: !reduce, startPage: opts.start || 0, autoSize: true,
    });
    pf.loadFromHTML(pages);
    return pf;
  }

  // the caption and "1 / 3" under a viewer follow the spread on show
  function bar(root, capFor, total) {
    const cap = $('.viewer-bar > .cap', root), n = $('.n', root), t = $('.t', root);
    t.textContent = total;
    return (spread) => { cap.textContent = capFor(spread); n.textContent = spread + 1; };
  }
  const barHTML = (label) => `<div class="viewer-bar"><p class="cap"></p><div class="viewer-nav">
      <button type="button" class="circle-btn" data-dir="-1" aria-label="Previous ${label}">←</button>
      <span class="cap"><b class="n">1</b> / <span class="t"></span></span>
      <button type="button" class="circle-btn" data-dir="1" aria-label="Next ${label}">→</button></div></div>`;

  /* ---------- the spread on the page itself ---------- */
  const inline = $('#book-viewer');
  if (inline) {
    inline.innerHTML = `<div class="flip-host inline-host"></div>${barHTML('spread')}`;
    const pf = makeFlip($('.flip-host', inline), BOOK.map((p) => page(p)), { w: 285, h: 440 });
    const show = bar(inline, (s) => BOOK_CAPS[s], BOOK_CAPS.length);
    show(0);
    pf.on('flip', (e) => show(Math.min(2, Math.floor(e.data / 2))));
    $$('[data-dir]', inline).forEach((b) => b.addEventListener('click', () => (+b.dataset.dir > 0 ? pf.flipNext() : pf.flipPrev())));
    let inView = false;
    new IntersectionObserver(([e]) => { inView = e.isIntersecting; }, { threshold: 0.4 }).observe(inline);
    addEventListener('keydown', (e) => {
      if (!inView || $('dialog[open]')) return;
      if (e.key === 'ArrowRight') pf.flipNext();
      if (e.key === 'ArrowLeft') pf.flipPrev();
    });
  }

  /* ---------- the reading room: full screen, with the opening ---------- */
  const dlg = document.createElement('dialog');
  dlg.className = 'full reading tx';
  dlg.dataset.cursor = 'light';
  dlg.setAttribute('aria-labelledby', 'reading-title');
  dlg.innerHTML = `<div class="full-top"><span id="reading-title" class="cap cap-gold"></span><button class="full-close cap link-cap" type="button">Close ×</button></div>
    <div class="reading-stage"><div class="flip-host big-host"></div></div>${barHTML('spread')}`;
  document.body.appendChild(dlg);
  const stage = $('.reading-stage', dlg), host = $('.big-host', dlg), title = $('#reading-title', dlg);
  let pf = null, opener = null, which = null;

  // the largest page that fits two-up in the room
  const fit = (ratio) => {
    const r = stage.getBoundingClientRect();
    const two = innerWidth >= 768;
    let w = (r.width * 0.96) / (two ? 2 : 1);
    let h = w * ratio;
    if (h > r.height * 0.96) { h = r.height * 0.96; w = h / ratio; }
    return { w: Math.floor(w), h: Math.floor(h), two };
  };

  function build(kind) {
    if (pf) { pf.destroy(); pf = null; }
    host.innerHTML = '';
    const isBook = kind === 'book';
    const set = isBook ? null : HANDBOOKS[kind];
    const ratio = isBook ? RATIO : set.ratio;
    const g = fit(ratio);
    host.style.width = `${g.two ? g.w * 2 : g.w}px`;
    const pages = isBook
      ? [page(['book-cover-front', 'Cover of The 100 Decisions Before the First Brick'], 'hard'), ...BOOK.map((p) => page(p)), blank('backcover')]
      : [page(set.pages[0], 'hard'), page(set.pages[1]), page(set.pages[2])];
    pf = makeFlip(host, pages, { w: g.w, h: g.h, cover: true, start: isBook ? 1 : 0 });
    const caps = isBook ? ['The 100 Decisions Before the First Brick · Cover', ...BOOK_CAPS, 'Back cover'] : [`${set.title} · Cover`, `${set.title} · ${set.spread}`];
    const spreadOf = (i) => (i === 0 ? 0 : Math.ceil(i / 2));
    const show = bar(dlg, (s) => caps[s] || '', caps.length);
    show(spreadOf(isBook ? 1 : 0));
    pf.on('flip', (e) => show(spreadOf(e.data)));
    return g;
  }
  $$('[data-dir]', dlg).forEach((b) => b.addEventListener('click', () => (+b.dataset.dir > 0 ? pf?.flipNext() : pf?.flipPrev())));
  dlg.addEventListener('keydown', (e) => { if (e.key === 'ArrowRight') pf?.flipNext(); if (e.key === 'ArrowLeft') pf?.flipPrev(); });
  $('.full-close', dlg).addEventListener('click', () => close());
  dlg.addEventListener('cancel', (e) => { e.preventDefault(); close(); });
  addEventListener('resize', () => { if (dlg.open && which) build(which); });

  function close() {
    dlg.classList.add('closing');
    setTimeout(() => { dlg.close(); dlg.classList.remove('closing', 'ready'); KD.lock(false); opener?.focus(); }, reduce ? 0 : 420);
  }

  function open(kind, btn) {
    opener = btn; which = kind;
    title.textContent = kind === 'book' ? 'The 100 Decisions Before the First Brick' : HANDBOOKS[kind].title;
    dlg.classList.remove('ready');
    dlg.showModal();
    KD.lock(true);
    const g = build(kind);
    if (kind !== 'book' || reduce || !g.two) { dlg.classList.add('ready'); return; }
    playOpening(g);
  }

  /* ---------- the opening ---------- */
  function playOpening(g) {
    const W = g.w, H = g.h, T = Math.max(10, Math.round(W * 0.055));        // page size and the thickness of the page block
    const src = $('.book3d');
    const s = src ? src.getBoundingClientRect() : null;
    const hostR = host.getBoundingClientRect();
    const cx = hostR.left + hostR.width / 2, cy = hostR.top + H / 2;

    const img = (n) => `url('${B}${n}.jpg')`;
    const ob = document.createElement('div');
    ob.className = 'ob';
    ob.style.cssText = `--W:${W}px;--H:${H}px;--T:${T}px;left:${cx - W}px;top:${cy - H / 2}px`;
    // stack, from the bottom up: the right page (p16), three leaves, the cover; the inside of the back board on the left
    ob.innerHTML = `
      <div class="ob-floor"></div>
      <div class="ob-right"><div class="ob-face" style="background-image:${img('book-p16')}"></div><i class="ob-gutter r"></i><i class="ob-cast"></i></div>
      <div class="ob-block"></div>
      ${[0, 1, 2].map((k) => `<div class="ob-leaf" data-k="${k}"><div class="ob-half in"><div class="ob-face f"></div><div class="ob-face b" ${k === 2 ? `style="background-image:${img('book-p15')};background-position:100% 0"` : ''}></div>
        <div class="ob-half out"><div class="ob-face f"></div><div class="ob-face b" ${k === 2 ? `style="background-image:${img('book-p15')};background-position:0 0"` : ''}></div></div></div></div>`).join('')}
      <div class="ob-cover"><div class="ob-face f" style="background-image:${img('book-cover-front')}"></div><div class="ob-face b endpaper"></div><i class="ob-light"></i><i class="ob-edge"></i></div>`;
    dlg.appendChild(ob);               // inside the dialog, which sits in the top layer above the page
    const cover = $('.ob-cover', ob), leaves = $$('.ob-leaf', ob), cast = $('.ob-cast', ob), light = $('.ob-light', ob);

    // where it starts: the small book on the page, at its own size and angle
    const rightCx = cx + W / 2;
    const sx = s ? s.left + s.width / 2 - rightCx : 0, sy = s ? s.top + s.height / 2 - cy : innerHeight * 0.3;
    const s0 = s ? Math.max(0.2, s.height / H) : 0.4;

    const D = { fly: 900, cover: 1250, coverAt: 650, leaf: 620, leafAt: 1650, leafGap: 150 };
    const total = D.leafAt + D.leafGap * 2 + D.leaf + 120;
    const t0 = performance.now();
    if (src) src.style.visibility = 'hidden';

    function frame(now) {
      const t = now - t0;
      // 1. the book lifts off the page and comes to the centre, turning to face you
      const f = ease(clamp(t / D.fly));
      // 2. the cover swings open on its hinge
      const c = ease(clamp((t - D.coverAt) / D.cover));
      const coverA = -180 * c;
      // the camera slides so the open spread ends up centred
      const camX = lerp(-W / 2, 0, ease(clamp((t - D.coverAt) / (D.cover * 0.9))));
      const scale = lerp(s0, 1, f);
      const ry = lerp(-28, 0, f), rx = lerp(14, 0, f);
      ob.style.transform = `translate(${lerp(sx, camX, f)}px, ${lerp(sy, 0, f)}px) perspective(2400px) rotateX(${rx}deg) rotateY(${ry}deg) scale(${scale})`;
      ob.style.setProperty('--lift', (Math.sin(f * Math.PI) * 0.6 + (1 - f) * 0.2).toFixed(3));
      cover.style.transform = `translateZ(${lerp(2.5, 0.2, c).toFixed(2)}px) rotateY(${coverA}deg)`;
      // light: the cover darkens as it turns from the lamp; its shadow sweeps across the first page
      const rad = (-coverA * Math.PI) / 180;
      light.style.opacity = (Math.sin(rad / 2) * 0.55).toFixed(3);
      // 3. three leaves riffle over, each bending as it goes, landing on the first spread
      let castO = Math.sin(rad) * 0.5;
      leaves.forEach((leaf, k) => {
        const p = easeOut(clamp((t - D.leafAt - k * D.leafGap) / D.leaf));
        const a = -180 * p;
        const bend = Math.sin(p * Math.PI) * 26;          // the free edge trails behind, so the paper curves
        // a leaf lifts while it turns and lands on top of the ones already turned
        leaf.style.transform = `translateZ(${(lerp((3 - k) * 0.4, 2 + k * 0.4, p) + Math.sin(p * Math.PI) * 6).toFixed(2)}px) rotateY(${a}deg)`;
        leaf.firstElementChild.lastElementChild.style.transform = `rotateY(${bend}deg)`;
        leaf.style.setProperty('--sh', (Math.sin(p * Math.PI) * 0.35).toFixed(3));
        castO = Math.max(castO, Math.sin(p * Math.PI) * 0.4);
      });
      cast.style.opacity = castO.toFixed(3);
      if (t < total) requestAnimationFrame(frame);
      else {
        // the real book takes over at exactly the same spread
        dlg.classList.add('ready');
        ob.classList.add('done');
        setTimeout(() => { ob.remove(); if (src) src.style.visibility = ''; }, 380);
      }
    }
    requestAnimationFrame(frame);
  }

  // the small book, READ A SAMPLE and the handbooks' VIEW PAGES all open the reading room
  $$('[data-pages]').forEach((b) => b.addEventListener('click', () => setTimeout(() => open(b.dataset.pages, b), reduce ? 0 : 200)));
})();
