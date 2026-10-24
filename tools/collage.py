#!/usr/bin/env python3
"""A 16:9 collage of the store's widgets for sharing, one image per theme, and
optionally a video that fades through them.

Big widgets are shrunk and small ones grown so sizes mix across the frame; the
featured ones are drawn larger and spread out. Widgets then grow into any free
cells around them, extending their own panel background, so no gaps are left.
The layout is seeded, so every theme gets the same one.

  tools/collage.py [-f author/id ...] [-t theme ...] [--video [seconds per theme]]

  tools/collage.py -f cbarland/astroterm gregoftheweb/sky ... \\
    -t tokyo-night vantablack retro-82 gruvbox all --video

Needs Pillow and numpy; --video needs ffmpeg. Output goes to collage/ (ignored).
"""
import argparse, glob, math, os, random, subprocess
import numpy as np
from PIL import Image

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UX, UY, GAP = 88.75, 95, 14  # layout unit: half a launcher cell pitch, in preview pixels
BORDER = 6                   # every preview has a 6px frame
W, H = 3840, 2160

ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
ap.add_argument("-f", "--feature", nargs="*", default=[], metavar="ID", help="widgets to draw larger")
ap.add_argument("-t", "--theme", nargs="*", default=["tokyo-night"],
                help="themes in this order; 'all' adds every other theme after them")
ap.add_argument("-x", "--exclude", nargs="*", default=["simonschubert"], metavar="AUTHOR",
                help="authors left out (default: simonschubert, for a community collage)")
ap.add_argument("--video", nargs="?", type=float, const=1.3, metavar="SECONDS",
                help="also make collage.mp4 fading through the themes")
ap.add_argument("-o", "--out", default=os.path.join(REPO, "collage"))
args = ap.parse_args()

items = []
for p in sorted(glob.glob(f"{REPO}/widgets/*/*/preview.png")):
    wid = os.path.relpath(os.path.dirname(p), f"{REPO}/widgets")
    if wid.split("/")[0] in args.exclude:
        continue
    w, h = Image.open(p).size
    # Area in layout units: the square root of the launcher size evens sizes out
    a = 1.5 * math.sqrt((w / 177.5) * (h / 190))
    if wid in args.feature:
        a = max(a * 2.2, 7)
    A, asp = 4 * a, w / h
    c = max(2, round(math.sqrt(A * asp * UY / UX)))
    r = max(2, round(c * UX / (asp * UY)))
    items.append((wid, p, c, r, asp))
missing = set(args.feature) - {i[0] for i in items}
if missing:
    ap.error(f"no such widgets: {', '.join(sorted(missing))}")
total = sum(i[2] * i[3] for i in items)


def window_sum(sat, c, r):
    return sat[r:, c:] - sat[:-r, c:] - sat[r:, :-c] + sat[:-r, :-c]


def pack(C, R, rng):
    """Featured widgets go near anchors spread over the frame; the rest, biggest
    first, where they touch the most already placed widgets or edges."""
    occ = np.zeros((R, C), np.int32)
    feat = [i for i in items if i[0] in args.feature]
    rest = [i for i in items if i[0] not in args.feature]
    rng.shuffle(feat)
    gc = math.ceil(math.sqrt(len(feat) * 16 / 9)) or 1
    gr = math.ceil(len(feat) / gc) or 1
    cells = [(i, j) for j in range(gr) for i in range(gc)]
    rng.shuffle(cells)
    anchors = {f[0]: ((i + rng.uniform(.25, .75)) / gc * C, (j + rng.uniform(.25, .75)) / gr * R)
               for f, (i, j) in zip(feat, cells)}
    rest.sort(key=lambda t: -t[2] * t[3] * rng.uniform(0.5, 1.0))
    pos = {}
    for wid, p, c, r, _ in feat + rest:
        if c > C or r > R:
            return None
        sat = np.pad(occ, ((1, 0), (1, 0))).cumsum(0).cumsum(1)
        free = window_sum(sat, c, r) == 0
        if not free.any():
            return None
        ys, xs = np.nonzero(free)
        if wid in anchors:
            ax, ay = anchors[wid]
            score = -((xs + c / 2 - ax) ** 2 + (ys + r / 2 - ay) ** 2)
        else:
            satp = np.pad(np.pad(occ, 1, constant_values=1), ((1, 0), (1, 0))).cumsum(0).cumsum(1)
            ring = window_sum(satp, c + 2, r + 2)[ys, xs]
            score = ring / (2 * (c + r) + 4) + np.array([rng.uniform(0, .15) for _ in ys])
        k = int(np.argmax(score))
        x, y = int(xs[k]), int(ys[k])
        occ[y:y + r, x:x + c] = 1
        pos[wid] = [x, y, c, r]
    return pos


def layout():
    for fill in [0.95, 0.93, 0.91, 0.89, 0.87, 0.85]:
        R = round(math.sqrt(total / fill * 9 * UX / (16 * UY)))
        C = round(R * 16 * UY / (9 * UX))
        for seed in range(40):
            pos = pack(C, R, random.Random(seed))
            if pos:
                return C, R, pos
    raise SystemExit("no layout found")


C, R, pos = layout()

# Grow widgets into free neighbouring rows and columns, toward their own shape
occ = np.zeros((R, C), bool)
for x, y, c, r in pos.values():
    occ[y:y + r, x:x + c] = True
