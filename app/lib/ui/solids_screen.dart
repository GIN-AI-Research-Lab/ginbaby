import 'package:flutter/material.dart';

import '../core/kit.dart';
import '../core/theme.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import '../domain/solids.dart';
import 'widgets.dart';

/// Theo dõi ăn dặm: bữa ăn, thực phẩm đã thử, phản ứng dị ứng.
class SolidsScreen extends StatelessWidget {
  const SolidsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final months = app.age.days / 30.4375;
        final entries = app.ofType(T.solid).toList();
        final tried = <String, ({DateTime first, String reaction})>{};
        for (final e in entries.reversed) {
          final foods = List<String>.from((e.data['foods'] as List?) ?? const []);
          final r = e.str('reaction', 'none');
          for (final f in foods) {
            final prev = tried[f];
            final worse = prev == null ? r : _worse(prev.reaction, r);
            tried[f] = (first: prev?.first ?? e.time, reaction: worse);
          }
        }
        final stage = kSolidStages.lastWhere((s) => months >= s.fromMonths, orElse: () => kSolidStages.first);
        final recentNew = tried.entries.where((x) => DateTime.now().difference(x.value.first).inDays < 3).map((x) => x.key).toList();
        final reactions = tried.entries.where((x) => x.value.reaction != 'none').toList();

