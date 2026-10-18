# -*- coding: utf-8 -*-
"""Đợt góp ý trên bản thật: thứ tự Trang chủ, nút ghi nhanh, lịch + việc cần làm, nhiều bé, mục tiêu quỹ, nhịp EASY."""
from playwright.sync_api import sync_playwright
from gb import GB, check, summary


def order_on_scroll(g, labels, steps=14):
    """Cuộn Trang chủ từng đoạn, ghi thứ tự lần đầu mỗi nhãn xuất hiện."""
    seen = []
    for _ in range(steps):
        for lab in labels:
            if lab not in seen and g.has(lab):
                seen.append(lab)
        g.page.mouse.move(195, 400)
        g.page.mouse.wheel(0, 450)
        g.page.wait_for_timeout(450)
    return seen


with sync_playwright() as p:
    g = GB(p)
    g.open(wait=10)
    g.tap('Xem thử với dữ liệu mẫu', wait=6000)

    # ---- 1. Trang chủ
    check('H1 ba ô lớn: Hút sữa, Ghi bú, Ngủ (không còn Cho bú/Bình sữa riêng)', g.has('Ghi bú') and g.has('Hút sữa') and not g.has('Bình sữa Bình sữa'), g.uniq(14))
    seen = order_on_scroll(g, ['Tổng quan hôm nay', 'Hoạt động hôm nay', 'Cữ bú gần nhất', 'Cữ hút gần nhất', 'Giấc ngủ hôm nay'])
    check('H2 thứ tự khối: Tổng quan → Hoạt động → Cữ bú/hút gần nhất → Giấc ngủ hôm nay', seen == ['Tổng quan hôm nay', 'Hoạt động hôm nay', 'Cữ bú gần nhất', 'Cữ hút gần nhất', 'Giấc ngủ hôm nay'], seen)
    g.open('?go=tab0', wait=7)
    check('H3 Tổng quan có "Thời gian ngủ"', g.has('Thời gian ngủ') or any('Thời gian ngủ' in l for l in g.labels()))

    # ---- 7. Nút ghi nhanh
    g.open('?go=tab0', wait=7)
    ok = g.tap('Ghi nhanh', exact=False, wait=1500)
    labs = g.uniq(40)
    check('Q1 nút + ghi nhanh mở bảng', ok and g.has('Chạm để ghi ngay'), labs[:10])
    check('Q2 bảng ghi nhanh có đủ việc hay làm', all(g.has(t) for t in ['Ghi bú', 'Hút sữa', 'Tã ướt', 'Nhiệt độ', 'Thuốc', 'Ghi chú', 'Chi tiêu']), labs)
    g.shot('f_quick')
    g.tap('Tã ướt', wait=1500)
    check('Q3 chạm "Tã ướt" ghi ngay (có thông báo)', g.has('Đã ghi tã ướt'), g.uniq(8))

    # ---- 4. Lịch tháng và việc cần làm
    g.open('?go=tab1', wait=7)
    g.tap('Lịch tháng', wait=1800)
    check('C1 biểu tượng lịch mở lịch tháng', g.has('Thêm việc') and g.has('Việc cần làm'), g.uniq(12))
    g.tap('Thêm việc', wait=2500)
    print('   DBG inputs', g.inputs(), [l for l in g.uniq(100) if 'Lưu' in l][:3])
    ok = g.type_in('Việc cần làm', 'Đi khám nhi định kỳ')
    check('C2 gõ được tên việc', ok)
    g.tap('Lưu', wait=1800)
    check('C3 việc mới hiện trong danh sách của ngày', g.has('Đi khám nhi định kỳ'), g.uniq(30))
    g.shot('f_calendar')
    g.open('?go=calendar', wait=7) if False else None
    g.open('?go=tab1', wait=7)
    g.tap('Lịch tháng', wait=1800)
    check('C4 sau reload việc vẫn còn (ngày hôm nay)', g.has('Đi khám nhi định kỳ'), g.uniq(30))
    g.tap('Đánh dấu đã xong', wait=1000)
    check('C5 đánh dấu xong đổi nút thành "Bỏ đánh dấu xong"', g.has('Bỏ đánh dấu xong'))

    # ---- 3. Mục tiêu quỹ
    g.open('?go=tab3', wait=7)
    g.tap('Quỹ của con', wait=1800)
    check('F1 thẻ "Mục tiêu quỹ" có hai mục tiêu mẫu', g.has('Mục tiêu quỹ') and g.has('Học phí lớp 1') and g.has('Du học'), g.uniq(30))
    g.tap('+ Thêm mục tiêu', wait=1500)
    g.type_in('Tên mục tiêu', 'Mua nhà')
    g.type_in('Số tiền đích', '2ty')
    g.tap('Lưu', wait=1500)
    check('F2 thêm mục tiêu mới hiện trong danh sách', g.has('Mua nhà'), g.uniq(30))
    g.open('?go=tab3', wait=7); g.tap('Quỹ của con', wait=1800)
    check('F3 mục tiêu còn sau reload', g.has('Mua nhà') and g.has('Học phí lớp 1'), g.uniq(30))
    g.tap('Mã hàng') if False else None
    g.open('?go=moneyadd', wait=6)
    check('F4 màn Thêm khoản chi không còn ô "Mã hàng"', 'Mã hàng / SKU / mã vạch' not in str(g.inputs()), g.inputs())

    # ---- 2. Nhịp EASY
    g.open('?go=easy', wait=7)
    g.page.mouse.move(195, 400)
    for _ in range(10):
        g.page.mouse.wheel(0, 500)
        g.page.wait_for_timeout(300)
    if g.has('Tự chọn theo tuổi'):
        g.tap('Tự chọn theo tuổi', wait=800)
    g.tap('E2.5', wait=1000)
    for _ in range(10):
        g.page.mouse.wheel(0, -500)
        g.page.wait_for_timeout(150)
    a = ' | '.join(g.uniq(80))
    for _ in range(10):
        g.page.mouse.wheel(0, 500)
        g.page.wait_for_timeout(150)
    g.tap('E4', wait=1200)
    for _ in range(10):
        g.page.mouse.wheel(0, -500)
        g.page.wait_for_timeout(150)
    b = ' | '.join(g.uniq(80))
    check('E1 đổi nhịp E2.5 → E4 làm đổi lịch gợi ý và thời gian thức', a != b and 'E4' in b, (a[:150], b[:150]))
    check('E2 E4 có 3 cữ ngủ ngày, E2.5 có 5 cữ', '3 cữ' in b and '5 cữ' in a, (a[:200], b[:200]))

    # ---- 9, 10. Bước 5 ml và bỏ "Hai bên"
    g.open('?go=pump', wait=6)
    g.tap('Nhập tay một cữ đã hút', wait=1800)
    check('S1 màn Hút sữa: nút ± đổi 5 ml', g.has('Tăng Trái 5ml') and g.has('Giảm Phải 5ml'))
    g.open('?go=feed', wait=6)
    g.tap('Bú mẹ trực tiếp', wait=1200)
    check('S2 bú mẹ trực tiếp không còn "Hai bên"', not g.has('Hai bên') and g.has('Trái') and g.has('Phải'), g.uniq(14))

    # ---- 11. Tiện ích không trùng
    g.open('?go=tab5', wait=7)
    nhiet = [l for l in g.uniq(120) if l.startswith('Nhiệt độ')]
    check('U1 Tiện ích chỉ có một mục "Nhiệt độ"', len(nhiet) <= 1, nhiet)

    check('Z không có lỗi console/JS', not g.errors, g.errors[:3])
    g.close()

raise SystemExit(1 if summary() else 0)
