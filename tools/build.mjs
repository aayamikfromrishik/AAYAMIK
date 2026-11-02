// Builds the whole website into dist/. Run: npm run build
// Content comes from the studio's folder (site-content/, a mirror of Z:\2_Office Data\KD WEBSITE).
// Anything the folder does not have yet falls back to the placeholders in content/projects.json.
// Section numbers in comments refer to docs/KARUKRIT_WEBSITE_SPEC.md.
import { readFileSync, writeFileSync, mkdirSync, existsSync, rmSync, cpSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { loadContent, Media } from './content.mjs';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const OUT = resolve(ROOT, process.env.KD_OUT || 'dist');
const CONTENT_DIR = resolve(ROOT, process.env.KD_CONTENT || 'site-content');
const data = JSON.parse(readFileSync(join(ROOT, 'content/projects.json'), 'utf8'));
rmSync(OUT, { recursive: true, force: true });
mkdirSync(OUT, { recursive: true });
const media = new Media(OUT, join(ROOT, '.cache/media'));
const C = loadContent(CONTENT_DIR, media);
await media.run();
const PROJECTS = C.projects || data.projects;
// a category shows only once it has a project in it
const CATS = (C.categories || data.categories).filter((c) => PROJECTS.some((p) => p.category === c.slug));
const SITE = 'https://karukritdesigns.com/';
const HAS_SATOSHI = existsSync(join(ROOT, 'assets/fonts/Satoshi-Light.woff2'));
const STAGES = ['Design', 'Approvals', 'Structure', 'Masonry and services', 'Finishing', 'Handover'];

const esc = (s = '') => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
const cat = (slug) => CATS.find((c) => c.slug === slug);
const statusText = (p) => p.status === 'ongoing' ? `Ongoing · stage ${p.stage} of 6` : p.status === 'concept' ? `Concept · ${p.year}` : `Completed · ${p.city}`;
const projectHref = (base, p) => `${base}projects/${p.slug}/index.html`;
const catHref = (base, c) => `${base}projects/${c.slug}/index.html`;

// an image from the studio, or a labelled placeholder in the project's tint until one exists
const withBase = (base, srcset) => srcset.split(', ').map((x) => base + x).join(', ');
const visual = (img, tint, label, base, eager = false, sizes = '(max-width: 767px) 100vw, 50vw') => {
  if (!img) return `<div class="ph tx" style="background-color:${tint}" role="img" aria-label="${esc(label)}, placeholder"><span class="cap">[${esc(label)}]</span></div>`;
  const lazy = eager ? '' : ' loading="lazy" decoding="async"';
  // 16: AVIF and WebP with a JPEG fallback, each at two sizes
  if (img.srcset) return `<picture><source type="image/avif" srcset="${withBase(base, img.srcset('avif'))}" sizes="${sizes}"><source type="image/webp" srcset="${withBase(base, img.srcset('webp'))}" sizes="${sizes}"><img src="${base}${img.src}" srcset="${withBase(base, img.srcset('jpg'))}" sizes="${sizes}" alt="${esc(img.alt)}"${lazy}></picture>`;
  return `<picture>${img.webp ? `<source srcset="${base}${esc(img.webp)}" type="image/webp">` : ''}<img src="${base}${esc(img.src)}" alt="${esc(img.alt)}"${lazy}></picture>`;
};
// "*a hundred decisions*" in the studio's text becomes the highlighted words
const highlight = (t) => esc(t).replace(/\*(.+?)\*/g, '<b class="hl">$1</b>');

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
${home ? `<script type="importmap">{ "imports": { "three": "./assets/vendor/three/three.module.min.js", "three/addons/": "./assets/vendor/three/addons/" } }</script>
<script>
  // 5.1 the logo animation plays on the first visit only
  try { if (!localStorage.getItem('kd_intro_seen')) { document.documentElement.classList.add('kd-intro');
    var l = document.createElement('link'); l.rel = 'preload'; l.as = 'video'; l.href = 'assets/loader/KD_logo_animation_alpha_8s.mp4'; document.head.appendChild(l); } } catch (e) {}
</script>` : ''}
</head>`;
}

// the opening scroll is the home page; every chapter after it has its own page
const NAV = [['About', 'about'], ['Team', 'team'], ['Philosophy', 'philosophy'], ['Projects', 'projects'], ['Contact', 'contact']];
const pageHref = (base, slug) => `${base}${slug}/index.html`;
const navLinks = (base, current) => NAV.map(([t, slug]) => `<li><a class="cap" href="${pageHref(base, slug)}"${slug === current ? ' aria-current="page"' : ''} data-ring>${t}</a></li>`).join('');

function topbar(base, current, home = false) {
  return `<header class="topbar tx${home ? '' : ' always'}">
  <div class="wrap">
    <a class="wordmark" href="${base}index.html" aria-label="Karukrit Designs, home"><img src="${base}assets/brand/wordmark-dark-TRACED.svg" alt="Karukrit Designs" width="230" height="18"></a>
    <nav aria-label="Main"><ul class="menu" data-ring-group>${navLinks(base, current)}</ul></nav>
    <button class="menu-btn" type="button" aria-label="Open menu"><i></i><i></i></button>
  </div>
</header>`;
}

function mobileMenu(base, current) {
  return `<div class="mobile-menu s-moss tx" data-cursor="light" inert aria-label="Menu">
  <div class="row">
    <img class="wordmark" src="${base}assets/brand/wordmark-light-TRACED.svg" alt="Karukrit Designs" width="160" height="13">
    <button class="menu-close cap link-cap" type="button">Close</button>
  </div>
  <nav aria-label="Main"><ul data-ring-group><li><a href="${base}index.html" data-ring>Home</a></li>${NAV.map(([t, slug]) => `<li><a href="${pageHref(base, slug)}"${slug === current ? ' aria-current="page"' : ''} data-ring>${t}</a></li>`).join('')}</ul></nav>
</div>`;
}

// 4 the chapter indicator: the current numeral, and a list of every chapter page
const CHAPTERS = [['I', 'Home', ''], ['II', 'The architect and the author', 'about'], ['III', 'The studio', 'team'], ['IV', 'Philosophy', 'philosophy'], ['V', 'Work', 'projects'], ['VI', 'Contact', 'contact']];
function indicator(base, current) {
  return `<div class="indicator cap">
  <button type="button" aria-expanded="false" aria-controls="chapter-list" aria-label="Chapters"><span class="cur">${CHAPTERS.find((c) => c[2] === current)?.[0] || 'I'}</span><span class="line"></span><span class="last">VI</span></button>
  <ol id="chapter-list" class="tx" hidden data-ring-group>
    ${CHAPTERS.map(([n, t, slug]) => `<li><a href="${slug ? pageHref(base, slug) : base + 'index.html'}"${slug === current ? ' aria-current="page"' : ''} data-ring><span>${n}</span><span>${t}</span></a></li>`).join('\n    ')}
  </ol>
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
  const fill = (row) => { const out = []; while (row.length && out.length < 6) out.push(...row); return out; };
  const row = (items, cls) => {
    const full = fill(items);
    const seen = new Set();
    const tiles = full.map((p) => { const dup = seen.has(p.slug); seen.add(p.slug); return tile(base, p, dup); }).join('');
    // the row is duplicated once so the loop is seamless; one cycle of 6 tiles takes 48 s
    return `<div class="marq"><div class="track ${cls}" style="--dur:${(48 * full.length / 6).toFixed(1)}s">${tiles}${full.map((p) => tile(base, p, true)).join('')}</div></div>`;
  };
  return row(r1, 'row1') + row(r2, 'row2');
}

