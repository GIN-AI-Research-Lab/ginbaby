# -*- coding: utf-8 -*-
import io

ROOT = r'F:\Project Ai\GinBaby\app'


def rd(p):
    return io.open(ROOT + '\\' + p, encoding='utf-8').read()


def wr(p, s):
    io.open(ROOT + '\\' + p, 'w', encoding='utf-8').write(s)


def rep(s, a, b):
    assert a in s, a[:70]
    return s.replace(a, b, 1)


# index.html: nạp cầu nối trước bộ nạp Flutter
s = rd(r'web\index.html')
if 'offline_bridge.js' not in s:
    s = rep(s, '  <script src="flutter_bootstrap.js" async></script>', '  <script src="offline_bridge.js"></script>\n  <script src="flutter_bootstrap.js" async></script>')
    wr(r'web\index.html', s)

# settings: mở màn trong app thay vì rời sang trang tĩnh
s = rd(r'lib\ui\settings.dart')
s = rep(s, "_action('Kiểm tra chế độ ngoại tuyến', Icons.cloud_off_rounded, () => openLocalPage('offline-check.html')),", "_action('Kiểm tra chế độ ngoại tuyến', Icons.cloud_off_rounded, () => openPage(context, const OfflineScreen())),")
if 'offline_screen.dart' not in s:
    s = rep(s, "import '../core/kit.dart';", "import '../core/kit.dart';\nimport 'offline_screen.dart';")
wr(r'lib\ui\settings.dart', s)

# platform: tắt lịch sử trình duyệt và cầu nối
st = rd(r'lib\core\platform_stub.dart')
if 'disableBrowserHistory' not in st:
    st = st.rstrip() + """

/// Tắt việc app ghi từng màn vào lịch sử trình duyệt (chỉ web): để vuốt từ mép trái trên iPhone không quay lại trang trắng.
void disableBrowserHistory() {}

/// Tình trạng lưu ngoại tuyến (JSON) và thao tác lưu thêm, đăng ký lại (chỉ web).
Future<String?> offlineStatusJson() async => null;
Future<void> offlineWarm() async {}
Future<void> offlineReset() async {}
"""
    wr(r'lib\core\platform_stub.dart', st)
w = rd(r'lib\core\platform_web.dart')
if 'disableBrowserHistory' not in w:
    w = rep(w, "import 'dart:js_interop_unsafe';", "import 'dart:js_interop_unsafe';\nimport 'dart:ui_web' as ui_web;")
    w = w.rstrip() + """

/// Tắt việc app ghi từng màn vào lịch sử trình duyệt. Nếu không, iPhone coi cử chỉ vuốt từ mép trái là "quay lại trang trước"
/// và hiện trang trắng vài giây thay vì để app tự lùi một màn.
void disableBrowserHistory() {
  try {
    ui_web.urlStrategy = null;
  } catch (_) {}
}

Future<String?> offlineStatusJson() async {
  try {
    final r = await globalContext.callMethod<JSPromise<JSString>>('ginbabyOfflineStatus'.toJS).toDart;
    return r.toDart;
  } catch (_) {
    return null;
  }
}

Future<void> offlineWarm() async {
  try {
    await globalContext.callMethod<JSPromise<JSAny?>>('ginbabyOfflineWarm'.toJS).toDart;
  } catch (_) {}
}

Future<void> offlineReset() async {
  try {
    await globalContext.callMethod<JSPromise<JSAny?>>('ginbabyOfflineReset'.toJS).toDart;
  } catch (_) {}
}
"""
    wr(r'lib\core\platform_web.dart', w)

m = rd(r'lib\main.dart')
if 'disableBrowserHistory' not in m:
    m = rep(m, "  runApp(const GinBabyApp());", "  disableBrowserHistory();\n  runApp(const GinBabyApp());")
    wr(r'lib\main.dart', m)
print('ok')
