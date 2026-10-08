import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Phong cách "Pastel trái tim" (kem hồng, thẻ trắng mềm, tranh màu nước), phông Plus Jakarta Sans + Be Vietnam Pro, và các hàm định dạng dùng chung.
/// Phong cách "Kính mờ" cũ được lưu ở docs/THEMES.md.
class GB {
  /// Đang dùng bảng màu tối (đặt ở gốc app; đổi giá trị thì cả cây giao diện được dựng lại).
  static bool dark = false;

  /// Hiệu ứng kính mờ (làm mờ nền phía sau thẻ, tab bar, bảng chọn). Tắt được trong Cài đặt nếu máy yếu.
  static bool glass = true; // có dùng kiểu kính (nền trong mờ, viền sáng, làm mờ thanh dưới và popup)
  static bool glassCards = false; // làm mờ cả nền phía sau từng thẻ (nặng hơn, chỉ ở mức Đầy đủ)

  /// Nền trắng mờ cho các ô nhỏ (trên nền tối chỉ là lớp sáng rất nhẹ).
  static Color w(double a) => dark ? Colors.white.withValues(alpha: a * .11) : Colors.white.withValues(alpha: a);

  /// Màu pastel dùng làm nền: ở chế độ tối được pha với nền tối cho dịu mắt.
  static Color p(Color c) => dark ? _dim(c) : c;

  // Chế độ tối: giữ nguyên sắc, hạ về nền tím đêm vừa phải (độ sáng cố định) để mọi ô pastel cùng một nhịp màu, không bị bùn.
  static Color _dim(Color c) {
    final h = HSLColor.fromColor(c.withValues(alpha: 1));
    // màu ấm (cam, vàng) dễ thành nâu bùn trên nền tím: giảm bão hoà, nâng sáng thành be hồng khói
    final warm = h.hue >= 10 && h.hue <= 70;
    return HSLColor.fromAHSL(c.a, h.hue, warm ? (h.saturation * .4).clamp(0.0, .30) : (h.saturation * .5).clamp(0.0, .42), warm ? .47 : .44).toColor();
  }

  /// Làm dịu một màu nền còn quá sáng ở chế độ tối (màu đã tối thì giữ nguyên, tránh làm tối hai lần).
  static Color tone(Color c) => dark && Color.alphaBlend(c, card).computeLuminance() > .3 ? _dim(c) : c;

  /// Màu chữ/biểu tượng đọc được trên nền [bg] (nền sáng dùng mực đậm, nền tối dùng mực sáng).
  static Color onBg(Color bg) {
    final base = Color.alphaBlend(bg, card);
    return base.computeLuminance() > .5 ? const Color(0xFF2B2634) : ink;
  }

  /// Màu đậm dùng cho chữ/biểu tượng trên nền pastel: ở chế độ tối được làm sáng lên.
  static Color f(Color c) {
    if (!dark) return c;
    final h = HSLColor.fromColor(c.withValues(alpha: 1));
    return HSLColor.fromAHSL(c.a, h.hue, h.saturation.clamp(.35, .85), .82).toColor();
  }

  /// Viền cho ô tô màu [fill]: cùng sắc nhưng đậm hơn (sáng) hoặc sáng hơn (tối) để nổi lên khỏi nền.
  static Color edgeOf(Color fill) {
    final o = fill.withValues(alpha: 1);
    return dark ? Color.lerp(o, Colors.white, .30)!.withValues(alpha: .55) : Color.lerp(o, const Color(0xFF8B4A47), .30)!.withValues(alpha: .70);
  }

  static Color get bg => dark ? const Color(0xFF3A3262) : const Color(0xFFFBEEE8);
  static Color get bgTop => dark ? const Color(0xFF4A4180) : const Color(0xFFFAE6E1);
  static Color get card => dark ? const Color(0xFF50478A) : const Color(0xFFFFFFFF);
  static Color get line => dark ? const Color(0xFF7468B0) : const Color(0xFFDDB9B0);
  static Color get ink => dark ? const Color(0xFFFBF8FF) : const Color(0xFF2B2634);
  static Color get inkMuted => dark ? const Color(0xFFE0D9F7) : const Color(0xFF6F6470);
  static Color get cream => dark ? const Color(0xFF50478A) : const Color(0xFFFFFBF8);
  static Color get title => dark ? const Color(0xFFF0E4FF) : const Color(0xFF8B2F33); // tiêu đề lớn đỏ rượu
  static Color get accent => dark ? const Color(0xFF9B7CF0) : const Color(0xFFE5666F); // hồng san hô
  static Color get accentDeep => dark ? const Color(0xFFD8C8FF) : const Color(0xFFC0434F);
  static Color get accentSoft => dark ? const Color(0xFF5A4F96) : const Color(0xFFFCE4E3);

