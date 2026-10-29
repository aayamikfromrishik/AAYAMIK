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
  book.addEventListener('click', () => {
    const open = book.classList.toggle('open');
    book.setAttribute('aria-pressed', String(open));
  });
}
