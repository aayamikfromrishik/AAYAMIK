# Karukrit Designs website

The studio website for Karukrit Designs, Ludhiana, built to the client's specification in [`docs/KARUKRIT_WEBSITE_SPEC.md`](docs/KARUKRIT_WEBSITE_SPEC.md) (version 1.0, 30 October 2026).

It is a static site with no framework. Every page is generated from one content file, so the studio can add projects without touching the HTML.

## Viewing it

```bash
python3 -m http.server 8000
```

Then open <http://localhost:8000>. The site also works when published as-is on GitHub Pages, Netlify or Vercel.

## Changing content

1. Edit `content/projects.json`: categories, projects, status (`completed`, `ongoing`, `concept`), current stage 1–6, city, year, and images.
2. Rebuild the pages:

```bash
node tools/build.mjs
```

This rewrites `index.html`, the four category pages in `projects/<category>/` and one page per project in `projects/<slug>/`. Projects removed from the JSON disappear on the next build.

Anything in [square brackets] is placeholder text from the spec, waiting for the client.

## Files

- `index.html`: home page, chapters I to VI (generated)
- `projects/`: category pages and project pages (generated)
- `content/projects.json`: every project on the site
- `tools/build.mjs`: the page generator
- `assets/css/site.css`: all styles; comments point to spec sections
- `assets/css/fonts.css`: the Satoshi font faces, linked automatically once the font files are present
- `assets/js/site.js`: smooth scroll and snapping, pencil cursor, sketched circles, reveals, header, phone menu
- `assets/js/home.js`: logo loader, sketch slideshow, chapter indicator, book viewer, work rows, philosophy, contact form
- `assets/js/project.js`: category filters and the image lightbox
- `assets/texture`, `assets/cursor`, `assets/loader`, `assets/book`: files from the client handoff
- `assets/brand/*-TRACED.svg`: traced wordmark, for layout only until the original artwork arrives
- `assets/sketches/`: four placeholder sketches for the chapter I slideshow
- `assets/vendor/lenis-1.1.13.min.js`: Lenis smooth scrolling (MIT licence)

## Spec checklist

Built and matching the spec:

| Section | Item |
|---|---|
| 1, 2 | Chapters story order; home chapters numbered I to VI; separate category and project pages; four categories in order; bachelor projects inside the normal categories with honest status tags |
| 3.2 | Main and supporting colours exactly as listed, with the readability pairs (moss highlights on taupe, light gold on moss, pale gold on burnt orange) |
| 3.3 | Type scale, weights 300/400/500, CAP labels at 11 px and 0.28em; Satoshi wired up and loaded automatically once the files are added |
| 3.4 | Leather texture on every coloured surface, 512 px tile |
| 3.5 | Letterhead stripe at the bottom of Contact and of the category and project pages |
| 4 | 12-column grid with 64 px margins; one-screen chapters; Lenis smooth scroll (1.1 s) with proximity snapping on desktop only; reveals rising 24 px over 0.8 s, staggered 80 ms; chapter indicator with a chapter list; slim header after chapter I; square corners apart from the glass, pills and circles; shadows only on the book |
| 5.1 | Logo animation (8 s MP4 on moss), first visit only, skippable by scroll, click, tap or key, 0.9 s fade; reduced motion shows the last frame for 1 s |
| 5.2 | Pencil cursor following the pointer exactly, dark or light by surface, tilting over anything clickable and pressing on mouse down, off on touch screens, with the CSS cursor as fallback |
| 5.3 | Hand-drawn circle on menu items, tabs, buttons and the chapter list; stays on the current menu item and tab; links wait 350 ms before navigating |
| 5.4 | Project images and portraits in black and white, colour and a 4 px lift on hover; on touch screens the image in the middle of the screen turns to colour |
| 5.5 | Orange and gold pill buttons, outline secondary buttons, visible focus outline per surface |
| 6 | Frosted glass to the exact insets, blur and fill, with a fallback; six glows at the listed positions; slideshow every 6 s with a 1.2 s crossfade, background following it, pause on hover, clickable dots |
| 7 | The Architect with the book card; The Author with cover, title, buttons, the spread viewer (page flip, arrows, keys, swipe, one page at a time on phones), the full-screen viewer and both handbooks |
| 8 | The studio on gold, four portrait columns, 2 × 2 on phones |
| 9 | Three philosophy screens, sentence fades and rises in, progress bars, gold strip on the right edge |
| 10 | Two rows flowing left (48 s per 6 tiles, second row half a cycle behind), hover pauses a row, tabs crossfade the rows, the "View all" link follows the tab; on phones touch pauses and resumes after 2 s; reduced motion makes the rows scrollable lists. Category pages with a 4-column grid and ALL / ONGOING / COMPLETED / CONCEPT filters |
| 11 | Completed project page: hero, info row, section links, galleries with a lightbox (arrows, keys, swipe), walkthrough hidden when there is none, facts table, next project, stripe |
| 12 | Ongoing project page: header, six stage blocks (vertical list with a coloured bar on phones), render plus dated site photos, archive by stage |
| 13 | Contact on moss with the form panel sliding up, fields with a bottom border, inline errors |
| 14 | Tablet and phone layouts; phone menu on moss; 44 px touch targets |
| 15 | Real links and buttons, labelled icon buttons, alt text, one H1 per page, reduced motion respected throughout |
| 16 | Book pages served as WebP with JPEG fallback; everything below chapter I lazy-loaded; page titles, descriptions and an Open Graph image (wordmark on moss leather) |

Waiting for the client (spec sections 17 and 18):

- Original logo vector (the traced wordmark is in place meanwhile)
- Satoshi WOFF2 files and confirmation of the web licence. Until then the site uses Manrope, the stand-in from the design boards
- 8–12 hand sketches with their colour renders (four placeholder sketches and coloured glows are in place)
- Portraits, the about-me story, the team sentence and roles, philosophy sentences 2 and 3
- Every project's details, photos and drawings, plus final print pages of the book and where to buy it
- Where "Connect to the author" should lead. It currently opens the contact form with "About the book" chosen, as the spec recommends
- Where form submissions go. Until an endpoint is set in `data-endpoint` on the form in `tools/build.mjs`, the form tells visitors to call or email instead of pretending to send
- Whether to keep the letterhead stripe colours (kept as the original for now) and whether to use the 8 s or 12 s loader (8 s used)

Not built yet:

- A CMS (the spec suggests Sanity, Strapi or similar). For now the studio edits `content/projects.json` and runs the build
- AVIF images and 2× `srcset`: the handoff has only one size of each page, served as WebP and JPEG
- Lighthouse has not been measured yet
