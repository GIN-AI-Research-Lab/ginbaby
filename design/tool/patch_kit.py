# -*- coding: utf-8 -*-
"""Chuyển kit.dart sang phong cách Pastel trái tim (chạy một lần)."""
p = r'F:\Project Ai\GinBaby\app\lib\core\kit.dart'
s = open(p, encoding='utf-8').read()

BG_CARD = r"""/// Hình minh hoạ màu nước trong assets/art (đã tách nền).
class Art extends StatelessWidget {
  const Art(this.name, {super.key, this.width, this.height, this.fit = BoxFit.contain, this.alignment = Alignment.center});
  final String name;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/art/$name.png',
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        filterQuality: FilterQuality.medium,
        excludeFromSemantics: true,
        errorBuilder: (_, __, ___) => SizedBox(width: width, height: height),
      );
}

/// Nền kem hồng dịu, có vài vệt màu rất nhẹ (không dùng làm mờ nên chạy nhẹ).
class GlassBackground extends StatelessWidget {
  const GlassBackground({super.key, required this.child});
  final Widget child;

  Widget _blob(Color c, double size) => RepaintBoundary(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [c.withValues(alpha: .75), c.withValues(alpha: 0)]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [GB.bgTop, GB.bg, GB.bg])))),
        Positioned(right: -140, top: -120, child: _blob(GB.blobPeach, 420)),
        Positioned(left: -160, top: 420, child: _blob(GB.blobLilac, 420)),
        Positioned(right: -120, bottom: -140, child: _blob(GB.blobRose, 380)),
        Positioned.fill(child: child),
      ],
    );
  }
}

/// Thẻ trắng mềm: bo tròn, bóng rất nhẹ. (Tên cũ GlassCard giữ lại để các màn không phải đổi.)
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.radius = 24,
    this.padding = const EdgeInsets.all(16),
    this.opacity = .5,
    this.blur = 20,
    this.tint,
    this.onTap,
    this.shadow = true,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double opacity;
  final double blur;
  final Color? tint;
  final VoidCallback? onTap;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);
    Widget card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: tint != null ? tint!.withValues(alpha: .95) : GB.card,
        borderRadius: br,
        boxShadow: shadow ? [BoxShadow(color: const Color(0xFFD9A79F).withValues(alpha: .20), blurRadius: 18, offset: const Offset(0, 6))] : null,
      ),
      child: child,
    );
    if (onTap != null) {
      card = GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: card);
    }
    return card;
  }
}

"""

HEADERS = r"""/// Tiêu đề màn con: nút quay lại hồng nhạt, tên đỏ rượu, dòng phụ viết tay, có thể kèm tranh bên phải.
class BackHeader extends StatelessWidget {
  const BackHeader(this.title, {super.key, this.actions = const [], this.subtitle, this.art, this.artWidth = 150});
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final String? art;
  final double artWidth;

  @override
  Widget build(BuildContext context) {
    final back = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).maybePop(),
      child: Semantics(
        button: true,
        label: 'Quay lại',
        child: Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(color: GB.accentSoft, shape: BoxShape.circle),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: GB.title),
        ),
      ),
    );
    final texts = Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: GB.display(art != null ? 34 : 26, color: GB.title)),
      if (subtitle != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(subtitle!, style: GB.script(art != null ? 14 : 12.5))),
    ]);
    if (art == null) {
      return Row(children: [back, const SizedBox(width: 12), Expanded(child: texts), ...actions]);
    }
    return SizedBox(
      height: 170,
      child: Stack(children: [
        Positioned(right: -6, top: 0, bottom: 0, child: Art(art!, width: artWidth, alignment: Alignment.topRight, fit: BoxFit.contain)),
        Positioned(left: 0, top: 0, child: back),
        Positioned(left: 0, right: artWidth - 10, bottom: 14, child: texts),
        if (actions.isNotEmpty) Positioned(right: 0, top: 0, child: Row(children: actions)),
      ]),
    );
  }
}

/// Trang con (đẩy lên trên tab) có nền kem hồng và cuộn.
class SubPage extends StatelessWidget {
  const SubPage({super.key, required this.title, required this.children, this.subtitle, this.actions = const [], this.bottom, this.padBottom = 40, this.art, this.artWidth = 150});
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final List<Widget> actions;
  final Widget? bottom;
  final double padBottom;
  final String? art;
  final double artWidth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GB.bg,
      body: GlassBackground(
        child: Column(children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 14, 20, 8),
            child: BackHeader(title, subtitle: subtitle, actions: actions, art: art, artWidth: artWidth),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(20, 8, 20, padBottom + (bottom != null ? 80 : 0)),
              children: children,
            ),
          ),
          if (bottom != null)
            Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + MediaQuery.of(context).padding.bottom),
              child: bottom,
            ),
        ]),
      ),
    );
  }
}

"""