  static Color get blobPeach => dark ? const Color(0xFF8C5AB0) : const Color(0xFFFCE6DA);
  static Color get blobLilac => dark ? const Color(0xFF6B5FD8) : const Color(0xFFF0EAF8);
  static Color get blobRose => dark ? const Color(0xFFB05AA8) : const Color(0xFFFCE0E2);

  /// Màu sữa trong bình mô phỏng: kem sữa ngà (sữa mẹ), nền bình sáng/tối để sữa luôn nổi rõ.
  static Color get milkBottle => dark ? const Color(0xFFFFE9BD) : const Color(0xFFF3DDAE);
  static Color get milkMom => dark ? const Color(0xFFFFD1A3) : const Color(0xFFFAD6B2);
  static Color get milkFormula => dark ? const Color(0xFFE8E2FF) : const Color(0xFFE4E0F5);
  static Color get sleepIndigo => dark ? const Color(0xFF3A3470) : const Color(0xFF3A3470);

  // ô pastel theo hoạt động (nền) và nút đậm hơn (dấu cộng)
  static Color get pumpTile => dark ? const Color(0xFF7B4B88) : const Color(0xFFFDE3E5);
  static Color get pumpDeep => dark ? const Color(0xFFFFB0DA) : const Color(0xFFEC8A8F);
  static Color get breastTile => dark ? const Color(0xFF84586F) : const Color(0xFFFDEBDF);
  static Color get breastDeep => dark ? const Color(0xFFFFC1AA) : const Color(0xFFEBA77A);
  static Color get bottleTile => dark ? const Color(0xFF5A58A8) : const Color(0xFFEFE6F6);
  static Color get bottleDeep => dark ? const Color(0xFFCFC2FF) : const Color(0xFFB3A3DE);
  static Color get sleepTile => dark ? const Color(0xFF45728A) : const Color(0xFFE3EBDD);
  static Color get sleepDeep => dark ? const Color(0xFFB0F0DC) : const Color(0xFF86AA82);

  // màu theo loại ghi
  static Color get feed => dark ? const Color(0xFFF0A872) : const Color(0xFFF0A872);
  static Color get sleep => dark ? const Color(0xFF9ED6A8) : const Color(0xFF8FB08B);
  static Color get diaper => dark ? const Color(0xFFE9C46A) : const Color(0xFFE9C46A);
  static Color get pump => dark ? const Color(0xFFF59FB5) : const Color(0xFFE58F96);
  static Color get health => dark ? const Color(0xFF8CCBE0) : const Color(0xFF7FB7C9);
  static Color get gold => dark ? const Color(0xFFF2B632) : const Color(0xFFF2B632);

  static Color get ok => dark ? const Color(0xFFA6E8C4) : const Color(0xFF4F6330);
  static Color get okBg => dark ? const Color(0xFF487066) : const Color(0xFFE4EBD2);
  static Color get warn => dark ? const Color(0xFFFFC99A) : const Color(0xFF8A4A1E);
  static Color get warnBg => dark ? const Color(0xFF6F5C78) : const Color(0xFFFBE6D4);
  static Color get alert => dark ? const Color(0xFFFFA9BD) : const Color(0xFF9A3F49);
  static Color get alertBg => dark ? const Color(0xFF80496F) : const Color(0xFFF8DEDF);
  static Color get info => dark ? const Color(0xFFC3C5FF) : const Color(0xFF4A4A8F);
  static Color get infoBg => dark ? const Color(0xFF5656A8) : const Color(0xFFE6E4F6);

  /// Hệ số thu nhỏ chữ chung (gọn như mẫu thiết kế); chữ nhỏ nhất giữ 10,5.
  static const double fs = .9;
  static double _s(double v) => math.max(math.min(v, 10.5), v * fs);

