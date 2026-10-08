# -*- coding: utf-8 -*-
import os
ROOT = r'F:\Project Ai\GinBaby\app\lib'


def edit(rel, fn):
    p = os.path.join(ROOT, rel)
    s = open(p, encoding='utf-8').read()
    s = fn(s)
    open(p, 'w', encoding='utf-8').write(s)


def rep(s, old, new, cnt=1):
    assert old in s, old[:90]
    return s.replace(old, new, cnt)


def bottle(s):
    # tham số dark cho BottleView -> painter
    s = rep(s, "    this.interactive = true,\n    this.label = 'Mực sữa trong bình',\n  });", "    this.interactive = true,\n    this.label = 'Mực sữa trong bình',\n    this.dark,\n  });")
    s = rep(s, "  final bool interactive;\n  final String label;", "  final bool interactive;\n  final String label;\n  final bool? dark; // mặc định theo chế độ giao diện; thẻ tổng kết ép sáng")
    s = rep(s, "phase: reduce ? 0 : _wave.value, milk: widget.color ?? GB.milkMom),", "phase: reduce ? 0 : _wave.value, milk: widget.color ?? GB.milkMom, dark: widget.dark ?? GB.dark),")
    s = rep(s, "required this.milk, this.labels = true});\n  final double level;", "required this.milk, this.labels = true, this.dark = false});\n  final bool dark;\n  final double level;")
    s = rep(s, "    const ink = Color(0xFF2B2634); // thân bình luôn sáng nên nét viền luôn đậm\n",
            "    // Bình sáng (nét đậm trên thân kem) hoặc bình tối (nét kem trên thân tím thẫm)\n    final ink = dark ? const Color(0xFFEBDCD3) : const Color(0xFF2B2634);\n    final bodyFill = dark ? const Color(0xFF2B222F) : const Color(0xFFFFFCF7);\n    final labelColor = dark ? const Color(0xFFB7AAB5) : const Color(0xFF6F6470);\n")
    s = rep(s, "canvas.drawRect(const Rect.fromLTWH(84, 76, 72, 34), Paint()..color = const Color(0xFFFFFCF7));", "canvas.drawRect(const Rect.fromLTWH(84, 76, 72, 34), Paint()..color = bodyFill);")
    s = rep(s, "    canvas.drawRRect(body, Paint()..color = const Color(0xFFFFFCF7));\n\n    canvas.save();", "    canvas.drawRRect(body, Paint()..color = bodyFill);\n\n    canvas.save();")
    s = rep(s, "style: GB.body(11, w: FontWeight.w600, color: GB.inkMuted)),\n          textDirection: TextDirection.ltr,\n        )..layout();\n        tp.paint(canvas, Offset(196, y - 7));", "style: GB.body(11, w: FontWeight.w600, color: labelColor)),\n          textDirection: TextDirection.ltr,\n        )..layout();\n        tp.paint(canvas, Offset(196, y - 7));")
    s = rep(s, "bool shouldRepaint(BottlePainter old) => old.level != level || old.phase != phase || old.milk != milk || old.cap != cap;", "bool shouldRepaint(BottlePainter old) => old.level != level || old.phase != phase || old.milk != milk || old.cap != cap || old.dark != dark;")
    # bình mini
    s = rep(s, "      ..color = const Color(0xFF2B2634)\n      ..strokeWidth = 1.5\n      ..strokeJoin = StrokeJoin.round;\n    final nip", "      ..color = GB.dark ? const Color(0xFFEBDCD3) : const Color(0xFF2B2634)\n      ..strokeWidth = 1.5\n      ..strokeJoin = StrokeJoin.round;\n    final nip")
    s = rep(s, "Paint()..color = const Color(0xFF2B2634));\n    final body = RRect.fromRectAndRadius(const Rect.fromLTWH(4, 12, 16, 20), const Radius.circular(4));\n    canvas.drawRRect(body, Paint()..color = const Color(0xFFFFFCF7));", "Paint()..color = GB.dark ? const Color(0xFFEBDCD3) : const Color(0xFF2B2634));\n    final body = RRect.fromRectAndRadius(const Rect.fromLTWH(4, 12, 16, 20), const Radius.circular(4));\n    canvas.drawRRect(body, Paint()..color = GB.dark ? const Color(0xFF2B222F) : const Color(0xFFFFFCF7));")
    return s


edit(r'ui\bottle.dart', bottle)


def recap(s):
    a = s.index("  static final themes = [")
    b = s.index("  Future<void> _export() async {")
    s = s[:a] + """  // Thẻ tổng kết là ảnh chia sẻ nên dùng màu cố định, không đổi theo chế độ sáng/tối của app.
  static const themes = [
    _Theme('Hồng', Color(0xFFF6B9BD), Color(0xFF2B2634), Color(0xFFFFFBF8), Color(0xFF8B2F33), Color(0xFF6F6470)),
    _Theme('Kem', Color(0xFFFCEDE6), Color(0xFF2B2634), Colors.white, Color(0xFFE5666F), Color(0xFF6F6470)),
    _Theme('Đêm', Color(0xFF2B2F6B), Colors.white, Color(0xFF3A3F85), Color(0xFFF6B27E), Color(0xFFD4D8F5)),
    _Theme('Tím', Color(0xFFD9D2F0), Color(0xFF2B2634), Color(0xFFFBF9FF), Color(0xFF5B4B9A), Color(0xFF6A6285)),
  ];

""" + s[b:]
    s = s.replace("t.fg == Colors.white ? Colors.white : GB.ink", "t.fg")
    s = rep(s, "t.fg == Colors.white ? GB.p(Color(0xFFD4D8F5)) : GB.f(Color(0xFF3F4A8A))", "t.fg == Colors.white ? const Color(0xFFD4D8F5) : const Color(0xFF3F4A8A)")
    s = rep(s, "decoration: BoxDecoration(color: GB.sleep, borderRadius: BorderRadius.circular(5))", "decoration: BoxDecoration(color: const Color(0xFF8FB08B), borderRadius: BorderRadius.circular(5))")
    s = rep(s, "BottleView(ml: 190, cap: 240, width: 120, interactive: false, onChanged: (_) {})", "BottleView(ml: 190, cap: 240, width: 120, interactive: false, dark: false, onChanged: (_) {})")
    s = s.replace("GB.p(Color(0xFFD9C8B8))", "const Color(0xFFD9C8B8)")
    return s


edit(r'ui\recap.dart', recap)
print('ok')
