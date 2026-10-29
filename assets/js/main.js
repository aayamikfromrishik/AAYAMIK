// Logo intro, the tilting glass card, and the 3D book in Chapter II.
const reduceMotion = matchMedia('(prefers-reduced-motion: reduce)').matches;
const finePointer = matchMedia('(pointer: fine)').matches;

// ---------- intro: the logo draws itself, then hands over to the house ----------
const intro = document.querySelector('.intro');
function endIntro() {
  if (window.__introDone) return;
  window.__introDone = true;
  intro?.classList.add('done');
  window.dispatchEvent(new Event('intro:done'));
}
if (!intro || reduceMotion) endIntro();
else {
  setTimeout(endIntro, 3200);
  intro.querySelector('.skip')?.addEventListener('click', endIntro);
  addEventListener('keydown', (e) => { if (e.key === 'Escape') endIntro(); });
}

// ---------- the glass card leans toward the cursor ----------
const glass = document.querySelector('.glass');
if (glass && finePointer && !reduceMotion) {
  let tx = 0, ty = 0, x = 0, y = 0;
  addEventListener('pointermove', (e) => {
    tx = (e.clientX / innerWidth - 0.5) * 2;
    ty = (e.clientY / innerHeight - 0.5) * 2;
  });
  (function loop() {
    x += (tx - x) * 0.06;
    y += (ty - y) * 0.06;
    glass.style.transform = `perspective(1200px) rotateY(${x * 5}deg) rotateX(${-y * 4}deg) translateZ(0)`;
    requestAnimationFrame(loop);
  })();
}

// ---------- Chapter II: the book turns as you scroll and opens on click ----------
const book = document.querySelector('.book');
const about = document.querySelector('.about');
if (book && about) {
  let mx = 0, my = 0;
  const update = () => {
    const r = about.getBoundingClientRect();
    const p = Math.min(1, Math.max(0, 1 - (r.top + r.height / 2) / innerHeight)); // 0 entering, ~0.5 centred
    const ry = reduceMotion ? -24 : -48 + p * 44 + mx * 14;
    const rx = reduceMotion ? -6 : -10 + my * -8;
    book.style.setProperty('--ry', `${ry}deg`);
    book.style.setProperty('--rx', `${rx}deg`);
  };
  addEventListener('scroll', update, { passive: true });
  if (finePointer && !reduceMotion) {
    about.addEventListener('pointermove', (e) => {
      const r = about.getBoundingClientRect();
      mx = (e.clientX - r.left) / r.width - 0.5;
      my = (e.clientY - r.top) / r.height - 0.5;
      update();
    });
  }
  update();
  const reader = document.querySelector('.reader');
  const note = document.querySelector('.book-note');
  book.addEventListener('click', () => {
    const open = book.classList.toggle('open');
    book.setAttribute('aria-pressed', String(open));
    reader.hidden = !open;
    note.textContent = open ? 'Click the book to close it' : 'Click the book to open it';
  });
  setupReader(book, reader);
}

// the sample pages from the book, two at a time, with a real page turn
function setupReader(book, reader) {
  const spreads = [
    { l: 'intro-1', r: 'intro-2', cap: 'Introduction · Why your home should be built on paper first' },
    { l: 'ch1-1', r: 'ch1-2', cap: 'Chapter 1 · Before I learned to build on paper' },
    { l: 'ch13-1', r: 'ch13-2', cap: 'Chapter 13 · The 100 decisions, decisions 1–6' },
  ];
  const src = (n) => `assets/img/book/${n}.jpg`;
  spreads.forEach((sp) => [sp.l, sp.r].forEach((n) => { new Image().src = src(n); }));
  const pageL = book.querySelector('.page-l'), pageR = book.querySelector('.page-r');
  const leaf = book.querySelector('.leaf');
  const [leafF, leafB] = leaf.querySelectorAll('img');
  const cap = reader.querySelector('.reader-cap'), num = reader.querySelector('.reader-n');
  let i = 0, busy = false;
  const label = () => { cap.textContent = spreads[i].cap; num.textContent = i + 1; };
  const done = (fn) => { setTimeout(() => { fn(); leaf.classList.remove('turning'); busy = false; }, reduceMotion ? 0 : 920); };
  reader.querySelectorAll('.turn').forEach((b) => b.addEventListener('click', () => {
    if (busy) return;
    busy = true;
    const dir = +b.dataset.dir, from = spreads[i];
    i = (i + dir + spreads.length) % spreads.length;
    const to = spreads[i];
    label();
    if (dir > 0) {
      // the right page lifts and falls to the left, showing the next left page on its back
      leafF.src = src(from.r); leafB.src = src(to.l);
      leaf.style.setProperty('--leaf', '0deg');
      pageR.src = src(to.r);
      leaf.getBoundingClientRect();
      leaf.classList.add('turning');
      leaf.style.setProperty('--leaf', 'calc(var(--open) * -1)');
      done(() => { pageL.src = src(to.l); });
    } else {
      leafF.src = src(to.r); leafB.src = src(from.l);
      leaf.style.setProperty('--leaf', 'calc(var(--open) * -1)');
      pageL.src = src(to.l);
      leaf.getBoundingClientRect();
      leaf.classList.add('turning');
      leaf.style.setProperty('--leaf', '0deg');
      done(() => { pageR.src = src(to.r); });
    }
  }));
}

