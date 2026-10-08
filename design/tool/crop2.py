"""Cắt thêm tranh từ 4 ảnh mẫu mới (ref11..14) và tạo biến thể màu (bạc, máu) bằng code."""
import colorsys
import os

import numpy as np
from PIL import Image

import crop as C

C.CUTS = []
CUTS = [
    ('hero_diaper', 'ref14', (508, 112, 850, 440), 14, 34, [(0, 0, 90, 16), (222, 40, 340, 160)]),
    ('hero_baby_awake', 'ref13', (548, 118, 845, 410), 14, 34, [(0, 0, 90, 16), (190, 25, 300, 120)]),
    ('poop_yellow', 'ref14', (146, 508, 220, 582), 16, 36, []),
    ('poop_mustard', 'ref14', (268, 510, 336, 580), 16, 36, []),
    ('poop_green', 'ref14', (382, 508, 456, 582), 16, 36, []),
    ('poop_brown', 'ref14', (498, 508, 572, 580), 16, 36, []),
    ('poop_black', 'ref14', (614, 508, 688, 582), 16, 36, []),
    ('poop_mucus', 'ref14', (728, 508, 804, 582), 16, 36, []),
    ('tex_liquid', 'ref14', (148, 730, 232, 772), 16, 36, []),
    ('tex_soft', 'ref14', (290, 722, 374, 768), 16, 36, []),
    ('tex_chunky', 'ref14', (426, 720, 514, 770), 16, 36, []),
    ('tex_hard', 'ref14', (566, 720, 656, 766), 16, 36, []),
    ('tex_foam', 'ref14', (714, 720, 794, 770), 16, 36, []),
    ('diaper_few', 'ref14', (204, 898, 280, 958), 16, 36, []),
    ('diaper_mid', 'ref14', (434, 898, 508, 958), 16, 36, []),
    ('diaper_lots', 'ref14', (664, 898, 744, 958), 16, 36, []),
]


def recolor(src, dst, hue=None, sat=1.0, val=1.0, tint=None):
    im = Image.open(os.path.join(C.OUT, src + '.png')).convert('RGBA')
    a = np.asarray(im).astype(np.float32) / 255
    out = a.copy()
    for y in range(a.shape[0]):
        for x in range(a.shape[1]):
            r, g, b, al = a[y, x]
            if al < .02:
                continue
            h, s, v = colorsys.rgb_to_hsv(r, g, b)
            if hue is not None:
                h = hue
            s = min(1, s * sat)
            v = min(1, v * val)
            r2, g2, b2 = colorsys.hsv_to_rgb(h, s, v)
            out[y, x] = (r2, g2, b2, al)
    Image.fromarray((out * 255).astype(np.uint8), 'RGBA').save(os.path.join(C.OUT, dst + '.png'))


if __name__ == '__main__':
    for c in CUTS:
        C.cut(*c)
    # biến thể: phân bạc/trắng (ít màu, sáng) và phân có máu (nâu đỏ)
    recolor('poop_mucus', 'poop_silver', hue=0.0, sat=0.0, val=0.97)
    recolor('poop_brown', 'poop_blood', hue=0.0, sat=1.6, val=0.95)
