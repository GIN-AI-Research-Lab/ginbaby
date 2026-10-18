# GinBaby – Kế hoạch test UI/UX và chức năng

Mục tiêu: mỗi màn có thể **nhập, lưu, xem lại, sửa, xoá** mà không lỗi, không mất dữ liệu, không mất ảnh, và hiển thị đúng ở cả chế độ sáng và tối.

## 1. Cách test

| Lớp | Công cụ | Phạm vi |
|---|---|---|
| Tự động – logic | `flutter test` (99 test hiện có) | Logic miền, lưu và đọc dữ liệu, ảnh |
| Tự động – giao diện | Test tràn chữ 320 px × 125 % | Mọi màn chính |
| Thủ công – giả lập | Chrome iPhone 13 (script `design/tool/shots.py`) | Luồng nhập, lưu, xoá |
| Thủ công – thiết bị | iPhone thật (Safari, thêm vào Màn hình chính) | Cảm giác, cử chỉ, offline |

Mỗi mục kiểm tra có 4 bước: **Mở → Nhập → Lưu → Xem lại / Sửa / Xoá**, rồi kiểm tra ở chế độ tối.

## 2. Tiêu chí chung (áp dụng cho mọi màn)

- Lưu xong có thông báo, có nút **Hoàn tác** cho thao tác vừa làm (khi có).
- Đóng và mở lại app thì dữ liệu còn nguyên.
- Mọi bản ghi có ảnh phải **hiển thị lại được** (thumbnail ở dòng danh sách, ảnh lớn ở chi tiết).
- Ô nhập có nhãn, biểu tượng, viền rõ ở cả hai chế độ.
- Nút chính luôn nằm trong vùng bấm được (≥ 44 px), không bị thanh tab che.
- Không có chữ bị cắt ở 320 px và chữ 125 %.
- Chuyển sáng ↔ tối không làm mất màn đang mở; màu không bị "đóng băng" (lỗi đã sửa cho các bảng màu).

## 3. Kế hoạch theo màn

Ký hiệu: ✅ đã có tự động · 🔲 cần làm · ⚠️ đã biết có lỗi/nghi ngờ.

### 3.1 Trang chủ
| # | Thao tác | Kỳ vọng | Trạng thái |
|---|---|---|---|
| H1 | Bấm từng ô Hút sữa / Cho bú / Bình sữa / Ngủ | Mở đúng màn | ✅ (test giao diện: điều hướng và tab) |
| H2 | Bấm ô nhanh (Phân & tã, Nhiệt độ, Thuốc, Ghi chú) | Mở sheet đúng | ✅ (test giao diện) |
| H3 | Nhắc nhở (cữ hút, cữ bú, tiêm chủng, mốc) | Bấm nhắc → đúng màn | ✅ (test thời gian cố định: 7 ca) |
| H4 | Nút đổi sáng/tối | Đổi ngay, không mất tab | ✅ (thủ công đã kiểm) |
| H5 | Vuốt/cuộn toàn trang ở 320 px | Không tràn | ✅ |

### 3.2 Ghi bú (bình và trực tiếp)
| # | Thao tác | Kỳ vọng | Trạng thái |
|---|---|---|---|
| F1 | Kéo mực sữa trên bình | Số ml cập nhật, nút Lưu ghi đúng | ✅ (test giao diện) |
| F2 | Chọn sữa mẹ / công thức, chọn mốc nhanh | Đổi màu bình, số đúng | ✅ (test giao diện) |
| F3 | Bú trực tiếp: Bắt đầu → Dừng → Lưu | Thời lượng đúng, lưu được | ✅ (test tầng dữ liệu) |
| F4 | Lưu → Hoàn tác | Bản ghi biến mất | ✅ (test tầng dữ liệu) |
| F5 | Sửa bản ghi từ dòng Lịch sử | Sửa được ml và giờ | ✅ (test tầng dữ liệu) |
| F6 | Xoá bản ghi | Có hộp xác nhận, có X đóng | ✅ (test giao diện) |

### 3.3 Hút sữa
| # | Thao tác | Kỳ vọng | Trạng thái |
|---|---|---|---|
| P1 | Đồng hồ hai bên trái/phải, Bắt đầu/Kết thúc | Thời lượng và ml đúng | ✅ (test giao diện) |
| P2 | Nhập tay số phút | Cộng đúng | ✅ (test giao diện) |
| P3 | Lưu xong, cữ tiếp theo đổi trạng thái | Đếm cữ đúng | ✅ (test tầng dữ liệu) |
| P4 | Đặt lại | Xoá nháp, không xoá bản đã lưu | ✅ (test tầng dữ liệu) |

