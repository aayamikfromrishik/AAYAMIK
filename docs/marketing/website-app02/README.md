# BAAKI BUILD: "App 02" section for studio.aayamik.com/workdesk

This package adds BAAKI BUILD as the second app on the AAYAMIK workdesk page.
It's a self-contained section: plain HTML and CSS, no JavaScript, no framework.
It drops into any site (static HTML, React/Next.js, WordPress, Webflow).

Open `preview.html` in a browser to see it on its own.

## What's inside

| File | Purpose |
|---|---|
| `section.html` | The section markup. Paste it where App 02 should appear, after App 01 |
| `app02.css` | Styles. Every class starts with `bb-`, so nothing affects the rest of the site |
| `preview.html` | Stand-alone preview of the section |
| `images/` | Logo mark (SVG), app screenshots and posters, each as WebP plus PNG fallback |
| `content.md` | All the text, if the page is managed in a CMS |
| `screenshots/` | How the section should look on desktop, tablet and mobile |

## How to add it

1. Copy `images/` to the site's assets, e.g. `/assets/apps/baaki-build/`.
2. Link the stylesheet in `<head>`, or paste its contents into the site's CSS:
   ```html
   <link rel="stylesheet" href="/assets/apps/baaki-build/app02.css">
   ```
3. Paste `section.html` below the App 01 section.
4. If the images aren't in `images/` next to the page, update the `src` and `srcset` paths.
   Search for `images/` in `section.html`.
5. Replace the two placeholders below.

### React / Next.js

Paste the markup into a component and change `class=` to `className=`.
Use `next/image` for the screenshots if you prefer; their sizes are 780 × 1640.

## Placeholders to replace

| Where | Current value | Replace with |
|---|---|---|
| "Get early access" button | `mailto:REPLACE-WITH-YOUR-EMAIL@aayamik.com` | AAYAMIK's contact email, or a link to the site's contact form |
| "Try the demo" button | `https://baaki-build.pages.dev/demo/` | Keep it. It goes live once the Cloudflare hosting is switched on. Until then, hide this button or point it at the contact form |

## Matching the existing App 01 style

- **Font:** the section inherits the page font (`--bb-font: inherit`). To use the app's own font,
  load Plus Jakarta Sans and set `--bb-font: "Plus Jakarta Sans", sans-serif;` on `.bb-app`.
- **Width:** the card is max 1200px wide, centred. Change `max-width` on `.bb-app__card` and
  `.bb-app__cats` to match App 01.
- **Spacing above/below:** change `padding` on `.bb-app`.
- **Corner radius:** `--bb-radius` (default 24px).
- **Badge text:** "App 02" is in `.bb-app__badge`. Change it if App 01 uses a different label.
- **Layout:** to put the image on the left (alternating with App 01), add
  `.bb-app__visual { order: -1; }` above 900px width.

## Brand colours (BAAKI BUILD · Brick & Sage)

| Role | Hex |
|---|---|
| Buttons (brick) | `#B23A1E` |
| Panel (sage green) | `#3D5A47` |
| Highlight (mustard) | `#E0B23C` |
| Background (cream) | `#FAF6F0` |
| Text (warm dark grey) | `#2B2622` |

## Images

| File | Size | Use |
|---|---|---|
| `baaki-build-mark.svg` | vector | Logo tile (placeholder icon until the final logo is ready) |
| `screen-browse.*` | 780 × 1640 | App screenshot: Browse |
| `screen-listing-unlocked.*` | 780 × 1640 | App screenshot: listing with contact unlocked |
| `screen-listing.*`, `screen-login.*` | 780 × 1640 | Spare screenshots |
| `baaki-build-poster-landscape.*` | 1600 × 900 | Banner, slider or social share image (`og:image`) |
| `baaki-build-poster-portrait.*` | 1080 × 1350 | Card, Instagram |

## Accessibility

- Real `<h2>` heading, linked to the section with `aria-labelledby`.
- Screenshots have descriptive `alt` text; decorative icons are hidden from screen readers.
- Text and button colours pass WCAG AA contrast. Buttons show a visible focus ring.
- Screenshots load lazily (`loading="lazy"`).
