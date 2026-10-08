# -*- coding: utf-8 -*-
"""Chụp ảnh màn hình app (giả lập iPhone 13) cho README. Cần Playwright + Chrome và máy chủ đang chạy ở cổng 8090."""
import os, sys
from playwright.sync_api import sync_playwright

BASE = 'http://localhost:8090/'
OUT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', 'docs', 'screenshots'))
os.makedirs(OUT, exist_ok=True)

LIGHT = [  # (tên tệp, tham số, chờ giây)
    ('home', 'go=tab0', 4),
    ('history', 'go=tab1', 4),
    ('stats', 'go=tab2', 5),
    ('utilities', 'go=tab5', 4),
    ('bottle', 'go=feed', 4),
    ('pump', 'go=pump', 4),
    ('diaper', 'go=diaper', 4),
    ('milestones', 'go=memory', 4),
    ('milestone-card', 'go=memcard', 4),
    ('leaps', 'go=leaps', 4),
    ('vaccine', 'go=vaccine', 4),
    ('growth', 'go=growth', 5),
    ('money', 'go=tab3', 4),
    ('milk-stash', 'go=milk', 4),
    ('easy', 'go=easy', 4),
    ('mind', 'go=mind', 4),
]
DARK = [
    ('home-dark', 'go=tab0', 4),
    ('stats-dark', 'go=tab2', 5),
    ('utilities-dark', 'go=tab5', 4),
    ('bottle-dark', 'go=feed', 4),
    ('history-dark', 'go=tab1', 4),
]

with sync_playwright() as p:
    b = p.chromium.launch(channel='chrome', headless=True)
    dev = dict(p.devices['iPhone 13'])
    dev['device_scale_factor'] = 2
    ctx = b.new_context(**dev)
    page = ctx.new_page()
    page.goto(BASE + '?glass=2', wait_until='load')
    page.wait_for_timeout(12000)
    page.mouse.click(195, 625)  # "Xem thử với dữ liệu mẫu"
    page.wait_for_timeout(5000)

    def shoot(name, q, wait):
        page.goto(BASE + '?glass=2&' + q, wait_until='load')
        page.wait_for_timeout(wait * 1000 + 3000)
        page.screenshot(path=os.path.join(OUT, name + '.png'))
        print('ok', name)

    for name, q, wait in LIGHT:
        shoot(name, q, wait)
    # đổi sang chế độ tối bằng nút trên Trang chủ (không dùng tham số để tránh lẫn trạng thái)
    page.goto(BASE + '?glass=2&go=tab0', wait_until='load')
    page.wait_for_timeout(8000)
    page.mouse.click(357, 26)
    page.wait_for_timeout(4000)
    for name, q, wait in DARK:
        shoot(name, q, wait)
    b.close()
