# Karukrit Designs website: build specification

Version 1.0, 30 October 2026
Owner: Ar. Saptarshi Kapri, Founder and Principal Designer, Karukrit Designs, Ludhiana
Contact for questions: ceo@karukritdesigns.com, +91 88243 96618

This document is the complete brief for building the Karukrit Designs website. It records every design decision the client has approved. Build exactly what is written here. Anything marked **[TO CONFIRM]** is still open and must be checked with the client before launch. Anything in [square brackets] inside page copy is placeholder text the client will supply.

The `assets/` folder next to this file contains the texture, cursor, logo animation, wordmark, book cover and book/handbook pages referred to below.

---

## 1. What the site is

- An architecture and interior design studio site for Karukrit Designs, founded 2018 in Ludhiana.
- The firm is young, with a small built portfolio and many renders. The design must make a modest amount of work feel **professional, minimal and luxurious**. Prefer depth over breadth, plenty of empty space, slow and soft motion, and honest project labels.
- The story runs in this order: **the architect → the author (book and handbooks) → the team → the philosophy → the work → contact.**
- Layout family: **"Chapters"**. Each section of the home page is one full screen, numbered with Roman numerals, and visitors scroll through them like chapters of a book.
- This site is completely separate from the client's other brand, AAYAMIK. Do not link to or mention AAYAMIK anywhere.

---

## 2. Site map

```
Logo animation (first visit only)
└── Home: one long scroll of chapters
    ├── I    Home, frosted glass hero with sketch slideshow
    ├── II   The Architect (About me)
    ├── II   The Author (book and two handbooks)    ← second screen of chapter II
    ├── III  The Studio (Team)
    ├── IV   Philosophy (3 screens, one sentence each)
    ├── V    Work (projects, two flowing rows)
    └── VI   Contact
Project category page   /projects/residences, /hotels, /offices, /convention-centres
Project page, completed /projects/<slug>
Project page, ongoing   /projects/<slug>   (same template, ongoing variant)
```

Notes:
- The design boards label Contact "Chapter VIII". On the live site, number the home chapters **I to VI** as above. Project pages are separate templates, not chapters.
- Top navigation items: **ABOUT, TEAM, PHILOSOPHY, PROJECTS, CONTACT**. On the home page these smooth-scroll to the chapter. On other pages they link back to the home page at that chapter.
- Project categories: **Residences, Hotels, Offices, Convention centres**, in that order. More may be added later.
- The client's 2–3 bachelor (student) projects go **inside the normal categories** as concept projects, not in a separate category. Example: his bachelor hotel appears first under Hotels, followed by the two hotels currently in design. Every project carries an honest status tag: **COMPLETED**, **ONGOING · STAGE n OF 6**, or **CONCEPT · [YEAR]**.

---

## 3. Brand

### 3.1 Wordmark and logo
- Always use the **original vector logo file** from the client: the infinity-loop symbol plus the "KARUKRIT DESIGNS" wordmark, which has a distinctive curved K. Never retype the wordmark in a font.
- `assets/brand/wordmark-*-TRACED.svg` are tracings from a scanned letterhead. They are for layout only. **Replace them with the client's original artwork [TO CONFIRM: client to send AI/SVG/CDR].**
- Dark version (charcoal on light): fill `#23261A`. Light version (on moss or burnt orange): fill `#EFE8DC`.
- Width in the header: **230 px** desktop, 160 px mobile.

### 3.2 Colours

**Main palette (approved):**

| Name | Hex | Use |
|---|---|---|
| Moss green | `#45492D` | Dark chapter backgrounds (Home behind glass, The Author, Contact), active tab, "done" stages, highlighted words on taupe |
| Burnt orange | `#8B4729` | Completed-project page background, primary buttons, current stage, ongoing dots, slider active marker, click-circle stroke |
| Gold | `#BB8D3F` | Team chapter background, secondary buttons ("Connect to the author", "Book a first meeting"), thin accent edges, sketch highlights |
| Sage green | `#818865` | Image backdrops, hover-colour placeholder, supporting panels |
| Taupe (cool, like the letterhead grey) | `#A8A29D` | **Main page colour: at least 50% of total screen area across the site** |

**Supporting tones (derived; use exactly these):**

| Name | Hex | Use |
|---|---|---|
| Ink | `#23261A` | All body text and headings on taupe and gold |
| Ink secondary | `#3A3D28` | Secondary text on taupe |
| Taupe dark | `#948E89` | Image placeholders on taupe, upcoming stages, inactive progress bars |
| Taupe light | `#C9C4BF` | Hairlines on taupe |
| Cream | `#EFE8DC` | Text on moss, book page paper |
| Cream warm | `#F3ECE2` | Text on burnt orange and on orange buttons |
| Cream muted | `#D9CFBF` | Secondary text on moss |
| Light gold | `#DDB86E` | Small labels and highlighted words on moss (gold `#BB8D3F` is too dark for small text there) |
| Pale gold | `#F0DDB5` | Small labels on burnt orange |
| Deep moss | `#2A2D1B` | Darkest glow behind the home glass |

