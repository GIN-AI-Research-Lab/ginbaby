# -*- coding: utf-8 -*-
"""Thu gọn giao diện: chữ, đệm, nút, tab bar, đầu trang (chạy một lần)."""
import os

ROOT = r'F:\Project Ai\GinBaby\app'


def edit(rel, fn):
    p = os.path.join(ROOT, rel)
    s = open(p, encoding='utf-8').read()
    s = fn(s)
    open(p, 'w', encoding='utf-8').write(s)


def rep(s, old, new, cnt=1):
    assert old in s, old[:80]
    return s.replace(old, new, cnt)


def th(s):
    s = rep(s, "  /// Tiêu đề lớn, số lớn.\n  static TextStyle display(double size, {FontWeight w = FontWeight.w800, Color color = ink}) =>\n      GoogleFonts.nunito(fontSize: size, fontWeight: w, color: color, height: 1.1);",
            "  /// Hệ số thu nhỏ chữ chung (gọn như mẫu thiết kế); chữ nhỏ nhất giữ 10,5.\n  static const double fs = .9;\n  static double _s(double v) => math.max(math.min(v, 10.5), v * fs);\n\n  /// Tiêu đề lớn, số lớn.\n  static TextStyle display(double size, {FontWeight w = FontWeight.w800, Color color = ink}) =>\n      GoogleFonts.nunito(fontSize: _s(size), fontWeight: w, color: color, height: 1.1);")
    s = rep(s, "GoogleFonts.nunito(fontSize: size, fontWeight: w, color: color, height: height);", "GoogleFonts.nunito(fontSize: _s(size), fontWeight: w, color: color, height: height);")
    s = rep(s, "GoogleFonts.mali(fontSize: size,", "GoogleFonts.mali(fontSize: _s(size),")
    return s


edit(r'lib\core\theme.dart', th)


def kit(s):
    s = rep(s, "    this.padding = const EdgeInsets.all(16),\n    this.opacity = .5,", "    this.padding = const EdgeInsets.all(14),\n    this.opacity = .5,")
    s = rep(s, "this.height = 54, this.enabled = true});", "this.height = 48, this.enabled = true});")
    s = rep(s, "this.filled = false, this.size = 48, this.color});", "this.filled = false, this.size = 42, this.color});")
    s = rep(s, "this.color, this.height = 40, this.icon});", "this.color, this.height = 36, this.icon});")
    s = rep(s, "required this.onChanged, this.height = 44});", "required this.onChanged, this.height = 40});")
    s = rep(s, "          width: 44,\n          height: 44,\n          decoration: const BoxDecoration(color: GB.accentSoft, shape: BoxShape.circle),\n          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: GB.title),",
            "          width: 40,\n          height: 40,\n          decoration: const BoxDecoration(color: GB.accentSoft, shape: BoxShape.circle),\n          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: GB.title),")
    s = rep(s, "art != null ? (artWidth <= 120 ? 28 : 34) : 26,", "art != null ? (artWidth <= 120 ? 26 : 30) : 24,")
    s = rep(s, "height: artWidth <= 120 ? 128 : 170,", "height: artWidth <= 120 ? 112 : 148,")
    s = rep(s, "Text(subtitle!, style: GB.script(art != null ? 14 : 12.5))", "Text(subtitle!, style: GB.script(art != null ? 13 : 12))")
    return s


edit(r'lib\core\kit.dart', kit)


def pa(s):
    s = rep(s, "padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),", "padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),")
    s = rep(s, "SizedBox(height: 54, child: Art(art, height: 54)),\n            const SizedBox(height: 6),", "SizedBox(height: 44, child: Art(art, height: 44)),\n            const SizedBox(height: 4),")
    s = rep(s, "            const SizedBox(height: 8),\n            Container(\n              width: 32,\n              height: 32,", "            const SizedBox(height: 6),\n            Container(\n              width: 28,\n              height: 28,")
    s = rep(s, "child: Icon(icon, size: 20, color: Colors.white),", "child: Icon(icon, size: 18, color: Colors.white),")
    s = rep(s, "this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 16)", "this.padding = const EdgeInsets.fromLTRB(14, 14, 14, 14)")
    s = rep(s, "      radius: 26,\n      padding: padding,", "      radius: 22,\n      padding: padding,")
    s = rep(s, "Icon(icon, size: 24, color: iconColor),\n          const SizedBox(width: 8),", "Icon(icon, size: 21, color: iconColor),\n          const SizedBox(width: 7),")
    s = rep(s, "style: GB.display(18, w: FontWeight.w800)))),\n          if (trailing", "style: GB.display(17, w: FontWeight.w800)))),\n          if (trailing")
    s = rep(s, "        const SizedBox(height: 12),\n        child,", "        const SizedBox(height: 10),\n        child,")
    s = rep(s, "padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),\n        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),", "padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),\n        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18)),")
    return s


