import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/kit.dart';
import '../core/theme.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import '../domain/epds.dart';

/// Góc của mẹ: tâm trạng hằng ngày, thở thư giãn, tự kiểm tra tâm trạng sau sinh (EPDS).
class MindScreen extends StatelessWidget {
  const MindScreen({super.key});

  static final _moods = [('Mệt', Icons.sentiment_very_dissatisfied_rounded, Color(0xFFF0B5B9)), ('Bình thường', Icons.sentiment_neutral_rounded, GB.p(Color(0xFFE3E6F6))), ('Ổn', Icons.sentiment_satisfied_rounded, GB.p(Color(0xFFE4EBD2))), ('Vui', Icons.sentiment_very_satisfied_rounded, GB.p(Color(0xFFF8E9A8)))];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final today = AppState.dayStart(DateTime.now());
        final todays = app.moods.where((m) => AppState.dayStart(m.time) == today).firstOrNull;
        final last = app.epds.firstOrNull;
        final days = [for (var i = 13; i >= 0; i--) today.subtract(Duration(days: i))];
        MoodEntry? moodOn(DateTime d) => app.moods.where((m) => AppState.dayStart(m.time) == d).firstOrNull;
        return SubPage(
          title: 'Góc của mẹ',
          subtitle: 'Riêng tư: chỉ lưu trên máy này',
          art: 'hero_mom_baby',
          artWidth: 110,
          children: [
            GlassCard(
              radius: 26,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Hôm nay mẹ thế nào?', style: GB.display(22, w: FontWeight.w700)),
                const SizedBox(height: 10),
                Row(children: [
                  for (var i = 0; i < _moods.length; i++) ...[
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _moodSheet(context, i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(color: todays?.mood == i ? GB.ink : GB.w(.65), borderRadius: BorderRadius.circular(20), border: Border.all(color: GB.edgeOf(todays?.mood == i ? GB.ink : GB.w(.65)), width: 1)),
                          child: Column(children: [
                            Icon(_moods[i].$2, size: 30, color: todays?.mood == i ? GB.cream : GB.ink),
                            const SizedBox(height: 4),
                            FittedBox(fit: BoxFit.scaleDown, child: Text(_moods[i].$1, style: GB.body(11.5, w: FontWeight.w700, color: todays?.mood == i ? GB.cream : GB.ink))),
                          ]),
                        ),
                      ),
                    ),
                    if (i < _moods.length - 1) const SizedBox(width: 8),
                  ],
                ]),
                if (todays != null && todays.note.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Text('"${todays.note}"', style: GB.body(13, color: GB.inkMuted))),
                const SizedBox(height: 14),
                Text('14 ngày gần đây', style: GB.body(12.5, w: FontWeight.w700, color: GB.inkMuted)),
                const SizedBox(height: 8),
                Row(children: [
                  for (final d in days)
                    Expanded(
                      child: Container(
                        height: 30,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: BoxDecoration(color: moodOn(d) == null ? GB.w(.5) : _moods[moodOn(d)!.mood].$3, borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                ]),
              ]),
            ),
            const SizedBox(height: 12),
            GlassCard(
              radius: 24,
              onTap: () => _breathe(context),
              child: Row(children: [
                Orb(icon: Icons.air_rounded, color: GB.p(Color(0xFFDCEBF5)), size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Bài thở 2 phút', style: GB.body(15, w: FontWeight.w800)),
                    Text('Thở theo vòng tròn để thư giãn khi mẹ căng thẳng', style: GB.body(12.5, color: GB.inkMuted)),
                  ]),
                ),
                Icon(Icons.chevron_right_rounded, color: GB.inkMuted),
              ]),
            ),
            const SizedBox(height: 12),
            GlassCard(
              radius: 24,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Orb(icon: Icons.favorite_rounded, color: GB.p(Color(0xFFF8DEDF)), size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Tự kiểm tra tâm trạng sau sinh', style: GB.body(15, w: FontWeight.w800)),
                      Text('Thang EPDS · 10 câu · khoảng 2 phút', style: GB.body(12.5, color: GB.inkMuted)),
                    ]),
                  ),
                ]),
                if (last != null) ...[
                  const SizedBox(height: 10),
                  Callout(level: epdsOutcome(last.answers).level == 0 ? Level.ok : epdsOutcome(last.answers).level == 1 ? Level.note : Level.alert, title: 'Lần gần nhất ${GB.dmy(last.time)}: ${epdsOutcome(last.answers).title}', body: 'Điểm ${last.score}/30'),
                ],
                const SizedBox(height: 12),
                BigButton('Bắt đầu', icon: Icons.play_arrow_rounded, onTap: () => openPage(context, const EpdsScreen())),
                const SizedBox(height: 8),
                Text(kEpdsDisclaimer, style: GB.body(11.5, color: GB.inkMuted, height: 1.4)),
              ]),
            ),
            const SizedBox(height: 12),
            const Callout(level: Level.info, title: 'Mẹ không cần hoàn hảo', body: 'Ngủ khi bé ngủ, nhờ người thân phụ một cữ đêm, ăn đủ bữa và đi ra ngoài hít thở là những việc nhỏ nhưng quan trọng. Nếu mẹ thấy buồn kéo dài trên 2 tuần, hãy nói với bác sĩ.'),
          ],
        );
      },
    );
  }

  void _moodSheet(BuildContext context, int mood) {
    final note = TextEditingController();
    showGlassSheet(context, builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Orb(icon: _moods[mood].$2, color: _moods[mood].$3, size: 44), const SizedBox(width: 12), Text(_moods[mood].$1, style: GB.display(24, w: FontWeight.w700))]),
          const SizedBox(height: 12),
          GlassField(controller: note, label: 'Mẹ muốn ghi thêm điều gì? (tuỳ chọn)', maxLines: 3),
          const SizedBox(height: 14),
          BigButton('Lưu', icon: Icons.check_rounded, onTap: () {
            app.addMood(MoodEntry(time: DateTime.now(), mood: mood, note: note.text.trim()));
            Navigator.pop(ctx);
          }),
        ]));
  }

  void _breathe(BuildContext context) {
    showGlassSheet(context, builder: (ctx) => const _Breathing());
  }
}

