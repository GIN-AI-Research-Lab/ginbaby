import '../data/app_state.dart';
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
  // nhắc cữ bú: đã qua X giờ kể từ cữ bú gần nhất (trong 30 phút đầu sau mốc đó)
  final last = app.lastFeed;
  if (s.feedRemindHours > 0 && last != null) {
    final since = now.difference(last.time);
    final h = s.feedRemindHours;
    if (since.inMinutes >= h * 60 && since.inMinutes < h * 60 + 30) {
      out.add(DueReminder('feed-${last.id}', 'Đến cữ bú', 'Đã ${GB.dur(since)} kể từ cữ bú trước (${GB.hm(last.time)}).'));
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
