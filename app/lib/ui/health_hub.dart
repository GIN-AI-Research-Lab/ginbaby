import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/kit.dart';
import '../core/pickers.dart';
import '../core/theme.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import '../domain/milestones.dart';
import 'quick_logs.dart';
import 'widgets.dart';

/// Sức khoẻ của bé: nhiệt độ, thuốc, lịch hẹn khám, mốc phát triển, răng.
class HealthHub extends StatefulWidget {
  const HealthHub({super.key, this.initial = 0});
  final int initial;

  @override
  State<HealthHub> createState() => _HealthHubState();
}

class _HealthHubState extends State<HealthHub> {
  late int tab = widget.initial;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        return SubPage(
          title: 'Sức khoẻ của bé',
          subtitle: 'Bé ${app.age.short} · chăm bé từng ngày',
          art: 'hero_baby_awake',
          artWidth: 110,
          children: [
            SizedBox(
              height: 44,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                for (var i = 0; i < 5; i++) ...[PillChip(label: const ['Nhiệt độ', 'Thuốc', 'Lịch hẹn', 'Mốc phát triển', 'Răng'][i], on: tab == i, height: 44, onTap: () => setState(() => tab = i)), const SizedBox(width: 8)],
              ]),
            ),
            const SizedBox(height: 12),
            if (tab == 0) ..._temps(),
            if (tab == 1) ..._meds(),
            if (tab == 2) ..._appts(),
            if (tab == 3) ..._miles(),
            if (tab == 4) ..._teeth(),
          ],
        );
      },
    );
  }

  // ===== Nhiệt độ =====
  List<Widget> _temps() {
    final l = app.ofType(T.temp).take(30).toList();
    final chart = l.take(14).toList().reversed.toList();
    final last = l.firstOrNull;
    return [
      BigButton('Ghi nhiệt độ', icon: Icons.thermostat_rounded, onTap: () => showOtherLogSheet(context, initial: 0)),
      const SizedBox(height: 12),
      if (last != null && last.num('v') >= 38)
        Callout(level: Level.alert, title: 'Lần đo gần nhất ${GB.num1(last.num('v'))}°C', body: app.age.days < 90 ? 'Bé dưới 3 tháng sốt từ 38°C cần đi khám ngay.' : 'Theo dõi sát và liên hệ bác sĩ nếu sốt kéo dài hoặc bé mệt.'),
      if (chart.length >= 2) ...[
        const SizedBox(height: 12),
        GlassCard(
          radius: 24,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Các lần đo gần đây', style: GB.body(13.5, w: FontWeight.w800)),
            const SizedBox(height: 8),
            SizedBox(height: 120, child: CustomPaint(size: const Size(double.infinity, 120), painter: _TempPainter(chart.map((e) => e.num('v')).toList()))),
          ]),
        ),
      ],
      const SectionTitle('Lịch sử'),
      GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: l.isEmpty ? const EmptyState('Chưa có lần đo nào.') : Column(children: [for (final e in l) EntryRow(e)]),
      ),
      const SizedBox(height: 8),
      Text('Nhiệt độ thường gặp 36,5–37,5°C. Nguồn: AAP, NHS.', style: GB.body(11.5, color: GB.inkMuted)),
    ];
  }

  // ===== Thuốc =====
  List<Widget> _meds() {
    final l = app.ofType(T.med).take(60).toList();
    return [
      BigButton('Ghi thuốc đã cho bé', icon: Icons.medication_rounded, onTap: () => showOtherLogSheet(context, initial: 1)),
      const SectionTitle('Lịch sử'),
      GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: l.isEmpty ? const EmptyState('Chưa ghi thuốc nào.') : Column(children: [for (final e in l) EntryRow(e)]),
      ),
      const SizedBox(height: 8),
      Text('App chỉ ghi lại, không tư vấn liều thuốc. Hãy dùng thuốc theo chỉ định của bác sĩ.', style: GB.body(11.5, color: GB.inkMuted)),
    ];
  }

  // ===== Lịch hẹn =====
  List<Widget> _appts() {
    final now = DateTime.now();
    final up = app.appts.where((a) => !a.done && !a.time.isBefore(now.subtract(const Duration(hours: 2)))).toList();
    final past = app.appts.where((a) => a.done || a.time.isBefore(now.subtract(const Duration(hours: 2)))).toList().reversed.toList();
    Widget row(Appointment a) => InkWell(
          onTap: () => _apptSheet(a),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Row(children: [
              GestureDetector(
                onTap: () {
                  a.done = !a.done;
                  app.apptChanged();
                },
                child: Icon(a.done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: a.done ? GB.ok : GB.inkMuted),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.title, style: GB.body(14.5, w: FontWeight.w700)),
                  Text('${GB.dmyhm(a.time)}${a.place.isEmpty ? '' : ' · ${a.place}'}', style: GB.body(12, color: GB.inkMuted)),
                ]),
              ),
              Icon(Icons.chevron_right_rounded, color: GB.inkMuted),
            ]),
          ),
        );
    return [
      BigButton('Thêm lịch hẹn khám', icon: Icons.event_rounded, onTap: () => _apptSheet(null)),
      const SectionTitle('Sắp tới'),
      GlassCard(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4), child: up.isEmpty ? const EmptyState('Chưa có lịch hẹn sắp tới.') : Column(children: [for (final a in up) row(a)])),
      if (past.isNotEmpty) ...[
        const SectionTitle('Đã qua'),
        GlassCard(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4), child: Column(children: [for (final a in past.take(20)) row(a)])),
      ],
    ];
  }

  void _apptSheet(Appointment? edit) {
    showGlassSheet(context, builder: (ctx) {
      final title = TextEditingController(text: edit?.title ?? '');
      final place = TextEditingController(text: edit?.place ?? '');
      final note = TextEditingController(text: edit?.note ?? '');
      var time = edit?.time ?? DateTime.now().add(const Duration(days: 7));
      return StatefulBuilder(builder: (ctx, setS) {
        return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(edit == null ? 'Thêm lịch hẹn' : 'Sửa lịch hẹn', style: GB.display(22, w: FontWeight.w700)),
          const SizedBox(height: 12),
          GlassField(controller: title, label: 'Nội dung (khám nhi, tái khám, tiêm…)'),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () async {
              final d = await pickDateTime(ctx, time, last: DateTime.now().add(const Duration(days: 365 * 2)));
              if (d != null) setS(() => time = d);
            },
            child: GlassCard(radius: 18, padding: const EdgeInsets.all(14), blur: 12, child: Row(children: [const Icon(Icons.schedule_rounded), const SizedBox(width: 10), Expanded(child: Text('${GB.dmyhm(time)}', style: GB.body(14.5, w: FontWeight.w700))), Text('Sửa', style: GB.body(13, w: FontWeight.w700, color: GB.accentDeep))])),
          ),
          const SizedBox(height: 10),
          GlassField(controller: place, label: 'Nơi khám'),
          const SizedBox(height: 10),
          GlassField(controller: note, label: 'Ghi chú', maxLines: 2),
          const SizedBox(height: 14),
          BigButton('Lưu', icon: Icons.check_rounded, onTap: () {
            if (title.text.trim().isEmpty) {
              toast(context, 'Nhập nội dung lịch hẹn');
              return;
            }
            if (edit == null) {
              app.addAppt(Appointment(time: time, title: title.text.trim(), place: place.text.trim(), note: note.text.trim()));
            } else {
              edit
                ..time = time
                ..title = title.text.trim()
                ..place = place.text.trim()
                ..note = note.text.trim();
              app.appts.sort((a, b) => a.time.compareTo(b.time));
              app.apptChanged();
            }
            Navigator.pop(ctx);
          }),
          if (edit != null) ...[
            const SizedBox(height: 10),
            BigButton('Xoá lịch hẹn', icon: Icons.delete_outline_rounded, color: GB.alertBg, fg: GB.alert, onTap: () {
              app.removeAppt(edit.id);
              Navigator.pop(ctx);
            }),
          ],
        ]);
      });
    });
  }

  // ===== Mốc phát triển =====
  List<Widget> _miles() {
    final age = app.age.adjDays / 30.4375;
    final current = kMilestones.lastWhere((g) => age >= g.months - 1, orElse: () => kMilestones.first);
    return [
      Callout(level: Level.info, title: 'Mốc không phải bài kiểm tra', body: 'Mỗi bé phát triển theo tốc độ riêng. Nếu mẹ lo lắng hoặc bé mất kỹ năng đã có, hãy trao đổi với bác sĩ nhi.${app.age.preterm ? ' Với bé sinh non, app dùng tuổi hiệu chỉnh.' : ''}'),
      for (final g in kMilestones) ...[
        SectionTitle('${g.months} tháng${g == current ? ' · tuổi hiện tại' : ''}', trailing: '${g.items.asMap().keys.where((i) => app.milestones.containsKey('m${g.months}_$i')).length}/${g.items.length}', padTop: 16),
        GlassCard(
          radius: 22,
          tint: g == current ? GB.warnBg : null,
          opacity: g == current ? .75 : .5,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(children: [
            for (var i = 0; i < g.items.length; i++)
              InkWell(
                onTap: () => app.toggleMilestone('m${g.months}_$i'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Row(children: [
                    Icon(app.milestones.containsKey('m${g.months}_$i') ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: app.milestones.containsKey('m${g.months}_$i') ? GB.ok : GB.inkMuted),
                    const SizedBox(width: 12),
                    Expanded(child: Text(g.items[i], style: GB.body(14))),
                  ]),
                ),
              ),
          ]),
        ),
      ],
      const SizedBox(height: 10),
      Text(kMilestoneSource, style: GB.body(11.5, color: GB.inkMuted)),
    ];
  }

  // ===== Răng =====
  List<Widget> _teeth() {
    final months = app.age.days / 30.4375;
    final count = app.teeth.length * 2;
    Widget grid(bool upper) => Row(children: [
          for (final t in kTeeth.where((t) => t.upper == upper))
            Expanded(
              child: GestureDetector(
                onTap: () => _toothSheet(t),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  decoration: BoxDecoration(color: app.teeth.containsKey(t.id) ? GB.okBg : GB.w(.65), borderRadius: BorderRadius.circular(16), border: Border.all(color: months >= t.from && months <= t.to && !app.teeth.containsKey(t.id) ? GB.accent : GB.w(.8), width: 2)),
                  child: Column(children: [
                    Icon(Icons.tag_faces_rounded, size: 22, color: app.teeth.containsKey(t.id) ? GB.ok : GB.inkMuted),
                    const SizedBox(height: 4),
                    Text(t.name.split(' ').take(2).join('\n'), textAlign: TextAlign.center, style: GB.body(10, w: FontWeight.w700), maxLines: 2),
                    Text('${t.from}–${t.to}th', style: GB.body(9.5, color: GB.inkMuted)),
                  ]),
                ),
              ),
            ),
        ]);
    return [
      Callout(level: Level.info, title: 'Đã mọc khoảng $count/20 chiếc', body: 'Chạm vào từng loại răng để đánh dấu đã mọc (mỗi loại gồm 2 chiếc trái/phải). Ô viền cam là tuổi thường mọc của bé hiện tại.'),
      const SectionTitle('Hàm trên'),
      grid(true),
      const SectionTitle('Hàm dưới'),
      grid(false),
      const SizedBox(height: 10),
      Text(kTeethSource, style: GB.body(11.5, color: GB.inkMuted, height: 1.4)),
    ];
  }

  void _toothSheet(Tooth t) {
    final has = app.teeth[t.id];
    showGlassSheet(context, builder: (ctx) {
      var date = has ?? DateTime.now();
      return StatefulBuilder(builder: (ctx, setS) {
        return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.name, style: GB.display(22, w: FontWeight.w700)),
          Text('Thường mọc lúc ${t.from}–${t.to} tháng', style: GB.body(13, color: GB.inkMuted)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final d = await pickDateTime(ctx, date, timeToo: false, last: DateTime.now());
              if (d != null) setS(() => date = d);
            },
            child: GlassCard(radius: 18, padding: const EdgeInsets.all(14), blur: 12, child: Row(children: [const Icon(Icons.today_rounded), const SizedBox(width: 10), Expanded(child: Text('Ngày thấy mọc ${GB.dmy(date)}', style: GB.body(14.5, w: FontWeight.w700))), Text('Sửa', style: GB.body(13, w: FontWeight.w700, color: GB.accentDeep))])),
          ),
          const SizedBox(height: 14),
          BigButton(has == null ? 'Đánh dấu đã mọc' : 'Lưu ngày', icon: Icons.check_rounded, onTap: () {
            app.teeth[t.id] = date;
            app.changed('teeth');
            Navigator.pop(ctx);
          }),
          if (has != null) ...[
            const SizedBox(height: 10),
            BigButton('Bỏ đánh dấu', icon: Icons.undo_rounded, color: GB.alertBg, fg: GB.alert, onTap: () {
              app.toggleTooth(t.id);
              Navigator.pop(ctx);
            }),
          ],
        ]);
      });
    });
  }
}

