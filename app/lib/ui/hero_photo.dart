import 'package:flutter/material.dart';

import '../core/kit.dart';
import '../core/theme.dart';
import '../data/app_state.dart';
import 'quick_logs.dart';

/// Ảnh đầu trang: mặc định là tranh mẹ bế bé; bấm dấu + để chọn ảnh từ thư viện (hiện thành vòng tròn).
/// Giữ lâu để quay về tranh mặc định.
class HeroPhoto extends StatelessWidget {
  const HeroPhoto({super.key, this.width = 108, this.editable = false});
  final double width;
  final bool editable; // chỉ ở màn Hồ sơ: chạm để đổi ảnh, giữ để về ảnh mặc định, có dấu +

  Future<void> _pick(BuildContext context) async {
    final hasPhoto = app.settings.heroPhoto != null;
    final c = await showPhotoMenu(context, removeLabel: hasPhoto ? 'Về ảnh mặc định' : null);
    if (c == null || !context.mounted) return;
    if (c == PhotoChoice.remove) {
      _reset(context);
      return;
    }
    final id = await pickAndStorePhoto(context, camera: c == PhotoChoice.camera);
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
        final d = width * .86; // đường kính ảnh tròn
        final avatar = Container(
          width: d,
          height: d,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: GB.accentSoft,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [BoxShadow(color: const Color(0xFFD9A79F).withValues(alpha: .35), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          clipBehavior: Clip.antiAlias,
          child: bytes != null
              ? Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true, filterQuality: FilterQuality.high, isAntiAlias: true)
              : Center(child: Art('hero_mom_baby', width: d * .80, height: d * .80)) // thu gọn để thấy trọn hình, không bị khung tròn cắt viền,
        );
        if (!editable) return SizedBox(width: d + 6, height: d + 6, child: Align(alignment: Alignment.topLeft, child: avatar));
        return Semantics(
          button: true,
          label: 'Đổi ảnh đầu trang',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _pick(context),
            onLongPress: () => _reset(context),
            child: SizedBox(
              width: d + 6,
              height: d + 6,
              child: Stack(clipBehavior: Clip.none, children: [
                Positioned(left: 0, top: 0, child: avatar),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: GB.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [BoxShadow(color: GB.accent.withValues(alpha: .35), blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
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
