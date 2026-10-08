import 'dart:math' as math;
import 'package:flutter/cupertino.dart' show CupertinoPageRoute;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/app_state.dart';
import 'art_catalog.dart';
import 'pastel.dart';
import 'theme.dart';

/// Hiệu ứng chạm kiểu iOS: nhấn xuống thì co nhẹ và mờ đi, thả ra thì bật lại mềm (lò xo), kèm rung nhẹ trên điện thoại.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap, this.onLongPress, this.scale = .95, this.dim = .78, this.haptic = true, this.behavior = HitTestBehavior.opaque});
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale; // tỉ lệ khi nhấn (thẻ lớn nên dùng .985)
  final double dim; // độ đậm khi nhấn
  final bool haptic;
  final HitTestBehavior behavior;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;
  DateTime _since = DateTime.now();

  void _press() {
    _since = DateTime.now();
    if (!_down) setState(() => _down = true);
  }

  // Chạm rất nhanh vẫn giữ trạng thái nhấn đủ lâu để mắt kịp thấy.
  void _release() {
    final left = 90 - DateTime.now().difference(_since).inMilliseconds;
    if (left > 0) {
      Future.delayed(Duration(milliseconds: left), () {
        if (mounted) setState(() => _down = false);
      });
    } else if (_down) {
      setState(() => _down = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null && widget.onLongPress == null) return widget.child;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: (_) => _press(),
      onTapUp: (_) => _release(),
      onTapCancel: _release,
      onTap: widget.onTap == null
          ? null
          : () {
              if (widget.haptic) HapticFeedback.selectionClick();
              widget.onTap!();
            },
      onLongPress: widget.onLongPress == null
          ? null
          : () {
              if (widget.haptic) HapticFeedback.mediumImpact();
              widget.onLongPress!();
            },
      child: reduce
          ? widget.child
          : AnimatedScale(
              scale: _down ? widget.scale : 1,
              duration: Duration(milliseconds: _down ? 90 : 320),
              curve: _down ? Curves.easeOut : Curves.elasticOut,
              child: AnimatedOpacity(
                opacity: _down ? widget.dim : 1,
                duration: Duration(milliseconds: _down ? 70 : 220),
                child: widget.child,
              ),
            ),
    );
  }
}