// ---------- text and pictures settle in as they arrive ----------
const revealObs = new IntersectionObserver((entries) => {
  entries.forEach((e) => { if (e.isIntersecting) { e.target.classList.add('in'); revealObs.unobserve(e.target); } });
}, { threshold: 0.15 });
document.querySelectorAll('.reveal, .stage-bar, .grow').forEach((el) => revealObs.observe(el));

// a helper for scroll-driven sections: 0 when the section reaches the top, 1 when it leaves
const progressOf = (el) => {
  const r = el.getBoundingClientRect();
  return Math.min(1, Math.max(0, -r.top / Math.max(1, r.height - innerHeight)));
};

// ---------- Chapter III: portraits tilt toward the cursor, a light follows it ----------
if (finePointer && !reduceMotion) {
  document.querySelectorAll('.card .tilt').forEach((t) => {
    t.addEventListener('pointermove', (e) => {
      const r = t.getBoundingClientRect();
      const x = (e.clientX - r.left) / r.width, y = (e.clientY - r.top) / r.height;
      t.style.setProperty('--ry', `${(x - 0.5) * 18}deg`);
      t.style.setProperty('--rx', `${(0.5 - y) * 14}deg`);
      t.style.setProperty('--mx', `${x * 100}%`);
      t.style.setProperty('--my', `${y * 100}%`);
    });
    t.addEventListener('pointerleave', () => { t.style.setProperty('--rx', '0deg'); t.style.setProperty('--ry', '0deg'); });
  });
}

// ---------- Chapter IV: three statements, the drawing behind moves slower than the words ----------
const philo = document.querySelector('.philo');
if (philo) {
  const back = philo.querySelector('.layer.back'), mid = philo.querySelector('.layer.mid');
  const stmts = [...philo.querySelectorAll('.stmt')], dashes = [...philo.querySelectorAll('.dashes i')];
  const count = philo.querySelector('.philo-count b');
  back.querySelectorAll('path, rect, circle').forEach((el) => el.setAttribute('pathLength', '1'));
  let cur = -1, mx = 0, my = 0;
  if (finePointer && !reduceMotion) philo.addEventListener('pointermove', (e) => { mx = e.clientX / innerWidth - 0.5; my = e.clientY / innerHeight - 0.5; tick(); });
  function tick() {
    const p = progressOf(philo);
    const idx = Math.min(2, Math.floor(p * 3));
    if (idx !== cur) {
      cur = idx;
      stmts.forEach((s, k) => s.classList.toggle('on', k === idx));
      dashes.forEach((d, k) => d.classList.toggle('on', k === idx));
      count.textContent = idx + 1;
    }
    if (reduceMotion) { back.style.setProperty('--draw', 0); return; }
    back.style.setProperty('--draw', Math.max(0, 1 - p * 2.2).toFixed(3));
    back.style.transform = `translate3d(${mx * -20}px, ${p * -60 + my * -14}px, -200px) scale(1.2)`;
    mid.style.transform = `translate3d(${mx * 14}px, ${my * 10}px, 0)`;
  }
  addEventListener('scroll', tick, { passive: true });
  tick();
}

