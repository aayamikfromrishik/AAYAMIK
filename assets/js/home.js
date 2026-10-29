/* Home page: loader, sketch slideshow, chapter indicator, book viewer, work rows, philosophy, contact form. */
(function () {
  const KD = window.KD;
  const reduce = KD.reduce;
  const $ = (s, r = document) => r.querySelector(s);
  const $$ = (s, r = document) => [...r.querySelectorAll(s)];
  const phone = matchMedia('(max-width: 767px)');

  /* ---------- 5.1 logo loader, first visit only ---------- */
  const html = document.documentElement;
  if (html.classList.contains('kd-intro')) {
    KD.store.set('kd_intro_seen', '1');
    const loader = $('.loader'), video = $('.loader video');
    let done = false;
    KD.lock(true);
    const finish = () => {
      if (done) return;
      done = true;
      html.classList.add('kd-intro-out');
      loader.classList.add('out');
      setTimeout(() => { video.pause(); html.classList.remove('kd-intro', 'kd-intro-out'); KD.lock(false); }, 900);
    };
    if (reduce) {
      // show the last frame for a second, then fade
      const toEnd = () => { try { video.currentTime = Math.max(0, video.duration - 0.05); } catch (e) { /* not seekable yet */ } setTimeout(finish, 1000); };
      if (video.readyState >= 1) toEnd(); else video.addEventListener('loadedmetadata', toEnd, { once: true });
      setTimeout(finish, 3000);
    } else {
      video.addEventListener('ended', finish);
      const p = video.play();
      if (p && p.catch) p.catch(finish);
      setTimeout(finish, 14000);
      ['wheel', 'touchstart', 'pointerdown', 'keydown'].forEach((ev) => addEventListener(ev, finish, { once: true, passive: true }));
    }
  }

  /* ---------- 6 sketch slideshow, with the blurred render behind the glass following it ---------- */
  const show = $('.sketches');
  if (show) {
    const slides = $$('img', show), sets = $$('.glowset'), dots = $$('.dots button');
    const cap = $('.sketch-cap');
    let i = 0, timer = null, hover = false;
    const go = (n) => {
      i = (n + slides.length) % slides.length;
      slides.forEach((s, k) => s.classList.toggle('on', k === i));
      sets.forEach((s, k) => s.classList.toggle('on', k === i));
      dots.forEach((d, k) => d.setAttribute('aria-current', String(k === i)));
      cap.textContent = `Sketch ${String(i + 1).padStart(2, '0')} · ${slides[i].dataset.name}`;
    };
    const start = () => { clearInterval(timer); timer = setInterval(() => { if (!hover && !document.hidden && !(KD.heroP > 0.05)) go(i + 1); }, 6000); };
    show.addEventListener('pointerenter', () => { hover = true; });
    show.addEventListener('pointerleave', () => { hover = false; });
    dots.forEach((d, k) => d.addEventListener('click', () => { go(k); start(); }));
    go(0);
    start();
  }

  /* ---------- 4 chapter indicator and chapter list ---------- */
  const ind = $('.indicator');
  if (ind) {
    const cur = $('.cur', ind), btn = $('button', ind), list = $('ol', ind);
    const chapters = $$('[data-chapter]');
    const io = new IntersectionObserver((es) => es.forEach((e) => {
      if (!e.isIntersecting) return;
      cur.textContent = e.target.dataset.chapter;
      ind.classList.toggle('on-dark', e.target.dataset.cursor === 'light');
    }), { rootMargin: '-50% 0px -50% 0px' });
    chapters.forEach((c) => io.observe(c));
    const close = () => { list.hidden = true; btn.setAttribute('aria-expanded', 'false'); };
    btn.addEventListener('click', () => { const open = list.hidden; list.hidden = !open; btn.setAttribute('aria-expanded', String(open)); });
    list.addEventListener('click', (e) => { if (e.target.closest('a')) setTimeout(close, 600); });
    addEventListener('keydown', (e) => { if (e.key === 'Escape') close(); });
    document.addEventListener('click', (e) => { if (!ind.contains(e.target)) close(); });
  }

  /* ---------- 7.2 book and handbook viewer ---------- */
  const pic = (base, alt, eager) => `<picture><source srcset="${base}.webp" type="image/webp"><img src="${base}.jpg" alt="${alt}"${eager ? '' : ' loading="lazy"'}></picture>`;
  const B = 'assets/book/';
  const BOOK = [
    { cap: 'Introduction · Why your home should be built on paper first', pages: [[B + 'book-p15', 'The 100 Decisions Before the First Brick, introduction, first page'], [B + 'book-p16', 'The 100 Decisions Before the First Brick, introduction, second page']] },
    { cap: 'Chapter 1 · Before I learned to build on paper', pages: [[B + 'book-p17', 'Chapter 1, Before I Learned to Build on Paper, opening page'], [B + 'book-p18', 'Chapter 1, second page']] },
    { cap: 'Chapter 13 · The 100 decisions, decisions 1–6', pages: [[B + 'book-p191', 'Chapter 13, The 100 Decisions, opening page'], [B + 'book-p192', 'Chapter 13, decisions 1 to 6']] },
  ];
  const HANDBOOKS = {
    building: [
      { cap: 'Building with Intention · Cover', pages: [[B + 'building-p1', 'Building with Intention, a construction handbook by Karukrit Designs, cover']] },
      { cap: 'Building with Intention · Page 17', pages: [[B + 'building-p17', 'Building with Intention, page 17: Where great spaces begin']] },
      { cap: 'Building with Intention · Page 58', pages: [[B + 'building-p58', 'Building with Intention, page 58: The journey now divides into two parallel paths']] },
    ],
    craft: [
      { cap: 'Craft with Intention · Cover', pages: [[B + 'craft-p1', 'Craft with Intention, an interior design and execution handbook by Karukrit Designs, cover']] },
      { cap: 'Craft with Intention · Page 14', pages: [[B + 'craft-p14', 'Craft with Intention, page 14: Where your interior journey begins']] },
      { cap: 'Craft with Intention · Page 20', pages: [[B + 'craft-p20', 'Craft with Intention, page 20: Designing one space at a time']] },
    ],
  };
  // on phones a spread becomes one page at a time
  const singles = (views) => views.flatMap((v) => v.pages.map((p) => ({ cap: v.cap, pages: [p] })));

  function Viewer(root, getViews, label) {
    let views = getViews(), i = 0, busy = false;
    root.innerHTML = `<div class="spread"><div class="spread-inner"></div></div>
      <div class="viewer-bar"><p class="cap"></p><div class="viewer-nav">
      <button type="button" class="circle-btn" data-dir="-1" aria-label="Previous ${label}">←</button>
      <span class="cap"><b class="n">1</b> / <span class="t"></span></span>
      <button type="button" class="circle-btn" data-dir="1" aria-label="Next ${label}">→</button></div></div>`;
    const spread = $('.spread', root), inner = $('.spread-inner', root), capEl = $('.viewer-bar > .cap', root);
    const n = $('.n', root), t = $('.t', root);
    const paint = () => {
      const v = views[i];
      spread.classList.toggle('two', v.pages.length === 2);
      inner.innerHTML = v.pages.map((p) => `<div class="page${v.pages.length === 1 ? ' single' : ''}">${pic(p[0], p[1])}</div>`).join('');
      capEl.textContent = v.cap;
      n.textContent = i + 1;
      t.textContent = views.length;
    };
    const flip = (dir) => {
      if (busy) return;
      const from = views[i];
      const to = views[(i + dir + views.length) % views.length];
      const pages = $$('.page', inner);
      if (reduce || from.pages.length !== 2 || to.pages.length !== 2) {
        // crossfade for single pages and when the page flip is turned off
        if (reduce) { i = (i + dir + views.length) % views.length; paint(); return; }
        busy = true;
        inner.classList.add('fade');
        inner.style.opacity = 0;
        setTimeout(() => { i = (i + dir + views.length) % views.length; paint(); inner.style.opacity = 1; setTimeout(() => { busy = false; }, 500); }, 250);
        return;
      }
      // the right page turns over the spine, 0.7 s
      busy = true;
      const [L, R] = pages;
      const leaf = document.createElement('div');
      leaf.className = 'leaf';
      leaf.style.left = L.offsetWidth + 'px';
      leaf.style.width = R.offsetWidth + 'px';
      const img = (p) => `<img src="${p[0]}.jpg" alt="">`;
      leaf.innerHTML = dir > 0 ? `<div class="front">${img(from.pages[1])}</div><div class="back">${img(to.pages[0])}</div>`
        : `<div class="front">${img(to.pages[1])}</div><div class="back">${img(from.pages[0])}</div>`;
      inner.appendChild(leaf);
      leaf.style.transition = 'none';
      leaf.style.transform = dir > 0 ? 'rotateY(0deg)' : 'rotateY(-180deg)';
      leaf.classList.add('turning');
      if (dir > 0) R.innerHTML = pic(...to.pages[1]); else L.innerHTML = pic(...to.pages[0]);
      leaf.getBoundingClientRect();
      leaf.style.transition = '';
      leaf.style.transform = dir > 0 ? 'rotateY(-180deg)' : 'rotateY(0deg)';
      setTimeout(() => { i = (i + dir + views.length) % views.length; paint(); busy = false; }, 720);
    };
    $$('[data-dir]', root).forEach((b) => b.addEventListener('click', () => flip(+b.dataset.dir)));
    KD.onSwipe(spread, flip);
    paint();
    return {
      flip,
      reset(newGet) { if (newGet) getViews = newGet; views = getViews(); i = Math.min(i, views.length - 1); paint(); },
    };
  }

  const viewerRoot = $('#book-viewer');
  let inline = null;
  if (viewerRoot) {
    inline = Viewer(viewerRoot, () => (phone.matches ? singles(BOOK) : BOOK), 'spread');
    phone.addEventListener('change', () => inline.reset());
    let inView = false;
    new IntersectionObserver(([e]) => { inView = e.isIntersecting; }, { threshold: 0.4 }).observe(viewerRoot);
    addEventListener('keydown', (e) => {
      if (!inView || $('dialog[open]') || /INPUT|TEXTAREA|SELECT/.test(document.activeElement.tagName)) return;
      if (e.key === 'ArrowRight') inline.flip(1);
      if (e.key === 'ArrowLeft') inline.flip(-1);
    });
  }

  // READ A SAMPLE and VIEW PAGES open the same viewer full screen
  const dlg = $('#pages-dialog');
  if (dlg) {
    const box = $('.viewer', dlg), title = $('.full-title', dlg);
    let full = null, opener = null;
    const open = (which, btn) => {
      opener = btn;
      const get = which === 'book' ? () => (phone.matches ? singles(BOOK) : BOOK) : () => HANDBOOKS[which];
      title.textContent = which === 'book' ? 'The 100 Decisions Before the First Brick' : which === 'building' ? 'Building with Intention' : 'Craft with Intention';
      if (!full) full = Viewer(box, get, which === 'book' ? 'spread' : 'page');
      else full.reset(get);
      dlg.showModal();
      KD.lock(true);
    };
    $$('[data-pages]').forEach((b) => b.addEventListener('click', () => setTimeout(() => open(b.dataset.pages, b), reduce ? 0 : 300)));
    $('.full-close', dlg).addEventListener('click', () => dlg.close());
    dlg.addEventListener('close', () => { KD.lock(false); opener?.focus(); });
    dlg.addEventListener('keydown', (e) => { if (e.key === 'ArrowRight') full?.flip(1); if (e.key === 'ArrowLeft') full?.flip(-1); });
  }

  /* ---------- 10 work: category tabs swap the two flowing rows ---------- */
  const tabs = $$('.work .tabs [role="tab"]');
  const rows = $('.rows');
  if (rows) {
    const foot = $('.work-foot a');
    tabs.forEach((tab) => tab.addEventListener('click', () => {
      if (tab.getAttribute('aria-selected') === 'true') return;
      tabs.forEach((t) => t.setAttribute('aria-selected', String(t === tab)));
      rows.classList.add('fading');
      setTimeout(() => {
        rows.innerHTML = $(`template[data-cat="${tab.dataset.cat}"]`).innerHTML;
        foot.textContent = `View all ${tab.dataset.name.toLowerCase()} →`;
        foot.href = `projects/${tab.dataset.cat}/index.html`;
        initWall();
        rows.classList.remove('fading');
      }, reduce ? 0 : 250);
    }));
    initWall();
  }

  /* ---------- 10 the curved gallery wall: both rows flow left at the same speed, one cycle of 6 tiles in 48 s ---------- */
  function initWall() {
    if (reduce || !rows) return;
    $$('.marq', rows).forEach((marq, r) => {
      marq.classList.add('curved');
      const tiles = $$('.tile', marq);
      const st = { tiles, offset: 0, paused: false, held: false, drag: null, vel: 0, moved: 0, resume: null, row: r };
      marq._wall = st;
      marq.addEventListener('pointerenter', (e) => { if (e.pointerType === 'mouse') st.paused = true; });
      marq.addEventListener('pointerleave', (e) => { if (e.pointerType === 'mouse') st.paused = false; });
      marq.addEventListener('focusin', () => { st.paused = true; });
      marq.addEventListener('focusout', () => { st.paused = false; });
      marq.addEventListener('pointerdown', (e) => {
        st.drag = e.clientX; st.moved = 0; st.vel = 0; marq.classList.add('dragging');
        if (e.pointerType !== 'mouse') {
          // 14 touching a row pauses it and colours the tile under the finger
          clearTimeout(st.resume); st.held = true;
          $$('.is-colour', rows).forEach((m) => m.classList.remove('is-colour'));
          e.target.closest('.tile')?.querySelector('.mono')?.classList.add('is-colour');
        }
      });
      marq.addEventListener('click', (e) => { if (st.moved > 6) e.preventDefault(); }, true);
    });
  }
  if (rows && !reduce) {
    const all = () => $$('.marq.curved', rows).map((m) => m._wall).filter(Boolean);
    addEventListener('pointermove', (e) => all().forEach((st) => {
      if (st.drag === null) return;
      const dx = e.clientX - st.drag; st.drag = e.clientX; st.offset += dx; st.vel = dx; st.moved += Math.abs(dx);
    }));
    const up = (e) => all().forEach((st) => {
      if (st.drag === null) return;
      st.drag = null;
      $$('.marq.dragging', rows).forEach((m) => m.classList.remove('dragging'));
      if (e.pointerType !== 'mouse') { clearTimeout(st.resume); st.resume = setTimeout(() => { st.held = false; $$('.is-colour', rows).forEach((m) => m.classList.remove('is-colour')); }, 2000); }
    });
    addEventListener('pointerup', up);
    addEventListener('pointercancel', up);
    let inView = false, last = performance.now();
    new IntersectionObserver(([e]) => { inView = e.isIntersecting; }).observe($('.work'));
    (function loop(now) {
      const dt = Math.min(0.05, (now - last) / 1000); last = now;
      if (inView) {
        const narrow = innerWidth < 768;
        const gap = narrow ? 244 : 324;                     // tile width plus the 24 px gap
        const speed = (gap * 6) / 48;                      // px per second: 6 tiles in 48 s
        const R = narrow ? 560 : Math.max(1000, innerWidth * 0.8); // radius of the wall
        all().forEach((st) => {
          if (st.drag === null) {
            if (!st.paused && !st.held) st.offset -= speed * dt;
            if (Math.abs(st.vel) > 0.1) { st.offset += st.vel; st.vel *= 0.92; }
          }
          const L = st.tiles.length * gap;
          const shift = st.row ? gap * 3 : 0;               // the second row runs half a cycle behind
          st.tiles.forEach((t, k) => {
            let x = (((k * gap + st.offset - shift) % L) + L) % L;
            if (x > L / 2) x -= L;
            const th = x / R;
            const hide = Math.abs(th) > 1.2;
            t.style.visibility = hide ? 'hidden' : '';
            if (!hide) t.style.transform = `translate3d(${(R * Math.sin(th)).toFixed(1)}px,0,${(R * (1 - Math.cos(th)) * 0.9).toFixed(1)}px) rotateY(${(-th * 57.2958).toFixed(2)}deg)`;
          });
        });
      }
      requestAnimationFrame(loop);
    })(last);
  }

  /* ---------- 9 philosophy: each sentence fades and rises in as its screen arrives ---------- */
  const thoughts = $$('.thought');
  if (reduce) thoughts.forEach((t) => t.classList.add('in'));
  else {
    const io = new IntersectionObserver((es) => es.forEach((e) => e.target.classList.toggle('in', e.isIntersecting)), { threshold: 0.5 });
    thoughts.forEach((t) => io.observe(t));
  }

  /* ---------- 13 contact form, sliding up over the chapter ---------- */
  const panel = $('.form-panel');
  if (panel) {
    const form = $('form', panel), done = $('.thanks', panel);
    let opener = null;
    const openForm = (topic, btn) => {
      opener = btn;
      if (topic) form.elements.planning.value = topic;
      panel.classList.add('open');
      panel.removeAttribute('inert');
      setTimeout(() => form.elements.name.focus({ preventScroll: true }), reduce ? 0 : 600);
    };
    const closeForm = () => { panel.classList.remove('open'); panel.setAttribute('inert', ''); opener?.focus({ preventScroll: true }); };
    $$('[data-open-form]').forEach((b) => b.addEventListener('click', () => {
      const topic = b.dataset.topic;
      if (b.closest('#contact')) setTimeout(() => openForm(topic, b), reduce ? 0 : 300);
      else { KD.scrollTo('#contact'); setTimeout(() => openForm(topic, b), reduce ? 0 : 1200); }
    }));
    $('.form-close', panel).addEventListener('click', closeForm);
    panel.addEventListener('keydown', (e) => { if (e.key === 'Escape') closeForm(); });
    const messages = { name: 'Please add your name.', phone: 'Please add a phone number so we can call you.', planning: 'Please choose what you are planning.' };
    const check = (f) => {
      const el = form.elements[f], box = el.closest('.field'), err = $('.err', box);
      const bad = !el.value.trim() || (f === 'phone' && el.value.replace(/\D/g, '').length < 7);
      box.classList.toggle('bad', bad);
      el.setAttribute('aria-invalid', String(bad));
      err.textContent = bad ? (f === 'phone' && el.value.trim() ? 'Please check the number.' : messages[f]) : '';
      return !bad;
    };
    Object.keys(messages).forEach((f) => form.elements[f].addEventListener('blur', () => { if (form.elements[f].value) check(f); }));
    form.addEventListener('submit', async (e) => {
      e.preventDefault();
      const ok = Object.keys(messages).map(check).every(Boolean);
      if (!ok) { form.querySelector('[aria-invalid="true"]').focus(); return; }
      const endpoint = form.dataset.endpoint;
      const send = $('.form-actions .err', form);
      send.textContent = '';
      if (endpoint) {
        try {
          const r = await fetch(endpoint, { method: 'POST', body: new FormData(form), headers: { Accept: 'application/json' } });
          if (!r.ok) throw new Error(r.status);
        } catch (err) {
          send.textContent = 'Your message did not go through. Please call us on +91 88243 96618.';
          return;
        }
      } else {
        // where submissions go is still to be confirmed (spec section 18, item 3), so say so rather than pretend
        send.textContent = 'This form is not connected yet. Please call +91 88243 96618 or write to ceo@karukritdesigns.com.';
        return;
      }
      form.hidden = true;
      done.hidden = false;
      done.focus();
    });
  }
  /* ---------- motion layered on the spec ---------- */
  const clamp = (v, a = 0, b = 1) => Math.min(b, Math.max(a, v));
  const smooth = (a, b, v) => { const t = clamp((v - a) / (b - a)); return t * t * (3 - 2 * t); };
  const lerp = (a, b, t) => a + (b - a) * t;
  const progressOf = (el) => { const r = el.getBoundingClientRect(); return clamp(-r.top / Math.max(1, r.height - innerHeight)); };
  const mouse = { x: 0, y: 0 };
  if (KD.mouse && !reduce) addEventListener('pointermove', (e) => { mouse.x = e.clientX / innerWidth - 0.5; mouse.y = e.clientY / innerHeight - 0.5; }, { passive: true });

  // Chapter I: the frosted glass shrinks into a card around the headline, and the 3D house appears behind it
  const hs = $('.hero-scroll');
  KD.heroP = 0;
  if (hs && !reduce) {
    const hero = $('.hero', hs), glass = $('.glass', hs), pane = $('.pane', hs), text = $('.hero-text', hs);
    const bar = $('.topbar');
    let target = null, inView = true, tx = 0, ty = 0;
    const measure = () => {
      glass.style.transform = '';
      const g = glass.getBoundingClientRect(), t = text.getBoundingClientRect();
      const pad = innerWidth < 768 ? 20 : 40;
      const x = Math.max(0, t.left - g.left - pad), y = Math.max(0, t.top - g.top - pad);
      target = { gw: g.width, gh: g.height, x, y, w: Math.min(g.width - x, t.width + pad * 2), h: Math.min(g.height - y, t.height + pad * 2) };
      glass.style.setProperty('--card-x', `${((x + target.w / 2) / g.width) * 100}%`);
      glass.style.setProperty('--card-y', `${((y + target.h / 2) / g.height) * 100}%`);
    };
    addEventListener('resize', measure);
    document.fonts && document.fonts.ready.then(measure);
    new IntersectionObserver(([e]) => { inView = e.isIntersecting; }).observe(hs);
    (function loop() {
      requestAnimationFrame(loop);
      if (!inView && KD.heroP > 0.99) return;
      if (!target) measure();
      const p = progressOf(hs);
      KD.heroP = p;
      const m = smooth(0, 0.12, p);
      pane.style.left = `${lerp(0, target.x, m)}px`;
      pane.style.top = `${lerp(0, target.y, m)}px`;
      pane.style.width = `${lerp(target.gw, target.w, m)}px`;
      pane.style.height = `${lerp(target.gh, target.h, m)}px`;
      hero.style.setProperty('--fade', (1 - smooth(0, 0.07, p)).toFixed(3));
      hero.style.setProperty('--glow', (1 - smooth(0.03, 0.13, p)).toFixed(3));
      hero.style.setProperty('--scene', smooth(0.02, 0.12, p).toFixed(3));
      hero.style.setProperty('--stg', smooth(0.1, 0.15, p).toFixed(3));
      hero.classList.toggle('opened', p > 0.08);
      if (bar) bar.classList.toggle('show', p > 0.12 || hs.getBoundingClientRect().bottom < 0);
      // once it is a card, it leans gently toward the cursor
      const k = smooth(0.12, 0.2, p);
      tx += (mouse.x - tx) * 0.06; ty += (mouse.y - ty) * 0.06;
      glass.style.transform = k > 0 ? `perspective(1200px) rotateY(${(tx * 8 * k).toFixed(2)}deg) rotateX(${(-ty * 6 * k).toFixed(2)}deg)` : '';
    })();
  }

  if (hs && reduce) {
    const bar = $('.topbar');
    new IntersectionObserver(([e]) => bar && bar.classList.toggle('show', !e.isIntersecting && e.boundingClientRect.top < 0), { threshold: 0.02 }).observe(hs);
  }

  // Chapter II: the book turns as the chapter scrolls by and leans toward the cursor
  const book = $('.book3d'), author = $('#author');
  if (book && author && !reduce) {
    let mx = 0, my = 0;
    const turn = () => {
      const r = author.getBoundingClientRect();
      const p = clamp(1 - (r.top + r.height / 2) / innerHeight);
      book.style.setProperty('--ry', `${-44 + p * 36 + mx * 16}deg`);
      book.style.setProperty('--rx', `${-8 - my * 8}deg`);
    };
    addEventListener('scroll', turn, { passive: true });
    if (KD.lenis) KD.lenis.on('scroll', turn);
    if (KD.mouse) author.addEventListener('pointermove', (e) => { const r = author.getBoundingClientRect(); mx = (e.clientX - r.left) / r.width - 0.5; my = (e.clientY - r.top) / r.height - 0.5; turn(); });
    turn();
  }

  // Chapter III: portraits lean toward the cursor, a soft light follows it
  if (KD.mouse && !reduce) $$('.member .tilt').forEach((t) => {
    t.addEventListener('pointermove', (e) => {
      const r = t.getBoundingClientRect(), x = (e.clientX - r.left) / r.width, y = (e.clientY - r.top) / r.height;
      t.style.setProperty('--ry', `${((x - 0.5) * 14).toFixed(2)}deg`);
      t.style.setProperty('--rx', `${((0.5 - y) * 10).toFixed(2)}deg`);
      t.style.setProperty('--mx', `${x * 100}%`);
      t.style.setProperty('--my', `${y * 100}%`);
    });
    t.addEventListener('pointerleave', () => { t.style.setProperty('--rx', '0deg'); t.style.setProperty('--ry', '0deg'); });
  });

  // Chapter IV: the plan drawing behind the sentences draws itself and moves slower than the words
  const philo = $('.philosophy');
  if (philo) {
    const svg = $('.philo-draw svg', philo);
    $$('rect, path, circle', svg).forEach((el) => el.setAttribute('pathLength', '1'));
    if (reduce) svg.style.setProperty('--draw', 0);
    else {
      const tick = () => {
        const p = progressOf(philo);
        svg.style.setProperty('--draw', Math.max(0, 1 - p * 2.4).toFixed(3));
        svg.style.transform = `translate3d(${(mouse.x * -24).toFixed(1)}px, ${(p * -80 + mouse.y * -16).toFixed(1)}px, 0) scale(1.08)`;
      };
      addEventListener('scroll', tick, { passive: true });
      if (KD.lenis) KD.lenis.on('scroll', tick);
      if (KD.mouse) philo.addEventListener('pointermove', tick);
      tick();
    }
  }
})();
