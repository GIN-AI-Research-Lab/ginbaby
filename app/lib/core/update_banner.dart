import 'dart:async';

import 'package:flutter/material.dart';

import '../ui/settings.dart' show kBuild;
import 'kit.dart';
import 'platform.dart';
import 'theme.dart';

/// Khi có bản mới trên máy chủ (web), hiện thanh "Có bản mới" ở mọi màn để mẹ tải lại một chạm.
class UpdateBanner extends StatefulWidget {
  const UpdateBanner({super.key, required this.child});
  final Widget child;

  @override
  State<UpdateBanner> createState() => _UpdateBannerState();
}

class _UpdateBannerState extends State<UpdateBanner> {
  Timer? _poll;
  bool newVersion = false;

  @override
  void initState() {
    super.initState();
    if (kIsWebPlatform && kBuild != 'dev') {
      _poll = Timer.periodic(const Duration(seconds: 30), (_) async {
        final v = await fetchVersion();
        if (v != null && v != kBuild && mounted && !newVersion) setState(() => newVersion = true);
      });
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Positioned.fill(child: widget.child),
      if (newVersion)
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          child: Material(
            type: MaterialType.transparency,
            child: GlassCard(
              radius: 20,
              opacity: .92,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              onTap: reloadPage,
              child: Row(children: [
                Icon(Icons.system_update_alt_rounded, color: GB.accentDeep),
                const SizedBox(width: 10),
                Expanded(child: Text('Có bản mới. Bấm để cập nhật', style: GB.body(14, w: FontWeight.w700))),
                Text('Tải lại', style: GB.body(13, w: FontWeight.w800, color: GB.accentDeep)),
              ]),
            ),
          ),
        ),
    ]);
  }
}
