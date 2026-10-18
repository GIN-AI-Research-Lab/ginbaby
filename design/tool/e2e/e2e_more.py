# -*- coding: utf-8 -*-
"""Kiểm thử đầu-cuối nhóm còn lại: Tiền, Quỹ, Tăng trưởng, Tiêm chủng, Cài đặt (lưu qua reload)."""
from playwright.sync_api import sync_playwright
from gb import GB, check, summary

with sync_playwright() as p:
    g = GB(p)
    g.open(wait=10)
    g.type_in('Tên bé', 'Bé Gin'); g.tap('Bé trai')
    for _ in range(6):
        if g.has('Bắt đầu'):
            break
        g.tap('Tiếp tục')
    g.tap('Bắt đầu', wait=4000)

    # ---- Thu chi
    g.open('?go=moneyadd', wait=6)
    g.tap('+50k'); g.tap('+200k')
    g.tap('Bỉm/tã')
    g.type_in('Tên món', 'Tã Bobby')  # gõ sau cùng: trang tự cuộn xuống khi gõ nên các nút số tiền ra khỏi màn hình
    g.tap('Lưu', wait=2000)
    g.tap('Xong', wait=600)
    g.open(wait=8); g.tap('Tiền', wait=2000)
    L = ' | '.join(g.uniq(80))
    check('M1 khoản chi hiện trong tab Tiền', 'Tã Bobby' in L, L[:250])
    check('M2 tổng chi 250.000 (50k + 200k)', '250' in L, L[:250])

    # ---- Quỹ
    g.tap('Quỹ của con', wait=1500); g.tap('Thêm vào quỹ', wait=2000)
    g.type_in('Tên khoản', 'Lì xì Tết'); g.type_in('Số tiền', '2tr')
    g.tap('Lưu', wait=2500); g.tap('Xong', wait=600)
    g.open(wait=8); g.tap('Tiền', wait=1800); g.tap('Quỹ của con', wait=1800)
    Lf = ' | '.join(g.uniq(80))
    check('Q1 khoản quỹ còn sau reload', 'Lì xì Tết' in Lf, Lf[:250])
    check('Q2 quỹ hiện 1 khoản', '1 khoản trong quỹ' in Lf, Lf[:250])

    # ---- Tăng trưởng
    g.open('?go=growth', wait=6)
    g.tap('Thêm lần đo', wait=1500)
    g.type_in('Cân nặng', '3.6'); g.type_in('Chiều dài', '51'); g.type_in('Vòng đầu', '35')
    g.tap('Lưu', wait=2000); g.tap('Xong', wait=600)
    g.open('?go=growth', wait=7)
    Lg = ' | '.join(g.uniq(80))
    check('G1 lần đo cân nặng được lưu', '3,6' in Lg or '3.6' in Lg, Lg[:300])
    check('G2 mục "Các lần đo" không còn trống', 'Chưa có lần đo nào' not in Lg, Lg[:300])

    # ---- Tiêm chủng
    g.open('?go=vaccine', wait=6)
    before = [l for l in g.uniq(30) if 'Đã tiêm' in l]
    g.tap('Viêm gan B sơ sinh', wait=1500)
    g.tap('Đánh dấu đã tiêm', wait=1800)
    g.tap('Xong', wait=500)
    g.open('?go=vaccine', wait=7)
    after = [l for l in g.uniq(30) if 'Đã tiêm' in l]
    check('V1 đánh dấu đã tiêm tăng số mũi 0 → 1 và còn sau reload', before and after and 'Đã tiêm 1/' in after[0], (before, after))

    # ---- Cài đặt: chế độ tối + kính mờ giữ qua reload
    g.open('?go=settings', wait=6)
    g.tap('Tối', exact=True, wait=1200)
    g.tap('Đầy đủ', wait=1200)
    g.open('?go=settings', wait=7)
    g.shot('c_settings_after_reload')
    dark = g.page.evaluate("""() => { const c = document.createElement('canvas'); return 0 }""")
    img = g.page.screenshot()
    # nền tối: điểm ảnh ở góc trên trái có độ sáng thấp
    from PIL import Image
    import io
    im = Image.open(io.BytesIO(img)).convert('RGB')
    r, gg, b = im.getpixel((20, 200))
    check('C1 chế độ Tối giữ sau reload (nền tối)', (r + gg + b) / 3 < 110, (r, gg, b))

    check('Z không có lỗi console/JS', not g.errors, g.errors[:3])
    g.close()

raise SystemExit(1 if summary() else 0)
