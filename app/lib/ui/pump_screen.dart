import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/kit.dart';
import '../core/platform.dart';
import '../core/pastel.dart';
import '../core/theme.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import '../domain/pump_ref.dart';
import 'history.dart';
import 'widgets.dart';

/// Ghi hút sữa: bấm giờ hai bên (trái/phải); khi Kết thúc hiện ngay hộp nhập lượng sữa (hoặc nhập tay một cữ đã hút).
class PumpScreen extends StatefulWidget {
  const PumpScreen({super.key});

  @override
  State<PumpScreen> createState() => _PumpScreenState();
}

class _PumpScreenState extends State<PumpScreen> {
  static const goalMin = 20;

  int l = 60, r = 60; // lượng gợi ý ban đầu cho hộp nhập
  int manualMin = 20;
  DateTime time = DateTime.now();
  bool autoStop = true;
  bool _sheetOpen = false;

  // đồng hồ
  Timer? _t;
  DateTime? startAt;
  DateTime? endAt;
  bool running = false;
  bool activeL = true, activeR = true;
  Duration accTotal = Duration.zero, accL = Duration.zero, accR = Duration.zero;
  DateTime _last = DateTime.now();

  @override
  void initState() {
    super.initState();
    final base = app.pumpBaseline();
    final g = _target().perSession;
    final start = (base ?? (g > 0 ? g : 100)).round();
    l = ((start / 2) / 10).round() * 10;
    r = l;
    _t = Timer.periodic(const Duration(milliseconds: 500), (_) {
      keepScreenAwake(mounted && running); // đang bấm giờ thì không để màn hình tự khoá
      if (!mounted || !running) return;
      if (autoStop && _total.inSeconds >= goalMin * 60) {
        _end();
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    keepScreenAwake(false);
    super.dispose();
  }

  Duration get _total => accTotal + (running ? DateTime.now().difference(_last) : Duration.zero);
  Duration get _left => accL + (running && activeL ? DateTime.now().difference(_last) : Duration.zero);
  Duration get _right => accR + (running && activeR ? DateTime.now().difference(_last) : Duration.zero);

  void _flush() {
    if (!running) return;
    final now = DateTime.now();
    final d = now.difference(_last);
    accTotal += d;
    if (activeL) accL += d;
    if (activeR) accR += d;
    _last = now;
  }

  void _toggle() {
    setState(() {
      if (running) {
        _flush();
        running = false;
      } else {
        startAt ??= DateTime.now();
        endAt = null;
        _last = DateTime.now();
        running = true;
      }
    });
  }

  void _end() {
    setState(() {
      _flush();
      running = false;
      if (startAt != null) endAt = DateTime.now();
      if (accTotal.inSeconds > 0) manualMin = math.max(1, accTotal.inMinutes);
    });
    // kết thúc xong hiện ngay hộp nhập lượng sữa (mẹ có thể đóng lại và mở lại bằng nút ở dưới)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_sheetOpen) _openEntry();
    });
  }

  void _reset() {
    setState(() {
      running = false;
      startAt = null;
      endAt = null;
      accTotal = accL = accR = Duration.zero;
      activeL = activeR = true;
    });
  }

  void _toggleSide(bool left) {
    setState(() {
      _flush();
      if (left) {
        activeL = !activeL;
      } else {
        activeR = !activeR;
      }
      _last = DateTime.now();
    });
  }

  PumpTarget _target() => PumpRef.target(
        ageDays: app.age.adjDays,
        weightKg: app.weightKg,
        sessionsPerDay: app.settings.pumpSessions,
        pumpShare: app.settings.pumpShare,
        pumpedToday: app.pumpedOn(time).toDouble(),
        sessionsDone: app.pumpSessionsOn(time),
      );


  String _clock(Duration d) => '${GB.two(d.inMinutes)}:${GB.two(d.inSeconds % 60)}';

  /// Mở hộp nhập lượng sữa. [manual]: nhập tay một cữ đã hút (không bấm giờ).
  Future<void> _openEntry({bool manual = false}) async {
    _flush();
    _sheetOpen = true;
    final timed = !manual && startAt != null;
    final res = await showGlassSheet<_PumpResult>(
      context,
      builder: (ctx) => _PumpEntrySheet(
        l: l,
        r: r,
        timed: timed,
        minutes: timed ? math.max(1, accTotal.inMinutes) : manualMin,
        time: timed ? startAt! : time,
        last: app.ofType(T.pump).firstOrNull,
      ),
    );
    _sheetOpen = false;
    if (res == null || !mounted) return;
    await _commit(res, timed: timed);
  }

  Future<void> _commit(_PumpResult res, {required bool timed}) async {
    final total = res.l + res.r;
    final a = PumpRef.assess(ml: total, ageDays: app.age.adjDays, baseline: app.pumpBaseline(), perSessionGoal: _target().perSession);
    final st = res.time;
    final en = timed ? (endAt ?? DateTime.now()) : st.add(Duration(minutes: res.minutes));
    final e = app.addPump(mlL: res.l, mlR: res.r, minutes: res.minutes, time: st, end: en, store: res.store, bottles: res.bottles, note: res.note);
    running = false;
    if (!mounted) return;
    final t = _target();
    final doneToday = app.pumpedOn(st);
    // Lượng thấp hơn thường gặp thì hiện lời khuyên; còn lại chỉ báo ngắn (đỡ một lần chạm "Xong").
    if (total > 0 && a.verdict == PumpVerdict.lower) {
      await showGlassSheet(context, builder: (ctx) {
        return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Orb(icon: Icons.check_rounded, color: GB.okBg),
            const SizedBox(width: 12),
            Expanded(child: Text('Đã ghi ${total}ml', style: GB.display(22, w: FontWeight.w700))),
          ]),
          const SizedBox(height: 14),
          PumpAssessmentCard(a),
          const SizedBox(height: 12),
          Text('Hôm nay đã hút ${doneToday}ml · mục tiêu ~${t.dailyGoal.round()}ml', style: GB.body(13.5, w: FontWeight.w700)),
          const SizedBox(height: 6),
          RangeBar(value: doneToday.toDouble(), lo: t.dailyGoal * .85, hi: t.dailyGoal * 1.15, maxV: math.max(t.dailyGoal * 1.5, doneToday.toDouble())),
          if (res.store != 'none') ...[
            const SizedBox(height: 10),
            Text('Đã thêm ${res.bottles} bình vào ${res.store == 'freezer' ? 'ngăn đông' : 'ngăn mát'}.', style: GB.body(13, color: GB.inkMuted)),
          ],
          const SizedBox(height: 14),
          BigButton('Xong', onTap: () => Navigator.pop(ctx)),
        ]);
      });
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final nav = Navigator.of(context);
    toast(context, total > 0 ? 'Đã ghi ${total}ml · hôm nay $doneToday/${t.dailyGoal.round()}ml' : 'Đã ghi cữ hút ${res.minutes} phút', undo: res.store == 'none' ? () => app.removeEntry(e.id) : null);
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final done = app.pumpSessionsOn(time) + 1;
    final ended = endAt != null;
    final started = startAt != null;
    final recent = app.ofType(T.pump).take(3).toList();

    final String label;
    final IconData icon;
    final VoidCallback action;
    if (!started) {
      label = 'Bắt đầu hút';
      icon = Icons.play_arrow_rounded;
      action = _toggle;
    } else if (!ended) {
      label = 'Kết thúc và nhập lượng sữa';
      icon = Icons.stop_rounded;
      action = _end;
    } else {
      label = 'Nhập lượng sữa';
      icon = Icons.water_drop_rounded;
      action = () => _openEntry();
    }

    return SubPage(
      title: 'Hút sữa',
      subtitle: 'Bấm giờ, kết thúc rồi nhập lượng sữa',
      art: 'hero_pump',
      artWidth: 150,
      bottom: BigButton(label, icon: icon, onTap: action),
      children: [
        _timerCard(done),
        const SizedBox(height: 10),
        if (!started)
          Semantics(
            button: true,
            label: 'Nhập tay một cữ đã hút',
            child: GlassCard(
              radius: 20,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              onTap: () => _openEntry(manual: true),
              child: Row(children: [
                Icon(Icons.edit_note_rounded, color: GB.accentDeep, size: 24),
                const SizedBox(width: 10),
                Expanded(child: Text('Nhập tay một cữ đã hút (không bấm giờ)', style: GB.body(14, w: FontWeight.w700))),
                Icon(Icons.chevron_right_rounded, color: GB.inkMuted),
              ]),
            ),
          ),
        const SizedBox(height: 10),
        _todayCard(),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Các cữ hút gần đây',
          icon: Icons.history_rounded,
          iconColor: GB.pumpDeep,
          trailing: 'Xem tất cả',
          onTrailing: () => openPage(context, const HistoryScreen()),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
          child: recent.isEmpty ? const EmptyState('Chưa có cữ hút nào.') : Column(children: [for (final e in recent) _recentRow(e)]),
        ),
        const SizedBox(height: 12),
        Text('Nguồn tham khảo: Kent 2006 (Pediatrics), tổng hợp của tư vấn viên sữa mẹ, CDC. Lượng hút không phản ánh toàn bộ lượng sữa mẹ. Không thay thế tư vấn của bác sĩ hoặc tư vấn viên sữa mẹ.', style: GB.body(11.5, color: GB.inkMuted, height: 1.4)),
      ],
    );
  }

  // ───────── Tóm tắt hôm nay: số cữ, lượng đã hút so với mục tiêu, tự động dừng
  Widget _todayCard() {
    final t = _target();
    final doneMl = app.pumpedOn(time);
    final sessions = app.pumpSessionsOn(time);
    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.water_drop_rounded, size: 20, color: GB.pumpDeep),
          const SizedBox(width: 8),
          Expanded(child: Text('Hôm nay', style: GB.body(14.5, w: FontWeight.w800))),
          Text('$sessions/${app.settings.pumpSessions} cữ · ${doneMl}ml', style: GB.body(13.5, w: FontWeight.w700, color: GB.accentDeep)),
        ]),
        const SizedBox(height: 8),
        RangeBar(value: doneMl.toDouble(), lo: t.dailyGoal * .85, hi: t.dailyGoal * 1.15, maxV: math.max(t.dailyGoal * 1.5, doneMl.toDouble())),
        const SizedBox(height: 4),
        Text('Mục tiêu tham khảo ~${t.dailyGoal.round()}ml/ngày', style: GB.body(12, color: GB.inkMuted)),
        Row(children: [
          Expanded(child: Text('Tự động dừng sau $goalMin phút', style: GB.body(13, color: GB.inkMuted))),
          Switch(value: autoStop, activeThumbColor: Colors.white, activeTrackColor: GB.pumpDeep, onChanged: (v) => setState(() => autoStop = v)),
        ]),
      ]),
    );
  }

  // ───────── Thẻ đồng hồ
  Widget _timerCard(int done) {
    final tot = _total;
    final progress = (tot.inSeconds / (goalMin * 60)).clamp(0.0, 1.0);
    final state = running ? 'Đang hút sữa...' : (startAt == null ? 'Cữ $done/${app.settings.pumpSessions} hôm nay' : (endAt != null ? 'Đã kết thúc' : 'Tạm dừng'));
    return GlassCard(
      radius: 28,
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 14),
      child: Column(children: [
        SoftPill(state, arrow: false),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(child: _sidePanel('Trái', 'pump_left', _left, activeL, () => _toggleSide(true))),
          SizedBox(
            width: 124,
            height: 124,
            child: CustomPaint(
              painter: _RingPainter(progress),
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  FittedBox(fit: BoxFit.scaleDown, child: Text(_clock(tot), style: GB.display(34))),
                  Text('/ $goalMin phút', style: GB.body(12.5, color: GB.inkMuted)),
                ]),
              ),
            ),
          ),
          Expanded(child: _sidePanel('Phải', 'pump_right', _right, activeR, () => _toggleSide(false))),
        ]),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _ctrl('Kết thúc', Icons.stop_rounded, 54, GB.accentSoft, GB.accentDeep, startAt == null ? null : _end),
          _ctrl(running ? 'Tạm dừng' : (startAt == null ? 'Bắt đầu' : 'Tiếp tục'), running ? Icons.pause_rounded : Icons.play_arrow_rounded, 70, GB.pumpDeep, Colors.white, _toggle),
          _ctrl('Đặt lại', Icons.refresh_rounded, 54, GB.accentSoft, GB.accentDeep, startAt == null && accTotal == Duration.zero ? null : _reset),
        ]),
      ]),
    );
  }

  Widget _sidePanel(String name, String art, Duration d, bool active, VoidCallback onTap) {
    final on = active && running;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(color: (name == 'Trái' ? GB.pumpTile : GB.bottleTile).withValues(alpha: .3), borderRadius: BorderRadius.circular(20), border: Border.all(color: GB.edgeOf((name == 'Trái' ? GB.pumpTile : GB.bottleTile).withValues(alpha: .3)), width: 1)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(height: 46, child: Art(art, height: 46)),
          const SizedBox(height: 4),
          Text(name, style: GB.body(14, w: FontWeight.w800)),
          Text(_clock(d), style: GB.body(13.5, w: FontWeight.w600)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: on ? GB.accentSoft : GB.line.withValues(alpha: .7), borderRadius: BorderRadius.circular(12), border: Border.all(color: GB.edgeOf(on ? GB.accentSoft : GB.line.withValues(alpha: .7)), width: 1)),
            child: Text(!active ? 'Nghỉ bên này' : (on ? 'Đang hút' : (d.inSeconds > 0 ? 'Tạm dừng' : 'Chưa hút')), style: GB.body(10.5, w: FontWeight.w700, color: on ? GB.accentDeep : GB.inkMuted)),
          ),
        ]),
      ),
    );
  }

  Widget _ctrl(String label, IconData icon, double size, Color bg, Color fg, VoidCallback? onTap) {
    return Semantics(
      button: true,
      label: label,
      enabled: onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? .45 : 1,
          child: SizedBox(
            width: 82,
            child: Column(children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle, boxShadow: bg == GB.pumpDeep ? [BoxShadow(color: GB.pumpDeep.withValues(alpha: .35), blurRadius: 14, offset: const Offset(0, 6))] : null),
                child: Icon(icon, size: size * .5, color: fg),
              ),
              const SizedBox(height: 4),
              FittedBox(fit: BoxFit.scaleDown, child: Text(label, maxLines: 1, style: GB.body(13, w: FontWeight.w700, color: GB.accentDeep))),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _recentRow(Entry e) {
    final mins = e.end == null ? e.num('min').round() : e.end!.difference(e.time).inMinutes;
    final end = e.end ?? e.time.add(Duration(minutes: mins));
    Widget col(String top, String bottom, Color c) => SizedBox(
          width: 52,
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.water_drop_rounded, size: 12, color: c), const SizedBox(width: 2), Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(top, style: GB.body(12.5, w: FontWeight.w800))))]),
            Text(bottom, style: GB.body(11, color: GB.inkMuted)),
          ]),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Icon(Icons.event_note_rounded, color: GB.pumpDeep, size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(GB.dayLabel(e.time), style: GB.body(13, w: FontWeight.w800)),
            Text(mins > 0 ? '${GB.hm(e.time)} – ${GB.hm(end)}' : GB.hm(e.time), style: GB.body(11.5, color: GB.inkMuted)),
          ]),
        ),
        col('${e.num('l').round()} ml', 'Trái', GB.pumpDeep),
        col('${e.num('r').round()} ml', 'Phải', GB.bottleDeep),
        col('${e.ml} ml', 'Tổng', const Color(0xFFF2B632)),
        Icon(Icons.chevron_right_rounded, color: GB.inkMuted, size: 20),
      ]),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final rad = size.width / 2 - 10;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = GB.accentSoft;
    canvas.drawCircle(c, rad, track);
    if (progress > 0) {
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(startAngle: -math.pi / 2, endAngle: 3 * math.pi / 2, colors: [Color(0xFFF4A3A8), GB.pumpDeep], transform: const GradientRotation(0)).createShader(Rect.fromCircle(center: c, radius: rad));
      canvas.drawArc(Rect.fromCircle(center: c, radius: rad), -math.pi / 2, 2 * math.pi * progress, false, p);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}