aspect = {i[0]: i[4] for i in items}
changed = True
while changed:
    changed = False
    for wid in sorted(pos, key=lambda w: pos[w][2] * pos[w][3]):
        x, y, c, r = pos[wid]
        opts = []
        if x + c < C and not occ[y:y + r, x + c].any():
            opts.append(([x, y, c + 1, r], (slice(y, y + r), x + c)))
        if x > 0 and not occ[y:y + r, x - 1].any():
            opts.append(([x - 1, y, c + 1, r], (slice(y, y + r), x - 1)))
        if y + r < R and not occ[y + r, x:x + c].any():
            opts.append(([x, y, c, r + 1], (y + r, slice(x, x + c))))
        if y > 0 and not occ[y - 1, x:x + c].any():
            opts.append(([x, y - 1, c, r + 1], (y - 1, slice(x, x + c))))
        if opts:
            rect, strip = min(opts, key=lambda o: abs(math.log(
                (o[0][2] * UX - GAP) / (o[0][3] * UY - GAP) / aspect[wid])))
            occ[strip] = True
            pos[wid] = rect
            changed = True
print(f"{len(items)} widgets, {C}x{R} grid, {int((~occ).sum())} cells left empty")


def fill_slot(im, sw, sh):
    """The widget at the slot's size: up to 8% stretched, then its panel background
    extended to the frame; photo-like widgets are cropped (at most ~15%) instead."""
    w, h = im.size
    frame = im.getpixel((0, h // 2))
    inner = im.crop((BORDER, BORDER, w - BORDER, h - BORDER))
    b = max(2, round(BORDER * min(sw / w, sh / h)))
    iw, ih = sw - 2 * b, sh - 2 * b
    px = np.asarray(inner)
    ring = np.concatenate([px[[0, 1, -2, -1]].reshape(-1, 3), px[:, [0, 1, -2, -1]].reshape(-1, 3)])
    bg = tuple(int(v) for v in np.median(ring, 0))
    uniform = (np.abs(ring.astype(int) - bg).sum(1) < 24).mean() > 0.9
    a, t = inner.width / inner.height, iw / ih
    a2 = a * min(1.08, max(1 / 1.08, t / a))
    if uniform or max(t / a2, a2 / t) > 1.15:
        cw, ch = (iw, round(iw / a2)) if a2 >= t else (round(ih * a2), ih)
        body = Image.new("RGB", (iw, ih), bg)
        body.paste(inner.resize((cw, ch), Image.LANCZOS), ((iw - cw) // 2, (ih - ch) // 2))
    else:
        cw, ch = (round(ih * a2), ih) if a2 >= t else (iw, round(iw / a2))
        body = inner.resize((cw, ch), Image.LANCZOS)
        body = body.crop(((cw - iw) // 2, (ch - ih) // 2, (cw - iw) // 2 + iw, (ch - ih) // 2 + ih))
    out = Image.new("RGB", (sw, sh), frame)
    out.paste(body, (b, b))
    return out


def render(theme):
    previews = {}
    for wid, p, *_ in items:
        t = os.path.join(os.path.dirname(p), "previews", f"{theme}.webp")
        previews[wid] = t if os.path.exists(t) else p
    fallback = [wid for wid, p in previews.items() if p.endswith("preview.png")]
    # The gutters: a shade off the theme's panel background
    m = np.median([Image.open(previews[i[0]]).convert("RGB").getpixel((BORDER + 4, BORDER + 4))
                   for i in items[:40]], 0)
    gutter = tuple(int(v) for v in (m * 0.93 if m.mean() > 128 else m * 0.7))
    cw, ch = round(C * UX), round(R * UY)
    canvas = Image.new("RGB", (cw, ch), gutter)
    for wid, (x, y, c, r) in pos.items():
        sw, sh = round(c * UX - GAP), round(r * UY - GAP)
        canvas.paste(fill_slot(Image.open(previews[wid]).convert("RGB"), sw, sh),
                     (round(x * UX + GAP / 2), round(y * UY + GAP / 2)))
    # Edge to edge: the outer half gutter goes, and the ~16:9 grid fills the frame
    g = GAP // 2
    final = canvas.crop((g, g, cw - g, ch - g)).resize((W, H), Image.LANCZOS)
    path = os.path.join(args.out, f"collage-{theme}")
    final.save(f"{path}.png", optimize=True)
    final.save(f"{path}.jpg", quality=92, subsampling=0)
    print(f"{path}.jpg", f"({len(fallback)} without this theme: {', '.join(fallback)})" if fallback else "")
    return f"{path}.png"


themes = [t for t in args.theme if t != "all"]
if "all" in args.theme:
    found = {os.path.basename(t)[:-5] for t in glob.glob(f"{REPO}/widgets/*/*/previews/*.webp")}
    themes += sorted(found - set(themes))
os.makedirs(args.out, exist_ok=True)
stills = [render(t) for t in themes]

if args.video and len(stills) > 1:
    # Ends on the first theme again, so it loops seamlessly
    D, F = args.video, 0.3
    stills.append(stills[0])
    cmd, f = ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y"], ""
    for i, s in enumerate(stills):
        cmd += ["-loop", "1", "-framerate", "30", "-t", str(D), "-i", s]
        f += f"[{i}:v]scale=1920:1080:flags=lanczos,format=yuv420p,setsar=1[v{i}];"
    prev = "v0"
    for i in range(1, len(stills)):
        f += f"[{prev}][v{i}]xfade=transition=fade:duration={F}:offset={i * (D - F):.3f}[x{i}];"
        prev = f"x{i}"
    video = os.path.join(args.out, "collage.mp4")
    subprocess.run(cmd + ["-filter_complex", f.rstrip(";"), "-map", f"[{prev}]",
                          "-t", f"{(len(stills) - 1) * (D - F):.3f}", "-c:v", "libx264", "-preset", "slow",
                          "-crf", "18", "-pix_fmt", "yuv420p", "-movflags", "+faststart", "-r", "30", video],
                   check=True)
    print(video)