const CONTACT = C.contact || {};
const ADDRESS = CONTACT.address || ['3652/2, 1st Floor, Green Field', 'Model Gram, Ludhiana 141002, Punjab'];
const PHONE = CONTACT.phone || '+91 88243 96618';
const EMAIL = CONTACT.email || 'ceo@karukritdesigns.com';
const MEMBERS = C.members || [{ name: 'Kuljeet' }, { name: 'Krishma' }, { name: 'Sanchit' }, { name: '[Fourth member]' }];

/* ---------- home page ---------- */
const SKETCHES = [
  { src: 'assets/sketches/sketch-01.svg', name: '[Residence name]', alt: 'Pencil sketch of a two-storey house elevation', glow: ['#818865', '#BB8D3F', '#818865', '#8B4729', '#2A2D1B', '#BB8D3F'] },
  { src: 'assets/sketches/sketch-02.svg', name: '[Residence name]', alt: 'Pencil sketch of a long single-storey house with a timber screen', glow: ['#BB8D3F', '#8B4729', '#818865', '#BB8D3F', '#2A2D1B', '#818865'] },
  { src: 'assets/sketches/sketch-03.svg', name: '[Residence name]', alt: 'Pencil sketch of a three-storey house with a stair tower', glow: ['#8B4729', '#818865', '#BB8D3F', '#2A2D1B', '#818865', '#8B4729'] },
  { src: 'assets/sketches/sketch-04.svg', name: '[Residence name]', alt: 'Pencil sketch of a ground floor plan around a courtyard', glow: ['#818865', '#2A2D1B', '#BB8D3F', '#818865', '#8B4729', '#BB8D3F'] },
];
const GLOW_SETS = SKETCHES.map((s) => s.glow);
if (C.sketches && C.sketches.length) {
  SKETCHES.length = 0;
  C.sketches.forEach((s, i) => SKETCHES.push({
    // sketches keep their transparent paper, so they are shown as WebP
    src: `media/${s.image.name}-${s.image.widths[s.image.widths.length - 1]}.webp`, name: s.name, alt: s.alt,
    render: s.render ? `media/${s.render.name}-${s.render.widths[0]}.jpg` : null, glow: GLOW_SETS[i % GLOW_SETS.length],
  }));
}
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
<a class="skip-link cap" href="#contents">Skip to content</a>

