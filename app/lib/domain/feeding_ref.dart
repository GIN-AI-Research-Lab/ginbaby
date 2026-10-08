import 'dart:math' as math;

/// Đánh giá lượng sữa theo tuổi và cân nặng.
///
/// Nguồn tham khảo (không thay thế tư vấn bác sĩ):
///  - AAP / HealthyChildren: ~2,5 oz sữa công thức mỗi pound mỗi ngày (≈150–165 ml/kg/ngày), tối đa ~32 oz (≈960 ml)/ngày;
///    mỗi cữ: 2–3 oz những ngày đầu, ≥4 oz cuối tháng đầu, 5–6 oz lúc 2 tháng, 6–7 oz lúc 3–5 tháng, tới 8 oz từ 6 tháng.
///  - Tài liệu hướng dẫn nuôi dưỡng trong nước (nhà thuốc/bệnh viện, không phải văn bản chính thức của Bộ Y tế):
///    0–4 tuần 60–120 ml/cữ; 5–8 tuần ~120 ml; 9–16 tuần 120–180 ml; 5 tháng 180–210 ml; 6 tháng 180–240 ml; 150–200 ml/kg/ngày.
///  - Kent và cs. 2006 (Pediatrics 117:e387): trẻ bú mẹ hoàn toàn 1–6 tháng bú 4–13 cữ/ngày, 54–234 ml/cữ,
///    tổng 478–1356 ml/ngày, trung bình ~750 ml/ngày.
///  - Hướng dẫn nhi sơ sinh: ngày 1 khoảng 60 ml/kg/ngày, tăng dần tới ~150 ml/kg/ngày vào cuối tuần đầu.
/// Các con số là KHOẢNG THƯỜNG GẶP để tham khảo, cần chuyên gia nhi duyệt trước khi phát hành.
class Range {
  const Range(this.lo, this.hi);
  final double lo;
  final double hi;
  double get mid => (lo + hi) / 2;
  bool contains(double v) => v >= lo && v <= hi;
  String text([String unit = 'ml']) => '${lo.round()}–${hi.round()}$unit';
}

enum Verdict { ok, low, high, veryLow, veryHigh, unknown }

class FeedAssessment {
  FeedAssessment({
    required this.verdict,
    required this.title,
    required this.message,
    required this.range,
    this.tips = const [],
  });
  final Verdict verdict;
  final String title;
  final String message;
  final Range range;
  final List<String> tips;
}

class DayAssessment {
  DayAssessment({required this.total, required this.range, required this.perKg, required this.cap, required this.note});
  final int total;
  final Range range; // ml/ngày
  final Range perKg; // ml/kg/ngày
  final bool cap;
  final String note;
}

class FeedingRef {
  /// Khoảng ml mỗi cữ bình theo tuổi (ngày, đã hiệu chỉnh nếu sinh non).
  static Range perFeed(int ageDays) {
    if (ageDays < 1) return const Range(5, 15);
    if (ageDays < 2) return const Range(10, 30);
    if (ageDays < 3) return const Range(20, 45);
    if (ageDays < 4) return const Range(30, 60);
    if (ageDays < 7) return const Range(45, 90);
    if (ageDays < 28) return const Range(60, 120);
    if (ageDays < 56) return const Range(90, 150);
    if (ageDays < 91) return const Range(120, 180);
    if (ageDays < 151) return const Range(120, 200);
    if (ageDays < 181) return const Range(150, 210);
    if (ageDays < 270) return const Range(150, 240);
    return const Range(120, 240);
  }

  /// Số cữ ăn/ngày thường gặp.
  static Range feedsPerDay(int ageDays) {
    if (ageDays < 30) return const Range(8, 12);
    if (ageDays < 60) return const Range(7, 9);
    if (ageDays < 120) return const Range(6, 8);
    if (ageDays < 180) return const Range(5, 7);
    return const Range(4, 6);
  }

  /// ml/kg/ngày theo ngày tuổi.
  static Range perKgPerDay(int ageDays) {
    if (ageDays < 7) {
      final mid = math.min(150.0, 60.0 + 15.0 * ageDays);
      return Range(mid * .8, mid * 1.2);
    }
    if (ageDays < 120) return const Range(130, 180);
    if (ageDays < 180) return const Range(110, 160);
    return const Range(70, 130); // có ăn dặm
  }

