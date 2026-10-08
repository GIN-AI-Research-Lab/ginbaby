import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';

/// Bình sữa có thể vuốt để chỉnh mực sữa (hít mốc, rung nhẹ).
class BottleView extends StatefulWidget {
  const BottleView({
    super.key,
    required this.ml,
    required this.onChanged,
    this.cap = 240,
    this.step = 10,
    this.color,
    this.width = 204,
    this.interactive = true,
    this.label = 'Mực sữa trong bình',
    this.dark,
  });

  final int ml;
  final ValueChanged<int> onChanged;
  final int cap;
  final int step;
  final Color? color;
  final double width;
  final bool interactive;
  final String label;
  final bool? dark; // mặc định theo chế độ giao diện; thẻ tổng kết ép sáng

  @override
  State<BottleView> createState() => _BottleViewState();
}

class _BottleViewState extends State<BottleView> with SingleTickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  double get _scale => widget.width / 240;
  double get _height => 340 * _scale;

  void _fromDy(double dy) {
    if (!widget.interactive) return;
    final y = dy / _scale;
    final v = (330 - y) / 220 * widget.cap;
    final n = (((v / widget.step).round()) * widget.step).clamp(0, widget.cap);
    if (n != widget.ml) {
      HapticFeedback.selectionClick();
      widget.onChanged(n);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.width;
    final reduce = MediaQuery.of(context).disableAnimations;
    return Semantics(
      label: widget.label,
      value: '${widget.ml} ml',
      increasedValue: '${math.min(widget.cap, widget.ml + widget.step)} ml',
      decreasedValue: '${math.max(0, widget.ml - widget.step)} ml',
      onIncrease: widget.interactive ? () => widget.onChanged(math.min(widget.cap, widget.ml + widget.step)) : null,
      onDecrease: widget.interactive ? () => widget.onChanged(math.max(0, widget.ml - widget.step)) : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => _fromDy(d.localPosition.dy),
        onVerticalDragStart: (d) => _fromDy(d.localPosition.dy),
        onVerticalDragUpdate: (d) => _fromDy(d.localPosition.dy),
        child: SizedBox(
          width: w,
          height: _height,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: widget.ml.toDouble()),
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            builder: (context, level, _) => AnimatedBuilder(
              animation: _wave,
              builder: (context, _) => CustomPaint(
                painter: BottlePainter(level: level, cap: widget.cap, phase: reduce ? 0 : _wave.value, milk: widget.color ?? GB.milkBottle, dark: widget.dark ?? GB.dark),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BottlePainter extends CustomPainter {
  BottlePainter({required this.level, required this.cap, required this.phase, required this.milk, this.labels = true, this.dark = false});
  final bool dark;
  final double level;
  final int cap;
  final double phase;
  final Color milk;
  final bool labels;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 240, size.height / 340);
    // Bình sáng (nét đậm trên thân kem) hoặc bình tối (nét kem trên thân tím thẫm)
    final ink = dark ? const Color(0xFFEBDCD3) : const Color(0xFF2B2634);
    final bodyFill = dark ? const Color(0xFF50478A) : const Color(0xFFEAF1F6); // thân bình: thuỷ tinh trong, sữa kem nổi lên
    final labelColor = dark ? const Color(0xFFB7AAB5) : const Color(0xFF6F6470);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = ink
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round;

    final nipple = Path()
      ..moveTo(104, 18)
      ..quadraticBezierTo(120, 0, 136, 18)
      ..lineTo(142, 52)
      ..lineTo(98, 52)
      ..close();
    canvas.drawPath(nipple, Paint()..color = const Color(0xFFEAD3B5));
    canvas.drawPath(nipple, stroke);

    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(72, 50, 96, 26), const Radius.circular(10)), Paint()..color = ink);
    canvas.drawRect(const Rect.fromLTWH(84, 76, 72, 34), Paint()..color = bodyFill);
    canvas.drawRect(const Rect.fromLTWH(84, 76, 72, 34), stroke);

    final body = RRect.fromRectAndRadius(const Rect.fromLTWH(50, 100, 140, 230), const Radius.circular(30));
    canvas.drawRRect(body, Paint()..color = bodyFill);

    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(52, 102, 136, 226), const Radius.circular(28)));
    final top = 330 - level / cap * 220;
    if (level > 0) {
      final wave = Path()..moveTo(40, 345);
      wave.lineTo(40, top);
      for (double x = 40; x <= 200; x += 4) {
        final y = top + math.sin(((x / 35) + phase * 2) * math.pi) * 4;
        wave.lineTo(x, y);
      }
      wave.lineTo(200, 345);
      wave.close();
      // sữa: trắng ngà ở mặt thoáng, đậm dần xuống đáy như sữa thật; mép sóng có vệt sáng
      canvas.drawPath(
        wave,
        Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.lerp(milk, Colors.white, .55)!, milk]).createShader(Rect.fromLTWH(40, top - 6, 160, 345 - top)),
      );
      final crest = Path()..moveTo(40, top);
      for (double x = 40; x <= 200; x += 4) {
        crest.lineTo(x, top + math.sin(((x / 35) + phase * 2) * math.pi) * 4);
      }
      canvas.drawPath(crest, Paint()..style = PaintingStyle.stroke..strokeWidth = 2.2..color = Colors.white.withValues(alpha: .85));

      for (var i = 0; i < 3; i++) {
        final p = (phase + i / 3) % 1.0;
        final by = 320 - p * 80;
        if (by > top + 6) {
          canvas.drawCircle(Offset(88 + i * 30.0, by), 3.5 + (i % 2), Paint()..color = Colors.white.withValues(alpha: .7 * (1 - p)));
        }
      }
    }
    canvas.restore();
    canvas.drawRRect(body, stroke..strokeWidth = 2.5);

    // vạch chia: 4 vạch lớn + 4 vạch nhỏ theo dung tích
    final tick = Paint()
      ..color = ink
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final minor = Paint()
      ..color = ink
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    // Mép phải thân bình bị bo ở hai góc: vạch phải thụt vào theo độ cong để không lòi ra ngoài khung.
    double edge(double y) {
      const r = 30.0;
      final dy = y < 100 + r ? (100 + r - y) : (y > 330 - r ? y - (330 - r) : 0.0);
      return 190 - (r - math.sqrt(math.max(0, r * r - dy * dy))) - 4;
    }

    for (var i = 1; i <= 4; i++) {
      final v = cap * i / 4;
      final y = 330 - v / cap * 220;
      final ex = edge(y);
      canvas.drawLine(Offset(ex - 14, y), Offset(ex, y), tick);
      if (labels) {
        final tp = TextPainter(
          text: TextSpan(text: '${v.round()}', style: GB.body(11, w: FontWeight.w600, color: labelColor)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(196, y - 7));
      }
      final vm = cap * (i - .5) / 4;
      final ym = 330 - vm / cap * 220;
      final exm = edge(ym);
      canvas.drawLine(Offset(exm - 8, ym), Offset(exm, ym), minor);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(BottlePainter old) => old.level != level || old.phase != phase || old.milk != milk || old.cap != cap || old.dark != dark;
}

/// Bình mini (tĩnh) dùng trong tủ sữa.
class MiniBottle extends StatelessWidget {
  const MiniBottle({super.key, required this.fill, this.color, this.frozen = false, this.size = 40});
  final double fill; // 0..1
  final Color? color;
  final bool frozen;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size * .72, size), painter: _MiniPainter(fill.clamp(0.0, 1.0), frozen ? const Color(0xFFCFE3F2) : (color ?? GB.milkBottle), frozen));
  }
}

