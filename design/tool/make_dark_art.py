# -*- coding: utf-8 -*-
"""Tạo bản tranh cho chế độ tối: assets/art_dark/<tên>.png từ assets/art/<tên>.png.

Ý tưởng: đảo độ sáng của các màu trung tính (kem, trắng, nét viền nâu sẫm) và giữ nguyên màu có sắc độ cao
(da, hồng, tím, xanh), nâng nhẹ các màu tối (tóc) để vẫn đọc được trên nền tối.
"""
import os
import sys

import numpy as np
from PIL import Image

SRC = r'F:\Project Ai\GinBaby\app\assets\art'
DST = r'F:\Project Ai\GinBaby\app\assets\art_dark'
BASE = os.path.dirname(SRC)
SMALL = 192
os.makedirs(DST, exist_ok=True)


def rgb_to_hsv(a):
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    mx = np.max(a, axis=-1)
    mn = np.min(a, axis=-1)
    d = mx - mn
    s = np.where(mx > 0, d / np.maximum(mx, 1e-6), 0)
    return mx, s, d


def defringe(arr):
    """Bỏ viền sáng quanh hình: pixel bán trong suốt lấy màu của các pixel đặc gần nhất (không còn quầng trắng/kem
    của nền cũ), rồi co nhẹ độ trong suốt để mép mịn, không răng cưa sáng."""
    rgb = arr[..., :3].astype(np.float32) / 255
    al = arr[..., 3].astype(np.float32) / 255
    core = al > 0.92
    col = np.where(core[..., None], rgb, 0).astype(np.float32)
    have = core.astype(np.float32)
    fill = core.copy()
    for _ in range(6):
        sh = [(dy, dx) for dy in (-1, 0, 1) for dx in (-1, 0, 1) if (dy, dx) != (0, 0)]
        acc = np.zeros_like(col)
        cnt = np.zeros_like(have)
        for dy, dx in sh:
            acc += np.roll(np.roll(col * have[..., None], dy, 0), dx, 1)
            cnt += np.roll(np.roll(have, dy, 0), dx, 1)
        new = (cnt > 0) & (~fill)
        col[new] = acc[new] / cnt[new][:, None]
        have[new] = 1
        fill |= new
    out_rgb = np.where(core[..., None], rgb, np.where(fill[..., None], col, rgb))
    # co độ trong suốt: mép mờ (<0.35) biến mất, phần còn lại kéo giãn
    al2 = np.clip((al - 0.30) / 0.60, 0, 1)
    res = np.concatenate([out_rgb, al2[..., None]], axis=-1)
    return (np.clip(res, 0, 1) * 255).astype(np.uint8)


def process(arr):
    arr = defringe(arr)
    a = arr[..., 3:4]
    rgb = arr[..., :3].astype(np.float32) / 255
    mx, s, d = rgb_to_hsv(rgb)
    lum = 0.2126 * rgb[..., 0] + 0.7152 * rgb[..., 1] + 0.0722 * rgb[..., 2]

    # 1) màu sáng trung tính (kem, trắng: độ bão hoà rất thấp): chuyển thành tím than ấm cho hợp nền tối
    w_neutral = np.clip(1 - s / 0.20, 0, 1) * np.clip((lum - 0.50) / 0.20, 0, 1)
    # trắng/kem -> be hồng khói (vẫn sáng, giữ được cảm giác màu nước; không biến thành mảng tối)
    base_n = np.array([0.95, 0.88, 0.90], dtype=np.float32)
    neutral = np.clip(base_n[None, None, :] * (0.90 + 0.10 * lum)[..., None], 0, 1)

    # 2) mọi màu còn lại: nâng độ sáng (giữ nguyên sắc và độ bão hoà) để tóc, nét viền thành màu pastel đậm, không bị xám bùn
    target = mx + (0.80 - mx) * np.clip((0.75 - mx) / 0.75, 0, 1) * 0.85
    scale = np.where(mx > 0.02, target / np.maximum(mx, 0.02), 1.0)
    base = np.where((mx > 0.02)[..., None], rgb * scale[..., None], np.stack([target] * 3, axis=-1))
    # nét gần xám/đen: ám hồng ấm cho hợp tranh pastel
    greyish = np.clip(1 - s / 0.25, 0, 1)[..., None]
    warm = np.array([1.0, 0.82, 0.80], dtype=np.float32)
    chroma = np.clip(base * (1 - 0.35 * greyish) + base * warm * 0.35 * greyish, 0, 1)

    w = w_neutral[..., None]
    out = neutral * w + chroma * (1 - w)
    res = np.concatenate([out, a.astype(np.float32) / 255], axis=-1)
    return (np.clip(res, 0, 1) * 255).astype(np.uint8)


def hero_pass(arr):
    """Tranh lớn (mẹ bế bé, mẹ hút sữa...) ở nền tối: bóp mép trong suốt 2 px để hết viền kem quanh tóc/áo,
    hạ vùng sáng chói (da, áo trắng) xuống tông tím khói cho khớp nền."""
    from PIL import ImageFilter
    # viền kem cứng quanh tóc/áo: điểm sáng, gần trắng nằm trong dải 10 px sát mép -> trong suốt
    inner = np.asarray(Image.fromarray(arr[..., 3], 'L').filter(ImageFilter.MinFilter(7))) > 128
    f = arr[..., :3].astype(np.float32) / 255
    mx, mn = f.max(-1), f.min(-1)
    hair = (f[..., 0] > f[..., 2] + 0.12) & (mx < 0.80) & (arr[..., 3] > 200)
    near_hair = np.asarray(Image.fromarray((hair * 255).astype(np.uint8), 'L').filter(ImageFilter.MaxFilter(9))) > 128
    rim = near_hair & (~inner) & (mx > 0.84) & ((mx - mn) < 0.16)
    arr = arr.copy()
    arr[rim, 3] = 0
    a = Image.fromarray(arr[..., 3], 'L').filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(0.9))
    al = np.asarray(a).astype(np.float32) / 255
    al = np.clip((al - 0.15) / 0.7, 0, 1)
    rgb = arr[..., :3].astype(np.float32) / 255
    lum = (0.2126 * rgb[..., 0] + 0.7152 * rgb[..., 1] + 0.0722 * rgb[..., 2])[..., None]
    k = np.clip((lum - 0.55) / 0.45, 0, 1)
    tint = np.array([0.80, 0.72, 0.88], dtype=np.float32)
    rgb = rgb * (1 - 0.30 * k) + rgb * tint * 0.30 * k
    rgb = rgb * 0.88
    return (np.clip(np.concatenate([rgb, al[..., None]], -1), 0, 1) * 255).astype(np.uint8)


def small(img, path):
    if max(img.size) > SMALL:
        r = SMALL / max(img.size)
        img = img.resize((round(img.width * r), round(img.height * r)), Image.LANCZOS)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path, optimize=True)


def main():
    names = [f[:-4] for f in os.listdir(SRC) if f.endswith('.png')]
    if len(sys.argv) > 1:
        names = [n for n in names if n in sys.argv[1:]]
    for n in names:
        im = Image.open(os.path.join(SRC, n + '.png')).convert('RGBA')
        arr = process(np.asarray(im))
        if n.startswith('hero_'):
            arr = hero_pass(arr)
        out = Image.fromarray(arr, 'RGBA')
        out.save(os.path.join(DST, n + '.png'), optimize=True)
        if not n.startswith('hero_'):
            small(im, os.path.join(BASE, 'art_s', n + '.png'))
            small(out, os.path.join(BASE, 'art_dark_s', n + '.png'))
    print('done', len(names))


if __name__ == '__main__':
    main()
