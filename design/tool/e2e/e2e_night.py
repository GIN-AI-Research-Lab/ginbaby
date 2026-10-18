# -*- coding: utf-8 -*-
"""Chế độ giao diện "Theo giờ" trên bản thật, dùng đồng hồ giả: 19:58 sáng → 20:01 tối → 06:01 sáng lại."""
import io
from datetime import datetime
from PIL import Image
from playwright.sync_api import sync_playwright
from gb import GB, check, summary


def bright(g):
    im = Image.open(io.BytesIO(g.page.screenshot())).convert('RGB')
    r, gg, b = im.getpixel((12, 330))
    return (r + gg + b) / 3


with sync_playwright() as p:
    g = GB(p)
    g.page.clock.install(time=datetime(2026, 10, 9, 19, 58, 0))
    g.open(wait=10)
    g.type_in('Tên bé', 'Bé Đêm'); g.tap('Bé trai')
    for _ in range(6):
        if g.has('Bắt đầu'):
            break
        g.tap('Tiếp tục')
    g.tap('Bắt đầu', wait=4000)

    g.open('?go=settings', wait=7)
    check('N1 Cài đặt có lựa chọn "Theo giờ"', g.has('Theo giờ'))
    g.tap('Theo giờ', exact=False, wait=1500)
    check('N2 chọn Theo giờ hiện hai hàng chỉnh giờ', g.has('Giao diện tối từ') and g.has('Trở lại sáng lúc'), g.uniq(20))
    check('N3 mặc định 20h và 6h', g.has('20h') and g.has('6h'))
    b0 = bright(g)
    check('N4 lúc 19:58 giao diện còn sáng', b0 > 150, b0)
    g.shot('n_before')

    g.page.clock.run_for(3 * 60 * 1000)  # tới 20:01, mẹ vẫn đang ở màn Cài đặt
    g.page.wait_for_timeout(1500)
    b1 = bright(g)
    check('N5 tới 20:01 mà đang ở màn con thì hoãn: vẫn sáng, vẫn ở Cài đặt', b1 > 150 and g.has('Giao diện tối từ'), (b1, g.uniq(6)))

    g.tap('Quay lại', wait=1500)  # về màn chính
    g.page.clock.run_for(35 * 1000)
    g.page.wait_for_timeout(1500)
    b2 = bright(g)
    check('N6 về màn chính thì tự đổi sang tối trong tối đa 30 giây', b2 < 110, b2)
    g.shot('n_night')

    g.page.clock.fast_forward(10 * 3600 * 1000 + 30 * 1000)  # tới khoảng 06:01 hôm sau
    g.page.clock.run_for(35 * 1000)
    g.page.wait_for_timeout(1500)
    b3 = bright(g)
    check('N7 qua 6:00 sáng (đang ở màn chính) tự trở lại sáng', b3 > 150, b3)
    g.shot('n_morning')

    # lưu qua reload
    g.open('?go=settings', wait=7)
    check('N8 sau reload vẫn ở chế độ Theo giờ (hiện hàng chỉnh giờ)', g.has('Giao diện tối từ'))
    check('Z không có lỗi console/JS', not g.errors, g.errors[:3])
    g.close()

raise SystemExit(1 if summary() else 0)