/// Nút tròn đổi nhanh sáng/tối (mặt trời khi đang tối, mặt trăng khi đang sáng). Đổi thì dựng lại cả giao diện.
class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key, this.size = 38});
  final double size;

  @override
  Widget build(BuildContext context) {
    final dark = GB.dark;
    return Semantics(
      button: true,
      label: dark ? 'Chuyển sang chế độ sáng' : 'Chuyển sang chế độ tối',
      child: Pressable(
        scale: .88,
        onTap: () {
          app.settings.themeMode = dark ? 1 : 2;
          app.settingsChanged();
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: GB.glass ? (dark ? Colors.white.withValues(alpha: .16) : Colors.white.withValues(alpha: .75)) : GB.card,
            border: Border.all(color: GB.glass ? (dark ? Colors.white.withValues(alpha: .3) : Colors.white) : GB.edgeOf(GB.line), width: 1.2),
            boxShadow: [BoxShadow(color: const Color(0xFFC98C84).withValues(alpha: dark ? .10 : .20), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Icon(dark ? Icons.wb_sunny_rounded : Icons.nightlight_round, size: size * .52, color: dark ? const Color(0xFFF2C46B) : const Color(0xFF7C6FC0)),
        ),
      ),
    );
  }
}

/// Hình minh hoạ màu nước trong assets/art (đã tách nền).
class Art extends StatelessWidget {
  const Art(this.name, {super.key, this.width, this.height, this.fit = BoxFit.contain, this.alignment = Alignment.center, this.plate = true});
  final String name;
  final bool plate; // chế độ tối: có quầng sáng phía sau
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final darkArt = GB.dark && ArtCatalog.hasDark(name);
    final dpr = math.min(MediaQuery.maybeDevicePixelRatioOf(context) ?? 2, 2.0);
    final img = Image.asset(
      darkArt ? 'assets/art_dark/$name.png' : 'assets/art/$name.png',
      width: width,
      height: height,
      cacheWidth: width != null ? (width! * dpr).ceil() : null,
      cacheHeight: width == null && height != null ? (height! * dpr).ceil() : null,
      fit: fit,
      alignment: alignment,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
      errorBuilder: (_, __, ___) => SizedBox(width: width, height: height),
    );
    if (!GB.dark || !plate || darkArt) return img;
    // Tranh chưa có bản tối (tệp mới thêm): đặt một quầng kem mờ phía sau để màu không bị rối.
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(radius: .62, colors: [Color(0xF2FFF1E9), Color(0xE6FFF1E9), Color(0x00FFF1E9)], stops: [0, .72, 1]),
      ),
      child: img,
    );
  }
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
            gradient: RadialGradient(colors: [c.withValues(alpha: GB.dark ? .85 : .95), c.withValues(alpha: 0)]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [GB.bgTop, GB.bg, GB.bg])))),
        Positioned(right: -140, top: -120, child: _blob(GB.blobPeach, 420)),
        Positioned(left: -160, top: 420, child: _blob(GB.blobLilac, 420)),
        Positioned(right: -120, bottom: -140, child: _blob(GB.blobRose, 380)),
        Positioned(left: -100, bottom: 60, child: _blob(GB.blobPeach, 300)),
        Positioned(right: -80, top: 560, child: _blob(GB.blobLilac, 320)),
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
    this.padding = const EdgeInsets.all(14),
    this.opacity = .5,
    this.blur = 20,
    this.tint,
    this.onTap,
    this.shadow = true,
    this.forceBlur = false,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double opacity;
  final double blur;
  final Color? tint;
  final VoidCallback? onTap;
  final bool shadow;
  final bool forceBlur; // luôn làm mờ nền phía sau (popup), kể cả khi thẻ thường không làm mờ

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);
    final glass = GB.glass && blur > 0;
    final cheap = !GB.glassCards && !forceBlur; // nền trong nhưng không làm mờ, không đổ bóng: nhẹ nhất
    final Widget inner = Container(
      padding: padding,
      decoration: glass
          ? BoxDecoration(
              borderRadius: br,
              // kính: lớp trắng mờ có độ sáng chuyển từ góc trên trái, viền sáng như ánh phản chiếu mép kính
              gradient: tint != null
                  ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [tint!.withValues(alpha: .80), tint!.withValues(alpha: .62)])
                  : LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: GB.dark ? [Colors.white.withValues(alpha: .20), Colors.white.withValues(alpha: .09)] : [Colors.white.withValues(alpha: .78), Colors.white.withValues(alpha: .48)]),
              border: Border.all(color: GB.dark ? Colors.white.withValues(alpha: .30) : const Color(0xFFD3A097).withValues(alpha: .60), width: 1.2),
            )
          : BoxDecoration(
              color: tint != null ? tint!.withValues(alpha: .95) : GB.card,
              borderRadius: br,
              border: Border.all(color: tint != null ? GB.edgeOf(tint!) : GB.line, width: 1.2),
            ),
      child: child,
    );
    Widget card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: shadow && !cheap ? [BoxShadow(color: (GB.dark ? const Color(0xFF120A2E) : const Color(0xFFC98C84)).withValues(alpha: GB.dark ? .35 : (glass ? .22 : .20)), blurRadius: GB.glassCards ? 22 : 12, offset: const Offset(0, 4))] : null,
      ),
      child: glass && (GB.glassCards || forceBlur) ? ClipRRect(borderRadius: br, child: BackdropFilter(filter: ImageFilter.blur(sigmaX: blur * .7, sigmaY: blur * .7), child: inner)) : inner,
    );
    if (onTap != null) {
      card = Pressable(scale: .985, dim: .88, onTap: onTap, child: card);
    }
    return card;
  }
}

