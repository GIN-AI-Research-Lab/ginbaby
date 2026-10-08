import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/kit.dart';
import '../core/pastel.dart';
import '../core/theme.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import '../domain/age.dart';
import '../domain/easy.dart';
import '../domain/feeding_ref.dart';
import '../domain/stats.dart';
import 'diaper_screen.dart';
import 'easy_screen.dart';
import 'recap.dart';
import 'widgets.dart';

/// Tab Tổng quan: Ngày · Tuần · Tháng.
class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  int period = 1;
  int pumpView = 0; // 0: theo ngày, 1: theo từng cữ hút
  DateTime anchor = AppState.dayStart(DateTime.now());

  bool get _atToday => AppState.dayStart(DateTime.now()) == anchor || (period == 1 && Stats.weekStart(anchor) == Stats.weekStart(DateTime.now())) || (period == 2 && anchor.year == DateTime.now().year && anchor.month == DateTime.now().month);

  void _shift(int dir) {
    setState(() {
      if (period == 0) {
        anchor = anchor.add(Duration(days: dir));
      } else if (period == 1) {
        anchor = anchor.add(Duration(days: 7 * dir));
      } else {
        anchor = DateTime(anchor.year, anchor.month + dir, 1);
      }
      final today = AppState.dayStart(DateTime.now());
      if (anchor.isAfter(today)) anchor = today;
    });
  }

  String get _label {
    if (period == 0) return GB.dayLabel(anchor) == 'Hôm nay' ? 'Hôm nay · ${GB.dmy(anchor)}' : GB.dayLabel(anchor);
    if (period == 1) {
      final w = Stats.weekStart(anchor);
      return '${GB.dmy(w)} – ${GB.dmy(w.add(const Duration(days: 6)))}';
    }
    return 'Tháng ${anchor.month}, ${anchor.year}';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        return ListView(
          padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 16, 100),
          children: [
            SizedBox(
              height: 140,
              child: Stack(children: [
                const Positioned(right: -8, top: 0, child: Art('hero_baby_awake', width: 140)),
                Positioned(
                  left: 0,
                  top: 10,
                  right: 122,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('Thống kê', style: GB.display(30, color: GB.title)),
                        const SizedBox(width: 8),
                        const Icon(Icons.bar_chart_rounded, color: Color(0xFFF08A97), size: 30),
                      ]),
                    ),
                    const SizedBox(height: 4),
                    Text('Những nỗ lực nhỏ hôm nay đang tạo nên điều tuyệt vời', style: GB.script(13.5)),
                  ]),
                ),
              ]),
            ),
            Seg(labels: const ['Ngày', 'Tuần', 'Tháng'], index: period, onChanged: (i) => setState(() {
                  period = i;
                  if (i == 2) anchor = DateTime(anchor.year, anchor.month, 1);
                })),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(children: [
                RoundIconButton(icon: Icons.chevron_left_rounded, label: 'Trước', size: 44, onTap: () => _shift(-1)),
                const SizedBox(width: 10),
                Expanded(
                  child: GlassCard(
                    radius: 22,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.calendar_today_rounded, size: 18, color: GB.inkMuted),
                      const SizedBox(width: 8),
                      Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(_label, style: GB.body(14.5, w: FontWeight.w800)))),
                    ]),
                  ),
                ),
                const SizedBox(width: 10),
                Opacity(opacity: _atToday ? .35 : 1, child: RoundIconButton(icon: Icons.chevron_right_rounded, label: 'Sau', size: 44, onTap: _atToday ? () {} : () => _shift(1))),
              ]),
            ),
            if (period == 0) ..._day(),
            if (period == 1) ..._week(),
            if (period == 2) ..._month(),
          ],
        );
      },
    );
  }

  // ================= NGÀY =================
  List<Widget> _day() {
    final st = Stats.day(app, anchor);
    final age = Age(app.baby!, anchor.add(const Duration(hours: 12))).adjDays;
    final sr = Easy.sleepHours(age);
    final da = FeedingRef.day(age, app.weightKg, st.milk);
    final wetMin = FeedingRef.wetDiapersMin(app.age.days);
    final list = app.entriesOn(anchor);
    return [
      ...pairRows([
        _stat('Ngủ', GB.dur(st.sleep), 'thường gặp ${sr.text('h')}', GB.sleep, Icons.bedtime_rounded),
        _stat('Bú', '${st.feedCount} cữ', '${st.milk}ml · ${da.range.text()}', GB.feed, Icons.local_drink_rounded),
        _stat('Tã', '${st.diapers} lần', '${st.wet} ướt · ${st.poop} phân (ướt ≥$wetMin)', GB.diaper, Icons.water_drop_rounded),
        _stat('Hút sữa', '${st.pumpMl}ml', '${st.pumpCount} cữ', GB.pump, Icons.favorite_rounded),
      ], gap: 12),
      const SectionTitle('Nhịp trong ngày'),
      GlassCard(
        radius: 24,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(height: 118, child: CustomPaint(size: const Size(double.infinity, 118), painter: DayBarPainter(app, anchor))),
          const SizedBox(height: 8),
          Wrap(spacing: 12, runSpacing: 4, children: [
            _lg(GB.sleep, 'Ngủ'),
            _lg(GB.feed, 'Bú'),
            _lg(GB.diaper, 'Tã'),
            _lg(GB.pump, 'Hút'),
          ]),
        ]),
      ),
      const SizedBox(height: 12),
      GlassCard(
        radius: 24,
        onTap: () => openPage(context, const EasyScreen()),
        child: Row(children: [
          Orb(icon: Icons.schedule_rounded, color: GB.p(Color(0xFFE3E6F6))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Nhịp EASY ${Easy.label(Easy.cycleFor(app.settings, app.age.adjDays))}', style: GB.body(15, w: FontWeight.w800)),
              Text('Thời gian thức, lịch gợi ý và cài đặt nhịp', style: GB.body(12.5, color: GB.inkMuted)),
            ]),
          ),
          Icon(Icons.chevron_right_rounded, color: GB.inkMuted),
        ]),
      ),
      const SectionTitle('Sữa trong ngày'),
      DayFeedCard(day: anchor),
      const SectionTitle('Thời gian thức giữa các cữ ngủ'),
      _wakeWindows(age),
      const SectionTitle('Nhật ký'),
      GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: list.isEmpty ? const EmptyState('Không có bản ghi trong ngày này.') : Column(children: [for (final e in list) EntryRow(e)]),
      ),
    ];
  }

  Widget _wakeWindows(int age) {
    final s = AppState.dayStart(anchor);
    final e = s.add(const Duration(days: 1));
    final sl = app.entries.where((x) => x.type == T.sleep && x.end != null && !x.time.isBefore(s.subtract(const Duration(hours: 6))) && x.time.isBefore(e)).toList()..sort((a, b) => a.time.compareTo(b.time));
    final ww = Easy.wakeWindow(age);
    final rows = <Widget>[];
    for (var i = 0; i + 1 < sl.length; i++) {
      final from = sl[i].end!;
      final to = sl[i + 1].time;
      if (from.isBefore(s) && to.isBefore(s)) continue;
      final m = to.difference(from).inMinutes;
      if (m <= 0 || m > 360) continue;
      final lvl = m < ww.lo * .8 ? 'ngắn' : m > ww.hi * 1.15 ? 'dài' : 'phù hợp';
      rows.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          SizedBox(width: 92, child: Text('${GB.hm(from)} → ${GB.hm(to)}', style: GB.body(13, color: GB.inkMuted))),
          Expanded(child: Text(GB.dur(Duration(minutes: m)), style: GB.body(14.5, w: FontWeight.w800))),
          Tag(lvl, bg: lvl == 'phù hợp' ? GB.okBg : GB.warnBg, fg: lvl == 'phù hợp' ? GB.ok : GB.warn),
        ]),
      ));
    }
    return GlassCard(
      radius: 24,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Thường gặp ${ww.text('p')} ở tuổi này', style: GB.body(12.5, w: FontWeight.w700, color: GB.inkMuted)),
        const SizedBox(height: 4),
        if (rows.isEmpty) const EmptyState('Cần ít nhất hai giấc ngủ để tính thời gian thức.') else ...rows,
      ]),
    );
  }

  Widget _stat(String label, String value, String sub, Color color, IconData icon) {
    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [IconBadge(icon: icon, bg: color.withValues(alpha: .28), fg: color, size: 30), const SizedBox(width: 8), Expanded(child: Text(label, style: GB.body(13, w: FontWeight.w700, color: GB.inkMuted)))]),
        const SizedBox(height: 10),
        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: GB.display(28))),
        Text(sub, style: GB.body(11.5, color: GB.inkMuted, height: 1.3)),
      ]),
    );
  }

  Widget _lg(Color c, String t) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(t, style: GB.body(11.5, color: GB.inkMuted)),
      ]);

  // ================= TUẦN =================
  List<Widget> _week() {
    final cur = Stats.week(app, anchor);
    final prev = Stats.week(app, anchor.subtract(const Duration(days: 7)));
    final age = Age(app.baby!, Stats.weekStart(anchor).add(const Duration(days: 3))).adjDays;
    final sr = Easy.sleepHours(age);
    final da = FeedingRef.day(age, app.weightKg, 0);
    final sleepAvg = Stats.avgOf(cur, (d) => d.sleepHours);
    final sleepPrev = Stats.avgOf(prev, (d) => d.sleepHours);
    final milkAvg = Stats.avgOf(cur, (d) => d.milk.toDouble());
    final milkPrev = Stats.avgOf(prev, (d) => d.milk.toDouble());
    final hasData = cur.any((d) => d.hasData);
    const wd = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final maxSleep = math.max(sr.hi + 2, maxOf(cur.map((d) => d.sleepHours)));
    final maxMilk = math.max(da.range.hi * 1.15, maxOf(cur.map((d) => d.milk)));

    return [
      if (!hasData)
        const GlassCard(child: EmptyState('Tuần này chưa có dữ liệu.\nHãy ghi bú, ngủ, tã để xem tổng kết.', icon: Icons.insert_chart_outlined_rounded))
      else ...[
        _weekTiles(cur, prev, sleepAvg, sleepPrev),
        const SizedBox(height: 14),
        if (cur.any((d) => d.pumpMl > 0)) ...[
          _pumpBars(cur),
          const SizedBox(height: 14),
        ],
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: _lineCard(
              'Thời gian bú',
              'phút',
              GB.breastDeep,
              Icons.timer_outlined,
              [for (final d in cur) d.hasData ? d.breastMin.toDouble() : null],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _lineCard(
              'Giấc ngủ của bé',
              'giờ',
              GB.bottleDeep,
              Icons.bedtime_rounded,
              [for (final d in cur) d.hasData ? d.sleepHours : null],
            ),
          ),
        ]),
        const SizedBox(height: 14),
        _weekHighlights(cur, prev, sleepAvg, sleepPrev),
        const SizedBox(height: 14),
        BigButton('Xem thẻ tổng kết tuần', icon: Icons.ios_share_rounded, height: 50, onTap: () => openPage(context, RecapScreen(weekStart: Stats.weekStart(anchor)))),
        const SectionTitle('Giấc ngủ mỗi ngày'),
        GlassCard(
          radius: 24,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              height: 130,
              child: Stack(children: [
                _band(sr.lo, sr.hi, maxSleep, 112),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() {
                          period = 0;
                          anchor = cur[i].day;
                        }),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                            Text(cur[i].hasData ? GB.num1(cur[i].sleepHours) : '', style: GB.body(10.5, color: GB.inkMuted)),
                            AnimatedContainer(duration: const Duration(milliseconds: 250), height: math.max(3, cur[i].sleepHours / maxSleep * 92), decoration: BoxDecoration(color: AppState.dayStart(DateTime.now()) == cur[i].day ? GB.sleep : GB.p(Color(0xFFC9CFEE)), borderRadius: BorderRadius.circular(8))),
                            const SizedBox(height: 4),
                            Text(wd[i], style: GB.body(11, w: AppState.dayStart(DateTime.now()) == cur[i].day ? FontWeight.w800 : FontWeight.w500, color: GB.inkMuted)),
                          ]),
                        ),
                      ),
                    ),
                ]),
              ]),
            ),
            Text('Vùng xanh: thường gặp ${sr.text('h')}/ngày (National Sleep Foundation)', style: GB.body(11.5, color: GB.inkMuted)),
          ]),
        ),
        const SectionTitle('Sữa mỗi ngày'),
        GlassCard(
          radius: 24,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              height: 140,
              child: Stack(children: [
                _band(da.range.lo, da.range.hi, maxMilk, 122),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                          Expanded(
                            child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                              _seg(cur[i].bottleFormula, maxMilk, GB.sleep),
                              _seg(cur[i].bottleMom, maxMilk, GB.milkMom),
                              _seg(cur[i].breastEst, maxMilk, GB.feed),
                            ]),
                          ),
                          const SizedBox(height: 4),
                          Text(wd[i], style: GB.body(11, color: GB.inkMuted)),
                        ]),
                      ),
                    ),
                ]),
              ]),
            ),
            const SizedBox(height: 6),
            Wrap(spacing: 12, runSpacing: 4, children: [_lg(GB.feed, 'Bú mẹ (ước tính)'), _lg(GB.milkMom, 'Sữa mẹ hút'), _lg(GB.sleep, 'Công thức'), _lg(GB.okBg, 'Khoảng thường gặp')]),
            if (milkPrev > 0) ...[
              const SizedBox(height: 6),
              Text('Trung bình ${milkAvg.round()}ml/ngày, tuần trước ${milkPrev.round()}ml', style: GB.body(12.5, color: GB.inkMuted)),
            ],
          ]),
        ),
        const SectionTitle('Tã mỗi ngày'),
        GlassCard(
          radius: 24,
          child: SizedBox(
            height: 110,
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                      Text(cur[i].diapers == 0 ? '' : '${cur[i].diapers}', style: GB.body(10.5, color: GB.inkMuted)),
                      Container(height: cur[i].poop / 12 * 70, constraints: BoxConstraints(minHeight: cur[i].poop > 0 ? 3 : 0), decoration: BoxDecoration(color: const Color(0xFFB9C98A), borderRadius: BorderRadius.circular(5))),
                      const SizedBox(height: 1),
                      Container(height: cur[i].wet / 12 * 70, constraints: BoxConstraints(minHeight: cur[i].wet > 0 ? 3 : 0), decoration: BoxDecoration(color: GB.diaper, borderRadius: BorderRadius.circular(5))),
                      const SizedBox(height: 4),
                      Text(wd[i], style: GB.body(11, color: GB.inkMuted)),
                    ]),
                  ),
                ),
            ]),
          ),
        ),
        const SizedBox(height: 14),
        _poopWeek(),
      ],
    ];
  }

  // ───────── Phân của bé trong tuần: màu và kết cấu hay gặp, cảnh báo nếu có màu cần chú ý
  Widget _poopWeek() {
    final w = Stats.weekStart(anchor);
    final list = app.entriesBetween(w, w.add(const Duration(days: 7)), type: T.diaper).where((e) => e.str('kind') != 'wet').toList();
    final colors = <String, int>{};
    final texts = <String, int>{};
    var alert = 0;
    for (final e in list) {
      final c = e.str('color');
      if (c.isNotEmpty) colors[c] = (colors[c] ?? 0) + 1;
      final t = e.str('state');
      if (t.isNotEmpty) texts[t] = (texts[t] ?? 0) + 1;
      final v = diaperVerdict(kind: e.str('kind'), color: c, state: t, amount: e.str('amount'), ageDays: app.age.days);
      if (v.level == Level.alert) alert++;
    }
    Widget chip(String? art, String label, int n) => Container(
          padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
          decoration: BoxDecoration(color: GB.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: GB.line)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (art != null) SizedBox(width: 26, height: 22, child: Art(art)),
            const SizedBox(width: 4),
            Text('$label · $n', style: GB.body(12, w: FontWeight.w700)),
          ]),
        );
    final cs = colors.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final ts = texts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return SectionCard(
      title: 'Phân của bé trong tuần',
      icon: Icons.baby_changing_station_rounded,
      iconColor: GB.diaper,
      trailing: 'Ghi phân',
      onTrailing: () => openPage(context, const DiaperScreen()),
      child: list.isEmpty
          ? const EmptyState('Tuần này chưa ghi lần có phân nào.')
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${list.length} lần có phân trong tuần.', style: GB.body(13.5, w: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Màu hay gặp', style: GB.body(12, color: GB.inkMuted)),
              const SizedBox(height: 4),
              Wrap(spacing: 6, runSpacing: 6, children: [for (final e in cs) chip(poopArt(e.key), e.key, e.value)]),
              if (ts.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Kết cấu', style: GB.body(12, color: GB.inkMuted)),
                const SizedBox(height: 4),
                Wrap(spacing: 6, runSpacing: 6, children: [for (final e in ts) chip(textureArt(e.key), e.key, e.value)]),
              ],
              if (alert > 0) ...[
                const SizedBox(height: 10),
                Callout(level: Level.alert, title: '$alert lần có màu cần chú ý', body: 'Phân bạc, có máu hoặc đen sau những ngày đầu nên được bác sĩ kiểm tra.'),
              ],
            ]),
    );
  }

  // ───────── 3 thẻ "Những điểm nổi bật"
  Widget _weekHighlights(List<DayStat> cur, List<DayStat> prev, double sleepAvg, double sleepPrev) {
    final usePump = cur.any((d) => d.pumpMl > 0) || prev.any((d) => d.pumpMl > 0);
    final a = cur.fold(0, (x, d) => x + (usePump ? d.pumpMl : d.milk));
    final b = prev.fold(0, (x, d) => x + (usePump ? d.pumpMl : d.milk));
    final dm = pctDelta(a, b);
    final cnt = cur.fold(0, (x, d) => x + d.feedCount) - prev.fold(0, (x, d) => x + d.feedCount);
    final sleepMin = ((sleepAvg - sleepPrev) * 60).round();

    final t1 = dm == null
        ? ('Sữa mỗi ngày', 'Chưa có tuần trước để so sánh.')
        : (dm.up ? ('Tăng ${dm.text.replaceAll('+', '')}', 'Lượng sữa so với tuần trước. Mẹ đang làm rất tốt!') : ('Giảm ${dm.text.replaceAll('-', '')}', 'Lượng sữa so với tuần trước. Cứ từ từ, mẹ nhé.'));
    final t2 = cnt == 0 ? ('Đều như tuần trước', 'Số cữ bú trong tuần không đổi.') : (cnt > 0 ? ('Nhiều hơn $cnt cữ', 'Số cữ bú trong tuần so với tuần trước.') : ('Ít hơn ${-cnt} cữ', 'Số cữ bú trong tuần so với tuần trước.'));
    final t3 = sleepPrev <= 0
        ? ('Giấc ngủ của bé', 'Chưa có tuần trước để so sánh.')
        : (sleepMin >= 10 ? ('Bé ngủ ngon hơn', 'Thời gian ngủ tăng ${GB.num1(sleepMin / 60)} giờ mỗi ngày.') : (sleepMin <= -10 ? ('Bé ngủ ít hơn', 'Giảm ${GB.num1(-sleepMin / 60)} giờ mỗi ngày. Giữ nhịp đều nhé.') : ('Giấc ngủ ổn định', 'Gần như không đổi so với tuần trước.')));

    Widget tile(Color bg, Color fg, IconData icon, (String, String) t) => Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 12, 8, 12),
            decoration: BoxDecoration(color: bg.withValues(alpha: .7), borderRadius: BorderRadius.circular(18), border: Border.all(color: GB.edgeOf(bg.withValues(alpha: .7)), width: 1)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icon, color: fg, size: 28),
              const SizedBox(height: 6),
              Text(t.$1, style: GB.body(13.5, w: FontWeight.w800, color: fg, height: 1.15)),
              const SizedBox(height: 4),
              Text(t.$2, style: GB.body(11, color: GB.inkMuted, height: 1.3)),
            ]),
          ),
        );
    return SectionCard(
      title: 'Những điểm nổi bật',
      icon: Icons.lightbulb_rounded,
      iconColor: const Color(0xFFF2B632),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          tile(GB.pumpTile, GB.pumpDeep, Icons.trending_up_rounded, t1),
          const SizedBox(width: 8),
          tile(GB.sleepTile, GB.f(const Color(0xFF4F7A4B)), Icons.star_rounded, t2),
          const SizedBox(width: 8),
          tile(GB.bottleTile, GB.f(const Color(0xFF7B68C4)), Icons.bedtime_rounded, t3),
        ]),
      ),
    );
  }

  // ───────── Thẻ số liệu tuần (pastel)
  Widget _weekTiles(List<DayStat> cur, List<DayStat> prev, double sleepAvg, double sleepPrev) {
    final pumpSum = cur.fold(0, (a, d) => a + d.pumpMl);
    final pumpPrev = prev.fold(0, (a, d) => a + d.pumpMl);
    final milkSum = cur.fold(0, (a, d) => a + d.milk);
    final milkPrevSum = prev.fold(0, (a, d) => a + d.milk);
    final usePump = pumpSum > 0 || pumpPrev > 0;
    final main = usePump ? pumpSum : milkSum;
    final mainPrev = usePump ? pumpPrev : milkPrevSum;
    final dMain = pctDelta(main, mainPrev);
    final bmSum = cur.fold(0, (a, d) => a + d.breastMin);
    final bmCnt = cur.fold(0, (a, d) => a + d.breastCount);
    final bmPrevSum = prev.fold(0, (a, d) => a + d.breastMin);
    final bmPrevCnt = prev.fold(0, (a, d) => a + d.breastCount);
    final bmAvg = bmCnt == 0 ? 0 : (bmSum / bmCnt).round();
    final bmPrevAvg = bmPrevCnt == 0 ? 0 : bmPrevSum / bmPrevCnt;
    final dBm = pctDelta(bmAvg, bmPrevAvg);
    final cnt = cur.fold(0, (a, d) => a + d.feedCount);
    final cntPrev = prev.fold(0, (a, d) => a + d.feedCount);
    final dCnt = cnt - cntPrev;
    final dSleepMin = ((sleepAvg - sleepPrev) * 60).round();

    Widget tile(Color bg, Widget icon, String label, String value, String unit, Widget? delta) => Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          decoration: BoxDecoration(color: bg.withValues(alpha: .6), borderRadius: BorderRadius.circular(22), border: Border.all(color: GB.edgeOf(bg.withValues(alpha: .6)), width: 1)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [icon, const SizedBox(width: 8), Expanded(child: Text(label, maxLines: 2, style: GB.body(12, w: FontWeight.w600, height: 1.2)))]),
            const SizedBox(height: 8),
            BigNumber(value, unit, size: 27),
            const SizedBox(height: 8),
            delta ?? Text('chưa có kỳ trước để so', style: GB.body(11, color: GB.inkMuted)),
          ]),
        );
    return Column(children: [
      IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: tile(GB.pumpTile, Icon(Icons.water_drop_rounded, color: GB.pumpDeep, size: 26), usePump ? 'Tổng sữa hút' : 'Tổng sữa uống', GB.thousands(main), 'ml', dMain == null ? null : DeltaChip(dMain.text, up: dMain.up, hint: 'so với tuần trước'))),
          const SizedBox(width: 10),
          Expanded(child: tile(GB.breastTile, Icon(Icons.timer_outlined, color: GB.breastDeep, size: 26), 'Thời gian bú TB', '$bmAvg', 'phút', dBm == null ? null : DeltaChip(dBm.text, up: dBm.up, hint: 'so với tuần trước'))),
        ]),
      ),
      const SizedBox(height: 10),
      IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: tile(GB.bottleTile, const Art('ic_bottle', height: 28), 'Số cữ trong tuần', '$cnt', 'cữ', cntPrev == 0 && cnt == 0 ? null : DeltaChip('${dCnt >= 0 ? '+' : ''}$dCnt', up: dCnt >= 0, hint: 'so với tuần trước'))),
          const SizedBox(width: 10),
          Expanded(child: tile(GB.sleepTile, Icon(Icons.bedtime_rounded, color: GB.sleepDeep, size: 26), 'Thời gian ngủ TB', GB.num1(sleepAvg), 'giờ', sleepPrev <= 0 ? null : DeltaChip('${dSleepMin >= 0 ? '+' : '−'}${GB.num1(dSleepMin.abs() / 60)} giờ', up: dSleepMin >= 0, hint: 'so với tuần trước'))),
        ]),
      ),
    ]);
  }

  // ───────── Biểu đồ cột sữa hút mỗi ngày
  Widget _pumpBars(List<DayStat> cur) {
    const wd = ['Th 2', 'Th 3', 'Th 4', 'Th 5', 'Th 6', 'Th 7', 'CN'];
    // Hai cách xem: theo ngày (7 cột) hoặc theo từng cữ hút trong tuần.
    final w0 = Stats.weekStart(anchor);
    final sessions = app.entriesBetween(w0, w0.add(const Duration(days: 7)), type: T.pump).toList()..sort((a, b) => a.time.compareTo(b.time));
    final bySession = pumpView == 1;
    final shown = sessions.length > 12 ? sessions.sublist(sessions.length - 12) : sessions;
    final values = bySession ? [for (final e in shown) e.ml] : [for (final d in cur) d.pumpMl];
    final labels = bySession ? [for (final e in shown) ('${GB.dm(e.time)}'.replaceFirst(RegExp(r'^0'), '').replaceFirst(RegExp(r'/0'), '/'), GB.hm(e.time))] : [for (var i = 0; i < 7; i++) (GB.dm(cur[i].day).replaceFirst(RegExp(r'^0'), '').replaceFirst(RegExp(r'/0'), '/'), wd[i])];
    final mx = math.max(100.0, (values.isEmpty ? 0 : values.reduce(math.max)) * 1.15);
    return SectionCard(
      title: 'Lượng sữa hút được',
      icon: Icons.water_drop_rounded,
      iconColor: GB.pumpDeep,
      trailingWidget: PopupMenuButton<int>(
        initialValue: pumpView,
        onSelected: (v) => setState(() => pumpView = v),
        color: GB.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        itemBuilder: (_) => [
          PopupMenuItem(value: 0, child: Text('Theo ngày', style: GB.body(14, w: FontWeight.w700))),
          PopupMenuItem(value: 1, child: Text('Theo từng cữ hút', style: GB.body(14, w: FontWeight.w700))),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: GB.accentSoft, borderRadius: BorderRadius.circular(18), border: Border.all(color: GB.edgeOf(GB.accentSoft), width: 1)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(bySession ? 'Theo cữ' : 'Theo ngày', style: GB.body(12.5, w: FontWeight.w700, color: GB.accentDeep)),
            Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: GB.accentDeep),
          ]),
        ),
      ),
      child: values.isEmpty
          ? const EmptyState('Tuần này chưa có cữ hút nào.')
          : SizedBox(
              height: 190,
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                for (var i = 0; i < values.length; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: values.length > 8 ? 1.5 : 3),
                      child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                        FittedBox(fit: BoxFit.scaleDown, child: Text(values[i] > 0 ? '${values[i]}' : '', style: GB.body(11, w: FontWeight.w700))),
                        const SizedBox(height: 3),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          height: math.max(4, values[i] / mx * 120),
                          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF3A5AA), GB.p(Color(0xFFF9D3D5))]), borderRadius: BorderRadius.circular(9)),
                        ),
                        const SizedBox(height: 6),
                        FittedBox(fit: BoxFit.scaleDown, child: Text(labels[i].$1, style: GB.body(10.5, color: GB.inkMuted))),
                        FittedBox(fit: BoxFit.scaleDown, child: Text(labels[i].$2, style: GB.body(10, color: GB.inkMuted))),
                      ]),
                    ),
                  ),
              ]),
            ),
    );
  }

  // ───────── Biểu đồ đường nhỏ (kèm điểm cao nhất)
  Widget _lineCard(String title, String unit, Color color, IconData icon, List<double?> v) {
    final vals = v.whereType<double>().toList();
    final hasAny = vals.isNotEmpty && vals.any((x) => x > 0);
    final peak = hasAny ? vals.reduce(math.max) : 0.0;
    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 5),
          Expanded(child: Text(title, maxLines: 2, style: GB.body(13.5, w: FontWeight.w800, height: 1.15))),
        ]),
        const SizedBox(height: 10),
        SizedBox(height: 110, child: CustomPaint(size: const Size(double.infinity, 110), painter: LineChartPainter(v, color, hasAny ? '${peak == peak.roundToDouble() ? peak.round() : GB.num1(peak)} $unit' : ''))),
      ]),
    );
  }

  Widget _band(double lo, double hi, double mx, double h) {
    final top = h - hi / mx * (h - 20);
    final bottom = h - lo / mx * (h - 20);
    return Positioned(left: 0, right: 0, top: top, height: math.max(3, bottom - top), child: Container(decoration: BoxDecoration(color: GB.okBg.withValues(alpha: .65), borderRadius: BorderRadius.circular(6))));
  }

  Widget _seg(int v, double mx, Color c) => v == 0 ? const SizedBox.shrink() : Container(height: v / mx * 100, constraints: const BoxConstraints(minHeight: 3), margin: const EdgeInsets.only(bottom: 1), decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4)));

  // ================= THÁNG =================
  List<Widget> _month() {
    final days = Stats.month(app, anchor);
    final first = DateTime(anchor.year, anchor.month, 1);
    final lead = first.weekday - 1;
    final age = Age(app.baby!, DateTime(anchor.year, anchor.month, 15)).adjDays;
    final sr = Easy.sleepHours(age);
    final withData = days.where((d) => d.hasData).toList();
    final sleepAvg = Stats.avgOf(days, (d) => d.sleepHours);
    final milkAvg = Stats.avgOf(days, (d) => d.milk.toDouble());
    final fussy = days.where((d) => app.isFussy(d.day)).length;
    final today = AppState.dayStart(DateTime.now());
    Color cellColor(DayStat d) {
      if (!d.hasData) return GB.line.withValues(alpha: .55);
      final t = ((d.sleepHours - 8) / (sr.lo - 8)).clamp(0.0, 1.0);
      return Color.lerp(GB.p(Color(0xFFE6E0F5)), const Color(0xFF9D8DD0), t)!;
    }

    return [
      GlassCard(
        radius: 24,
        child: Column(children: [
          Row(children: [
            for (final w in const ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN']) Expanded(child: Center(child: Text(w, style: GB.body(11.5, w: FontWeight.w700, color: GB.inkMuted)))),
          ]),
          const SizedBox(height: 6),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            children: [
              for (var i = 0; i < lead; i++) const SizedBox.shrink(),
              for (final d in days)
                GestureDetector(
                  onTap: () => setState(() {
                    period = 0;
                    anchor = d.day;
                  }),
                  onLongPress: () {
                    app.toggleFussy(d.day);
                    toast(context, app.isFussy(d.day) ? 'Đã đánh dấu ngày ${d.day.day} bé quấy' : 'Đã bỏ đánh dấu');
                  },
                  child: Container(
                    decoration: BoxDecoration(color: cellColor(d), borderRadius: BorderRadius.circular(12), border: d.day == today ? Border.all(color: GB.accent, width: 2.2) : null),
                    child: Stack(children: [
                      Center(child: Text('${d.day.day}', style: GB.body(13, w: FontWeight.w700, color: d.hasData ? GB.ink : GB.inkMuted))),
                      if (app.isFussy(d.day)) Positioned(right: 4, top: 4, child: Container(width: 9, height: 9, decoration: const BoxDecoration(color: Color(0xFFE58F96), shape: BoxShape.circle))),
                    ]),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 14, runSpacing: 4, children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 14, height: 14, decoration: BoxDecoration(color: const Color(0xFF9D8DD0), borderRadius: BorderRadius.circular(4))),
              const SizedBox(width: 6),
              Text('Ngủ đủ', style: GB.body(11.5, color: GB.inkMuted)),
            ]),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 14, height: 14, decoration: BoxDecoration(color: GB.p(Color(0xFFE6E0F5)), borderRadius: BorderRadius.circular(4))),
              const SizedBox(width: 6),
              Text('Ngủ ít', style: GB.body(11.5, color: GB.inkMuted)),
            ]),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFFE58F96), shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text('Bé quấy', style: GB.body(11.5, color: GB.inkMuted)),
            ]),
          ]),
          const SizedBox(height: 6),
          Text('Chạm một ngày để xem chi tiết. Giữ lâu để đánh dấu ngày bé quấy hoặc khó chịu.', style: GB.body(11.5, color: GB.inkMuted)),
        ]),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _mini('Ngủ TB', GB.dur(Duration(minutes: (sleepAvg * 60).round())), GB.infoBg, GB.info)),
        const SizedBox(width: 10),
        Expanded(child: _mini('Sữa TB', '${milkAvg.round()}ml', GB.warnBg, GB.warn)),
        const SizedBox(width: 10),
        Expanded(child: _mini('Ngày quấy', '$fussy', GB.alertBg, GB.alert)),
      ]),
      const SizedBox(height: 12),
      if (withData.isEmpty)
        const GlassCard(child: EmptyState('Tháng này chưa có dữ liệu.'))
      else
        Callout(level: Level.info, title: 'Tháng ${anchor.month}: ${withData.length} ngày có ghi chép', body: 'Bé ngủ trung bình ${GB.num1(sleepAvg)} giờ mỗi ngày (thường gặp ${sr.text('h')}). Số ngày ngủ đủ: ${withData.where((d) => d.sleepHours >= sr.lo).length}/${withData.length}.'),
    ];
  }

  Widget _mini(String label, String v, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(color: bg.withValues(alpha: .9), borderRadius: BorderRadius.circular(18), border: Border.all(color: GB.edgeOf(bg.withValues(alpha: .9)), width: 1)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GB.body(11.5, w: FontWeight.w700, color: fg)),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(v, style: GB.display(22, color: fg))),
        ]),
      );
}

