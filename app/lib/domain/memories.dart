import 'package:flutter/material.dart';

/// Mốc theo ngày tuổi, quen thuộc với gia đình Việt: đầy tháng, trăm ngày, thôi nôi…
class DayMark {
  const DayMark(this.id, this.title, this.days, this.icon, this.color);
  final String id;
  final String title;
  final int days; // số ngày kể từ ngày sinh
  final IconData icon;
  final Color color;
}

const List<DayMark> kDayMarks = [
  DayMark('d_week1', 'Tròn 1 tuần tuổi', 7, Icons.looks_one_rounded, Color(0xFFDCEBF5)),
  DayMark('d_month1', 'Đầy tháng', 30, Icons.cake_rounded, Color(0xFFFCE0E2)),
  DayMark('d_day100', 'Trăm ngày', 100, Icons.celebration_rounded, Color(0xFFF8E9A8)),
  DayMark('d_month6', 'Nửa tuổi', 183, Icons.star_half_rounded, Color(0xFFE6DEF5)),
  DayMark('d_year1', 'Thôi nôi', 365, Icons.emoji_events_rounded, Color(0xFFFBE3CF)),
];

/// Những lần đầu tiên của bé, mẹ tự ghi khi bé làm được.
class FirstMark {
  const FirstMark(this.id, this.title, this.icon, this.color);
  final String id;
  final String title;
  final IconData icon;
  final Color color;
}

const List<FirstMark> kFirsts = [
  FirstMark('f_smile', 'Nụ cười đầu tiên', Icons.sentiment_very_satisfied_rounded, Color(0xFFF8E9A8)),
  FirstMark('f_laugh', 'Cười thành tiếng', Icons.mood_rounded, Color(0xFFFCE0E2)),
  FirstMark('f_roll', 'Lần đầu lật', Icons.autorenew_rounded, Color(0xFFE6DEF5)),
  FirstMark('f_sit', 'Lần đầu ngồi', Icons.event_seat_rounded, Color(0xFFDCEBF5)),
  FirstMark('f_crawl', 'Lần đầu bò', Icons.child_friendly_rounded, Color(0xFFE4EBD2)),
  FirstMark('f_stand', 'Lần đầu đứng', Icons.accessibility_new_rounded, Color(0xFFFBE3CF)),
  FirstMark('f_step', 'Bước đi đầu tiên', Icons.directions_walk_rounded, Color(0xFFE3E6F6)),
  FirstMark('f_tooth', 'Chiếc răng đầu tiên', Icons.tag_faces_rounded, Color(0xFFFCE0E2)),
  FirstMark('f_word', 'Tiếng gọi mẹ, gọi ba', Icons.record_voice_over_rounded, Color(0xFFF8DEDF)),
  FirstMark('f_solid', 'Bữa ăn dặm đầu tiên', Icons.restaurant_rounded, Color(0xFFF8E9A8)),
  FirstMark('f_clap', 'Lần đầu vỗ tay', Icons.back_hand_rounded, Color(0xFFFBE3CF)),
  FirstMark('f_hair', 'Lần đầu cắt tóc', Icons.content_cut_rounded, Color(0xFFE6DEF5)),
  FirstMark('f_trip', 'Chuyến đi xa đầu tiên', Icons.flight_takeoff_rounded, Color(0xFFDCEBF5)),
  FirstMark('f_swim', 'Lần đầu tắm biển, bơi', Icons.pool_rounded, Color(0xFFDCEBF5)),
];

/// Tìm tên và biểu tượng của một mã mốc đã lưu (mốc ngày, lần đầu hoặc mốc riêng).
({IconData icon, Color color}) memoStyle(String key) {
  for (final d in kDayMarks) {
    if (d.id == key) return (icon: d.icon, color: d.color);
  }
  for (final f in kFirsts) {
    if (f.id == key) return (icon: f.icon, color: f.color);
  }
  if (RegExp(r'^m\d+_\d+$').hasMatch(key)) return (icon: Icons.verified_rounded, color: const Color(0xFFE4EBD2));
  return (icon: Icons.favorite_rounded, color: const Color(0xFFF8DEDF));
}
