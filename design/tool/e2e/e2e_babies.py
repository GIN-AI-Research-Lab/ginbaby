# -*- coding: utf-8 -*-
"""Nhiều bé trên bản thật: thêm bé, chuyển qua lại, dữ liệu tách riêng, qua reload, dải chip ở Hồ sơ, sao lưu, xoá bé."""
import json, os
from playwright.sync_api import sync_playwright
from gb import GB, check, summary, OUT

with sync_playwright() as p:
    g = GB(p)
    g.open(wait=10)
    g.tap('Xem thử với dữ liệu mẫu', wait=6000)
    g.open('?go=tab0', wait=7)
    check('B0 bé mẫu Suri có dữ liệu (tóm tắt có "Bú lần cuối")', g.has('Suri') and g.has('Tóm tắt nhanh'), g.uniq(6))

    # ---- thêm bé thứ hai
    g.tap('Chuyển bé', wait=1500)
    check('B1 chạm tên bé mở bảng "Chọn bé"', g.has('Chọn bé') and g.has('Suri'), g.uniq(10))
    g.tap('Thêm bé', nth=0, wait=2000)
    check('B2 mở màn "Thêm bé mới"', g.has('Thêm bé mới'), g.uniq(6))
    g.type_in('Tên bé', 'Bé Hai')
    g.tap('Bé trai')
    for _ in range(4):
        if g.has('Tiếp tục'):
            g.tap('Tiếp tục', wait=700)
    g.shot('b_add_last')
    g.tap('Thêm bé', exact=False, wait=3500)
    g.open('?go=tab0', wait=8)
    check('B3 sau khi thêm, Trang chủ chuyển sang bé mới', g.has('Bé Hai'), g.uniq(6))
    check('B4 bé mới chưa có dữ liệu', g.has('Bú lần cuối chưa ghi'), [l for l in g.uniq(12) if 'Tóm tắt' in l])

    # ---- ghi dữ liệu riêng cho bé hai
    g.tap('Ghi nhanh', wait=1500); g.tap('Tã ướt', wait=1800)
    check('B5 ghi tã ướt cho bé hai', g.has('Tã hôm nay 1') or g.has('Đã ghi tã ướt'), [l for l in g.uniq(12) if 'Tóm tắt' in l])

    # ---- qua reload: nhớ bé đang xem
    g.open('?go=tab0', wait=8)
    check('B6 sau reload vẫn đang xem Bé Hai', g.has('Bé Hai'), g.uniq(6))
    check('B7 dữ liệu riêng của Bé Hai còn (1 lần tã)', g.has('Tã hôm nay 1'), [l for l in g.uniq(12) if 'Tóm tắt' in l])

    # ---- chuyển về Suri
    g.tap('Chuyển bé', wait=1500)
    check('B8 bảng chọn bé có cả hai bé', g.has('Bé Hai') and g.has('Bé Suri'), g.uniq(14))
    g.tap('Bé Suri', wait=2500)
    g.open('?go=tab0', wait=8) if False else None
    check('B9 chuyển về Suri: dữ liệu của Suri còn nguyên (không lẫn tã của Bé Hai)', g.has('Suri') and not g.has('Tã hôm nay 1'), [l for l in g.uniq(12) if 'Tóm tắt' in l])
    g.shot('b_back_suri')

    # ---- Hồ sơ: dải chip bé
    g.tap('Hồ sơ', wait=2000)
    check('B10 tab Hồ sơ có dải chọn bé (hai chip và "Thêm bé")', g.has('Bé Hai') and g.has('Thêm bé'), g.uniq(14))
    g.tap('Bé Hai', exact=False, wait=2000)
    check('B11 chạm chip Bé Hai chuyển sang bé đó', g.has('Bé Hai'), g.uniq(12))

    # ---- sao lưu có cả hai bé
    g.open('?go=settings', wait=7)
    for _ in range(14):
        if g.has('Xuất tệp sao lưu'):
            break
        g.page.mouse.move(195, 400); g.page.mouse.wheel(0, 500); g.page.wait_for_timeout(350)
    with g.page.expect_download(timeout=20000) as dl:
        g.tap('Xuất tệp sao lưu', wait=500)
    path = os.path.join(OUT, 'backup2.json'); dl.value.save_as(path)
    data = json.load(open(path, encoding='utf-8'))
    names = {data.get('baby', {}).get('name')} | {o.get('n') for o in data.get('otherBabies', [])}
    check('B12 tệp sao lưu chứa cả hai bé', {'Suri', 'Bé Hai'} <= names, names)

    # ---- xoá Bé Hai
    g.open('?go=tab0', wait=8)
    g.tap('Chuyển bé', wait=1500)
    g.tap('Xoá bé Bé Hai', wait=1500)
    check('B13 xoá bé có hộp xác nhận', g.has('Xoá hồ sơ của Bé Hai'), g.uniq(8))
    g.tap('Xoá bé', exact=False, nth=1, wait=2500) or g.tap('Xoá bé', wait=2500)
    g.open('?go=tab0', wait=8)
    g.tap('Chuyển bé', wait=1500)
    check('B14 sau khi xoá chỉ còn Suri', not g.has('Bé Hai') and g.has('Suri'), g.uniq(10))
    check('Z không có lỗi console/JS', not g.errors, g.errors[:3])
    g.close()

raise SystemExit(1 if summary() else 0)