/// Thanh 24 giờ: ngủ, bú, tã, hút.
class DayBarPainter extends CustomPainter {
  DayBarPainter(this.a, this.day);
  final AppState a;
  final DateTime day;

  @override
  void paint(Canvas canvas, Size size) {
    final s = AppState.dayStart(day);
    final e = s.add(const Duration(days: 1));
    double x(DateTime t) => (t.difference(s).inMinutes / 1440).clamp(0.0, 1.0) * size.width;
    final track = Paint()..color = GB.line.withValues(alpha: .7);
    const rowH = 22.0;
    void row(double y) => canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, y, size.width, rowH), const Radius.circular(8)), track);
    row(0);
    row(28);
    row(56);
    row(84);
    final now = DateTime.now();
    for (final en in a.entries) {
      if (en.type == T.sleep) {
        final xe = en.end ?? now;
        if (xe.isBefore(s) || en.time.isAfter(e)) continue;
        final r = Rect.fromLTRB(x(en.time.isBefore(s) ? s : en.time), 0, x(xe.isAfter(e) ? e : xe), rowH);
        canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(6)), Paint()..color = GB.sleep);
      } else if (!en.time.isBefore(s) && en.time.isBefore(e)) {
        if (en.type == T.feed) {
          canvas.drawCircle(Offset(x(en.time), 28 + rowH / 2), 6, Paint()..color = GB.feed);
        } else if (en.type == T.diaper) {
          canvas.drawCircle(Offset(x(en.time), 56 + rowH / 2), 5.5, Paint()..color = GB.diaper);
        } else if (en.type == T.pump) {
          canvas.drawCircle(Offset(x(en.time), 84 + rowH / 2), 6, Paint()..color = GB.pump);
        }
      }
    }
    if (AppState.dayStart(now) == s) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x(now) - 1, -4, 2.4, 110), const Radius.circular(2)), Paint()..color = GB.accent);
    }
    for (final h in [0, 6, 12, 18, 24]) {
      final tp = TextPainter(text: TextSpan(text: '${h}h', style: GB.body(10.5, color: GB.inkMuted)), textDirection: TextDirection.ltr)..layout();
      final px = (h / 24 * size.width - tp.width / 2).clamp(0.0, size.width - tp.width);
      tp.paint(canvas, Offset(px, 108));
    }
  }

  @override
  bool shouldRepaint(DayBarPainter old) => true;
}


