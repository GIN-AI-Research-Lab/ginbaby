# -*- coding: utf-8 -*-
"""Chuyển hệ màu sang dạng getter có hai bảng màu (sáng/tối) và bọc các màu cứng bằng GB.p / GB.f / GB.w."""
import glob
import os
import re

ROOT = r'F:\Project Ai\GinBaby\app\lib'

# ---------- A. theme.dart
p = os.path.join(ROOT, 'core', 'theme.dart')
s = open(p, encoding='utf-8').read()

DARK = {
    'bg': '0xFF17121A', 'bgTop': '0xFF1F1824', 'card': '0xFF241C29', 'line': '0xFF3A2F40',
    'ink': '0xFFF4EDF0', 'inkMuted': '0xFFB7AAB5', 'cream': '0xFF241C29',
    'title': '0xFFF2A9AC', 'accent': '0xFFE96C76', 'accentDeep': '0xFFF28C95', 'accentSoft': '0xFF3F2630',
    'blobPeach': '0xFF3A2630', 'blobLilac': '0xFF2C2640', 'blobRose': '0xFF402632',
    'milkMom': '0xFFF1C69A', 'milkFormula': '0xFFB9B0E6', 'sleepIndigo': '0xFF3A3470',
    'pumpTile': '0xFF47282F', 'pumpDeep': '0xFFF08A8F', 'breastTile': '0xFF47311F', 'breastDeep': '0xFFF0A877',
    'bottleTile': '0xFF32304D', 'bottleDeep': '0xFFB9A9F0', 'sleepTile': '0xFF2C3D30', 'sleepDeep': '0xFF93C48E',
    'feed': '0xFFF0A872', 'sleep': '0xFF8FB08B', 'diaper': '0xFFE9C46A', 'pump': '0xFFE58F96', 'health': '0xFF7FB7C9', 'gold': '0xFFF2B632',
    'ok': '0xFFA9D197', 'okBg': '0xFF2B3A27', 'warn': '0xFFF0B98C', 'warnBg': '0xFF4A3520',
    'alert': '0xFFF4A3AD', 'alertBg': '0xFF4A2630', 'info': '0xFFBDBCF2', 'infoBg': '0xFF2F2E52',
}


def conv(m):
    name, val = m.group(1), m.group(2)
    return "  static Color get %s => dark ? const Color(%s) : const Color(%s);" % (name, DARK[name], val)


s = re.sub(r"  static const (\w+) = Color\((0x[0-9A-Fa-f]{8})\);", conv, s)
s = s.replace("class GB {\n", """class GB {
  /// Đang dùng bảng màu tối (đặt ở gốc app; đổi giá trị thì cả cây giao diện được dựng lại).
  static bool dark = false;

  /// Nền trắng mờ cho các ô nhỏ (trên nền tối chỉ là lớp sáng rất nhẹ).
  static Color w(double a) => dark ? Colors.white.withValues(alpha: a * .09) : Colors.white.withValues(alpha: a);

  /// Màu pastel dùng làm nền: ở chế độ tối được pha với nền tối cho dịu mắt.
  static Color p(Color c) => dark ? Color.lerp(c, const Color(0xFF17121A), .76)! : c;

  /// Màu đậm dùng cho chữ/biểu tượng trên nền pastel: ở chế độ tối được làm sáng lên.
  static Color f(Color c) => dark ? Color.lerp(c, Colors.white, .62)! : c;

""", 1)
s = s.replace("static TextStyle display(double size, {FontWeight w = FontWeight.w800, Color color = ink}) =>\n      GoogleFonts.plusJakartaSans(fontSize: _s(size), fontWeight: w, color: color,",
              "static TextStyle display(double size, {FontWeight w = FontWeight.w800, Color? color}) =>\n      GoogleFonts.plusJakartaSans(fontSize: _s(size), fontWeight: w, color: color ?? ink,")
s = s.replace("static TextStyle body(double size, {FontWeight w = FontWeight.w500, Color color = ink, double? height}) =>\n      GoogleFonts.beVietnamPro(fontSize: _s(size), fontWeight: w, color: color, height: height);",
              "static TextStyle body(double size, {FontWeight w = FontWeight.w500, Color? color, double? height}) =>\n      GoogleFonts.beVietnamPro(fontSize: _s(size), fontWeight: w, color: color ?? ink, height: height);")
s = s.replace("static TextStyle script(double size, {Color color = inkMuted, FontWeight w = FontWeight.w400, bool italic = false}) =>\n      GoogleFonts.beVietnamPro(fontSize: _s(size), fontWeight: w, color: color,",
              "static TextStyle script(double size, {Color? color, FontWeight w = FontWeight.w400, bool italic = false}) =>\n      GoogleFonts.beVietnamPro(fontSize: _s(size), fontWeight: w, color: color ?? inkMuted,")
open(p, 'w', encoding='utf-8').write(s)

# ---------- B. các tệp khác
def lum(hexv):
    v = int(hexv, 16)
    r, g, b = (v >> 16) & 255, (v >> 8) & 255, v & 255
    return (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255


HEX = re.compile(r"(?<![\w.])(?:const )?Color\((0xFF[0-9A-Fa-f]{6})\)")
files = [f for f in glob.glob(os.path.join(ROOT, '**', '*.dart'), recursive=True) if not f.endswith('theme.dart')]
changed = 0
for f in files:
    t = open(f, encoding='utf-8').read()
    o = t
    # trắng mờ làm nền -> GB.w (giữ nguyên bọt sữa trong bình)
    if not f.endswith('bottle.dart'):
        t = re.sub(r"Colors\.white\.withValues\(alpha: ([^)]+)\)", r"GB.w(\1)", t)

    def wrap(m):
        hv = m.group(1)
        l = lum(hv)
        inner = 'Color(%s)' % hv
        if l >= 0.78:
            return 'GB.p(%s)' % inner
        if l <= 0.40:
            return 'GB.f(%s)' % inner
        return m.group(0)

    # không đụng vào các tệp vẽ mà màu là của nội dung (bình sữa, tiền vàng)
    if not (f.endswith('bottle.dart') or f.endswith('pickers.dart')):
        t = HEX.sub(wrap, t)
    if t != o:
        open(f, 'w', encoding='utf-8').write(t)
        changed += 1
print('files changed', changed)
