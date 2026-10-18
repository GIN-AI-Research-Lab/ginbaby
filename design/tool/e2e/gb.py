# -*- coding: utf-8 -*-
"""Khung kiểm thử trình duyệt cho GinBaby: bật trợ năng Flutter, chọn nút theo nhãn, thu lỗi console."""
import os, sys, re
from playwright.sync_api import sync_playwright

BASE = os.environ.get('GB_BASE', 'http://127.0.0.1:8090/')
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'out')
os.makedirs(OUT, exist_ok=True)
try:
    sys.stdout.reconfigure(encoding='utf-8')
except Exception:
    pass

RESULTS = []


class GB:
    def __init__(self, p, state=None, offline=False, dark=False):
        self.b = p.chromium.launch(channel='chrome', headless=True)
        dev = dict(p.devices['iPhone 13']); dev['device_scale_factor'] = 2
        if state:
            dev['storage_state'] = state
        self.ctx = self.b.new_context(**dev)
        self.page = self.ctx.new_page()
        self.errors = []
        self.page.on('console', lambda m: self.errors.append('console: ' + m.text[:200]) if m.type == 'error' else None)
        self.page.on('pageerror', lambda e: self.errors.append('pageerror: ' + str(e)[:200]))

    def open(self, q='', wait=9):
        self.page.goto(BASE + q, wait_until='load')
        self.page.wait_for_timeout(wait * 1000)
        self.sem()

    def sem(self):
        self.page.evaluate("document.querySelector('flt-semantics-placeholder')?.click()")
        self.page.wait_for_timeout(800)

    def labels(self):
        return self.page.evaluate("""() => [...document.querySelectorAll('flt-semantics')]
            .map(n => (n.getAttribute('aria-label') || n.textContent || '').replace(/\\s+/g, ' ').trim()).filter(x => x)""")

    def has(self, text):
        return any(text in l for l in self.labels())

    def wait(self, text, secs=8):
        for _ in range(int(secs * 4)):
            if self.has(text):
                return True
            self.page.wait_for_timeout(250)
        return False

    def tap(self, text, nth=0, exact=False, wait=900):
        """Bấm nút/ô có nhãn chứa [text]. Trả về False nếu không thấy."""
        pos = self.page.evaluate("""([t, exact, nth]) => {
            const out = [];
            const all = [...document.querySelectorAll('flt-semantics')];
            for (let i = 0; i < all.length; i++) {
              const n = all[i];
              const l = (n.getAttribute('aria-label') || n.textContent || '').replace(/\s+/g, ' ').trim();
              const r = n.getAttribute('role');
              const own = r === 'button' || r === 'textbox' || r === 'tab' || r === 'checkbox' || r === 'switch' || n.getAttribute('aria-label');
              if (!(own && (exact ? l === t : l.includes(t)))) continue;
              const b = n.getBoundingClientRect();
              if (b.width <= 0 || b.height <= 0) continue;
              const pref = (r === 'button' || r === 'textbox' || r === 'tab' || r === 'checkbox' || r === 'switch') ? 0 : 1;
              out.push([b.left + b.width / 2, b.top + b.height / 2, i, pref]);
            }
            out.sort((a, b) => a[3] - b[3] || a[2] - b[2]); // ưu tiên nút thật, rồi theo thứ tự trong trang
            return out[nth] || null; }""", [text, exact, nth])
        if pos is None:
            return False
        vh = self.page.evaluate('window.innerHeight')
        if 4 < pos[1] < vh - 4:
            # trong màn hình: chạm chuột tại tâm phần tử (giống ngón tay thật)
            self.page.mouse.click(pos[0], pos[1])
        else:
            # ngoài màn hình: để Playwright tự cuộn tới rồi bấm
            self.page.locator('flt-semantics').nth(int(pos[2])).click(force=True)
        self.page.wait_for_timeout(wait)
        return True

    def type_in(self, label, text, nth=0):
        """Chạm vào ô nhập có nhãn [label] rồi gõ [text] (thay nội dung cũ)."""
        inp = self.page.locator('input[aria-label*="%s"], textarea[aria-label*="%s"]' % (label, label))
        if inp.count() <= nth:
            return False
        el = inp.nth(nth)
        el.click(force=True)
        self.page.keyboard.press('Control+A')
        self.page.keyboard.type(text, delay=20)
        self.page.wait_for_timeout(400)
        return True

    def inputs(self):
        return self.page.evaluate("[...document.querySelectorAll('input,textarea')].map(i => i.getAttribute('aria-label'))")

    def uniq(self, n=40):
        seen, out = set(), []
        for l in self.labels():
            if l not in seen and len(l) < 80:
                seen.add(l); out.append(l)
        return out[:n]

    def shot(self, name):
        self.page.screenshot(path=os.path.join(OUT, name + '.png'))

    def close(self):
        self.b.close()


def check(name, ok, detail=''):
    RESULTS.append((name, bool(ok), detail))
    print(('PASS ' if ok else 'FAIL ') + name + (('  -> ' + str(detail)) if (detail and not ok) else ''))


def summary():
    bad = [r for r in RESULTS if not r[1]]
    print('\n%d/%d đạt' % (len(RESULTS) - len(bad), len(RESULTS)))
    for n, _, d in bad:
        print('  FAIL', n, d)
    return len(bad)
