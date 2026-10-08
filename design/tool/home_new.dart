import 'dart:async';

import 'package:flutter/material.dart';

import '../core/kit.dart';
import '../core/pastel.dart';
import '../core/theme.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import '../domain/easy.dart';
import 'easy_screen.dart';
import 'feed_screen.dart';
import 'milk_hub.dart';
import 'pump_screen.dart';
import 'quick_logs.dart';
import 'vaccine_screen.dart';
import 'widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.goTab});
  final void Function(int) goTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final fast = app.activeSleep != null;
      if (fast || DateTime.now().second == 0) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  static const _quotes = [
    'Mỗi giọt sữa là một điều kỳ diệu',
    'Mẹ đã làm rất tốt rồi',
    'Từng ngày nhỏ, một yêu thương lớn',
    'Mẹ nghỉ một chút cũng không sao nhé',
    'Bé lớn lên từng ngày nhờ vòng tay mẹ',
  ];

  int _breastMinutes(DateTime day) => app.entriesOn(day, type: T.feed).where((e) => e.str('method') == 'breast').fold(0, (a, e) => a + (e.num('min')?.toInt() ?? 0));

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final age = app.age;
        final now = DateTime.now();
        final sleeping = app.activeSleep != null;
        final owner = app.settings.ownerName;
        return ListView(
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 130),
          children: [
            _header(owner, age.label, now),
            ..._reminders(),
            const SizedBox(height: 14),
            _tiles(sleeping),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _mini('Phân & tã', Icons.water_drop_rounded, GB.diaper, () => showDiaperSheet(context))),
              const SizedBox(width: 8),
              Expanded(child: _mini('Nhiệt độ', Icons.thermostat_rounded, GB.health, () => showOtherLogSheet(context, initial: 0))),
              const SizedBox(width: 8),
              Expanded(child: _mini('Thuốc', Icons.medication_rounded, GB.pump, () => showOtherLogSheet(context, initial: 1))),
              const SizedBox(width: 8),
              Expanded(child: _mini('Ghi chú', Icons.edit_note_rounded, GB.feed, () => showOtherLogSheet(context, initial: 2))),
            ]),
            const SizedBox(height: 16),
            _overview(now),
            const SizedBox(height: 14),
            const DayFeedCard(),
            const SizedBox(height: 14),
            _latest(now),
            const SizedBox(height: 14),
            IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Expanded(flex: 11, child: _activity(now)),
                const SizedBox(width: 12),
                Expanded(flex: 12, child: _sleepCard(now)),
              ]),
            ),
            if (!sleeping) ...[const SizedBox(height: 14), _nextUpCard()],
            const SizedBox(height: 14),
            _sleepToday(),
            const SizedBox(height: 18),
            _quote(now),
          ],
        );
      },
    );
  }

  // ───────── Đầu trang
  Widget _header(String owner, String ageLabel, DateTime now) {
    return SizedBox(
      height: 200,
      child: Stack(children: [
        const Positioned(right: -10, top: 0, child: Art('hero_mom_baby', width: 178)),
        Positioned(
          left: 0,
          top: 8,
          right: 130,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text('Xin chào, $owner', style: GB.display(34, color: GB.title)))),
              const SizedBox(width: 6),
              const Icon(Icons.favorite_rounded, color: Color(0xFFF08A97), size: 26),
            ]),
            const SizedBox(height: 4),
            Text('Hành trình nuôi con bằng yêu thương', style: GB.script(14)),
          ]),
        ),
        Positioned(
          left: 0,
          bottom: 8,
          right: 0,
          child: Row(children: [
            Flexible(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => widget.goTab(1),
                child: GlassCard(
                  radius: 22,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.calendar_today_rounded, size: 18, color: GB.inkMuted),
                    const SizedBox(width: 8),
                    Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text('Hôm nay, ${GB.dmy(now)}', style: GB.body(14, w: FontWeight.w700)))),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: GB.inkMuted),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: GlassCard(
                radius: 22,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: FittedBox(fit: BoxFit.scaleDown, child: Text('${app.baby!.name} · $ageLabel', style: GB.body(13, w: FontWeight.w700, color: GB.accentDeep))),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ───────── 4 ô hoạt động
  Widget _tiles(bool sleeping) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: ActivityTile(label: 'Hút sữa', art: 'ic_pump', tile: GB.pumpTile, deep: GB.pumpDeep, onTap: () => openPage(context, const PumpScreen()))),
      const SizedBox(width: 10),
      Expanded(child: ActivityTile(label: 'Cho bú', art: 'ic_breast', tile: GB.breastTile, deep: GB.breastDeep, onTap: () => openPage(context, const FeedScreen(initialTab: 1)))),
      const SizedBox(width: 10),
      Expanded(child: ActivityTile(label: 'Bình sữa', art: 'ic_bottle', tile: GB.bottleTile, deep: GB.bottleDeep, onTap: () => openPage(context, const FeedScreen(initialTab: 0)))),
      const SizedBox(width: 10),
      Expanded(
        child: ActivityTile(
          label: sleeping ? 'Dậy rồi' : 'Ngủ',
          art: 'ic_moon',
          tile: GB.sleepTile,
          deep: GB.sleepDeep,
          icon: sleeping ? Icons.stop_rounded : Icons.add_rounded,
          onTap: () => sleeping ? app.endSleep() : app.startSleep(),
          onLong: () => showSleepManualSheet(context),
        ),
      ),
    ]);
  }

  Widget _mini(String label, IconData icon, Color color, VoidCallback onTap) => Semantics(
        button: true,
        label: label,
        child: GlassCard(
          radius: 18,
          padding: const EdgeInsets.symmetric(vertical: 10),
          onTap: onTap,
          child: Column(children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 3),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, style: GB.body(11.5, w: FontWeight.w700)))),
          ]),
        ),
      );

  // ───────── Tổng quan hôm nay
  Widget _overview(DateTime now) {
    final y = now.subtract(const Duration(days: 1));
    final tt = app.feedTotals(now);
    final ty = app.feedTotals(y);
    final bm = _breastMinutes(now);
    final bmy = _breastMinutes(y);
    final dMl = pctDelta(tt.total, ty.total);
    final dMin = pctDelta(bm, bmy);
    final dCnt = tt.count - ty.count;

    Widget cell(Widget icon, String label, Widget value, Widget? delta) => Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
            decoration: BoxDecoration(color: GB.accentSoft.withValues(alpha: .35), borderRadius: BorderRadius.circular(18)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                icon,
                const SizedBox(width: 6),
                Expanded(child: Text(label, maxLines: 2, style: GB.body(11.5, color: GB.inkMuted, height: 1.2))),
              ]),
              const SizedBox(height: 8),
              value,
              const SizedBox(height: 8),
              delta ?? Text('chưa có để so', style: GB.body(11, color: GB.inkMuted)),
            ]),
          ),
        );

    return SectionCard(
      title: 'Tổng quan hôm nay',
      icon: Icons.wb_sunny_rounded,
      iconColor: const Color(0xFFF2B632),
      trailing: 'Xem chi tiết',
      onTrailing: () => widget.goTab(2),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          cell(const Icon(Icons.water_drop_rounded, color: GB.pumpDeep, size: 24), 'Tổng sữa hôm nay', BigNumber(GB.thousands(tt.total), 'ml', size: 26), dMl == null ? null : DeltaChip(dMl.text, up: dMl.up)),
          const SizedBox(width: 8),
          cell(const Icon(Icons.timer_outlined, color: GB.breastDeep, size: 24), 'Thời gian bú', BigNumber('$bm', 'phút', size: 26), dMin == null ? null : DeltaChip(dMin.text, up: dMin.up)),
          const SizedBox(width: 8),
          cell(const Art('ic_bottle', height: 26), 'Số cữ ăn', BigNumber('${tt.count}', 'cữ', size: 26), ty.count == 0 && tt.count == 0 ? null : DeltaChip('${dCnt >= 0 ? '+' : ''}$dCnt', up: dCnt >= 0)),
        ]),
      ),
    );
  }

  // ───────── Cữ gần nhất
  Widget _latest(DateTime now) {
    final f = app.ofType(T.feed).firstOrNull;
    final p = app.ofType(T.pump).firstOrNull;
    final e = f == null ? p : (p == null ? f : (p.time.isAfter(f.time) ? p : f));
    Widget body;
    if (e == null) {
      body = const EmptyState('Chưa có cữ nào được ghi.');
    } else {
      final isPump = e.type == T.pump;
      final breast = !isPump && e.str('method') == 'breast';
      final art = isPump ? 'ic_pump' : (breast ? 'ic_breast' : 'ic_bottle');
      final tile = isPump ? GB.pumpTile : (breast ? GB.breastTile : GB.bottleTile);
      final title = isPump ? 'Hút sữa' : (breast ? 'Cho bú' : 'Bình sữa');
      final end = e.end ?? e.time;
      final mins = e.end == null ? null : e.end!.difference(e.time).inMinutes;
      body = Row(children: [
        Container(width: 60, height: 60, padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: tile.withValues(alpha: .6), shape: BoxShape.circle), child: Art(art)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(title, style: GB.display(17, w: FontWeight.w800))),
              SoftPill(GB.ago(end), arrow: false),
            ]),
            const SizedBox(height: 4),
            Text(mins == null || mins < 1 ? GB.hm(e.time) : '${GB.hm(e.time)} – ${GB.hm(end)} ($mins phút)', style: GB.body(13.5, color: GB.inkMuted)),
            if (e.ml > 0)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(children: [
                  const Icon(Icons.water_drop_rounded, size: 16, color: Color(0xFFF2B632)),
                  const SizedBox(width: 4),
                  Text('${e.ml} ml${e.data['est'] == true ? ' (ước tính)' : ''}', style: GB.body(15, w: FontWeight.w800)),
                ]),
              ),
          ]),
        ),
      ]);
    }
    return SectionCard(title: 'Cữ gần nhất', icon: Icons.schedule_rounded, iconColor: GB.pumpDeep, trailing: e == null ? null : 'Lịch sử', onTrailing: () => widget.goTab(1), child: body);
  }

  // ───────── Dải 24 giờ
  Widget _activity(DateTime now) {
    final day = AppState.dayStart(now);
    final es = app.entriesOn(now);
    Widget seg(double l, double w, Color c) => Positioned(left: l, width: w, top: 0, bottom: 0, child: Container(decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4))));
    return GlassCard(
      radius: 26,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.bar_chart_rounded, color: GB.pumpDeep, size: 22),
          const SizedBox(width: 6),
          Expanded(child: Text('Hoạt động hôm nay', style: GB.display(14.5, w: FontWeight.w800), maxLines: 2)),
        ]),
        const Spacer(),
        LayoutBuilder(builder: (context, c) {
          final w = c.maxWidth;
          final children = <Widget>[Positioned.fill(child: Container(decoration: BoxDecoration(color: GB.line.withValues(alpha: .6), borderRadius: BorderRadius.circular(4))))];
          for (final e in es) {
            if (e.type != T.feed && e.type != T.pump && e.type != T.sleep) continue;
            final s = e.time.difference(day).inMinutes / 1440 * w;
            var span = ((e.end ?? e.time).difference(e.time).inMinutes) / 1440 * w;
            if (e.type == T.sleep && e.end == null) span = now.difference(e.time).inMinutes / 1440 * w;
            span = span.clamp(e.type == T.sleep ? 6 : 7, w);
            final col = e.type == T.sleep ? GB.sleepDeep : e.type == T.pump ? GB.pumpDeep : (e.str('method') == 'breast' ? GB.breastDeep : GB.bottleDeep);
            children.add(seg(s.clamp(0, w - span).toDouble(), span.toDouble(), col.withValues(alpha: e.type == T.sleep ? .55 : .9)));
          }
          return SizedBox(height: 18, child: Stack(children: children));
        }),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [for (final h in const ['0h', '6h', '12h', '18h', '24h']) Text(h, style: GB.body(10.5, color: GB.inkMuted))]),
      ]),
    );
  }

  Widget _sleepCard(DateTime now) {
    final s = app.activeSleep;
    final wake = app.lastWake;
    final String title, sub, pill;
    if (s != null) {
      title = '${app.baby!.name} đang ngủ';
      sub = 'Từ ${GB.hm(s.time)}';
      pill = 'Đã ngủ ${GB.dur(now.difference(s.time))}';
    } else {
      title = '${app.baby!.name} đang thức';
      sub = wake == null ? 'Chưa ghi giờ dậy' : 'Dậy từ ${GB.hm(wake)}';
      pill = wake == null ? 'Bấm để xem nhịp EASY' : 'Thức ${GB.dur(now.difference(wake).isNegative ? Duration.zero : now.difference(wake))}';
    }
    return GlassCard(
      radius: 26,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      onTap: () => openPage(context, const EasyScreen()),
      child: Row(children: [
        Container(width: 46, height: 60, alignment: Alignment.center, decoration: BoxDecoration(color: GB.bottleTile.withValues(alpha: .5), borderRadius: BorderRadius.circular(14)), child: const Art('baby_sleep', width: 44)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(title, style: GB.body(13.5, w: FontWeight.w800, height: 1.15)),
            Text(sub, style: GB.body(12, color: GB.inkMuted)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: GB.sleepTile, borderRadius: BorderRadius.circular(10)),
              child: Text(pill, style: GB.body(11, w: FontWeight.w800, color: const Color(0xFF4B6B47), height: 1.2)),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _sleepToday() {
    final age = app.age;
    final sr = Easy.sleepHours(age.adjDays);
    final sleepToday = app.sleepOn(DateTime.now());
    return SectionCard(
      title: 'Giấc ngủ hôm nay',
      icon: Icons.bedtime_rounded,
      iconColor: GB.sleepDeep,
      trailing: 'Nhịp EASY',
      onTrailing: () => openPage(context, const EasyScreen()),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(GB.dur(sleepToday), style: GB.display(32)),
          const Spacer(),
          Flexible(child: Text('tham khảo ${sr.text('h')}/ngày', textAlign: TextAlign.right, style: GB.body(12.5, w: FontWeight.w600, color: GB.inkMuted))),
        ]),
        const SizedBox(height: 4),
        RangeBar(value: sleepToday.inMinutes / 60, lo: sr.lo, hi: sr.hi, maxV: sr.hi * 1.2, color: GB.sleepDeep),
        const SizedBox(height: 6),
        Text('Nhu cầu ngủ theo National Sleep Foundation (cả ngày lẫn đêm). Tổng ngày chưa đủ vì còn đêm nay.', style: GB.body(11.5, color: GB.inkMuted, height: 1.4)),
      ]),
    );
  }

  Widget _quote(DateTime now) {
    final q = _quotes[(now.difference(DateTime(now.year, 1, 1)).inDays) % _quotes.length];
    return Row(children: [
      const Icon(Icons.favorite_rounded, color: Color(0xFFF08A97), size: 20),
      const SizedBox(width: 8),
      Expanded(child: Text('“$q”', style: GB.script(14, italic: true, color: const Color(0xFF8B6A6A)))),
      const SizedBox(width: 8),
      const Art('rainbow', width: 62),
    ]);
  }

  // ───────── EASY: giờ ngủ kế tiếp
  Widget _nextUpCard() {
    final age = app.age.adjDays;
    final ww = Easy.wakeWindow(age);
    final wake = app.lastWake;
    final cycle = Easy.cycleFor(app.settings, age);
    final lastFeed = app.lastFeed;
    final now = DateTime.now();

    String big = '—';
    String sub = 'Ghi giờ bé dậy để dự đoán';
    double progress = 0;
    String left = '', right = '';
    var over = false;
    final night = now.hour >= 20 || now.hour < 5;
    if (night) {
      big = 'Ngủ đêm';
      sub = 'đã khuya, bé nên ngủ đêm rồi';
      progress = 1;
    } else if (wake != null) {
      final awake = now.difference(wake);
      final target = wake.add(Duration(minutes: ww.mid.round()));
      final remain = target.difference(now);
      progress = (awake.inMinutes / ww.hi).clamp(0.0, 1.0);
      left = 'Dậy ${GB.hm(wake)}';
      right = 'Ngủ ~${GB.hm(target)}';
      if (remain.isNegative) {
        over = true;
        big = '${(-remain.inMinutes)} phút';
        sub = 'đã quá giờ ngủ gợi ý';
      } else if (remain.inMinutes < 1) {
        big = 'Sắp tới';
        sub = 'giờ ngủ';
      } else {
        big = remain.inHours >= 1 ? '${remain.inHours}h${GB.two(remain.inMinutes % 60)}' : '${remain.inMinutes} phút';
        sub = 'nữa là tới cữ ngủ';
      }
    }
    final nextFeed = lastFeed == null ? null : lastFeed.time.add(Duration(minutes: cycle));

    return SectionCard(
      title: 'Giờ ngủ kế tiếp',
      icon: Icons.nights_stay_rounded,
      iconColor: GB.bottleDeep,
      trailing: Easy.label(cycle),
      onTrailing: () => openPage(context, const EasyScreen()),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(big, style: GB.display(wake == null && !night ? 38 : 46, color: over ? GB.alert : GB.title))),
        Text(sub, style: GB.body(14, color: GB.inkMuted, height: 1.3)),
        if (wake != null) ...[
          const SizedBox(height: 10),
          ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: GB.line, valueColor: AlwaysStoppedAnimation(over ? GB.alert : GB.sleepDeep))),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(left, style: GB.body(12, color: GB.inkMuted)),
            Text(right, style: GB.body(12, color: GB.inkMuted)),
          ]),
        ],
        const SizedBox(height: 6),
        Text('Thức tối đa thường gặp ${ww.text('p')} ở tuổi này${nextFeed != null ? ' · bú kế ~${GB.hm(nextFeed)}' : ''}', style: GB.body(12, color: GB.inkMuted)),
      ]),
    );
  }

  // ───────── Nhắc nhở
  List<Widget> _reminders() {
    final items = <Widget>[];
    final now = DateTime.now();
    if (app.settings.remind) {
      final done = app.pumpSessionsOn(now);
      final times = app.settings.pumpTimes;
      if (app.baby!.mode != FeedMode.formula && done < times.length) {
        final next = DateTime(now.year, now.month, now.day, times[done]);
        final diff = next.difference(now);
        if (diff.inMinutes <= 30 && diff.inMinutes > -120) {
          items.add(_remind(Icons.favorite_rounded, GB.pump, diff.isNegative ? 'Đã tới cữ hút ${done + 1}' : 'Cữ hút ${done + 1} lúc ${GB.hm(next)}', 'Bấm để ghi hút sữa', () => openPage(context, const PumpScreen())));
        }
      }
      final exp = app.fridgeActive.where((f) => f.expires.difference(now).inHours <= 24 && f.expires.isAfter(now)).toList();
      if (exp.isNotEmpty) {
        items.add(_remind(Icons.kitchen_rounded, GB.warn, '${exp.length} bình sữa sắp hết hạn', 'Nên dùng trước: ${exp.first.left}ml, còn ${GB.dur(exp.first.expires.difference(now))}', () => openPage(context, const MilkHub())));
      }
      final vr = nextVaccineReminder();
      if (vr != null) {
        items.add(_remind(Icons.vaccines_rounded, GB.alert, vr.status == VStatus.overdue ? 'Quá lịch: ${vr.v.name}' : 'Mũi tiêm: ${vr.v.name}', 'Dự kiến ${GB.dmy(vr.dueDate)}', () => openPage(context, const VaccineScreen())));
      }
      for (final a in app.appts.where((a) => !a.done && AppState.dayStart(a.time) == AppState.dayStart(now))) {
        items.add(_remind(Icons.event_rounded, GB.info, a.title, 'Hôm nay ${GB.hm(a.time)}${a.place.isEmpty ? '' : ' · ${a.place}'}', () => widget.goTab(4)));
      }
    }
    if (items.isEmpty) return const [];
    return [const SizedBox(height: 10), ...items.expand((w) => [w, const SizedBox(height: 8)]).toList()..removeLast()];
  }

  Widget _remind(IconData icon, Color color, String title, String sub, VoidCallback onTap) {
    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(children: [
        IconBadge(icon: icon, bg: color.withValues(alpha: .22), fg: color, size: 38),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GB.body(14, w: FontWeight.w800)),
            Text(sub, style: GB.body(12, color: GB.inkMuted)),
          ]),
        ),
        const Icon(Icons.chevron_right_rounded, color: GB.inkMuted),
      ]),
    );
  }
}
