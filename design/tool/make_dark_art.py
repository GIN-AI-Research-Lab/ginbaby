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
os.makedirs(DST, exist_ok=True)


def rgb_to_hsv(a):
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    mx = np.max(a, axis=-1)
    mn = np.min(a, axis=-1)
    d = mx - mn
    s = np.where(mx > 0, d / np.maximum(mx, 1e-6), 0)
    return mx, s, d


def process(arr):
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


def main():
    names = [f[:-4] for f in os.listdir(SRC) if f.endswith('.png')]
    if len(sys.argv) > 1:
        names = [n for n in names if n in sys.argv[1:]]
    for n in names:
        im = Image.open(os.path.join(SRC, n + '.png')).convert('RGBA')
        out = Image.fromarray(process(np.asarray(im)), 'RGBA')
        out.save(os.path.join(DST, n + '.png'), optimize=True)
    print('done', len(names))


if __name__ == '__main__':
    main()
