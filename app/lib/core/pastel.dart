import 'package:flutter/material.dart';

import 'art_catalog.dart';
import 'kit.dart';
import 'theme.dart';

/// Ô hoạt động pastel có tranh, nhãn và nút tròn dấu cộng (Trang chủ).
class ActivityTile extends StatelessWidget {
  const ActivityTile({super.key, required this.label, required this.art, required this.tile, required this.deep, required this.onTap, this.icon = Icons.add_rounded, this.onLong});
  final String label;
  final String art;
  final Color tile;
  final Color deep;
  final VoidCallback onTap;
  final VoidCallback? onLong;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Pressable(
        scale: .93,
        dim: .85,
        onTap: onTap,
        onLongPress: onLong,
        child: Container(
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.alphaBlend(Colors.white.withValues(alpha: GB.dark ? .16 : .45), tile), tile]),
            border: Border.all(color: deep.withValues(alpha: GB.dark ? .55 : .75), width: 1.4),
            boxShadow: [BoxShadow(color: deep.withValues(alpha: .30), blurRadius: 14, offset: const Offset(0, 6))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(height: 52, child: Art(art, height: 52)),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, maxLines: 1, style: GB.body(13.5, w: FontWeight.w800))),
            ),
            const SizedBox(height: 6),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: deep, shape: BoxShape.circle),
              child: Icon(icon, size: 18, color: Colors.white),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Thẻ có tiêu đề kèm biểu tượng và nút "Xem chi tiết →".
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.title, required this.icon, required this.iconColor, required this.child, this.trailing, this.onTrailing, this.trailingWidget, this.padding = const EdgeInsets.fromLTRB(14, 14, 14, 14)});
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;
  final String? trailing;
  final VoidCallback? onTrailing;
  final Widget? trailingWidget; // thay cho nút chữ, ví dụ ô chọn "Theo ngày"
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 22,
      padding: padding,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 21, color: iconColor),
          const SizedBox(width: 7),
          Expanded(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(title, maxLines: 1, style: GB.display(17, w: FontWeight.w800)))),
          if (trailingWidget != null) ...[const SizedBox(width: 8), trailingWidget!] else if (trailing != null) ...[const SizedBox(width: 8), SoftPill(trailing!, onTap: onTrailing)],
        ]),
        const SizedBox(height: 10),
        child,
      ]),
    );
  }
}

/// Viên thuốc hồng nhạt "Xem chi tiết →".
class SoftPill extends StatelessWidget {
  const SoftPill(this.text, {super.key, this.onTap, this.arrow = true, this.bg, this.fg});
  final String text;
  final VoidCallback? onTap;
  final bool arrow;
  final Color? bg;
  final Color? fg;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: .93,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: bg ?? GB.accentSoft, borderRadius: BorderRadius.circular(18), border: Border.all(color: (fg ?? GB.accentDeep).withValues(alpha: .45), width: 1.1)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(text, style: GB.body(12.5, w: FontWeight.w700, color: fg ?? GB.accentDeep)),
          if (arrow && onTap != null) ...[const SizedBox(width: 4), Icon(Icons.arrow_forward_rounded, size: 14, color: fg ?? GB.accentDeep)],
        ]),
      ),
    );
  }
}

/// Chip "↑ +12% so với hôm qua".
class DeltaChip extends StatelessWidget {
  const DeltaChip(this.text, {super.key, this.up = true, this.hint = 'so với hôm qua'});
  final String text;
  final bool up;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final c = up ? GB.f(const Color(0xFF4F8A4B)) : GB.alert;
    final bg = up ? GB.p(Color(0xFFE3F0DA)) : GB.alertBg;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: GB.edgeOf(bg), width: 1)),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 13, color: c),
            const SizedBox(width: 2),
            Text(text, style: GB.body(12, w: FontWeight.w800, color: c)),
          ]),
        ),
      ),
      const SizedBox(height: 3),
      Text(hint, style: GB.body(11, color: GB.inkMuted)),
    ]);
  }
}

/// Số lớn kèm đơn vị: 420 ml.
class BigNumber extends StatelessWidget {
  const BigNumber(this.value, this.unit, {super.key, this.size = 30, this.color});
  final String value;
  final String unit;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, mainAxisSize: MainAxisSize.min, children: [
        Text(value, style: GB.display(size, color: color ?? GB.ink)),
        const SizedBox(width: 4),
        Text(unit, style: GB.body(size * .55, w: FontWeight.w700, color: GB.inkMuted)),
      ]),
    );
  }
}

/// Phần trăm thay đổi so với kỳ trước; null nếu kỳ trước bằng 0.
({String text, bool up})? pctDelta(num now, num before) {
  if (before <= 0) return null;
  final p = ((now - before) / before * 100).round();
  return (text: '${p >= 0 ? '+' : ''}$p%', up: p >= 0);
}

/// Thẻ nhỏ có biểu tượng tròn pastel bên trái và hai dòng chữ.
class IconBadge extends StatelessWidget {
  const IconBadge({super.key, required this.icon, required this.bg, required this.fg, this.size = 44, this.art});
  final IconData icon;
  final String? art; // tên tranh (tệp ic_<art>.png); nếu chưa có thì dùng icon
  final Color bg;
  final Color fg;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hasArt = art != null && ArtCatalog.has('ic_$art');
    Color disc = GB.tone(bg);
    Color ink = fg == GB.ink ? GB.onBg(disc) : fg;
    if (GB.dark) {
      // Chế độ tối: nền tròn là màu pastel đục tông cùng sắc, biểu tượng là pastel sáng cùng sắc (không trắng xám).
      final h = HSLColor.fromColor(bg.withValues(alpha: 1));
      final tinted = h.saturation > .12;
      disc = HSLColor.fromAHSL(1, h.hue, tinted ? .30 : .08, .35).toColor();
      if (fg == GB.ink) ink = tinted ? HSLColor.fromAHSL(1, h.hue, .72, .82).toColor() : GB.ink;
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: disc, shape: BoxShape.circle),
      child: hasArt ? Padding(padding: EdgeInsets.all(size * .14), child: Art('ic_$art')) : Icon(icon, size: size * .52, color: ink),
    );
  }
}