  /// Tiêu đề lớn, số lớn.
  static TextStyle display(double size, {FontWeight w = FontWeight.w800, Color? color}) =>
      TextStyle(fontFamily: 'Inter', fontSize: _s(size), fontWeight: w, color: color ?? ink, height: 1.15, letterSpacing: -.4);

  static TextStyle body(double size, {FontWeight w = FontWeight.w500, Color? color, double? height}) =>
      TextStyle(fontFamily: 'Inter', fontSize: _s(size), fontWeight: w, color: color ?? ink, height: height);

  /// Dòng phụ và câu động viên (chữ thường, nhẹ, nghiêng khi cần).
  static TextStyle script(double size, {Color? color, FontWeight w = FontWeight.w400, bool italic = false}) =>
      TextStyle(fontFamily: 'Inter', fontSize: _s(size), fontWeight: w, color: color ?? inkMuted, height: 1.4, fontStyle: italic ? FontStyle.italic : FontStyle.normal);

  static String two(int n) => n.toString().padLeft(2, '0');
  static String hm(DateTime t) => '${two(t.hour)}:${two(t.minute)}';
  /// Định dạng ngày chuẩn của app: dd/mm/yy, kèm giờ thì dd/mm/yy hh:mm.
  static String dm(DateTime t) => '${two(t.day)}/${two(t.month)}';
  static String dmy(DateTime t) => '${two(t.day)}/${two(t.month)}/${two(t.year % 100)}';
  static String dmyhm(DateTime t) => '${dmy(t)} ${hm(t)}';
  static String dayLabel(DateTime t, [DateTime? now]) {
    final n = now ?? DateTime.now();
    final d = DateTime(t.year, t.month, t.day);
    final today = DateTime(n.year, n.month, n.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Hôm nay';
    if (diff == 1) return 'Hôm qua';
    return const ['Chủ nhật', 'Thứ hai', 'Thứ ba', 'Thứ tư', 'Thứ năm', 'Thứ sáu', 'Thứ bảy'][t.weekday % 7] + ' ${dmy(t)}';
  }

  static String dur(Duration d) {
    if (d.inMinutes < 1) return d.inSeconds < 5 ? '0 phút' : '${d.inSeconds}s';
    if (d.inHours < 1) return '${d.inMinutes} phút';
    final m = d.inMinutes % 60;
    return m == 0 ? '${d.inHours}h' : '${d.inHours}h${two(m)}';
  }

  static String ago(DateTime t, [DateTime? now]) {
    final d = (now ?? DateTime.now()).difference(t);
    if (d.inMinutes < 1) return 'vừa xong';
    if (d.inMinutes < 60) return '${d.inMinutes} phút trước';
    if (d.inHours < 24) {
      final m = d.inMinutes % 60;
      return m == 0 ? '${d.inHours}h trước' : '${d.inHours}h${two(m)} trước';
    }
    return '${d.inDays} ngày trước';
  }

  static String thousands(num n) =>
      n.round().abs().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');

  static String vnd(int n, {bool sign = false}) {
    final p = sign ? (n < 0 ? '−' : (n > 0 ? '+' : '')) : (n < 0 ? '−' : '');
    return '$p${thousands(n)}đ';
  }

  /// Rút gọn tiền: 1,2tr · 350k
  static String vndShort(int n) {
    final a = n.abs();
    if (a >= 1000000000) return '${(a / 1e9).toStringAsFixed(a % 1000000000 == 0 ? 0 : 1).replaceAll('.', ',')} tỷ';
    if (a >= 1000000) return '${(a / 1e6).toStringAsFixed(a % 1000000 == 0 ? 0 : 1).replaceAll('.', ',')}tr';
    if (a >= 1000) return '${(a / 1000).round()}k';
    return '$a';
  }

  static String num1(double v) => v.toStringAsFixed(1).replaceAll('.', ',');
  static String num2(double v) => v.toStringAsFixed(2).replaceAll('.', ',');

  static double clamp01(double v) => math.max(0, math.min(1, v));
}

/// Chế độ nhẹ: tắt làm mờ nền (kính bậc C) để chạy mượt trên máy yếu.
final ValueNotifier<bool> glassLite = ValueNotifier<bool>(false);

class Responsive {
  static EdgeInsets pad(BuildContext c, {double bottom = 130}) =>
      EdgeInsets.fromLTRB(20, MediaQuery.of(c).padding.top + 16, 20, bottom);
}
