# GinBaby – Theme giao diện

Cập nhật: 2026-10-07

## Đang dùng từ 2026-10-07: **Pastel trái tim** (theo 4 màn mẫu người dùng gửi)

Thay cho Kính mờ. Nền kem hồng, thẻ trắng mềm bo tròn, tranh màu nước (mẹ bế bé, máy hút, bình sữa, mặt trăng, cầu vồng), chữ Nunito và Mali (viết tay).

| Token | Giá trị | Dùng cho |
|---|---|---|
| `bg` / `bgTop` | `#FCF1EB` / `#FBEAE6` | Nền |
| `card` | `#FFFBF9` | Thẻ |
| `title` | `#8B2F33` | Tiêu đề lớn đỏ rượu |
| `accent` / `accentDeep` | `#E5666F` / `#C0434F` | Nút chính, tab đang chọn, liên kết |
| Hút sữa | ô `#F8CFD1`, nút `#E27C80` | |
| Cho bú | ô `#FBDFC4`, nút `#E6A06D` | |
| Bình sữa | ô `#DDD5F2`, nút `#A998D8` | |
| Ngủ | ô `#D7E4D1`, nút `#7FA27B` | |

Tranh nằm trong `app/assets/art/` (cắt từ ảnh mẫu bằng `design/tool/crop.py`, ảnh gốc ở `design/ref/`). Có thể thay bằng file PNG nền trong suốt cùng tên.

## Đã dùng trước đó (v1 thử nghiệm): **H · Kính mờ** (Liquid Glass)

Hướng chính của app. Lớp kính trong mờ nổi trên nền màu mềm. Nền kem-đào, điểm nhấn cam mơ (cùng bảng màu "Kem & Mơ").

### Token (lấy từ canvas thiết kế)

| Token | Giá trị | Dùng cho |
|---|---|---|
| `bg` | `#FBEFE4` | Nền màn hình |
| `blobPeach` | `#F6B27E` | Mảng màu mờ phía sau (góc trên trái) |
| `blobLilac` | `#B9C3F2` | Mảng màu mờ phía sau (phải giữa) |
| `blobRose` | `#F8C9D0` | Mảng màu mờ phía sau (góc dưới trái) |
| `ink` | `#3B2F28` | Chữ chính |
| `inkMuted` | `#5A4A3E` | Chữ phụ (đã chỉnh đủ tương phản trên kính) |
| `accent` | `#F29E62` | Nút chính, tab đang chọn |
| `glass.fill` | trắng 45–50% | Nền thẻ kính |
| `glass.blur` | 16–22pt, tăng bão hòa 1.4 | Độ mờ phía sau |
| `glass.stroke` | trắng 75–80%, 1pt | Viền sáng của thẻ |
| `glass.highlight` | trắng 90%, viền trong phía trên | Ánh sáng cạnh trên |
| `glass.shadow` | nâu 12–14%, mờ 24pt, lệch 8pt | Bóng nổi |
| Màu loại ghi | Bú `#F29E62` · Ngủ `#8E9AD8` · Tã `#9DB36B` · Hút `#E58F96` · Công thức `#8E9AD8` | Chấm màu, biểu đồ |
| Chữ | Tiêu đề/số: Baloo 2 (hoặc SF Rounded) · Nội dung: Be Vietnam Pro (hoặc SF) | |

### Quy tắc dùng kính (để không lag, không khó đọc)

1. Kính chỉ cho **thẻ nổi, thanh tab, sheet**. Màn nhiều số liệu (Tổng quan, Nhật ký) dùng nền phẳng, kính chỉ ở chrome.
2. Chữ trên kính dùng `ink` đậm, luôn kiểm tra tương phản ≥ 4.5:1 (số lớn ≥ 3:1).
3. iOS 26+: dùng API Liquid Glass gốc (`glassEffect`, `GlassEffectContainer`). iOS 17–25: dự phòng bằng `Material` (`.ultraThinMaterial`) + viền trắng.
4. Bật "Giảm trong suốt" / "Giảm chuyển động" của iOS thì chuyển sang nền đặc, tắt hiệu ứng sóng.
5. Số lớp kính chồng nhau ≤ 2 trên một màn; tránh blur toàn màn hình khi cuộn.
### Mức hỗ trợ kính mờ theo nền tảng (3 bậc)