### 3.4 Giấc ngủ
| # | Thao tác | Kỳ vọng | Trạng thái |
|---|---|---|---|
| S1 | Ngủ ngay → đồng hồ chạy | Chạy đúng, sang tab khác rồi quay lại vẫn đúng | ✅ (test tầng dữ liệu) |
| S2 | Bé dậy rồi → Hoàn tác | Quay về trạng thái đang ngủ | ✅ (test giao diện) |
| S3 | Nhập nhanh 30 phút / 1 giờ… | Lưu đúng khoảng | ✅ (test tầng dữ liệu) |
| S4 | Huỷ giấc ngủ đang chạy | Hộp xác nhận, xoá đúng | ✅ (test giao diện) |

### 3.5 Phân & tã ⚠️ (đã sửa ảnh)
| # | Thao tác | Kỳ vọng | Trạng thái |
|---|---|---|---|
| D1 | Chọn màu, kết cấu, số lượng | Ô chọn có dấu, đổi đúng | ✅ (ảnh chụp) |
| D2 | Thêm ảnh rồi Lưu | Ảnh hiện trong dòng nhật ký (thumbnail) | ✅ (test ảnh) |
| D3 | Mở chi tiết bản ghi có ảnh | Ảnh lớn hiển thị | ✅ (test ảnh) |
| D4 | Chỉ có tã ướt (không phân) | Lưu được, ghi "Tã ướt" | ✅ (test giao diện) |
| D5 | Màu cảnh báo (Bạc, Máu) | Hiện lời khuyên đi khám | ✅ (test giao diện) |
| D6 | Hoàn tác sau khi lưu | Bản ghi và ảnh cùng biến mất | ✅ (test tầng dữ liệu) |
| D7 | Bỏ ảnh trước khi lưu (nút X) | Không còn ảnh trong bản ghi | ✅ (test tầng dữ liệu) |

### 3.6 Nhiệt độ, thuốc, ghi chú
| # | Thao tác | Kỳ vọng | Trạng thái |
|---|---|---|---|
| T1 | Nhiệt độ: chỉnh bằng nút ±, thanh trượt | Số đúng, nhận xét đúng ngưỡng | ✅ (test giao diện) |
| T2 | Thuốc: tên, liều, nhắc lại | Lưu và hiện trong nhật ký | ✅ (test giao diện) |
| T3 | Ghi chú: văn bản dài | Không tràn, lưu đủ | ✅ (test dữ liệu) |

### 3.7 Lịch sử
| # | Thao tác | Kỳ vọng | Trạng thái |
|---|---|---|---|
| L1 | Lọc theo loại (Tất cả, Bú, Hút sữa, Ngủ, Tã…) | Chỉ hiện đúng loại, chip đổi màu | ✅ (ảnh chụp) |
| L2 | Tìm kiếm từ khoá | Lọc đúng | ✅ (test giao diện) |
| L3 | Chọn ngày ở biểu tượng lịch | Hiện đúng ngày | ✅ (test giao diện) |
| L4 | Sửa / xoá từ chi tiết | Lưu và cập nhật ngay | ✅ (test giao diện) |
| L5 | Bản ghi có ảnh | Thumbnail hiện, không chỉ biểu tượng | ✅ (test ảnh) |

### 3.8 Thống kê, Tổng quan
| # | Thao tác | Kỳ vọng | Trạng thái |
|---|---|---|---|
| O1 | Chuyển Ngày / Tuần / Tháng | Số và biểu đồ đổi đúng | ✅ (test giao diện) |
| O2 | Mũi tên lùi / tới tuần | Ngày hiển thị đúng | ✅ (test giao diện) |
| O3 | Chọn "Theo ngày" trong biểu đồ | Dropdown đúng, không che chữ | ✅ (test giao diện) |
| O4 | Thẻ tổng kết → Lưu ảnh | Tải ảnh PNG; trên iPhone mở bảng chia sẻ | ✅ (test: chụp ra PNG thật) |

