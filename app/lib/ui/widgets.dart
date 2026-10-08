import 'package:flutter/material.dart';

import '../core/kit.dart';
import '../core/pickers.dart';
import '../core/theme.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import '../domain/feeding_ref.dart';
import '../domain/pump_ref.dart';

Color kindColor(String type) {
  switch (type) {
    case T.feed:
      return GB.feed;
    case T.sleep:
      return GB.sleep;
    case T.diaper:
      return GB.diaper;
    case T.pump:
      return GB.pump;
    case T.temp:
    case T.med:
      return GB.health;
    case T.solid:
      return const Color(0xFFB9C98A);
    default:
      return GB.inkMuted;
  }
}

IconData kindIcon(String type) {
  switch (type) {
    case T.feed:
      return Icons.local_drink_rounded;
    case T.sleep:
      return Icons.bedtime_rounded;
    case T.diaper:
      return Icons.water_drop_rounded;
    case T.pump:
      return Icons.favorite_rounded;
    case T.temp:
      return Icons.thermostat_rounded;
    case T.med:
      return Icons.medication_rounded;
    case T.solid:
      return Icons.restaurant_rounded;
    default:
      return Icons.edit_note_rounded;
  }
}

/// Mô tả một bản ghi trên dòng thời gian.
String entryTitle(Entry e) {
  switch (e.type) {
    case T.feed:
      if (e.str('method') == 'breast') {
        final side = e.str('side');
        final s = side == 'L' ? 'trái' : side == 'R' ? 'phải' : 'hai bên';
        return 'Bú mẹ $s · ${e.num('min').round()} phút';
      }
      final src = e.str('source') == 'formula' ? 'sữa công thức' : 'sữa mẹ';
      return 'Bú bình · ${e.ml}ml $src';
    case T.sleep:
      if (e.end == null) return 'Đang ngủ…';
      return 'Ngủ · ${GB.dur(e.end!.difference(e.time))}';
    case T.diaper:
      final k = e.str('kind');
      if (k == 'wet') return 'Tã ướt';
      final cs = e.str('state');
      final co = e.str('color');
      final base = k == 'both' ? 'Ướt + phân' : 'Phân';
      return [base, if (cs.isNotEmpty) cs.toLowerCase(), if (co.isNotEmpty) co.toLowerCase()].join(' · ').replaceFirst(' · ', ' · ');
    case T.pump:
      return 'Hút sữa · ${e.ml}ml (${e.num('l').round()} + ${e.num('r').round()})';
    case T.temp:
      return 'Nhiệt độ ${GB.num1(e.num('v'))}°C';
    case T.med:
      return 'Thuốc · ${e.str('name')}${e.str('dose').isEmpty ? '' : ' ${e.str('dose')}'}';
    case T.solid:
      return 'Ăn dặm · ${e.str('food')}';
    default:
      return e.str('text', 'Ghi chú');
  }
}

/// Dòng bản ghi (bấm để sửa, giữ để xoá).
class EntryRow extends StatelessWidget {
  const EntryRow(this.e, {super.key, this.showDay = false});
  final Entry e;
  final bool showDay;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showEntrySheet(context, e),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(children: [
          SizedBox(width: 48, child: Text(GB.hm(e.time), style: GB.body(13, color: GB.inkMuted))),
          Container(width: 10, height: 10, decoration: BoxDecoration(color: kindColor(e.type), shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(child: Text(entryTitle(e), style: GB.body(14.5))),
          if (e.data['photo'] != null) Icon(Icons.photo_camera_rounded, size: 16, color: GB.inkMuted),
        ]),
      ),
    );
  }
}

