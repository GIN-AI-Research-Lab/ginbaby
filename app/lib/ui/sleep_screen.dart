import 'dart:async';

import 'package:flutter/material.dart';

import '../core/kit.dart';
import '../core/pastel.dart';
import '../core/pickers.dart';
import '../core/theme.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import '../domain/easy.dart';
import 'widgets.dart';

/// Ghi giấc ngủ: "Ngủ ngay" / "Dậy rồi", hoặc nhập giờ bắt đầu và kết thúc, hoặc chạm nhanh thời lượng.
class SleepScreen extends StatefulWidget {
  const SleepScreen({super.key});

  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> {
  Timer? _t;
  DateTime? start; // bản nháp khi chưa có giấc ngủ đang chạy
  DateTime? end;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && app.activeSleep != null) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  String _clock(Duration d) => '${d.inHours}:${GB.two(d.inMinutes % 60)}:${GB.two(d.inSeconds % 60)}';

  Future<void> _pickStart() async {
    final s = app.activeSleep;
    final now = DateTime.now();
    final d = await pickDateTime(context, s?.time ?? start ?? now, last: now, title: 'Giờ bắt đầu ngủ');
    if (d == null || !mounted) return;
    if (s != null) {
      s.time = d;
      app.updateEntry(s);
    } else {
      if (end != null && !d.isBefore(end!)) {
        toast(context, 'Giờ ngủ phải trước giờ dậy');
        return;
      }
      start = d;
    }
    setState(() {});
  }

  Future<void> _pickEnd() async {
    final s = app.activeSleep;
    final from = s?.time ?? start;
    if (from == null) {
      toast(context, 'Hãy nhập giờ bắt đầu ngủ trước');
      return;
    }
    final now = DateTime.now();
    final d = await pickDateTime(context, end ?? now, last: now, title: 'Giờ bé dậy');
    if (d == null || !mounted) return;
    if (!d.isAfter(from)) {
      toast(context, 'Giờ dậy phải sau giờ ngủ');
      return;
    }
    if (s != null) {
      app.endSleep(d);
    } else {
      end = d;
    }
    setState(() {});
  }

  void _quick(Duration d) {
    final now = DateTime.now();
    setState(() {
      end = now;
      start = now.subtract(d);
    });
  }

  void _reset() => setState(() {
        start = null;
        end = null;
      });

