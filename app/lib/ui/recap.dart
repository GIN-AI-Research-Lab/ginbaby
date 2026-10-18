import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/capture.dart';
import '../core/kit.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../data/app_state.dart';
import '../domain/age.dart';
import '../domain/stats.dart';
import 'baby_profile.dart';

/// Thẻ tổng kết tuần để chia sẻ (xuất ảnh PNG).
class RecapScreen extends StatefulWidget {
  const RecapScreen({super.key, required this.weekStart});
  final DateTime weekStart;

  @override
  State<RecapScreen> createState() => _RecapScreenState();
}

class _Theme {
  const _Theme(this.name, this.bg, this.fg, this.card, this.accent, this.muted);
  final String name;
  final Color bg;
  final Color fg;
  final Color card;
  final Color accent;
  final Color muted;
}

class _RecapScreenState extends State<RecapScreen> {
  final key = GlobalKey();
  int themeIdx = 0;
  bool hideName = false;
  bool showNumbers = true;
  bool busy = false;

  // Thẻ tổng kết là ảnh chia sẻ nên dùng màu cố định, không đổi theo chế độ sáng/tối của app.
  static const themes = [
    _Theme('Hồng', Color(0xFFF6B9BD), Color(0xFF2B2634), Color(0xFFFFFBF8), Color(0xFF8B2F33), Color(0xFF6F6470)),
    _Theme('Kem', Color(0xFFFCEDE6), Color(0xFF2B2634), Colors.white, Color(0xFFE5666F), Color(0xFF6F6470)),
    _Theme('Đêm', Color(0xFF2B2F6B), Colors.white, Color(0xFF3A3F85), Color(0xFFF6B27E), Color(0xFFD4D8F5)),
    _Theme('Tím', Color(0xFFD9D2F0), Color(0xFF2B2634), Color(0xFFFBF9FF), Color(0xFF5B4B9A), Color(0xFF6A6285)),
  ];

  Future<void> _export() async {
    setState(() => busy = true);
    final png = await capturePng(key, pixelRatio: 3);
    setState(() => busy = false);
    if (png == null || !mounted) return;
    final name = 'ginbaby-tuan-${GB.dm(widget.weekStart).replaceAll('/', '-')}.png';
    if (await shareFileBytes(name, png, 'image/png', title: 'Tổng kết tuần của bé')) return;
    downloadBytes(name, png, 'image/png');
    if (mounted) toast(context, kIsWebPlatform ? 'Đã tải ảnh tổng kết' : 'Chỉ hỗ trợ lưu ảnh trên bản web');
  }