        return SubPage(
          title: 'Ăn dặm',
          subtitle: 'Bé ${app.age.short} · những miếng ăn đầu đời',
          art: 'hero_baby_awake',
          artWidth: 110,
          bottom: BigButton('Ghi bữa ăn dặm', icon: Icons.restaurant_rounded, onTap: () => _logSheet(context, tried)),
          children: [
            if (months < 6)
              Callout(level: Level.info, title: months < 4 ? 'Chưa đến lúc ăn dặm' : 'Sắp đến lúc ăn dặm', body: 'WHO khuyến cáo bắt đầu từ khi bé đủ 6 tháng (180 ngày), trước đó chỉ cần sữa. Hãy chờ đến khi bé ngồi được, giữ đầu vững và quan tâm thức ăn.')
            else
              GlassCard(
                radius: 24,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Giai đoạn ${stage.title}', style: GB.body(13, w: FontWeight.w700, color: GB.inkMuted)),
                  const SizedBox(height: 4),
                  Text(stage.texture, style: GB.body(16, w: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(stage.meals, style: GB.body(13.5, color: GB.inkMuted)),
                ]),
              ),
            if (recentNew.isNotEmpty) ...[
              const SizedBox(height: 10),
              Callout(level: Level.note, title: 'Đang theo dõi: ${recentNew.join(', ')}', body: 'Chờ 3–5 ngày trước khi thử thực phẩm mới khác, nhất là nhóm dễ dị ứng.'),
            ],
            if (reactions.isNotEmpty) ...[
              const SizedBox(height: 10),
              Callout(level: reactions.any((x) => x.value.reaction == 'severe') ? Level.alert : Level.note, title: 'Thực phẩm có phản ứng: ${reactions.map((x) => x.key).join(', ')}', body: 'Hãy trao đổi với bác sĩ trước khi cho bé ăn lại các thực phẩm này.'),
            ],
            const SectionTitle('Thực phẩm đã thử'),
            for (final g in kFoodGroups)
              if (kFoods.any((f) => f.group == g)) ...[
                Padding(padding: const EdgeInsets.only(top: 8, bottom: 6), child: Text(g, style: GB.body(13, w: FontWeight.w800, color: GB.inkMuted))),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final f in kFoods.where((f) => f.group == g))
                    _foodChip(f, tried[f.name]),
                ]),
              ],
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.warning_amber_rounded, size: 16, color: GB.warn),
              const SizedBox(width: 6),
              Expanded(child: Text('Dấu cảnh báo: nhóm thực phẩm dễ gây dị ứng', style: GB.body(11.5, color: GB.inkMuted))),
            ]),
            const SectionTitle('Nhật ký ăn dặm'),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: entries.isEmpty ? const EmptyState('Chưa có bữa ăn dặm nào.') : Column(children: [for (final e in entries.take(30)) _row(e)]),
            ),
            const SizedBox(height: 10),
            Text(kSolidSource, style: GB.body(11.5, color: GB.inkMuted, height: 1.4)),
          ],
        );
      },
    );
  }

  static String _worse(String a, String b) {
    const o = {'none': 0, 'mild': 1, 'severe': 2};
    return (o[b] ?? 0) > (o[a] ?? 0) ? b : a;
  }

  Widget _foodChip(Food f, ({DateTime first, String reaction})? t) {
    Color bg = GB.w(.6);
    Color fg = GB.ink;
    IconData? ic;
    if (t != null) {
      if (t.reaction == 'severe') {
        bg = GB.alertBg;
        fg = GB.alert;
        ic = Icons.error_rounded;
      } else if (t.reaction == 'mild') {
        bg = GB.warnBg;
        fg = GB.warn;
        ic = Icons.report_rounded;
      } else {
        bg = GB.okBg;
        fg = GB.ok;
        ic = Icons.check_circle_rounded;
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18), border: Border.all(color: GB.w(.8))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (ic != null) ...[Icon(ic, size: 15, color: fg), const SizedBox(width: 5)],
        Text(f.name, style: GB.body(13, w: FontWeight.w600, color: fg)),
        if (f.allergen) ...[const SizedBox(width: 4), Icon(Icons.warning_amber_rounded, size: 14, color: GB.warn)],
      ]),
    );
  }

  Widget _row(Entry e) {
    final r = e.str('reaction', 'none');
    return Builder(
      builder: (context) => InkWell(
        onTap: () => showEntrySheet(context, e),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(children: [
            SizedBox(width: 74, child: Text(GB.dayLabel(e.time) == 'Hôm nay' ? GB.hm(e.time) : GB.dmy(e.time), style: GB.body(12.5, color: GB.inkMuted))),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.str('food'), style: GB.body(14.5, w: FontWeight.w700)),
                Text('Lượng: ${e.str('amount', 'vừa')}${e.str('note').isEmpty ? '' : ' · ${e.str('note')}'}', style: GB.body(12, color: GB.inkMuted)),
              ]),
            ),
            if (r != 'none') Tag(r == 'severe' ? 'Phản ứng nặng' : 'Phản ứng nhẹ', bg: r == 'severe' ? GB.alertBg : GB.warnBg, fg: r == 'severe' ? GB.alert : GB.warn),
          ]),
        ),
      ),
    );
  }

  void _logSheet(BuildContext context, Map<String, ({DateTime first, String reaction})> tried) {
    showGlassSheet(context, builder: (ctx) {
      final sel = <String>{};
      var amount = 'vừa';
      var reaction = 'none';
      var time = DateTime.now();
      final note = TextEditingController();
      return StatefulBuilder(builder: (ctx, setS) {
        final newOnes = sel.where((s) => !tried.containsKey(s)).toList();
        final newAllergens = newOnes.where((n) => kFoods.any((f) => f.name == n && f.allergen)).toList();
        return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Ghi bữa ăn dặm', style: GB.display(22, w: FontWeight.w700)),
          const SizedBox(height: 10),
          TimeRow(time: time, onChanged: (d) => setS(() => time = d)),
          const SizedBox(height: 12),
          for (final g in kFoodGroups)
            if (kFoods.any((f) => f.group == g)) ...[
              Padding(padding: const EdgeInsets.only(top: 6, bottom: 6), child: Text(g, style: GB.body(13, w: FontWeight.w800, color: GB.inkMuted))),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final f in kFoods.where((f) => f.group == g))
                  PillChip(label: '${f.name}${f.allergen ? ' *' : ''}', on: sel.contains(f.name), onTap: () => setS(() => sel.contains(f.name) ? sel.remove(f.name) : sel.add(f.name))),
              ]),
            ],
          const SizedBox(height: 12),
          Text('Lượng bé ăn', style: GB.body(13.5, w: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(children: [
            for (final a in const ['từ chối', 'ít', 'vừa', 'nhiều']) ...[
              Expanded(child: PillChip(label: a, on: amount == a, height: 42, onTap: () => setS(() => amount = a))),
              if (a != 'nhiều') const SizedBox(width: 6),
            ],
          ]),
          const SizedBox(height: 12),
          Text('Phản ứng sau ăn', style: GB.body(13.5, w: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: PillChip(label: 'Không', on: reaction == 'none', height: 42, onTap: () => setS(() => reaction = 'none'))),
            const SizedBox(width: 6),
            Expanded(child: PillChip(label: 'Nhẹ', on: reaction == 'mild', height: 42, color: GB.warnBg, onTap: () => setS(() => reaction = 'mild'))),
            const SizedBox(width: 6),
            Expanded(child: PillChip(label: 'Nặng', on: reaction == 'severe', height: 42, color: GB.alertBg, onTap: () => setS(() => reaction = 'severe'))),
          ]),
          if (reaction == 'severe') ...[
            const SizedBox(height: 10),
            const Callout(level: Level.alert, title: 'Phản ứng nặng: gọi cấp cứu 115', body: 'Khó thở, khò khè, sưng môi/mặt/lưỡi, nôn liên tục, tái xám hoặc li bì cần được cấp cứu ngay.'),
          ] else if (reaction == 'mild') ...[
            const SizedBox(height: 10),
            const Callout(level: Level.note, title: 'Phản ứng nhẹ', body: 'Dừng thực phẩm này, theo dõi và hỏi bác sĩ trước khi cho ăn lại. Nổi mẩn lan rộng hoặc nôn nhiều cần đi khám.'),
          ],
          if (newOnes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Callout(level: Level.info, title: 'Thực phẩm mới: ${newOnes.join(', ')}', body: newAllergens.isNotEmpty ? 'Có nhóm dễ dị ứng (${newAllergens.join(', ')}). Cho lượng nhỏ buổi sáng, theo dõi 3–5 ngày.' : 'Chỉ nên thử một thực phẩm mới mỗi lần và theo dõi vài ngày.'),
          ],
          const SizedBox(height: 10),
          GlassField(controller: note, label: 'Ghi chú (tuỳ chọn)'),
          const SizedBox(height: 14),
          BigButton('Lưu', icon: Icons.check_rounded, enabled: sel.isNotEmpty, onTap: () {
            app.addEntry(Entry(type: T.solid, time: time, data: {'foods': sel.toList(), 'food': sel.join(', '), 'amount': amount, 'reaction': reaction, if (note.text.trim().isNotEmpty) 'note': note.text.trim()}));
            Navigator.pop(ctx);
          }),
        ]);
      });
    });
  }
}