  Widget _row(String label, DateTime? t, String empty, VoidCallback onTap) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            SizedBox(width: 82, child: Text(label, style: GB.body(13, w: FontWeight.w600, color: GB.inkMuted))),
            Expanded(child: Text(t == null ? empty : GB.dmyhm(t), style: GB.body(15, w: FontWeight.w700, color: t == null ? GB.inkMuted : GB.ink))),
            Text(t == null ? 'Nhập' : 'Sửa', style: GB.body(13, w: FontWeight.w700, color: GB.accentDeep)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final a = app.activeSleep;
        final now = DateTime.now();
        final sleeping = a != null;
        final s = a?.time ?? start;
        final e = sleeping ? null : end;
        final elapsed = s == null ? Duration.zero : ((e ?? now).difference(s));
        final ready = !sleeping && s != null && e != null && e.isAfter(s);
        final today = app.entriesOn(now, type: T.sleep);
        final total = app.sleepOn(now);
        final sr = Easy.sleepHours(app.age.adjDays);
        final night = s != null && (s.hour >= 19 || s.hour < 5);

        return SubPage(
          title: 'Giấc ngủ',
          subtitle: sleeping ? 'Bé đang ngủ' : 'Ghi giấc ngủ của bé',
          art: 'baby_sleep',
          artWidth: 100,
          children: [
            GlassCard(
              radius: 26,
              child: Column(children: [
                Text(sleeping ? 'Bé đang ngủ' : (ready ? 'Giấc ngủ đã sẵn sàng để lưu' : 'Giấc ngủ'), style: GB.body(13, w: FontWeight.w700, color: GB.inkMuted)),
                const SizedBox(height: 4),
                Text(s == null ? '0:00:00' : _clock(elapsed), style: GB.display(52)),
                if (sleeping)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('Dự kiến dậy lúc ${GB.hm(a.time.add(Duration(minutes: night ? 600 : 90)))}', style: GB.body(12.5, color: GB.inkMuted)),
                  ),
                const SizedBox(height: 8),
                _row('Bắt đầu', s, 'Chưa nhập', _pickStart),
                Divider(height: 1, color: GB.ink.withValues(alpha: .08)),
                _row('Kết thúc', e, sleeping ? 'Đang ngủ…' : 'Chưa nhập', _pickEnd),
                const SizedBox(height: 12),
                if (sleeping)
                  Row(children: [
                    Expanded(child: BigButton('Bé dậy rồi', icon: Icons.wb_sunny_rounded, color: GB.sleepDeep, onTap: () {
                      final done = app.endSleep();
                      toast(context, 'Đã ghi giấc ngủ ${GB.dur(elapsed)}', undo: () {
                        if (done != null) {
                          done.end = null;
                          app.changed('entries');
                        }
                      });
                    })),
                    const SizedBox(width: 10),
                    RoundIconButton(icon: Icons.close_rounded, label: 'Huỷ giấc ngủ', onTap: () async {
                      final ok = await confirmDialog(context, 'Huỷ giấc ngủ này?', 'Giấc ngủ đang chạy sẽ bị xoá.', ok: 'Huỷ giấc ngủ');
                      if (ok) app.removeEntry(a.id);
                    }),
                  ])
                else if (ready)
                  Row(children: [
                    Expanded(child: BigButton('Lưu giấc ngủ ${GB.dur(elapsed)}', icon: Icons.check_rounded, onTap: () {
                      final saved = Entry(type: T.sleep, time: s, end: e);
                      app.addEntry(saved);
                      toast(context, 'Đã ghi giấc ngủ ${GB.dur(elapsed)}', undo: () => app.removeEntry(saved.id));
                      _reset();
                    })),
                    const SizedBox(width: 10),
                    RoundIconButton(icon: Icons.refresh_rounded, label: 'Làm lại', onTap: _reset),
                  ])
                else
                  BigButton('Ngủ ngay', icon: Icons.bedtime_rounded, color: GB.sleepDeep, onTap: () {
                    app.startSleep(start);
                    _reset();
                  }),
                if (!sleeping && !ready) ...[
                  const SizedBox(height: 14),
                  Text('Hoặc nhập nhanh một giấc đã qua', style: GB.body(12.5, color: GB.inkMuted)),
                  const SizedBox(height: 8),
                  Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
                    for (final m in const [(30, '30 phút'), (60, '1 giờ'), (90, '1,5 giờ'), (120, '2 giờ'), (480, '8 giờ')]) PillChip(label: m.$2, on: false, height: 38, onTap: () => _quick(Duration(minutes: m.$1))),
                  ]),
                ],
              ]),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: 'Hôm nay',
              icon: Icons.bedtime_rounded,
              iconColor: GB.sleepDeep,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(GB.dur(total), style: GB.display(28)),
                  const SizedBox(width: 8),
                  Text('${today.length} giấc', style: GB.body(13, color: GB.inkMuted)),
                  const Spacer(),
                  Flexible(child: Text('tham khảo ${sr.text('h')}/ngày', textAlign: TextAlign.right, style: GB.body(12, w: FontWeight.w600, color: GB.inkMuted))),
                ]),
                const SizedBox(height: 6),
                RangeBar(value: total.inMinutes / 60, lo: sr.lo, hi: sr.hi, maxV: sr.hi * 1.2, color: GB.sleepDeep),
                const SizedBox(height: 8),
                if (today.isEmpty)
                  const EmptyState('Hôm nay chưa có giấc ngủ nào.')
                else
                  for (final x in today) EntryRow(x),
              ]),
            ),
            const SizedBox(height: 10),
            Text('Nhu cầu ngủ theo National Sleep Foundation (cả ngày lẫn đêm). Mỗi bé một nhịp riêng.', style: GB.body(11, color: GB.inkMuted, height: 1.4)),
          ],
        );
      },
    );
  }
}