class _Breathing extends StatefulWidget {
  const _Breathing();

  @override
  State<_Breathing> createState() => _BreathingState();
}

class _BreathingState extends State<_Breathing> with SingleTickerProviderStateMixin {
  // thở hộp 4-4-4-4 giây
  late final AnimationController c = AnimationController(vsync: this, duration: const Duration(seconds: 16))..repeat();

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  (String, double) _phase(double t) {
    final s = t * 16;
    if (s < 4) return ('Hít vào', s / 4);
    if (s < 8) return ('Giữ hơi', 1);
    if (s < 12) return ('Thở ra', 1 - (s - 8) / 4);
    return ('Giữ hơi', 0);
  }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text('Thở hộp 4-4-4-4', style: GB.display(22, w: FontWeight.w700)),
      const SizedBox(height: 4),
      Text('Hít 4 giây · giữ 4 · thở ra 4 · giữ 4', style: GB.body(13, color: GB.inkMuted)),
      const SizedBox(height: 18),
      SizedBox(
        height: 220,
        child: AnimatedBuilder(
          animation: c,
          builder: (context, _) {
            final p = _phase(c.value);
            final eased = Curves.easeInOut.transform(p.$2);
            final size = 90 + 110 * eased;
            return Center(
              child: Stack(alignment: Alignment.center, children: [
                Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: GB.p(Color(0xFFDCEBF5)).withValues(alpha: .6 + .3 * eased), border: Border.all(color: Colors.white, width: 3))),
                Text(p.$1, style: GB.display(24)),
              ]),
            );
          },
        ),
      ),
      const SizedBox(height: 8),
      BigButton('Xong', onTap: () => Navigator.pop(context)),
    ]);
  }
}

class EpdsScreen extends StatefulWidget {
  const EpdsScreen({super.key});

  @override
  State<EpdsScreen> createState() => _EpdsScreenState();
}

class _EpdsScreenState extends State<EpdsScreen> {
  int i = 0;
  final answers = List<int?>.filled(kEpds.length, null);
  EpdsOutcome? outcome;

  @override
  Widget build(BuildContext context) {
    if (outcome != null) {
      final o = outcome!;
      return SubPage(
        title: 'Kết quả',
        children: [
          Callout(level: o.level == 0 ? Level.ok : o.level == 1 ? Level.note : Level.alert, title: o.title, body: o.body),
          if (o.urgent) ...[
            const SizedBox(height: 12),
            const Callout(level: Level.alert, title: 'Gọi 115 hoặc đến cơ sở y tế gần nhất', body: 'Hãy ở cạnh người thân, đừng ở một mình. Nói với họ mẹ cần được giúp đỡ ngay.'),
          ],
          const SizedBox(height: 12),
          Text(kEpdsDisclaimer, style: GB.body(11.5, color: GB.inkMuted, height: 1.4)),
          const SizedBox(height: 16),
          BigButton('Xong', onTap: () => Navigator.of(context).pop()),
        ],
      );
    }
    final q = kEpds[i];
    final sel = answers[i];
    return SubPage(
      title: 'Tự kiểm tra',
      subtitle: 'Câu ${i + 1}/${kEpds.length}',
      bottom: Row(children: [
        if (i > 0) ...[Expanded(child: BigButton('Quay lại', color: GB.w(.7), fg: GB.ink, onTap: () => setState(() => i--))), const SizedBox(width: 10)],
        Expanded(
          flex: 2,
          child: BigButton(i == kEpds.length - 1 ? 'Xem kết quả' : 'Tiếp', enabled: sel != null, onTap: () {
            if (i == kEpds.length - 1) {
              final a = answers.map((e) => e ?? 0).toList();
              app.addEpds(EpdsResult(time: DateTime.now(), answers: a));
              setState(() => outcome = epdsOutcome(a));
            } else {
              setState(() => i++);
            }
          }),
        ),
      ]),
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: (i + 1) / kEpds.length, minHeight: 6, backgroundColor: GB.w(.7), valueColor: AlwaysStoppedAnimation(GB.accent))),
        const SizedBox(height: 14),
        if (i == 0) Padding(padding: const EdgeInsets.only(bottom: 12), child: Callout(level: Level.info, title: 'Trong 7 ngày qua', body: kEpdsIntro)),
        Text(q.text, style: GB.display(24, w: FontWeight.w700)),
        const SizedBox(height: 16),
        for (final o in q.options)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              radius: 20,
              tint: sel == o.$2 ? GB.warnBg : null,
              opacity: sel == o.$2 ? .9 : .5,
              onTap: () => setState(() => answers[i] = o.$2),
              child: Row(children: [
                Icon(sel == o.$2 ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: sel == o.$2 ? GB.accentDeep : GB.inkMuted),
                const SizedBox(width: 12),
                Expanded(child: Text(o.$1, style: GB.body(15, w: FontWeight.w600))),
              ]),
            ),
          ),
        const SizedBox(height: 4),
        Text('Bản dịch tham khảo, chưa được kiểm chứng.', style: GB.body(11.5, color: GB.inkMuted)),
      ],
    );
  }
}

double sinPulse(double t) => math.sin(t * math.pi * 2);
