import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gin_baby/data/app_state.dart';

import 'package:gin_baby/core/theme.dart';
import 'package:gin_baby/data/models.dart';
import 'package:gin_baby/domain/age.dart';
import 'package:gin_baby/domain/feeding_ref.dart';
import 'package:gin_baby/domain/leaps.dart';
import 'package:gin_baby/core/reminders.dart';
import 'package:gin_baby/ui/export_report.dart';
import 'package:gin_baby/domain/epds.dart';
import 'package:gin_baby/domain/pump_ref.dart';
import 'package:gin_baby/domain/vaccines.dart';
import 'package:gin_baby/domain/who_growth.dart';

void main() {
  test('định dạng tiền VND', () {
    expect(GB.vnd(1250000), '1.250.000đ');
    expect(GB.vnd(-285000, sign: true), '−285.000đ');
    expect(GB.vnd(500000, sign: true), '+500.000đ');
  });

  test('ngày giờ luôn dd/mm/yy và hh:mm', () {
    final t = DateTime(2026, 4, 5, 7, 3);
    expect(GB.dmy(t), '05/04/26');
    expect(GB.dmyhm(t), '05/04/26 07:03');
    expect(GB.dm(t), '05/04');
  });

  test('tuổi hiệu chỉnh khi sinh non', () {
    final now = DateTime(2026, 10, 1);
    final b = Baby(name: 'A', sex: Sex.girl, dob: DateTime(2026, 6, 1), gestWeeks: 32);
    final a = Age(b, now);
    expect(a.days, 122);
    expect(a.adjDays, 122 - 8 * 7);
    final t = Baby(name: 'B', sex: Sex.boy, dob: DateTime(2026, 6, 1));
    expect(Age(t, now).adjDays, 122);
  });

  group('đánh giá cữ bú bình', () {
    test('trong khoảng thường gặp', () {
      expect(FeedingRef.feed(150, 60, expressedMilk: false).verdict, Verdict.ok);
    });
    test('hơi ít và rất ít', () {
      expect(FeedingRef.feed(100, 100, expressedMilk: false).verdict, Verdict.low);
      expect(FeedingRef.feed(40, 100, expressedMilk: false).verdict, Verdict.veryLow);
    });
    test('hơi nhiều và rất nhiều', () {
      expect(FeedingRef.feed(220, 100, expressedMilk: false).verdict, Verdict.high);
      expect(FeedingRef.feed(300, 100, expressedMilk: false).verdict, Verdict.veryHigh);
    });
    test('sữa mẹ đã hút được nới ngưỡng thấp', () {
      expect(FeedingRef.feed(100, 100, expressedMilk: true).verdict, Verdict.ok);
    });
    test('ngày đầu bé bú rất ít vẫn bình thường', () {
      expect(FeedingRef.feed(10, 0, expressedMilk: false).verdict, Verdict.ok);
    });
  });

  test('tổng ngày theo cân nặng, có trần 960ml', () {
    final d = FeedingRef.day(60, 5.0, 700);
    expect(d.range.lo, closeTo(650, 1));
    final big = FeedingRef.day(100, 9.0, 900);
    expect(big.range.hi, 960);
    expect(big.cap, true);
  });

  test('nhu cầu mỗi ngày tăng dần trong tuần đầu', () {
    final d1 = FeedingRef.perKgPerDay(0).mid;
    final d5 = FeedingRef.perKgPerDay(5).mid;
    expect(d5 > d1, true);
  });

  group('đánh giá hút sữa', () {
    test('những ngày đầu hút ít là bình thường', () {
      expect(PumpRef.assess(ml: 10, ageDays: 2, perSessionGoal: 80).verdict, PumpVerdict.firstDays);
    });
    test('ít hơn thường lệ có lời trấn an', () {
      final a = PumpRef.assess(ml: 40, ageDays: 90, baseline: 120, perSessionGoal: 100);
      expect(a.verdict, PumpVerdict.lower);
      expect(a.message.contains('rất hay gặp'), true);
    });
    test('đạt mục tiêu', () {
      expect(PumpRef.assess(ml: 110, ageDays: 90, baseline: 100, perSessionGoal: 100).verdict, PumpVerdict.good);
    });
    test('mục tiêu mỗi cữ còn lại', () {
      final t = PumpRef.target(ageDays: 90, weightKg: 6, sessionsPerDay: 6, pumpShare: 100, pumpedToday: 300, sessionsDone: 3);
      expect(t.remainingSessions, 3);
      expect(t.perSessionRemaining > 0, true);
    });
  });

  group('WHO growth', () {
    test('trung vị có z = 0 và phân vị 50', () {
      final m = Growth.valueAtZ(GrowthKind.weight, Sex.boy, 6, 0);
      expect(m, closeTo(7.934, 0.001));
      expect(Growth.zScore(GrowthKind.weight, Sex.boy, 6, m), closeTo(0, 1e-9));
      expect(Growth.percentile(0), closeTo(50, 0.01));
    });
    test('bé gái 12 tháng 8,9kg gần trung vị', () {
      final z = Growth.zScore(GrowthKind.weight, Sex.girl, 12, 8.9481);
      expect(z.abs() < 1e-6, true);
    });
    test('chiều dài trung vị lúc sinh', () {
      expect(Growth.valueAtZ(GrowthKind.length, Sex.boy, 0, 0), closeTo(49.8842, 1e-6));
      expect(Growth.valueAtZ(GrowthKind.head, Sex.girl, 24, 0), closeTo(47.1822, 1e-6));
    });
    test('P3 thấp hơn trung vị, P97 cao hơn', () {
      final lo = Growth.valueAtZ(GrowthKind.weight, Sex.girl, 5, Growth.zP3);
      final hi = Growth.valueAtZ(GrowthKind.weight, Sex.girl, 5, Growth.zP97);
      expect(lo < 6.9 && hi > 6.9, true);
    });
    test('z rất thấp được cảnh báo', () {
      expect(Growth.verdict(-2.5).$2, true);
      expect(Growth.verdict(0.3).$2, false);
    });
  });

  test('thang EPDS: câu 10 > 0 là khẩn', () {
    final a = List<int>.filled(10, 0)..[9] = 1;
    expect(epdsOutcome(a).urgent, true);
    expect(epdsOutcome(List<int>.filled(10, 0)).level, 0);
    expect(epdsOutcome(List<int>.filled(10, 2)).level, 2);
  });

  test('lịch tiêm chủng có đủ mũi TCMR chính', () {
    final ids = kVaccines.map((v) => v.id).toSet();
    expect(ids.containsAll({'bcg', 'dpt1', 'dpt3', 'measles', 'mr', 'rota2', 'ipv1'}), true);
    expect(kVaccines.where((v) => v.epi).length > 10, true);
  });

  test('sao lưu và khôi phục gồm cả ảnh, quỹ, thu chi, người thân', () async {
    final a = AppState();
    a.baby = Baby(name: 'Suri', sex: Sex.girl, dob: DateTime(2026, 4, 25, 6, 30));
    final id = await a.putPhoto(Uint8List.fromList([1, 2, 3, 4, 5]));
    a.entries.add(Entry(type: T.diaper, time: DateTime(2026, 10, 1, 8), data: {'kind': 'poop', 'photo': id}));
    a.txs.add(Tx(time: DateTime(2026, 10, 2), amount: -285000, title: 'Tã', tags: ['bim']));
    a.funds.add(FundItem(name: 'Vàng', type: AssetType.gold, qty: 2, buyPrice: 7500000, curPrice: 7600000, date: DateTime(2026, 7, 1)));
    a.members.add(Member(name: 'Ba', role: 'edit'));
    final dump = await a.exportAll();
    expect((dump['photos'] as Map).containsKey(id), true);

    final b = AppState();
    await b.importAll(jsonDecode(jsonEncode(dump)) as Map<String, dynamic>);
    expect(b.baby!.name, 'Suri');
    expect(b.entries.length, 1);
    expect(b.photo(id), Uint8List.fromList([1, 2, 3, 4, 5]));
    expect(b.txs.single.amount, -285000);
    expect(b.funds.single.value, 15200000);
    expect(b.members.any((m) => m.name == 'Ba'), true);
  });

  test('tuần khủng hoảng theo tuổi', () {
    expect(kLeaps.length, 10);
    expect(leapState(26 * 7).current?.n, 5);
    final s = leapState(20 * 7);
    expect(s.current, null);
    expect(s.next?.n, 5);
    expect(s.prev?.n, 4);
    expect(leapState(3 * 7).next?.n, 1);
    expect(leapState(120 * 7).next, null);
  });

  test('xuất CSV và báo cáo bác sĩ', () {
    app.baby = Baby(name: 'Suri', sex: Sex.girl, dob: DateTime(2026, 4, 25, 6, 30));
    app.entries
      ..clear()
      ..add(Entry(type: T.feed, time: DateTime(2026, 10, 1, 8), data: {'method': 'bottle', 'source': 'mom', 'ml': 120, 'note': 'ngoan, ít'}))
      ..add(Entry(type: T.temp, time: DateTime(2026, 10, 2, 9), data: {'v': 37.2}));
    final csv = entriesCsv();
    expect(csv.contains('01/10/26 08:00'), true);
    expect(csv.contains('"ngoan, ít"'), true);
    final html = doctorReportHtml();
    expect(html.contains('Suri'), true);
    expect(html.contains('Báo cáo sức khoẻ của bé'), true);
  });

  test('nhắc nhở đến hạn: cữ hút và sữa sắp hết hạn', () {
    app.baby = Baby(name: 'Suri', sex: Sex.girl, dob: DateTime(2026, 4, 25, 6, 30));
    app.entries.clear();
    app.fridge.clear();
    app.appts.clear();
    app.settings.remind = true;
    app.settings.pumpTimes = [9, 12];
    final t = DateTime(2026, 10, 6, 9, 10);
    var l = dueReminders(t);
    expect(l.any((r) => r.key.startsWith('pump-') && r.key.endsWith('-0')), true);
    expect(l.any((r) => r.key.endsWith('-1')), false);
    // đã hút đủ thì không nhắc
    app.entries.add(Entry(type: T.pump, time: DateTime(2026, 10, 6, 9, 5), data: {'l': 50, 'r': 50, 'ml': 100, 'min': 20}));
    l = dueReminders(t);
    expect(l.any((r) => r.key.startsWith('pump-')), false);
    // bình sữa còn 90 phút thì nhắc
    app.fridge.add(FridgeItem(ml: 100, storedAt: t.subtract(const Duration(days: 4)).add(const Duration(minutes: 90))));
    l = dueReminders(t);
    expect(l.any((r) => r.key.startsWith('fridge-')), true);
  });

  test('hạn dùng sữa trong tủ', () {
    final t = DateTime(2026, 10, 1, 8);
    expect(FridgeItem(ml: 100, storedAt: t).expires, t.add(const Duration(days: 4)));
    expect(FridgeItem(ml: 100, storedAt: t, freezer: true).expires.month, 4);
  });
}
