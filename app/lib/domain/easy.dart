import '../data/models.dart';
import 'feeding_ref.dart';

/// Nhịp EASY (Eat – Activity – Sleep – Your time) và nhu cầu ngủ theo tuổi.
///
/// Thời gian thức tối đa là mức tham khảo phổ biến trong hướng dẫn luyện nếp (không phải chuẩn y khoa chính thức).
/// Nhu cầu ngủ theo khuyến nghị của National Sleep Foundation (0–3 tháng 14–17h; 4–11 tháng 12–15h; 1–2 tuổi 11–14h).
class Easy {
  /// Khoảng thời gian thức (phút) giữa các cữ ngủ.
  static Range wakeWindow(int ageDays) {
    if (ageDays < 28) return const Range(40, 70);
    if (ageDays < 60) return const Range(60, 90);
    if (ageDays < 90) return const Range(75, 105);
    if (ageDays < 120) return const Range(90, 120);
    if (ageDays < 150) return const Range(105, 150);
    if (ageDays < 180) return const Range(120, 165);
    if (ageDays < 270) return const Range(150, 210);
    return const Range(180, 240);
  }

  static Range napsPerDay(int ageDays) {
    if (ageDays < 90) return const Range(4, 5);
    if (ageDays < 180) return const Range(3, 4);
    if (ageDays < 270) return const Range(2, 3);
    return const Range(2, 2);
  }

  static Range sleepHours(int ageDays) {
    if (ageDays < 120) return const Range(14, 17);
    if (ageDays < 365) return const Range(12, 15);
    return const Range(11, 14);
  }

  /// Độ dài một vòng EASY tự chọn theo tuổi (phút): 150 (E2.5), 180 (E3), 210 (E3.5), 240 (E4).
  static int autoCycle(int ageDays) {
    if (ageDays < 45) return 150;
    if (ageDays < 120) return 180;
    if (ageDays < 210) return 210;
    return 240;
  }

  /// Độ dài vòng EASY (phút) theo cài đặt: tự chọn theo tuổi hoặc E2.5/E3/E3.5/E4.
  static int cycleFor(Settings s, int ageDays) {
    if (s.easyAuto) return autoCycle(ageDays);
    final v = s.easy < 10 ? s.easy * 10 : s.easy; // 25, 30, 35, 40
    return v * 6;
  }

  static String label(int cycleMinutes) => 'E${cycleMinutes / 60}'.replaceAll('.0', '');

  /// Một vòng: ăn ~20–30p, chơi, ngủ phần còn lại.
  static ({int eat, int activity, int sleep}) split(int cycleMinutes, int ageDays) {
    final eat = ageDays < 60 ? 30 : 25;
    final wake = wakeWindow(ageDays).mid.round();
    final activity = (wake - eat).clamp(15, 180);
    final sleep = (cycleMinutes - eat - activity).clamp(20, 240);
    return (eat: eat, activity: activity, sleep: sleep);
  }
}
