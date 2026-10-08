import 'dart:math' as math;

import 'app_state.dart';
import 'models.dart';

/// Dữ liệu mẫu 14 ngày để xem thử giao diện (có thể xoá trong Cài đặt).
Future<void> seedDemo(AppState a) async {
  final rnd = math.Random(7);
  final now = DateTime.now();
  final dob = DateTime(now.year, now.month, now.day, 6, 30).subtract(const Duration(days: 165));
  a.saveBaby(Baby(name: 'Suri', sex: Sex.girl, dob: dob, birthWeightKg: 3.2, birthLengthCm: 50, gestWeeks: 39, mode: FeedMode.mixed));

  a.measurements
    ..clear()
    ..addAll([
      Measurement(date: dob.add(const Duration(days: 30)), weightKg: 4.4, heightCm: 54.5, headCm: 37.5),
      Measurement(date: dob.add(const Duration(days: 61)), weightKg: 5.5, heightCm: 58.8, headCm: 39.5),
      Measurement(date: dob.add(const Duration(days: 91)), weightKg: 6.3, heightCm: 61.5, headCm: 40.8),
      Measurement(date: dob.add(const Duration(days: 122)), weightKg: 6.9, heightCm: 64.0, headCm: 41.8),
      Measurement(date: dob.add(const Duration(days: 152)), weightKg: 7.4, heightCm: 66.2, headCm: 42.6),
    ]);
  a.measurements.sort((x, y) => y.date.compareTo(x.date));
  a.changed('meas');

  a.entries.clear();
  a.fridge.clear();
  final today = DateTime(now.year, now.month, now.day);
  for (var d = 13; d >= 0; d--) {
    final day = today.subtract(Duration(days: d));
    DateTime at(int h, int m) => day.add(Duration(hours: h, minutes: m + rnd.nextInt(14) - 7));
    final isToday = d == 0;
    bool past(DateTime t) => !isToday || t.isBefore(now);

    // bú
    final hours = [6, 9, 12, 15, 18, 21];
    for (var i = 0; i < hours.length; i++) {
      final t = at(hours[i], 40);
      if (!past(t)) continue;
      if (i % 3 == 1) {
        final mins = 15 + rnd.nextInt(10);
        a.entries.add(Entry(type: T.feed, time: t.subtract(Duration(minutes: mins)), end: t, data: {'method': 'breast', 'source': 'mom', 'ml': 110 + rnd.nextInt(25), 'est': true, 'min': mins, 'side': i % 2 == 0 ? 'L' : 'R'}));
      } else {
        final formula = i == 5;
        a.entries.add(Entry(type: T.feed, time: t, data: {'method': 'bottle', 'source': formula ? 'formula' : 'mom', 'ml': 120 + rnd.nextInt(5) * 10}));
      }
    }
    // ngủ
    final nap = <(int, int, int, int)>[(9, 30, 11, 0), (13, 0, 14, 30), (16, 30, 17, 10)];
    final night = Entry(type: T.sleep, time: day.subtract(const Duration(hours: 3, minutes: 0)).add(Duration(minutes: rnd.nextInt(20))), end: day.add(Duration(hours: 6, minutes: 30 + rnd.nextInt(30))));
    if (isToday && night.end!.isAfter(now)) night.end = null; // đang ngủ đêm
    a.entries.add(night);
    for (final n in nap) {
      final s = day.add(Duration(hours: n.$1, minutes: n.$2 + rnd.nextInt(10)));
      final e = day.add(Duration(hours: n.$3, minutes: n.$4 + rnd.nextInt(10)));
      if (isToday && e.isAfter(now)) continue;
      a.entries.add(Entry(type: T.sleep, time: s, end: e));
    }
    // tã
    for (var i = 0; i < 5 + rnd.nextInt(3); i++) {
      final t = at(7 + i * 3, 10);
      if (!past(t)) continue;
      final poop = i % 3 == 1;
      a.entries.add(Entry(type: T.diaper, time: t, data: {'kind': poop ? 'poop' : 'wet', if (poop) 'state': 'Sệt', if (poop) 'color': 'Vàng'}));
    }
    // hút sữa
    for (final h in [8, 14, 20]) {
      final t = at(h, 0);
      if (!past(t)) continue;
      final l = 40 + rnd.nextInt(30), r = 40 + rnd.nextInt(30);
      a.entries.add(Entry(type: T.pump, time: t, data: {'l': l, 'r': r, 'ml': l + r, 'min': 20, 'store': 'fridge'}));
      if (d <= 2) a.fridge.add(FridgeItem(ml: l + r, storedAt: t));
    }
  }
  a.entries.sort((x, y) => y.time.compareTo(x.time));
  a.changed('entries');
  a.changed('fridge');

  // thu chi
  a.txs
    ..clear()
    ..addAll([
      Tx(time: now.subtract(const Duration(hours: 3)), amount: -285000, title: 'Tã dán size M', tags: ['bim'], code: 'BB-M54', qty: 1, unitPrice: 285000, store: 'Siêu thị'),
      Tx(time: now.subtract(const Duration(hours: 6)), amount: -640000, title: 'Sữa công thức số 2, 800g', tags: ['sua'], code: 'AP2-800'),
      Tx(time: now.subtract(const Duration(days: 1, hours: 4)), amount: 500000, title: 'Tiền mừng cô Hạnh', tags: ['mung']),
      Tx(time: now.subtract(const Duration(days: 1, hours: 8)), amount: -85000, title: 'Siro hạ sốt', tags: ['thuoc'], store: 'Nhà thuốc'),
      Tx(time: now.subtract(const Duration(days: 4)), amount: -285000, title: 'Tã dán size M', tags: ['bim'], code: 'BB-M54'),
      Tx(time: now.subtract(const Duration(days: 5)), amount: -300000, title: 'Khám nhi định kỳ', tags: ['kham']),
      Tx(time: now.subtract(const Duration(days: 6)), amount: 2000000, title: 'Lì xì ông bà ngoại', tags: ['lixi']),
    ]);
  a.changed('tx');

  a.funds
    ..clear()
    ..addAll([
      FundItem(name: 'Lì xì và tiền mừng', type: AssetType.cash, amount: 6500000, holder: 'Ba giữ', note: 'Đầy tháng, ngoại tặng', date: now.subtract(const Duration(days: 60))),
      FundItem(name: 'Sổ tiết kiệm 12 tháng', type: AssetType.saving, amount: 20000000, rate: 6, maturity: DateTime(now.year + 1, now.month, now.day), holder: 'Mẹ giữ sổ', date: now.subtract(const Duration(days: 90))),
      FundItem(name: 'Vàng nhẫn 9999', type: AssetType.gold, qty: 2, unit: 'chỉ', buyPrice: 7500000, curPrice: 7500000, holder: 'Bà nội giữ', note: 'Bà nội tặng', date: now.subtract(const Duration(days: 80))),
      FundItem(name: 'Chứng chỉ quỹ', type: AssetType.other, amount: 7100000, holder: 'Ba giữ', note: 'Góp mỗi tháng', date: now.subtract(const Duration(days: 120))),
    ]);
  a.goal = FundGoal(name: 'Học phí lớp 1', target: 120000000);
  a.changed('funds');
  a.changed('goal');

  a.vax.clear();
  for (final e in const {'hepb0': 0, 'bcg': 2, 'dpt1': 61, 'opv1': 61, 'rota1': 61, 'dpt2': 92, 'opv2': 92, 'rota2': 92, 'dpt3': 123, 'opv3': 123}.entries) {
    a.vax[e.key] = VaxRecord(date: dob.add(Duration(days: e.value)), place: 'Trạm y tế phường');
  }
  a.changed('vax');

  a.milestones
    ..clear()
    ..addAll({'m2_0': now.subtract(const Duration(days: 100)), 'm2_1': now.subtract(const Duration(days: 100)), 'm4_0': now.subtract(const Duration(days: 45))});
  a.changed('miles');

  a.memos
    ..clear()
    ..['d_month1'] = MilestoneMemo(key: 'd_month1', title: 'Đầy tháng', date: dob.add(const Duration(days: 30)), note: 'Cả nhà có mặt, bé ngủ ngoan suốt buổi tiệc.')
    ..['f_smile'] = MilestoneMemo(key: 'f_smile', title: 'Nụ cười đầu tiên', date: dob.add(const Duration(days: 52)), note: 'Bé cười khi mẹ hát ru.');
  a.changed('memos');
}