/// Kết quả hộp nhập lượng sữa.
class _PumpResult {
  const _PumpResult({required this.l, required this.r, required this.minutes, required this.time, required this.store, required this.bottles, required this.note});
  final int l, r, minutes;
  final DateTime time;
  final String store;
  final int bottles;
  final String note;
}

/// Hộp nhập lượng sữa sau cữ hút: số ml từng bên (bước 5), chọn nhanh, lưu vào tủ sữa, ghi chú.
class _PumpEntrySheet extends StatefulWidget {
  const _PumpEntrySheet({required this.l, required this.r, required this.timed, required this.minutes, required this.time, required this.last});
  final int l, r;
  final bool timed; // đã bấm giờ: hiện thời gian đã hút; chưa thì cho nhập giờ và số phút
  final int minutes;
  final DateTime time;
  final Entry? last;

  @override
  State<_PumpEntrySheet> createState() => _PumpEntrySheetState();
}

class _PumpEntrySheetState extends State<_PumpEntrySheet> {
  late int l = widget.l, r = widget.r, minutes = widget.minutes;
  late DateTime time = widget.time;
  String store = 'fridge';
  int bottles = 1;
  final note = TextEditingController();

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  int get total => l + r;

  Widget _side(String name, int v, Color tile, Color deep, ValueChanged<int> on) {
    Widget mini(IconData ic, String label, bool filled, VoidCallback tap) => Semantics(
          button: true,
          label: label,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: tap,
            child: minHit(Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: filled ? deep : GB.w(.7), shape: BoxShape.circle),
              child: Icon(ic, size: 22, color: filled ? Colors.white : deep),
            )),
          ),
        );
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 12, 6, 8),
      decoration: BoxDecoration(color: tile.withValues(alpha: .5), borderRadius: BorderRadius.circular(18), border: Border.all(color: GB.edgeOf(tile.withValues(alpha: .5)), width: 1)),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.water_drop_rounded, size: 18, color: deep),
          const SizedBox(width: 4),
          Text(name, style: GB.body(13.5, w: FontWeight.w800)),
        ]),
        const SizedBox(height: 8),
        BigNumber('$v', 'ml', size: 30),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          mini(Icons.remove_rounded, 'Giảm $name 5ml', false, () => on(math.max(0, v - 5))),
          mini(Icons.add_rounded, 'Tăng $name 5ml', true, () => on(math.min(300, v + 5))),
        ]),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final last = widget.last;
    final lastL = last == null ? 0 : last.num('l').round();
    final lastR = last == null ? 0 : last.num('r').round();
    final hasLast = last != null && lastL + lastR > 0;
    final a = PumpRef.assess(ml: total, ageDays: app.age.adjDays, baseline: app.pumpBaseline(), perSessionGoal: PumpRef.target(ageDays: app.age.adjDays, weightKg: app.weightKg, sessionsPerDay: app.settings.pumpSessions, pumpShare: app.settings.pumpShare, pumpedToday: app.pumpedOn(time).toDouble(), sessionsDone: app.pumpSessionsOn(time)).perSession);

    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Lượng sữa đã hút', style: GB.display(22, w: FontWeight.w700)),
      const SizedBox(height: 4),
      if (widget.timed)
        Text('Đã hút $minutes phút · bắt đầu ${GB.hm(time)}', style: GB.body(13, color: GB.inkMuted))
      else ...[
        Text('Nhập tay một cữ đã hút', style: GB.body(13, color: GB.inkMuted)),
        const SizedBox(height: 10),
        TimeRow(label: 'Lúc', time: time, onChanged: (d) => setState(() => time = d)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: Text('Thời gian hút', style: GB.body(14, w: FontWeight.w700))),
          RoundIconButton(icon: Icons.remove_rounded, label: 'Giảm 5 phút', size: 40, onTap: () => setState(() => minutes = math.max(5, minutes - 5))),
          SizedBox(width: 78, child: Text('$minutes phút', textAlign: TextAlign.center, style: GB.body(15, w: FontWeight.w800))),
          RoundIconButton(icon: Icons.add_rounded, label: 'Tăng 5 phút', size: 40, filled: true, onTap: () => setState(() => minutes = math.min(60, minutes + 5))),
        ]),
      ],
      const SizedBox(height: 14),
      IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: _side('Trái', l, GB.pumpTile, GB.pumpDeep, (v) => setState(() => l = v))),
          const SizedBox(width: 10),
          Expanded(child: _side('Phải', r, GB.bottleTile, GB.bottleDeep, (v) => setState(() => r = v))),
        ]),
      ),
      const SizedBox(height: 10),
      Row(children: [
        Icon(Icons.water_drop_rounded, size: 18, color: const Color(0xFFF2B632)),
        const SizedBox(width: 6),
        Text('Tổng cộng $total ml', style: GB.body(16, w: FontWeight.w800)),
        const SizedBox(width: 8),
        Expanded(child: Text(total > 0 ? a.title : '', maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right, style: GB.body(12.5, color: GB.inkMuted))),
      ]),
      const SizedBox(height: 12),
      Text('Chọn nhanh (Trái + Phải)', style: GB.body(12.5, w: FontWeight.w700, color: GB.inkMuted)),
      const SizedBox(height: 6),
      Wrap(spacing: 8, runSpacing: 8, children: [
        if (hasLast) PillChip(label: 'Lần trước ($lastL+$lastR)', icon: Icons.replay_rounded, on: l == lastL && r == lastR, onTap: () => setState(() {
              l = lastL;
              r = lastR;
            })),
        for (final v in const [20, 30, 40, 50, 60]) PillChip(label: '$v+$v', on: l == v && r == v, onTap: () => setState(() => l = r = v)),
      ]),
      const SizedBox(height: 12),
      Text('Lưu vào tủ sữa', style: GB.body(14, w: FontWeight.w800)),
      const SizedBox(height: 8),
      Seg(labels: const ['Không', 'Ngăn mát', 'Ngăn đông'], index: const ['none', 'fridge', 'freezer'].indexOf(store), height: 44, onChanged: (i) => setState(() => store = const ['none', 'fridge', 'freezer'][i])),
      if (store != 'none') ...[
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: Text('Chia thành $bottles bình · ~${(total / bottles).round()}ml mỗi bình', style: GB.body(13, w: FontWeight.w600))),
          RoundIconButton(icon: Icons.remove_rounded, label: 'Bớt một bình', size: 40, onTap: () => setState(() => bottles = math.max(1, bottles - 1))),
          const SizedBox(width: 6),
          RoundIconButton(icon: Icons.add_rounded, label: 'Thêm một bình', size: 40, filled: true, onTap: () => setState(() => bottles = math.min(8, bottles + 1))),
        ]),
      ],
      const SizedBox(height: 12),
      GlassField(controller: note, label: 'Ghi chú (không bắt buộc)', icon: Icons.edit_note_rounded),
      const SizedBox(height: 16),
      BigButton(total > 0 ? 'Lưu · ${total}ml' : 'Lưu cữ hút', icon: Icons.check_rounded, onTap: () {
        Navigator.pop(context, _PumpResult(l: l, r: r, minutes: minutes, time: time, store: total > 0 ? store : 'none', bottles: bottles, note: note.text.trim()));
      }),
      if (total == 0)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Center(child: Text('Chưa nhập lượng sữa: cữ hút vẫn được lưu với số phút.', style: GB.body(12, color: GB.inkMuted))),
        ),
    ]);
  }
}
