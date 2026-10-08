import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/kit.dart';
import '../core/platform.dart';
import '../core/theme.dart';

/// Kiểm tra GinBaby đã được lưu đủ trong điện thoại để mở khi mất mạng chưa (nằm trong app, quay lại bình thường).
class OfflineScreen extends StatefulWidget {
  const OfflineScreen({super.key});

  @override
  State<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<OfflineScreen> {
  Map<String, dynamic>? s;
  Timer? _t;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    _load();
    _t = Timer.periodic(const Duration(seconds: 3), (_) => _load());
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final j = await offlineStatusJson();
    if (!mounted || j == null) return;
    setState(() => s = jsonDecode(j) as Map<String, dynamic>);
  }

  Widget _row(String k, String v, {bool? ok}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Text(k, style: GB.body(13, color: GB.inkMuted))),
          const SizedBox(width: 12),
          Flexible(child: Text(v, textAlign: TextAlign.right, style: GB.body(13, w: FontWeight.w800, color: ok == null ? GB.ink : (ok ? GB.ok : GB.alert)))),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final d = s;
    final core = (d?['core'] as num?)?.toInt() ?? 0;
    final rest = (d?['rest'] as num?)?.toInt() ?? 0;
    final coreOk = (d?['coreOk'] as num?)?.toInt() ?? 0;
    final restOk = (d?['restOk'] as num?)?.toInt() ?? 0;
    final active = ((d?['sw'] as String?) ?? '').startsWith('active');
    final ready = d != null && active && core > 0 && coreOk >= core;
    final total = core + rest;
    final pct = total == 0 ? 0.0 : (coreOk + restOk) / total;
    final missing = [for (final m in (d?['missing'] as List? ?? const [])) '$m'];
    final cache = d == null ? '' : '${d['cache']}';
    return SubPage(
      title: 'Chạy khi không có mạng',
      subtitle: 'GinBaby đã lưu đủ trong điện thoại chưa',
      bottom: BigButton(
        busy ? 'Đang lưu…' : 'Lưu thêm ngay (cần có mạng)',
        icon: Icons.cloud_download_rounded,
        onTap: busy
            ? null
            : () async {
                setState(() => busy = true);
                await offlineWarm();
                await Future<void>.delayed(const Duration(seconds: 2));
                await _load();
                if (mounted) setState(() => busy = false);
              },
      ),
      children: [
        GlassCard(
          radius: 24,
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d == null ? 'Đang kiểm tra…' : ready ? 'Sẵn sàng chạy ngoại tuyến' : 'Chưa sẵn sàng', style: GB.display(20, color: d == null ? GB.ink : (ready ? GB.ok : GB.alert))),
            const SizedBox(height: 4),
            Text(
              d == null
                  ? ''
                  : ready
                      ? (restOk >= rest ? 'Đã lưu đủ. Có thể tắt mạng để thử.' : 'Đủ để mở app. Ảnh minh hoạ vẫn đang được lưu nốt, giữ app mở thêm một lúc.')
                      : !active
                          ? 'Chưa có bộ lưu ngoại tuyến. Hãy mở app khi có mạng.'
                          : 'Còn thiếu tệp. Giữ mạng và bấm "Lưu thêm ngay".',
              style: GB.body(13, color: GB.inkMuted, height: 1.4),
            ),
            const SizedBox(height: 10),
            ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: pct, minHeight: 10, backgroundColor: GB.line, valueColor: AlwaysStoppedAnimation(GB.accent))),
            const SizedBox(height: 4),
            Text(total == 0 ? '' : '${coreOk + restOk}/$total tệp', style: GB.body(12, color: GB.inkMuted)),
          ]),
        ),
        const SizedBox(height: 12),
        if (d != null)
          GlassCard(
            radius: 24,
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              _row('Phiên bản app đang chạy', const String.fromEnvironment('BUILD', defaultValue: 'dev')),
              _row('Đang mở dạng', d['standalone'] == true ? 'App trên Màn hình chính' : 'Trình duyệt', ok: d['standalone'] == true),
              _row('Bộ lưu ngoại tuyến', '${d['sw']}', ok: active),
              _row('Điều khiển trang này', d['controlled'] == true ? 'Có' : 'Chưa (mở lại app một lần)', ok: d['controlled'] == true),
              _row('Bản đã lưu', cache.isEmpty ? 'chưa có' : cache, ok: cache.isNotEmpty),
              if (d['latest'] != null) _row('Bản mới nhất trên máy chủ', '${d['latest']}', ok: d['latest'] == d['cache']),
              if (core > 0) _row('Tệp cần để mở app', '$coreOk/$core', ok: coreOk >= core),
              for (final m in missing) _row('· THIẾU', m, ok: false),
              if (rest > 0) _row('Ảnh minh hoạ và phần phụ', '$restOk/$rest', ok: restOk >= rest ? true : null),
              if (d['offline'] == true) _row('Máy chủ', 'Không liên lạc được (đang mất mạng?)', ok: false),
              if (d['usedMb'] != null) _row('Dung lượng đã dùng', '${d['usedMb']} MB'),
              if (d['persisted'] != null) _row('Được giữ cố định', d['persisted'] == true ? 'Có' : 'Chưa'),
            ]),
          ),
        const SizedBox(height: 12),
        BigButton('Xoá bộ nhớ đệm và đăng ký lại', icon: Icons.restart_alt_rounded, color: GB.w(.75), fg: GB.ink, onTap: () async {
          final ok = await confirmDialog(context, 'Xoá bộ nhớ đệm?', 'App sẽ tải lại toàn bộ từ máy chủ. Dữ liệu ghi chép của mẹ không bị ảnh hưởng. Cần có mạng.', ok: 'Làm lại');
          if (!ok) return;
          setState(() => busy = true);
          await offlineReset();
          await Future<void>.delayed(const Duration(seconds: 2));
          await _load();
          if (mounted) setState(() => busy = false);
        }),
      ],
    );
  }
}