### 3.9 Tiền của bé (Thu chi)
| # | Thao tác | Kỳ vọng | Trạng thái |
|---|---|---|---|
| M1 | Nút + → màn Thêm khoản chi | Mở màn riêng, không popup | ✅ (ảnh chụp) |
| M2 | Nhập số tiền, gợi ý +50k… | Số và chữ "đ" đúng | ✅ (test giao diện) |
| M3 | Chọn nhãn (nhiều), thời gian, chi tiết | Lưu đúng nhãn | ✅ (test giao diện) |
| M4 | Thêm ảnh hoá đơn → Lưu | Ảnh hiện ở danh sách và chi tiết | ✅ (test ảnh) |
| M5 | Sửa khoản, Xoá khoản | Có xác nhận, cập nhật tổng | ✅ (test giao diện) |
| M6 | Ẩn/hiện số tiền (mắt) | Bình quỹ không đổi hình | ✅ (đã sửa) |
| M7 | Ngân sách tháng, cảnh báo | Hiện khi vượt | ✅ (test giao diện) |
| M8 | Lọc, tìm kiếm | Đúng kết quả | ✅ (test dữ liệu) |

### 3.10 Quỹ của con
| # | Thao tác | Kỳ vọng | Trạng thái |
|---|---|---|---|
| Q1 | Nút + ở tab Quỹ → màn Thêm vào quỹ | Màn riêng | ✅ (đã sửa) |
| Q2 | Chọn loại tài sản, nhập tên, số tiền | Lưu đúng | ✅ (test giao diện) |
| Q3 | Vàng: số lượng, giá mua, giá hiện tại | Tính giá trị đúng | ✅ (test dữ liệu) |
| Q4 | Thêm ảnh sổ tiết kiệm → Lưu → mở chi tiết | Ảnh hiện | ✅ (test ảnh) |
| Q5 | Thêm vào / Rút ra / Sửa giá | Cập nhật lịch sử | ✅ (test dữ liệu) |
| Q6 | Mục tiêu (đặt, sửa, bình) | Phần trăm đúng | ✅ (test giao diện) |

### 3.11 Tiện ích và Hồ sơ
| # | Thao tác | Kỳ vọng | Trạng thái |
|---|---|---|---|
| U1 | Tìm chức năng | Lọc đúng, không dấu vẫn tìm được | ✅ (test giao diện) |
| U2 | Ghim nhanh: thêm, bỏ, kéo sắp xếp | Thứ tự lưu lại sau khi đóng app | ✅ (test dữ liệu) |
| U3 | Đổi ba nút giữa thanh dưới | Thanh dưới đổi, lưu lại | ✅ (test dữ liệu) |
| U4 | Về mặc định | Khôi phục đúng | ✅ (test giao diện) |
| U5 | Hồ sơ bé: sửa tên, ngày sinh, cân nặng | Tuổi tính lại đúng | ✅ (test giao diện: lưu, thoát không lưu, tên trống) |

### 3.12 Nhật ký mốc
| # | Thao tác | Kỳ vọng | Trạng thái |
|---|---|---|---|
| J1 | Lưu kỷ niệm mốc ngày (đầy tháng…) | Thông báo, mở thẻ chia sẻ | ✅ (test giao diện) |
| J2 | Ghi "lần đầu" và mốc riêng | Chip đổi trạng thái | ✅ (test giao diện) |
| J3 | Thẻ chia sẻ: đổi 4 mẫu màu, lưu ảnh | Ảnh đúng màu đã chọn | ✅ (test giao diện, chưa kiểm tra ảnh xuất) |
| J4 | Xoá kỷ niệm (có ảnh) | Ảnh bị xoá khỏi máy | ✅ (test giao diện) |

### 3.13 Cài đặt và sao lưu
| # | Thao tác | Kỳ vọng | Trạng thái |
|---|---|---|---|
| C1 | Giao diện Theo máy / Sáng / Tối | Đổi đúng | ✅ (test giao diện) |
| C2 | Hiệu ứng kính mờ Tắt/Nhẹ/Đầy đủ | Thay đổi thấy được | ✅ (test giao diện) |
| C3 | Xuất tệp sao lưu → Khôi phục | Dữ liệu và ảnh đầy đủ sau khôi phục | ✅ (đã có trong widget_test: sao lưu và khôi phục gồm ảnh) |
| C4 | Chạy khi không có mạng → Kiểm tra | Sẵn sàng khi đã lưu đủ | ✅ (kiểm tra bằng Chrome tự động; iPhone thật bỏ qua theo yêu cầu) |
| C5 | Xoá toàn bộ dữ liệu | Hộp xác nhận rõ ràng | ✅ (test giao diện) |

## 4. Thứ tự làm