/// Thanh chọn kiểu viên thuốc (segmented).
class Seg extends StatelessWidget {
  const Seg({super.key, required this.labels, required this.index, required this.onChanged, this.height = 40});
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: height / 2 + 2,
      padding: const EdgeInsets.all(4),
      blur: 14,
      child: Row(children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: Pressable(
              scale: .94,
              dim: .8,
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: height - 8,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: i == index ? GB.accent : Colors.transparent, borderRadius: BorderRadius.circular((height - 8) / 2)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(labels[i], maxLines: 1, style: GB.body(13.5, w: i == index ? FontWeight.w800 : FontWeight.w600, color: i == index ? Colors.white : GB.inkMuted)),
                  ),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

/// Chip bấm được (chọn một hoặc nhiều).
class PillChip extends StatelessWidget {
  const PillChip({super.key, required this.label, required this.on, required this.onTap, this.color, this.height = 36, this.icon, this.hPad = 14, this.dot, this.iconColor});
  final String label;
  final bool on;
  final VoidCallback onTap;
  final Color? color;
  final double height;
  final IconData? icon;
  final double hPad;
  final Color? dot; // chấm màu đầu chip (nhận biết nhanh nhãn)
  final Color? iconColor; // màu biểu tượng khi chip chưa chọn

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: on,
      label: label,
      child: Pressable(
        scale: .93,
        onTap: onTap,
        child: Container(
          height: height,
          padding: EdgeInsets.symmetric(horizontal: hPad),
          decoration: BoxDecoration(
            color: on ? (color ?? GB.accent) : GB.card,
            borderRadius: BorderRadius.circular(height / 2),
            border: Border.all(color: on ? Colors.transparent : GB.edgeOf(GB.line), width: 1.2),
          ),
          child: Center(
            widthFactor: 1,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (dot != null) ...[Container(width: 9, height: 9, decoration: BoxDecoration(color: dot, shape: BoxShape.circle, border: Border.all(color: on ? Colors.white.withValues(alpha: .9) : GB.edgeOf(dot!), width: 1))), const SizedBox(width: 6)],
              if (icon != null) ...[Icon(icon, size: 16, color: on ? (color == null ? Colors.white : GB.ink) : (iconColor ?? GB.ink)), const SizedBox(width: 6)],
              Text(label, style: GB.body(13.5, w: on ? FontWeight.w800 : FontWeight.w600, color: on ? (color == null ? Colors.white : GB.ink) : GB.ink)),
            ]),
          ),
        ),
      ),
    );
  }
}

class BigButton extends StatelessWidget {
  const BigButton(this.label, {super.key, required this.onTap, this.icon, this.color, this.fg, this.height = 48, this.enabled = true});
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? color;
  final Color? fg;
  final double height;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final on = enabled && onTap != null;
    // Nút chính (hồng san hô) luôn chữ trắng cho dễ đọc.
    final color = this.color ?? GB.accent;
    final fg = color == GB.accent ? Colors.white : (this.fg ?? Colors.white);
    return Semantics(
      button: true,
      enabled: on,
      label: label,
      child: Pressable(
        scale: .965,
        dim: .86,
        onTap: on ? onTap : null,
        child: Opacity(
          opacity: on ? 1 : .45,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(height / 2),
              border: Border.all(color: color.a < .95 ? GB.edgeOf(GB.line) : Colors.white.withValues(alpha: .35), width: 1.2),
              boxShadow: [BoxShadow(color: color.withValues(alpha: color.a < .95 ? .12 : .38), blurRadius: 14, offset: const Offset(0, 6))],
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (icon != null) ...[Icon(icon, size: 20, color: fg), const SizedBox(width: 8)],
              Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, style: GB.body(16, w: FontWeight.w700, color: fg)))),
            ]),
          ),
        ),
      ),
    );
  }
}

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({super.key, required this.icon, required this.onTap, required this.label, this.filled = false, this.size = 42, this.color, this.iconColor});
  final IconData icon;
  final VoidCallback onTap;
  final String label;
  final bool filled;
  final double size;
  final Color? color;
  final Color? iconColor; // màu biểu tượng khi nút không tô đặc (kiểu kính)

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Pressable(
        scale: .9,
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? (color ?? GB.accent) : (GB.glass ? (GB.dark ? Colors.white.withValues(alpha: .16) : Colors.white.withValues(alpha: .78)) : GB.card),
            border: filled ? null : Border.all(color: GB.edgeOf(GB.line), width: 1.3),
            boxShadow: filled ? null : [BoxShadow(color: const Color(0xFFC98C84).withValues(alpha: GB.dark ? .10 : .18), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Icon(icon, size: size * .46, color: filled ? Colors.white : (iconColor ?? GB.ink)),
        ),
      ),
    );
  }
}

