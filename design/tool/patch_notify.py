# -*- coding: utf-8 -*-
import os
ROOT = r'F:\Project Ai\GinBaby\app'


def edit(rel, fn):
    p = os.path.join(ROOT, rel)
    s = open(p, encoding='utf-8').read()
    s = fn(s)
    open(p, 'w', encoding='utf-8').write(s)


def rep(s, old, new):
    assert old in s, old[:80]
    return s.replace(old, new, 1)


# --- nền tảng
edit(r'lib\core\platform_stub.dart', lambda s: s + """
/// Thông báo hệ thống: 'unsupported' | 'default' | 'granted' | 'denied'.
String notificationState() => 'unsupported';

Future<String> requestNotifications() async => 'unsupported';

void showNotification(String title, String body, String tag) {}
""")


def web(s):
    s = rep(s, "import 'dart:js_interop';", "import 'dart:js_interop';\nimport 'dart:js_interop_unsafe';")
    return s + """
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
"""


edit(r'lib\core\platform_web.dart', web)


# --- cài đặt: cờ bật thông báo và các khoá đã báo
def models(s):
    s = rep(s, "  String? heroPhoto;", "  bool notify = false; // bật thông báo của trình duyệt\n  List<String> notified = []; // các nhắc nhở đã báo (tránh báo lặp)\n  String? heroPhoto;")
    s = rep(s, "        if (heroPhoto != null) 'hp': heroPhoto,\n", "        if (heroPhoto != null) 'hp': heroPhoto,\n        'nf': notify,\n        'nt': notified,\n")
    s = rep(s, "    s.heroPhoto = j['hp'] as String?;\n", "    s.heroPhoto = j['hp'] as String?;\n    s.notify = j['nf'] == true;\n    s.notified = List<String>.from(j['nt'] as List? ?? const []);\n")
    return s


edit(r'lib\data\models.dart', models)

REM = """import '../data/app_state.dart';
import '../data/models.dart';
import '../ui/vaccine_screen.dart';
import 'platform.dart';
import 'theme.dart';

class DueReminder {
  const DueReminder(this.key, this.title, this.body);
  final String key;
  final String title;
  final String body;
}

/// Các nhắc nhở đang đến hạn tại thời điểm [now] (cữ hút, sữa sắp hết hạn, tiêm chủng, lịch hẹn).
List<DueReminder> dueReminders(DateTime now) {
  final out = <DueReminder>[];
  final s = app.settings;
  if (app.baby == null || !s.remind) return out;
  final day = AppState.dayKey(now);

  // cữ hút theo giờ đã đặt, trong 30 phút kể từ giờ hẹn và chưa đủ số cữ
  if (app.baby!.mode != FeedMode.formula) {
    final done = app.pumpSessionsOn(now);
    for (var i = 0; i < s.pumpTimes.length; i++) {
      final at = DateTime(now.year, now.month, now.day, s.pumpTimes[i]);
      if (!now.isBefore(at) && now.difference(at).inMinutes < 30 && done <= i) {
        out.add(DueReminder('pump-$day-$i', 'Đến cữ hút sữa', 'Cữ hút ${i + 1}/${s.pumpTimes.length} lúc ${GB.hm(at)}. Mẹ nhớ uống nước nhé.'));
      }
    }
  }
  // sữa trong tủ sắp hết hạn trong 2 giờ
  for (final f in app.fridgeActive) {
    final left = f.expires.difference(now);
    if (left.inMinutes > 0 && left.inMinutes <= 120) {
      out.add(DueReminder('fridge-${f.id}', 'Sữa sắp hết hạn', 'Bình ${f.left}ml còn ${GB.dur(left)}. Nên dùng trước.'));
    }
  }
  // mũi tiêm đến hạn hoặc quá hạn: nhắc mỗi ngày một lần
  final vr = nextVaccineReminder();
  if (vr != null && vr.status != VStatus.soon) {
    out.add(DueReminder('vax-${vr.v.id}-$day', vr.status == VStatus.overdue ? 'Quá lịch tiêm' : 'Đến hạn tiêm chủng', '${vr.v.name}, dự kiến ${GB.dmy(vr.dueDate)}.'));
  }
  // lịch hẹn trong 30 phút tới
  for (final a in app.appts.where((a) => !a.done)) {
    final d = a.time.difference(now);
    if (d.inMinutes >= 0 && d.inMinutes <= 30) {
      out.add(DueReminder('appt-${a.id}', a.title, 'Lúc ${GB.hm(a.time)}${a.place.isEmpty ? '' : ' · ${a.place}'}'));
    }
  }
  return out;
}

/// Kiểm tra và gửi thông báo trình duyệt cho các nhắc nhở chưa báo. Trả về số thông báo đã gửi.
int checkAndNotify([DateTime? at]) {
  final s = app.settings;
  if (!s.notify || notificationState() != 'granted') return 0;
  var n = 0;
  for (final r in dueReminders(at ?? DateTime.now())) {
    if (s.notified.contains(r.key)) continue;
    showNotification(r.title, r.body, r.key);
    s.notified.add(r.key);
    n++;
  }
  if (n > 0) {
    if (s.notified.length > 200) s.notified = s.notified.sublist(s.notified.length - 200);
    app.settingsChanged();
  }
  return n;
}
"""
open(os.path.join(ROOT, r'lib\core\reminders.dart'), 'w', encoding='utf-8').write(REM)


