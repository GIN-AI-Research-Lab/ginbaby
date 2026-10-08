# -*- coding: utf-8 -*-
"""Giao diện kính mờ kiểu iOS (blur nền, viền sáng, tab bar nổi) + tím pastel nhạt cho chế độ tối."""
import os

ROOT = r'F:\Project Ai\GinBaby\app\lib'


def rd(rel):
    return open(os.path.join(ROOT, rel), encoding='utf-8').read()


def wr(rel, s):
    open(os.path.join(ROOT, rel), 'w', encoding='utf-8').write(s)


def rep(s, old, new, cnt=1):
    assert old in s, old[:90]
    return s.replace(old, new, cnt)


# ---------- theme
t = rd(r'core\theme.dart')
pal = {
    "0xFF2E2848": "0xFF3A3262", "0xFF3A3360": "0xFF4A4180", "0xFF3F3868": "0xFF50478A", "0xFF5B5390": "0xFF7468B0",
    "0xFFF9F5FF": "0xFFFBF8FF", "0xFFD9D2F0": "0xFFE0D9F7", "0xFFE6D8FF": "0xFFF0E4FF",
    "0xFF9A7BEA": "0xFF9B7CF0", "0xFFCDB8FF": "0xFFD8C8FF", "0xFF4E4382": "0xFF5A4F96",
    "0xFF5A4478": "0xFF8C5AB0", "0xFF4A44A0": "0xFF6B5FD8", "0xFF6A4380": "0xFFB05AA8",
    "0xFF68416E": "0xFF7B4B88", "0xFFFFA3D1": "0xFFFFB0DA", "0xFF6B4A5F": "0xFF84586F", "0xFFFFB9A0": "0xFFFFC1AA",
    "0xFF4C4A94": "0xFF5A58A8", "0xFFC4B5FF": "0xFFCFC2FF", "0xFF3A6270": "0xFF45728A", "0xFFA3E8D0": "0xFFB0F0DC",
    "0xFF3A6358": "0xFF487066", "0xFF64503C": "0xFF7A6048", "0xFF6A3C62": "0xFF80496F", "0xFF4A4A94": "0xFF5656A8",
}
for a, b in pal.items():
    assert a in t, a
    t = t.replace(a, b)
t = rep(t, "h.hue, (h.saturation * .5).clamp(0.0, .40), .37)", "h.hue, (h.saturation * .5).clamp(0.0, .42), .44)")
t = rep(t, "  static bool dark = false;", """  static bool dark = false;

  /// Hiệu ứng kính mờ (làm mờ nền phía sau thẻ, tab bar, bảng chọn). Tắt được trong Cài đặt nếu máy yếu.
  static bool glass = true;""")
wr(r'core\theme.dart', t)

# ---------- kit: thẻ kính, nền, bảng chọn
k = rd(r'core\kit.dart')
k = rep(k, "import 'package:flutter/material.dart';\n", "import 'dart:ui' show ImageFilter;\n\nimport 'package:flutter/material.dart';\n")

a = k.index("  @override\n  Widget build(BuildContext context) {\n    final br = BorderRadius.circular(radius);")
b = k.index("/// Thanh chọn kiểu viên thuốc (segmented).")
k = k[:a] + """  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);
    final glass = GB.glass && blur > 0;
    final Widget inner = Container(
      padding: padding,
      decoration: glass
          ? BoxDecoration(
              borderRadius: br,
              // kính: lớp trắng mờ có độ sáng chuyển từ góc trên trái, viền sáng như ánh phản chiếu mép kính
              gradient: tint != null
                  ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [tint!.withValues(alpha: .80), tint!.withValues(alpha: .62)])
                  : LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: GB.dark ? [Colors.white.withValues(alpha: .20), Colors.white.withValues(alpha: .09)] : [Colors.white.withValues(alpha: .78), Colors.white.withValues(alpha: .48)]),
              border: Border.all(color: GB.dark ? Colors.white.withValues(alpha: .28) : Colors.white.withValues(alpha: .95), width: 1.2),
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
        boxShadow: shadow ? [BoxShadow(color: (GB.dark ? const Color(0xFF120A2E) : const Color(0xFFC98C84)).withValues(alpha: GB.dark ? .35 : (glass ? .22 : .20)), blurRadius: glass ? 22 : 14, offset: const Offset(0, 6))] : null,
      ),
      child: glass ? ClipRRect(borderRadius: br, child: BackdropFilter(filter: ImageFilter.blur(sigmaX: blur * .7, sigmaY: blur * .7), child: inner)) : inner,
    );
    if (onTap != null) {
      card = Pressable(scale: .985, dim: .88, onTap: onTap, child: card);
    }
    return card;
  }
}

""" + k[b:]

# nền: thêm một vệt màu để lớp kính có gì mà làm mờ
k = rep(k, "        Positioned(right: -120, bottom: -140, child: _blob(GB.blobRose, 380)),",
        "        Positioned(right: -120, bottom: -140, child: _blob(GB.blobRose, 380)),\n        Positioned(left: -100, bottom: 60, child: _blob(GB.blobPeach, 300)),\n        Positioned(right: -80, top: 560, child: _blob(GB.blobLilac, 320)),")