class Orb extends StatelessWidget {
  const Orb({super.key, required this.icon, required this.color, this.size = 36});
  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: GB.tone(color), shape: BoxShape.circle),
        child: Icon(icon, size: size * .52, color: GB.onBg(GB.tone(color))),
      );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing, this.onTrailing, this.padTop = 18});
  final String text;
  final String? trailing;
  final VoidCallback? onTrailing;
  final double padTop;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(top: padTop, bottom: 8),
        child: Row(children: [
          Expanded(child: Text(text, style: GB.display(18, w: FontWeight.w700))),
          if (trailing != null)
            Pressable(
              scale: .94,
              onTap: onTrailing,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Text(trailing!, style: GB.body(13, w: FontWeight.w700, color: GB.accentDeep)),
              ),
            ),
        ]),
      );
}

class Tag extends StatelessWidget {
  const Tag(this.text, {super.key, this.bg, this.fg});
  final String text;
  final Color? bg;
  final Color? fg;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: bg ?? GB.p(const Color(0xFFFBE3CF)), borderRadius: BorderRadius.circular(9), border: Border.all(color: GB.edgeOf(bg ?? GB.p(const Color(0xFFFBE3CF))), width: 1)),
        child: Text(text, style: GB.body(11.5, w: FontWeight.w700, color: fg ?? GB.f(const Color(0xFF8A4A1E)))),
      );
}

/// Thanh tiến độ mảnh có vùng "khoảng thường gặp" đánh dấu.
class RangeBar extends StatelessWidget {
  const RangeBar({super.key, required this.value, required this.lo, required this.hi, this.maxV, this.color});
  final double value;
  final double lo;
  final double hi;
  final double? maxV;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final mx = maxV ?? (hi * 1.35);
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      double x(double v) => (v / mx).clamp(0.0, 1.0) * w;
      return SizedBox(
        height: 22,
        child: Stack(children: [
          Positioned(left: 0, right: 0, top: 8, child: Container(height: 8, decoration: BoxDecoration(color: GB.w(.7), borderRadius: BorderRadius.circular(4)))),
          Positioned(left: x(lo), width: (x(hi) - x(lo)).clamp(2.0, w), top: 5, child: Container(height: 14, decoration: BoxDecoration(color: GB.okBg, borderRadius: BorderRadius.circular(7), border: Border.all(color: const Color(0xFF9DB36B), width: 1)))),
          Positioned(left: 0, width: x(value), top: 8, child: AnimatedContainer(duration: const Duration(milliseconds: 220), height: 8, decoration: BoxDecoration(color: color ?? GB.accent, borderRadius: BorderRadius.circular(4)))),
        ]),
      );
    });
  }
}

/// Hộp thông báo mức độ (ổn / lưu ý / cảnh báo / thông tin).
enum Level { ok, note, alert, info }

class Callout extends StatelessWidget {
  const Callout({super.key, required this.level, required this.title, this.body, this.children = const [], this.icon});
  final Level level;
  final String title;
  final String? body;
  final List<Widget> children;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    late Color bg, fg;
    late IconData ic;
    switch (level) {
      case Level.ok:
        bg = GB.okBg;
        fg = GB.ok;
        ic = Icons.check_circle_rounded;
      case Level.note:
        bg = GB.warnBg;
        fg = GB.warn;
        ic = Icons.info_rounded;
      case Level.alert:
        bg = GB.alertBg;
        fg = GB.alert;
        ic = Icons.warning_amber_rounded;
      case Level.info:
        bg = GB.infoBg;
        fg = GB.info;
        ic = Icons.lightbulb_rounded;
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg.withValues(alpha: .92), borderRadius: BorderRadius.circular(18), border: Border.all(color: GB.edgeOf(bg.withValues(alpha: .92)), width: 1)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon ?? ic, color: fg, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GB.body(14.5, w: FontWeight.w800, color: fg)),
            if (body != null) Padding(padding: const EdgeInsets.only(top: 3), child: Text(body!, style: GB.body(13, color: fg, height: 1.45))),
            ...children,
          ]),
        ),
      ]),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState(this.text, {super.key, this.icon = Icons.inbox_rounded});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(children: [
          Icon(icon, size: 34, color: GB.inkMuted.withValues(alpha: .6)),
          const SizedBox(height: 8),
          Text(text, textAlign: TextAlign.center, style: GB.body(13.5, color: GB.inkMuted)),
        ]),
      );
}

