# -*- coding: utf-8 -*-
"""Thao tác sâu các màn còn lại: Ăn dặm, Tủ sữa, Cẩm nang, Góc của mẹ, EPDS, Gia đình, Wonder Weeks, EASY."""
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

    # ---- Ăn dặm: ghi một bữa rồi mở lại thấy thực phẩm đã thử
    g.open('?go=solids', wait=6)
    g.tap('Ghi bữa ăn dặm', wait=1800)
    g.tap('Gạo', exact=False, nth=0); g.tap('Bí đỏ', nth=0)
    g.tap('vừa', exact=False)
    sheet = g.uniq(60)
    save = next((l for l in sheet if l.startswith('Lưu')), None)
    check('S1 hộp ghi ăn dặm có nút Lưu', save is not None, sheet[-6:])
    if save:
        g.tap(save, wait=2000)
    g.tap('Xong', wait=500)
    g.open('?go=solids', wait=7)
    L = ' | '.join(g.uniq(80))
    check('S2 sau reload bữa ăn dặm được ghi (đã thử Gạo/Bí đỏ)', 'Đã thử' in L or 'đã thử' in L or 'Gạo' in L, L[:300])

    # ---- Tủ sữa: thêm bình
    g.open('?go=milk', wait=6)
    g.tap('Tủ sữa', exact=True, wait=1500)
    check('F0 chuyển sang tab Tủ sữa', g.has('Tủ sữa của mẹ'), g.uniq(10))
    g.tap('Thêm bình sữa', wait=1800)
    sheet = g.uniq(60)
    check('F1 hộp thêm bình sữa mở ra có nút Lưu', any(l.startswith('Lưu') for l in sheet), sheet[:14])
    print('   milk sheet:', sheet[:25], g.inputs())

    # ---- Cẩm nang: tìm kiếm và mở bài
    g.open('?go=articles', wait=6)
    ok = g.type_in('Tìm trong cẩm nang', 'sữa')
    g.page.wait_for_timeout(600)
    check('A1 tìm kiếm cẩm nang gõ được', ok)
    arts = [l for l in g.uniq(80) if len(l) > 18]
    check('A2 cẩm nang hiện bài viết', len(arts) > 3, arts[:5])

    # ---- Góc của mẹ: chọn tâm trạng, lưu qua reload
    g.open('?go=mind', wait=6)
    g.tap('Mệt', exact=False, nth=0, wait=1200)
    check('M0 chọn tâm trạng mở hộp Lưu', g.has('Lưu'))
    g.tap('Lưu', wait=1800)
    g.open('?go=mind', wait=7)
    check('M1 màn Góc của mẹ mở lại bình thường sau khi chọn tâm trạng', g.has('Hôm nay mẹ thế nào'))
    g.shot('s_mind')

    # ---- EPDS: trả lời đủ 10 câu rồi ra kết quả
    g.open('?go=epds', wait=6)
    for i in range(10):
        labs = g.uniq(40)
        if 'Tự kiểm tra' not in labs:
            break
        a = labs.index('Tự kiểm tra') + 3  # sau 'Tự kiểm tra', số điểm, câu hỏi
        opts = []
        for l in labs[a:]:
            if l.startswith('Bản dịch'):
                break
            opts.append(l)
        g.tap(opts[0], exact=True, wait=300)
        g.tap('Tiếp', wait=700) or g.tap('Xem kết quả', wait=700) or g.tap('Hoàn tất', wait=700)
    res = g.uniq(40)
    check('E1 làm xong EPDS thì hiện kết quả', any('điểm' in l.lower() or 'kết quả' in l.lower() for l in res), res[:12])
    g.shot('s_epds_result')

    # ---- Gia đình
    g.open('?go=family', wait=6)
    fam = g.uniq(50)
    check('Y1 màn Gia đình hiện thành viên và mã mời', g.has('Chủ') and g.has('Mã') or g.has('Sao chép mã'), fam[:10])
    g.shot('s_family')

    # ---- Wonder Weeks và EASY
    g.open('?go=leaps', wait=6)
    check('W1 Wonder Weeks có danh sách bước nhảy', g.has('10 bước nhảy'))
    g.tap('Bước nhảy', exact=False, nth=1, wait=1200)
    g.open('?go=easy', wait=6)
    check('Y2 EASY có lịch gợi ý', g.has('Lịch gợi ý hôm nay'))

    check('Z không có lỗi console/JS', not g.errors, g.errors[:3])
    g.close()

raise SystemExit(1 if summary() else 0)
