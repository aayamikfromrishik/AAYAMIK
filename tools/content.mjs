// Reads the studio's content folder (a mirror of Z:\2_Office Data\KD WEBSITE) and prepares every image for the web.
// Folder and file names carry the content: numbers in front set the order, the rest becomes names and captions.
// Anything missing falls back to the placeholders in content/projects.json, so the site always builds.
import { readFileSync, existsSync, readdirSync, statSync, mkdirSync, copyFileSync } from 'node:fs';
import { join, extname, basename } from 'node:path';
import { createHash } from 'node:crypto';

const IMG = new Set(['.jpg', '.jpeg', '.png', '.webp', '.tif', '.tiff', '.heic', '.avif']);
const VIDEO = new Set(['.mp4', '.webm', '.mov']);
const STAGE_NAMES = ['Design', 'Approvals', 'Structure', 'Masonry and services', 'Finishing', 'Handover'];

export const slugify = (s) => s.toLowerCase().normalize('NFKD').replace(/[\u0300-\u036f]/g, '').replace(/&/g, ' and ').replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
// "02 Living room, looking south" -> { order: 2, name: "Living room, looking south" }
const parseName = (file) => {
  const stem = basename(file, extname(file)).trim();
  const m = stem.match(/^(\d+)[\s._-]+(.*)$/);
  return m ? { order: +m[1], name: m[2].trim() } : { order: 9999, name: stem };
};
const dateIn = (s) => { const m = s.match(/(\d{4})[-_. ](\d{2})[-_. ](\d{2})/); return m ? `${m[1]}-${m[2]}-${m[3]}` : null; };
const niceDate = (iso) => { if (!iso) return ''; const d = new Date(iso + 'T00:00:00'); return d.toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' }); };
const visible = (n) => !n.startsWith('.') && !n.startsWith('~$') && !n.startsWith('_') && n !== 'Thumbs.db' && n !== 'desktop.ini';
const list = (dir) => (existsSync(dir) ? readdirSync(dir).filter(visible) : []);
const dirs = (dir) => list(dir).filter((n) => statSync(join(dir, n)).isDirectory());
const files = (dir, kinds) => list(dir).filter((n) => statSync(join(dir, n)).isFile() && kinds.has(extname(n).toLowerCase()));
const byOrder = (a, b) => (parseName(a).order - parseName(b).order) || a.localeCompare(b, 'en', { numeric: true });
// find a sub-folder by meaning, ignoring numbers, case and spacing: "1 Home", "home", "01-Home"
const find = (dir, ...keys) => dirs(dir).find((n) => keys.some((k) => parseName(n).name.toLowerCase().replace(/\s+/g, ' ').startsWith(k)));
const readText = (f) => (existsSync(f) ? readFileSync(f, 'utf8').replace(/^\uFEFF/, '').replace(/\r\n?/g, '\n') : '');
const textFile = (dir, ...names) => { const f = list(dir).find((n) => names.some((k) => n.toLowerCase().startsWith(k)) && n.toLowerCase().endsWith('.txt')); return f ? readText(join(dir, f)) : ''; };

// "Key: value" lines; everything after "Brief:" (or "Story:") is free text
function parseInfo(text) {
  const out = {};
  const lines = text.split('\n');
  for (let i = 0; i < lines.length; i++) {
    const m = lines[i].match(/^\s*([A-Za-z -]+?)\s*:\s*(.*)$/);
    if (!m) continue;
    const key = m[1].toLowerCase().replace(/\s+/g, ' ');
    if (key === 'brief' || key === 'story' || key === 'address') { out[key] = [m[2], ...lines.slice(i + 1)].join('\n').trim(); if (key !== 'address') break; else continue; }
    out[key] = m[2].trim();
  }
  return out;
}
const paragraphs = (t) => t.split(/\n\s*\n/).map((p) => p.replace(/\s*\n\s*/g, ' ').trim()).filter(Boolean);

/* ---------- images: two sizes in AVIF, WebP and JPEG, cached between builds ---------- */
export class Media {
  constructor(out, cache) { this.out = out; this.cache = cache; this.jobs = []; this.warnings = []; }
  key(file, extra) { const s = statSync(file); return createHash('sha1').update(file + s.size + s.mtimeMs + extra).digest('hex').slice(0, 12); }
  // returns the picture description now; the files are made in run()
  image(file, alt, widths = [800, 1600]) {
    const k = this.key(file, widths.join(','));
    const name = `${slugify(parseName(file).name).slice(0, 40) || 'image'}-${k}`;
    const pic = { name, alt, widths, file, src: `media/${name}-${widths[widths.length - 1]}.jpg` };
    pic.srcset = (ext) => widths.map((w) => `media/${name}-${w}.${ext} ${w}w`).join(', ');
    this.jobs.push(pic);
    return pic;
  }
  copy(file) {
    const s = statSync(file);
    if (s.size > 80 * 1024 * 1024) { this.warnings.push(`${basename(file)} is larger than 80 MB and was left out. Please export a smaller version.`); return null; }
    const name = `${slugify(parseName(file).name) || 'file'}-${this.key(file, '')}${extname(file).toLowerCase()}`;
    mkdirSync(join(this.out, 'media'), { recursive: true });
    copyFileSync(file, join(this.out, 'media', name));
    return `media/${name}`;
  }
  async run() {
    if (!this.jobs.length) return;
    let sharp;
    try { sharp = (await import('sharp')).default; } catch (e) { throw new Error('Images need the "sharp" package. Run: npm install'); }
    mkdirSync(join(this.out, 'media'), { recursive: true });
    mkdirSync(this.cache, { recursive: true });
    // several photos at once; each one is done in turn at its sizes and formats
    const queue = this.jobs.slice();
    const work = async () => { for (let pic = queue.shift(); pic; pic = queue.shift()) await this.make(sharp, pic); };
    await Promise.all(Array.from({ length: 4 }, work));
  }
  async make(sharp, pic) {
    {
      for (const w of pic.widths) {
        for (const ext of ['avif', 'webp', 'jpg']) {
          const fname = `${pic.name}-${w}.${ext}`;
          const cached = join(this.cache, fname);
          if (!existsSync(cached)) {
            try {
              let img = sharp(pic.file, { failOn: 'none' }).rotate().resize({ width: w, withoutEnlargement: true });
              img = ext === 'avif' ? img.avif({ quality: 52, effort: 2 }) : ext === 'webp' ? img.webp({ quality: 78 }) : img.flatten({ background: '#EFE8DC' }).jpeg({ quality: 80, mozjpeg: true, progressive: true });
              await img.toFile(cached);
            } catch (e) { this.warnings.push(`Could not read ${basename(pic.file)}: ${e.message}`); continue; }
          }
          copyFileSync(cached, join(this.out, 'media', fname));
        }
      }
      try { const m = await sharp(pic.file, { failOn: 'none' }).metadata(); pic.ratio = m.width && m.height ? ((m.orientation || 1) >= 5 ? m.width / m.height : m.height / m.width) : null; } catch (e) { /* size unknown */ }
    }
  }
}

/* ---------- the folder ---------- */
export function loadContent(root, media) {
  const C = { found: existsSync(root), warnings: [] };
  if (!C.found) return C;

  // 1 Home: sketches (and the colour render of the same house), and the 3D model
  const home = find(root, 'home');
  if (home) {
    const sk = find(join(root, home), 'sketch');
    if (sk) {
      const dir = join(root, home, sk);
      const all = files(dir, IMG).sort(byOrder);
      const renders = all.filter((f) => /render/i.test(f));
      C.sketches = all.filter((f) => !/render/i.test(f)).map((f) => {
        const { order, name } = parseName(f);
        const r = renders.find((x) => parseName(x).order === order) || renders.find((x) => parseName(x).name.replace(/\s*render\s*/i, '').trim() === name);
        return { name, alt: `Pencil sketch of ${name}`, image: media.image(join(dir, f), `Pencil sketch of ${name}`, [700, 1400]), render: r ? media.image(join(dir, r), '', [1200, 2400]) : null };
      });
    }
    const md = find(join(root, home), '3d');
    if (md) {
      const glb = list(join(root, home, md)).find((n) => /\.glb$/i.test(n));
      if (glb) C.model = media.copy(join(root, home, md, glb));
      else if (list(join(root, home, md)).length) C.warnings.push('The 3D model folder needs a .glb file. Export from SketchUp as glTF (.glb), or send the model to be converted.');
    }
  }

  // 2 About: portrait and the two paragraphs of story
  const about = find(root, 'about');
  if (about) {
    const dir = join(root, about);
    const pic = files(dir, IMG).sort(byOrder)[0];
    if (pic) C.portrait = media.image(join(dir, pic), 'Portrait of Ar. Saptarshi Kapri', [900, 1800]);
    const story = paragraphs(textFile(dir, 'story', 'my story', 'about').replace(/^\s*story\s*:\s*/i, ''));
    if (story.length) C.story = story;
  }

  // 3 Team: "01 Kuljeet - Site architect.jpg", and team.txt with the one sentence
  const team = find(root, 'team', 'studio');
  if (team) {
    const dir = join(root, team);
    const members = files(dir, IMG).sort(byOrder).map((f) => {
      const { name } = parseName(f);
      const [person, ...role] = name.split(/\s+[-–]\s+/);
      return { name: person.trim(), role: role.join(' - ').trim() || '', photo: media.image(join(dir, f), `Portrait of ${person.trim()}`, [600, 1200]) };
    });
    if (members.length) C.members = members;
    const s = paragraphs(textFile(dir, 'team', 'sentence', 'studio'))[0];
    if (s) C.teamSentence = s;
  }

  // 4 Philosophy: three blocks; the first line of each is the sentence, *words in stars* are highlighted
  const philo = find(root, 'philosophy');
  if (philo) {
    const blocks = textFile(join(root, philo), 'sentence', 'philosophy').split(/\n\s*\n/).map((b) => b.trim()).filter(Boolean);
    if (blocks.length) C.philosophy = blocks.slice(0, 3).map((b) => { const [first, ...rest] = b.split('\n'); return { sentence: first.trim(), sub: rest.join(' ').trim() }; });
  }

  // 5 Projects: one folder per category, one folder per project inside it
  const pr = find(root, 'project', 'work');
  if (pr) {
    C.categories = [];
    C.projects = [];
    for (const catDir of dirs(join(root, pr)).sort(byOrder)) {
      const catName = parseName(catDir).name;
      const slug = slugify(catName);
      const one = { residences: 'Residence', hotels: 'Hotel', offices: 'Office', 'convention-centres': 'Convention centre' }[slug] || catName.replace(/s$/i, '');
      C.categories.push({ slug, name: catName, one });
      for (const pDir of dirs(join(root, pr, catDir)).sort(byOrder)) {
        const dir = join(root, pr, catDir, pDir);
        const name = parseName(pDir).name.replace(/\s*\((ongoing|completed|concept)\)\s*$/i, '').trim();
        const info = parseInfo(textFile(dir, 'info', 'details', 'project'));
        const st = (info.status || (/\(ongoing\)/i.test(pDir) ? 'ongoing' : /\(concept\)/i.test(pDir) ? 'concept' : 'completed')).toLowerCase();
        const status = st.startsWith('ongo') ? 'ongoing' : st.startsWith('con') ? 'concept' : 'completed';
        const p = {
          slug: slugify(`${name}-${catName === 'Residences' ? '' : one}`).replace(/-$/, '') || slugify(name), name, category: slug, status,
          city: info.city || '[City]', year: info.year || '[Year]', stage: Math.min(6, Math.max(1, parseInt(info.stage, 10) || 1)),
          updated: info.updated || '', plot: info.plot, area: info['built-up area'] || info['built up area'] || info.area, scope: info.scope,
          brief: info.brief, tint: '#818865', walkthroughLink: /^https?:/.test(info.walkthrough || '') ? info.walkthrough : null,
        };
        const top = files(dir, IMG).sort(byOrder);
        const pick = (re) => top.find((f) => re.test(f));
        const hero = pick(/elevation|front|cover|hero/i) || top.find((f) => !/render/i.test(f));
        const render = pick(/render/i);
        if (hero) { p.heroImage = media.image(join(dir, hero), `${name}, front elevation`, [1200, 2400]); p.tileImage = media.image(join(dir, hero), `${name}`, [600, 1200]); }
        if (render) { p.render = media.image(join(dir, render), `${name}, render of how it will look`, [1000, 2000]); if (!p.tileImage) p.tileImage = media.image(join(dir, render), name, [600, 1200]); }
        const vid = files(dir, VIDEO)[0];
        if (vid) p.walkthrough = media.copy(join(dir, vid));
        // galleries: Site photographs, Interiors, Drawings (only presentation drawings, spec 11)
        const gallery = (...keys) => {
          const g = find(dir, ...keys);
          if (!g) return null;
          const items = files(join(dir, g), IMG).sort(byOrder).map((f) => { const cap = parseName(f).name; return { caption: cap, label: cap, image: media.image(join(dir, g, f), `${name}, ${cap}`) }; });
          return items.length ? items : null;
        };
        p.galleries = { site: gallery('site photograph', 'exterior'), interiors: gallery('interior'), drawings: gallery('drawing') };
        // ongoing: "Site photos/Stage 4/2026-10-30 north wall.jpg"; the newest two are shown first
        const sp = find(dir, 'site photo', 'progress');
        if (sp) {
          const photos = [];
          const add = (folder, stage) => files(folder, IMG).forEach((f) => {
            const iso = dateIn(f) || dateIn(basename(folder)) || new Date(statSync(join(folder, f)).mtimeMs).toISOString().slice(0, 10);
            // "2026-10-30 north wall.jpg": the date first, then the caption
            const cap = basename(f, extname(f)).replace(/^\s*\d{4}[-_. ]\d{2}[-_. ]\d{2}[\s._-]*/, '').replace(/^\d+[\s._-]+/, '').trim();
            photos.push({ iso, stage, caption: `${cap ? cap + ' · ' : ''}${niceDate(iso)}`, label: 'Site photo', image: media.image(join(folder, f), `${name}, site photo, ${niceDate(iso)}`, [600, 1200]) });
          });
          add(join(dir, sp), null);
          dirs(join(dir, sp)).forEach((d) => { const m = d.match(/stage\s*(\d)/i); add(join(dir, sp, d), m ? +m[1] : null); });
          photos.sort((a, b) => b.iso.localeCompare(a.iso));
          if (photos.length) {
            p.latest = photos.slice(0, 2);
            p.archive = STAGE_NAMES.map((s, k) => ({ stage: `Stage ${k + 1} · ${s}`, photos: photos.filter((x) => x.stage === k + 1) })).filter((a) => a.photos.length).reverse();
            const undated = photos.filter((x) => !x.stage);
            if (undated.length) p.archive.push({ stage: 'Site photos', photos: undated });
            if (!p.updated) p.updated = niceDate(photos[0].iso);
          }
        }
        if (!p.updated) p.updated = '[Date]';
        C.projects.push(p);
      }
    }
    if (!C.projects.length) { delete C.categories; delete C.projects; }
  }

  // 6 Contact
  const ct = find(root, 'contact');
  if (ct) {
    const info = parseInfo(textFile(join(root, ct), 'details', 'contact'));
    C.contact = { address: info.address ? info.address.split('\n').map((l) => l.trim()).filter(Boolean) : null, phone: info.phone, email: info.email, hours: info.hours, instagram: info.instagram };
  }
  C.warnings.push(...media.warnings);
  return C;
}
