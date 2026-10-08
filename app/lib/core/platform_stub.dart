import 'dart:typed_data';

const bool kIsWebPlatform = false;

void reloadPage() {}

Future<String?> fetchVersion() async => null;

/// Tải một tệp về máy (chỉ web).
void downloadBytes(String name, Uint8List bytes, String mime) {}

/// Xin trình duyệt giữ dữ liệu lâu dài (không tự xoá khi thiếu dung lượng).
Future<bool> requestPersistentStorage() async => true;

/// Dung lượng đang dùng / tối đa của kho dữ liệu (chỉ web).
Future<({int used, int quota})?> storageEstimate() async => null;

/// Chọn một tệp văn bản (chỉ web).
Future<String?> pickTextFile() async => null;

/// Thông báo hệ thống: 'unsupported' | 'default' | 'granted' | 'denied'.
String notificationState() => 'unsupported';

Future<String> requestNotifications() async => 'unsupported';

void showNotification(String title, String body, String tag) {}

/// Mở bảng chia sẻ của hệ điều hành kèm tệp (iPhone: có nút "Lưu ảnh"). Trả về true nếu đã mở hoặc mẹ đã đóng bảng.
Future<bool> shareFileBytes(String name, Uint8List bytes, String mime, {String title = ''}) async => false;

/// Mở một trang tĩnh đi kèm app (ví dụ offline-check.html) ngay trong cửa sổ hiện tại (chỉ web).
void openLocalPage(String relative) {}

/// Tắt việc app ghi từng màn vào lịch sử trình duyệt: để cử chỉ vuốt từ mép trái của iOS không quay lại trang trắng (chỉ web).
void disableBrowserHistory() {}

/// Tình trạng lưu ngoại tuyến (JSON) và các thao tác lưu thêm / đăng ký lại (chỉ web).
Future<String?> offlineStatusJson() async => null;
Future<void> offlineWarm() async {}
Future<void> offlineReset() async {}
