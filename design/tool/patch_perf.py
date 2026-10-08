# -*- coding: utf-8 -*-
"""Tối ưu để mượt trên iPhone: chữ khai báo sẵn (không qua google_fonts), ảnh nhỏ đúng cỡ, bỏ hiệu ứng chồng hai trang khi đổi tab,
thẻ phẳng không đổ bóng khi tắt kính, giảm độ phân giải vẽ trên màn 3x."""
import io
import re

ROOT = r'F:\Project Ai\GinBaby\app'


def rd(rel):
    return io.open(ROOT + '\\' + rel, encoding='utf-8').read()


def wr(rel, s):
    io.open(ROOT + '\\' + rel, 'w', encoding='utf-8').write(s)


def rep(s, a, b):
    assert a in s, a[:90]
    return s.replace(a, b, 1)


# ---- chữ: TextStyle thường với font Inter khai báo trong pubspec (nhanh hơn GoogleFonts.inter mỗi lần gọi)
t = rd(r'lib\core\theme.dart')
t = t.replace("GoogleFonts.inter(", "TextStyle(fontFamily: 'Inter', ")
t = re.sub(r"import 'package:google_fonts/google_fonts.dart';\n", "", t)
wr(r'lib\core\theme.dart', t)

p = rd('pubspec.yaml')
p = rep(p, "  assets:\n    - assets/art/\n    - assets/art_dark/\n    - assets/google_fonts/\n", """  assets:
    - assets/art/
    - assets/art_dark/

  fonts:
    - family: Inter
      fonts:
        - asset: assets/google_fonts/Inter-Regular.ttf
          weight: 400
        - asset: assets/google_fonts/Inter-Medium.ttf
          weight: 500
        - asset: assets/google_fonts/Inter-SemiBold.ttf
          weight: 600
        - asset: assets/google_fonts/Inter-Bold.ttf
          weight: 700
        - asset: assets/google_fonts/Inter-ExtraBold.ttf
          weight: 800
""")
wr('pubspec.yaml', p)

ts = rd(r'test\screens_test.dart')
a = ts.index("  GoogleFonts.config.allowRuntimeFetching = false;")
ts = ts.replace("  GoogleFonts.config.allowRuntimeFetching = false;\n", "", 1)
s0 = ts.index("    // Nạp phông thật")
s1 = ts.index("    await seedDemo(app);")
ts = ts[:s0] + "    // Phông Inter đã khai báo trong pubspec nên bộ test tự nạp phông thật.\n" + ts[s1:]
ts = ts.replace("import 'package:google_fonts/google_fonts.dart';\n", "")
wr(r'test\screens_test.dart', ts)

# ---- đổi tab: bỏ hiệu ứng mờ dần chồng hai trang (vẽ hai trang cùng lúc gây khựng)
m = rd(r'lib\main.dart')
a = m.index("              child: AnimatedSwitcher(")
b = m.index("            Positioned(left: 0, right: 0, bottom: 0, child: _TabBar(")
m = m[:a] + "              child: KeyedSubtree(key: ValueKey(tab), child: pages[tab]),\n            ),\n" + m[b:]
wr(r'lib\main.dart', m)

# ---- ảnh: giải mã đúng kích thước hiển thị (nhẹ bộ nhớ và GPU)
k = rd(r'lib\core\kit.dart')
k = rep(k, "    final darkArt = GB.dark && ArtCatalog.hasDark(name);\n    final img = Image.asset(",
        "    final darkArt = GB.dark && ArtCatalog.hasDark(name);\n    final dpr = math.min(MediaQuery.maybeDevicePixelRatioOf(context) ?? 2, 2.0);\n    final img = Image.asset(")
k = rep(k, "      width: width,\n      height: height,\n      fit: fit,\n      alignment: alignment,\n      filterQuality: FilterQuality.medium,",
        "      width: width,\n      height: height,\n      cacheWidth: width != null ? (width! * dpr).ceil() : null,\n      cacheHeight: width == null && height != null ? (height! * dpr).ceil() : null,\n      fit: fit,\n      alignment: alignment,\n      filterQuality: FilterQuality.medium,")
if "import 'dart:math' as math;" not in k:
    k = "import 'dart:math' as math;\n" + k
# thẻ ở mức kính Tắt/Nhẹ: không đổ bóng, nền đặc hơn (rẻ khi vẽ)
k = rep(k, "    final glass = GB.glass && blur > 0;\n", "    final glass = GB.glass && blur > 0;\n    final cheap = !GB.glassCards && !forceBlur; // nền trong nhưng không làm mờ, không đổ bóng: nhẹ nhất\n")
k = rep(k, "        boxShadow: shadow ? [BoxShadow(", "        boxShadow: shadow && !cheap ? [BoxShadow(")
wr(r'lib\core\kit.dart', k)

# ---- mặc định kính Tắt: mượt nhất
md = rd(r'lib\data\models.dart')
md = rep(md, "  int glassMode = 1;", "  int glassMode = 0;")
md = md.replace("?? (j['gl'] == false ? 0 : 1);", "?? 0;")
wr(r'lib\data\models.dart', md)
print('ok')