def main(s):
    s = rep(s, "import 'core/perf.dart';", "import 'core/perf.dart';\nimport 'core/reminders.dart';")
    s = rep(s, "  int tab = 0;\n\n  @override\n  void initState() {\n    super.initState();", "  int tab = 0;\n  Timer? _remind;\n\n  @override\n  void initState() {\n    super.initState();\n    // Thông báo trình duyệt: kiểm tra nhắc nhở đến hạn mỗi 45 giây khi app còn mở.\n    _remind = Timer.periodic(const Duration(seconds: 45), (_) => checkAndNotify());")
    s = rep(s, "  void _go(int i) => setState(() => tab = i);", "  @override\n  void dispose() {\n    _remind?.cancel();\n    super.dispose();\n  }\n\n  void _go(int i) => setState(() => tab = i);")
    return s


edit(r'lib\main.dart', main)


def settings(s):
    s = rep(s, "import 'export_report.dart';", "import '../core/reminders.dart';\nimport 'export_report.dart';")
    old = "              _switch('Nhắc nhở trong app',"
    a = s.index(old)
    # chèn công tắc thông báo ngay sau công tắc nhắc nhở trong app
    b = s.index("              }),\n", a) + len("              }),\n")
    new = """              if (kIsWebPlatform && notificationState() != 'unsupported')
                _switch('Thông báo của trình duyệt', 'Hiện khi GinBaby còn mở (kể cả tab nền): cữ hút, sữa sắp hết hạn, tiêm chủng, lịch hẹn. Bản iPhone sẽ nhắc cả khi đã đóng app.', s.notify && notificationState() == 'granted', (v) async {
                  if (v) {
                    final r = await requestNotifications();
                    if (r != 'granted') {
                      if (context.mounted) toast(context, r == 'denied' ? 'Trình duyệt đang chặn thông báo, hãy bật lại trong cài đặt trang web' : 'Chưa bật được thông báo');
                      return;
                    }
                    s.notify = true;
                    app.settingsChanged();
                    showNotification('GinBaby', 'Đã bật thông báo. Mẹ sẽ được nhắc khi đến giờ.', 'welcome');
                  } else {
                    s.notify = false;
                    app.settingsChanged();
                  }
                }),
"""
    s = s[:b] + new + s[b:]
    return s


edit(r'lib\ui\settings.dart', settings)
print('ok')
