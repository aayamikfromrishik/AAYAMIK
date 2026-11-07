# Karukrit Designs website

The studio website for Karukrit Designs, Ludhiana, built to the client's specification in [`docs/KARUKRIT_WEBSITE_SPEC.md`](docs/KARUKRIT_WEBSITE_SPEC.md) (version 1.0, 30 October 2026).

It is a static site with no framework. Every page is generated from the studio's own folder, `Z:\2_Office Data\KD WEBSITE`: whatever is saved there appears on karukritdesigns.com about 10 to 15 minutes later.

## How an update reaches the website

1. Someone saves photos or text in `Z:\2_Office Data\KD WEBSITE`. The folder's `READ ME FIRST.txt` explains what goes where.
2. Every 10 minutes, an office computer copies that folder into `site-content/` here and sends any changes to GitHub (`tools/windows/sync-website.ps1`).
3. GitHub builds the site (`npm run build`), resizing every photo into AVIF, WebP and JPEG at two sizes.
4. GitHub uploads the result to Erichost by FTP. Only changed files are sent (`.github/workflows/deploy.yml`).

Anything the folder does not have yet (a story, team photos, projects) falls back to the placeholders, so the site always builds. A category appears only once it has a project.

## Launching (one time)

1. **Publish branch.** The website is published from the `main` branch. Merge this work into `main` on GitHub.
2. **Erichost FTP details.** In Erichost's cPanel, under FTP Accounts, find (or create) an FTP account for the website. On GitHub, open the repository's Settings > Secrets and variables > Actions and add three secrets: `FTP_SERVER` (for example `ftp.karukritdesigns.com`), `FTP_USERNAME` and `FTP_PASSWORD`. If the site should not go in `public_html/`, add a variable `FTP_DIR` with the right folder.
3. **First publish.** In the repository's Actions tab, run "Publish website". It takes a few minutes. The domain already points at Erichost, so the site appears at karukritdesigns.com.
4. **Office computer.** On a computer that is on during working hours and can see the Z: drive, right-click `tools/windows/setup-website-sync.ps1` and choose Run with PowerShell. It installs Git if needed, makes a copy of this repository in `C:\KD-Website`, fills the KD WEBSITE folder with the starter folders if it is empty, asks once for a GitHub sign-in, and schedules the sync every 10 minutes.

Progress and problems are written to `_website-log.txt` in the KD WEBSITE folder. A build's notes (for example a video over 80 MB, or a 3D model that is not a .glb) appear in the Actions tab.

## Coming soon (until 1 January 2027)

While `content/coming-soon.txt` holds a date, every page says "We are coming soon" with a live countdown to midnight (India time) on that date. All pages, the menu, the logo animation, the 3D house, the pencil cursor and circle, and the smooth scroll still work; photos and writing wait. Only the book (About page, "The author") is shown in full, and "Connect to the author" opens an email to the studio. Project pages are not published yet. The client questionnaire keeps working.

To open the whole site, delete `content/coming-soon.txt` (or set the GitHub variable `SITE_MODE` to `full`) and publish again. To change the date, edit the date in that file.

## Colour themes

`content/theme.txt` picks the colours: `leather` (moss green, a bright stone grey and gold; the current choice), `bottle` (deep bottle green, light grey, bright yellow) or `maroon` (deep brownish maroon, warm grey, yellow). Every surface has a silk suede finish with one soft sheen, and things that sit on it cast smooth layered shadows. Change the first word and publish again, or set the GitHub variable `SITE_THEME`. Every surface, the 3D scene and the logo reveal follow the theme.

## The 3D house

`assets/model/house.glb` is the Gaurav Jain residence (Zira), converted from the SketchUp .dae: roads, interior furniture and carpets removed, the boundary wall left out and drawn as the plot line instead, textures recoloured into the site palette, ten simple trees added in the lawn, and a plan cut at 1.2 m stored with it for the drawing stage. A .glb put in "1 Home/3D Model" in the studio folder takes its place.

## The client questionnaire

The Manus quiz opens at `karukritdesigns.com/quiz/`, but only from a personal link.

