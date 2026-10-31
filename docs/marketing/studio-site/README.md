# studio.aayamik.com: add Baaki Build (Software 02)

Two changes to the AAYAMIK Studio site:

1. **New page** `baakibuild`: the Baaki Build product page, built like the Work Desk page.
2. **Updated "All software" page** (`index`): the "Software 02 · Coming soon" card becomes a
   Baaki Build card linking to the new page.

Both use the site's existing `site.css`, `site.js`, `lenis.min.js`, fonts, wordmark, `leather`
and `marble-nero` backgrounds, curtain transition and gold/champagne text effects. No new
libraries, no build step.

## Files

```
site/
  baakibuild.html            new page (same structure as workdesk)
  index.html                 the live index.html with the Software 02 card replaced
  assets/baakibuild/         app screenshots (WebP + JPG fallback) and share.jpg
index-change.diff            the exact index change, if you prefer to patch by hand
preview/                     how the pages should look (desktop and mobile)
```

## Steps

1. Upload `site/assets/baakibuild/` to `/assets/baakibuild/` on the server.
2. Upload `site/baakibuild.html` **the same way `workdesk` is published**. The index links to
   `baakibuild` with no extension, like `workdesk`:
   - if the server has `workdesk.html` and serves it at `/workdesk`, upload `baakibuild.html` next to it;
   - if it uses a folder (`/workdesk/index.html`), put the file at `/baakibuild/index.html`.
3. Update the index:
   - **Easiest:** replace `index.html` with `site/index.html`. It is the live file as of
     31 Oct 2026, with only the Software 02 card changed.
   - **If index.html has changed since then:** apply `index-change.diff`, or swap the
     Software 02 `<div class="glass" aria-disabled="true">…</div>` for the `<a href="baakibuild" …>` block in the diff.
4. Bump the `?v=2` cache-buster only if you also change `site.css` or `site.js` (this update doesn't).
5. Open `/` and `/baakibuild` on desktop and phone and compare with `preview/`.

## Page contents

| Section | Anchor | Notes |
|---|---|---|
| Hero | | "Leftover material, a fair price." · 6 benefits (`wd-ease` grid) · 3 phone screenshots |
| How it works | `#flow` | I–VI: List, Check, Browse, Unlock, Call and collect, Mark sold |
| Features | `#features` | 4 rows (`wd-f`), each with a real app screenshot |
| Fees | `#fees` | Unlock fee table: ₹10 / 1% / ₹500 / ₹1,000, and the refund rule |
| Who uses it | `#roles` | 6 cells, same grid as Work Desk |
| Enquire | `#enquire` | "Coming soon" + WhatsApp button (same number as Work Desk, own message text) |

Page-specific styles are in one small `<style>` block in the page head (`.bb-` classes: phone
frames for the screenshots and the fee table). Everything else reuses `site.css` classes.

## Content notes

- The product name is set as **"Baaki Build"** in the Cormorant headings, to match how
  "Work Desk" is written. The app itself uses **BAAKI BUILD** in capitals. Change it if you
  prefer capitals on the site too.
- The card and page say **"Coming soon"**. When the app launches, change the index label to
  `SOFTWARE 02 · AVAILABLE` and replace "Get early access" with app store links.
- The WhatsApp button reuses `wa.me/917347468058` with the message
  "I would like early access to AAYAMIK Baaki Build".
- `og:image` points to `/assets/baakibuild/share.jpg` (1200 × 675).
- The screenshots show the app's own Brick & Sage colours on purpose: they're product shots,
  framed in the studio's brown phone frame like Work Desk's sample screens.

## Accessibility

- One `<h1>`, then `<h2>`/`<h3>` in order. The fee table has a caption and column headers.
- Every screenshot has descriptive `alt` text. Below-the-fold images use `loading="lazy"`.
- On phones the hero shows one screenshot instead of three, so the page stays light.