/// Tiêu đề màn con: nút quay lại hồng nhạt, tên đỏ rượu, dòng phụ viết tay, có thể kèm tranh bên phải.
class BackHeader extends StatelessWidget {
  const BackHeader(this.title, {super.key, this.actions = const [], this.subtitle, this.art, this.artWidth = 150, this.titleArt});
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final String? art;
  final double artWidth;
  final String? titleArt; // tranh nhỏ cạnh tên màn

  @override
  Widget build(BuildContext context) {
    final back = Pressable(
      scale: .88,
      onTap: () => Navigator.of(context).maybePop(),
      child: Semantics(
        button: true,
        label: 'Quay lại',
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: GB.accentSoft, shape: BoxShape.circle),
          child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: GB.title),
        ),
      ),
    );
    final texts = Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(title, maxLines: 1, style: GB.display(art != null ? (artWidth <= 120 ? 26 : 30) : 24, color: GB.title)),
          if (titleArt != null) ...[const SizedBox(width: 6), Art(titleArt!, height: 28)],
        ]),
      ),
      if (subtitle != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(subtitle!, style: GB.script(art != null ? 13 : 12))),
    ]);
    if (art == null) {
      return Row(children: [back, const SizedBox(width: 12), Expanded(child: texts), ...actions]);
    }
    return SizedBox(
      height: artWidth <= 120 ? 112 : 148,
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
  const SubPage({super.key, required this.title, required this.children, this.subtitle, this.actions = const [], this.bottom, this.padBottom = 40, this.art, this.artWidth = 150, this.titleArt});
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final List<Widget> actions;
  final Widget? bottom;
  final double padBottom;
  final String? art;
  final double artWidth;
  final String? titleArt;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GB.bg,
      body: GlassBackground(
        child: Column(children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 10, 16, 6),
            child: BackHeader(title, subtitle: subtitle, actions: actions, art: art, artWidth: artWidth, titleArt: titleArt),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 6, 16, padBottom + (bottom != null ? 72 : 0)),
              children: children,
            ),
          ),
          if (bottom != null)
            Padding(
              padding: EdgeInsets.fromLTRB(16, 6, 16, 14 + MediaQuery.of(context).padding.bottom),
              child: bottom,
            ),
        ]),
      ),
    );
  }
}

/// Xếp các ô thành từng hàng 2 ô cao bằng nhau, tự cao theo chữ (không cắt chữ).
List<Widget> pairRows(List<Widget> items, {double gap = 10}) {
  final out = <Widget>[];
  for (var i = 0; i < items.length; i += 2) {
    out.add(Padding(
      padding: EdgeInsets.only(bottom: i + 2 < items.length ? gap : 0),
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: items[i]),
          SizedBox(width: gap),
          Expanded(child: i + 1 < items.length ? items[i + 1] : const SizedBox.shrink()),
        ]),
      ),
    ));
  }
  return out;
}

Future<T?> openPage<T>(BuildContext context, Widget page) {
  return Navigator.of(context).push<T>(CupertinoPageRoute<T>(builder: (_) => page));
}

/// Nút X đóng ở góc trên bên phải của mọi popup (bảng trượt lên, hộp thoại).
class PopupCloseButton extends StatelessWidget {
  const PopupCloseButton({super.key, this.size = 34, this.onTap});
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Đóng',
        child: Pressable(
          scale: .88,
          onTap: onTap ?? () => Navigator.of(context).maybePop(),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: GB.dark ? Colors.white.withValues(alpha: .14) : Colors.white.withValues(alpha: .85),
              border: Border.all(color: GB.edgeOf(GB.line), width: 1.2),
            ),
            child: Icon(Icons.close_rounded, size: size * .56, color: GB.ink),
          ),
        ),
      );
}

