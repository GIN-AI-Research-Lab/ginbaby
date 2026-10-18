# -*- coding: utf-8 -*-
"""Sao lưu / xoá sạch / khôi phục, CSV và báo cáo bác sĩ trên bản thật."""
import json, os
from playwright.sync_api import sync_playwright
from gb import GB, check, summary, OUT

NOTE = 'Sao luu thu nghiem 123'


def scroll_to(g, label, tries=14):
    for _ in range(tries):
        if g.has(label):
            return True
        g.page.mouse.move(195, 500)
        g.page.mouse.wheel(0, 500)
        g.page.wait_for_timeout(400)
    return g.has(label)


def onboard(g, name):
    g.type_in('Tên bé', name); g.tap('Bé trai')
    for _ in range(6):
        if g.has('Bắt đầu'):
            break
        g.tap('Tiếp tục')
    g.tap('Bắt đầu', wait=4000)


with sync_playwright() as p:
    g = GB(p)
    g.ctx.grant_permissions([])
    g.open(wait=10)
    onboard(g, 'Bé Backup')

    # ghi hai bản ghi
    g.tap('Ghi chú', wait=1500)
    g.type_in('Ghi chú', NOTE) or g.type_in('Nội dung', NOTE)
    g.tap('Lưu', wait=1500)
    g.tap('Nhiệt độ', wait=1500); g.tap('Lưu', wait=1500)

    # ---- xuất sao lưu
    g.open('?go=settings', wait=7)
    check('B0 tìm thấy nút xuất sao lưu', scroll_to(g, 'Xuất tệp sao lưu'))
    with g.page.expect_download(timeout=20000) as dl:
        g.tap('Xuất tệp sao lưu', wait=500)
    path = os.path.join(OUT, 'backup.json')
    dl.value.save_as(path)
    data = json.load(open(path, encoding='utf-8'))
    blob = json.dumps(data, ensure_ascii=False)
    check('B1 tệp sao lưu tải về là JSON hợp lệ', isinstance(data, dict) and len(blob) > 100, list(data)[:8])
    check('B2 tệp sao lưu chứa ghi chú và tên bé', NOTE in blob and 'Bé Backup' in blob)

    # ---- CSV
    scroll_to(g, 'Nhật ký dạng bảng')
    with g.page.expect_download(timeout=20000) as dl2:
        g.tap('Nhật ký dạng bảng', wait=500)
    csvp = os.path.join(OUT, 'nhat-ky.csv'); dl2.value.save_as(csvp)
    csv = open(csvp, encoding='utf-8-sig').read()
    check('B3 CSV có ghi chú và dòng tiêu đề', NOTE in csv and csv.count('\n') >= 2, csv[:150])

    # ---- báo cáo bác sĩ
    scroll_to(g, 'Báo cáo cho bác sĩ')
    with g.page.expect_download(timeout=20000) as dl3:
        g.tap('Báo cáo cho bác sĩ', wait=500)
    rp = os.path.join(OUT, 'bao-cao.html'); dl3.value.save_as(rp)
    html = open(rp, encoding='utf-8').read()
    check('B4 báo cáo bác sĩ là HTML có tên bé', '<html' in html.lower() and 'Bé Backup' in html, html[:120])

    # ---- xoá sạch
    scroll_to(g, 'Xoá toàn bộ dữ liệu')
    g.tap('Xoá toàn bộ dữ liệu', wait=1200)
    check('B5 có hộp xác nhận xoá', g.has('Xoá toàn bộ dữ liệu?'))
    print('   dialog:', g.uniq(40)[:8])
    g.tap('Xoá Xoá', exact=True, wait=3000) or g.tap('Xoá', exact=True, wait=3000)
    g.open(wait=9)
    check('B6 sau khi xoá, app quay về màn làm quen', g.has('Chào mẹ'), g.uniq(6))

    # ---- khôi phục
    onboard(g, 'Bé Tạm')
    g.open('?go=settings', wait=7)
    scroll_to(g, 'Khôi phục từ tệp')
    with g.page.expect_file_chooser(timeout=15000) as fc:
        g.tap('Khôi phục từ tệp', wait=300)
    fc.value.set_files(path)
    g.page.wait_for_timeout(1000)  # thông báo chỉ hiện 2 giây
    check('B7 hiện thông báo đã khôi phục', g.has('Đã khôi phục') or g.has('khôi phục'), g.uniq(8))
    g.open(wait=9)
    g.tap('Lịch sử', wait=2200)
    L = ' | '.join(g.uniq(100))
    check('B8 sau khôi phục, Lịch sử có lại ghi chú', 'Sao luu' in L, L[:300])
    g.tap('Hồ sơ', wait=1800)
    check('B9 tên bé trở lại là "Bé Backup"', g.has('Bé Backup'), g.uniq(10))
    check('Z không có lỗi console/JS', not g.errors, g.errors[:3])
    g.close()

raise SystemExit(1 if summary() else 0)
