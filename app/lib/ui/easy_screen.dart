import 'package:flutter/material.dart';

import '../core/kit.dart';
import '../core/theme.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import '../domain/easy.dart';

/// Nhịp EASY: thời gian thức, lịch gợi ý trong ngày, cài đặt vòng ăn–chơi–ngủ.
class EasyScreen extends StatefulWidget {
  const EasyScreen({super.key});

  @override
  State<EasyScreen> createState() => _EasyScreenState();
}

class _EasyScreenState extends State<EasyScreen> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final s = app.settings;
        final age = app.age.adjDays;
        final cycle = Easy.cycleFor(s, age);
        final sp = Easy.split(cycle, age);
        final ww = Easy.wakeWindow(age);
        final naps = Easy.napsPerDay(age);
        final sh = Easy.sleepHours(age);

        // lịch gợi ý từ giờ bé dậy sáng nay (hoặc bây giờ)
        final today = AppState.dayStart(DateTime.now());
        final morning = app.entries.where((e) => e.type == T.sleep && e.end != null && e.end!.isAfter(today) && e.end!.hour < 11).toList()..sort((a, b) => a.end!.compareTo(b.end!));
        final start = morning.isNotEmpty ? morning.first.end! : DateTime(today.year, today.month, today.day, 7);
        final plan = <(DateTime, String, IconData, Color)>[];
        var t = start;
        final napLen = age < 90 ? 75 : age < 180 ? 90 : 90;
        final n = naps.hi.round();
        for (var i = 0; i < n; i++) {
          plan.add((t, 'Dậy và ăn (E)', Icons.local_drink_rounded, GB.feed));
          plan.add((t.add(Duration(minutes: sp.eat)), 'Chơi (A)', Icons.toys_rounded, GB.diaper));
          final nap = t.add(Duration(minutes: ww.mid.round()));
          plan.add((nap, 'Ngủ ngày ${i + 1} (S) ~${napLen}p', Icons.bedtime_rounded, GB.sleep));
          t = nap.add(Duration(minutes: napLen));
        }
        plan.add((t, 'Dậy, ăn và chơi', Icons.local_drink_rounded, GB.feed));
        final bed = t.add(Duration(minutes: ww.hi.round()));
        plan.add((bed.isAfter(DateTime(today.year, today.month, today.day, 21)) ? DateTime(today.year, today.month, today.day, 20, 30) : bed, 'Tắm, ăn, đi ngủ đêm', Icons.nights_stay_rounded, GB.sleepIndigo));

        return SubPage(
          title: 'Nhịp EASY',
          subtitle: 'Bé ${app.age.short} · lịch ${Easy.label(cycle)}',
          art: 'baby_sleep',
          artWidth: 110,
          children: [
            GlassCard(
              radius: 26,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Một vòng ${Easy.label(cycle)} ≈ ${GB.dur(Duration(minutes: cycle))}', style: GB.body(14, w: FontWeight.w800)),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(flex: sp.eat, child: _seg('E', '${sp.eat}p', GB.feed)),
                  const SizedBox(width: 4),
                  Expanded(flex: sp.activity, child: _seg('A', '${sp.activity}p', GB.diaper)),
                  const SizedBox(width: 4),
                  Expanded(flex: sp.sleep, child: _seg('S', '${sp.sleep}p', GB.sleep)),
                ]),
                const SizedBox(height: 10),
                Text('E: ăn · A: chơi · S: ngủ. Phần "Y" là thời gian của mẹ trong lúc bé ngủ.', style: GB.body(12.5, color: GB.inkMuted, height: 1.4)),
              ]),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _fact('Thức mỗi lần', ww.text('p'), Icons.wb_sunny_rounded)),
              const SizedBox(width: 10),
              Expanded(child: _fact('Ngủ ngày', '${naps.lo.round()}–${naps.hi.round()} cữ', Icons.bedtime_rounded)),
              const SizedBox(width: 10),
              Expanded(child: _fact('Tổng ngủ', sh.text('h'), Icons.nights_stay_rounded)),
            ]),
            const SectionTitle('Lịch gợi ý hôm nay'),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Column(children: [
                for (final p in plan)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    child: Row(children: [
                      SizedBox(width: 48, child: Text(GB.hm(p.$1), style: GB.body(13, w: FontWeight.w700, color: p.$1.isBefore(DateTime.now()) ? GB.inkMuted.withValues(alpha: .6) : GB.ink))),
                      Orb(icon: p.$3, color: p.$4.withValues(alpha: .35), size: 30),
                      const SizedBox(width: 12),
                      Expanded(child: Text(p.$2, style: GB.body(14.5, w: FontWeight.w600, color: p.$1.isBefore(DateTime.now()) ? GB.inkMuted : GB.ink))),
                    ]),
                  ),
              ]),
            ),
            const SizedBox(height: 8),
            Text('Lịch được tính từ giờ bé dậy sáng nay và thời gian thức thường gặp. Mỗi bé mỗi khác: hãy nhìn dấu hiệu buồn ngủ của bé trước tiên.', style: GB.body(11.5, color: GB.inkMuted, height: 1.4)),
            const SectionTitle('Cài đặt nhịp'),
            GlassCard(
              radius: 24,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text('Tự chọn theo tuổi', style: GB.body(14.5, w: FontWeight.w700))),
                  Switch(value: s.easyAuto, activeThumbColor: GB.accent, onChanged: (v) {
                    s.easyAuto = v;
                    app.settingsChanged();
                  }),
                ]),
                if (!s.easyAuto) ...[
                  const SizedBox(height: 6),
                  Seg(labels: const ['E2.5', 'E3', 'E3.5', 'E4'], index: const [25, 30, 35, 40].indexOf(s.easy < 10 ? s.easy * 10 : s.easy).clamp(0, 3), height: 42, onChanged: (i) {
                    s.easy = const [25, 30, 35, 40][i];
                    app.settingsChanged();
                  }),
                ],
                const SizedBox(height: 8),
                Text('Luyện nếp từ từ: mỗi lần dời giờ 10–15 phút. Thời gian thức và số cữ ngủ là mức tham khảo phổ biến trong hướng dẫn luyện ngủ; nhu cầu ngủ theo National Sleep Foundation. Không thay thế tư vấn bác sĩ.', style: GB.body(11.5, color: GB.inkMuted, height: 1.4)),
              ]),
            ),
          ],
        );
      },
    );
  }

  Widget _seg(String l, String v, Color c) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: c.withValues(alpha: .5), borderRadius: BorderRadius.circular(14), border: Border.all(color: GB.edgeOf(c.withValues(alpha: .5)), width: 1)),
        child: Column(children: [
          Text(l, style: GB.display(18)),
          Text(v, style: GB.body(11.5, w: FontWeight.w700)),
        ]),
      );

  Widget _fact(String label, String v, IconData icon) => GlassCard(
        radius: 20,
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 20, color: GB.accentDeep),
          const SizedBox(height: 6),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(v, style: GB.body(15, w: FontWeight.w800))),
          Text(label, style: GB.body(11.5, color: GB.inkMuted)),
        ]),
      );
}
