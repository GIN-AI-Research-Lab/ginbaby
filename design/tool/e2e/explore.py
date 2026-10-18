# -*- coding: utf-8 -*-
"""Thăm dò nhãn: python explore.py go:solids go:milk 'Nút cần bấm' ... (tạo hồ sơ mới trước)."""
import sys
from playwright.sync_api import sync_playwright
from gb import GB
with sync_playwright() as p:
    g = GB(p); g.open(wait=10)
    g.type_in('Tên bé', 'Bé Gin'); g.tap('Bé trai')
    for _ in range(6):
        if g.has('Bắt đầu'): break
        g.tap('Tiếp tục')
    g.tap('Bắt đầu', wait=4000)
    for a in sys.argv[1:]:
        if a.startswith('go:'):
            g.open('?go=' + a[3:], wait=6)
        else:
            g.tap(a, wait=1500)
        print('\n==', a); print(g.uniq(45)); print('inputs', g.inputs())
    print('ERR', g.errors[:3]); g.close()