1. **Tuần 1:** hoàn tất các mục 🔲 của Bú, Ngủ, Hút sữa, Tã (luồng nhập và xoá).
2. **Tuần 2:** Tiền, Quỹ, Nhật ký mốc (đều có ảnh).
3. **Tuần 3:** Thống kê, Lịch sử, Tiện ích, Cài đặt, sao lưu.
4. **Cuối:** chạy lại toàn bộ trên iPhone thật, ở cả hai chế độ.

## 5. Ghi nhận lỗi

Mỗi lỗi ghi: màn, bước, kỳ vọng, thực tế, ảnh chụp, chế độ sáng hay tối, và thiết bị. Lỗi nghiêm trọng (mất dữ liệu, mất ảnh, không lưu được) được sửa trước mọi việc khác.


## Kiểm thử đầu-cuối trên trình duyệt thật (tự động)

Chạy bằng Chrome giả lập iPhone 13, dùng bản build đang phục vụ ở cổng 8090 (`design/tool/e2e/`). Yêu cầu: `pip install playwright`, Chrome, máy chủ đã chạy (`app/tool/deploy.ps1`).

| Tệp | Nội dung | Kết quả |
|---|---|---|
| `e2e_full.py` | Người dùng mới: làm quen, ngủ, tã, bình sữa, Lịch sử, reload, 6 tab, chế độ tối, 24 deep link, ngoại tuyến | ✅ 52/52 |
| `e2e_data.py` | Lưu bền: ngủ, tã, hút sữa, nhiệt độ, thuốc, ghi chú sau reload; thông báo Hoàn tác không đè màn mới | ✅ 20/20 |
| `e2e_more.py` | Thu chi, Quỹ, Tăng trưởng, Tiêm chủng, Cài đặt (chế độ tối) qua reload | ✅ 9/9 |
| `e2e_screens.py` | Ăn dặm, Tủ sữa (thêm bình), Cẩm nang (tìm kiếm), Góc của mẹ (lưu tâm trạng), EPDS đủ 10 câu ra kết quả, Gia đình, Wonder Weeks, EASY | ✅ 13/13 |
| `e2e_backup.py` | Xuất sao lưu JSON, CSV, báo cáo bác sĩ; xoá sạch; khôi phục từ tệp (dữ liệu và tên bé trở lại) | ✅ 11/11 |
| `e2e_extra.py` | Tiếng ồn trắng; lưu ảnh thẻ tổng kết và thẻ kỷ niệm (nhánh chia sẻ và nhánh tải PNG); tủ sữa lưu bình; sửa/xoá bản ghi; chọn tệp ảnh vào cữ tã | ✅ 16/16 |
| `e2e_night.py` | Chế độ "Theo giờ" với đồng hồ giả: 19:58 sáng, 20:00 tối (hoãn khi đang ở màn con, đổi khi về màn chính), 6:00 sáng lại, lưu qua reload | ✅ 9/9 |
| `e2e_mom.py` | Thao tác một tay: ngủ/dậy 1 chạm, tã ướt bằng giữ ô, dòng tóm tắt đầu Trang chủ, bình sữa lượng thường gặp không cần bấm Xong, vùng chạm ≥ 44 | ✅ 19/19 |
| `e2e_feedback.py` | Đợt góp ý: thứ tự Trang chủ, nút ghi nhanh, lịch tháng + việc cần làm (qua reload), mục tiêu quỹ, nhịp EASY đổi lịch, bước 5 ml, bỏ "Hai bên", Tiện ích hết trùng | ✅ 21/21 |
| `e2e_babies.py` | Nhiều bé: thêm bé, dữ liệu tách riêng, nhớ bé đang xem qua reload, dải chip ở Hồ sơ, sao lưu chứa cả hai bé, xoá bé | ✅ 16/16 |

Lỗi tìm được bằng lớp này: thông báo "Đã ghi giấc ngủ · Hoàn tác" ở lại 5 giây trên màn kế tiếp, che hàng chọn và nhận chạm nhầm (mở lại giấc ngủ đã kết thúc). Đã sửa trong `openPage` (ẩn thông báo khi mở màn mới) và có test hồi quy `test/toast_test.dart`.

Ghi chú: nút "Lưu ảnh" ưu tiên hộp chia sẻ của hệ điều hành (Web Share), chỉ tải tệp PNG khi không có Web Share; kịch bản kiểm tra cả hai nhánh bằng cách giả lập `navigator.share`.

## Rà giao diện bằng mắt (sáng và tối)

