import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/kit.dart';
import '../core/pickers.dart';
import '../core/theme.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import '../domain/feeding_ref.dart';
import 'bottle.dart';
import 'widgets.dart';

/// Ghi bú: bình (vuốt mực sữa) hoặc bú mẹ trực tiếp (bấm giờ), kèm đánh giá theo tuổi và cân nặng.
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late int tab = widget.initialTab;
  bool mom = true;
  int ml = 120;
  DateTime time = DateTime.now();
  FridgeItem? fridgeBottle;
  Timer? _t;
  int? estOverride;

  @override
  void initState() {
    super.initState();
    final age = app.age.adjDays;
    final r = FeedingRef.perFeed(age);
    ml = ((r.mid / 10).round() * 10).clamp(10, 360);
    final last = app.lastFeed;
    if (last != null && last.str('method') == 'bottle' && last.ml > 0) {
      ml = last.ml;
      mom = last.str('source') != 'formula';
    }
    if (app.baby!.mode == FeedMode.formula) mom = false;
    if (app.settings.breastStart != null) tab = 1;
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && app.settings.breastStart != null && app.settings.breastEnd == null) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  int get cap {
    final age = app.age.adjDays;
    var c = age < 28 ? 120 : age < 180 ? 240 : 360;
    final need = math.max(ml, fridgeBottle?.left ?? 0);
    while (c < need) {
      c += 120;
    }
    return c;
  }

  void _pickFridge(FridgeItem? f) {
    setState(() {
      fridgeBottle = f;
      if (f != null) {
        final r = FeedingRef.perFeed(app.age.adjDays);
        ml = math.min(f.left, ((r.mid / 10).round() * 10)).clamp(10, 360);
      }
    });
  }

  Future<void> _saveBottle() async {
    final age = app.age.adjDays;
    final a = FeedingRef.feed(ml, age, expressedMilk: mom);
    final fb = fridgeBottle;
    app.addBottle(ml: ml, source: mom ? 'mom' : 'formula', fridgeId: fb?.id, time: time);
    if (!mounted) return;
    await showGlassSheet(context, builder: (ctx) {
      final tot = app.feedTotals(time);
      final da = FeedingRef.day(age, app.weightKg, tot.total);
      return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Orb(icon: Icons.check_rounded, color: GB.okBg),
          const SizedBox(width: 12),
          Expanded(child: Text('Đã ghi ${ml}ml', style: GB.display(22, w: FontWeight.w700))),
        ]),
        const SizedBox(height: 14),
        FeedAssessmentCard(a),
        if (fb != null && fb.left > 0 && fb.ml > ml) ...[
          const SizedBox(height: 10),
          Callout(level: Level.info, title: 'Đổ bỏ ${fb.ml - ml}ml', body: 'Phần sữa còn lại trong bình sau khi bé bú được đổ bỏ (đã tiếp xúc nước bọt).'),
        ],
        const SizedBox(height: 12),
        Text('Cả ngày: ${tot.total}ml · thường gặp ${da.range.text()}', style: GB.body(13.5, w: FontWeight.w700)),
        const SizedBox(height: 6),
        RangeBar(value: tot.total.toDouble(), lo: da.range.lo, hi: da.range.hi),
        const SizedBox(height: 10),
        Text(kFeedSource, style: GB.body(11.5, color: GB.inkMuted, height: 1.4)),
        const SizedBox(height: 14),
        BigButton('Xong', onTap: () => Navigator.pop(ctx)),
      ]);
    });
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final baby = app.baby!;
    final age = app.age;
    final assessment = tab == 0 ? FeedingRef.feed(ml, age.adjDays, expressedMilk: mom) : null;
    final range = FeedingRef.perFeed(age.adjDays);
    final fridge = app.fridgeActive.where((f) => f.expires.isAfter(DateTime.now())).toList();

    return SubPage(
      title: 'Ghi bú',
      subtitle: 'Bé ${age.short} · ${GB.num1(app.weightKg)}kg${age.preterm ? ' · tuổi hiệu chỉnh' : ''}',
      art: 'hero_mom_baby',
      artWidth: 150,
      bottom: tab == 0
          ? BigButton('Lưu · ${ml}ml', icon: Icons.check_rounded, enabled: ml > 0, onTap: _saveBottle)
          : null,
      children: [
        Seg(labels: const ['Bình', 'Bú mẹ trực tiếp'], index: tab, onChanged: (i) => setState(() => tab = i)),
        const SizedBox(height: 12),
        if (tab == 0) ...[
          TimeRow(time: time, onChanged: (d) => setState(() => time = d)),
          const SizedBox(height: 12),
          Seg(labels: const ['Sữa mẹ', 'Sữa công thức'], index: mom ? 0 : 1, height: 40, onChanged: (i) => setState(() {
                mom = i == 0;
                if (!mom) fridgeBottle = null;
              })),
          if (mom && fridge.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 44,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                PillChip(label: 'Sữa mới / khác', on: fridgeBottle == null, onTap: () => _pickFridge(null), height: 44),
                for (final f in fridge) ...[
                  const SizedBox(width: 8),
                  PillChip(label: '${f.freezer ? 'Đông' : 'Mát'} ${f.left}ml · ${_left(f)}', on: fridgeBottle?.id == f.id, onTap: () => _pickFridge(f), height: 44),
                ],
              ]),
            ),
          ],
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Bé uống', style: GB.body(13, w: FontWeight.w600, color: GB.inkMuted)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, mainAxisSize: MainAxisSize.min, children: [
                    Text('$ml', style: GB.display(64)),
                    const SizedBox(width: 4),
                    Text('ml', style: GB.body(18, w: FontWeight.w700, color: GB.inkMuted)),
                  ]),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  RoundIconButton(icon: Icons.remove_rounded, label: 'Giảm 10ml', onTap: () => setState(() => ml = math.max(0, ml - 10)), size: 52),
                  const SizedBox(width: 10),
                  RoundIconButton(icon: Icons.add_rounded, label: 'Tăng 10ml', filled: true, onTap: () => setState(() => ml = math.min(cap, ml + 10)), size: 52),
                ]),
                const SizedBox(height: 10),
                Text('Vuốt trên bình để chỉnh.\nThường gặp ${range.text()}', style: GB.body(12.5, color: GB.inkMuted, height: 1.4)),
              ]),
            ),
            BottleView(ml: ml, cap: cap, width: math.min(204.0, (MediaQuery.of(context).size.width - 32) * .5), color: mom ? GB.milkBottle : GB.milkFormula, onChanged: (v) => setState(() => ml = v)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            for (final v in _presets(range)) ...[
              Expanded(child: PillChip(label: '$v', on: v == ml, height: 44, hPad: 4, onTap: () => setState(() => ml = v))),
              if (v != _presets(range).last) const SizedBox(width: 8),
            ]
          ]),
          const SizedBox(height: 14),
          if (assessment != null) FeedAssessmentCard(assessment),
          if (fridgeBottle != null && ml < fridgeBottle!.left) ...[
            const SizedBox(height: 10),
            Callout(level: Level.info, title: 'Bình ${fridgeBottle!.left}ml, bé uống ${ml}ml', body: 'Còn ${fridgeBottle!.left - ml}ml sẽ được đổ bỏ sau khi lưu.'),
          ],
          const SizedBox(height: 10),
          Text(kFeedSource, style: GB.body(11.5, color: GB.inkMuted, height: 1.4)),
        ] else
          _breast(baby),
      ],
    );
  }

  String _left(FridgeItem f) {
    final d = f.expires.difference(DateTime.now());
    if (d.inDays >= 2) return '${d.inDays} ngày';
    if (d.inHours >= 1) return '${d.inHours}h';
    return '${d.inMinutes}p';
  }

  List<int> _presets(Range r) {
    final base = (r.lo / 10).round() * 10;
    final top = (r.hi / 10).round() * 10;
    final mid = (r.mid / 10).round() * 10;
    final set = <int>{math.max(10, base - 30), math.max(10, base), mid, top, top + 30}.toList()..sort();
    return set.take(5).toList();
  }

  Future<void> _pickBreast({required bool isStart}) async {
    final s = app.settings;
    final now = DateTime.now();
    if (!isStart && s.breastStart == null) {
      toast(context, 'Hãy nhập giờ bắt đầu bú trước');
      return;
    }
    final d = await pickDateTime(context, (isStart ? s.breastStart : s.breastEnd) ?? now, last: now, title: isStart ? 'Giờ bắt đầu bú' : 'Giờ kết thúc bú');
    if (d == null || !mounted) return;
    if (isStart) {
      if (s.breastEnd != null && !d.isBefore(s.breastEnd!)) {
        toast(context, 'Giờ bắt đầu phải trước giờ kết thúc');
        return;
      }
      s.breastStart = d;
    } else {
      if (!d.isAfter(s.breastStart!)) {
        toast(context, 'Giờ kết thúc phải sau giờ bắt đầu');
        return;
      }
      s.breastEnd = d;
    }
    app.settingsChanged();
    setState(() {});
  }

  void _quickBreast(int mins) {
    final s = app.settings;
    final now = DateTime.now();
    final st = s.breastStart;
    if (st != null && !st.add(Duration(minutes: mins)).isAfter(now)) {
      s.breastEnd = st.add(Duration(minutes: mins));
    } else {
      s.breastEnd = now;
      s.breastStart = now.subtract(Duration(minutes: mins));
    }
    app.settingsChanged();
    setState(() {});
  }

  void _resetBreast() {
    final s = app.settings;
    s.breastStart = null;
    s.breastEnd = null;
    estOverride = null;
    app.settingsChanged();
    setState(() {});
  }

  Widget _breastTimeRow(String label, DateTime? t, String empty, VoidCallback onTap) => GestureDetector(
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

  Widget _breast(Baby baby) {
    final s = app.settings;
    final st = s.breastStart;
    final en = s.breastEnd;
    final running = st != null && en == null;
    final ready = st != null && en != null;
    final age = app.age.adjDays;
    final elapsed = st == null ? Duration.zero : (en ?? DateTime.now()).difference(st);
    final minutes = math.max(1, elapsed.inMinutes);
    final est = estOverride ?? FeedingRef.breastEstimate(age, minutes);
    final fr = FeedingRef.feedsPerDay(age);
    final todayCount = app.entriesOn(DateTime.now(), type: T.feed).length;

    String clock(Duration d) => '${GB.two(d.inMinutes)}:${GB.two(d.inSeconds % 60)}';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Seg(labels: const ['Trái', 'Phải', 'Hai bên'], index: const ['L', 'R', 'B'].indexOf(s.breastSide), height: 40, onChanged: (i) {
        s.breastSide = const ['L', 'R', 'B'][i];
        app.settingsChanged();
        setState(() {});
      }),
      const SizedBox(height: 12),
      GlassCard(
        radius: 26,
        child: Column(children: [
          Text(running ? 'Đang bú' : (ready ? 'Cữ bú đã sẵn sàng để lưu' : 'Bú mẹ trực tiếp'), style: GB.body(13, w: FontWeight.w700, color: GB.inkMuted)),
          const SizedBox(height: 4),
          Text(st == null ? '00:00' : clock(elapsed), style: GB.display(64)),
          const SizedBox(height: 8),
          _breastTimeRow('Bắt đầu', st, 'Chưa nhập', () => _pickBreast(isStart: true)),
          Divider(height: 1, color: GB.ink.withValues(alpha: .08)),
          _breastTimeRow('Kết thúc', en, running ? 'Đang bú…' : 'Chưa nhập', () => _pickBreast(isStart: false)),
          const SizedBox(height: 12),
          if (ready)
            Row(children: [
              Expanded(
                child: BigButton('Lưu cữ bú ${GB.dur(elapsed)}', icon: Icons.check_rounded, onTap: () {
                  final saved = app.addBreast(start: st, end: en, side: s.breastSide, mlEst: estOverride);
                  final text = GB.dur(elapsed);
                  _resetBreast();
                  toast(context, 'Đã ghi bú mẹ $text', undo: () => app.removeEntry(saved.id));
                  Navigator.of(context).pop();
                }),
              ),
              const SizedBox(width: 10),
              RoundIconButton(icon: Icons.refresh_rounded, label: 'Làm lại', onTap: _resetBreast),
            ])
          else if (running)
            Row(children: [
              Expanded(
                child: BigButton('Dừng ngay', icon: Icons.stop_rounded, color: GB.accent, fg: GB.ink, onTap: () {
                  s.breastEnd = DateTime.now();
                  app.settingsChanged();
                  setState(() {});
                }),
              ),
              const SizedBox(width: 10),
              RoundIconButton(icon: Icons.close_rounded, label: 'Huỷ cữ bú', onTap: _resetBreast),
            ])
          else
            BigButton('Bú ngay', icon: Icons.play_arrow_rounded, color: GB.accent, fg: GB.ink, onTap: () {
              s.breastStart = DateTime.now();
              s.breastEnd = null;
              app.settingsChanged();
              setState(() {});
            }),
          if (!ready) ...[
            const SizedBox(height: 14),
            Text('Hoặc nhập nhanh thời lượng', style: GB.body(12.5, color: GB.inkMuted)),
            const SizedBox(height: 8),
            Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
              for (final m in const [5, 10, 15, 20, 30]) PillChip(label: '$m phút', on: false, height: 40, onTap: () => _quickBreast(m)),
            ]),
          ],
        ]),
      ),
      const SizedBox(height: 12),
      GlassCard(
        radius: 20,
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('Lượng sữa ước tính', style: GB.body(13.5, w: FontWeight.w700))),
            RoundIconButton(icon: Icons.remove_rounded, label: 'Giảm 10ml', size: 40, onTap: () => setState(() => estOverride = math.max(0, est - 10))),
            const SizedBox(width: 10),
            SizedBox(width: 64, child: Text('~${est}ml', textAlign: TextAlign.center, style: GB.body(16, w: FontWeight.w800))),
            const SizedBox(width: 10),
            RoundIconButton(icon: Icons.add_rounded, label: 'Tăng 10ml', size: 40, filled: true, onTap: () => setState(() => estOverride = est + 10)),
          ]),
          const SizedBox(height: 6),
          Text('Bú trực tiếp không đo được. Số này ước tính theo tuổi và thời gian bú (Kent 2006: trung bình ~106–126ml mỗi cữ lúc 1–6 tháng), chỉ để tham khảo.', style: GB.body(11.5, color: GB.inkMuted, height: 1.4)),
        ]),
      ),
      const SizedBox(height: 12),
      Callout(
        level: Level.info,
        title: 'Hôm nay $todayCount cữ · thường gặp ${fr.text('')} cữ',
        body: 'Với bé bú mẹ, đừng đo từng cữ. Hãy xem bé có bú đều, tã ướt đủ (≥${FeedingRef.wetDiapersMin(app.age.days)} cái/ngày) và tăng cân đều không.',
      ),
      const SizedBox(height: 10),
      Text(kFeedSource, style: GB.body(11.5, color: GB.inkMuted, height: 1.4)),
    ]);
  }
}