def between(a_marker, b_marker, new):
    global s
    a = s.index(a_marker)
    b = s.index(b_marker)
    s = s[:a] + new + s[b:]

between("/// Nền có các mảng màu", "/// Thanh chọn kiểu viên thuốc", BG_CARD)
between("/// Tiêu đề màn con có nút quay lại.", "/// Xếp các ô thành từng hàng", HEADERS)


def rep(old, new):
    global s
    assert old in s, old[:60]
    s = s.replace(old, new)

# Seg
rep("decoration: BoxDecoration(color: i == index ? GB.ink : Colors.transparent, borderRadius: BorderRadius.circular((height - 8) / 2)),",
    "decoration: BoxDecoration(color: i == index ? GB.accent : Colors.transparent, borderRadius: BorderRadius.circular((height - 8) / 2)),")
rep("style: GB.body(13.5, w: i == index ? FontWeight.w700 : FontWeight.w600, color: i == index ? GB.cream : GB.inkMuted)",
    "style: GB.body(13.5, w: i == index ? FontWeight.w800 : FontWeight.w600, color: i == index ? Colors.white : GB.inkMuted)")
# PillChip
rep("color: on ? (color ?? GB.ink) : Colors.white.withValues(alpha: .62),\n            borderRadius: BorderRadius.circular(height / 2),\n            border: Border.all(color: Colors.white.withValues(alpha: .8)),",
    "color: on ? (color ?? GB.accent) : GB.card,\n            borderRadius: BorderRadius.circular(height / 2),\n            border: Border.all(color: on ? Colors.transparent : GB.line),")
rep("if (icon != null) ...[Icon(icon, size: 16, color: on ? GB.cream : GB.ink), const SizedBox(width: 6)],\n              Text(label, style: GB.body(13.5, w: on ? FontWeight.w700 : FontWeight.w600, color: on ? (color == null ? GB.cream : GB.ink) : GB.ink)),",
    "if (icon != null) ...[Icon(icon, size: 16, color: on ? (color == null ? Colors.white : GB.ink) : GB.ink), const SizedBox(width: 6)],\n              Text(label, style: GB.body(13.5, w: on ? FontWeight.w800 : FontWeight.w600, color: on ? (color == null ? Colors.white : GB.ink) : GB.ink)),")
# BigButton
rep("const BigButton(this.label, {super.key, required this.onTap, this.icon, this.color = GB.ink, this.fg = GB.cream, this.height = 54, this.enabled = true});",
    "const BigButton(this.label, {super.key, required this.onTap, this.icon, this.color = GB.accent, this.fg = Colors.white, this.height = 54, this.enabled = true});")
rep("    final on = enabled && onTap != null;\n    return Semantics(\n      button: true,\n      enabled: on,",
    "    final on = enabled && onTap != null;\n    // Nút chính (hồng san hô) luôn chữ trắng cho dễ đọc.\n    final fg = color == GB.accent ? Colors.white : this.fg;\n    return Semantics(\n      button: true,\n      enabled: on,")
# RoundIconButton
rep("color: filled ? (color ?? GB.ink) : Colors.white.withValues(alpha: .62),\n            border: filled ? null : Border.all(color: const Color(0xFFCDBBA3)),",
    "color: filled ? (color ?? GB.accent) : GB.card,\n            border: filled ? null : Border.all(color: GB.line, width: 1.5),")
rep("child: Icon(icon, size: size * .46, color: filled ? GB.cream : GB.ink),",
    "child: Icon(icon, size: size * .46, color: filled ? Colors.white : GB.ink),")
# field
rep("fillColor: Colors.white.withValues(alpha: .62),", "fillColor: GB.card,")
rep("borderSide: BorderSide(color: Colors.white.withValues(alpha: .8))),\n        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: Colors.white.withValues(alpha: .8))),",
    "borderSide: const BorderSide(color: GB.line)),\n        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: GB.line)),")
# sheet
rep("        child: GlassCard(\n          radius: 30,\n          opacity: .86,\n          padding: EdgeInsets.zero,",
    "        child: GlassCard(\n          radius: 30,\n          padding: EdgeInsets.zero,")
rep("import 'dart:ui';\n\n", "")
open(p, 'w', encoding='utf-8').write(s)
print('ok')