`design/tool/e2e/visual_sweep.py` chụp 26 màn ở chế độ sáng và tối với dữ liệu mẫu, ghép thành tờ ảnh trong `design/tool/e2e/out/vs/` để xem bằng mắt. Lượt rà 2026-10-08 tìm và sửa 4 lỗi hiển thị:

1. Nút "Ngủ ngay" / "Bé dậy rồi" ở chế độ tối: chữ trắng trên nền bạc hà nhạt → `BigButton` tự dùng chữ tối khi nền nhạt (`test/button_contrast_test.dart`).
2. Nút "Ghi hút" (Tủ sữa) ở chế độ tối: chữ trắng trên nền hồng nhạt → dùng chữ tối.
3. Hàng "Hoặc nhập tay số phút" (Hút sữa): chữ dính sát nút − và + → thêm khoảng cách.
4. Khung "14 ngày gần đây" (Góc của mẹ): chế độ sáng không thấy ô trống → ô trống có nền nhạt; nhãn "Sắp có" (Premium) ở chế độ tối đã đổi nền cho đọc được.

Chế độ giao diện "Theo giờ" (mặc định tối từ 20h đến 6h): `test/night_mode_test.dart` (9 test: khung giờ qua nửa đêm, lưu/đọc cài đặt, giao diện cài đặt, app đổi chế độ, bộ hẹn 30 giây, hoãn khi đang ở màn con).

## Thao tác một tay cho mẹ bỉm (2026-10-08)

`design/tool/e2e/touch_audit.py` đo kích thước nút trên 27 màn. Trước: hàng chục nút dưới 44 pt (nút ± ml ở Hút sữa 30 pt, Quay lại 40 pt, chip/Seg 28–38 pt). Sau: các thành phần dùng chung (`minHit` cho nút tròn, chip, Quay lại; Seg cao tối thiểu 44) và các nút hay dùng đều có vùng chạm ≥ 44 pt. Ghi nhanh: vòng tròn ở ô Ngủ bắt đầu/kết thúc ngủ ngay, giữ ô Phân & tã ghi tã ướt, đều có Hoàn tác. Bình sữa lượng thường gặp chỉ báo ngắn thay vì hộp "Xong". Màn hình giữ sáng khi đang bấm giờ bú/hút (Screen Wake Lock; chưa thử được trên iPhone thật). Test: `test/mom_ux_test.dart` (10 test).

## Đợt góp ý 2026-10-10

Trang chủ (thứ tự khối, Tổng quan có thời gian ngủ, Cữ gần nhất có cả hút sữa, gộp Cho bú/Bình sữa thành Ghi bú tự mở đúng tab), nhịp EASY (lịch gợi ý và thời gian thức đổi theo E2.5–E4), quỹ nhiều mục tiêu, bỏ ô Mã hàng, lịch tháng có việc cần làm, quản lý nhiều bé (dữ liệu mỗi bé lưu riêng; bé đầu tiên giữ khoá cũ nên dữ liệu cũ không đổi), nút ghi nhanh góc dưới phải, bước ± 5 ml, bỏ "Hai bên", bỏ mục "Sức khoẻ" trùng trong Tiện ích. Test: `test/feedback_batch_test.dart`, `test/multi_baby_test.dart` (lõi lưu nhiều bé và nhiều mục tiêu, kho bộ nhớ), `test/baby_switch_ui_test.dart`, `test/calendar_test.dart`.

Đợt 2026-10-10 (tiếp): ô nhỏ Trang chủ có nền pastel riêng; Hút sữa có dòng 'Lần trước' và chọn nhanh lượng ('Như lần trước', 20-80 ml mỗi bên); Hồ sơ có ảnh đại diện bé, thẻ 'Thông tin của bé' sửa từng dòng và 'Cài đặt nhanh'. Test: test/profile_pump_test.dart (11 test). Trình duyệt: e2e_babies 16/16, e2e_backup 11/11, e2e_full 52/52, e2e_mom 19/19.

Hút sữa viết lại (2026-10-10): màn chính gọn (đồng hồ, nhập tay, tóm tắt hôm nay, cữ gần đây); bấm Kết thúc thì hiện ngay hộp nhập ml (Trái/Phải, bước 5, chọn nhanh dạng chip xuống dòng, tủ sữa, ghi chú); có thể nhập tay một cữ không bấm giờ hoặc lưu không ghi ml. Test: test/pump_flow_test.dart (12 test, gồm kiểm tra không tràn ở 320-430 px). Trình duyệt: e2e_data 22/22, e2e_mom 19/19, e2e_feedback 21/21.
