# -*- coding: utf-8 -*-
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


# ---- phông chữ: Plus Jakarta Sans (tiêu đề, số) + Be Vietnam Pro (nội dung), cả hai hỗ trợ tiếng Việt
def th(s):
    s = rep(s, "GoogleFonts.nunito(fontSize: _s(size), fontWeight: w, color: color, height: 1.1);", "GoogleFonts.plusJakartaSans(fontSize: _s(size), fontWeight: w, color: color, height: 1.15, letterSpacing: -.2);")
    s = rep(s, "GoogleFonts.nunito(fontSize: _s(size), fontWeight: w, color: color, height: height);", "GoogleFonts.beVietnamPro(fontSize: _s(size), fontWeight: w, color: color, height: height);")
    s = rep(s, "GoogleFonts.mali(fontSize: _s(size), fontWeight: w, color: color, height: 1.35, fontStyle: italic ? FontStyle.italic : FontStyle.normal);", "GoogleFonts.beVietnamPro(fontSize: _s(size), fontWeight: w, color: color, height: 1.4, fontStyle: italic ? FontStyle.italic : FontStyle.normal);")
    s = rep(s, "/// Chữ viết tay mềm cho dòng phụ và câu động viên.", "/// Dòng phụ và câu động viên (chữ thường, nhẹ, nghiêng khi cần).")
    s = rep(s, "Phong cách \"Pastel trái tim\" (kem hồng, thẻ trắng mềm, tranh màu nước) và các hàm định dạng dùng chung.", "Phong cách \"Pastel trái tim\" (kem hồng, thẻ trắng mềm, tranh màu nước), phông Plus Jakarta Sans + Be Vietnam Pro, và các hàm định dạng dùng chung.")
    return s


edit(r'lib\core\theme.dart', th)


# ---- ảnh đầu trang tuỳ chọn
def models(s):
    s = rep(s, "  String ownerName = 'Mẹ';\n", "  String ownerName = 'Mẹ';\n  String? heroPhoto; // id ảnh đầu trang do mẹ chọn (null = tranh mặc định)\n")
    s = rep(s, "        'owner': ownerName,\n", "        'owner': ownerName,\n        if (heroPhoto != null) 'hp': heroPhoto,\n")
    s = rep(s, "    s.ownerName = (j['owner'] as String?) ?? 'Mẹ';\n", "    s.ownerName = (j['owner'] as String?) ?? 'Mẹ';\n    s.heroPhoto = j['hp'] as String?;\n")
    return s


edit(r'lib\data\models.dart', models)


def appst(s):
    s = rep(s, "        for (final f in funds) ...f.photos,\n      };", "        for (final f in funds) ...f.photos,\n        if (settings.heroPhoto != null) settings.heroPhoto!,\n      };")
    return s


edit(r'lib\data\app_state.dart', appst)

HERO = r"""import 'package:flutter/material.dart';

import '../core/kit.dart';
import '../core/theme.dart';
import '../data/app_state.dart';
import 'quick_logs.dart';

/// Ảnh đầu trang: mặc định là tranh mẹ bế bé; bấm dấu + để chọn ảnh từ thư viện (hiện thành vòng tròn).
/// Giữ lâu để quay về tranh mặc định.
class HeroPhoto extends StatelessWidget {
  const HeroPhoto({super.key, this.width = 150});
  final double width;

  Future<void> _pick(BuildContext context) async {
    final id = await pickAndStorePhoto(context);
    if (id == null) return;
    final old = app.settings.heroPhoto;
    app.settings.heroPhoto = id;
    app.settingsChanged();
    if (old != null) app.deletePhoto(old);
  }

  void _reset(BuildContext context) {
    final old = app.settings.heroPhoto;
    if (old == null) return;
    app.settings.heroPhoto = null;
    app.settingsChanged();
    app.deletePhoto(old);
    toast(context, 'Đã quay về hình mặc định');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final id = app.settings.heroPhoto;
        final bytes = id == null ? null : app.photo(id);
        final h = width * .88;
        final d = h * .92;
        return Semantics(
          button: true,
          label: 'Đổi ảnh đầu trang',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _pick(context),
            onLongPress: () => _reset(context),
            child: SizedBox(
              width: width,
              height: h,
              child: Stack(clipBehavior: Clip.none, children: [
                if (bytes == null)
                  Positioned.fill(child: Art('hero_mom_baby', width: width, alignment: Alignment.topRight))
                else
                  Positioned(
                    right: 4,
                    top: 2,
                    child: Container(
                      width: d,
                      height: d,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [BoxShadow(color: const Color(0xFFD9A79F).withValues(alpha: .35), blurRadius: 14, offset: const Offset(0, 5))],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true),
                    ),
                  ),
                Positioned(
                  right: bytes == null ? 14 : 6,
                  bottom: bytes == null ? 4 : 10,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: GB.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [BoxShadow(color: GB.accent.withValues(alpha: .35), blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: const Icon(Icons.add_rounded, size: 17, color: Colors.white),
                  ),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }
}
"""
open(os.path.join(ROOT, r'lib\ui\hero_photo.dart'), 'w', encoding='utf-8').write(HERO)


def home(s):
    s = rep(s, "        const Positioned(right: -8, top: 0, child: Art('hero_mom_baby', width: 150)),", "        const Positioned(right: -4, top: 0, child: HeroPhoto(width: 150)),")
    s = rep(s, "import 'feed_screen.dart';", "import 'feed_screen.dart';\nimport 'hero_photo.dart';")
    return s


edit(r'lib\ui\home.dart', home)


def guide(s):
    s = rep(s, "                const Positioned(right: -8, top: 0, child: Art('hero_mom_baby', width: 130)),", "                const Positioned(right: -4, top: 0, child: HeroPhoto(width: 130)),")
    s = rep(s, "import 'growth_screen.dart';", "import 'growth_screen.dart';\nimport 'hero_photo.dart';")
    return s


edit(r'lib\ui\guide.dart', guide)
print('ok')
