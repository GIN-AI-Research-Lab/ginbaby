# -*- coding: utf-8 -*-
"""Tiếng ồn trắng, lưu ảnh thẻ (PNG), tủ sữa, sửa/xoá bản ghi, thêm ảnh vào bản ghi."""
import os
from PIL import Image
from playwright.sync_api import sync_playwright
from gb import GB, check, summary, OUT

with sync_playwright() as p:
    g = GB(p)
    g.open(wait=10)
    g.type_in('Tên bé', 'Bé Gin'); g.tap('Bé trai')
    for _ in range(6):
        if g.has('Bắt đầu'):
            break
        g.tap('Tiếp tục')
    g.tap('Bắt đầu', wait=4000)

    # ---- Tiếng ồn trắng
    g.open('?go=noise', wait=6)
    before = [l for l in g.uniq(60) if 'phát' in l.lower()]
    g.tap('Mưa', exact=False, nth=0, wait=1500)
    mid = [l for l in g.uniq(60) if 'phát' in l.lower() or 'Dừng' in l]
    check('N1 chọn âm thì trạng thái đổi (đang phát)', mid != before, (before, mid))
    g.tap('15 phút', exact=False, wait=800)
    g.tap('Dừng', exact=False, wait=1000)
    check('N2 không lỗi khi phát và dừng', not g.errors, g.errors[:2])

    # ---- Lưu ảnh thẻ: nhánh chia sẻ (iPhone/Android) và nhánh tải xuống (không có Web Share)
    SHARE = """() => { window.__shared = null;
      navigator.canShare = () => true;
      navigator.share = async (d) => { const f = d.files && d.files[0]; window.__shared = f ? [f.name, f.type, f.size] : 'no-file'; }; }"""
    NOSHARE = "() => { try { Object.defineProperty(navigator, 'share', {value: undefined, configurable: true}); Object.defineProperty(navigator, 'canShare', {value: undefined, configurable: true}); } catch (e) {} }"
    for go, name in [('recap', 'recap'), ('memcard', 'memcard')]:
        g.open('?go=' + go, wait=7)
        g.page.evaluate(SHARE)
        g.tap('Lưu ảnh', wait=3500)
        sh = g.page.evaluate('window.__shared')
        check('C %s: chia sẻ nhận được tệp PNG' % name, isinstance(sh, list) and sh[1] == 'image/png' and sh[2] > 5000, sh)
        g.page.evaluate(NOSHARE)
        try:
            with g.page.expect_download(timeout=20000) as dl:
                g.tap('Lưu ảnh', wait=300)
            path = os.path.join(OUT, name + '.png'); dl.value.save_as(path)
            im = Image.open(path)
            check('C %s: không có Web Share thì tải được PNG' % name, im.format == 'PNG' and im.width >= 600, (im.format, im.size))
        except Exception as e:
            check('C %s: tải dự phòng' % name, False, str(e)[:120])

    # ---- Tủ sữa: lưu một bình
    g.open('?go=milk', wait=6)
    g.tap('Tủ sữa', exact=True, wait=1500)
    g.tap('Thêm bình sữa', wait=1800)
    for _ in range(4):
        g.tap('Tăng 5ml')
    g.tap('Lưu bình', wait=2000)
    L = ' | '.join(g.uniq(60))
    check('F1 tủ sữa có 1 bình sau khi lưu', '1 bình' in L, L[:300])
    check('F2 tổng ml tủ sữa cập nhật (140 ml)', '140' in L, L[:300])
    g.open('?go=milk', wait=7); g.tap('Tủ sữa', exact=True, wait=1500)
    L = ' | '.join(g.uniq(60))
    check('F3 bình sữa còn sau reload', '1 bình' in L, L[:300])

    # ---- Ghi chú rồi sửa / xoá trong Lịch sử
    g.open(wait=8)
    g.tap('Ghi chú', wait=1500)
    g.type_in('Ghi chú', 'Ghi chu de xoa')
    g.tap('Lưu', wait=1500)
    g.tap('Lịch sử', wait=2200)
    L = g.uniq(100)
    row = next((l for l in L if 'Ghi chu de xoa' in l), None)
    check('H1 ghi chú hiện trong Lịch sử', row is not None, L[:12])
    if row:
        g.tap('Ghi chu de xoa', wait=1500)
        sheet = g.uniq(40)
        print('   chi tiết:', sheet[:14])
        check('H2 chạm vào bản ghi mở chi tiết có Sửa/Xoá', any('Xoá' in l for l in sheet) or any('Sửa' in l for l in sheet), sheet[:14])
        g.tap('Xoá', wait=1200)
        if g.has('Xoá Xoá') or any(l == 'Xoá' for l in g.uniq(40)):
            g.tap('Xoá Xoá', exact=True, wait=1500) or g.tap('Xoá', exact=True, wait=1500)
        g.tap('Xong', wait=600)
        g.open(wait=8); g.tap('Lịch sử', wait=2200)
        check('H3 bản ghi đã xoá không còn sau reload', not g.has('Ghi chu de xoa'), g.uniq(10))

    # ---- Thêm ảnh vào cữ tã (chọn tệp thật)
    png = os.path.join(OUT, 'test-photo.png')
    Image.new('RGB', (300, 200), (200, 120, 90)).save(png)
    g.open('?go=diaper', wait=6)
    g.tap('thêm ảnh', exact=False, wait=1200)
    inside = g.uniq(60)
    btn = next((l for l in inside if 'Thêm ảnh' in l or 'Chụp' in l or 'Chọn ảnh' in l), None)
    check('P0 mục thêm ảnh có nút chọn ảnh', btn is not None, inside[-8:])
    if btn:
        try:
            g.tap(btn, wait=900)
            check('P0b nút Thêm ảnh hiện menu Thư viện/Chụp ảnh ngay bên dưới', g.has('Thư viện ảnh') and g.has('Chụp ảnh'), g.uniq(12))
            with g.page.expect_file_chooser(timeout=8000) as fc:
                g.tap('Thư viện ảnh', wait=300)
            fc.value.set_files(png)
            g.page.wait_for_timeout(2500)
            check('P1 chọn ảnh xong không lỗi', not g.errors, g.errors[:2])
            g.tap('Lưu cữ thay tã', wait=2500); g.tap('Xong', wait=500)
            g.open('?go=diaper', wait=7)
            L = ' | '.join(g.uniq(80))
            check('P2 cữ tã có ảnh vẫn hiện sau reload', 'Chưa có lần thay tã nào' not in L, L[:200])
            g.shot('x_photo_diaper')
        except Exception as e:
            check('P1 chọn ảnh', False, str(e)[:150])

    check('Z không có lỗi console/JS', not g.errors, g.errors[:3])
    g.close()

raise SystemExit(1 if summary() else 0)
