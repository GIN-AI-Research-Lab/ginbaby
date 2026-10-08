# -*- coding: utf-8 -*-
import os
ROOT = r'F:\Project Ai\GinBaby\app'


def edit(rel, fn):
    p = os.path.join(ROOT, rel)
    s = open(p, encoding='utf-8').read()
    s = fn(s)
    open(p, 'w', encoding='utf-8').write(s)


def rep(s, old, new):
    assert old in s, old[:80]
    return s.replace(old, new, 1)


CATALOG = """import 'package:flutter/services.dart';

/// Danh mục tranh trong assets/art: nếu có tệp ic_<tên>.png thì icon tương ứng tự đổi sang tranh màu nước,
/// không có thì dùng icon hệ thống (xem design/icons/PROMPTS.md để biết cần tạo những tệp nào).
class ArtCatalog {
  static Set<String> _names = {};

  static Future<void> load() async {
    try {
      final m = await AssetManifest.loadFromAssetBundle(rootBundle);
      _names = {
        for (final a in m.listAssets())
          if (a.startsWith('assets/art/') && a.endsWith('.png')) a.substring('assets/art/'.length, a.length - 4),
      };
    } catch (_) {
      _names = {};
    }
  }

  static bool has(String name) => _names.contains(name);
}
"""
open(os.path.join(ROOT, r'lib\core\art_catalog.dart'), 'w', encoding='utf-8').write(CATALOG)


def pastel(s):
    s = rep(s, "import 'kit.dart';", "import 'art_catalog.dart';\nimport 'kit.dart';")
    s = rep(s, "  const IconBadge({super.key, required this.icon, required this.bg, required this.fg, this.size = 44});\n  final IconData icon;",
            "  const IconBadge({super.key, required this.icon, required this.bg, required this.fg, this.size = 44, this.art});\n  final IconData icon;\n  final String? art; // tên tranh (tệp ic_<art>.png); nếu chưa có thì dùng icon")
    s = rep(s, "        child: Icon(icon, size: size * .52, color: fg),\n      );\n}",
            "        child: art != null && ArtCatalog.has('ic_$art') ? Padding(padding: EdgeInsets.all(size * .14), child: Art('ic_$art')) : Icon(icon, size: size * .52, color: fg),\n      );\n}")
    return s


edit(r'lib\core\pastel.dart', pastel)


def main(s):
    s = rep(s, "import 'core/deeplink.dart';", "import 'core/art_catalog.dart';\nimport 'core/deeplink.dart';")
    s = rep(s, "  WidgetsFlutterBinding.ensureInitialized();\n  runApp(", "  WidgetsFlutterBinding.ensureInitialized();\n  await ArtCatalog.load();\n  runApp(")
    return s


edit(r'lib\main.dart', main)


def guide(s):
    s = rep(s, "      IconBadge(icon: icon, bg: color.withValues(alpha: .55), fg: GB.ink, size: 38),", "      IconBadge(icon: icon, bg: color.withValues(alpha: .55), fg: GB.ink, size: 38, art: art),") if "      IconBadge(icon: icon, bg: color.withValues(alpha: .55), fg: GB.ink, size: 38)," in s else s
    return s


# tile() của Hồ sơ: thêm tham số art
def guide2(s):
    s = rep(s, "Widget tile(String title, String sub, IconData icon, Color color, Widget page) => GlassCard(", "Widget tile(String title, String sub, IconData icon, Color color, Widget page, [String? art]) => GlassCard(")
    s = rep(s, "IconBadge(icon: icon, bg: color.withValues(alpha: .55), fg: GB.ink, size: 38),", "IconBadge(icon: icon, bg: color.withValues(alpha: .55), fg: GB.ink, size: 38, art: art),")
    pairs = {
        "const Color(0xFFFCE0E2), const LeapsScreen())": "'wonder'",
        "const Color(0xFFE6DEF5), const EasyScreen())": "'clock'",
        "Icons.vaccines_rounded, const Color(0xFFF0B5B9), const VaccineScreen())": "'vaccine'",
        "const Color(0xFFC9DBA6), const GrowthScreen())": "'growth'",
        "const Color(0xFFF8E9A8), const SolidsScreen())": "'solids'",
        "const Color(0xFFFBE3CF), const ArticlesScreen())": "'book'",
        "const Color(0xFFDCEBF5), const HealthHub())": "'health'",
        "const Color(0xFFF8DEDF), const MindScreen())": "'mind'",
        "const Color(0xFFE3E6F6), const NoiseScreen())": "'noise'",
        "const Color(0xFFE4EBD2), const FamilyScreen())": "'family'",
    }
    for k, v in pairs.items():
        s = rep(s, k, k[:-1] + ", " + v + ")")
    return s


edit(r'lib\ui\guide.dart', guide2)


def home(s):
    s = rep(s, "Widget _mini(String label, IconData icon, Color color, VoidCallback onTap, {String? art}) => Semantics(", "Widget _mini(String label, IconData icon, Color color, VoidCallback onTap, {String? art}) => Semantics(")
    s = rep(s, "            art != null ? SizedBox(height: 24, child: Art(art)) : Icon(icon, size: 22, color: color),", "            art != null && ArtCatalog.has(art) ? SizedBox(height: 24, child: Art(art)) : (art == 'poop_mustard' ? SizedBox(height: 24, child: Art(art)) : Icon(icon, size: 22, color: color)),")
    s = rep(s, "_mini('Nhiệt độ', Icons.thermostat_rounded, GB.health, () => showOtherLogSheet(context, initial: 0))", "_mini('Nhiệt độ', Icons.thermostat_rounded, GB.health, () => showOtherLogSheet(context, initial: 0), art: 'ic_thermometer')")
    s = rep(s, "_mini('Thuốc', Icons.medication_rounded, GB.pump, () => showOtherLogSheet(context, initial: 1))", "_mini('Thuốc', Icons.medication_rounded, GB.pump, () => showOtherLogSheet(context, initial: 1), art: 'ic_medicine')")
    s = rep(s, "_mini('Ghi chú', Icons.edit_note_rounded, GB.feed, () => showOtherLogSheet(context, initial: 2))", "_mini('Ghi chú', Icons.edit_note_rounded, GB.feed, () => showOtherLogSheet(context, initial: 2), art: 'ic_note')")
    s = rep(s, "import '../core/kit.dart';", "import '../core/art_catalog.dart';\nimport '../core/kit.dart';")
    return s


edit(r'lib\ui\home.dart', home)
print('ok')
