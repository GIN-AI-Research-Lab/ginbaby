# GinBaby – ứng dụng Flutter

Giao diện **kính mờ**, dữ liệu lưu cục bộ trên máy (JSON trong bộ nhớ trình duyệt/điện thoại), không cần tài khoản.

## Đã làm (bản web chạy được)

| Tab | Chức năng |
|---|---|
| **Hôm nay** | Hồ sơ bé, nhịp EASY (dự đoán giờ ngủ, thức bao lâu), ghi nhanh bú / ngủ / phân & tã (ảnh, màu, cảnh báo) / hút sữa / nhiệt độ / thuốc / ghi chú, nhắc việc, nhật ký có sửa/xoá |
| **Sữa** | **Bú bình: vuốt mực sữa**, đánh giá theo tuổi và cân nặng (AAP, Kent 2006, tài liệu trong nước); bú mẹ trực tiếp bấm giờ; **ghi hút sữa 2 bên**, mục tiêu hút, đánh giá nhẹ nhàng; **tủ sữa** (hạn dùng CDC, dùng trước, trừ hao); thống kê tách loại |
| **Tổng quan** | Ngày · Tuần · Tháng, biểu đồ ngủ/sữa/tã, lịch tháng (ngày quấy), **thẻ tổng kết tuần xuất ảnh PNG**, màn nhịp EASY |
| **Tiền** | **Thu chi**: nhãn nhiều chọn, lọc nhiều tiêu chí, tìm kiếm, ảnh, mã hàng, số lượng × đơn giá, ngân sách tháng, thống kê theo nhãn; **Quỹ của con**: tiền/tiết kiệm/vàng/khác, người giữ, ghi chú, lịch sử, mục tiêu có hũ tiết kiệm, ẩn/hiện số tiền |
| **Cho mẹ** | **Tiêm chủng** (TCMR + dịch vụ), **tăng trưởng WHO** (cân nặng, chiều dài, vòng đầu), **ăn dặm** + theo dõi dị ứng, **cẩm nang** (13 bài có nguồn), sức khoẻ (nhiệt độ, thuốc, lịch hẹn, mốc phát triển, răng), **Góc của mẹ** (tâm trạng, EPDS, bài thở), **tiếng ồn trắng** (8 âm tạo bằng code), gia đình |
| **Cài đặt** | Sửa hồ sơ, cách ăn, hút sữa, EASY, chế độ nhẹ, sao lưu/khôi phục `.json`, dữ liệu mẫu |

Chưa làm: đồng bộ gia đình giữa các máy, nhắc giờ bằng thông báo hệ thống, widget/Live Activity/Siri (cần code iOS gốc), Hỏi Gin (AI), cộng đồng.

## Cách cập nhật bản web (người xem chỉ cần mở lại link)

```powershell
& "F:\Project Ai\GinBaby\app\tool\deploy.ps1"
```

Script build bản mới, ghi `version.json` và bảo đảm máy chủ **không-cache** (`tool/serve.py`, cổng 8090) đang chạy.
Trang đang mở sẽ **tự hiện thanh "Có bản mới. Bấm để cập nhật"** trong khoảng 30 giây; trang mở mới luôn lấy bản mới nhất.

## Chạy khi phát triển

```powershell
$env:Path = "F:\dev\flutter\bin;$env:Path"
cd "F:\Project Ai\GinBaby\app"
flutter run -d chrome     # hot reload
flutter analyze
flutter test
```

## Cấu trúc

```
lib/core     giao diện chung (kính mờ), định dạng, ảnh chụp, tự bật chế độ nhẹ khi chậm
lib/data     mô hình dữ liệu, lưu trữ (AppState), dữ liệu mẫu
lib/domain   logic thuần: tuổi, đánh giá bú/hút, EASY, WHO, tiêm chủng, mốc, EPDS, cẩm nang
lib/ui       các màn hình
test         kiểm thử logic y khoa và dữ liệu
```

## Lưu ý

- Số liệu y khoa chỉ để **tham khảo**, ghi nguồn trong app, **cần bác sĩ/chuyên gia duyệt** trước khi phát hành.
- Bản dịch EPDS tiếng Việt chưa được kiểm chứng.
- Build iOS cần Mac hoặc CI macOS (xem `../docs/ROADMAP.md`).

