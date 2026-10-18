import 'package:flutter_test/flutter_test.dart';
import 'package:gin_baby/core/reminders.dart';
import 'package:gin_baby/data/app_state.dart';
import 'package:gin_baby/data/demo.dart';
import 'package:gin_baby/data/models.dart';

/// H3: nhắc nhở đúng lúc, đúng điều kiện, với thời điểm cố định (không phụ thuộc giờ thật).
/// Mỗi test tự dọn trạng thái đã đặt.
void main() {
  setUpAll(() async {
    await seedDemo(app);
  });

  // mốc thời gian cố định: 8/10/2026 lúc 10:00
  final day = DateTime(2026, 10, 8);
  DateTime at(int h, [int m = 0]) => DateTime(day.year, day.month, day.day, h, m);

  List<String> keys(DateTime now) => dueReminders(now).map((r) => r.key).toList();

  void resetSettings() {
    app.settings.remind = true;
    app.settings.pumpTimes = [9, 12];
    app.settings.feedRemindHours = 0;
    app.settings.pumpSessions = 2;
    app.baby!.mode = FeedMode.mixed;
  }

  void clearEntries() {
    for (final e in List<Entry>.from(app.entries)) {
      app.removeEntry(e.id);
    }
  }

  setUp(() {
    clearEntries();
    resetSettings();
  });

  tearDown(() {
    clearEntries();
    for (final a in List<Appointment>.from(app.appts)) {
      app.appts.remove(a);
    }
    resetSettings();
  });

  test('H3a: tắt nhắc nhở thì không có nhắc nào', () {
    app.settings.remind = false;
    app.settings.feedRemindHours = 1;
    app.addEntry(Entry(type: T.feed, time: at(7), data: {'method': 'bottle', 'ml': 100}));
    expect(dueReminders(at(10)), isEmpty);
  });

  test('H3b: cữ hút báo trong 30 phút kể từ giờ hẹn, quá 30 phút thì không báo', () {
    expect(keys(at(9, 10)).where((k) => k.startsWith('pump-')), hasLength(1));
    expect(keys(at(9, 40)).where((k) => k.startsWith('pump-')), isEmpty, reason: 'quá 30 phút không nhắc nữa');
    expect(keys(at(8, 50)).where((k) => k.startsWith('pump-')), isEmpty, reason: 'chưa tới giờ thì chưa nhắc');
  });

  test('H3c: đã hút đủ cữ của mốc đó thì không nhắc cữ đó nữa', () {
    app.addPump(mlL: 50, mlR: 50, minutes: 10, time: at(9, 2));
    final ks = keys(at(9, 10)).where((k) => k.startsWith('pump-')).toList();
    expect(ks, isEmpty, reason: 'cữ 1 đã ghi lúc 9:02 nên không nhắc nữa');
  });

  test('H3d: nhắc cữ bú sau X giờ, không nhắc khi chưa đủ giờ', () {
    app.settings.feedRemindHours = 3;
    app.addEntry(Entry(type: T.feed, time: at(7), data: {'method': 'bottle', 'ml': 100}));
    expect(keys(at(9, 30)).where((k) => k.startsWith('feed-')), isEmpty, reason: 'mới 2 giờ 30 phút');
    expect(keys(at(10, 5)).where((k) => k.startsWith('feed-')), hasLength(1), reason: 'đã đủ 3 giờ');
    expect(keys(at(10, 45)).where((k) => k.startsWith('feed-')), isEmpty, reason: 'quá 30 phút sau mốc thì thôi');
  });

  test('H3e: lịch hẹn chỉ nhắc trong 30 phút trước giờ hẹn', () {
    final a = Appointment(time: at(10, 20), title: 'Khám nhi');
    app.appts.add(a);
    expect(keys(at(10)).where((k) => k.startsWith('appt-')), hasLength(1));
    expect(keys(at(9, 45)).where((k) => k.startsWith('appt-')), isEmpty, reason: 'còn hơn 30 phút thì chưa nhắc');
    app.appts.remove(a);
  });

  test('H3f: lịch hẹn đã xong thì không nhắc', () {
    app.appts.add(Appointment(time: at(10, 10), title: 'Đã khám', done: true));
    expect(keys(at(10)).where((k) => k.startsWith('appt-')), isEmpty);
  });

  test('H3g: bé ăn công thức thì không nhắc cữ hút', () {
    app.baby!.mode = FeedMode.formula;
    expect(keys(at(9, 10)).where((k) => k.startsWith('pump-')), isEmpty);
  });
}
