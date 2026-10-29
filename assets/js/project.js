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