<div class="loader tx" aria-hidden="true">
  <!-- 5.1 the logo draws itself straight onto the moss leather: a transparent animation, no box behind it.
       The video holds colour in its top half and transparency in its bottom half; home.js combines them on a canvas. -->
  <canvas class="logo-anim"></canvas>
  <img class="logo-last" src="assets/loader/KD_logo_last.webp" alt="" width="1600" height="880">
  <video muted playsinline preload="none" src="assets/loader/KD_logo_animation_alpha_8s.mp4"></video>
</div>

${topbar(base, '', true)}
${mobileMenu(base, '')}

${indicator(base, '')}

<main>
<!-- I · Home: frosted glass. Scrolling shrinks the glass into a card and the 3D house is drawn, modelled and finished behind it. -->
<div id="home" class="hero-scroll" data-chapter="I" data-cursor="light" data-snap>
<section class="ch hero s-moss tx" aria-label="Chapter I, home">
  <div class="glowsets" aria-hidden="true">${SKETCHES.map(glowset).join('')}</div>
  <canvas id="house" role="img" aria-label="A house drawn as a plan on paper, rising into walls, then shown as a white model and as the finished home"${C.model ? ` data-model="${C.model}"` : ''}></canvas>
  <div class="glass hero-fade" data-cursor="dark">
    <div class="pane tx" aria-hidden="true"></div>
    <div class="glass-top fades">
      <a class="wordmark" href="index.html" aria-label="Karukrit Designs, home"><img src="assets/brand/wordmark-dark-TRACED.svg" alt="Karukrit Designs" width="230" height="18"></a>
      <nav aria-label="Chapters"><ul class="menu" data-ring-group>${navLinks(base, '')}</ul></nav>
      <button class="menu-btn" type="button" aria-label="Open menu"><i></i><i></i></button>
    </div>
    <div class="g12 glass-body">
      <div class="sketch-col fades">
        <div class="sketches">${SKETCHES.map((s, i) => `<img src="${s.src}" alt="${esc(s.alt)}" data-name="${esc(s.name)}"${i === 0 ? ' class="on"' : ' loading="lazy"'}>`).join('')}</div>
        <div class="sketch-meta">
          <span class="cap sketch-cap" aria-live="polite">Sketch 01 · ${esc(SKETCHES[0].name)}</span>
          <div class="dots">${SKETCHES.map((_, i) => `<button type="button" aria-label="Show sketch ${i + 1}" aria-current="${i === 0}"></button>`).join('')}</div>
        </div>
      </div>
      <div class="hero-text">
        <span class="cap">Chapter I</span>
        <h1 class="h1"><b class="hl">Every house</b> begins as a line on paper.</h1>
        <div class="build-stages cap" aria-hidden="true"><span class="on">Plan</span><i></i><span>Model</span><i></i><span>Home</span></div>
        <a class="btn btn-orange tx" href="projects/index.html" data-ring>View projects</a>
        <a class="cap link-cap" href="#build">Scroll to begin ↓</a>
      </div>
    </div>
  </div>
</section>
<span id="build" class="build-anchor" aria-hidden="true"></span>
</div>

