import 'package:flutter/material.dart';

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
