# -*- coding: utf-8 -*-
"""Kiểm thử đầu-cuối trên app thật (Chrome giả lập iPhone 13). Chạy: python e2e_full.py
Cần máy chủ app ở cổng 8090 (app/tool/deploy.ps1). Báo cáo PASS/FAIL từng bước, thu lỗi console."""
from playwright.sync_api import sync_playwright
from gb import GB, check, summary

TABS = ['Lịch sử', 'Thống kê', 'Tiền', 'Tiện ích', 'Hồ sơ', 'Trang chủ']
GO = ['feed', 'pump', 'vaccine', 'growth', 'solids', 'articles', 'mind', 'epds', 'noise', 'family',
      'premium', 'settings', 'easy', 'milk', 'sleep', 'leaps', 'memory', 'memedit', 'memcard',
      'diaper', 'history', 'moneyadd', 'profile', 'recap']


def back(g):
    return g.tap('Quay lại', wait=1200) or g.tap('Đóng', wait=1200)


with sync_playwright() as p:
    g = GB(p)
    g.open(wait=10)

    # ---- A. Người dùng mới: tạo hồ sơ
    check('A1 màn làm quen hiện ra', g.has('Chào mẹ'))
    check('A2 gõ được tên bé', g.type_in('Tên bé', 'Bé Gin'))
    g.tap('Bé trai')
    for _ in range(6):
        if g.has('Bắt đầu'):
            break
        g.tap('Tiếp tục')
    check('A3 tới bước cuối "Bắt đầu"', g.has('Bắt đầu'))
    g.tap('Bắt đầu', wait=4000)
    check('A4 vào Trang chủ', g.has('Hút sữa') and g.has('Ghi bú'))
    check('A5 Trang chủ hiện tên bé', g.has('Bé Gin'), g.uniq(8))
    g.shot('a_home')

    # ---- B. Ngủ: bắt đầu và kết thúc
    g.tap('Ngủ', exact=False, wait=1800)
    check('B1 mở màn Giấc ngủ', g.has('Ghi giấc ngủ'))
    g.tap('Ngủ ngay', wait=1500)
    check('B2 đang ngủ thì hiện nút "Bé dậy rồi"', g.wait('Bé dậy rồi', 4), g.uniq(10))
    g.tap('Bé dậy rồi', wait=1500)
    check('B3 bấm dậy thì hết trạng thái ngủ', not g.has('Bé dậy rồi'))
    back(g)

    # ---- C. Tã
    g.tap('Phân & tã', wait=1800)
    check('C1 mở màn Phân của bé', g.has('Phân của bé'))
    g.tap('Xanh rêu', exact=False); g.tap('Nhiều', exact=False)
    g.tap('Lưu cữ thay tã', wait=2000)
    # lưu xong màn tự đóng (hoặc hiện hộp xác nhận); đóng nếu còn
    g.tap('Xong', wait=800)
    check('C2 lưu tã xong rời khỏi màn nhập', not g.has('Lưu cữ thay tã'), g.uniq(8))
    if g.has('Quay lại'):
        back(g)

    # ---- D. Bình sữa
    g.tap('Ghi bú', wait=1800)
    check('D1 mở màn Ghi bú', g.has('Ghi bú'))
    for _ in range(4):
        g.tap('Tăng 5ml')
    check('D2 chỉnh lượng 20 → 40ml', g.has('Bé uống 40 ml'), [l for l in g.uniq(40) if 'uống' in l])
    g.tap('Lưu · 40ml', wait=2000)
    check('D3 lưu bình sữa hiện xác nhận "Đã ghi 40ml"', g.has('Đã ghi 40ml'), g.uniq(8))
    g.tap('Xong', wait=1200)
    if g.has('Ghi bú'):
        back(g)

    # ---- E. Lịch sử có đủ ba bản ghi
    g.tap('Lịch sử', wait=2000)
    L = ' | '.join(g.uniq(80))
    check('E1 Lịch sử có giấc ngủ', 'Ngủ' in L or 'ngủ' in L, L[:300])
    check('E2 Lịch sử có tã', 'Xanh rêu' in L or 'tã' in L.lower() or 'Tã' in L, L[:300])
    check('E3 Lịch sử có bình sữa 40ml', '40' in L, L[:300])
    g.shot('e_history')

    # ---- F. Reload: dữ liệu còn
    g.open(wait=9)
    check('F1 sau reload không bắt làm quen lại', not g.has('Chào mẹ, mình làm quen'))
    g.tap('Lịch sử', wait=2000)
    L2 = ' | '.join(g.uniq(80))
    check('F2 sau reload Lịch sử vẫn đủ dữ liệu', ('Xanh rêu' in L2 or 'Tã' in L2) and '40' in L2, L2[:300])

    # ---- G. Duyệt từng tab
    for t in TABS:
        ok = g.tap(t, exact=False, wait=2200)
        n = len(g.uniq(200))
        check('G %s mở được và có nội dung' % t, ok and n > 4, n)
        g.shot('g_' + t.replace(' ', '_'))

    # ---- H. Chế độ tối lưu qua reload
    g.tap('Trang chủ', wait=1500)
    before = g.page.screenshot()
    ok = g.tap('chế độ tối', wait=1500) or g.tap('Tối', wait=1500) or g.tap('Chế độ', wait=1500)
    check('H1 có nút đổi sáng/tối trên Trang chủ', ok)
    g.shot('h_dark')
    after = g.page.screenshot()
    check('H2 đổi chế độ làm thay đổi giao diện', before != after)
    g.open(wait=9)
    g.shot('h_dark_reload')

    # ---- I. Duyệt mọi màn qua deep link
    for key in GO:
        g.errors.clear()
        g.open('?go=' + key, wait=6)
        n = len(g.uniq(200))
        check('I go=%s mở được, không lỗi console' % key, n > 3 and not g.errors, (n, g.errors[:2]))

    # ---- J. Ngoại tuyến
    g.open(wait=10)
    g.page.wait_for_timeout(20000)  # cho service worker tải xong tài nguyên
    g.ctx.set_offline(True)
    try:
        g.open(wait=10)
        off = g.has('Hút sữa') or g.has('Lịch sử') or g.has('Trang chủ')
    except Exception as e:
        off = False
        print('offline err', str(e)[:120])
    check('J1 tắt mạng rồi mở lại app vẫn chạy', off, g.uniq(6))
    g.shot('j_offline')
    g.ctx.set_offline(False)

    check('K không có lỗi console/JS ở bước cuối', not g.errors, g.errors[:3])
    g.close()

raise SystemExit(1 if summary() else 0)
