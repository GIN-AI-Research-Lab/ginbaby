import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/kit.dart';
import '../core/theme.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import '../domain/feeding_ref.dart';
import '../domain/pump_ref.dart';
import 'bottle.dart';
import 'feed_screen.dart';
import 'pump_screen.dart';
import 'widgets.dart';

/// Tab Sữa: tổng quan hôm nay, tủ sữa (dùng bình sắp hết hạn trước), thống kê tách loại.
class MilkHub extends StatefulWidget {
  const MilkHub({super.key});

  @override
  State<MilkHub> createState() => _MilkHubState();
}

class _MilkHubState extends State<MilkHub> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        return SubPage(
          title: 'Tủ sữa',
          subtitle: 'Sữa hút, hạn dùng và thống kê',
          art: 'hero_pump',
          artWidth: 110,
          children: [
            Seg(labels: const ['Hôm nay', 'Tủ sữa', 'Thống kê'], index: tab, onChanged: (i) => setState(() => tab = i)),
            const SizedBox(height: 14),
            if (tab == 0) ..._today(),
            if (tab == 1) ..._fridgeTab(),
            if (tab == 2) ..._stats(),
          ],
        );
      },
    );
  }

  // ---------- Hôm nay ----------
  List<Widget> _today() {
    final now = DateTime.now();
    final age = app.age;
    final t = PumpRef.target(
      ageDays: age.adjDays,
      weightKg: app.weightKg,
      sessionsPerDay: app.settings.pumpSessions,
      pumpedToday: app.pumpedOn(now).toDouble(),
      sessionsDone: app.pumpSessionsOn(now),
      pumpShare: app.settings.pumpShare,
    );
    final pumped = app.pumpedOn(now);
    final tot = app.feedTotals(now);
    return [
      const DayFeedCard(),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: BigButton('Ghi bú', icon: Icons.local_drink_rounded, color: GB.accent, fg: GB.ink, height: 50, onTap: () => openPage(context, const FeedScreen()))),
        const SizedBox(width: 10),
        Expanded(child: BigButton('Ghi hút', icon: Icons.favorite_rounded, color: GB.pump, fg: GB.ink, height: 50, onTap: () => openPage(context, const PumpScreen()))),
      ]),
      const SectionTitle('Hút sữa hôm nay'),
      GlassCard(
        radius: 24,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('Đã hút', style: GB.body(13, w: FontWeight.w700, color: GB.inkMuted))),
            Text('${app.pumpSessionsOn(now)}/${app.settings.pumpSessions} cữ', style: GB.body(12.5, w: FontWeight.w700, color: GB.inkMuted)),
          ]),
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text('$pumped', style: GB.display(38)),
            const SizedBox(width: 4),
            Text('ml', style: GB.body(15, w: FontWeight.w700, color: GB.inkMuted)),
            const Spacer(),
            Text('mục tiêu ~${t.dailyGoal.round()}ml', style: GB.body(12.5, w: FontWeight.w600, color: GB.inkMuted)),
          ]),
          RangeBar(value: pumped.toDouble(), lo: t.dailyGoal * .85, hi: t.dailyGoal * 1.15, maxV: math.max(t.dailyGoal * 1.5, pumped.toDouble()), color: GB.pump),
          const SizedBox(height: 8),
          Text(
            t.remainingSessions > 0
                ? 'Còn ${t.remainingSessions} cữ, mỗi cữ cần ~${t.perSessionRemaining.round()}ml để chạm mục tiêu.'
                : 'Đã đủ số cữ dự kiến trong ngày.',
            style: GB.body(13, color: GB.inkMuted),
          ),
          const SizedBox(height: 6),
          Text('Bé cần ~${t.dailyNeed.text()}/ngày. Hút ít hơn mục tiêu rất hay gặp và không có nghĩa là thiếu sữa.', style: GB.body(12, color: GB.inkMuted, height: 1.4)),
        ]),
      ),
      const SectionTitle('Bé nhận được hôm nay'),
      GlassCard(
        radius: 24,
        child: Column(children: [
          _splitBar(tot.breastEst, tot.bottleMom, tot.bottleFormula),
          const SizedBox(height: 10),
          _legend(GB.feed, 'Bú mẹ trực tiếp (ước tính)', tot.breastEst),
          _legend(GB.milkMom, 'Sữa mẹ đã hút', tot.bottleMom),
          _legend(GB.sleep, 'Sữa công thức', tot.bottleFormula),
        ]),
      ),
    ];
  }

  Widget _splitBar(int a, int b, int c) {
    Widget seg(int v, Color col) => v == 0 ? const SizedBox.shrink() : Expanded(flex: v, child: Container(height: 14, margin: const EdgeInsets.only(right: 3), decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(7))));
    if (a + b + c == 0) return Container(height: 14, decoration: BoxDecoration(color: GB.w(.7), borderRadius: BorderRadius.circular(7)));
    return Row(children: [seg(a, GB.feed), seg(b, GB.milkMom), seg(c, GB.sleep)]);
  }

  Widget _legend(Color c, String label, int ml) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: GB.body(14))),
          Text('${ml}ml', style: GB.body(14, w: FontWeight.w800)),
        ]),
      );

  // ---------- Tủ sữa ----------
  List<Widget> _fridgeTab() {
    final now = DateTime.now();
    final all = app.fridgeActive;
    final valid = all.where((f) => f.expires.isAfter(now)).toList();
    final expired = all.where((f) => !f.expires.isAfter(now)).toList();
    final fr = valid.where((f) => !f.freezer).fold(0, (a, f) => a + f.left);
    final fz = valid.where((f) => f.freezer).fold(0, (a, f) => a + f.left);
    final soon = valid.where((f) => f.expires.difference(now).inHours <= 24).length;
    return [
      GlassCard(
        radius: 26,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Tủ sữa của mẹ', style: GB.body(13, w: FontWeight.w700, color: GB.inkMuted)),
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text('${fr + fz}', style: GB.display(40)),
            const SizedBox(width: 4),
            Text('ml · ${valid.length} bình', style: GB.body(15, w: FontWeight.w700, color: GB.inkMuted)),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(child: _mini('Ngăn mát', '${fr}ml', GB.infoBg, GB.info)),
            const SizedBox(width: 10),
            Expanded(child: _mini('Ngăn đông', '${fz}ml', GB.p(Color(0xFFDCEBF5)), GB.f(Color(0xFF2F5F7A)))),
          ]),
          if (soon > 0) ...[
            const SizedBox(height: 10),
            Callout(level: Level.note, title: '$soon bình sắp hết hạn trong 24 giờ', body: 'Nên dùng các bình này trước (xếp đầu danh sách).'),
          ],
          if (expired.isNotEmpty) ...[
            const SizedBox(height: 10),
            Callout(level: Level.alert, title: '${expired.length} bình đã quá hạn', body: 'Sữa quá hạn nên bỏ đi. Bấm vào bình để loại khỏi tủ.'),
          ],
        ]),
      ),
      const SizedBox(height: 12),
      BigButton('Thêm bình sữa', icon: Icons.add_rounded, height: 50, color: GB.ink, onTap: _addSheet),
      const SectionTitle('Danh sách (dùng trước ở trên)'),
      if (all.isEmpty)
        const GlassCard(child: EmptyState('Tủ sữa đang trống.\nGhi hút sữa và chọn "Lưu vào tủ sữa" để thêm bình.', icon: Icons.kitchen_rounded))
      else
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(children: [
            for (var i = 0; i < all.length; i++) _bottleRow(all[i], first: i == 0 && all[i].expires.isAfter(now)),
          ]),
        ),
      const SizedBox(height: 8),
      Text('Hạn dùng tham khảo (CDC): sữa mẹ ngăn mát tối đa 4 ngày, ngăn đông tốt nhất trong 6 tháng, để nhiệt độ phòng tối đa 4 giờ. Sữa đã rã đông dùng trong 24 giờ, không cấp đông lại.', style: GB.body(11.5, color: GB.inkMuted, height: 1.4)),
    ];
  }

  Widget _mini(String label, String v, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: bg.withValues(alpha: .9), borderRadius: BorderRadius.circular(16), border: Border.all(color: GB.edgeOf(bg.withValues(alpha: .9)), width: 1)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GB.body(11.5, w: FontWeight.w700, color: fg)),
          Text(v, style: GB.body(17, w: FontWeight.w800, color: fg)),
        ]),
      );

  Widget _bottleRow(FridgeItem f, {required bool first}) {
    final now = DateTime.now();
    final total = f.expires.difference(f.storedAt).inMinutes;
    final remain = f.expires.difference(now).inMinutes;
    final frac = total <= 0 ? 0.0 : (remain / total).clamp(0.0, 1.0);
    final expired = remain <= 0;
    final low = !expired && f.expires.difference(now).inHours <= 24;
    final col = expired ? GB.alert : low ? GB.f(Color(0xFFC2453B)) : const Color(0xFF9DB36B);
    final label = expired ? 'Quá hạn' : (f.expires.difference(now).inDays >= 2 ? 'Còn ${f.expires.difference(now).inDays} ngày' : 'Còn ${GB.dur(f.expires.difference(now))}');
    return InkWell(
      onTap: () => _bottleSheet(f),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: GB.f(Color(0xFF785A46)).withValues(alpha: .08)))),
        child: Row(children: [
          MiniBottle(fill: f.left / f.ml, frozen: f.freezer, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('${f.freezer ? 'Ngăn đông' : 'Ngăn mát'} · ${f.left}ml', style: GB.body(14.5, w: FontWeight.w700)),
                if (first) ...[const SizedBox(width: 8), Tag('Dùng trước', bg: GB.warnBg, fg: GB.warn)],
              ]),
              Text('Hút ${GB.dmyhm(f.storedAt)}', style: GB.body(12, color: GB.inkMuted)),
              const SizedBox(height: 6),
              ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: frac, minHeight: 6, backgroundColor: GB.w(.7), valueColor: AlwaysStoppedAnimation(col))),
            ]),
          ),
          const SizedBox(width: 10),
          Text(label, style: GB.body(12.5, w: FontWeight.w800, color: expired ? GB.alert : low ? GB.f(Color(0xFFC2453B)) : GB.ok)),
        ]),
      ),
    );
  }

  void _bottleSheet(FridgeItem f) {
    showGlassSheet(context, builder: (ctx) {
      return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          MiniBottle(fill: f.left / f.ml, frozen: f.freezer, size: 48),
          const SizedBox(width: 12),
          Expanded(child: Text('${f.left}ml · ${f.freezer ? 'ngăn đông' : 'ngăn mát'}', style: GB.display(22, w: FontWeight.w700))),
        ]),
        const SizedBox(height: 6),
        Text('Hút ${GB.dmyhm(f.storedAt)} · hạn ${GB.dmyhm(f.expires)}', style: GB.body(13, color: GB.inkMuted)),
        const SizedBox(height: 16),
        BigButton('Cho bé bú bình này', icon: Icons.local_drink_rounded, color: GB.accent, fg: GB.ink, onTap: () {
          Navigator.pop(ctx);
          openPage(context, const FeedScreen());
        }),
        const SizedBox(height: 10),
        BigButton(f.freezer ? 'Chuyển sang ngăn mát (rã đông)' : 'Chuyển sang ngăn đông', icon: Icons.ac_unit_rounded, color: GB.w(.7), fg: GB.ink, onTap: () {
          if (f.freezer) {
            f.freezer = false;
            f.storedAt = DateTime.now().subtract(const Duration(days: 3)); // rã đông: dùng trong 24 giờ
          } else {
            f.freezer = true;
          }
          app.changed('fridge');
          Navigator.pop(ctx);
        }),
        const SizedBox(height: 10),
        BigButton('Bỏ bình này', icon: Icons.delete_outline_rounded, color: GB.alertBg, fg: GB.alert, onTap: () {
          app.fridgeDiscard(f.id);
          Navigator.pop(ctx);
        }),
      ]);
    });
  }

  void _addSheet() {
    showGlassSheet(context, builder: (ctx) {
      var ml = 120;
      var freezer = false;
      var time = DateTime.now();
      return StatefulBuilder(builder: (ctx, setS) {
        return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Thêm bình sữa', style: GB.display(22, w: FontWeight.w700)),
          const SizedBox(height: 12),
          Seg(labels: const ['Ngăn mát', 'Ngăn đông'], index: freezer ? 1 : 0, height: 40, onChanged: (i) => setS(() => freezer = i == 1)),
          const SizedBox(height: 10),
          TimeRow(label: 'Hút lúc', time: time, onChanged: (v) => setS(() => time = v)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: Center(child: Text('$ml ml', style: GB.display(36)))),
            BottleView(ml: ml, cap: 240, width: 110, color: GB.milkBottle, onChanged: (v) => setS(() => ml = v), label: 'Lượng sữa'),
          ]),
          Row(children: [
            RoundIconButton(icon: Icons.remove_rounded, label: 'Giảm 10ml', onTap: () => setS(() => ml = math.max(10, ml - 10))),
            const SizedBox(width: 10),
            RoundIconButton(icon: Icons.add_rounded, label: 'Tăng 10ml', filled: true, onTap: () => setS(() => ml = math.min(240, ml + 10))),
          ]),
          const SizedBox(height: 16),
          BigButton('Lưu bình', icon: Icons.check_rounded, onTap: () {
            app.fridgeAdd(FridgeItem(ml: ml, storedAt: time, freezer: freezer));
            Navigator.pop(ctx);
          }),
        ]);
      });
    });
  }

  // ---------- Thống kê ----------
  List<Widget> _stats() {
    final today = AppState.dayStart(DateTime.now());
    final days = [for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i))];
    final data = days.map((d) => app.feedTotals(d)).toList();
    final pumps = days.map((d) => app.pumpedOn(d)).toList();
    final maxMl = math.max(300, data.map((e) => e.total).fold(0, math.max));
    final avg = data.fold(0, (a, e) => a + e.total) ~/ 7;
    final da = FeedingRef.day(app.age.adjDays, app.weightKg, avg);
    return [
      GlassCard(
        radius: 24,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('Sữa 7 ngày qua', style: GB.body(14.5, w: FontWeight.w800))),
            Text('TB $avg ml/ngày', style: GB.body(12.5, w: FontWeight.w700, color: GB.inkMuted)),
          ]),
          const SizedBox(height: 10),
          SizedBox(
            height: 130,
            child: Stack(children: [
              Positioned.fill(
                child: LayoutBuilder(builder: (c, cons) {
                  final h = cons.maxHeight - 18;
                  double y(double v) => h - v / maxMl * h;
                  return Stack(children: [
                    Positioned(left: 0, right: 0, top: y(da.range.hi), height: math.max(2, y(da.range.lo) - y(da.range.hi)), child: Container(decoration: BoxDecoration(color: GB.okBg.withValues(alpha: .6), borderRadius: BorderRadius.circular(6)))),
                  ]);
                }),
              ),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                        Expanded(
                          child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                            _seg(data[i].bottleFormula, maxMl, GB.sleep),
                            _seg(data[i].bottleMom, maxMl, GB.milkMom),
                            _seg(data[i].breastEst, maxMl, GB.feed),
                          ]),
                        ),
                        const SizedBox(height: 4),
                        Text(GB.dm(days[i]), style: GB.body(10.5, color: GB.inkMuted)),
                      ]),
                    ),
                  ),
              ]),
            ]),
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 12, runSpacing: 4, children: [
            _lg(GB.feed, 'Bú mẹ'),
            _lg(GB.milkMom, 'Sữa mẹ hút'),
            _lg(GB.sleep, 'Công thức'),
            _lg(GB.okBg, 'Khoảng thường gặp'),
          ]),
        ]),
      ),
      const SizedBox(height: 12),
      GlassCard(
        radius: 24,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('Sữa đã hút 7 ngày', style: GB.body(14.5, w: FontWeight.w800))),
            Text('TB ${pumps.fold(0, (a, b) => a + b) ~/ 7} ml/ngày', style: GB.body(12.5, w: FontWeight.w700, color: GB.inkMuted)),
          ]),
          const SizedBox(height: 10),
          SizedBox(
            height: 100,
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                      Text(pumps[i] == 0 ? '' : '${pumps[i]}', style: GB.body(10, color: GB.inkMuted)),
                      Container(height: math.max(2, pumps[i] / math.max(300, pumps.fold(0, math.max)) * 70), decoration: BoxDecoration(color: GB.pump, borderRadius: BorderRadius.circular(6))),
                      const SizedBox(height: 4),
                      Text(GB.dm(days[i]), style: GB.body(10.5, color: GB.inkMuted)),
                    ]),
                  ),
                ),
            ]),
          ),
        ]),
      ),
    ];
  }

  Widget _seg(int v, int maxMl, Color c) => v == 0 ? const SizedBox.shrink() : Container(height: v / maxMl * 100, constraints: const BoxConstraints(minHeight: 3), margin: const EdgeInsets.only(bottom: 1), decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4)));

  Widget _lg(Color c, String t) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(t, style: GB.body(11.5, color: GB.inkMuted)),
      ]);
}
