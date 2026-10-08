import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

const bool kIsWebPlatform = true;

void reloadPage() => web.window.location.reload();

Future<String?> fetchVersion() async {
  try {
    final uri = Uri.base.resolve('version.json?ts=${DateTime.now().millisecondsSinceEpoch}');
    final r = await http.get(uri).timeout(const Duration(seconds: 6));
    if (r.statusCode != 200) return null;
    final m = RegExp(r'"build"\s*:\s*"([^"]+)"').firstMatch(r.body);
    return m?.group(1);
  } catch (_) {
    return null;
  }
}

void downloadBytes(String name, Uint8List bytes, String mime) {
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: mime));
  final url = web.URL.createObjectURL(blob);
  final a = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = name;
  web.document.body!.append(a);
  a.click();
  a.remove();
  web.URL.revokeObjectURL(url);
}

Future<bool> requestPersistentStorage() async {
  try {
    final r = await web.window.navigator.storage.persist().toDart;
    return r.toDart;
  } catch (_) {
    return false;
  }
}

Future<({int used, int quota})?> storageEstimate() async {
  try {
    final e = await web.window.navigator.storage.estimate().toDart;
    return (used: e.usage.toInt(), quota: e.quota.toInt());
  } catch (_) {
    return null;
  }
}

Future<String?> pickTextFile() {
  final c = Completer<String?>();
  final input = web.document.createElement('input') as web.HTMLInputElement
    ..type = 'file'
    ..accept = '.json,application/json';
  input.onchange = ((web.Event _) {
    final f = input.files?.item(0);
    if (f == null) {
      c.complete(null);
      return;
    }
    f.text().toDart.then((t) => c.complete(t.toDart), onError: (_) => c.complete(null));
  }).toJS;
  input.click();
  return c.future;
}

bool get _hasNotification => globalContext.has('Notification');

/// Thông báo của trình duyệt: hiện khi GinBaby còn mở (kể cả tab nền).
String notificationState() {
  try {
    if (!_hasNotification) return 'unsupported';
    return web.Notification.permission;
  } catch (_) {
    return 'unsupported';
  }
}

Future<String> requestNotifications() async {
  try {
    if (!_hasNotification) return 'unsupported';
    final r = await web.Notification.requestPermission().toDart;
    return r.toDart;
  } catch (_) {
    return 'unsupported';
  }
}

void showNotification(String title, String body, String tag) {
  try {
    if (!_hasNotification || web.Notification.permission != 'granted') return;
    web.Notification(title, web.NotificationOptions(body: body, tag: tag, icon: 'icons/Icon-192.png'));
  } catch (_) {}
}

/// Chia sẻ tệp qua bảng chia sẻ của hệ điều hành (Web Share API). Safari trên iPhone cho phép "Lưu ảnh" thẳng vào Ảnh.
/// Trả về false khi trình duyệt không hỗ trợ, để nơi gọi quay về cách tải tệp.
Future<bool> shareFileBytes(String name, Uint8List bytes, String mime, {String title = ''}) async {
  try {
    final nav = web.window.navigator;
    if (!nav.has('canShare') || !nav.has('share')) return false;
    final file = web.File([bytes.toJS].toJS, name, web.FilePropertyBag(type: mime));
    final data = web.ShareData(files: [file].toJS, title: title);
    if (!nav.canShare(data)) return false;
    await nav.share(data).toDart;
    return true;
  } catch (e) {
    // Mẹ bấm đóng bảng chia sẻ cũng ném lỗi AbortError: coi như đã xử lý, không tải tệp nữa.
    return e.toString().contains('AbortError');
  }
}

/// Mở một trang tĩnh đi kèm app (ví dụ offline-check.html) ngay trong cửa sổ hiện tại.
void openLocalPage(String relative) => web.window.location.assign(relative);

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
