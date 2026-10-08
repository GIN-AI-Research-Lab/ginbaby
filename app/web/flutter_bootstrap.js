{{flutter_js}}
{{flutter_build_config}}

// Không dùng service worker mặc định của Flutter (đã ngừng hỗ trợ ngoại tuyến).
// GinBaby tự đăng ký sw.js trong index.html để chạy được khi mất mạng.
_flutter.loader.load();