// ---------- Chapter V: projects on a curved wall, drifting left, pause on hover, drag to move ----------
const wall = document.querySelector('.wall');
if (wall) {
  const pal = ['#818865', '#BB8D3F', '#8B4729', '#7E7A5C', '#45492D', '#9C7B52'];
  const rows = [
    ['Ongoing · stage 4 of 6', 'Completed · Ludhiana', 'Completed · [City]', 'Ongoing · stage 2 of 6', 'Completed · [City]', 'Concept · [Year]'],
    ['Completed · [City]', 'Ongoing · stage 5 of 6', 'Completed · [City]', 'Completed · [City]', 'Ongoing · stage 1 of 6', 'Completed · [City]'],
  ];
  const strips = [...wall.querySelectorAll('.row')].map((rowEl, r) => {
    const tiles = [];
    // two passes so the wall is full on wide screens
    for (let pass = 0; pass < 2; pass++) rows[r].forEach((status, k) => {
      const n = r * 6 + k + 1;
      const a = document.createElement('a');
      a.href = '#'; a.className = 'tile';
      a.innerHTML = `<span class="img tx" style="background-color:${pal[n % pal.length]}"><span class="cap">[Photo · elevation]</span></span>`
        + `<span class="n">[Residence ${String(n).padStart(2, '0')}]</span>`
        + `<span class="s cap"><i style="background:${status.startsWith('Ongoing') ? 'var(--orange)' : 'transparent'}"></i>${status}</span>`;
      if (pass) { a.tabIndex = -1; a.setAttribute('aria-hidden', 'true'); }
      rowEl.appendChild(a);
      tiles.push(a);
    });
    return { tiles, offset: r ? -160 : 0 };
  });
  let paused = false, dragging = false, lastX = 0, vel = 0, inView = false;
  wall.addEventListener('pointerenter', (e) => { if (e.pointerType === 'mouse') paused = true; });
  wall.addEventListener('pointerleave', () => { paused = false; });
  wall.addEventListener('focusin', () => { paused = true; });
  wall.addEventListener('focusout', () => { paused = false; });
  wall.addEventListener('pointerdown', (e) => { dragging = true; lastX = e.clientX; vel = 0; wall.classList.add('dragging'); });
  ['pointerup', 'pointercancel'].forEach((ev) => addEventListener(ev, () => { dragging = false; wall.classList.remove('dragging'); }));
  addEventListener('pointermove', (e) => {
    if (!dragging) return;
    const dx = e.clientX - lastX; lastX = e.clientX;
    strips.forEach((s) => { s.offset += dx; });
    vel = dx;
  });
  wall.addEventListener('click', (e) => { if (Math.abs(vel) > 2) e.preventDefault(); }, true);
  new IntersectionObserver(([e]) => { inView = e.isIntersecting; }).observe(wall);

  function layout() {
    const narrow = innerWidth < 820;
    const gap = narrow ? 240 : 324;          // tile width plus space
    const R = narrow ? 520 : Math.max(900, innerWidth * 0.75); // radius of the curved wall
    strips.forEach((s) => {
      const L = s.tiles.length * gap;
      s.tiles.forEach((t, k) => {
        let x = ((k * gap + s.offset) % L + L) % L;
        if (x > L / 2) x -= L;                // centre the strip around the viewer
        const th = x / R;
        const hide = Math.abs(th) > 1.25;
        t.style.visibility = hide ? 'hidden' : 'visible';
        if (hide) return;
        t.style.transform = `translate3d(${R * Math.sin(th)}px, 0, ${R * (1 - Math.cos(th)) * 0.9}px) rotateY(${-th * 57.3}deg)`;
      });
    });
  }
  (function loop() {
    if (inView) {
      if (!paused && !dragging && !reduceMotion) strips.forEach((s, r) => { s.offset -= r ? 0.45 : 0.55; });
      if (!dragging && Math.abs(vel) > 0.1) { strips.forEach((s) => { s.offset += vel; }); vel *= 0.92; }
      layout();
    }
    requestAnimationFrame(loop);
  })();
  layout();
}

// ---------- Chapter VI: scroll walks you through the front door ----------
const walk = document.querySelector('.walk-stage');
if (walk) {
  const out = walk.querySelector('.walk-out'), hint = walk.querySelector('.walk-hint');
  const tick = () => {
    const p = progressOf(walk);
    const e = p * p;
    out.style.transform = `scale(${1 + e * 5})`;
    out.style.opacity = String(Math.max(0, 1 - Math.max(0, p - 0.55) / 0.35));
    hint.style.opacity = String(1 - p * 3);
  };
  if (!reduceMotion) { addEventListener('scroll', tick, { passive: true }); tick(); }
}

// ---------- Chapter VII: the stage bar fills up to today, the drawing builds to match ----------
const bar = document.querySelector('.stage-bar');
if (bar) {
  const now = +bar.dataset.now;
  [...bar.children].forEach((li, k) => {
    li.style.setProperty('--i', k);
    li.innerHTML = `<span>${li.innerHTML}</span>`;
    li.classList.add(k + 1 < now ? 'done' : k + 1 === now ? 'now' : 'later');
  });
  document.querySelectorAll('.grow g').forEach((g) => {
    const step = +g.dataset.step;
    g.classList.add(step <= now ? 'built' : 'later');
    g.querySelectorAll('path, circle').forEach((el, k) => {
      el.setAttribute('pathLength', '1');
      el.style.transitionDelay = `${(step - 1) * 0.45 + k * 0.05}s`;
    });
  });
}