k = rep(k, "gradient: RadialGradient(colors: [c.withValues(alpha: .75), c.withValues(alpha: 0)]),", "gradient: RadialGradient(colors: [c.withValues(alpha: GB.dark ? .85 : .95), c.withValues(alpha: 0)]),")
wr(r'core\kit.dart', k)

# ---------- nút đổi sáng/tối theo kính
k = rd(r'core\kit.dart')
k = rep(k, """          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: GB.card,
            border: Border.all(color: GB.edgeOf(GB.line), width: 1.2),
            boxShadow: [BoxShadow(color: const Color(0xFFC98C84).withValues(alpha: dark ? .10 : .20), blurRadius: 10, offset: const Offset(0, 3))],
          ),""", """          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: GB.glass ? (dark ? Colors.white.withValues(alpha: .16) : Colors.white.withValues(alpha: .75)) : GB.card,
            border: Border.all(color: GB.glass ? (dark ? Colors.white.withValues(alpha: .3) : Colors.white) : GB.edgeOf(GB.line), width: 1.2),
            boxShadow: [BoxShadow(color: const Color(0xFFC98C84).withValues(alpha: dark ? .10 : .20), blurRadius: 10, offset: const Offset(0, 3))],
          ),""")
wr(r'core\kit.dart', k)

# ---------- ô hoạt động: ánh kính ở mép trên
p = rd(r'core\pastel.dart')
p = rep(p, "gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [tile.withValues(alpha: .85), tile]),",
        "gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.alphaBlend(Colors.white.withValues(alpha: GB.dark ? .16 : .45), tile), tile]),")
wr(r'core\pastel.dart', p)

# ---------- tab bar nổi dạng kính
m = rd('main.dart')
m = rep(m, "import 'package:flutter/material.dart';\n", "import 'dart:ui' show ImageFilter;\n\nimport 'package:flutter/material.dart';\n")
a = m.index("    final bottom = MediaQuery.of(context).padding.bottom;\n    return Container(\n      padding: EdgeInsets.fromLTRB(8, 6, 8, 6 + (bottom > 0 ? bottom : 4)),")
b = m.index("      child: Row(children: [\n        for (var i = 0; i < _items.length; i++)")
m = m[:a] + """    final bottom = MediaQuery.of(context).padding.bottom;
    final glass = GB.glass;
    final bar = Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      decoration: BoxDecoration(
        color: glass ? null : GB.card,
        gradient: glass ? LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: GB.dark ? [Colors.white.withValues(alpha: .22), Colors.white.withValues(alpha: .12)] : [Colors.white.withValues(alpha: .86), Colors.white.withValues(alpha: .62)]) : null,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: glass ? (GB.dark ? Colors.white.withValues(alpha: .3) : Colors.white) : GB.line, width: 1.2),
      ),
""" + m[b:]
# đóng Row rồi bọc ngoài
m = rep(m, """          ),
      ]),
    );
  }
}
""", """          ),
      ]),
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, (bottom > 0 ? bottom : 8) + 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: (GB.dark ? const Color(0xFF120A2E) : const Color(0xFFC98F86)).withValues(alpha: GB.dark ? .45 : .30), blurRadius: 26, offset: const Offset(0, 8))],
        ),
        child: glass ? ClipRRect(borderRadius: BorderRadius.circular(30), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22), child: bar)) : bar,
      ),
    );
  }
}
""")
# GB.glass theo cài đặt
m = rep(m, "        GB.dark = dark;\n", "        GB.dark = dark;\n        GB.glass = app.settings.glass;\n")
wr('main.dart', m)

# ---------- cài đặt: công tắc kính
mo = rd(r'data\models.dart')
mo = rep(mo, "  int themeMode = 0; // 0 theo máy, 1 sáng, 2 tối\n", "  int themeMode = 0; // 0 theo máy, 1 sáng, 2 tối\n  bool glass = true; // hiệu ứng kính mờ\n")
mo = rep(mo, "        'tm': themeMode,\n", "        'tm': themeMode,\n        'gl': glass,\n")
mo = rep(mo, "    s.themeMode = (j['tm'] as num?)?.toInt() ?? 0;\n", "    s.themeMode = (j['tm'] as num?)?.toInt() ?? 0;\n    s.glass = j['gl'] != false;\n")
wr(r'data\models.dart', mo)

se = rd(r'ui\settings.dart')
se = rep(se, "              const SizedBox(height: 6),\n              Text('Chế độ tối dịu mắt khi cho bé bú ban đêm.", "              const SizedBox(height: 6),\n              _switch('Hiệu ứng kính mờ', 'Làm mờ nền phía sau thẻ và thanh tab như iOS. Tắt nếu máy chạy chậm.', s.glass, (v) {\n                s.glass = v;\n                app.settingsChanged();\n              }),\n              Text('Chế độ tối dịu mắt khi cho bé bú ban đêm.")
wr(r'ui\settings.dart', se)

# bình sữa: thân bình theo màu thẻ mới
bo = rd(r'ui\bottle.dart')
bo = bo.replace("0xFF3F3868", "0xFF50478A")
wr(r'ui\bottle.dart', bo)
print('ok')
