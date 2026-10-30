# Cleans every frame of the logo animation and stacks colour over alpha for a transparent MP4.
from PIL import Image, ImageFilter
import numpy as np, glob, sys
from collections import deque

SILVER = np.array([186, 180, 172], float)

def box(x, r):
    # box filter via cumulative sums, same size output
    p = np.pad(x, ((r + 1, r), (r + 1, r)) + ((0, 0),) * (x.ndim - 2), mode='constant')
    c = p.cumsum(0).cumsum(1)
    k = 2 * r + 1
    return c[k:, k:] - c[:-k, k:] - c[k:, :-k] + c[:-k, :-k]

def blobs(mask):
    seen = np.zeros_like(mask, bool); out = []
    H, W = mask.shape
    for y, x in zip(*np.nonzero(mask)):
        if seen[y, x]: continue
        q = deque([(y, x)]); seen[y, x] = True; pts = []
        while q:
            cy, cx = q.popleft(); pts.append((cy, cx))
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    ny, nx = cy + dy, cx + dx
                    if 0 <= ny < H and 0 <= nx < W and mask[ny, nx] and not seen[ny, nx]:
                        seen[ny, nx] = True; q.append((ny, nx))
        out.append(pts)
    return out

def dilate(m, k):
    return np.array(Image.fromarray((m * 255).astype('uint8')).filter(ImageFilter.MaxFilter(k))) > 0

def drop_glitter(rgb, a):
    # keep the one star that leads the drawing; remove the scattered sparkles it leaves behind
    R, B = rgb[..., 0], rgb[..., 2]
    S = (a > 20) & (R > 238) & (R - B > 29)
    if not S.any(): return rgb, a
    bl = sorted(blobs(dilate(S, 5)), key=len, reverse=True)
    lead = bl[0] if len(bl[0]) > 150 else None
    gone = np.zeros_like(S)
    for b in bl:
        if b is lead: continue
        ys, xs = zip(*b); gone[list(ys), list(xs)] = True
    if not gone.any(): return rgb, a
    gone = dilate(gone, 5)
    keep = (~gone).astype(float)
    rgb, a = rgb.copy(), a.copy()
    todo = gone.copy()
    for r in (3, 6, 10):
        w = box(keep, r)
        ok = todo & (w > 0)
        aa = box(a * keep, r)
        a[ok] = aa[ok] / w[ok]
        for i in range(3):
            c = box(rgb[..., i] * keep, r)
            rgb[..., i][ok] = c[ok] / w[ok]
        todo &= ~ok
    return rgb, a

def clean(path):
    f = np.array(Image.open(path)).astype(float)
    rgb, a = drop_glitter(f[..., :3], f[..., 3])
    # 1. faint dust: drop near-invisible pixels, and anything faint that is not next to a real stroke
    a[a <= 10] = 0
    near = np.array(Image.fromarray(a.astype('uint8')).filter(ImageFilter.MaxFilter(5))).astype(float)
    a[(near < 48)] = 0
    # 2. edge colour: the master stores dark colour in its antialiased edges, which draws a brown outline.
    #    Give every edge pixel the colour of the solid metal next to it instead.
    solid = (a >= 225).astype(float)
    out = rgb.copy()
    todo = a < 225
    for r in (2, 4, 8):
        w = box(solid, r)
        s = np.stack([box(rgb[..., i] * solid, r) for i in range(3)], -1)
        ok = todo & (w > 0)
        out[ok] = s[ok] / w[ok][:, None]
        todo &= ~ok
    # pixels with no solid metal nearby (the travelling star and its sparkle): un-premultiply, kept light
    if todo.any():
        un = np.where(a[..., None] > 0, rgb / np.maximum(a[..., None] / 255, 0.05), SILVER)
        out[todo] = np.clip(un[todo], 150, 245)
    out[a == 0] = SILVER
    return np.clip(out, 0, 255).astype('uint8'), a.astype('uint8')

fs = sorted(glob.glob('c/*.png'))
for i, fp in enumerate(fs):
    rgb, a = clean(fp)
    h, w = a.shape
    st = np.zeros((h * 2, w, 3), 'uint8')
    st[:h] = rgb
    st[h:] = a[..., None]
    Image.fromarray(st).save(f's/{i + 1:04d}.png', compress_level=1)
    if i == len(fs) - 1:
        Image.fromarray(np.dstack([rgb, a])).save('logo-last.png')
print('cleaned', len(fs))
