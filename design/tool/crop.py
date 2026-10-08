"""Cắt hình minh hoạ từ ảnh mẫu, xoá nền bằng flood-fill từ mép và xuất PNG trong suốt.

Dùng: python crop.py   (đọc danh sách CUTS bên dưới)
"""
import os
import numpy as np
from PIL import Image
from scipy import ndimage as ndi

REF = r'F:\Project Ai\GinBaby\design\ref'
OUT = r'F:\Project Ai\GinBaby\app\assets\art'
PREV = r'F:\Project Ai\GinBaby\design\ref\prev'
os.makedirs(OUT, exist_ok=True)
os.makedirs(PREV, exist_ok=True)

# name, ref, (x0, y0, x1, y1), tolerance low/high, [erase boxes in crop coords filled with bg]
CUTS = [
    ('hero_mom_baby', 'ref9', (505, 118, 850, 420), 14, 34, [(0, 0, 80, 14)]),
    ('hero_pump', 'ref8', (525, 112, 815, 452), 14, 34, [(0, 0, 90, 22), (215, 30, 310, 180), (0, 300, 60, 340)]),
    ('ic_pump', 'ref7', (140, 432, 245, 545), 16, 36, []),
    ('ic_breast', 'ref7', (318, 430, 445, 545), 16, 36, []),
    ('ic_bottle', 'ref7', (518, 432, 605, 548), 16, 36, []),
    ('ic_moon', 'ref7', (700, 440, 800, 548), 16, 36, []),
    ('baby_sleep', 'ref7', (500, 1205, 610, 1350), 14, 34, []),
    ('rainbow', 'ref7', (590, 1385, 690, 1455), 14, 34, []),
    ('pump_left', 'ref8', (155, 500, 250, 600), 14, 34, []),
    ('pump_right', 'ref8', (695, 500, 790, 600), 14, 34, []),
]


def cut(name, ref, box, t0, t1, erase):
    im = Image.open(os.path.join(REF, ref + '.png')).convert('RGB').crop(box)
    a = np.asarray(im).astype(np.float32)
    h, w, _ = a.shape
    border = np.concatenate([a[0], a[-1], a[:, 0], a[:, -1]])
    bg = np.median(border, axis=0)
    for (ex0, ey0, ex1, ey1) in erase:
        a[ey0:ey1, ex0:ex1] = bg
    dist = np.abs(a - bg).max(axis=2)
    near = dist < t1
    lab, n = ndi.label(near)
    edge_labels = set(lab[0]) | set(lab[-1]) | set(lab[:, 0]) | set(lab[:, -1])
    edge_labels.discard(0)
    bgmask = np.isin(lab, list(edge_labels))
    alpha = np.where(bgmask, np.clip((dist - t0) / (t1 - t0), 0, 1), 1.0)
    # Làm sạch viền: bỏ đảo nhỏ nằm ngoài (hạt bụi), giữ thành phần lớn nhất
    solid = alpha > .5
    lab2, n2 = ndi.label(solid)
    if n2 > 1:
        sizes = ndi.sum(solid, lab2, range(1, n2 + 1))
        keep = [i + 1 for i, s in enumerate(sizes) if s > 0.04 * sizes.max()]
        alpha = np.where(np.isin(lab2, keep) | (alpha >= 1), alpha, 0)
    al = np.clip(alpha, 1e-3, 1)[..., None]
    rgb = np.where(al < 1, (a - (1 - al) * bg) / al, a)
    rgb = np.clip(rgb, 0, 255)
    out = np.dstack([rgb, alpha * 255]).astype(np.uint8)
    img = Image.fromarray(out, 'RGBA')
    bbox = img.getchannel('A').point(lambda v: 255 if v > 8 else 0).getbbox()
    if bbox:
        img = img.crop(bbox)
    img.save(os.path.join(OUT, name + '.png'), optimize=True)
    prev = Image.new('RGBA', img.size, (120, 150, 200, 255))
    prev.alpha_composite(img)
    prev.convert('RGB').save(os.path.join(PREV, name + '.png'))
    print(name, img.size)


if __name__ == '__main__':
    for c in CUTS:
        cut(*c)