- **Making a link.** Anyone signed in to the Karukrit Work Desk opens **Client quiz**, picks the project (or types a new client's name), chooses 7, 14 or 30 days, and presses Create link. The link can be copied or sent straight to WhatsApp.
- **What a link carries.** For example `?c=RES-03_261202_ENGD_BBE2B3F8CA`: the project code, the last day it works (2 Dec 2026), four random letters, and a signature made with a key only the Work Desk and the website know. `quiz/index.php` checks the signature and the date on the server, so no list has to be kept in step. A link that is altered or out of date shows a polite message with the studio's phone and email instead.
- **Tagging the results.** The quiz page opens the Manus quiz with `?client=<the code>` added, so Manus can save each result in Google Drive under the right project. Manus needs to read that `client` value and put it in the saved file's name.
- **Setup.**
  1. Copy the key from the Work Desk (Saptarshi's login, Client quiz, Show the key) into a GitHub secret named `QUIZ_SECRET`.
  2. The Manus quiz address is in `content/quiz-link.txt`. To change it, edit that file, put a new one in `7 Quiz/quiz-link.txt` in the KD WEBSITE folder, or set a GitHub variable `QUIZ_URL`.
  If Manus does not allow the quiz to be shown inside the page, set a GitHub variable `QUIZ_MODE` to `redirect`: clients are then sent straight to the quiz once their link is checked.
  3. Erichost runs the PHP. `quiz/.htaccess` keeps the settings file out of reach of the browser.
- **One limit.** The check guards the page on karukritdesigns.com. Anyone who learned the Manus address itself could still open the quiz there, unless Manus also checks the code.

## Building on your own computer

```bash
npm install
npm run build
python3 -m http.server 8000 --directory dist
```

Then open <http://localhost:8000>. To build from a different folder, set `KD_CONTENT`, for example `KD_CONTENT="Z:/2_Office Data/KD WEBSITE" npm run build`.

## Pages

The home page holds the opening scroll: the logo, the frosted glass, and the 3D house going from plan to model to home. It ends with a contents list. Every chapter after that is its own page, at the client's request (30 Oct). The spec had them all on one long home page.

- `about/`: II · The architect and the author, with the book and the handbooks
- `team/`: III · The studio
- `philosophy/`: IV · Philosophy
- `projects/`: V · Work, plus the category pages and one page per project
- `contact/`: VI · Contact and the form

The top menu links to these pages. The current page keeps its pencil circle, and moving between pages cross-fades where the browser supports it.

## Motion on top of the spec

The spec sets the structure, colours, type, texture and interactions. On top of it the site keeps the 3D and scroll motion from the first prototype:

- **Chapter I:** the page opens exactly as the spec describes, with the frosted glass, the sketch slideshow and the glows. As you scroll, the glass pane shrinks into a card around the headline. Behind it a 3D house (three.js) draws its plan on paper, raises its walls as line drawings, becomes a white model and then the finished home in colour, while the camera comes down to the front door. The house answers the cursor: it turns to follow it, a quick sweep sets it spinning before it settles back, dragging turns it directly, and when the cursor is over the house the drawing lifts slightly and its lines darken. The card leans gently toward the cursor and the Plan / Model / Home labels follow the stage. To show one of your own houses, export it from SketchUp as glTF (`.glb`) into `1 Home/3D Model` in the KD WEBSITE folder.
- **The Author:** the book is a 3D object that turns as the chapter scrolls by and leans toward the cursor. Hovering lifts the cover. Clicking it, or READ A SAMPLE, plays an opening: the book lifts toward you, the hard cover swings open on its hinge, and three leaves bend and riffle over to the first spread, with light and shadow following each angle. From there the pages turn like paper, using StPageFlip (`assets/vendor/page-flip-2.0.7.browser.js`, MIT licence). The paper curls, casts a moving shadow and can be dragged by its corner. The spread on the page itself turns the same way.
- **The studio:** portraits lean toward the cursor with a soft light following it.
- **Philosophy:** one plan drawing sits behind the three screens, draws itself and moves more slowly than the words.
- **Work:** the two rows bend into a curved gallery wall. They still follow the spec's timing (6 tiles in 48 s, the second row half a cycle behind), pause on hover and can be dragged.
- **Completed projects:** scrolling walks you through the front door, from the elevation into the interior.
- **Ongoing projects:** the stage line fills up to the current stage, and an elevation drawing builds itself to match.

With reduced motion turned on, all of this switches off and the spec's still layout shows instead.

## Files

- `dist/`: the finished website, made by `npm run build` (not stored in the repository)
- `site-content/`: the copy of the studio's KD WEBSITE folder, kept up to date by the office computer
- `content/projects.json`: placeholder projects, used until the folder has real ones
- `tools/build.mjs`: the page generator
- `tools/content.mjs`: reads the KD WEBSITE folder and prepares the photos
- `tools/windows/`: the office computer's setup and sync scripts, and the starter `KD WEBSITE template`
- `.github/workflows/deploy.yml`: builds the site and uploads it to Erichost
- `assets/css/site.css`: all styles; comments point to spec sections
- `assets/css/fonts.css` and `assets/fonts/`: Satoshi Light, Regular and Medium, self-hosted. The Fontshare licence (`docs/Satoshi-Fontshare-licence.txt`) allows commercial use on the web, but not passing the font files on, so keep this repository private
- `assets/js/site.js`: smooth scroll and snapping, pencil cursor, sketched circles, reveals, header, phone menu
- `assets/js/home.js`: logo loader, sketch slideshow, chapter indicator, book viewer, work rows, philosophy, contact form
- `assets/js/project.js`: category filters and the image lightbox
- `assets/texture`, `assets/cursor`, `assets/loader`, `assets/book`: files from the client handoff
- `assets/brand/*-TRACED.svg`: traced wordmark, for layout only until the original artwork arrives
- `assets/sketches/`: four placeholder sketches for the chapter I slideshow
- `assets/js/hero3d.js`: the 3D house in Chapter I
- `assets/js/book.js`: the book's opening and the page turns on the About page
- `assets/vendor/lenis-1.1.13.min.js`: Lenis smooth scrolling (MIT licence)
- `assets/vendor/three/`: three.js r160 (MIT licence)

## The logo animation

`assets/loader/KD_logo_animation_alpha_8s.mp4` is made from the client's transparent 4K master by `tools/logo/build-loader.sh`. The script:

- crops to the logo and scales it to 1600 × 880;
- removes the scattered glitter sparkles while keeping the star that leads the drawing, and drops near-invisible dust pixels;
- gives antialiased edges the colour of the metal beside them;
- keeps all 360 original frames, played at 45 fps for 8 s. The earlier 8 s file had dropped frames to speed up, which made the motion uneven;
- stores colour in the top half of the video and transparency in the bottom half.

`assets/js/home.js` recombines the two halves on a canvas with a small WebGL shader. That gives a transparent animation in Safari too, where transparent WebM does not play.

## Spec checklist

Built and matching the spec:

| Section | Item |
|---|---|
| 1, 2 | Chapters story order; home chapters numbered I to VI; separate category and project pages; four categories in order; bachelor projects inside the normal categories with honest status tags |
| 3.2 | Main and supporting colours exactly as listed, with the readability pairs (moss highlights on taupe, light gold on moss, pale gold on burnt orange) |
| 3.3 | Satoshi, self-hosted and preloaded, in weights 300/400/500; type scale and CAP labels at 11 px and 0.28em. Web use confirmed by the Fontshare licence |
| 3.4 | Leather texture on every coloured surface, 512 px tile |
| 3.5 | Letterhead stripe at the bottom of Contact and of the category and project pages |
| 4 | 12-column grid with 64 px margins; one-screen chapters; Lenis smooth scroll (1.1 s) with proximity snapping on desktop only; reveals rising 24 px over 0.8 s, staggered 80 ms; chapter indicator with a chapter list; slim header after chapter I; square corners apart from the glass, pills and circles; shadows only on the book |
| 5.1 | Logo animation, first visit only, skippable by scroll, click, tap or key, 0.9 s fade; reduced motion shows the finished logo for 1 s. At the client's request (30 Oct) the logo draws straight onto the page's moss leather with no box behind it: it is rebuilt from the transparent 4K master as a transparent animation that plays in every browser (see below) |
| 5.2 | Pencil cursor following the pointer exactly, dark or light by surface, tilting over anything clickable and pressing on mouse down, off on touch screens, with the CSS cursor as fallback |
| 5.3 | Hand-drawn circle on menu items, tabs, buttons and the chapter list; stays on the current menu item and tab; links wait 350 ms before navigating. At the client's request (30 Oct) it is drawn as grainy graphite pencil, dark on light surfaces and pale on moss and burnt orange, instead of the spec's orange and gold line |
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
| 16 | Studio photos served as AVIF and WebP with a JPEG fallback at two sizes (book pages as WebP and JPEG); everything below chapter I lazy-loaded; page titles, descriptions and an Open Graph image (wordmark on moss leather) |

Waiting for the client (spec sections 17 and 18):

- Original logo vector (the traced wordmark is in place meanwhile)
- 8–12 hand sketches with their colour renders (four placeholder sketches and coloured glows are in place)
- Portraits, the about-me story, the team sentence and roles, philosophy sentences 2 and 3
- Every project's details, photos and drawings, plus final print pages of the book and where to buy it
- Where "Connect to the author" should lead. It currently opens the contact form with "About the book" chosen, as the spec recommends
- Where form submissions go. Until an endpoint is set in `data-endpoint` on the form in `tools/build.mjs`, the form tells visitors to call or email instead of pretending to send
- Whether to keep the letterhead stripe colours (kept as the original for now) and whether to use the 8 s or 12 s loader (8 s used)

Not built yet:

- A CMS (the spec suggests Sanity, Strapi or similar). Instead, the studio updates the KD WEBSITE folder on the Z: drive, which reaches the site automatically
- The book pages from the handoff are served as WebP and JPEG at their one supplied size. Every photo from the KD WEBSITE folder gets AVIF, WebP and JPEG at two sizes
- Lighthouse has not been measured yet