/// Đường + vùng tô nhẹ cho 7 ngày; ngày không có dữ liệu bị bỏ qua. Đánh dấu điểm cao nhất.
class LineChartPainter extends CustomPainter {
  LineChartPainter(this.v, this.color, this.peakLabel);
  final List<double?> v;
  final Color color;
  final String peakLabel;

  @override
  void paint(Canvas canvas, Size size) {
    final vals = v.whereType<double>();
    final top = vals.isEmpty ? 1.0 : math.max(1.0, vals.reduce(math.max) * 1.25);
    const padB = 16.0, padT = 22.0;
    final h = size.height - padB - padT;
    final n = v.length;
    Offset pt(int i) => Offset(n == 1 ? size.width / 2 : 6 + i * (size.width - 12) / (n - 1), padT + h - (v[i]! / top) * h);

    final grid = Paint()
      ..color = GB.line
      ..strokeWidth = 1;
    for (var k = 0; k <= 2; k++) {
      final y = padT + h * k / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final pts = <Offset>[for (var i = 0; i < n; i++) if (v[i] != null) pt(i)];
    if (pts.length >= 2) {
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (var i = 1; i < pts.length; i++) {
        final p0 = pts[i - 1], p1 = pts[i];
        final cx = (p0.dx + p1.dx) / 2;
        path.cubicTo(cx, p0.dy, cx, p1.dy, p1.dx, p1.dy);
      }
      final area = Path.from(path)
        ..lineTo(pts.last.dx, padT + h)
        ..lineTo(pts.first.dx, padT + h)
        ..close();
      canvas.drawPath(area, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [color.withValues(alpha: .28), color.withValues(alpha: .02)]).createShader(Rect.fromLTWH(0, padT, size.width, h)));
      canvas.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = 2.4..strokeCap = StrokeCap.round..color = color);
    }
    for (final p in pts) {
      canvas.drawCircle(p, 3, Paint()..color = color);
    }
    // điểm cao nhất
    if (vals.isNotEmpty && peakLabel.isNotEmpty) {
      var bi = 0;
      for (var i = 0; i < n; i++) {
        if (v[i] != null && (v[bi] == null || v[i]! > v[bi]!)) bi = i;
      }
      final p = pt(bi);
      canvas.drawCircle(p, 6, Paint()..color = color);
      canvas.drawCircle(p, 3, Paint()..color = Colors.white);
      final tp = TextPainter(text: TextSpan(text: peakLabel, style: GB.body(10.5, w: FontWeight.w800, color: color)), textDirection: TextDirection.ltr)..layout();
      final bw = tp.width + 12;
      final bx = (p.dx - bw / 2).clamp(0.0, size.width - bw);
      final rr = RRect.fromRectAndRadius(Rect.fromLTWH(bx, math.max(0, p.dy - 28), bw, 20), const Radius.circular(10));
      canvas.drawRRect(rr, Paint()..color = color.withValues(alpha: .16));
      tp.paint(canvas, Offset(bx + 6, rr.top + 4));
    }
    const wd = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    for (var i = 0; i < n; i += 2) {
      final tp = TextPainter(text: TextSpan(text: n == 7 ? wd[i] : '${i + 1}', style: GB.body(10, color: GB.inkMuted)), textDirection: TextDirection.ltr)..layout();
      final x = (n == 1 ? size.width / 2 : 6 + i * (size.width - 12) / (n - 1)) - tp.width / 2;
      tp.paint(canvas, Offset(x.clamp(0.0, size.width - tp.width), size.height - 13));
    }
  }

  @override
  bool shouldRepaint(LineChartPainter old) => true;
}