| Bậc | Máy | Cách làm | Ghi chú |
|---|---|---|---|
| A | iOS 26+ | Kính gốc (Liquid Glass) | Đẹp nhất, hệ điều hành lo hiệu năng |
| B | iOS 17–25 | Làm mờ phía sau (`Material` / blur) + viền trắng + sáng cạnh trên | Giống kính, không có khúc xạ |
| C | Android; máy yếu; bật "Giảm trong suốt" | Nền trắng mờ đặc (không blur) + viền sáng + bóng nhẹ | Giữ đúng bố cục và màu, không tốn GPU |

Mẹo hiệu năng: nền phía sau là **mảng màu tĩnh**, nên có thể dùng **ảnh nền đã làm mờ sẵn** cắt theo vị trí thẻ thay vì blur trực tiếp mỗi khung hình (rẻ hơn nhiều, nhìn gần như y hệt). Chỉ blur thật khi phía sau là nội dung đang chuyển động. Tự giảm bậc khi phát hiện rớt khung hình.

6. Chế độ tối: cần hướng riêng (nền tím mận/nâu tối + kính phát sáng nhẹ). **Chưa thiết kế.** Tham khảo D "Đêm Sữa".

## Theme lưu lại làm lựa chọn sau

Xem trong canvas thiết kế (artboard `Directions` … `Directions6`): https://claude.ai/artifact/FnxEswdSoi2EDjcdFTffc2

| Mã | Tên | Bảng | Ý chính | Có thể dùng làm |
|---|---|---|---|---|
| A | Kem & Mơ | Directions | Be kem, cam mơ, nâu cà phê | Bảng màu nền của app (đã dùng) |
| B | Yến mạch & Rêu | Directions | Be yến mạch, xanh rêu | Theme tùy chọn |
| C | Hồng đất sét | Directions | Hồng phấn pha be | Theme tùy chọn (giống KK Mẹ Mới) |
| D | Đêm Sữa | Directions2 | Nền tối ấm, cam mơ | **Gốc cho chế độ tối** |
| E | Mây & Bông | Directions2 | Xanh trời nhạt, trắng sữa | Theme tùy chọn |
| F | Mật Ong & Dâu | Directions2 | Sticker, viền đậm, bóng cứng | Thẻ chia sẻ |
| G | iOS chuẩn | Directions3 | Danh sách nhóm, tab chuẩn Apple | Khung điều hướng, màn cài đặt |
| **H** | **Kính mờ** | Directions3 | **Liquid Glass** | **ĐÃ CHỌN** |
| I | Sổ tay | Directions3 | Giấy kraft, chữ viết tay | Onboarding, thẻ chia sẻ |
| J | Bình minh | Directions4 | Kính trên nền cam đào–hồng–tím | Biến thể nữ tính của H |
| K | Ngọc trai | Directions4 | Trắng ngọc, vàng hồng, chữ có chân | Theme Premium |
| L | Kẹo mềm | Directions4 | Khối phồng mềm 3D | Thẻ nhỏ, sticker |
| M | Bento | Directions5 | Lưới ô nhiều cỡ | Bố cục màn Hôm nay |
| N | Ảnh bé làm nền | Directions5 | Ảnh bé trên thẻ chính | Thẻ chính, thẻ chia sẻ |
| O | Mascot Gin | Directions5 | Nhân vật đồng hành | Màn trống, onboarding, sticker |
| P | Chữ lớn | Directions6 | Chữ khổng lồ kiểu Thụy Sĩ | Thẻ số liệu |
| Q | Vòng hoạt động | Directions6 | Vòng lồng nhau, nền tối | Màn Tổng quan, widget |
| R | Màn theo trạng thái | Directions6 | Cả màn đổi màu theo việc của bé | Màn bé đang ngủ/đang bú |

Ý tưởng ghép với H khi làm: Bento (M) cho bố cục Hôm nay · Màn theo trạng thái (R) khi bé đang ngủ · Vòng hoạt động (Q) ở Tổng quan · Ảnh bé (N) và mascot (O) ở thẻ chia sẻ.
