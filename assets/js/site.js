/* Shared behaviour for every page. Section numbers refer to docs/KARUKRIT_WEBSITE_SPEC.md. */
(function () {
  const KD = (window.KD = window.KD || {});
  const reduce = matchMedia('(prefers-reduced-motion: reduce)').matches;
  const mouse = matchMedia('(hover: hover) and (pointer: fine)').matches;
  const desktop = matchMedia('(min-width: 1200px)');
  KD.reduce = reduce;
  KD.mouse = mouse;

  const store = {
    get(k) { try { return localStorage.getItem(k); } catch (e) { return null; } },
    set(k, v) { try { localStorage.setItem(k, v); } catch (e) { /* private mode */ } },
  };
  KD.store = store;

  // a surface is "dark" when its nearest data-cursor ancestor says light (moss, burnt orange, dark images)
  const onDark = (el) => { const s = el && el.closest && el.closest('[data-cursor]'); return !!s && s.dataset.cursor === 'light'; };
  KD.onDark = onDark;

  /* ---------- 4 smooth scroll, with gentle snapping between chapters on desktop ---------- */
  let lenis = null;
  if (!reduce && window.Lenis) {
    lenis = new window.Lenis({ duration: 1.1, smoothWheel: true });
    const raf = (t) => { lenis.raf(t); requestAnimationFrame(raf); };
    requestAnimationFrame(raf);
    let idle;
    lenis.on('scroll', () => {
      clearTimeout(idle);
      idle = setTimeout(snap, 160);
    });
  }
  KD.lenis = lenis;
  // proximity snap: settle on a chapter edge only when one is already close
  function snap() {
    if (!desktop.matches || !lenis || lenis.isStopped || KD.noSnap) return;
    const vh = innerHeight;
    let best = null;
    document.querySelectorAll('[data-snap]').forEach((el) => {
      const top = el.getBoundingClientRect().top;
      if (Math.abs(top) < vh * 0.18 && (!best || Math.abs(top) < Math.abs(best))) best = top;
    });
    if (best !== null && Math.abs(best) > 2) lenis.scrollTo(scrollY + best, { duration: 0.9 });
  }
  KD.scrollTo = (target) => {
    const el = typeof target === 'string' ? document.querySelector(target) : target;
    if (!el) return;
    if (lenis) lenis.scrollTo(el, { duration: 1.1 });
    else el.scrollIntoView({ behavior: reduce ? 'auto' : 'smooth' });
    if (el.id && history.replaceState) history.replaceState(null, '', '#' + el.id);
  };
  KD.lock = (on) => { if (lenis) on ? lenis.stop() : lenis.start(); document.documentElement.style.overflow = on ? 'hidden' : ''; };

  /* ---------- 5.3 sketched circle ---------- */
  function ringPath() {
    const n = 26, turn = 1.15;
    let d = '';
    for (let i = 0; i <= n; i++) {
      const a = -1.9 + (i / n) * Math.PI * 2 * turn;
      const j = 1 + (Math.random() - 0.5) * 0.08;
      const x = 50 + 48 * Math.cos(a) * j;
      const y = 50 + 44 * Math.sin(a) * j;
      d += (i ? 'L' : 'M') + x.toFixed(1) + ' ' + y.toFixed(1) + ' ';
    }
    return d;
  }
  function drawRing(el) {
    el.classList.add('ringable');
    el.querySelectorAll(':scope > svg.kd-ring').forEach((r) => r.remove());
    const colour = onDark(el) && !el.closest('.glass, .form-panel') ? '#DDB86E' : '#8B4729';
    const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
    svg.setAttribute('class', 'kd-ring');
    svg.setAttribute('viewBox', '0 0 100 100');
    svg.setAttribute('preserveAspectRatio', 'none');
    svg.setAttribute('aria-hidden', 'true');
    const p = document.createElementNS('http://www.w3.org/2000/svg', 'path');
    p.setAttribute('d', ringPath());
    p.setAttribute('vector-effect', 'non-scaling-stroke');
    p.style.cssText = `fill:none;stroke:${colour};stroke-width:1.3;stroke-linecap:round`;
    svg.appendChild(p);
    el.appendChild(svg);
    if (reduce) return;
    const L = p.getTotalLength();
    p.style.strokeDasharray = L;
    p.style.strokeDashoffset = L;
    p.getBoundingClientRect();
    p.style.transition = 'stroke-dashoffset .55s ease-out';
    p.style.strokeDashoffset = 0;
  }
  KD.drawRing = drawRing;
  const clearRings = (group) => group.querySelectorAll('svg.kd-ring').forEach((r) => r.remove());
  KD.clearRings = clearRings;

  // [data-ring] on a button or link draws the circle when clicked.
  // Inside [data-ring-group] the circle stays on the current item; links to other pages wait 350 ms.
  document.addEventListener('click', (e) => {
    const el = e.target.closest('[data-ring]');
    if (!el || e.defaultPrevented) return;
    const group = el.closest('[data-ring-group]');
    if (group) clearRings(group);
    drawRing(el);
    if (!group && el.tagName === 'BUTTON') setTimeout(() => el.querySelectorAll(':scope > svg.kd-ring').forEach((r) => r.remove()), 1600);
    const href = el.getAttribute('href');
    if (!href) return;
    if (href.startsWith('#')) {
      e.preventDefault();
      KD.scrollTo(href);
      KD.closeMenu && KD.closeMenu();
    } else if (!e.metaKey && !e.ctrlKey && !e.shiftKey && el.target !== '_blank' && !href.startsWith('tel:') && !href.startsWith('mailto:')) {
      e.preventDefault();
      setTimeout(() => { location.href = href; }, reduce ? 0 : 350);
    }
  });

  // plain in-page links scroll smoothly too
  document.addEventListener('click', (e) => {
    const a = e.target.closest('a[href^="#"]');
    if (!a || e.defaultPrevented || a.getAttribute('href').length < 2) return;
    e.preventDefault();
    KD.scrollTo(a.getAttribute('href'));
  });

  /* ---------- 5.2 pencil cursor ---------- */
  if (mouse) {
    const base = document.querySelector('meta[name="kd-base"]')?.content || '';
    const c = document.createElement('div');
    c.className = 'kd-cursor hidden';
    c.setAttribute('aria-hidden', 'true');
    c.innerHTML = `<img class="dark" src="${base}assets/cursor/pencil-cursor-dark.svg" alt=""><img class="light" src="${base}assets/cursor/pencil-cursor-light.svg" alt="">`;
    document.body.appendChild(c);
    document.documentElement.classList.add('kd-cursor-on');
    const hot = 'a, button, [role="tab"], label, select, summary, .tile';
    addEventListener('pointermove', (e) => {
      if (e.pointerType !== 'mouse') return;
      c.style.transform = `translate3d(${e.clientX - 3}px, ${e.clientY - 29}px, 0)`;
      c.classList.remove('hidden');
      const t = e.target;
      c.classList.toggle('on-dark', onDark(t) && !t.closest('.glass, .form-panel, .indicator ol'));
      c.classList.toggle('hot', !!(t.closest && t.closest(hot)));
    }, { passive: true });
    addEventListener('pointerdown', () => { c.classList.add('down'); setTimeout(() => c.classList.remove('down'), 100); });
    document.addEventListener('pointerleave', () => c.classList.add('hidden'));
  }

  /* ---------- 4 reveal on scroll, staggered by 80 ms within a group ---------- */
  const rvs = document.querySelectorAll('.rv');
  if (reduce || !('IntersectionObserver' in window)) rvs.forEach((el) => el.classList.add('in'));
  else {
    document.querySelectorAll('[data-stagger]').forEach((g) => g.querySelectorAll('.rv').forEach((el, i) => el.style.setProperty('--d', `${i * 0.08}s`)));
    const io = new IntersectionObserver((es) => es.forEach((e) => { if (e.isIntersecting) { e.target.classList.add('in'); io.unobserve(e.target); } }), { threshold: 0.12 });
    rvs.forEach((el) => io.observe(el));
  }

  /* ---------- 5.4 on touch screens the image in the middle of the screen turns to colour ---------- */
  if (!mouse && 'IntersectionObserver' in window) {
    const io = new IntersectionObserver((es) => es.forEach((e) => e.target.classList.toggle('is-colour', e.isIntersecting)), { threshold: 0.6, rootMargin: '-20% 0px -20% 0px' });
    document.querySelectorAll('.mono:not(.marq .mono)').forEach((el) => io.observe(el));
  }

  /* ---------- 4 slim header: appears after chapter I on the home page ---------- */
  const bar = document.querySelector('.topbar');
  const hero = document.querySelector('.hero');
  if (bar && hero && !bar.classList.contains('always') && !document.querySelector('.hero-scroll')) {
    const io = new IntersectionObserver(([e]) => bar.classList.toggle('show', !e.isIntersecting && e.boundingClientRect.top < 0), { threshold: 0.02 });
    io.observe(hero);
  }

  /* ---------- 14 phone menu ---------- */
  const mm = document.querySelector('.mobile-menu');
  if (mm) {
    let opener = null;
    const open = (btn) => { opener = btn; mm.classList.add('open'); mm.removeAttribute('inert'); KD.lock(true); mm.querySelector('a, button')?.focus(); };
    KD.closeMenu = () => { if (!mm.classList.contains('open')) return; mm.classList.remove('open'); mm.setAttribute('inert', ''); KD.lock(false); opener?.focus(); };
    document.querySelectorAll('.menu-btn').forEach((b) => b.addEventListener('click', () => open(b)));
    mm.querySelector('.menu-close')?.addEventListener('click', KD.closeMenu);
    addEventListener('keydown', (e) => { if (e.key === 'Escape') KD.closeMenu(); });
  }

  /* ---------- swipe helper for viewers and the lightbox ---------- */
  KD.onSwipe = (el, fn) => {
    let x0 = null, y0 = 0;
    el.addEventListener('pointerdown', (e) => { if (e.pointerType !== 'mouse') { x0 = e.clientX; y0 = e.clientY; } });
    el.addEventListener('pointerup', (e) => {
      if (x0 === null) return;
      const dx = e.clientX - x0, dy = e.clientY - y0;
      x0 = null;
      if (Math.abs(dx) > 40 && Math.abs(dx) > Math.abs(dy)) fn(dx < 0 ? 1 : -1);
    });
  };
})();
