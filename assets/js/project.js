/* Category and project pages: status filter chips (10) and the full-screen image lightbox (11). */
(function () {
  const KD = window.KD;
  const $ = (s, r = document) => r.querySelector(s);
  const $$ = (s, r = document) => [...r.querySelectorAll(s)];

  // ALL / ONGOING / COMPLETED / CONCEPT
  const chips = $$('.chips button');
  chips.forEach((chip) => chip.addEventListener('click', () => {
    chips.forEach((c) => c.setAttribute('aria-pressed', String(c === chip)));
    const want = chip.dataset.filter;
    $$('.cat-grid li').forEach((li) => { li.hidden = want !== 'all' && li.dataset.status !== want; });
  }));

  const reduce = KD.reduce;
  const clamp = (v) => Math.min(1, Math.max(0, v));

  // 11 completed project: scrolling walks through the front door into the interior
  const walk = $('.walk');
  if (walk && !reduce) {
    const out = $('.walk-out', walk), hint = $('.walk-hint', walk);
    const tick = () => {
      const r = walk.getBoundingClientRect();
      const p = clamp(-r.top / Math.max(1, r.height - innerHeight));
      out.style.transform = `scale(${(1 + p * p * 5).toFixed(3)})`;
      out.style.opacity = String(clamp(1 - (p - 0.55) / 0.35));
      if (hint) hint.style.opacity = String(clamp(1 - p * 3));
    };
    addEventListener('scroll', tick, { passive: true });
    if (KD.lenis) KD.lenis.on('scroll', tick);
    tick();
  }

  // 12 ongoing project: the stage line fills up to today and the drawing builds to match
  const stages = $('.stages.fill'), grow = $('.grow');
  if (stages) $$('li', stages).forEach((li, k) => li.style.setProperty('--i', k));
  if (grow) {
    const now = +grow.dataset.now;
    $$('g', grow).forEach((g) => {
      const step = +g.dataset.step;
      g.classList.add(step <= now ? 'built' : 'later');
      $$('path, circle', g).forEach((el, k) => { el.setAttribute('pathLength', '1'); el.style.transitionDelay = `${(step - 1) * 0.4 + k * 0.05}s`; });
    });
  }
  const io = new IntersectionObserver((es) => es.forEach((e) => { if (e.isIntersecting) { e.target.classList.add('in'); io.unobserve(e.target); } }), { threshold: 0.3 });
  [stages, grow].forEach((el) => el && (reduce ? el.classList.add('in') : io.observe(el)));

  // lightbox with arrows, keys and swipe
  const dlg = $('#lightbox');
  if (!dlg) return;
  const stage = $('.lightbox-stage', dlg), cap = $('.lb-cap', dlg), count = $('.lb-n', dlg);
  let items = [], i = 0, opener = null;
  const paint = () => {
    const src = items[i];
    stage.innerHTML = src.innerHTML;
    stage.querySelectorAll('img').forEach((im) => { im.loading = 'eager'; });
    cap.textContent = src.dataset.caption || '';
    count.textContent = `${i + 1} / ${items.length}`;
  };
  const step = (d) => { i = (i + d + items.length) % items.length; paint(); };
  $$('[data-lightbox]').forEach((btn) => btn.addEventListener('click', () => {
    items = $$(`[data-lightbox="${btn.dataset.lightbox}"]`);
    i = items.indexOf(btn);
    opener = btn;
    paint();
    dlg.showModal();
    KD.lock(true);
  }));
  $$('[data-step]', dlg).forEach((b) => b.addEventListener('click', () => step(+b.dataset.step)));
  $('.full-close', dlg).addEventListener('click', () => dlg.close());
  dlg.addEventListener('keydown', (e) => { if (e.key === 'ArrowRight') step(1); if (e.key === 'ArrowLeft') step(-1); });
  dlg.addEventListener('close', () => { KD.lock(false); opener?.focus(); });
  KD.onSwipe(stage, step);
})();