class _MiniPainter extends CustomPainter {
  _MiniPainter(this.fill, this.color, this.frozen);
  final double fill;
  final Color color;
  final bool frozen;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 34);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = GB.dark ? const Color(0xFFEBDCD3) : const Color(0xFF2B2634)
      ..strokeWidth = 1.5
      ..strokeJoin = StrokeJoin.round;
    final nip = Path()
      ..moveTo(9, 3)
      ..quadraticBezierTo(12, 0, 15, 3)
      ..lineTo(16, 8)
      ..lineTo(8, 8)
      ..close();
    canvas.drawPath(nip, Paint()..color = const Color(0xFFEAD3B5));
    canvas.drawPath(nip, stroke..strokeWidth = 1.3);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(6.5, 8, 11, 4), const Radius.circular(1.5)), Paint()..color = GB.dark ? const Color(0xFFEBDCD3) : const Color(0xFF2B2634));
    final body = RRect.fromRectAndRadius(const Rect.fromLTWH(4, 12, 16, 20), const Radius.circular(4));
    canvas.drawRRect(body, Paint()..color = GB.dark ? const Color(0xFF50478A) : const Color(0xFFEAF1F6));
    canvas.save();
    canvas.clipRRect(body);
    final h = 18 * fill;
    canvas.drawRect(Rect.fromLTWH(4, 31 - h, 16, h + 2), Paint()..color = color);
    if (frozen && fill > 0) {
      final p = Paint()
        ..color = Colors.white
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(9, 22), const Offset(11, 24), p);
      canvas.drawLine(const Offset(14, 21), const Offset(12, 24), p);
      canvas.drawLine(const Offset(13, 27), const Offset(15, 29), p);
    }
    canvas.restore();
    canvas.drawRRect(body, stroke..strokeWidth = 1.6);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MiniPainter old) => old.fill != fill || old.color != color || old.frozen != frozen;
}
