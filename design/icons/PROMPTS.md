# Bộ icon tranh màu nước cho GinBaby

App tự dùng tranh nếu có tệp `app/assets/art/ic_<tên>.png` (PNG nền trong suốt, nên cỡ 256–512 px, vật thể nằm giữa, chừa lề nhỏ). Chưa có tệp nào thì app dùng icon hệ thống. Không cần sửa code: thả tệp vào thư mục, chạy lại `tool/deploy.ps1`. Script deploy tự tạo bản tranh cho chế độ tối (`assets/art_dark`) bằng `design/tool/make_dark_art.py`.

## Câu mô tả phong cách (dán trước mỗi câu lệnh)

> Cute soft watercolor illustration icon for a baby-care app, pastel pink, peach and cream palette, gentle thin outlines, soft highlights, single object centered, plain transparent background, no text, no shadow, children's picture-book style, consistent with a mother-and-baby watercolor set.

## Danh sách icon và mô tả riêng từng cái

| Tên tệp | Dùng ở đâu | Mô tả vật thể |
|---|---|---|
| `ic_thermometer.png` | Ghi nhanh nhiệt độ | a baby digital thermometer, white and pink |
| `ic_medicine.png` | Ghi nhanh thuốc | a small medicine bottle with a dosing syringe, pastel |
| `ic_note.png` | Ghi nhanh ghi chú | a small notebook with a pencil and a tiny heart |
| `ic_vaccine.png` | Hồ sơ, tiêm chủng | a cute syringe with a small bandage and heart |
| `ic_growth.png` | Hồ sơ, tăng trưởng | a baby scale with a soft measuring tape |
| `ic_solids.png` | Hồ sơ, ăn dặm | a baby bowl with a spoon and little carrot and pumpkin |
| `ic_book.png` | Hồ sơ, cẩm nang | an open picture book with a small bookmark heart |
| `ic_health.png` | Hồ sơ, sức khoẻ | a stethoscope forming a heart |
| `ic_mind.png` | Hồ sơ, góc của mẹ | a lotus flower with a tiny heart |
| `ic_noise.png` | Hồ sơ, tiếng ồn trắng | a crescent moon with soft sound waves and a music note |
| `ic_family.png` | Hồ sơ, gia đình | three simple round figures (mom, dad, baby) holding hands with hearts |
| `ic_clock.png` | Lịch EASY | a soft round alarm clock with a pink bow |
| `ic_wonder.png` | Wonder Weeks | a bright star with little sparkles and a tiny rocket |
| `ic_wallet.png` | Tab Tiền | a coin purse with a few coins |
| `ic_fund.png` | Quỹ của con | a pink piggy bank with a coin |
| `ic_fridge.png` | Tủ sữa | a small fridge holding two milk bottles |
| `ic_star.png` | Premium | a golden star crown |
| `ic_settings.png` | Cài đặt | a gear with a small heart in the middle |

Các tệp `ic_pump`, `ic_breast`, `ic_bottle`, `ic_moon` đã có (cắt từ ảnh mẫu); muốn đồng bộ hơn có thể sinh lại cùng phong cách và ghi đè.

## Cách tạo

1. **Tự sinh bằng công cụ bạn đang dùng:** dán câu phong cách + mô tả riêng, xuất PNG nền trong suốt, đặt đúng tên tệp ở bảng trên vào `app/assets/art/`.
2. **Tự động bằng API:** xem `design/tool/gen_icons.py` (cần khoá API đặt vào biến môi trường `OPENAI_API_KEY` trên máy bạn, không gửi khoá qua chat).

## Bộ tranh hiện tại (sinh bằng Gemini trên Vertex AI)

Toàn bộ `ic_*`, `poop_*`, `tex_*`, `diaper_*`, `pump_left/right` và các tranh `hero_*`, `baby_sleep`, `rainbow` được sinh lại bằng `design/tool/gen_icons_vertex.py` (dùng tài khoản gcloud đã đăng nhập, không lưu khoá). Ảnh thô ở `design/icons/raw/`, bản cũ cắt từ mockup ở `design/icons/old/`.

- Sinh lại một số ảnh: `python design/tool/gen_icons_vertex.py ic_pump poop_brown`
- Chỉ xử lý lại (tách nền, tăng bão hoà) từ ảnh thô, không gọi API: `python -c "import gen_icons_vertex as g; g.reprocess()"` trong thư mục `design/tool`
- Sau khi đổi ảnh, chạy `app/tool/deploy.ps1`: script tự tạo bản tranh cho chế độ tối (`make_dark_art.py`) rồi build và deploy.
- Vertex có hạn mức theo phút (lỗi 429): script tự chờ rồi thử lại, nên chạy từng ảnh một.
