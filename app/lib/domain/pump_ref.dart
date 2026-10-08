import 'dart:math' as math;

import 'feeding_ref.dart';

/// Gợi ý và đánh giá lượng sữa hút.
///
/// Nguyên tắc: lượng hút KHÔNG phản ánh toàn bộ lượng sữa mẹ (bé bú trực tiếp lấy sữa hiệu quả hơn máy),
/// và thay đổi theo giờ, stress, giấc ngủ, loại máy. Vì vậy lời đánh giá luôn nhẹ nhàng, so với CHÍNH MẸ trước,
/// rồi mới so với khoảng tham khảo. Nguồn tham khảo: Kent 2006 (bé 1–6 tháng bú ~750 ml/ngày, 478–1356),
/// khoảng 60–150 ml mỗi cữ hút (cả hai bên) khi sữa đã ổn định (từ khoảng 6 tuần) theo các tổng hợp của
/// các nhà sản xuất máy hút sữa và tư vấn viên sữa mẹ. Cần chuyên gia duyệt.
enum PumpVerdict { good, typical, lower, much, firstDays }

class PumpTarget {
  PumpTarget({required this.dailyNeed, required this.dailyGoal, required this.perSession, required this.remainingSessions, required this.perSessionRemaining});
  final Range dailyNeed; // nhu cầu sữa của bé (ml/ngày)
  final double dailyGoal; // mục tiêu hút/ngày
  final double perSession; // mục tiêu mỗi cữ nếu đều
  final int remainingSessions;
  final double perSessionRemaining; // cần mỗi cữ còn lại để chạm mục tiêu
}

class PumpAssessment {
  PumpAssessment({required this.verdict, required this.title, required this.message, required this.range, this.baseline, this.tips = const []});
  final PumpVerdict verdict;
  final String title;
  final String message;
  final Range range;
  final double? baseline;
  final List<String> tips;
}

class PumpRef {
  /// Khoảng thường gặp mỗi cữ hút (tổng hai bên) theo ngày tuổi.
  static Range perSession(int ageDays) {
    if (ageDays < 3) return const Range(0, 20);
    if (ageDays < 7) return const Range(10, 60);
    if (ageDays < 14) return const Range(30, 100);
    if (ageDays < 42) return const Range(45, 120);
    return const Range(60, 150);
  }

  static Range dailyNeed(int ageDays, double weightKg) {
    if (ageDays >= 28 && ageDays <= 190) return const Range(570, 900); // Kent 2006, trung bình ~750
    final d = FeedingRef.day(ageDays, weightKg, 0);
    return Range(d.range.lo, math.min(d.range.hi, 960.0));
  }

  static PumpTarget target({
    required int ageDays,
    required double weightKg,
    required int sessionsPerDay,
    required int pumpShare,
    required double pumpedToday,
    required int sessionsDone,
  }) {
    final need = dailyNeed(ageDays, weightKg);
    final goal = need.mid * pumpShare / 100;
    final per = sessionsPerDay <= 0 ? 0.0 : goal / sessionsPerDay;
    final remain = math.max(0, sessionsPerDay - sessionsDone);
    final perRem = remain == 0 ? 0.0 : math.max(0.0, goal - pumpedToday) / remain;
    return PumpTarget(dailyNeed: need, dailyGoal: goal, perSession: per, remainingSessions: remain, perSessionRemaining: perRem);
  }

  static PumpAssessment assess({required int ml, required int ageDays, double? baseline, required double perSessionGoal}) {
    final r = perSession(ageDays);
    final tips = <String>[
      'Hút khi thư giãn, chườm ấm và massage ngực trước khi hút.',
      'Kiểm tra size phễu và áp lực hút có vừa không.',
      'Uống đủ nước, ngủ nghỉ khi có thể.',
    ];
    if (ageDays < 4) {
      return PumpAssessment(
        verdict: PumpVerdict.firstDays,
        title: 'Những ngày đầu hút được ít là bình thường',
        message: 'Sữa non rất ít nhưng đủ cho dạ dày bé. Hút hoặc cho bú thường xuyên giúp sữa về nhanh hơn.',
        range: r,
      );
    }
    if (ml > r.hi * 1.3) {
      return PumpAssessment(verdict: PumpVerdict.much, title: 'Cữ hút rất tốt', message: 'Nhiều hơn khoảng thường gặp (${r.text()}). Nhớ trữ sữa đúng cách và ghi vào tủ sữa.', range: r, baseline: baseline);
    }
    final base = baseline ?? 0;
    final vsBase = base > 0 ? ml / base : 1.0;
    if (ml >= perSessionGoal * .9 && perSessionGoal > 0 || (base > 0 && vsBase >= 1.1)) {
      return PumpAssessment(verdict: PumpVerdict.good, title: 'Đạt mục tiêu của mẹ', message: 'Lượng này đạt hoặc vượt mục tiêu mỗi cữ (~${perSessionGoal.round()}ml)${base > 0 ? ' và cao hơn mức thường lệ của mẹ (~${base.round()}ml)' : ''}.', range: r, baseline: baseline);
    }
    if (ml >= r.lo && (base == 0 || vsBase >= .75)) {
      return PumpAssessment(verdict: PumpVerdict.typical, title: 'Trong khoảng thường gặp', message: 'Thường gặp ${r.text()} mỗi cữ.${base > 0 ? ' Mẹ thường hút ~${base.round()}ml.' : ''}', range: r, baseline: baseline);
    }
    return PumpAssessment(
      verdict: PumpVerdict.lower,
      title: 'Cữ này ít hơn thường lệ',
      message: base > 0 && vsBase < .75
          ? 'Ít hơn mức thường lệ của mẹ (~${base.round()}ml). Điều này rất hay gặp: lượng hút thay đổi theo giờ, stress và giấc ngủ, và không phản ánh lượng sữa bé nhận khi bú trực tiếp.'
          : 'Thấp hơn khoảng thường gặp (${r.text()}). Máy hút thường lấy được ít hơn bé bú trực tiếp, nên mẹ đừng vội lo.',
      range: r,
      baseline: baseline,
      tips: [
        ...tips,
        'Nếu nhiều ngày liên tiếp thấp hơn nhiều và bé có dấu hiệu bú không đủ (ít tã ướt, không tăng cân), hãy gặp bác sĩ hoặc tư vấn viên sữa mẹ.',
      ],
    );
  }
}
