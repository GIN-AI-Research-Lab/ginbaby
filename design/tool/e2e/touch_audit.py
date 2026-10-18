# -*- coding: utf-8 -*-
"""Đo vùng chạm: liệt kê nút nhỏ hơn 44x44 pt trên từng màn (iPhone 13, 390 pt rộng)."""
from collections import defaultdict
from playwright.sync_api import sync_playwright
from gb import GB

KEYS = ['tab0', 'tab1', 'tab2', 'tab3', 'tab5', 'tab4', 'feed', 'pump', 'sleep', 'diaper', 'vaccine', 'growth',
        'solids', 'articles', 'mind', 'epds', 'noise', 'family', 'settings', 'easy', 'milk', 'leaps', 'memory',
        'memcard', 'recap', 'moneyadd', 'history']
JS = """() => [...document.querySelectorAll('flt-semantics')].filter(n => {
  const r = n.getAttribute('role'); return r === 'button' || r === 'checkbox' || r === 'switch' || r === 'tab' || r === 'radio' || r === 'slider';
}).map(n => { const b = n.getBoundingClientRect(); return [ (n.getAttribute('aria-label') || n.textContent || '').replace(/\\s+/g, ' ').trim().slice(0, 34), Math.round(b.width), Math.round(b.height), Math.round(b.top), Math.round(b.left) ]; })
.filter(x => x[0] && x[1] > 0 && x[2] > 0 && x[3] >= 0 && x[3] < 844)"""

with sync_playwright() as p:
    g = GB(p)
    g.open(wait=10)
    g.tap('Xem thử với dữ liệu mẫu', wait=6000)
    small = defaultdict(list)
    total = 0
    for k in KEYS:
        g.open('?go=' + k, wait=5)
        g.page.wait_for_timeout(1500)
        items = g.page.evaluate(JS)
        total += len(items)
        for lab, w, h, top, left in items:
            if w < 44 or h < 44:
                small[k].append((lab, w, h))
    print('tổng nút đo:', total)
    for k, v in small.items():
        seen = set(); out = []
        for lab, w, h in v:
            key = (lab, w, h)
            if key in seen:
                continue
            seen.add(key); out.append('%s [%dx%d]' % (lab, w, h))
        print('\n%s (%d):' % (k, len(out)))
        for o in out[:14]:
            print('   ', o)
    g.close()