  @override
  Widget build(BuildContext context) {
    final cur = Stats.week(app, widget.weekStart);
    final prev = Stats.week(app, widget.weekStart.subtract(const Duration(days: 7)));
    final t = themes[themeIdx];
    final sleepAvg = Stats.avgOf(cur, (d) => d.sleepHours);
    final milkTotal = cur.fold(0, (a, d) => a + d.milk);
    final diapers = cur.fold(0, (a, d) => a + d.diapers);
    final longest = cur.map((d) => d.longestSleep).fold(Duration.zero, (a, b) => a > b ? a : b);
    final hl = highlights(cur, prev);
    final baby = app.baby!;
    final name = hideName ? 'bé' : baby.name;
    final end = widget.weekStart.add(const Duration(days: 6));
    final pumpTotal = cur.fold(0, (a, d) => a + d.pumpMl);
    final feedCnt = cur.fold(0, (a, d) => a + d.feedCount);
    final pumpCnt = cur.fold(0, (a, d) => a + d.pumpCount);
    const wd = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final maxS = math.max(14.0, maxOf(cur.map((d) => d.sleepHours)));

    return SubPage(
      title: 'Thẻ tổng kết tuần',
      subtitle: '${GB.dmy(widget.weekStart)} – ${GB.dmy(end)}',
      bottom: BigButton(busy ? 'Đang tạo ảnh…' : 'Lưu ảnh', icon: Icons.ios_share_rounded, onTap: busy ? null : _export),
      children: [
        Center(
          child: RepaintBoundary(
            key: key,
            child: Container(
              width: 350,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(color: t.bg, borderRadius: BorderRadius.circular(32)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text('GinBaby', style: GB.display(20, color: t.fg))),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(14)), child: Text('${GB.dmy(widget.weekStart)} – ${GB.dmy(end)}', style: GB.body(12.5, w: FontWeight.w700, color: t.fg))),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Tuần của', style: GB.body(14, w: FontWeight.w600, color: t.fg)),
                      FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(name, style: GB.display(38, color: t.fg))),
                      if (!hideName) Text('bé ${Age(baby, end).short}', style: GB.body(12.5, color: t.muted)),
                    ]),
                  ),
                  if (!hideName) ...[const SizedBox(width: 10), const BabyAvatar(size: 58)],
                ]),
                const SizedBox(height: 12),
                if (showNumbers) ...[
                  // thẻ giấc ngủ: số giờ trung bình + biểu đồ 7 ngày gọn
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                    decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(22)),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Expanded(
                        flex: 5,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Icon(Icons.bedtime_rounded, size: 16, color: t.fg == Colors.white ? const Color(0xFFD4D8F5) : const Color(0xFF3F4A8A)),
                            const SizedBox(width: 6),
                            Expanded(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text('Ngủ mỗi ngày', style: GB.body(12, w: FontWeight.w700, color: t.muted)))),
                          ]),
                          const SizedBox(height: 2),
                          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(GB.dur(Duration(minutes: (sleepAvg * 60).round())), style: GB.display(32, color: t.fg))),
                        ]),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 6,
                        child: SizedBox(
                          height: 74,
                          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            for (var i = 0; i < 7; i++)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 2),
                                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                                    Container(height: math.max(3, cur[i].sleepHours / maxS * 40), decoration: BoxDecoration(color: const Color(0xFF8FB08B), borderRadius: BorderRadius.circular(4))),
                                    const SizedBox(height: 3),
                                    Text(wd[i], style: GB.body(9, color: t.muted)),
                                  ]),
                                ),
                              ),
                          ]),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _stat(t, Icons.local_drink_rounded, 'Sữa đã bú', GB.num1(milkTotal / 1000), 'lít', const Color(0xFF7B68C4))),
                    const SizedBox(width: 8),
                    Expanded(child: _stat(t, Icons.water_drop_rounded, 'Sữa hút được', GB.num1(pumpTotal / 1000), 'lít', const Color(0xFFE58F96))),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _stat(t, Icons.restaurant_rounded, 'Số cữ bú', '$feedCnt', 'cữ', const Color(0xFFE9A15F))),
                    const SizedBox(width: 8),
                    Expanded(child: _stat(t, Icons.baby_changing_station_rounded, 'Tã cả tuần', '$diapers', 'lần', const Color(0xFFD9A441))),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _stat(t, Icons.nights_stay_rounded, 'Ngủ dài nhất', GB.dur(longest), '', const Color(0xFF6E8FD6))),
                    const SizedBox(width: 8),
                    Expanded(child: _stat(t, Icons.favorite_rounded, 'Số cữ hút', '$pumpCnt', 'cữ', const Color(0xFFE58F96))),
                  ]),
                ],
                if (hl.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  for (final h in hl)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Icon(Icons.auto_awesome_rounded, size: 16, color: t.accent),
                        const SizedBox(width: 8),
                        Expanded(child: Text(h, style: GB.body(13.5, w: FontWeight.w600, color: t.fg))),
                      ]),
                    ),
                ],
                const SizedBox(height: 8),
                Text('Ghi nhanh trong 3 giây với GinBaby', style: GB.body(11.5, color: t.muted)),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Text('Mẫu thẻ', style: GB.body(13, w: FontWeight.w700, color: GB.inkMuted)),
          const SizedBox(width: 12),
          for (var i = 0; i < themes.length; i++) ...[
            GestureDetector(
              onTap: () => setState(() => themeIdx = i),
              child: Semantics(
                button: true,
                selected: i == themeIdx,
                label: 'Mẫu ${themes[i].name}',
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: themes[i].bg, shape: BoxShape.circle, border: Border.all(color: i == themeIdx ? GB.ink : const Color(0xFFD9C8B8), width: i == themeIdx ? 3 : 1)),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
        ]),
        const SizedBox(height: 8),
        _toggle('Ẩn tên bé', hideName, (v) => setState(() => hideName = v)),
        _toggle('Kèm số liệu ngủ, bú, tã', showNumbers, (v) => setState(() => showNumbers = v)),
      ],
    );
  }

  /// Ô số liệu nhỏ: biểu tượng màu trong vòng tròn, số lớn, nhãn bên dưới.
  Widget _stat(_Theme t, IconData icon, String label, String value, String unit, Color c) => Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(20)),
        child: Row(children: [
          Container(width: 34, height: 34, decoration: BoxDecoration(color: c.withValues(alpha: .20), shape: BoxShape.circle), child: Icon(icon, size: 19, color: c)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, mainAxisSize: MainAxisSize.min, children: [
                  Text(value, style: GB.display(24, color: t.fg)),
                  if (unit.isNotEmpty) ...[const SizedBox(width: 3), Text(unit, style: GB.body(12, w: FontWeight.w700, color: t.muted))],
                ]),
              ),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: GB.body(11, w: FontWeight.w600, color: t.muted)),
            ]),
          ),
        ]),
      );

  Widget _small(_Theme t, String label, String v, IconData icon) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(20)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(icon, size: 16, color: t.muted), const SizedBox(width: 6), Expanded(child: Text(label, style: GB.body(11.5, w: FontWeight.w700, color: t.muted)))]),
          const SizedBox(height: 2),
          Text(v, style: GB.display(24, color: t.fg)),
        ]),
      );

  Widget _toggle(String label, bool v, ValueChanged<bool> on) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          Expanded(child: Text(label, style: GB.body(14.5, w: FontWeight.w700))),
          Switch(value: v, activeThumbColor: GB.accent, onChanged: on),
        ]),
      );
}