**Colours that are not used:** wine/maroon reds, navy, pure black, pure white. The only exception is the letterhead stripe (section 3.5).

**Readability rules (all pairs below have been checked for contrast):**
- On taupe: text in Ink `#23261A`; small labels in Ink or `#3A3D28`; highlighted large words in Moss `#45492D`. Never put small text in burnt orange or gold on taupe.
- On moss: text `#EFE8DC`, secondary `#D9CFBF`, small labels `#DDB86E`.
- On burnt orange: text `#F3ECE2`, small labels `#F0DDB5`.
- On gold: text and labels `#23261A`.
- Bright gold and orange may appear as shapes, lines, dots and buttons, never as small text on light backgrounds.

### 3.3 Typography
- **Typeface: Satoshi** (Indian Type Foundry, free from Fontshare: fontshare.com/fonts/satoshi). Self-host the WOFF2 files. **[TO CONFIRM: check the licence covers commercial web use.]** Fallback stack: `Satoshi, "Helvetica Neue", Arial, sans-serif`. (The design boards use Manrope as a stand-in; the live site must use Satoshi.)
- Weights used: **Light 300** (Satoshi's lightest; where the boards show 200, use 300), **Regular 400**, **Medium 500**. No bold, no italics, no serif.

| Style | Size desktop / mobile | Weight | Line height | Letter spacing | Notes |
|---|---|---|---|---|---|
| Hero (H1) | 52–76 px / 34–40 px | 300 | 1.1 | 0 | One per screen. One or two key words step up to weight 400 and change colour (moss on taupe, light gold on moss). |
| Section heading (H2) | 40 px / 28 px | 300 | 1.2 | 0 | |
| Body | 17 px / 16 px | 300 | 1.75 | 0 | Maximum line length about 65 characters. |
| Small body | 15 px | 300 | 1.7 | 0 | |
| Label / menu / button (CAP) | 11 px / 11 px | 500 | 1.4 | 0.28em | ALL CAPITALS. Used for nav, buttons, chapter numbers, project status, captions. |
| Project name under tile | 15 px | 300 | 1.4 | 0 | |
| Team name | 18 px | 300 | 1.4 | 0 | |

Writing tone: short sentences, "we", calm and confident. No sales words ("best", "premium", "world-class"). Never mention degrees or qualifications on the site.

### 3.4 Texture: full-grain leather (mandatory)
**No flat colours anywhere.** Every coloured surface carries a subtle full-grain leather texture: page backgrounds, buttons, the active tab, stage blocks, image backdrops and the home glass panel.

- File: `assets/texture/leather-grain.png`, a 512 × 512 px seamless tile. It is a transparent overlay (white highlights and black creases at very low alpha), not a coloured image. The same tile works on every colour.
- Apply it as a background image on top of the background colour:

```css
.tx {
  background-image: url(/assets/texture/leather-grain.png);
  background-size: 512px 512px;
  background-repeat: repeat;
}
/* usage: <section class="tx" style="background-color:#A8A29D"> */
```

- Do not scale it larger than 512 px, or it starts to look like reptile skin. On HiDPI screens the same 512 px tile is fine.
- Intended look: soft pebbling, fine creases and gentle tonal mottling, readable as material rather than pattern. If it becomes noticeable as a pattern, it is too strong.
- How the tile was made, if it ever needs regenerating: Voronoi cells (about 5,200 points on a 512 px torus) give the creases and pebbles, plus wrapped Gaussian noise at sigma 28 and 9 for mottling and sigma 0.6 for fine grain. Value = −0.18 × pebble − 0.55 × crease × depth + 0.35 × mottle + 0.22 × fine, then normalised. Alpha = |value| × 40 out of 255. White where the value is positive, black where it is negative.

### 3.5 Letterhead stripe
- At the very bottom of the Contact chapter (and the footer of project pages) there is a 10 px stripe copied from the letterhead: maroon `#5B2525` 120 px, green `#295B28` 120 px, navy `#24305A` 120 px, then grey `#5A5A5A` for the remaining width.
- This is the only place these colours appear. **[TO CONFIRM: keep the original letterhead colours, or redo the stripe in burnt orange, gold and moss.]**

---

## 4. Global layout

- Desktop design width is 1440 px. Content uses a **12-column grid**, 24 px gutters, 64 px side margins (72 px for the home glass panel). Maximum content width 1440 px, centred.
- Each home chapter is one screen: `min-height: 100vh` (minimum 760 px), full-bleed background.
- **Scrolling:** smooth scrolling (Lenis or similar, duration about 1.1 s) with `scroll-snap-type: y proximity` between chapters on desktop. No hard snapping on mobile.
- **Reveal on scroll:** text and images fade in and rise 24 px when they enter the screen, over 0.8 s with `cubic-bezier(.2,.7,.2,1)`. Items in a group are staggered by 80 ms. Nothing bounces, slides sideways or zooms quickly.
- **Chapter indicator:** fixed on the right edge, vertically centred, 24–40 px from the edge. It shows the current Roman numeral in CAP style, a 1 × 26 px line at 35% opacity, then the last numeral at 60–70% opacity. It updates as chapters scroll past. Its colour is `#EFE8DC` over moss and orange, and `#23261A` over taupe and gold. Clicking it opens a small list of chapters.
- **Header:** inside the glass on chapter I. After scrolling past chapter I, a slim fixed header appears (64 px tall, taupe with 85% opacity, 20 px backdrop blur, leather texture) showing the wordmark and menu.
- **Corners:** square everywhere except the home glass panel (24 px radius), round buttons (999 px pill), and the slider arrows (circles).
- **Shadows:** only on the book cover and book spread (section 7.3). No other shadows.

---

## 5. Signature interactions

### 5.1 Logo animation loader
- Source: the client's own animation, a warm brushed-silver logo drawing itself.
  - `assets/loader/KD_logo_animation_transparent_4K.webm`: original, transparent, 12 s.
  - `assets/loader/KD_logo_animation_on_moss_1080p_8s.mp4`: prepared version baked onto moss leather, sped up 1.5× to 8 s, 1080p, 0.4 MB.
- **Use the MP4 for all browsers.** Transparent WebM does not play on iPhone or Mac Safari, and the loader sits on a solid moss background anyway.
- Loader screen: full screen, moss `#45492D` with leather texture, video centred with `object-fit: contain`. No buttons and no text. Silent.
- Plays **on the first visit only** (store a flag in `localStorage`, for example `kd_intro_seen=1`). Repeat visitors go straight to the home page.
- The visitor can skip at any time by scrolling, clicking, tapping or pressing a key.
- When the video ends or is skipped, the loader fades out over 0.9 s while chapter I fades in underneath.
- Visitors who have turned off animations on their device (`prefers-reduced-motion`) see the last frame for 1 s, then the fade.
- **[TO CONFIRM: 8 s sped-up version (recommended) or the full 12 s.]**

### 5.2 Pencil cursor (desktop and mouse only)
- The arrow cursor is replaced with a **clutch pencil** pointing down-left. Files: `assets/cursor/pencil-cursor-dark.svg` and `pencil-cursor-light.svg`, 32 × 32 px, **hotspot at (3, 29)**, the tip of the lead.
- Use the dark pencil over taupe and gold surfaces, and the light pencil over moss, burnt orange and dark images. Switch based on the section under the pointer, for example with a `data-cursor="light"` attribute on sections.
- Build it as a custom DOM element following the pointer exactly (no lag), with the native cursor hidden (`cursor: none`). As a fallback, also set the CSS cursor: `cursor: url(pencil-cursor-dark.svg) 3 29, auto;`.
- Over anything clickable (links, buttons, tiles, tabs), the pencil tilts to −12° and scales to 1.08 over 150 ms, like a pencil about to mark.
- On mouse down, it scales to 0.94 for 100 ms, as if pressed.
- On touch devices, and when no mouse is detected (`(hover: none)`), there is no custom cursor.

### 5.3 Sketched circle on click (selection effect)
When a visitor clicks a menu item, a category tab, a button, or a chapter in the chapter list, a **hand-drawn pencil circle** draws itself around it.

- It is an SVG ellipse with a jittered "hand-drawn" outline, slightly bigger than the element: 10 px outside left and right, 8 px above and below.
- The path goes round about **1.15 turns** (so the end overlaps the start, like a real pencil loop), starting at the upper left.
- Stroke: **burnt orange `#8B4729`** on taupe and gold; **light gold `#DDB86E`** on moss and burnt orange. Width 1.3 px, round caps, no fill.
- Animation: drawn with `stroke-dashoffset` from full length to 0 over **550 ms ease-out**.
- Each click generates a slightly different shape (random jitter of ±4% in radius per point), so it never looks mechanical.
- Persistence:
  - In the **top menu** and **category tabs**, the circle stays around the current item. Clicking another item removes the old circle and draws a new one.
  - On **buttons and links that navigate**, the circle draws, then navigation happens after 350 ms.
- On touch devices it is drawn on tap.
- With reduced motion, the circle appears instantly without the drawing animation.

Reference code (vanilla JS; the ring is appended inside a `position: relative` wrapper around the clicked element):

```js
function ringPath() {
  const n = 26, turn = 1.15;           // points, number of turns
  let d = '';
  for (let i = 0; i <= n; i++) {
    const a = -1.9 + (i / n) * Math.PI * 2 * turn;
    const j = 1 + (Math.random() - 0.5) * 0.08;  // hand-drawn wobble
    const x = 50 + 48 * Math.cos(a) * j;
    const y = 50 + 44 * Math.sin(a) * j;
    d += (i ? 'L' : 'M') + x.toFixed(1) + ' ' + y.toFixed(1) + ' ';
  }
  return d;
}
function drawRing(el, colour) {
  el.querySelectorAll(':scope > svg.kd-ring').forEach(r => r.remove());
  const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
  svg.setAttribute('class', 'kd-ring');
  svg.setAttribute('viewBox', '0 0 100 100');
  svg.setAttribute('preserveAspectRatio', 'none');
  svg.style.cssText = 'position:absolute;left:-10px;top:-8px;width:calc(100% + 20px);height:calc(100% + 16px);pointer-events:none;overflow:visible';
  const p = document.createElementNS('http://www.w3.org/2000/svg', 'path');
  p.setAttribute('d', ringPath());
  p.setAttribute('vector-effect', 'non-scaling-stroke');
  p.style.cssText = `fill:none;stroke:${colour};stroke-width:1.3;stroke-linecap:round`;
  svg.appendChild(p); el.appendChild(svg);
  const L = p.getTotalLength();
  p.style.strokeDasharray = L; p.style.strokeDashoffset = L;
  p.getBoundingClientRect();
  p.style.transition = 'stroke-dashoffset .55s ease-out';
  p.style.strokeDashoffset = 0;
}
```

### 5.4 Monochrome to colour on hover
- All project images (tiles, category grids) and team portraits are shown in **black and white** by default: `filter: grayscale(1) contrast(.9)`.
- On hover, the image turns to full colour and lifts 4 px: `filter: none; transform: translateY(-4px)`, with a 0.6 s ease transition on both.
- On touch devices, the image that is in the middle of the screen turns to colour, using IntersectionObserver with a threshold of about 0.6.

### 5.5 Buttons
- Primary button: pill shape (`border-radius: 999px`), padding 16 px × 26 px, CAP text, leather texture on the colour.
  - On the home glass: burnt orange `#8B4729` with text `#F3ECE2`.
  - On moss: gold `#BB8D3F` with text `#23261A`.
- Secondary button: pill, transparent, 1 px border in the text colour, padding 15 px × 22 px.
- On hover, the colour lightens 6% and the pencil cursor tilts (section 5.2). On click, the sketched circle draws (section 5.3).
- Keyboard focus is always visible: 2 px outline in light gold `#DDB86E` on dark surfaces and burnt orange `#8B4729` on light surfaces, offset 3 px.

---

## 6. Chapter I: Home (frosted glass)

**Background layer (behind the glass):**
- A full-screen, heavily blurred **colour render of the same house whose sketch is currently showing**. Blur 60 px, scaled to 110% so the blurred edges are hidden.
- Until real renders are supplied, use soft glows of sage, gold, burnt orange and deep moss on moss leather. These are blurred circles (60 px blur) at these positions on a 1440 × 900 screen:
  - sage, top-left: 620 × 540 at (−120, −140)
  - gold, top-centre: 520 × 380 at (480, −120), 90% opacity
  - sage, top-right: 560 × 500 at (1000, −120), 85% opacity
  - burnt orange, lower-right: 480 × 420 at (820, 380)
  - deep moss `#2A2D1B`, lower-left: 600 × 400 at (140, 540)
  - gold, bottom-right: 400 × 360 at (1140, 600), 70% opacity

**Glass panel:**
- Inset 72 px left and right, 64 px top, 56 px bottom (24 px on mobile). Radius 24 px.
- Fill `rgba(168,162,157,0.62)` (taupe at 62%), plus the leather texture.
- `backdrop-filter: blur(36px) saturate(1.05)`, including the `-webkit-` prefix.
- Border 1 px `rgba(255,255,255,0.30)`.
- Padding 36 px top, 56 px sides, 44 px bottom.
- Fallback where `backdrop-filter` is not supported: fill `rgba(168,162,157,0.92)`.

**Inside the glass:**
1. **Top row:** wordmark on the left (dark, 230 px); menu on the right, ABOUT / TEAM / PHILOSOPHY / PROJECTS / CONTACT in CAP style with 30 px gaps.
2. **Left 7 columns: sketch slideshow.**
   - Hand sketches by the architect, shown as **pencil lines only on a transparent background**. Scanned sketches must have the paper removed. Ink colour `#23261A`; small touches of gold and burnt orange are allowed.
   - 8–12 sketches. Each changes every **6 s** with a 1.2 s crossfade, and the blurred render behind the glass changes with it.
   - Hovering the sketch pauses the slideshow.
   - Below the sketch: caption **"SKETCH 03 · [RESIDENCE NAME]"** on the left, slide dots on the right. Dots are 6 × 6 px circles in ink at 40% opacity; the active one is a 22 × 6 px pill in burnt orange. Clicking a dot jumps to that sketch.
3. **Right 4 columns (columns 9–12), aligned to the bottom:**
   - "CHAPTER I" (CAP)
   - Hero text, 52 px Light: "**Every house** begins as a line on paper." with "Every house" in Regular 400, moss `#45492D`.
   - Primary button **VIEW PROJECTS** (burnt orange), scrolling to chapter V.
   - Text link **SCROLL TO BEGIN ↓** (CAP).
4. The chapter indicator sits outside the glass on the right, in light colour.

---

## 7. Chapter II: The Architect and The Author

### 7.1 Screen 1: The Architect (taupe leather)
- Two equal halves.
  - **Left:** full-height black-and-white portrait of Ar. Saptarshi Kapri, edge to edge (turns to colour on hover). [Client to supply portrait.]
  - **Right:** padding 100 px × 80 px, vertically centred:
    - "CHAPTER II · THE ARCHITECT" (CAP)
    - Name, 52 px: "**Ar. Saptarshi** Kapri" with "Ar. Saptarshi" in Regular, moss.
    - Two short paragraphs of story, 17 px, `#3A3D28`. [Client to supply.]
    - Small book card in moss leather (padding 24 × 28 px): book cover thumbnail 70 × 96 px, "THE BOOK" in light gold CAP, and "The 100 Decisions Before the First Brick" at 20 px Light in cream. Clicking it scrolls to the next screen.

### 7.2 Screen 2: The Author (moss leather)
- Padding 64 px. Top area on the 12-column grid; bottom strip for the handbooks.
- **Left (columns 1–4), vertically centred:**
  - Book front cover `assets/book/book-cover-front.jpg`, 128 px wide, shadow `0 14px 30px rgba(0,0,0,.35)`.
  - "CHAPTER II · THE AUTHOR" in light gold CAP.
  - Title, 34 px Light: "The 100 Decisions **Before the First Brick**" with the second part in Regular, light gold `#DDB86E`.
  - Line, 15 px, `#D9CFBF`: "What to finalise, question, compare and document before you start building. A practical guide for homeowners."
  - Buttons:
    - **CONNECT TO THE AUTHOR**: gold pill, ink text. **[TO CONFIRM where it leads. Recommended: the contact form with the subject preset to "About the book", or WhatsApp +91 88243 96618 with a prefilled message.]**
    - **READ A SAMPLE**: outline pill in cream. Opens the spread viewer below in full-screen mode.
  - "[WHERE TO BUY]" (CAP). **[TO CONFIRM: buying links, for example Amazon or the studio.]**
- **Right (columns 6–12): open-book spread viewer.**
  - Two pages side by side at 440 px height, with a 1 px `#CFC6B6` line at the spine and a shadow of `0 18px 40px rgba(0,0,0,.35)` around the pair.
  - Three spreads:
    1. `book-p15.jpg` + `book-p16.jpg`. Caption: "INTRODUCTION · WHY YOUR HOME SHOULD BE BUILT ON PAPER FIRST"
    2. `book-p17.jpg` + `book-p18.jpg`. Caption: "CHAPTER 1 · BEFORE I LEARNED TO BUILD ON PAPER"
    3. `book-p191.jpg` + `book-p192.jpg`. Caption: "CHAPTER 13 · THE 100 DECISIONS, DECISIONS 1–6"
  - Below the spread: caption on the left (CAP, `#D9CFBF`); on the right, ← and → buttons (44 px circles, 1 px border at 40% cream) with "1 / 3" between them.
  - Changing spread: the right page turns like a page flip (3D `rotateY`, 0.7 s), or crossfades if page-flip is not built. Keyboard arrows also work. Swipe on mobile.
  - **These pages come from the 1st draft of the book. [TO CONFIRM: swap in final print pages before launch.]**
- **Bottom strip:** 1 px top border at 25% cream, 22 px top padding. Two equal halves, one per handbook. Each shows cover + two pages (each 128 px wide, landscape), then text:
  - **Volume I:** `building-p1.jpg` (cover, shadow `0 8px 18px rgba(0,0,0,.3)`), `building-p17.jpg`, `building-p58.jpg`. Text: "HANDBOOK · VOLUME I" (light gold CAP), "Building with Intention" (18 px), "Construction and structure" (13 px, `#D9CFBF`), "VIEW PAGES →".
  - **Volume II:** `craft-p1.jpg`, `craft-p14.jpg`, `craft-p20.jpg`. Text: "HANDBOOK · VOLUME II", "Craft with Intention", "Interior design and execution", "VIEW PAGES →".
  - "VIEW PAGES" opens the same viewer as READ A SAMPLE, showing that handbook's pages.

---

## 8. Chapter III: The Studio (gold leather)
- Background gold `#BB8D3F` with leather texture; all text ink `#23261A`. Padding 80 px × 64 px.
- **Top row:**
  - Left: "CHAPTER III" (CAP), "The studio" (40 px Light), and a 56 × 3 px burnt-orange line under it.
  - Right: one sentence, max 420 px wide. [Client to supply: how the team works, from first sketch to site.]
- **Four portrait columns** (24–28 px gaps), each with:
  - Portrait filling the column height, black and white, in a frame of `rgba(35,38,26,.12)` with a 1 px `rgba(35,38,26,.25)` border. On hover it turns to colour (section 5.4).
  - Name (18 px Light) and role (CAP).
  - Members: **Kuljeet, Krishma, Sanchit, [fourth member]**. [Client to supply roles and portraits.]
- Portraits are shot in the same light and framing, waist-up, on a plain background.

---

## 9. Chapter IV: Philosophy (taupe leather, 3 screens)
- Three full screens in a row, each with **one sentence**. Padding 0 × 160 px, vertically centred.
- Each screen has:
  - "CHAPTER IV · n OF 3" (CAP).
  - The sentence at 76 px Light (max 1000 px wide), with key words in Regular moss.
    - Screen 1: "A home is **a hundred decisions**, made in the right order."
    - Screens 2 and 3: [Client to supply, drawn from the book.]
  - Two supporting sentences, 17 px, `#3A3D28`, max 560 px.
  - Progress marks: three 40 × 3 px bars, 10 px apart; the current one burnt orange, the others taupe dark `#948E89`.
- A 14 px wide gold leather strip runs down the full right edge of these screens.
- Scrolling moves from one sentence to the next. The sentence fades and rises in; the previous one fades out.

---

## 10. Chapter V: Work (taupe leather)
- Padding 56 px top, 48 px bottom. Rows run edge to edge.
- **Header row** (64 px side margins):
  - Left: "CHAPTER V" (CAP), "Work" (40 px Light).
  - Right: category tabs RESIDENCES / HOTELS / OFFICES / CONVENTION CENTRES (CAP, 30 px gaps). The active tab is a moss leather box with cream text and padding 8 × 14 px, plus the sketched circle on click.
  - Switching tabs crossfades the two rows to that category's projects (0.5 s).
- **Two rows of project tiles, flowing to the left continuously:**
  - Tile: **300 px wide**. Image 200 px tall, black and white by default. Below the image, 9 px apart:
    - Project name (15 px Light).
    - Status in CAP with a 7 px dot. The dot is **burnt orange for ongoing projects** and absent for others. Status text: "ONGOING · STAGE 4 OF 6", "COMPLETED · LUDHIANA", "CONCEPT · 2016" and so on.
  - Gap between tiles: 24 px. At 1440 px, about **4 tiles per row are fully visible, so 8 on screen**, with the edges of the next ones peeking in.
  - Each row holds 6 or more projects. The row's content is duplicated once so the loop is seamless.
  - Motion: each row moves left at constant speed; **one full cycle (6 tiles) takes 48 s**. **Both rows move at the same speed.** Row 2 starts half a cycle later (`animation-delay: -24s`) so the tiles don't line up in a grid.
  - **Hovering anywhere on a row pauses that row.** The hovered tile turns to colour and lifts 4 px. The row resumes when the cursor leaves.
  - Clicking a tile opens the project page.
  - With reduced motion, the rows don't move; they become horizontally scrollable lists instead.

Reference CSS:

```css
.marq { overflow: hidden; width: 100%; }
.track { display: flex; gap: 24px; padding-right: 24px; width: max-content;
         animation: kdflow 48s linear infinite; }
.track.row2 { animation-delay: -24s; }
.marq:hover .track { animation-play-state: paused; }
@keyframes kdflow { from { transform: translateX(0) } to { transform: translateX(-50%) } }
@media (prefers-reduced-motion: reduce) { .track { animation: none; } .marq { overflow-x: auto; } }
.tile { width: 300px; flex: none; display: flex; flex-direction: column; gap: 9px; }
.tile .img { height: 200px; filter: grayscale(1) contrast(.9);
             transition: filter .6s ease, transform .6s ease; }
.tile:hover .img { filter: none; transform: translateY(-4px); }
```

- **Bottom row** (64 px side margins): "HOVER TO PAUSE · CLICK A PROJECT TO OPEN IT" on the left (CAP, `#3A3D28`); "VIEW ALL RESIDENCES →" on the right (CAP, 1 px burnt-orange underline, 4 px below). The link text follows the active category and goes to the category page.
- **Category page** (`/projects/<category>`): taupe leather; the same header and tabs; a 4-column grid of the same tiles (larger, 4:3 images), not moving; monochrome to colour on hover. Filter chips ALL / ONGOING / COMPLETED / CONCEPT (CAP). Concept projects are always tagged.

---

## 11. Project page: completed (burnt orange leather)
- **Hero:** front elevation render or photo, full width, 520 px tall, in colour.
- **Info row** (12 columns, padding 48 × 64 px, text cream):
  - Columns 1–5: "RESIDENCE · [CITY] · COMPLETED [YEAR]" (CAP, `#F0DDB5`) and the project name (40 px Light).
  - Columns 6–9: the brief and the one idea behind the design, 3–4 sentences, 17 px, `#F3ECE2`.
  - Columns 10–12: section links in CAP:
    - I · SITE PHOTOGRAPHS
    - II · INTERIORS
    - III · WALKTHROUGH
    - IV · DRAWINGS (in `#F0DDB5`)
- **Sections below, in this order:**
  1. **Site photographs:** exterior photos of the finished building.
  2. **Interiors:** interior photographs.
  3. **Walkthrough:** video, if one exists. Hide the section if not.
  4. **Drawings:** **presentation drawings only** (coloured furnished plan, one section, concept diagram). Never working drawings with dimensions.
  - Galleries: taupe background, 12-column grid mixing full-width and two-up images, 24 px gaps. Clicking an image opens a full-screen lightbox with arrows and swipe.
- A small facts table: Plot, Built-up area, Scope (for example "Architecture, interiors"), Year.
- Footer: "NEXT PROJECT →" (name and black-and-white thumbnail turning to colour on hover), then the letterhead stripe.

## 12. Project page: ongoing (taupe leather)
- Padding 64 px.
- **Header:** "ONGOING · [CITY]" (CAP) and the project name (40 px) on the left; "UPDATED [DATE]" (CAP, `#3A3D28`) on the right.
- **Stage line:** six equal blocks, 4 px apart, padding 16 px, 13 px text. All carry the leather texture.
  - **Design, Approvals, Structure, Masonry and services, Finishing, Handover**
  - Done stages: moss background, cream text.
  - Current stage: burnt orange background, `#F3ECE2` text, weight 500, with "· now" after the name.
  - Upcoming stages: taupe dark `#948E89`, ink text.
- **Images:** 4-column grid, 20 px gaps. The render ("how it will look") spans 2 columns; latest site photos follow, each captioned with its date. Below that, an archive of site photos grouped by stage.
- Data: stage and photos should be easy for the studio to update without a developer (CMS fields: current stage number 1–6, photo uploads with date and stage).

---

## 13. Chapter VI: Contact (moss leather)
- Padding 0 × 160 px, vertically centred, text cream.
- "CHAPTER VI" (light gold CAP).
- Headline, 72 px Light: "Your house begins **here.**" with "here." in Regular, light gold.
- Two columns of 18 px Light text, 80 px apart, line height 1.8:
  - **STUDIO** (light gold CAP): 3652/2, 1st Floor, Green Field, Model Gram, Ludhiana 141002, Punjab
  - **TALK** (light gold CAP): `+91 88243 96618` (tel: link) and `ceo@karukritdesigns.com` (mailto: link)
- Button: **BOOK A FIRST MEETING**, gold leather, ink text, padding 16 × 26 px. It opens the contact form as a panel sliding up over the chapter (0.6 s), on taupe leather, with fields that have a 1 px bottom border only:
  - Your name
  - Phone
  - Plot size and city
  - What are you planning? (Residence / Hotel / Office / Convention centre / About the book / Other)
  - Message
  - SEND button (burnt orange pill)
  - Validate inline: show an error next to any empty required field.
  - On success, show "Thank you. We'll call you within two working days." **[TO CONFIRM: where form submissions go: email address and/or WhatsApp.]**
- [Client to supply: studio hours, Instagram link.]
- The 10 px letterhead stripe runs along the very bottom (section 3.5).

---

## 14. Mobile and tablet

| Width | Behaviour |
|---|---|
| ≥ 1200 px | Desktop, as specified. |
| 768–1199 px | 8-column grid, 40 px margins; hero 56 px; chapter screens may grow taller than the window. |
| < 768 px | Single column, 20 px margins. |

On phones:
- **Home glass:** inset 16 px. Wordmark plus a menu icon (two lines) opening a full-screen moss leather menu with large Light items 28 px tall, each getting the sketched circle on tap. The sketch sits above the headline, the buttons below.
- **The Architect:** portrait on top (60% screen height), text below.
- **The Author:** cover and text first, then the spread viewer showing **one page at a time** (swipe), then the handbooks stacked.
- **Team:** 2 × 2 grid of portraits.
- **Philosophy:** each sentence at 34–40 px.
- **Work:** both rows keep flowing left. Tiles 220 px wide (image 150 px). Touching a row pauses it and colours the tile under the finger. Releasing resumes after 2 s.
- **Project pages:** everything stacks; the stage line becomes a vertical list with a 3 px coloured bar on the left of each stage.
- No custom cursor. Sketched circles appear on tap.
- Touch targets are at least 44 × 44 px.

---

## 15. Accessibility
- Real `<a>` and `<button>` elements everywhere. Icon-only buttons get an `aria-label` (for example "Previous spread").
- Descriptive `alt` text on every image (for example "Building with Intention, page 17: Where great spaces begin").
- Logical heading order (one H1 per page).
- Visible keyboard focus (section 5.5).
- `prefers-reduced-motion`: no loader animation, no flowing rows, no scroll reveals, no drawn circles (they appear instantly), no page flip.
- All text and background colour pairs follow section 3.2.

## 16. Performance and technical
- Images in AVIF or WebP with JPEG fallback, served at 1× and 2× (`srcset`). Lazy-load everything below chapter I.
- Largest images: home background render about 2400 px wide, already heavily blurred, so it can be compressed hard.
- Self-hosted Satoshi WOFF2, preloaded. Leather tile under 220 KB. Loader MP4 0.4 MB, preloaded on the first visit only.
- Target: Lighthouse performance ≥ 85 on mobile; first content visible under 2.5 s.
- Suggested stack: any modern static setup (for example Astro or Next.js), GSAP or Motion One for scroll reveals and the page flip, Lenis for smooth scroll, and a light CMS (Sanity, Strapi or similar) so the studio can add projects, stages and site photos without a developer.
- Domain: karukritdesigns.com.
- SEO: page titles such as "Karukrit Designs | Architecture and interiors, Ludhiana"; one meta description per page; Open Graph image showing the wordmark on moss leather.

## 17. Content the client needs to supply
- [ ] Original logo and wordmark vector file
- [ ] 8–12 hand sketches (scanned at 600 dpi, paper removed) plus the matching colour render of each house
- [ ] Portrait of Ar. Saptarshi Kapri and portraits of the team, with names and roles
- [ ] About-me story (two short paragraphs) and the team sentence
- [ ] Philosophy sentences 2 and 3
- [ ] Per project: name, city, year, category, status (completed/ongoing/concept), brief (3–4 sentences), plot and built-up area, elevation image, site photos, interiors, walkthrough (if any), presentation drawings; for ongoing projects, the current stage and dated site photos
- [ ] Final print pages of the book (to replace the 1st draft pages)
- [ ] Where to buy the book
- [ ] Studio hours, Instagram link

## 18. Open decisions [TO CONFIRM]
1. Loader length: 8 s sped-up (recommended) or the full 12 s.
2. "Connect to the author" destination: contact form with "About the book", or WhatsApp, or email.
3. Contact form submissions: which email and/or WhatsApp.
4. Letterhead stripe: keep the original maroon/green/navy, or redo it in burnt orange/gold/moss.
5. Satoshi web licence confirmed.

## 19. Assets in this folder

| File | What it is |
|---|---|
| `assets/texture/leather-grain.png` | Seamless 512 px leather overlay; apply to every coloured surface |
| `assets/cursor/pencil-cursor-dark.svg` | Pencil cursor for light surfaces, hotspot (3, 29) |
| `assets/cursor/pencil-cursor-light.svg` | Pencil cursor for dark surfaces, hotspot (3, 29) |
| `assets/loader/KD_logo_animation_on_moss_1080p_8s.mp4` | Loader to use on the site |
| `assets/loader/KD_logo_animation_transparent_4K.webm` | Client's original animation (master) |
| `assets/brand/wordmark-*-TRACED.svg` | Traced wordmark, layout only; replace with original |
| `assets/book/book-cover-front.jpg` | Front cover of "The 100 Decisions Before the First Brick" |
| `assets/book/book-p15…p192.jpg` | Book pages for the three spreads (1st draft) |
| `assets/book/building-p1/p17/p58.jpg` | Building with Intention: cover and two pages |
| `assets/book/craft-p1/p14/p20.jpg` | Craft with Intention: cover and two pages |