<!-- II · The architect -->
<section id="about" class="ch arch s-taupe tx" data-chapter="II" data-cursor="dark" data-snap aria-labelledby="arch-h">
  <div class="portrait mono-host">${C.portrait ? `<div class="mono portrait-img">${visual(C.portrait, '', '', base, false, '(max-width: 767px) 100vw, 50vw')}</div>` : '<div class="mono ph tx" style="background-color:var(--sage);height:100%" role="img" aria-label="Portrait of Ar. Saptarshi Kapri, placeholder"><span class="cap">[Portrait · full height]</span></div>'}</div>
  <div class="arch-text" data-stagger>
    <span class="cap rv">Chapter II · The architect</span>
    <h2 id="arch-h" class="h1 rv"><b class="hl">Ar. Saptarshi</b> Kapri</h2>
    ${(C.story || ['[Your story, first short paragraph.]', '[Your story, second short paragraph.]']).map((t) => `<p class="body muted rv">${esc(t)}</p>`).join('\n    ')}
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
      <div class="book-wrap rv">
        <button class="book3d" type="button" data-pages="book" aria-label="The 100 Decisions Before the First Brick by Ar. Saptarshi Kapri. Read a sample">
          <span class="b-back"></span><span class="b-spine"></span><span class="b-pages"></span>
          <span class="b-inside">${bookPic('book-p15', '')}</span>
          <span class="b-cover">${bookPic('book-cover-front', '')}</span>
        </button>
      </div>
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
    <p class="body rv">${esc(C.teamSentence || '[One sentence on how the team works together, from first sketch to site.]')}</p>
  </div>
  <ul class="wrap team-grid" data-stagger>
    ${MEMBERS.map((m) => `<li class="member mono-host rv">
      <div class="frame tilt">${m.photo ? `<div class="mono portrait-img">${visual(m.photo, '', '', base, false, '(max-width: 767px) 50vw, 25vw')}</div>` : `<div class="mono ph tx" style="background-color:var(--sage)" role="img" aria-label="Portrait of ${esc(m.name)}, placeholder"><span class="cap">[Portrait]</span></div>`}</div>
      <span class="name">${esc(m.name)}</span><span class="cap">${esc(m.role || '[Role]')}</span>
    </li>`).join('')}
  </ul>
</section>

<!-- IV · Philosophy: three screens, one sentence each -->
<div id="philosophy" class="philosophy s-taupe tx">
<div class="philo-back" aria-hidden="true"><div class="philo-draw">
  <svg viewBox="0 0 1000 700" preserveAspectRatio="xMidYMid slice"><g fill="none" stroke="currentColor" stroke-width="1.2">
    <rect x="140" y="120" width="720" height="460"/><rect x="220" y="190" width="300" height="300"/><rect x="520" y="230" width="140" height="260"/>
    <rect x="660" y="150" width="120" height="140"/><path d="M220 400h300M370 190v300M520 360h140"/>
    <path d="M300 490a50 50 0 0 1 50-50M560 230a40 40 0 0 0 40 40"/>
    <path d="M140 640h720M140 630v20M860 630v20M100 120v460M90 120h20M90 580h20"/>
    <circle cx="820" cy="520" r="40"/><circle cx="210" cy="560" r="28"/></g></svg>
