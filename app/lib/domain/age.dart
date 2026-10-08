import '../data/models.dart';

/// Tuổi của bé, có hiệu chỉnh khi sinh non (dưới 37 tuần).
class Age {
  Age(this.baby, [DateTime? now]) : now = now ?? DateTime.now();
  final Baby baby;
  final DateTime now;

  Duration get raw => now.difference(baby.dob).isNegative ? Duration.zero : now.difference(baby.dob);
  int get days => raw.inDays;
  int get weeks => days ~/ 7;

  bool get preterm => baby.gestWeeks < 37;

  /// Tuổi hiệu chỉnh (ngày) cho đánh giá dinh dưỡng và mốc phát triển, đến 24 tháng.
  int get adjDays {
    if (!preterm || days > 730) return days;
    final d = days - (40 - baby.gestWeeks) * 7;
    return d < 0 ? 0 : d;
  }

  double get months => adjDays / 30.4375;

  /// "5 tháng 12 ngày 3 giờ"
  String get label {
    var months = (now.year - baby.dob.year) * 12 + now.month - baby.dob.month;
    var anchor = _addMonths(baby.dob, months);
    if (anchor.isAfter(now)) {
      months -= 1;
      anchor = _addMonths(baby.dob, months);
    }
    final d = now.difference(anchor);
    if (months <= 0) {
      final dd = raw;
      if (dd.inDays < 1) return '${dd.inHours} giờ tuổi';
      return '${dd.inDays} ngày ${dd.inHours % 24} giờ';
    }
    return '$months tháng ${d.inDays} ngày ${d.inHours % 24} giờ';
  }

  /// Nhãn ngắn: "5 tháng", "3 tuần", "6 ngày"
  String get short {
    if (days < 14) return '$days ngày';
    if (days < 60) return '$weeks tuần';
    return '${(days / 30.4375).floor()} tháng';
  }

  static DateTime _addMonths(DateTime d, int m) {
    final total = d.month - 1 + m;
    final y = d.year + total ~/ 12;
    final mo = total % 12 + 1;
    final last = DateTime(y, mo + 1, 0).day;
    return DateTime(y, mo, d.day > last ? last : d.day, d.hour, d.minute);
  }
}