Future<T?> showGlassSheet<T>(BuildContext context, {required WidgetBuilder builder, double maxHeightFactor = .92}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(10, 0, 10, 10 + MediaQuery.of(ctx).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * maxHeightFactor),
        child: GlassCard(
          radius: 30,
          padding: EdgeInsets.zero,
          forceBlur: true,
          child: Stack(children: [
            SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 48, 20, 20), child: builder(ctx)),
            const Positioned(right: 12, top: 10, child: PopupCloseButton()),
          ]),
        ),
      ),
    ),
  );
}

/// Hộp thoại kiểu GinBaby: giống AlertDialog nhưng luôn có nút X đóng ở góc trên bên phải.
class GlassAlert extends StatelessWidget {
  const GlassAlert({super.key, this.backgroundColor, this.shape, this.title, this.content, this.actions});
  final Color? backgroundColor;
  final ShapeBorder? shape;
  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: backgroundColor ?? GB.cream,
        shape: shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(22, 16, 12, 0),
        title: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Padding(padding: const EdgeInsets.only(top: 6), child: title ?? const SizedBox.shrink())),
          const SizedBox(width: 8),
          const PopupCloseButton(size: 32),
        ]),
        content: content,
        actions: actions,
      );
}

void toast(BuildContext context, String msg, {VoidCallback? undo}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg, style: GB.body(14, color: GB.cream)),
      action: undo == null ? null : SnackBarAction(label: 'Hoàn tác', textColor: GB.accent, onPressed: undo),
      backgroundColor: GB.ink,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      duration: Duration(seconds: undo == null ? 2 : 5),
    ));
}

Future<bool> confirmDialog(BuildContext context, String title, String message, {String ok = 'Xoá'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => GlassAlert(
      backgroundColor: GB.cream,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(title, style: GB.display(20, w: FontWeight.w700)),
      content: Text(message, style: GB.body(14, color: GB.inkMuted)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Huỷ', style: GB.body(14, w: FontWeight.w700, color: GB.inkMuted))),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ok, style: GB.body(14, w: FontWeight.w800, color: GB.alert))),
      ],
    ),
  );
  return r ?? false;
}

/// Ô nhập chữ kiểu kính.
class GlassField extends StatelessWidget {
  const GlassField({super.key, required this.controller, required this.label, this.keyboard, this.maxLines = 1, this.suffix, this.onChanged, this.hint, this.icon, this.iconColor});
  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboard;
  final int maxLines;
  final String? suffix;
  final ValueChanged<String>? onChanged;
  final IconData? icon; // biểu tượng đầu ô để nhận ra loại thông tin
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      onChanged: onChanged,
      style: GB.body(15, w: FontWeight.w600),
      cursorColor: GB.accentDeep,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        prefixIcon: icon == null ? null : Padding(padding: const EdgeInsets.only(left: 14, right: 8), child: Icon(icon, size: 21, color: iconColor ?? GB.accentDeep)),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        labelStyle: GB.body(13.5, color: GB.inkMuted),
        hintStyle: GB.body(14, color: GB.inkMuted.withValues(alpha: .6)),
        filled: true,
        fillColor: GB.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: GB.edgeOf(GB.line), width: 1.3)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: GB.edgeOf(GB.line), width: 1.3)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: GB.accent, width: 1.8)),
      ),
    );
  }
}


/// Tiêu đề nhóm trong màn nhập: biểu tượng tròn tô màu pastel + tên nhóm (+ phần phụ bên phải).
class FormHeader extends StatelessWidget {
  const FormHeader(this.title, this.icon, {super.key, required this.color, this.trailing, this.hint});
  final String title;
  final IconData icon;
  final Color color; // màu pastel gốc của nhóm
  final Widget? trailing;
  final String? hint;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          IconBadge(icon: icon, bg: color, fg: GB.ink, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: GB.body(14.5, w: FontWeight.w800)),
              if (hint != null) Text(hint!, style: GB.body(11.5, color: GB.inkMuted, height: 1.25)),
            ]),
          ),
          if (trailing != null) trailing!,
        ]),
      );
}