  static DayAssessment day(int ageDays, double weightKg, int totalMl) {
    final kg = perKgPerDay(ageDays);
    var lo = kg.lo * weightKg;
    var hi = kg.hi * weightKg;
    var capped = false;
    if (hi > 960) {
      hi = 960;
      capped = true;
    }
    if (lo > hi) lo = hi * .8;
    String note = '';
    if (ageDays >= 180) note = 'Từ 6 tháng bé đã ăn dặm nên lượng sữa có thể giảm dần.';
    if (ageDays < 7) note = 'Những ngày đầu bé bú ít và tăng dần mỗi ngày.';
    return DayAssessment(total: totalMl, range: Range(lo, hi), perKg: kg, cap: capped, note: note);
  }

  /// Đánh giá một cữ bú bình.
  static FeedAssessment feed(int ml, int ageDays, {required bool expressedMilk}) {
    final r = perFeed(ageDays);
    final tipsHigh = <String>['Cho bú chậm, nghỉ giữa chừng để bé tự báo no.', 'Quan sát dấu hiệu no: quay đầu, ngậm miệng, đẩy bình.'];
    final tipsLow = <String>['Bé có thể chưa đói hoặc ngủ gật khi bú: thử lại sau 20–30 phút.', 'Theo dõi tổng cả ngày và số tã ướt, đừng chỉ nhìn một cữ.'];
    if (ml <= 0) {
      return FeedAssessment(verdict: Verdict.unknown, title: 'Chưa có số ml', message: 'Kéo bình để chọn lượng sữa bé bú.', range: r);
    }
    final lowLimit = expressedMilk ? r.lo * .75 : r.lo;
    if (ml < lowLimit * .6) {
      return FeedAssessment(
        verdict: Verdict.veryLow,
        title: 'Cữ này khá ít',
        message: 'Thường gặp ${r.text()} mỗi cữ ở tuổi này. Bé có thể ăn dặm bữa nhỏ, bú dở hoặc sắp bú thêm. Một cữ ít chưa nói lên điều gì, hãy xem tổng cả ngày.',
        range: r,
        tips: tipsLow,
      );
    }
    if (ml < lowLimit) {
      return FeedAssessment(
        verdict: Verdict.low,
        title: 'Hơi ít so với thường gặp',
        message: 'Khoảng thường gặp ở tuổi này là ${r.text()} mỗi cữ. Bé bú ít hơn một chút vẫn bình thường nếu các cữ khác đủ.',
        range: r,
        tips: tipsLow,
      );
    }
    if (ml > r.hi * 1.3) {
      return FeedAssessment(
        verdict: Verdict.veryHigh,
        title: 'Nhiều hơn khá nhiều',
        message: 'Thường gặp ${r.text()} mỗi cữ. Cho bú quá nhiều một lần có thể khiến bé ọc sữa hoặc khó chịu.',
        range: r,
        tips: tipsHigh,
      );
    }
    if (ml > r.hi) {
      return FeedAssessment(
        verdict: Verdict.high,
        title: 'Hơi nhiều so với thường gặp',
        message: 'Khoảng thường gặp ở tuổi này là ${r.text()} mỗi cữ. Bé đói hơn bình thường (tăng tốc tăng trưởng) cũng có thể bú nhiều hơn.',
        range: r,
        tips: tipsHigh,
      );
    }
    return FeedAssessment(
      verdict: Verdict.ok,
      title: 'Phù hợp với tuổi',
      message: 'Nằm trong khoảng thường gặp ${r.text()} mỗi cữ ở tuổi này.',
      range: r,
    );
  }

  /// Ước tính ml cho một cữ bú trực tiếp theo tuổi (Kent: trung bình 106–126 ml mỗi cữ lúc 1–6 tháng).
  static int breastEstimate(int ageDays, int minutes) {
    final base = ageDays < 4 ? 15 : ageDays < 7 ? 40 : ageDays < 30 ? 80 : ageDays < 90 ? 106 : 120;
    final scale = minutes <= 0 ? 1.0 : (minutes / (ageDays < 30 ? 25 : 20)).clamp(.4, 1.4);
    return (base * scale).round();
  }

  /// Số tã ướt thường gặp.
  static int wetDiapersMin(int ageDays) {
    if (ageDays < 1) return 1;
    if (ageDays < 2) return 2;
    if (ageDays < 3) return 3;
    if (ageDays < 4) return 4;
    if (ageDays < 5) return 5;
    return 6;
  }
}
