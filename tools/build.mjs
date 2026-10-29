// Builds every page of the site from content/projects.json. Run: node tools/build.mjs
// Section numbers in comments refer to docs/KARUKRIT_WEBSITE_SPEC.md.
import { readFileSync, writeFileSync, mkdirSync, existsSync, rmSync, readdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const data = JSON.parse(readFileSync(join(ROOT, 'content/projects.json'), 'utf8'));
const CATS = data.categories;
const PROJECTS = data.projects;
const SITE = 'https://karukritdesigns.com/';
const HAS_SATOSHI = existsSync(join(ROOT, 'assets/fonts/Satoshi-Light.woff2'));
const STAGES = ['Design', 'Approvals', 'Structure', 'Masonry and services', 'Finishing', 'Handover'];

const esc = (s = '') => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
const cat = (slug) => CATS.find((c) => c.slug === slug);
const statusText = (p) => p.status === 'ongoing' ? `Ongoing · stage ${p.stage} of 6` : p.status === 'concept' ? `Concept · ${p.year}` : `Completed · ${p.city}`;
const projectHref = (base, p) => `${base}projects/${p.slug}/index.html`;
const catHref = (base, c) => `${base}projects/${c.slug}/index.html`;

// an image from the studio, or a labelled placeholder in the project's tint until one exists
const visual = (img, tint, label, base, eager = false) => img
  ? `<picture>${img.webp ? `<source srcset="${base}${esc(img.webp)}" type="image/webp">` : ''}<img src="${base}${esc(img.src)}" alt="${esc(img.alt)}"${eager ? '' : ' loading="lazy"'}></picture>`
  : `<div class="ph tx" style="background-color:${tint}" role="img" aria-label="${esc(label)}, placeholder"><span class="cap">[${esc(label)}]</span></div>`;

/* ---------- shared pieces ---------- */
function head({ base, title, description, path, home = false }) {
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>${esc(title)}</title>
<meta name="description" content="${esc(description)}">
<meta name="kd-base" content="${base}">
<link rel="canonical" href="${SITE}${path}">
<meta property="og:type" content="website">
<meta property="og:title" content="${esc(title)}">
<meta property="og:description" content="${esc(description)}">
<meta property="og:image" content="${SITE}assets/img/og.jpg">
<meta name="theme-color" content="#45492D">
<link rel="icon" href="${base}assets/img/favicon.svg" type="image/svg+xml">
${HAS_SATOSHI
    ? `<link rel="preload" href="${base}assets/fonts/Satoshi-Light.woff2" as="font" type="font/woff2" crossorigin>
<link rel="stylesheet" href="${base}assets/css/fonts.css">`
    : `<!-- Satoshi WOFF2 files are not in assets/fonts yet, so Manrope (the design-board stand-in) is used meanwhile. -->
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Manrope:wght@300;400;500&display=swap">`}
<link rel="stylesheet" href="${base}assets/css/site.css">
${home ? `<script>
  // 5.1 the logo animation plays on the first visit only
  try { if (!localStorage.getItem('kd_intro_seen')) { document.documentElement.classList.add('kd-intro');
    var l = document.createElement('link'); l.rel = 'preload'; l.as = 'video'; l.href = 'assets/loader/KD_logo_animation_on_moss_1080p_8s.mp4'; document.head.appendChild(l); } } catch (e) {}
</script>` : ''}
</head>`;
}

const NAV = [['About', 'about'], ['Team', 'team'], ['Philosophy', 'philosophy'], ['Projects', 'work'], ['Contact', 'contact']];
const navLinks = (base, home) => NAV.map(([t, id]) => `<li><a class="cap" href="${home ? '' : base + 'index.html'}#${id}" data-ring>${t}</a></li>`).join('');

function topbar(base, home) {
  return `<header class="topbar tx${home ? '' : ' always'}">
  <div class="wrap">
    <a class="wordmark" href="${home ? '#home' : base + 'index.html'}" aria-label="Karukrit Designs, home"><img src="${base}assets/brand/wordmark-dark-TRACED.svg" alt="Karukrit Designs" width="230" height="18"></a>
    <nav aria-label="Main"><ul class="menu" data-ring-group>${navLinks(base, home)}</ul></nav>
    <button class="menu-btn" type="button" aria-label="Open menu"><i></i><i></i></button>
  </div>
</header>`;
}

function mobileMenu(base, home) {
  return `<div class="mobile-menu s-moss tx" data-cursor="light" inert aria-label="Menu">
  <div class="row">
    <img class="wordmark" src="${base}assets/brand/wordmark-light-TRACED.svg" alt="Karukrit Designs" width="160" height="13">
    <button class="menu-close cap link-cap" type="button">Close</button>
  </div>
  <nav aria-label="Main"><ul data-ring-group>${NAV.map(([t, id]) => `<li><a href="${home ? '' : base + 'index.html'}#${id}" data-ring>${t}</a></li>`).join('')}</ul></nav>
</div>`;
}

const stripe = '<div class="stripe" aria-hidden="true"><i></i><i></i><i></i><i></i></div>';

function tile(base, p, hidden = false) {
  const extra = hidden ? ' tabindex="-1" aria-hidden="true"' : '';
  return `<a class="tile mono-host" href="${projectHref(base, p)}"${extra}>
  <div class="img mono">${visual(p.tileImage, p.tint, 'Photo · elevation', base)}</div>
  <span class="nm">${esc(p.name)}</span>
  <span class="status cap">${p.status === 'ongoing' ? '<i aria-hidden="true"></i>' : ''}${esc(statusText(p))}</span>
</a>`;
}

/* ---------- 10 the two flowing rows for one category ---------- */
function rowsFor(base, c) {
  const list = PROJECTS.filter((p) => p.category === c.slug);
  let r1 = list.filter((_, i) => i % 2 === 0), r2 = list.filter((_, i) => i % 2 === 1);
  if (!r2.length) r2 = r1.slice();
  const fill = (row) => { const out = []; while (out.length < 6) out.push(...row); return out; };
  const row = (items, cls) => {
    const full = fill(items);
    const seen = new Set();
    const tiles = full.map((p) => { const dup = seen.has(p.slug); seen.add(p.slug); return tile(base, p, dup); }).join('');
    // the row is duplicated once so the loop is seamless; one cycle of 6 tiles takes 48 s
    return `<div class="marq"><div class="track ${cls}" style="--dur:${(48 * full.length / 6).toFixed(1)}s">${tiles}${full.map((p) => tile(base, p, true)).join('')}</div></div>`;
  };
  return row(r1, 'row1') + row(r2, 'row2');
}

/* ---------- home page ---------- */
const SKETCHES = [
  { src: 'assets/sketches/sketch-01.svg', name: '[Residence name]', alt: 'Pencil sketch of a two-storey house elevation', glow: ['#818865', '#BB8D3F', '#818865', '#8B4729', '#2A2D1B', '#BB8D3F'] },
  { src: 'assets/sketches/sketch-02.svg', name: '[Residence name]', alt: 'Pencil sketch of a long single-storey house with a timber screen', glow: ['#BB8D3F', '#8B4729', '#818865', '#BB8D3F', '#2A2D1B', '#818865'] },
  { src: 'assets/sketches/sketch-03.svg', name: '[Residence name]', alt: 'Pencil sketch of a three-storey house with a stair tower', glow: ['#8B4729', '#818865', '#BB8D3F', '#2A2D1B', '#818865', '#8B4729'] },
  { src: 'assets/sketches/sketch-04.svg', name: '[Residence name]', alt: 'Pencil sketch of a ground floor plan around a courtyard', glow: ['#818865', '#2A2D1B', '#BB8D3F', '#818865', '#8B4729', '#BB8D3F'] },
];
// 6 the six glows on a 1440 x 900 screen, as percentages
const GLOWS = [[-120, -140, 620, 540, 1], [480, -120, 520, 380, 0.9], [1000, -120, 560, 500, 0.85], [820, 380, 480, 420, 1], [140, 540, 600, 400, 1], [1140, 600, 400, 360, 0.7]];
const glowset = (s, i) => `<div class="glowset${i === 0 ? ' on' : ''}">${s.render ? `<img src="${s.render}" alt="">` : GLOWS.map(([x, y, w, h, o], k) =>
  `<i style="left:${(x / 14.4).toFixed(2)}%;top:${(y / 9).toFixed(2)}%;width:${(w / 14.4).toFixed(2)}%;height:${(h / 9).toFixed(2)}%;background:${s.glow[k]};opacity:${o}"></i>`).join('')}</div>`;

const bookPic = (n, alt, extra = '') => `<picture><source srcset="assets/book/${n}.webp" type="image/webp"><img src="assets/book/${n}.jpg" alt="${esc(alt)}" loading="lazy"${extra}></picture>`;

function home() {
  const base = '';
  const first = CATS[0];
  return `${head({ base, title: 'Karukrit Designs | Architecture and interiors, Ludhiana', description: 'Karukrit Designs is an architecture and interior design studio in Ludhiana, founded in 2018 by Ar. Saptarshi Kapri.', path: '', home: true })}
<body>
<a class="skip-link cap" href="#about">Skip to content</a>

<div class="loader tx" aria-hidden="true">
  <video muted playsinline preload="none" src="assets/loader/KD_logo_animation_on_moss_1080p_8s.mp4"></video>
</div>

${topbar(base, true)}
${mobileMenu(base, true)}

<div class="indicator cap">
  <button type="button" aria-expanded="false" aria-controls="chapter-list" aria-label="Chapters"><span class="cur">I</span><span class="line"></span><span class="last">VI</span></button>
  <ol id="chapter-list" class="tx" hidden data-ring-group>
    <li><a href="#home" data-ring><span>I</span><span>Home</span></a></li>
    <li><a href="#about" data-ring><span>II</span><span>The architect</span></a></li>
    <li><a href="#author" data-ring><span>II</span><span>The author</span></a></li>
    <li><a href="#team" data-ring><span>III</span><span>The studio</span></a></li>
    <li><a href="#philosophy" data-ring><span>IV</span><span>Philosophy</span></a></li>
    <li><a href="#work" data-ring><span>V</span><span>Work</span></a></li>
    <li><a href="#contact" data-ring><span>VI</span><span>Contact</span></a></li>
  </ol>
</div>

<main>
<!-- I · Home: frosted glass -->
<section id="home" class="ch hero s-moss tx" data-chapter="I" data-cursor="light" data-snap aria-label="Chapter I, home">
  <div class="glowsets" aria-hidden="true">${SKETCHES.map(glowset).join('')}</div>
  <div class="glass tx hero-fade" data-cursor="dark">
    <div class="glass-top">
      <a class="wordmark" href="#home" aria-label="Karukrit Designs, home"><img src="assets/brand/wordmark-dark-TRACED.svg" alt="Karukrit Designs" width="230" height="18"></a>
      <nav aria-label="Chapters"><ul class="menu" data-ring-group>${navLinks(base, true)}</ul></nav>
      <button class="menu-btn" type="button" aria-label="Open menu"><i></i><i></i></button>
    </div>
    <div class="g12 glass-body">
      <div class="sketch-col">
        <div class="sketches">${SKETCHES.map((s, i) => `<img src="${s.src}" alt="${esc(s.alt)}" data-name="${esc(s.name)}"${i === 0 ? ' class="on"' : ' loading="lazy"'}>`).join('')}</div>
        <div class="sketch-meta">
          <span class="cap sketch-cap" aria-live="polite">Sketch 01 · ${esc(SKETCHES[0].name)}</span>
          <div class="dots">${SKETCHES.map((_, i) => `<button type="button" aria-label="Show sketch ${i + 1}" aria-current="${i === 0}"></button>`).join('')}</div>
        </div>
      </div>
      <div class="hero-text">
        <span class="cap">Chapter I</span>
        <h1 class="h1"><b class="hl">Every house</b> begins as a line on paper.</h1>
        <a class="btn btn-orange tx" href="#work" data-ring>View projects</a>
        <a class="cap link-cap" href="#about">Scroll to begin ↓</a>
      </div>
    </div>
  </div>
</section>

<!-- II · The architect -->
<section id="about" class="ch arch s-taupe tx" data-chapter="II" data-cursor="dark" data-snap aria-labelledby="arch-h">
  <div class="portrait mono-host"><div class="mono ph tx" style="background-color:var(--sage);height:100%" role="img" aria-label="Portrait of Ar. Saptarshi Kapri, placeholder"><span class="cap">[Portrait · full height]</span></div></div>
  <div class="arch-text" data-stagger>
    <span class="cap rv">Chapter II · The architect</span>
    <h2 id="arch-h" class="h1 rv"><b class="hl">Ar. Saptarshi</b> Kapri</h2>
    <p class="body muted rv">[Your story, first short paragraph.]</p>
    <p class="body muted rv">[Your story, second short paragraph.]</p>
    <a class="book-card s-moss tx rv" href="#author" data-cursor="light">
      ${bookPic('book-cover-front', 'Cover of The 100 Decisions Before the First Brick', ' width="70" height="96"')}
      <span class="stack"><span class="cap cap-gold">The book</span><span class="t">The 100 Decisions Before the First Brick</span></span>
    </a>
  </div>
</section>

<!-- II · The author -->
<section id="author" class="ch author s-moss tx" data-chapter="II" data-cursor="light" data-snap aria-labelledby="author-h">
  <div class="wrap g12" style="flex:1;align-items:center">
    <div class="author-left" data-stagger>
      ${bookPic('book-cover-front', 'Cover of The 100 Decisions Before the First Brick by Ar. Saptarshi Kapri', ' class="cover rv"').replace('<picture>', '<picture class="rv">')}
      <span class="cap cap-gold rv">Chapter II · The author</span>
      <h2 id="author-h" class="title rv">The 100 Decisions <b class="hl">Before the First Brick</b></h2>
      <p class="line rv">What to finalise, question, compare and document before you start building. A practical guide for homeowners.</p>
      <div class="btn-row rv">
        <button class="btn btn-gold tx" type="button" data-ring data-open-form data-topic="About the book">Connect to the author</button>
        <button class="btn btn-line" type="button" data-ring data-pages="book">Read a sample</button>
      </div>
      <span class="cap rv">[Where to buy]</span>
    </div>
    <div class="author-right">
      <div id="book-viewer" class="viewer" aria-label="Sample pages from the book"></div>
    </div>
  </div>
  <div class="wrap">
    <div class="handbooks">
      <div class="handbook rv">
        ${bookPic('building-p1', 'Building with Intention, cover', ' class="pg cover"')}
        ${bookPic('building-p17', 'Building with Intention, page 17: Where great spaces begin', ' class="pg"')}
        ${bookPic('building-p58', 'Building with Intention, page 58: The journey now divides into two parallel paths', ' class="pg"')}
        <div class="meta"><span class="cap cap-gold">Handbook · Volume I</span><span class="name">Building with Intention</span><span class="sub">Construction and structure</span>
          <button class="cap link-cap" type="button" data-ring data-pages="building">View pages →</button></div>
      </div>
      <div class="handbook rv">
        ${bookPic('craft-p1', 'Craft with Intention, cover', ' class="pg cover"')}
        ${bookPic('craft-p14', 'Craft with Intention, page 14: Where your interior journey begins', ' class="pg"')}
        ${bookPic('craft-p20', 'Craft with Intention, page 20: Designing one space at a time', ' class="pg"')}
        <div class="meta"><span class="cap cap-gold">Handbook · Volume II</span><span class="name">Craft with Intention</span><span class="sub">Interior design and execution</span>
          <button class="cap link-cap" type="button" data-ring data-pages="craft">View pages →</button></div>
      </div>
    </div>
  </div>
</section>

<!-- III · The studio -->
<section id="team" class="ch team s-gold tx" data-chapter="III" data-cursor="dark" data-snap aria-labelledby="team-h">
  <div class="wrap team-head" data-stagger>
    <div class="rv"><span class="cap">Chapter III</span><h2 id="team-h" class="h2">The studio</h2><i class="rule"></i></div>
    <p class="body rv">[One sentence on how the team works together, from first sketch to site.]</p>
  </div>
  <ul class="wrap team-grid" data-stagger>
    ${[['Kuljeet', '[Role]'], ['Krishma', '[Role]'], ['Sanchit', '[Role]'], ['[Fourth member]', '[Role]']].map(([n, r]) => `<li class="member mono-host rv">
      <div class="frame"><div class="mono ph tx" style="background-color:var(--sage)" role="img" aria-label="Portrait of ${esc(n)}, placeholder"><span class="cap">[Portrait]</span></div></div>
      <span class="name">${esc(n)}</span><span class="cap">${esc(r)}</span>
    </li>`).join('')}
  </ul>
</section>

<!-- IV · Philosophy: three screens, one sentence each -->
<div id="philosophy" class="philosophy">
${[
    ['A home is <b class="hl">a hundred decisions</b>, made in the right order.', '[Two sentences that open up the idea, drawn from the book.]'],
    ['[Second sentence, with <b class="hl">key words</b> highlighted.]', '[Two sentences that open up the idea, drawn from the book.]'],
    ['[Third sentence, with <b class="hl">key words</b> highlighted.]', '[Two sentences that open up the idea, drawn from the book.]'],
  ].map(([s, sub], i) => `<section class="ch thought s-taupe tx" data-chapter="IV" data-cursor="dark" data-snap aria-label="Chapter IV, philosophy, ${i + 1} of 3">
  <span class="cap">Chapter IV · ${i + 1} of 3</span>
  <p class="h1">${s}</p>
  <p class="body">${sub}</p>
  <div class="bars" aria-hidden="true">${[0, 1, 2].map((k) => `<i${k === i ? ' class="on"' : ''}></i>`).join('')}</div>
</section>`).join('\n')}
</div>

<!-- V · Work -->
<section id="work" class="ch work s-taupe tx" data-chapter="V" data-cursor="dark" data-snap aria-labelledby="work-h">
  <div class="wrap work-head">
    <div class="rv"><span class="cap">Chapter V</span><h2 id="work-h" class="h2">Work</h2></div>
    <div class="tabs cap" role="tablist" aria-label="Project categories" data-ring-group>
      ${CATS.map((c, i) => `<button type="button" role="tab" aria-selected="${i === 0}" data-cat="${c.slug}" data-name="${esc(c.name)}" data-ring>${esc(c.name)}</button>`).join('')}
    </div>
  </div>
  <div class="rows" role="tabpanel" aria-label="Projects">${rowsFor(base, first)}</div>
  ${CATS.map((c) => `<template data-cat="${c.slug}">${rowsFor(base, c)}</template>`).join('')}
  <div class="wrap work-foot cap">
    <span class="muted">Hover to pause · Click a project to open it</span>
    <a class="underline" href="${catHref(base, first)}" data-ring>View all ${first.name.toLowerCase()} →</a>
  </div>
</section>

<!-- VI · Contact -->
<section id="contact" class="ch contact s-moss tx" data-chapter="VI" data-cursor="light" data-snap aria-labelledby="contact-h">
  <span class="cap cap-gold rv">Chapter VI</span>
  <h2 id="contact-h" class="h1 rv">Your house begins <b class="hl">here.</b></h2>
  <div class="contact-cols rv">
    <div><span class="cap cap-gold">Studio</span><span>3652/2, 1st Floor, Green Field</span><span>Model Gram, Ludhiana 141002, Punjab</span></div>
    <div><span class="cap cap-gold">Talk</span><a href="tel:+918824396618">+91 88243 96618</a><a href="mailto:ceo@karukritdesigns.com">ceo@karukritdesigns.com</a></div>
  </div>
  <button class="btn btn-gold tx rv" type="button" data-ring data-open-form>Book a first meeting</button>

  <div class="form-panel s-taupe tx" data-cursor="dark" inert role="region" aria-label="Book a first meeting">
    <div class="top">
      <div><span class="cap">A first meeting</span><h2 class="h2">Tell us about your plot.</h2></div>
      <button class="form-close cap link-cap" type="button">Close ×</button>
    </div>
    <form novalidate data-endpoint="">
      <div class="form-grid">
        <div class="field"><label class="cap" for="f-name">Your name</label><input id="f-name" name="name" autocomplete="name" required><span class="err" aria-live="polite"></span></div>
        <div class="field"><label class="cap" for="f-phone">Phone</label><input id="f-phone" name="phone" type="tel" autocomplete="tel" required><span class="err" aria-live="polite"></span></div>
        <div class="field"><label class="cap" for="f-plot">Plot size and city</label><input id="f-plot" name="plot"><span class="err"></span></div>
        <div class="field"><label class="cap" for="f-planning">What are you planning?</label>
          <select id="f-planning" name="planning" required><option value="">Choose one</option>${['Residence', 'Hotel', 'Office', 'Convention centre', 'About the book', 'Other'].map((o) => `<option>${o}</option>`).join('')}</select><span class="err" aria-live="polite"></span></div>
        <div class="field wide"><label class="cap" for="f-msg">Message</label><textarea id="f-msg" name="message" rows="3"></textarea><span class="err"></span></div>
      </div>
      <div class="form-actions"><button class="btn btn-orange tx" type="submit">Send</button><span class="err small" aria-live="polite"></span></div>
    </form>
    <p class="thanks" tabindex="-1" hidden>Thank you. We'll call you within two working days.</p>
  </div>
  ${stripe}
</section>
</main>

<dialog id="pages-dialog" class="full tx" data-cursor="light" aria-labelledby="pages-title">
  <div class="full-top"><span id="pages-title" class="cap cap-gold full-title"></span><button class="full-close cap link-cap" type="button">Close ×</button></div>
  <div class="viewer"></div>
</dialog>

<script src="assets/vendor/lenis-1.1.13.min.js"></script>
<script src="assets/js/site.js"></script>
<script src="assets/js/home.js"></script>
</body>
</html>
`;
}

/* ---------- 10 category page ---------- */
function categoryPage(c) {
  const base = '../../';
  const list = PROJECTS.filter((p) => p.category === c.slug);
  return `${head({ base, title: `${c.name} | Karukrit Designs`, description: `${c.name} by Karukrit Designs, Ludhiana: completed, ongoing and concept projects.`, path: `projects/${c.slug}/` })}
<body class="s-taupe tx" data-cursor="dark">
<a class="skip-link cap" href="#main">Skip to content</a>
${topbar(base, false)}
${mobileMenu(base, false)}
<main id="main" class="page-top">
  <section class="wrap cat">
    <div class="work-head">
      <div><span class="cap">Work</span><h1 class="h2">${esc(c.name)}</h1></div>
      <nav aria-label="Project categories"><ul class="tabs cap" data-ring-group>${CATS.map((o) => `<li><a href="${catHref(base, o)}"${o.slug === c.slug ? ' aria-current="page"' : ''} data-ring>${esc(o.name)}</a></li>`).join('')}</ul></nav>
    </div>
    <div class="chips cap" role="group" aria-label="Show">
      ${[['all', 'All'], ['ongoing', 'Ongoing'], ['completed', 'Completed'], ['concept', 'Concept']].map(([v, t], i) => `<button type="button" data-filter="${v}" aria-pressed="${i === 0}" data-ring>${t}</button>`).join('')}
    </div>
    <ul class="cat-grid">${list.map((p) => `<li data-status="${p.status}">${tile(base, p)}</li>`).join('')}</ul>
  </section>
</main>
${footer(base)}
${lightboxAndScripts(base, false)}`;
}

function footer(base, next) {
  return `<footer class="wrap foot cap">
  ${next || `<a href="${base}index.html#contact" class="link-cap">Your house begins here. Contact the studio →</a>`}
  <span>Karukrit Designs · Ludhiana</span>
  ${stripe}
</footer>`;
}

function lightboxAndScripts(base, lightbox = true) {
  return `${lightbox ? `<dialog id="lightbox" class="full tx" data-cursor="light" aria-label="Image viewer">
  <div class="full-top"><span class="cap cap-gold lb-cap"></span><button class="full-close cap link-cap" type="button">Close ×</button></div>
  <div class="lightbox-stage"></div>
  <div class="viewer-bar"><span class="cap lb-n"></span><div class="viewer-nav">
    <button type="button" class="circle-btn" data-step="-1" aria-label="Previous image">←</button>
    <button type="button" class="circle-btn" data-step="1" aria-label="Next image">→</button></div></div>
</dialog>` : ''}
<script src="${base}assets/vendor/lenis-1.1.13.min.js"></script>
<script src="${base}assets/js/site.js"></script>
<script src="${base}assets/js/project.js"></script>
</body>
</html>
`;
}

/* ---------- 11 and 12 project pages ---------- */
function gallery(base, p, key, items) {
  // full-width and two-up images on a 12-column grid
  return `<div class="gallery">${items.map((it, i) => {
    const cls = items.length % 2 === 1 && i === 0 ? 'full-w' : 'half';
    return `<div class="${cls}"><button type="button" data-lightbox="${key}" data-caption="${esc(it.caption || it.label)}" aria-label="Open ${esc(it.caption || it.label)}">${visual(it.image, p.tint, it.label, base)}</button></div>`;
  }).join('')}</div>`;
}

function nextProject(base, p) {
  const list = PROJECTS.filter((q) => q.category === p.category);
  const n = list.length > 1 ? list[(list.indexOf(p) + 1) % list.length] : PROJECTS[(PROJECTS.indexOf(p) + 1) % PROJECTS.length];
  return `<a class="mono-host" href="${projectHref(base, n)}" data-ring>
    <div class="img mono">${visual(n.tileImage, n.tint, 'Photo · elevation', base)}</div>
    <span class="stack"><span class="cap">Next project →</span><span class="h2">${esc(n.name)}</span></span>
  </a>`;
}

function completedPage(p) {
  const base = '../../';
  const c = cat(p.category);
  const label = p.status === 'concept' ? `${c.one} · ${p.city} · Concept ${p.year}` : `${c.one} · ${p.city} · Completed ${p.year}`;
  const g = p.galleries || {};
  const sections = [
    ['site-photographs', 'I · Site photographs', g.site || [{ label: 'Site photograph · exterior' }, { label: 'Site photograph · exterior' }, { label: 'Site photograph · exterior' }]],
    ['interiors', 'II · Interiors', g.interiors || [{ label: 'Interior photograph' }, { label: 'Interior photograph' }, { label: 'Interior photograph' }]],
    ['walkthrough', 'III · Walkthrough', null],
    ['drawings', 'IV · Drawings', g.drawings || [{ label: 'Coloured furnished plan' }, { label: 'Section' }, { label: 'Concept diagram' }]],
  ];
  const hasWalk = !!p.walkthrough;
  return `${head({ base, title: `${p.name} | Karukrit Designs`, description: `${p.name}, ${c.one.toLowerCase()} by Karukrit Designs, ${p.city}.`, path: `projects/${p.slug}/` })}
<body class="s-taupe tx" data-cursor="dark">
<a class="skip-link cap" href="#main">Skip to content</a>
${topbar(base, false)}
${mobileMenu(base, false)}
<main id="main" class="page-top">
  <div class="s-orange tx" data-cursor="light">
    <div class="p-hero">${visual(p.heroImage, p.tint, 'Front elevation · render or photo', base, true)}</div>
    <div class="wrap g12 p-info">
      <div class="name-col"><span class="cap cap-gold">${esc(label)}</span><h1 class="h2">${esc(p.name)}</h1></div>
      <p class="brief body">${esc(p.brief || '[The brief and the one idea behind the design, in three or four sentences.]')}</p>
      <nav class="cap" aria-label="On this page" data-ring-group>
        <a href="#site-photographs" data-ring>I · Site photographs</a>
        <a href="#interiors" data-ring>II · Interiors</a>
        ${hasWalk ? '<a href="#walkthrough" data-ring>III · Walkthrough</a>' : ''}
        <a href="#drawings" class="cap-gold" data-ring>IV · Drawings</a>
      </nav>
    </div>
  </div>
  ${sections.map(([id, title, items]) => {
    if (id === 'walkthrough') return hasWalk ? `<section id="walkthrough" class="wrap gallery-sec"><h2 class="cap">${title}</h2><video controls preload="none" src="${base}${esc(p.walkthrough)}" style="width:100%"></video></section>` : '';
    return `<section id="${id}" class="wrap gallery-sec" aria-label="${esc(title)}"><h2 class="cap">${title}</h2>${gallery(base, p, id, items)}</section>`;
  }).join('\n  ')}
  <section class="wrap gallery-sec" aria-label="Project facts">
    <h2 class="cap">Facts</h2>
    <div style="overflow-x:auto"><table class="facts"><tbody>
      <tr><th scope="row">Plot</th><td>${esc(p.plot || '[Plot]')}</td></tr>
      <tr><th scope="row">Built-up area</th><td>${esc(p.area || '[Built-up area]')}</td></tr>
      <tr><th scope="row">Scope</th><td>${esc(p.scope || '[Scope, for example Architecture, interiors]')}</td></tr>
      <tr><th scope="row">Year</th><td>${esc(p.year)}</td></tr>
    </tbody></table></div>
  </section>
</main>
${footer(base, nextProject(base, p))}
${lightboxAndScripts(base)}`;
}

function ongoingPage(p) {
  const base = '../../';
  const c = cat(p.category);
  const stageClass = (k) => (k + 1 < p.stage ? 'done' : k + 1 === p.stage ? 'now' : 'later');
  const latest = p.latest || [{ label: 'Site photo', caption: 'Site photo · [Date]' }, { label: 'Site photo', caption: 'Site photo · [Date]' }];
  const archive = STAGES.slice(0, p.stage).map((s, k) => ({ stage: `Stage ${k + 1} · ${s}`, photos: [{ label: 'Site photo', caption: `${s} · [Date]` }, { label: 'Site photo', caption: `${s} · [Date]` }] }));
  return `${head({ base, title: `${p.name} | Karukrit Designs`, description: `${p.name}, an ongoing ${c.one.toLowerCase()} by Karukrit Designs in ${p.city}, now at stage ${p.stage} of 6.`, path: `projects/${p.slug}/` })}
<body class="s-taupe tx" data-cursor="dark">
<a class="skip-link cap" href="#main">Skip to content</a>
${topbar(base, false)}
${mobileMenu(base, false)}
<main id="main" class="page-top">
  <section class="wrap ongoing">
    <div class="p-head">
      <div class="stack" style="gap:12px"><span class="cap">Ongoing · ${esc(p.city)}</span><h1 class="h2">${esc(p.name)}</h1></div>
      <span class="cap muted">Updated ${esc(p.updated)}</span>
    </div>
    <ol class="stages" aria-label="Stages, now at stage ${p.stage} of 6">
      ${STAGES.map((s, k) => `<li class="${stageClass(k)} tx"${k + 1 === p.stage ? ' aria-current="step"' : ''}>${s}${k + 1 === p.stage ? ' · now' : ''}</li>`).join('')}
    </ol>
    <div class="photo-grid">
      <figure class="wide"><button type="button" data-lightbox="latest" data-caption="How it will look" aria-label="Open the render">${visual(p.render, p.tint, 'Render · how it will look', base, true)}</button></figure>
      ${latest.map((it) => `<figure><button type="button" data-lightbox="latest" data-caption="${esc(it.caption)}" aria-label="Open ${esc(it.caption)}">${visual(it.image, '#948E89', it.label, base)}</button><figcaption class="cap muted">${esc(it.caption)}</figcaption></figure>`).join('')}
    </div>
    <div class="archive">
      <h2 class="cap">Site photo archive</h2>
      ${archive.reverse().map((a, k) => `<section aria-label="${esc(a.stage)}"><h3 class="cap muted">${esc(a.stage)}</h3><div class="photo-grid">${a.photos.map((it) => `<figure><button type="button" data-lightbox="archive" data-caption="${esc(it.caption)}" aria-label="Open ${esc(it.caption)}">${visual(it.image, '#948E89', it.label, base)}</button><figcaption class="cap muted">${esc(it.caption)}</figcaption></figure>`).join('')}</div></section>`).join('')}
    </div>
  </section>
</main>
${footer(base, nextProject(base, p))}
${lightboxAndScripts(base)}`;
}

/* ---------- write everything ---------- */
const out = (rel, html) => { const f = join(ROOT, rel); mkdirSync(dirname(f), { recursive: true }); writeFileSync(f, html); };
// clear old generated pages so removed projects disappear
if (existsSync(join(ROOT, 'projects'))) for (const d of readdirSync(join(ROOT, 'projects'))) rmSync(join(ROOT, 'projects', d), { recursive: true, force: true });
out('index.html', home());
CATS.forEach((c) => out(`projects/${c.slug}/index.html`, categoryPage(c)));
PROJECTS.forEach((p) => out(`projects/${p.slug}/index.html`, p.status === 'ongoing' ? ongoingPage(p) : completedPage(p)));
console.log(`Built index.html, ${CATS.length} category pages and ${PROJECTS.length} project pages.`);
