# -*- coding: utf-8 -*-
"""Thao tác một tay cho mẹ bỉm trên bản thật: ghi nhanh 1 chạm, dòng tóm tắt, bình sữa không cần bấm Xong, vùng chạm 44."""
from playwright.sync_api import sync_playwright
from gb import GB, check, summary


def center(g, text, exact=False):
    """Tâm của phần tử khớp nhãn có diện tích nhỏ nhất (tránh nút bao ngoài cả hàng)."""
    return g.page.evaluate("""([t, exact]) => {
      let best = null;
      for (const n of document.querySelectorAll('flt-semantics')) {
        const l = (n.getAttribute('aria-label') || n.textContent || '').replace(/\s+/g, ' ').trim();
        if (!(exact ? l === t : l.includes(t))) continue;
        const b = n.getBoundingClientRect();
        if (b.width <= 0 || b.height <= 0) continue;
        if (!best || b.width * b.height < best[4]) best = [b.left + b.width / 2, b.top + b.height / 2, b.width, b.height, b.width * b.height];
      } return best; }""", [text, exact])


with sync_playwright() as p:
    g = GB(p)
    g.open(wait=10)
    g.type_in('Tên bé', 'Bé Gin'); g.tap('Bé trai')
    for _ in range(6):
        if g.has('Bắt đầu'):
            break
        g.tap('Tiếp tục')
    g.tap('Bắt đầu', wait=4000)

    # ---- dòng tóm tắt
    check('U1 Trang chủ có dòng tóm tắt nhanh', g.has('Tóm tắt nhanh'), g.uniq(6))
    check('U2 chưa ghi gì: "Bú lần cuối" báo chưa ghi', g.has('Bú lần cuối chưa ghi'), [l for l in g.uniq(10) if 'Tóm tắt' in l])
    g.shot('m_home')

    # ---- ngủ 1 chạm
    ok = g.tap('Bắt đầu ngủ ngay', wait=1200)
    check('Z1 chạm vòng tròn ở ô Ngủ bắt đầu ngủ ngay (không mở màn)', ok and g.has('Bé bắt đầu ngủ lúc') and not g.has('Ghi giấc ngủ của bé'), g.uniq(8))
    check('Z2 tóm tắt đổi thành "Đang ngủ"', g.has('Đang ngủ'), [l for l in g.uniq(10) if 'Tóm tắt' in l])
    g.shot('m_sleeping')
    g.page.wait_for_timeout(800)
    ok = g.tap('Bé dậy rồi (ghi ngay)', wait=1200)
    check('Z3 chạm lần nữa: bé dậy rồi', ok and g.has('Bé dậy rồi, ngủ'), g.uniq(8))
    check('Z4 tóm tắt đổi thành "Dậy ... trước"', g.has('Dậy') and not g.has('Đang ngủ'), [l for l in g.uniq(10) if 'Tóm tắt' in l])

    # ---- hoàn tác
    g.tap('Hoàn tác', wait=1200)
    check('Z5 Hoàn tác đưa bé về trạng thái đang ngủ', g.has('Bé dậy rồi (ghi ngay)'), g.uniq(8))
    g.tap('Bé dậy rồi (ghi ngay)', wait=1200)

    # ---- tã ướt: giữ ô Phân & tã
    c = center(g, 'Phân & tã', exact=False)
    check('D0 tìm thấy ô Phân & tã', c is not None)
    if c:
        g.page.mouse.move(c[0], c[1]); g.page.mouse.down(); g.page.wait_for_timeout(900); g.page.mouse.up(); g.page.wait_for_timeout(1200)
        check('D1 giữ ô Phân & tã ghi ngay tã ướt', g.has('Đã ghi tã ướt'), g.uniq(8))
        check('D2 tóm tắt hiện 1 lần tã', g.has('Tã hôm nay 1'), [l for l in g.uniq(10) if 'Tóm tắt' in l])

    # ---- bình sữa lượng thường gặp: lưu xong tự đóng, không hộp Xong
    g.tap('Ghi bú', wait=1800)
    saved = g.tap('Lưu · 20ml', wait=1800) or g.tap('Lưu ·', wait=1800)
    check('B1 lưu bình sữa mặc định (trong mức thường gặp) không hiện hộp "Xong"', saved and not g.has('Xong') and not g.has('Lưu ·'), g.uniq(8))
    check('B2 hiện thông báo ngắn kèm Hoàn tác', g.has('trong mức thường gặp'), g.uniq(8))
    check('B3 tóm tắt "Bú lần cuối" cập nhật', g.has('Bú lần cuối vừa xong') or g.has('Bú lần cuối 0') or g.has('phút trước'), [l for l in g.uniq(10) if 'Tóm tắt' in l])

    # ---- vùng chạm
    for label, exact in [('Chuyển sang chế độ tối', False), ('Hôm nay,', False)]:
        c = center(g, label, exact)
        check('H %s: vùng chạm ≥ 44 điểm' % label, c is not None and c[2] >= 43.5 and c[3] >= 43.5, c)
    g.open('?go=pump', wait=6)
    g.tap('Nhập tay một cữ đã hút', wait=1800)
    for label in ['Tăng Trái 5ml', 'Giảm Phải 5ml']:
        c = center(g, label)
        check('H %s: vùng chạm ≥ 44 điểm' % label, c is not None and c[2] >= 43.5 and c[3] >= 43.5, c)
    g.open('?go=feed', wait=6)
    c = center(g, 'Quay lại')
    check('H Quay lại: vùng chạm ≥ 44 điểm', c is not None and c[2] >= 43.5 and c[3] >= 43.5, c)

    check('Z không có lỗi console/JS', not g.errors, g.errors[:3])
    g.close()

raise SystemExit(1 if summary() else 0)
