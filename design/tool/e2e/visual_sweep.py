# -*- coding: utf-8 -*-
"""Chụp mọi màn ở chế độ sáng và tối với dữ liệu mẫu, ghép thành các tờ ảnh để rà bằng mắt (out/vs/)."""
import os
from PIL import Image
from playwright.sync_api import sync_playwright
from gb import GB, OUT

KEYS = ['tab0', 'tab1', 'tab2', 'tab3', 'tab5', 'tab4', 'feed', 'pump', 'sleep', 'diaper', 'vaccine', 'growth',
        'solids', 'articles', 'mind', 'epds', 'noise', 'family', 'premium', 'settings', 'easy', 'milk', 'leaps',
        'memory', 'memcard', 'recap']
D = os.path.join(OUT, 'vs')
os.makedirs(D, exist_ok=True)

with sync_playwright() as p:
    g = GB(p)
    g.open(wait=10)
    g.tap('Xem thử với dữ liệu mẫu', wait=6000)
    for mode in ('light', 'dark'):
        if mode == 'dark':
            g.open('?go=tab0', wait=8)
            g.tap('Chuyển sang chế độ tối', wait=2500)
        for k in KEYS:
            g.open('?go=' + k, wait=6)
            g.page.wait_for_timeout(2500)
            g.page.screenshot(path=os.path.join(D, '%s_%s.png' % (mode, k)))
        print(mode, 'xong')
    g.close()

# ghép: mỗi tờ 6 màn, hàng trên sáng, hàng dưới tối
def sheet(keys, name):
    w, h = 390, 844
    s = Image.new('RGB', (w * len(keys), h * 2), 'white')
    for i, k in enumerate(keys):
        for r, m in enumerate(('light', 'dark')):
            im = Image.open(os.path.join(D, '%s_%s.png' % (m, k))).convert('RGB').resize((w, h))
            s.paste(im, (i * w, r * h))
    s.save(os.path.join(D, name))

for n in range(0, len(KEYS), 5):
    sheet(KEYS[n:n + 5], 'sheet_%02d.png' % (n // 5))
print('ok')