class _TempPainter extends CustomPainter {
  _TempPainter(this.v);
  final List<double> v;

  @override
  void paint(Canvas canvas, Size size) {
    if (v.length < 2) return;
    const lo = 35.5, hi = 40.0;
    double y(double t) => size.height - 14 - ((t.clamp(lo, hi) - lo) / (hi - lo)) * (size.height - 20);
    final fever = Paint()
      ..color = GB.alertBg.withValues(alpha: .7);
    canvas.drawRect(Rect.fromLTRB(0, y(hi), size.width, y(38)), fever);
    canvas.drawRect(Rect.fromLTRB(0, y(37.5), size.width, y(36.5)), Paint()..color = GB.okBg.withValues(alpha: .7));
    final path = Path();
    for (var i = 0; i < v.length; i++) {
      final px = i / (v.length - 1) * (size.width - 12) + 6;
      if (i == 0) {
        path.moveTo(px, y(v[i]));
      } else {
        path.lineTo(px, y(v[i]));
      }
    }
    canvas.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = GB.accentDeep);
    for (var i = 0; i < v.length; i++) {
      final px = i / (v.length - 1) * (size.width - 12) + 6;
      canvas.drawCircle(Offset(px, y(v[i])), 4, Paint()..color = v[i] >= 38 ? GB.alert : GB.accentDeep);
    }
  }

  @override
  bool shouldRepaint(_TempPainter old) => true;
}

int unusedMath(int a) => math.max(a, 0);