edit(r'lib\core\pastel.dart', pa)


def mn(s):
    s = rep(s, "padding: EdgeInsets.fromLTRB(8, 8, 8, 8 + (bottom > 0 ? bottom : 6)),", "padding: EdgeInsets.fromLTRB(8, 6, 8, 6 + (bottom > 0 ? bottom : 4)),")
    s = rep(s, "size: 28, color: i == index ? GB.accent : GB.inkMuted),\n                    const SizedBox(height: 2),", "size: 24, color: i == index ? GB.accent : GB.inkMuted),\n                    const SizedBox(height: 1),")
    s = rep(s, "borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),", "borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),")
    s = rep(s, "padding: const EdgeInsets.symmetric(vertical: 4),\n                  child: Column(mainAxisSize: MainAxisSize.min, children: [", "padding: const EdgeInsets.symmetric(vertical: 2),\n                  child: Column(mainAxisSize: MainAxisSize.min, children: [")
    return s


edit(r'lib\main.dart', mn)


def hm(s):
    s = rep(s, "padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 130),", "padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 16, 100),")
    s = rep(s, "      height: 200,\n      child: Stack(children: [\n        const Positioned(right: -10, top: 0, child: Art('hero_mom_baby', width: 178)),", "      height: 164,\n      child: Stack(children: [\n        const Positioned(right: -8, top: 0, child: Art('hero_mom_baby', width: 150)),")
    s = rep(s, "style: GB.display(34, color: GB.title)))),\n              const SizedBox(width: 6),\n              const Icon(Icons.favorite_rounded, color: Color(0xFFF08A97), size: 26),", "style: GB.display(30, color: GB.title)))),\n              const SizedBox(width: 6),\n              const Icon(Icons.favorite_rounded, color: Color(0xFFF08A97), size: 22),")
    s = rep(s, "          right: 130,\n", "          right: 110,\n")
    s = s.replace("padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),", "padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),")
    s = s.replace("Text('Hành trình nuôi con bằng yêu thương', style: GB.script(14))", "Text('Hành trình nuôi con bằng yêu thương', style: GB.script(13))")
    s = s.replace("const SizedBox(height: 14),\n            _tiles(sleeping),", "const SizedBox(height: 10),\n            _tiles(sleeping),")
    s = s.replace("const SizedBox(width: 10),\n      Expanded(child: ActivityTile", "const SizedBox(width: 8),\n      Expanded(child: ActivityTile")
    s = s.replace("const SizedBox(height: 16),\n            _overview(now),\n            const SizedBox(height: 14),\n            const DayFeedCard(),\n            const SizedBox(height: 14),\n            _latest(now),\n            const SizedBox(height: 14),",
                  "const SizedBox(height: 12),\n            _overview(now),\n            const SizedBox(height: 10),\n            const DayFeedCard(),\n            const SizedBox(height: 10),\n            _latest(now),\n            const SizedBox(height: 10),")
    s = s.replace("if (!sleeping) ...[const SizedBox(height: 14), _nextUpCard()],\n            const SizedBox(height: 14),\n            _sleepToday(),\n            const SizedBox(height: 18),",
                  "if (!sleeping) ...[const SizedBox(height: 10), _nextUpCard()],\n            const SizedBox(height: 10),\n            _sleepToday(),\n            const SizedBox(height: 14),")
    s = s.replace("Container(width: 60, height: 60, padding: const EdgeInsets.all(8),", "Container(width: 52, height: 52, padding: const EdgeInsets.all(7),")
    return s


edit(r'lib\ui\home.dart', hm)
print('ok')
