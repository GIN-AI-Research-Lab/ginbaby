import 'package:flutter/services.dart';

/// Danh mục tranh trong assets/art: nếu có tệp ic_<tên>.png thì icon tương ứng tự đổi sang tranh màu nước,
/// không có thì dùng icon hệ thống (xem design/icons/PROMPTS.md để biết cần tạo những tệp nào).
class ArtCatalog {
  static Set<String> _names = {};
  static Set<String> _dark = {};

  static Future<void> load() async {
    try {
      final m = await AssetManifest.loadFromAssetBundle(rootBundle);
      final all = m.listAssets();
      _names = {
        for (final a in all)
          if (a.startsWith('assets/art/') && a.endsWith('.png')) a.substring('assets/art/'.length, a.length - 4),
      };
      _dark = {
        for (final a in all)
          if (a.startsWith('assets/art_dark/') && a.endsWith('.png')) a.substring('assets/art_dark/'.length, a.length - 4),
      };
    } catch (_) {
      _names = {};
      _dark = {};
    }
  }

  static bool has(String name) => _names.contains(name);

  /// Có bản tranh riêng cho chế độ tối (tạo bằng design/tool/make_dark_art.py).
  static bool hasDark(String name) => _dark.contains(name);
}