## Lưu trữ và liên kết nhanh

- Dữ liệu lưu bằng sembast: IndexedDB trên web, tệp trên di động. Ảnh lưu riêng theo khoá `gb1.ph.<id>`; tệp sao lưu (.json, bản 2) gồm cả ảnh và người thân.
- Trình duyệt Safari có thể xoá dữ liệu web nếu không dùng 7 ngày, nên cần xuất tệp sao lưu định kỳ (bản iOS thật sẽ không bị giới hạn này).
- Mở thẳng một màn bằng tham số `?go=`: `vaccine`, `growth`, `solids`, `articles`, `article:<id>`, `health0..4`, `mind`, `epds`, `noise`, `family`, `premium`, `settings`, `easy`, `history`, `feed`, `pump`, `moneyadd`, `recap`, `profile`, `tab0..4`. Ví dụ `http://localhost:8090/?go=vaccine`.

## Giao diện (Pastel trái tim)

- 5 tab: Trang chủ, Lịch sử, Thống kê, Tiền, Hồ sơ. Tủ sữa, tiêm chủng, tăng trưởng, ăn dặm, cẩm nang, cài đặt nằm trong Hồ sơ.
- Màu và chữ ở `lib/core/theme.dart`; thẻ, nút, tiêu đề ở `lib/core/kit.dart`; ô hoạt động, thẻ số liệu ở `lib/core/pastel.dart`.
- Tranh minh hoạ trong `assets/art/` (PNG nền trong suốt). Muốn dùng tranh khác, thay file cùng tên.

## Bổ sung gần đây

- Giấc ngủ: màn riêng (Ngủ ngay, Dậy rồi, nhập giờ ngủ và dậy, chạm nhanh thời lượng).
- Xuất báo cáo cho bác sĩ (HTML in được, lưu PDF bằng trình duyệt) và nhật ký CSV: Cài đặt > Xuất báo cáo.
- Wonder Weeks: `lib/domain/leaps.dart`, màn `leaps_screen.dart`, thẻ ở Trang chủ và ô ở Hồ sơ. Nội dung cần chuyên gia nhi duyệt.
- Phân của bé: màn `diaper_screen.dart` (màu, kết cấu, số lượng), thống kê phân theo tuần.
- Liên kết nhanh mới: `?go=sleep`, `?go=leaps`, `?go=diaper`, `?go=milk`, `?go=seed` (nạp dữ liệu mẫu).

## Kiểm thử

- `flutter test`: logic (tuổi, đánh giá sữa, WHO, Wonder Weeks, xuất báo cáo, sao lưu) và `test/screens_test.dart`.
- `screens_test.dart` dựng từng màn ở khổ 320px, cỡ chữ 100% và 125%, dùng phông thật (assets/google_fonts), kiểm tra không có tràn chữ; và chạy thử luồng Giấc ngủ, Phân của bé. Màn Tiếng ồn trắng không có trong bộ này vì cần plugin âm thanh.
- Phông Be Vietnam Pro và Plus Jakarta Sans được đóng gói trong `assets/google_fonts/` nên app không phải tải phông khi mở.

## Chế độ tối, thông báo, bộ icon

- Chế độ tối: Cài đặt > Giao diện (Theo máy / Sáng / Tối). Màu nằm trong `lib/core/theme.dart` dưới dạng getter có hai bảng màu; màu cứng dùng `GB.p()` (nền pastel), `GB.f()` (chữ đậm), `GB.w()` (nền trắng mờ). Liên kết thử nhanh: `?dark=1`, `?dark=0`.
- Thông báo trình duyệt: Cài đặt > Nhắc nhở. Chạy khi tab GinBaby còn mở (kể cả nền); logic ở `lib/core/reminders.dart`. Nhắc khi đóng hẳn app cần bản iOS.
- Bộ icon màu nước: xem `design/icons/PROMPTS.md` và `design/tool/gen_icons.py`. Thả tệp `ic_<tên>.png` vào `assets/art/` là icon tương ứng tự đổi.