/// Sửa giờ / xoá một bản ghi.
Future<void> showEntrySheet(BuildContext context, Entry e) {
  return showGlassSheet(context, builder: (ctx) {
    return StatefulBuilder(builder: (ctx, setS) {
      return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Orb(icon: kindIcon(e.type), color: kindColor(e.type)),
          const SizedBox(width: 12),
          Expanded(child: Text(entryTitle(e), style: GB.display(20, w: FontWeight.w700))),
        ]),
        const SizedBox(height: 14),
        _row('Thời gian', GB.dmyhm(e.time), () async {
          final d = await pickDateTime(ctx, e.time);
          if (d != null) {
            final dur = e.end?.difference(e.time);
            e.time = d;
            if (dur != null) e.end = d.add(dur);
            app.updateEntry(e);
            setS(() {});
          }
        }),
        if (e.type == T.sleep && e.end != null)
          _row('Dậy lúc', GB.dmyhm(e.end!), () async {
            final d = await pickDateTime(ctx, e.end!);
            if (d != null && d.isAfter(e.time)) {
              e.end = d;
              app.updateEntry(e);
              setS(() {});
            }
          }),
        if (e.type == T.feed && e.str('method') == 'bottle')
          _row('Lượng sữa', '${e.ml} ml', () async {
            final c = TextEditingController(text: '${e.ml}');
            final v = await showDialog<int>(
              context: ctx,
              builder: (dctx) => GlassAlert(
                backgroundColor: GB.cream,
                title: Text('Sửa lượng sữa', style: GB.display(20, w: FontWeight.w700)),
                content: GlassField(controller: c, label: 'ml', keyboard: TextInputType.number, suffix: 'ml'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(dctx), child: Text('Huỷ', style: GB.body(14, w: FontWeight.w700, color: GB.inkMuted))),
                  TextButton(onPressed: () => Navigator.pop(dctx, int.tryParse(c.text)), child: Text('Lưu', style: GB.body(14, w: FontWeight.w800, color: GB.accentDeep))),
                ],
              ),
            );
            if (v != null && v >= 0) {
              e.data['ml'] = v;
              app.updateEntry(e);
              setS(() {});
            }
          }),
        if (e.data['note'] != null && (e.data['note'] as String).isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Ghi chú: ${e.data['note']}', style: GB.body(13.5, color: GB.inkMuted))),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(child: BigButton('Xong', onTap: () => Navigator.pop(ctx), height: 50)),
          const SizedBox(width: 10),
          RoundIconButton(
            icon: Icons.delete_outline_rounded,
            label: 'Xoá bản ghi',
            size: 50,
            onTap: () async {
              final ok = await confirmDialog(ctx, 'Xoá bản ghi?', 'Bản ghi này sẽ bị xoá khỏi nhật ký.');
              if (ok && ctx.mounted) {
                app.removeEntry(e.id);
                Navigator.pop(ctx);
              }
            },
          ),
        ]),
      ]);
    });
  });
}

Widget _row(String label, String value, VoidCallback onTap) => InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(children: [
          SizedBox(width: 100, child: Text(label, style: GB.body(13, w: FontWeight.w600, color: GB.inkMuted))),
          Expanded(child: Text(value, style: GB.body(15, w: FontWeight.w700))),
          Text('Sửa', style: GB.body(13, w: FontWeight.w700, color: GB.accentDeep)),
        ]),
      ),
    );

/// Hàng chọn thời gian có nút "Sửa".
class TimeRow extends StatelessWidget {
  const TimeRow({super.key, required this.time, required this.onChanged, this.label = 'Lúc'});
  final DateTime time;
  final ValueChanged<DateTime> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isNow = now.difference(time).inMinutes.abs() < 2;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        final d = await pickDateTime(context, time, last: DateTime.now());
        if (d != null) onChanged(d);
      },
      child: GlassCard(
        radius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        blur: 14,
        child: Row(children: [
          Icon(Icons.schedule_rounded, size: 22, color: GB.ink),
          const SizedBox(width: 12),
          Text(isNow ? 'Bây giờ' : label, style: GB.body(13, w: FontWeight.w700, color: isNow ? GB.ok : GB.inkMuted)),
          const SizedBox(width: 10),
          Expanded(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(GB.dmyhm(time), style: GB.body(15, w: FontWeight.w700)))),
          Text('Sửa', style: GB.body(13, w: FontWeight.w700, color: GB.accentDeep)),
        ]),
      ),
    );
  }
}

Level levelOfFeed(Verdict v) {
  switch (v) {
    case Verdict.ok:
      return Level.ok;
    case Verdict.unknown:
      return Level.info;
    default:
      return Level.note;
  }
}

class FeedAssessmentCard extends StatelessWidget {
  const FeedAssessmentCard(this.a, {super.key});
  final FeedAssessment a;

  @override
  Widget build(BuildContext context) {
    return Callout(
      level: levelOfFeed(a.verdict),
      title: a.title,
      body: a.message,
      children: [
        for (final t in a.tips)
          Padding(padding: const EdgeInsets.only(top: 4), child: Text('• $t', style: GB.body(12.5, color: GB.inkMuted, height: 1.4))),
      ],
    );
  }
}

class PumpAssessmentCard extends StatelessWidget {
  const PumpAssessmentCard(this.a, {super.key});
  final PumpAssessment a;

  @override
  Widget build(BuildContext context) {
    final lvl = a.verdict == PumpVerdict.good || a.verdict == PumpVerdict.much
        ? Level.ok
        : a.verdict == PumpVerdict.typical
            ? Level.info
            : Level.note;
    return Callout(
      level: lvl,
      title: a.title,
      body: a.message,
      children: [
        for (final t in a.tips) Padding(padding: const EdgeInsets.only(top: 4), child: Text('• $t', style: GB.body(12.5, color: GB.inkMuted, height: 1.4))),
      ],
    );
  }
}

const kFeedSource =
    'Nguồn tham khảo: AAP/HealthyChildren, Kent 2006 (Pediatrics), tài liệu hướng dẫn nuôi dưỡng trong nước. Chỉ mang tính tham khảo, không thay thế tư vấn của bác sĩ.';

