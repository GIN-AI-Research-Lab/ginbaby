# -*- coding: utf-8 -*-
"""Kiểm thử lưu bền: ghi nhiều loại dữ liệu, reload, xác nhận còn. Cũng kiểm tra lỗi thông báo Hoàn tác đè màn."""
from playwright.sync_api import sync_playwright
from gb import GB, check, summary


def dismiss(g):
    g.tap('Xong', wait=700)


with sync_playwright() as p:
    g = GB(p)
    g.open(wait=10)
    g.type_in('Tên bé', 'Bé Gin'); g.tap('Bé trai')
    for _ in range(6):
        if g.has('Bắt đầu'):
            break
        g.tap('Tiếp tục')
    g.tap('Bắt đầu', wait=4000)

    # --- ngủ rồi sang ngay màn tã: giấc ngủ không được mở lại
    g.tap('Ngủ', wait=1800); g.tap('Ngủ ngay', wait=1500); g.tap('Bé dậy rồi', wait=1200)
    g.tap('Quay lại', wait=1000)
    g.tap('Phân & tã', wait=1500)
    check('R1 thông báo Hoàn tác không đè lên màn tã', not g.has('Hoàn tác'), g.uniq(6))
    g.tap('Xanh rêu'); g.tap('Nhiều'); g.tap('Lưu cữ thay tã', wait=2000); dismiss(g)
    check('R2 sau khi lưu tã, bé vẫn đã dậy (ô Ngủ, không phải Dậy rồi)', not g.has('Dậy rồi'), [l for l in g.uniq(40) if 'Ngủ' in l or 'Dậy' in l])

    # --- hút sữa
    g.tap('Hút sữa', wait=1800)
    g.tap('Bắt đầu hút', wait=1200)
    g.tap('Kết thúc và nhập lượng sữa', wait=2200)
    check('P0 bấm Kết thúc thì hiện ngay hộp nhập số ml', g.has('Lượng sữa đã hút'), g.uniq(12))
    g.tap('20+20', wait=600)
    check('P1 chọn nhanh 20+20 được tổng 40ml', g.has('Lưu · 40ml'), [l for l in g.uniq(60) if 'Lưu' in l])
    g.tap('Lưu · 40ml', wait=2200); dismiss(g)
    check('P2 lưu xong tự đóng màn Hút sữa', not g.has('Lượng sữa đã hút') and not g.has('Bắt đầu hút'), g.uniq(8))

    # --- ghi nhanh: nhiệt độ, thuốc, ghi chú
    g.tap('Nhiệt độ', wait=1500)
    g.tap('Tăng 0,1°C'); g.tap('Tăng 0,1°C')
    check('T1 nhiệt độ chỉnh lên 37,0°C', g.has('37,0°C'), [l for l in g.uniq(30) if '°C' in l])
    g.tap('Lưu', wait=1500)
    check('T2 lưu nhiệt độ đóng hộp ghi nhanh', not g.has('Ghi nhanh khác'), g.uniq(6))

    g.tap('Thuốc', wait=1500)
    ok_med = g.type_in('Tên thuốc', 'Vitamin D') or g.type_in('Thuốc', 'Vitamin D')
    g.tap('Lưu', wait=1500)
    check('T3 lưu thuốc đóng hộp ghi nhanh', not g.has('Ghi nhanh khác'), (ok_med, g.uniq(8)))

    g.tap('Ghi chú', wait=1500)
    ok_note = g.type_in('Ghi chú', 'Bé ngủ ngon') or g.type_in('Nội dung', 'Bé ngủ ngon')
    g.tap('Lưu', wait=1500)
    check('T4 lưu ghi chú đóng hộp ghi nhanh', not g.has('Ghi nhanh khác'), (ok_note, g.uniq(8)))

    # --- lịch sử trước và sau reload
    def hist():
        g.tap('Lịch sử', wait=2000)
        return ' | '.join(g.uniq(120))

    h1 = hist()
    for key, label in [('phân', 'tã'), ('Hút', 'hút'), ('37', 'nhiệt'), ('Vitamin', 'thuốc'), ('ngon', 'ghi chú'), ('Ngủ', 'ngủ')]:
        check('S1 Lịch sử trước reload có %s' % label, key in h1 or key.lower() in h1.lower(), h1[:200] if key not in h1 else '')
    g.open(wait=9)
    h2 = hist()
    for key, label in [('phân', 'tã'), ('Hút', 'hút'), ('37', 'nhiệt'), ('Vitamin', 'thuốc'), ('ngon', 'ghi chú'), ('Ngủ', 'ngủ')]:
        check('S2 sau reload Lịch sử còn %s' % label, key in h2 or key.lower() in h2.lower(), h2[:200] if key not in h2 else '')
    g.shot('d_history_after_reload')
    check('S3 không lỗi console/JS', not g.errors, g.errors[:3])
    g.close()

raise SystemExit(1 if summary() else 0)
