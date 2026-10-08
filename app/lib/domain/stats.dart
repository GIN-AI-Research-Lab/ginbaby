import 'dart:math' as math;

import '../data/app_state.dart';
import '../data/models.dart';

/// Số liệu một ngày.
class DayStat {
  DayStat({
    required this.day,
    required this.sleep,
    required this.longestSleep,
    required this.sleepCount,
    required this.feedCount,
    required this.bottleMom,
    required this.bottleFormula,
    required this.breastEst,
    required this.wet,
    required this.poop,
    required this.pumpMl,
    required this.pumpCount,
    required this.hasData,
    this.breastMin = 0,
    this.breastCount = 0,
  });

  final DateTime day;
  final Duration sleep;
  final Duration longestSleep;
  final int sleepCount;
  final int feedCount;
  final int bottleMom;
  final int bottleFormula;
  final int breastEst;
  final int wet;
  final int poop;
  final int pumpMl;
  final int pumpCount;
  final bool hasData;
  final int breastMin; // tổng phút bú mẹ trực tiếp
  final int breastCount; // số cữ bú mẹ trực tiếp

  int get milk => bottleMom + bottleFormula + breastEst;
  int get diapers => wet + poop;
  double get sleepHours => sleep.inMinutes / 60;
}

class Stats {
  static DayStat day(AppState a, DateTime d) {
    final s = AppState.dayStart(d);
    final list = a.entriesOn(s);
    final t = a.feedTotals(s);
    var longest = Duration.zero;
    var cnt = 0;
    final end = s.add(const Duration(days: 1));
    final now = DateTime.now();
    for (final e in a.entries) {
      if (e.type != T.sleep) continue;
      final xe = e.end ?? now;
      if (xe.isBefore(s) || e.time.isAfter(end)) continue;
      final from = e.time.isBefore(s) ? s : e.time;
      final to = xe.isAfter(end) ? end : xe;
      final len = to.difference(from);
      if (len > longest) longest = len;
      cnt++;
    }
    var wet = 0, poop = 0;
    for (final e in list.where((e) => e.type == T.diaper)) {
      final k = e.str('kind');
      if (k == 'wet' || k == 'both') wet++;
      if (k == 'poop' || k == 'both') poop++;
    }
    final pumps = list.where((e) => e.type == T.pump).toList();
    final breasts = list.where((e) => e.type == T.feed && e.str('method') == 'breast').toList();
    return DayStat(
      day: s,
      sleep: a.sleepOn(s),
      longestSleep: longest,
      sleepCount: cnt,
      feedCount: t.count,
      bottleMom: t.bottleMom,
      bottleFormula: t.bottleFormula,
      breastEst: t.breastEst,
      wet: wet,
      poop: poop,
      pumpMl: pumps.fold(0, (x, e) => x + e.ml),
      pumpCount: pumps.length,
      hasData: list.isNotEmpty || a.sleepOn(s) > Duration.zero,
      breastMin: breasts.fold(0, (x, e) => x + e.num('min').round()),
      breastCount: breasts.length,
    );
  }

  static DateTime weekStart(DateTime d) {
    final s = AppState.dayStart(d);
    return s.subtract(Duration(days: s.weekday - 1));
  }

  static List<DayStat> week(AppState a, DateTime anyDay) {
    final w = weekStart(anyDay);
    return [for (var i = 0; i < 7; i++) day(a, w.add(Duration(days: i)))];
  }

  static List<DayStat> month(AppState a, DateTime anyDay) {
    final first = DateTime(anyDay.year, anyDay.month, 1);
    final n = DateTime(anyDay.year, anyDay.month + 1, 0).day;
    return [for (var i = 0; i < n; i++) day(a, first.add(Duration(days: i)))];
  }

  static double avg(Iterable<double> v) {
    final l = v.toList();
    return l.isEmpty ? 0 : l.reduce((a, b) => a + b) / l.length;
  }

  /// Trung bình chỉ tính các ngày có dữ liệu.
  static double avgOf(List<DayStat> l, double Function(DayStat) f) => avg(l.where((d) => d.hasData).map(f));
}

/// Gợi ý "điểm sáng" cho thẻ tổng kết, sinh từ số liệu.
List<String> highlights(List<DayStat> cur, List<DayStat> prev) {
  final out = <String>[];
  final with_ = cur.where((d) => d.hasData).toList();
  if (with_.isEmpty) return out;
  final longest = with_.reduce((a, b) => a.longestSleep > b.longestSleep ? a : b);
  if (longest.longestSleep.inMinutes >= 240) {
    const wd = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    out.add('Giấc ngủ dài nhất ${longest.longestSleep.inHours}h${(longest.longestSleep.inMinutes % 60).toString().padLeft(2, '0')} (${wd[longest.day.weekday - 1]})');
  }
  final sc = Stats.avgOf(cur, (d) => d.sleepHours);
  final sp = Stats.avgOf(prev, (d) => d.sleepHours);
  if (sp > 0) {
    final diff = ((sc - sp) * 60).round();
    if (diff.abs() >= 10) out.add(diff > 0 ? 'Ngủ nhiều hơn tuần trước ${diff}p mỗi ngày' : 'Ngủ ít hơn tuần trước ${-diff}p mỗi ngày');
  }
  final mc = Stats.avgOf(cur, (d) => d.milk.toDouble());
  final mp = Stats.avgOf(prev, (d) => d.milk.toDouble());
  if (mp > 0) {
    final pct = ((mc - mp) / mp * 100).round();
    if (pct.abs() >= 8) out.add(pct > 0 ? 'Bú nhiều hơn tuần trước $pct%' : 'Bú ít hơn tuần trước ${-pct}%');
  }
  final steady = with_.where((d) => d.sleepHours >= 11).length;
  if (steady >= 5) out.add('$steady/7 ngày ngủ đủ 11 giờ trở lên');
  return out.take(3).toList();
}

double maxOf(Iterable<num> v, [double floor = 1]) => math.max(floor, v.fold<double>(0, (a, b) => math.max(a, b.toDouble())));
