import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/kit.dart';
import '../core/pastel.dart';
import '../core/theme.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import '../domain/pump_ref.dart';
import 'bottle.dart';
import 'history.dart';
import 'widgets.dart';

/// Ghi hút sữa: đồng hồ hai bên (trái/phải), lượng sữa, đánh giá nhẹ nhàng theo tuổi và cân nặng.
class PumpScreen extends StatefulWidget {
  const PumpScreen({super.key});

  @override
  State<PumpScreen> createState() => _PumpScreenState();
}

class _PumpScreenState extends State<PumpScreen> {
  static const goalMin = 20;

  int l = 60, r = 60;
  int manualMin = 20;
  DateTime time = DateTime.now();
  String store = 'fridge';
  int bottles = 1;
  String note = '';
  bool autoStop = true;
  bool showBottles = false;

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

  int get _minutes => accTotal.inSeconds >= 60 ? math.max(1, _total.inMinutes) : manualMin;

  Future<void> _save() async {
    _flush();
    final total = l + r;
    final a = PumpRef.assess(ml: total, ageDays: app.age.adjDays, baseline: app.pumpBaseline(), perSessionGoal: _target().perSession);
    final st = startAt ?? time;
    final en = endAt ?? (startAt != null ? DateTime.now() : null);
    final mins = _minutes;
    app.addPump(mlL: l, mlR: r, minutes: mins, time: st, end: en ?? st.add(Duration(minutes: mins)), store: store, bottles: bottles, note: note);
    running = false;
    if (!mounted) return;
    final t = _target();
    await showGlassSheet(context, builder: (ctx) {
      final doneToday = app.pumpedOn(st);
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
        if (store != 'none') ...[
          const SizedBox(height: 10),
          Text('Đã thêm $bottles bình vào ${store == 'freezer' ? 'ngăn đông' : 'ngăn mát'}.', style: GB.body(13, color: GB.inkMuted)),
        ],
        const SizedBox(height: 14),
        BigButton('Xong', onTap: () => Navigator.pop(ctx)),
      ]);
    });
    if (mounted) Navigator.of(context).pop();
  }

  String _clock(Duration d) => '${GB.two(d.inMinutes)}:${GB.two(d.inSeconds % 60)}';

  Future<void> _editNote() async {
    final c = TextEditingController(text: note);
    final v = await showDialog<String>(
      context: context,
      builder: (dctx) => GlassAlert(
        backgroundColor: GB.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Ghi chú cho cữ hút', style: GB.display(20, w: FontWeight.w700)),
        content: GlassField(controller: c, label: 'Ghi chú', maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dctx), child: Text('Huỷ', style: GB.body(14, w: FontWeight.w700, color: GB.inkMuted))),
          TextButton(onPressed: () => Navigator.pop(dctx, c.text.trim()), child: Text('Lưu', style: GB.body(14, w: FontWeight.w800, color: GB.accentDeep))),
        ],
      ),
    );
    if (v != null) setState(() => note = v);
  }

  @override
  Widget build(BuildContext context) {
    final t = _target();
    final age = app.age;
    final total = l + r;
    final base = app.pumpBaseline();
    final a = PumpRef.assess(ml: total, ageDays: age.adjDays, baseline: base, perSessionGoal: t.perSession);
    final done = app.pumpSessionsOn(time) + 1;
    final range = PumpRef.perSession(age.adjDays);
    final recent = app.ofType(T.pump).take(3).toList();
    final started = startAt != null;

    return SubPage(
      title: 'Hút sữa',
      subtitle: 'Lưu lại hành trình nhỏ bé tạo nên yêu thương lớn lao',
      art: 'hero_pump',
      artWidth: 150,
      bottom: BigButton('Lưu · ${total}ml', icon: Icons.check_rounded, enabled: total > 0, onTap: _save),
      children: [
        _timerCard(done),
        const SizedBox(height: 12),
        TimeRow(label: started ? 'Bắt đầu' : 'Lúc', time: startAt ?? time, onChanged: (d) => setState(() {
              time = d;
              if (startAt != null) startAt = d;
            })),
        if (!started || !running)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: GlassCard(
              radius: 20,
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Expanded(child: Text(accTotal.inSeconds >= 60 ? 'Thời gian hút ${_clock(accTotal)}' : 'Hoặc nhập tay số phút', style: GB.body(13.5, w: FontWeight.w700))),
                if (accTotal.inSeconds < 60) ...[
                  RoundIconButton(icon: Icons.remove_rounded, label: 'Giảm 5 phút', size: 38, onTap: () => setState(() => manualMin = math.max(5, manualMin - 5))),
                  SizedBox(width: 70, child: Text('$manualMin phút', textAlign: TextAlign.center, style: GB.body(14.5, w: FontWeight.w800))),
                  RoundIconButton(icon: Icons.add_rounded, label: 'Tăng 5 phút', size: 38, filled: true, onTap: () => setState(() => manualMin = math.min(60, manualMin + 5))),
                ],
              ]),
            ),
          ),
        const SizedBox(height: 14),
        GlassCard(
          radius: 26,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.water_drop_rounded, color: GB.pumpDeep, size: 24),
              const SizedBox(width: 6),
              Expanded(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text('Lượng sữa sau cữ hút', style: GB.display(16.5, w: FontWeight.w800)))),
              Text('Tự động dừng', style: GB.body(11.5, color: GB.inkMuted)),
              const SizedBox(width: 2),
              Icon(Icons.info_outline_rounded, size: 14, color: GB.inkMuted),
              Transform.scale(scale: .8, child: Switch(value: autoStop, activeThumbColor: Colors.white, activeTrackColor: GB.pumpDeep, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, onChanged: (v) => setState(() => autoStop = v))),
            ]),
            const SizedBox(height: 10),
            IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Expanded(child: _amount('Trái', l, GB.pumpTile, GB.pumpDeep, (v) => setState(() => l = v))),
                const SizedBox(width: 8),
                Expanded(child: _amount('Phải', r, GB.bottleTile, GB.bottleDeep, (v) => setState(() => r = v))),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
                    decoration: BoxDecoration(color: GB.p(Color(0xFFFFF3D6)), borderRadius: BorderRadius.circular(18), border: Border.all(color: GB.edgeOf(GB.p(Color(0xFFFFF3D6))), width: 1)),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.water_drop_rounded, size: 18, color: Color(0xFFF2B632)),
                        const SizedBox(width: 3),
                        Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text('Tổng cộng', style: GB.body(12.5, w: FontWeight.w700)))),
                      ]),
                      const SizedBox(height: 8),
                      BigNumber('$total', 'ml', size: 26),
                    ]),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _editNote,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(color: GB.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: GB.line)),
                child: Row(children: [
                  Icon(Icons.edit_note_rounded, color: GB.inkMuted),
                  const SizedBox(width: 10),
                  Expanded(child: Text(note.isEmpty ? 'Thêm ghi chú cho cữ hút này...' : note, style: GB.body(13.5, color: note.isEmpty ? GB.inkMuted : GB.ink))),
                  Icon(Icons.chevron_right_rounded, color: GB.inkMuted),
                ]),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => showBottles = !showBottles),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Icon(showBottles ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: GB.accentDeep),
                  const SizedBox(width: 6),
                  Text(showBottles ? 'Ẩn hình bình sữa' : 'Kéo mực sữa trên hình bình', style: GB.body(13, w: FontWeight.w700, color: GB.accentDeep)),
                ]),
              ),
            ),
            if (showBottles)
              Row(children: [
                Expanded(child: _bottle('Trái', l, (v) => setState(() => l = v))),
                const SizedBox(width: 8),
                Expanded(child: _bottle('Phải', r, (v) => setState(() => r = v))),
              ]),
          ]),
        ),
        const SizedBox(height: 12),
        Center(child: Text('Thường gặp ${range.text()} mỗi cữ${base != null ? ' · mẹ thường hút ~${base.round()}ml' : ''}', textAlign: TextAlign.center, style: GB.body(12.5, color: GB.inkMuted))),
        const SizedBox(height: 12),
        PumpAssessmentCard(a),
        const SizedBox(height: 14),
        GlassCard(
          radius: 24,
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Mục tiêu tham khảo', style: GB.body(13, w: FontWeight.w700, color: GB.inkMuted)),
            const SizedBox(height: 4),
            Text('Bé cần khoảng ${t.dailyNeed.text()} sữa/ngày. Với mục tiêu lấy ${app.settings.pumpShare}% từ sữa hút, mẹ nên hút ~${t.dailyGoal.round()}ml/ngày, trung bình ~${t.perSession.round()}ml mỗi cữ.', style: GB.body(13.5, height: 1.45)),
            if (t.remainingSessions > 0 && app.pumpedOn(time) > 0) ...[
              const SizedBox(height: 6),
              Text('Còn ${t.remainingSessions} cữ: cần ~${t.perSessionRemaining.round()}ml mỗi cữ để chạm mục tiêu hôm nay.', style: GB.body(13, w: FontWeight.w700, color: GB.accentDeep)),
            ],
          ]),
        ),
        const SizedBox(height: 14),
        Text('Lưu vào tủ sữa', style: GB.body(14, w: FontWeight.w800)),
        const SizedBox(height: 8),
        Seg(labels: const ['Không', 'Ngăn mát', 'Ngăn đông'], index: const ['none', 'fridge', 'freezer'].indexOf(store), height: 40, onChanged: (i) => setState(() => store = const ['none', 'fridge', 'freezer'][i])),
        if (store != 'none') ...[
          const SizedBox(height: 10),
          GlassCard(
            radius: 20,
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Expanded(child: Text('Chia thành $bottles bình · ~${(total / bottles).round()}ml mỗi bình', style: GB.body(13.5, w: FontWeight.w600))),
              RoundIconButton(icon: Icons.remove_rounded, label: 'Bớt một bình', size: 40, onTap: () => setState(() => bottles = math.max(1, bottles - 1))),
              const SizedBox(width: 8),
              RoundIconButton(icon: Icons.add_rounded, label: 'Thêm một bình', size: 40, filled: true, onTap: () => setState(() => bottles = math.min(8, bottles + 1))),
            ]),
          ),
          const SizedBox(height: 6),
          Text('Hạn dùng tham khảo (CDC): ngăn mát tối đa 4 ngày, ngăn đông tốt nhất trong 6 tháng.', style: GB.body(11.5, color: GB.inkMuted)),
        ],
        const SizedBox(height: 14),
        SectionCard(
          title: 'Các cữ hút gần đây',
          icon: Icons.history_rounded,
          iconColor: GB.pumpDeep,
          trailing: 'Xem tất cả',
          onTrailing: () => openPage(context, const HistoryScreen()),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
          child: recent.isEmpty
              ? const EmptyState('Chưa có cữ hút nào.')
              : Column(children: [for (final e in recent) _recentRow(e)]),
        ),
        const SizedBox(height: 12),
        Text('Nguồn tham khảo: Kent 2006 (Pediatrics), tổng hợp của tư vấn viên sữa mẹ, CDC. Lượng hút không phản ánh toàn bộ lượng sữa mẹ. Không thay thế tư vấn bác sĩ.', style: GB.body(11.5, color: GB.inkMuted, height: 1.4)),
      ],
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

  Widget _amount(String name, int v, Color tile, Color deep, ValueChanged<int> on) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
      decoration: BoxDecoration(color: tile.withValues(alpha: .5), borderRadius: BorderRadius.circular(18), border: Border.all(color: GB.edgeOf(tile.withValues(alpha: .5)), width: 1)),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.water_drop_rounded, size: 18, color: deep),
          const SizedBox(width: 3),
          Text(name, style: GB.body(12.5, w: FontWeight.w700)),
        ]),
        const SizedBox(height: 8),
        BigNumber('$v', 'ml', size: 24),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _mini(Icons.remove_rounded, 'Giảm $name 10ml', deep, false, () => on(math.max(0, v - 10))),
          const SizedBox(width: 8),
          _mini(Icons.add_rounded, 'Tăng $name 10ml', deep, true, () => on(math.min(300, v + 10))),
        ]),
      ]),
    );
  }

  Widget _mini(IconData ic, String label, Color deep, bool filled, VoidCallback onTap) => Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: filled ? deep : GB.w(.7), shape: BoxShape.circle),
            child: Icon(ic, size: 18, color: filled ? Colors.white : deep),
          ),
        ),
      );

  Widget _bottle(String name, int v, ValueChanged<int> on) => Column(children: [
        Text(name, style: GB.body(13, w: FontWeight.w700, color: GB.inkMuted)),
        BottleView(ml: v, cap: 200, color: GB.milkBottle, width: 120, onChanged: on, label: 'Sữa bên $name'),
      ]);

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