/// Thẻ tổng kết bú trong ngày: tổng ml so với khoảng thường gặp.
class DayFeedCard extends StatelessWidget {
  const DayFeedCard({super.key, this.day, this.compact = false});
  final DateTime? day;
  final bool compact; // gọn: bỏ số lớn (đã có ở thẻ Tổng quan)

  @override
  Widget build(BuildContext context) {
    final d = day ?? DateTime.now();
    final baby = app.baby!;
    final age = app.age;
    final tot = app.feedTotals(d);
    final da = FeedingRef.day(age.adjDays, app.weightKg, tot.total);
    final feeds = FeedingRef.feedsPerDay(age.adjDays);
    final wet = app.diaperCount(d, wet: true);
    final wetMin = FeedingRef.wetDiapersMin(age.days);
    final bottle = tot.bottleMom + tot.bottleFormula;
    final level = tot.total >= da.range.lo ? (tot.total <= da.range.hi ? Level.ok : Level.note) : Level.info;
    final isToday = AppState.dayStart(d) == AppState.dayStart(DateTime.now());

    String msg;
    if (tot.total == 0) {
      msg = 'Chưa có cữ bú nào được ghi hôm nay.';
    } else if (tot.total < da.range.lo) {
      msg = isToday ? 'Còn khoảng ${(da.range.lo - tot.total).round()}ml nữa để chạm mức thường gặp. Bé còn thời gian trong ngày.' : 'Ít hơn mức thường gặp. Nếu bé vẫn vui, ngủ tốt và đủ tã ướt thì không có gì lo, nhưng hãy theo dõi vài ngày.';
    } else if (tot.total <= da.range.hi) {
      msg = 'Nằm trong khoảng thường gặp cho bé ${GB.num1(app.weightKg)}kg.';
    } else {
      msg = 'Nhiều hơn khoảng thường gặp. Bé có thể đang tăng tốc tăng trưởng; cho bú chậm và quan sát ọc sữa.';
    }

    return GlassCard(
      radius: 24,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (compact)
          Row(children: [
            Icon(Icons.local_drink_rounded, size: 20, color: GB.breastDeep),
            const SizedBox(width: 6),
            Expanded(child: Text('Đánh giá lượng sữa', style: GB.body(14.5, w: FontWeight.w800))),
            Text('${tot.total}ml · thường gặp ${da.range.text()}', style: GB.body(11.5, w: FontWeight.w600, color: GB.inkMuted)),
          ])
        else ...[
          Row(children: [
            Expanded(child: Text(isToday ? 'Sữa hôm nay' : 'Sữa ngày ${GB.dmy(d)}', style: GB.body(13, w: FontWeight.w700, color: GB.inkMuted))),
            Text('${tot.count} cữ', style: GB.body(12.5, w: FontWeight.w700, color: GB.inkMuted)),
          ]),
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text('${tot.total}', style: GB.display(38)),
            const SizedBox(width: 4),
            Text('ml', style: GB.body(15, w: FontWeight.w700, color: GB.inkMuted)),
            const SizedBox(width: 8),
            Expanded(child: Text('thường gặp ${da.range.text()}', textAlign: TextAlign.right, style: GB.body(12.5, w: FontWeight.w600, color: GB.inkMuted))),
          ]),
        ],
        RangeBar(value: tot.total.toDouble(), lo: da.range.lo, hi: da.range.hi),
        const SizedBox(height: 8),
        Text(
          baby.mode == FeedMode.breast ? 'Bé bú mẹ trực tiếp: ml là ước tính. ' : (tot.breastEst > 0 ? 'Gồm ${tot.breastEst}ml bú trực tiếp (ước tính). ' : ''),
          style: GB.body(12, color: GB.inkMuted),
        ),
        const SizedBox(height: 2),
        Callout(level: level, title: tot.total == 0 ? 'Chưa có dữ liệu' : (level == Level.ok ? 'Tổng ngày phù hợp' : 'Gợi ý'), body: msg),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 6, children: [
          Tag('${tot.count}/${feeds.text('')} cữ', bg: GB.warnBg, fg: GB.warn),
          Tag('Tã ướt $wet (≥$wetMin)', bg: wet >= wetMin ? GB.okBg : GB.infoBg, fg: wet >= wetMin ? GB.ok : GB.info),
          if (bottle > 0) Tag('Bình ${bottle}ml', bg: GB.infoBg, fg: GB.info),
        ]),
        const SizedBox(height: 8),
        Text(da.cap ? 'Mức tối đa ~960ml/ngày theo AAP.' : (da.note.isEmpty ? '≈ ${da.perKg.text('')} ml/kg/ngày' : da.note), style: GB.body(11.5, color: GB.inkMuted)),
      ]),
    );
  }
}