</div></div>
${(C.philosophy || [
    { sentence: 'A home is *a hundred decisions*, made in the right order.', sub: '[Two sentences that open up the idea, drawn from the book.]' },
    { sentence: '[Second sentence, with *key words* highlighted.]', sub: '[Two sentences that open up the idea, drawn from the book.]' },
    { sentence: '[Third sentence, with *key words* highlighted.]', sub: '[Two sentences that open up the idea, drawn from the book.]' },
  ]).map((x) => [highlight(x.sentence), esc(x.sub)]).map(([s, sub], i, all) => `<section class="ch thought" data-chapter="IV" data-cursor="dark" data-snap aria-label="Chapter IV, philosophy, ${i + 1} of 3">
  <span class="cap">Chapter IV · ${i + 1} of ${all.length}</span>
  <p class="h1">${s}</p>
  <p class="body">${sub}</p>
  <div class="bars" aria-hidden="true">${all.map((_, k) => `<i${k === i ? ' class="on"' : ''}></i>`).join('')}</div>
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
    <div><span class="cap cap-gold">Studio</span>${ADDRESS.map((l) => `<span>${esc(l)}</span>`).join('')}${CONTACT.hours ? `<span class="muted">${esc(CONTACT.hours)}</span>` : ''}</div>
    <div><span class="cap cap-gold">Talk</span><a href="tel:${PHONE.replace(/[^+\d]/g, '')}">${esc(PHONE)}</a><a href="mailto:${esc(EMAIL)}">${esc(EMAIL)}</a>${CONTACT.instagram ? `<a href="${esc(/^https?:/.test(CONTACT.instagram) ? CONTACT.instagram : 'https://instagram.com/' + CONTACT.instagram.replace(/^@/, ''))}" target="_blank" rel="noopener">Instagram</a>` : ''}</div>
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
<script type="module" src="assets/js/hero3d.js"></script>
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
${topbar(base, 'projects')}
${mobileMenu(base, 'projects')}
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
  ${next || `<a href="${pageHref(base, 'contact')}" class="link-cap" data-ring>Your house begins here. Contact the studio →</a>`}
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
  const hasWalk = !!(p.walkthrough || p.walkthroughLink);
  return `${head({ base, title: `${p.name} | Karukrit Designs`, description: `${p.name}, ${c.one.toLowerCase()} by Karukrit Designs, ${p.city}.`, path: `projects/${p.slug}/` })}
<body class="s-taupe tx" data-cursor="dark">
<a class="skip-link cap" href="#main">Skip to content</a>
${topbar(base, 'projects')}
${mobileMenu(base, 'projects')}
<main id="main" class="page-top">
  <div class="s-orange tx" data-cursor="light">
    <div class="walk">
      <div class="walk-pin">
        <div class="walk-in">${visual(g.interiors && g.interiors[0] && g.interiors[0].image, '#45492D', 'Interior · through the front door', base)}</div>
        <div class="walk-out" style="--door-x:${(p.door && p.door.x) || 50}%;--door-y:${(p.door && p.door.y) || 72}%">${visual(p.heroImage, p.tint, 'Front elevation · render or photo', base, true)}${p.heroImage ? '' : '<i class="door" aria-hidden="true"></i>'}<span class="cap walk-hint" aria-hidden="true">Scroll to walk in</span></div>
      </div>
    </div>
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
    if (id === 'walkthrough') return !hasWalk ? '' : `<section id="walkthrough" class="wrap gallery-sec"><h2 class="cap">${title}</h2>${p.walkthrough ? `<video controls preload="none" src="${base}${esc(p.walkthrough)}" style="width:100%"></video>` : `<a class="btn btn-line" href="${esc(p.walkthroughLink)}" target="_blank" rel="noopener" data-ring>Watch the walkthrough →</a>`}</section>`;
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
  const archive = p.archive || STAGES.slice(0, p.stage).map((s, k) => ({ stage: `Stage ${k + 1} · ${s}`, photos: [{ label: 'Site photo', caption: `${s} · [Date]` }, { label: 'Site photo', caption: `${s} · [Date]` }] }));
  return `${head({ base, title: `${p.name} | Karukrit Designs`, description: `${p.name}, an ongoing ${c.one.toLowerCase()} by Karukrit Designs in ${p.city}, now at stage ${p.stage} of 6.`, path: `projects/${p.slug}/` })}
<body class="s-taupe tx" data-cursor="dark">
<a class="skip-link cap" href="#main">Skip to content</a>
${topbar(base, 'projects')}
${mobileMenu(base, 'projects')}
<main id="main" class="page-top">
  <section class="wrap ongoing">
    <div class="p-head">
      <div class="stack" style="gap:12px"><span class="cap">Ongoing · ${esc(p.city)}</span><h1 class="h2">${esc(p.name)}</h1></div>
      <span class="cap muted">Updated ${esc(p.updated)}</span>
    </div>
    <ol class="stages fill" aria-label="Stages, now at stage ${p.stage} of 6">
      ${STAGES.map((s, k) => `<li class="${stageClass(k)} tx"${k + 1 === p.stage ? ' aria-current="step"' : ''}>${s}${k + 1 === p.stage ? ' · now' : ''}</li>`).join('')}
    </ol>
    <figure class="progress-draw">
      <svg class="grow" viewBox="0 0 600 360" role="img" aria-label="Elevation drawing built up to stage ${p.stage} of 6" data-now="${p.stage}">
        <g data-step="1"><path d="M40 320h520M70 320v-18h460v18"/></g>
        <g data-step="2"><path d="M90 302V190M250 302V190M410 302V190M510 302V190"/></g>
        <g data-step="3"><path d="M70 190h460v-12H70zM90 178V80M250 178V80M410 178V80M510 178V80M70 80h460V68H70zM60 68h480"/></g>
        <g data-step="4"><path d="M90 302h160M250 302h160M120 302v-80h100v80M290 290v-70h90v70M440 290v-70h50v70M120 178v-70h100v70M290 178v-60h180v60"/></g>
        <g data-step="5"><path d="M300 178v-60M330 178v-60M360 178v-60M390 178v-60M420 178v-60M450 178v-60M140 302v-60h60"/></g>
        <g data-step="6"><path d="M20 320c20-60 50-60 60 0M540 320c10-80 50-80 50 0M560 320v-40"/><circle cx="50" cy="270" r="26"/><circle cx="565" cy="250" r="30"/></g>
      </svg>
      <figcaption class="cap muted">Progress drawing · stage ${p.stage} of 6</figcaption>
    </figure>
    <div class="photo-grid">
      <figure class="wide"><button type="button" data-lightbox="latest" data-caption="How it will look" aria-label="Open the render">${visual(p.render, p.tint, 'Render · how it will look', base, true)}</button></figure>
      ${latest.map((it) => `<figure><button type="button" data-lightbox="latest" data-caption="${esc(it.caption)}" aria-label="Open ${esc(it.caption)}">${visual(it.image, '#948E89', it.label, base)}</button><figcaption class="cap muted">${esc(it.caption)}</figcaption></figure>`).join('')}
    </div>
    <div class="archive">
      <h2 class="cap">Site photo archive</h2>
      ${(p.archive ? archive : archive.reverse()).map((a, k) => `<section aria-label="${esc(a.stage)}"><h3 class="cap muted">${esc(a.stage)}</h3><div class="photo-grid">${a.photos.map((it) => `<figure><button type="button" data-lightbox="archive" data-caption="${esc(it.caption)}" aria-label="Open ${esc(it.caption)}">${visual(it.image, '#948E89', it.label, base)}</button><figcaption class="cap muted">${esc(it.caption)}</figcaption></figure>`).join('')}</div></section>`).join('')}
    </div>
  </section>
</main>
${footer(base, nextProject(base, p))}
${lightboxAndScripts(base)}`;
}

/* ---------- the home page and the chapter pages ---------- */
// home() renders every chapter in one document; the pages below take their sections from it
const between = (html, a, b) => { const i = html.indexOf(a), j = html.indexOf(b, i); if (i < 0 || j < 0) throw new Error(`missing ${a}`); return html.slice(i, j); };
const rebase = (html) => html.replace(/(src|href|srcset|data-model)="(assets|projects|media)\//g, '$1="../$2/').replace(/, media\//g, ', ../media/');

function contents() {
  const rows = [
    ['II', 'The architect and the author', 'Ar. Saptarshi Kapri, and The 100 Decisions Before the First Brick', 'about'],
    ['III', 'The studio', MEMBERS.map((m) => m.name).join(', ').replace(/, ([^,]*)$/, ' and $1'), 'team'],
    ['IV', 'Philosophy', 'A home is a hundred decisions, made in the right order.', 'philosophy'],
    ['V', 'Work', 'Residences, hotels, offices and convention centres', 'projects'],
    ['VI', 'Contact', ADDRESS.join(', '), 'contact'],
  ];
  return `<section id="contents" class="contents s-taupe tx" data-cursor="dark" data-snap aria-labelledby="contents-h">
  <div class="wrap" data-stagger>
    <h2 id="contents-h" class="cap rv">Contents</h2>
    <ol class="toc">${rows.map(([n, t, d, slug]) => `
      <li class="rv"><a href="${pageHref('', slug)}" data-ring><span class="cap num">${n}</span><span class="t">${t}</span><span class="d">${esc(d)}</span><span class="arr" aria-hidden="true">→</span></a></li>`).join('')}
    </ol>
  </div>
</section>`;
}

function pages() {
  const full = home();
  const sec = {
    about: between(full, '<!-- II · The architect -->', '<!-- III · The studio -->'),
    team: between(full, '<!-- III · The studio -->', '<!-- IV · Philosophy'),
    philosophy: between(full, '<!-- IV · Philosophy', '<!-- V · Work -->'),
    projects: between(full, '<!-- V · Work -->', '<!-- VI · Contact -->'),
    contact: between(full, '<!-- VI · Contact -->', '</main>'),
  };
  const dialog = between(full, '<dialog id="pages-dialog"', '<script src=');
  const scripts = full.slice(full.indexOf('<script src='));
  const homePage = full.slice(0, full.indexOf('<!-- II · The architect -->')) + contents() + '\n</main>\n' + footer('') + '\n' + scripts;
  const result = { 'index.html': homePage };
  const META = {
    about: ['The architect and the author | Karukrit Designs', 'Ar. Saptarshi Kapri, founder of Karukrit Designs, and his book The 100 Decisions Before the First Brick.'],
    team: ['The studio | Karukrit Designs', 'The team at Karukrit Designs, Ludhiana.'],
    philosophy: ['Philosophy | Karukrit Designs', 'A home is a hundred decisions, made in the right order.'],
    projects: ['Work | Karukrit Designs', 'Residences, hotels, offices and convention centres by Karukrit Designs.'],
    contact: ['Contact | Karukrit Designs', 'Visit the studio in Model Gram, Ludhiana, or call +91 88243 96618.'],
  };
  for (const [slug, body] of Object.entries(sec)) {
    const base = '../';
    let main = rebase(body);
    // "Connect to the author" opens the contact form on the contact page, with "About the book" chosen
    main = main.replace('<button class="btn btn-gold tx" type="button" data-ring data-open-form data-topic="About the book">Connect to the author</button>',
      `<a class="btn btn-gold tx" href="${pageHref(base, 'contact')}#about-the-book" data-ring>Connect to the author</a>`);
    result[`${slug}/index.html`] = `${head({ base, title: META[slug][0], description: META[slug][1], path: `${slug}/` })}
<body class="s-taupe tx" data-cursor="dark">
<a class="skip-link cap" href="#main">Skip to content</a>
${topbar(base, slug)}
${mobileMenu(base, slug)}
${indicator(base, slug)}
<main id="main" class="page-top">
${main}
</main>
${slug === 'contact' ? '' : footer(base)}

<script src="${base}assets/vendor/lenis-1.1.13.min.js"></script>
<script src="${base}assets/js/site.js"></script>
${slug === 'about' ? `<script src="${base}assets/vendor/page-flip-2.0.7.browser.js"></script>
<script src="${base}assets/js/book.js"></script>` : ''}
<script src="${base}assets/js/home.js"></script>
</body>
</html>
`;
  }
  return result;
}

/* ---------- the client quiz: /quiz/?c=CODE ----------
   Links are made in the Karukrit Work Desk. Each code carries the project code, an expiry date and a signature
   made with QUIZ_SECRET, so the server can check it without keeping a list. The Manus quiz opens inside the page
   and receives the code as ?client=..., so every result saved in Google Drive is tagged with the project. */
const QUIZ_LINK_FILE = join(CONTENT_DIR, '7 Quiz', 'quiz-link.txt');
const QUIZ_URL = (process.env.QUIZ_URL || (existsSync(QUIZ_LINK_FILE) ? (readFileSync(QUIZ_LINK_FILE, 'utf8').match(/https?:\/\/\S+/) || [''])[0] : '')).trim();
const phpStr = (v) => `'${String(v).replace(/\\/g, '\\\\').replace(/'/g, "\\'")}'`;
function quizPage() {
  const base = '../';
  const msg = (title, text) => `<section class="quiz-msg wrap"><span class="cap">Client questionnaire</span><h1 class="h2">${title}</h1><p class="body">${text}</p>
    <p class="body">Call <a href="tel:${PHONE.replace(/[^+\d]/g, '')}">${esc(PHONE)}</a> or write to <a href="mailto:${esc(EMAIL)}">${esc(EMAIL)}</a>.</p></section>`;
  return `<?php
// Checks the invite code, then shows the Manus quiz. Settings are in config.php, written by the build.
header('X-Robots-Tag: noindex, nofollow');
header('Referrer-Policy: no-referrer');
$cfg = is_file(__DIR__ . '/config.php') ? include __DIR__ . '/config.php' : ['secret' => '', 'quiz' => ''];
$code = isset($_GET['c']) ? strtoupper(trim($_GET['c'])) : '';
$state = 'missing';
if ($code !== '' && preg_match('/^([A-Z0-9-]{2,24})_(\\d{6})_([A-Z0-9]{4})_([A-F0-9]{10})$/', $code, $m)) {
  $expected = strtoupper(substr(hash_hmac('sha256', $m[1] . '_' . $m[2] . '_' . $m[3], $cfg['secret']), 0, 10));
  if ($cfg['secret'] === '' || !hash_equals($expected, $m[4])) { $state = 'invalid'; }
  else {
    $tz = new DateTimeZone('Asia/Kolkata');
    $until = DateTime::createFromFormat('ymd H:i:s', $m[2] . ' 23:59:59', $tz);
    $state = ($until && $until >= new DateTime('now', $tz)) ? 'ok' : 'expired';
  }
} elseif ($code !== '') { $state = 'invalid'; }
if ($state === 'ok' && $cfg['quiz'] === '') { $state = 'notready'; }
$src = $state === 'ok' ? $cfg['quiz'] . (strpos($cfg['quiz'], '?') === false ? '?' : '&') . 'client=' . rawurlencode($code) : '';
?>${head({ base, title: 'Client questionnaire | Karukrit Designs', description: 'A private questionnaire for Karukrit Designs clients.', path: 'quiz/' }).replace('<meta name="description"', '<meta name="robots" content="noindex, nofollow">\n<meta name="description"')}
<body class="s-taupe tx quiz-body" data-cursor="dark">
${topbar(base, '')}
<main id="main" class="page-top">
<?php if ($state === 'ok'): ?>
  <div class="quiz-frame">
    <iframe src="<?= htmlspecialchars($src, ENT_QUOTES) ?>" title="Karukrit Designs client questionnaire" allow="clipboard-write; fullscreen" loading="eager"></iframe>
  </div>
  <p class="quiz-alt cap wrap">If the questionnaire does not load, <a class="underline" href="<?= htmlspecialchars($src, ENT_QUOTES) ?>" target="_blank" rel="noopener">open it in a new tab</a>.</p>
<?php elseif ($state === 'expired'): ?>
  ${msg('This link has expired.', 'Questionnaire links are valid for a limited time. Ask your project in-charge for a new one.')}
<?php elseif ($state === 'notready'): ?>
  ${msg('The questionnaire is being set up.', 'Please try again shortly.')}
<?php else: ?>
  ${msg('This questionnaire is by invitation.', 'It opens from the personal link your project in-charge sends you. If you are a client and need a link, get in touch.')}
<?php endif; ?>
</main>
<script src="${base}assets/js/site.js"></script>
</body>
</html>
`;
}

/* ---------- write everything into dist/ ---------- */
const notesLater = [];
const out = (rel, html) => { const f = join(OUT, rel); mkdirSync(dirname(f), { recursive: true }); writeFileSync(f, html); };
cpSync(join(ROOT, 'assets'), join(OUT, 'assets'), { recursive: true });
for (const [rel, html] of Object.entries(pages())) out(rel, html);
out('quiz/index.php', quizPage());
// keep the settings file out of reach of the browser; PHP still reads it
out('quiz/.htaccess', 'DirectoryIndex index.php\n<Files "config.php">\n  Require all denied\n</Files>\n');
if (process.env.QUIZ_SECRET) out('quiz/config.php', `<?php return ['secret' => ${phpStr(process.env.QUIZ_SECRET)}, 'quiz' => ${phpStr(QUIZ_URL)}];\n`);
else notesLater.push('QUIZ_SECRET is not set, so quiz links will not open yet.');
CATS.forEach((c) => out(`projects/${c.slug}/index.html`, categoryPage(c)));
PROJECTS.forEach((p) => out(`projects/${p.slug}/index.html`, p.status === 'ongoing' ? ongoingPage(p) : completedPage(p)));
console.log(`Built the home page, ${NAV.length} chapter pages, ${CATS.length} category pages and ${PROJECTS.length} project pages into ${OUT}.`);
console.log(C.found ? `Content folder: ${CONTENT_DIR}` : `No content folder at ${CONTENT_DIR}, so placeholders were used throughout.`);
const notes = [...(C.warnings || []), ...notesLater];
if (C.found && !C.projects) notes.push('No projects in the folder yet, so the placeholder projects are shown.');
notes.forEach((n) => console.warn(`Note: ${n}`));
