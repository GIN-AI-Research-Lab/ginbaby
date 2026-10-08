import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/kit.dart';
import '../core/pastel.dart';
import '../core/pickers.dart';
import '../core/theme.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import '../domain/who_growth.dart';

/// Biểu đồ tăng trưởng WHO (0–24 tháng) cho cân nặng, chiều dài, vòng đầu.
class GrowthScreen extends StatefulWidget {
  const GrowthScreen({super.key});

  @override
  State<GrowthScreen> createState() => _GrowthScreenState();
}

class _GrowthScreenState extends State<GrowthScreen> {
  GrowthKind kind = GrowthKind.weight;

  double _months(DateTime d) => math.max(0, d.difference(app.baby!.dob).inHours / 24 / 30.4375);

  double? _val(Measurement m) => switch (kind) { GrowthKind.weight => m.weightKg, GrowthKind.length => m.heightCm, GrowthKind.head => m.headCm };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final baby = app.baby!;
        final pts = app.measurements.where((m) => _val(m) != null).toList()..sort((a, b) => a.date.compareTo(b.date));
        final ageM = app.age.days / 30.4375;
        final tooOld = ageM > 24;
        final last = pts.isEmpty ? null : pts.last;
        double? z;
        if (last != null && !tooOld) z = Growth.zScore(kind, baby.sex, _months(last.date), _val(last)!);

        return SubPage(
          title: 'Tăng trưởng',
          subtitle: 'Chuẩn WHO 2006 · ${baby.sex == Sex.girl ? 'bé gái' : 'bé trai'}',
          art: 'hero_baby_awake',
          artWidth: 110,
          bottom: BigButton('Thêm lần đo', icon: Icons.add_rounded, onTap: _addSheet),
          children: [
            Seg(labels: [for (final k in GrowthKind.values) Growth.name(k)], index: kind.index, onChanged: (i) => setState(() => kind = GrowthKind.values[i])),
            const SizedBox(height: 12),
            if (tooOld)
              const Callout(level: Level.info, title: 'Bé trên 24 tháng', body: 'Biểu đồ trong app hiện hỗ trợ 0–24 tháng. Với bé lớn hơn, hãy dùng chuẩn WHO 2–5 tuổi tại cơ sở y tế.')
            else
              SectionCard(
                title: '${Growth.name(kind)} (${Growth.unit(kind)})',
                icon: kind == GrowthKind.weight ? Icons.monitor_weight_rounded : (kind == GrowthKind.length ? Icons.height_rounded : Icons.face_rounded),
                iconColor: GB.pumpDeep,
                trailingWidget: Text('P3 · P15 · P50 · P85 · P97', style: GB.body(10.5, color: GB.inkMuted)),
                padding: const EdgeInsets.fromLTRB(8, 14, 12, 10),
                child: SizedBox(height: 250, child: CustomPaint(size: const Size(double.infinity, 250), painter: _GrowthPainter(kind, baby.sex, [for (final m in pts) (_months(m.date), _val(m)!)], ageM))),
              ),
            const SizedBox(height: 12),
            if (last != null && z != null) ...[
              Builder(builder: (context) {
                final v = Growth.verdict(z!);
                return Callout(
                  level: v.$2 ? Level.note : Level.ok,
                  title: '${Growth.name(kind)} ${GB.num1(_val(last)!)}${Growth.unit(kind)} · phân vị ${Growth.percentile(z).round()}',
                  body: '${v.$1} (z = ${GB.num2(z)})',
                );
              }),
            ] else if (last == null)
              Callout(level: Level.info, title: 'Chưa có số đo ${Growth.name(kind).toLowerCase()}', body: 'Bấm "Thêm lần đo" để ghi và so với chuẩn WHO.'),
            const SectionTitle('Các lần đo'),
            if (app.measurements.isEmpty)
              const GlassCard(child: EmptyState('Chưa có lần đo nào.'))
            else
              GlassCard(
                radius: 22,
                padding: EdgeInsets.zero,
                child: Column(children: [
                  for (var i = 0; i < app.measurements.length; i++)
                    InkWell(
                      onTap: () => _addSheet(edit: app.measurements[i]),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(border: i == 0 ? null : Border(top: BorderSide(color: GB.f(Color(0xFF785A46)).withValues(alpha: .10)))),
                        child: Row(children: [
                          SizedBox(width: 86, child: Text(GB.dmy(app.measurements[i].date), style: GB.body(12.5, color: GB.inkMuted))),
                          Expanded(
                            child: Wrap(spacing: 14, children: [
                              if (app.measurements[i].weightKg != null) Text('${GB.num2(app.measurements[i].weightKg!)} kg', style: GB.body(14, w: FontWeight.w800)),
                              if (app.measurements[i].heightCm != null) Text('${GB.num1(app.measurements[i].heightCm!)} cm', style: GB.body(14, w: FontWeight.w700)),
                              if (app.measurements[i].headCm != null) Text('Đầu ${GB.num1(app.measurements[i].headCm!)} cm', style: GB.body(14, w: FontWeight.w700)),
                            ]),
                          ),
                          Icon(Icons.chevron_right_rounded, color: GB.inkMuted),
                        ]),
                      ),
                    ),
                ]),
              ),
            const SizedBox(height: 10),
            Text('Nguồn: WHO Child Growth Standards 2006 (tham số LMS). Số đo chỉ tham khảo; bé sinh non cần dùng biểu đồ hiệu chỉnh. Hãy trao đổi với bác sĩ nhi khi có lo lắng.', style: GB.body(11.5, color: GB.inkMuted, height: 1.4)),
          ],
        );
      },
    );
  }

  void _addSheet({Measurement? edit}) {
    showGlassSheet(context, builder: (ctx) {
      var date = edit?.date ?? DateTime.now();
      final w = TextEditingController(text: edit?.weightKg == null ? '' : GB.num2(edit!.weightKg!).replaceAll(',', '.'));
      final h = TextEditingController(text: edit?.heightCm == null ? '' : GB.num1(edit!.heightCm!).replaceAll(',', '.'));
      final c = TextEditingController(text: edit?.headCm == null ? '' : GB.num1(edit!.headCm!).replaceAll(',', '.'));
      double? p(TextEditingController t) => double.tryParse(t.text.trim().replaceAll(',', '.'));
      return StatefulBuilder(builder: (ctx, setS) {
        return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(edit == null ? 'Thêm lần đo' : 'Sửa lần đo', style: GB.display(22, w: FontWeight.w700)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final d = await pickDateTime(ctx, date, timeToo: false, last: DateTime.now());
              if (d != null) setS(() => date = d);
            },
            child: GlassCard(radius: 18, padding: const EdgeInsets.all(14), blur: 12, child: Row(children: [const Icon(Icons.today_rounded), const SizedBox(width: 10), Expanded(child: Text('Ngày đo ${GB.dmy(date)}', style: GB.body(14.5, w: FontWeight.w700))), Text('Sửa', style: GB.body(13, w: FontWeight.w700, color: GB.accentDeep))])),
          ),
          const SizedBox(height: 10),
          GlassField(controller: w, label: 'Cân nặng', suffix: 'kg', keyboard: const TextInputType.numberWithOptions(decimal: true)),
          const SizedBox(height: 10),
          GlassField(controller: h, label: 'Chiều dài / chiều cao', suffix: 'cm', keyboard: const TextInputType.numberWithOptions(decimal: true)),
          const SizedBox(height: 10),
          GlassField(controller: c, label: 'Vòng đầu', suffix: 'cm', keyboard: const TextInputType.numberWithOptions(decimal: true)),
          const SizedBox(height: 6),
          Text('Chỉ cần nhập số đo mẹ có.', style: GB.body(12, color: GB.inkMuted)),
          const SizedBox(height: 14),
          BigButton('Lưu', icon: Icons.check_rounded, onTap: () {
            final wv = p(w), hv = p(h), cv = p(c);
            if (wv == null && hv == null && cv == null) {
              toast(context, 'Nhập ít nhất một số đo');
              return;
            }
            if (edit == null) {
              app.addMeasurement(Measurement(date: date, weightKg: wv, heightCm: hv, headCm: cv));
            } else {
              edit
                ..date = date
                ..weightKg = wv
                ..heightCm = hv
                ..headCm = cv;
              app.measurements.sort((a, b) => b.date.compareTo(a.date));
              app.changed('meas');
            }
            Navigator.pop(ctx);
          }),
          if (edit != null) ...[
            const SizedBox(height: 10),
            BigButton('Xoá lần đo', icon: Icons.delete_outline_rounded, color: GB.alertBg, fg: GB.alert, onTap: () {
              app.removeMeasurement(edit.id);
              Navigator.pop(ctx);
            }),
          ],
        ]);
      });
    });
  }
}

class _GrowthPainter extends CustomPainter {
  _GrowthPainter(this.kind, this.sex, this.pts, this.ageM);
  final GrowthKind kind;
  final Sex sex;
  final List<(double, double)> pts;
  final double ageM;

  @override
  void paint(Canvas canvas, Size size) {
    const l = 38.0, b = 24.0, t = 6.0, r = 6.0;
    final w = size.width - l - r, h = size.height - b - t;
    final zs = [Growth.zP3, Growth.zP15, 0.0, Growth.zP85, Growth.zP97];
    final lo = Growth.valueAtZ(kind, sex, 0, -3);
    final hi = Growth.valueAtZ(kind, sex, 24, 3);
    double x(double m) => l + m / 24 * w;
    double y(double v) => t + h - (v - lo) / (hi - lo) * h;

    final grid = Paint()
      ..color = GB.inkMuted.withValues(alpha: .15)
      ..strokeWidth = 1;
    for (var m = 0; m <= 24; m += 3) {
      canvas.drawLine(Offset(x(m.toDouble()), t), Offset(x(m.toDouble()), t + h), grid);
      final tp = TextPainter(text: TextSpan(text: '$m', style: GB.body(10, color: GB.inkMuted)), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(x(m.toDouble()) - tp.width / 2, t + h + 5));
    }
    final steps = 5;
    for (var i = 0; i <= steps; i++) {
      final v = lo + (hi - lo) * i / steps;
      canvas.drawLine(Offset(l, y(v)), Offset(l + w, y(v)), grid);
      final tp = TextPainter(text: TextSpan(text: v.toStringAsFixed(kind == GrowthKind.weight ? 0 : 0), style: GB.body(10, color: GB.inkMuted)), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(l - tp.width - 4, y(v) - tp.height / 2));
    }

    // vùng P3–P97 và P15–P85
    Path band(double za, double zb) {
      final p = Path();
      for (var m = 0.0; m <= 24; m += .5) {
        final px = x(m), py = y(Growth.valueAtZ(kind, sex, m, zb));
        if (m == 0) {
          p.moveTo(px, py);
        } else {
          p.lineTo(px, py);
        }
      }
      for (var m = 24.0; m >= 0; m -= .5) {
        p.lineTo(x(m), y(Growth.valueAtZ(kind, sex, m, za)));
      }
      return p..close();
    }

    canvas.drawPath(band(Growth.zP3, Growth.zP97), Paint()..color = GB.pumpTile.withValues(alpha: .7));
    canvas.drawPath(band(Growth.zP15, Growth.zP85), Paint()..color = GB.p(Color(0xFFF6C4C8)).withValues(alpha: .55));

    for (final z in zs) {
      final path = Path();
      for (var m = 0.0; m <= 24; m += .5) {
        final px = x(m), py = y(Growth.valueAtZ(kind, sex, m, z));
        if (m == 0) {
          path.moveTo(px, py);
        } else {
          path.lineTo(px, py);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = z == 0 ? 2 : 1.2
          ..color = z == 0 ? GB.bottleDeep : GB.bottleDeep.withValues(alpha: .5),
      );
    }

    if (ageM <= 24) {
      canvas.drawLine(Offset(x(ageM), t), Offset(x(ageM), t + h), Paint()
        ..color = GB.ink.withValues(alpha: .25)
        ..strokeWidth = 1.2);
    }
    if (pts.isNotEmpty) {
      final line = Path();
      for (var i = 0; i < pts.length; i++) {
        final px = x(pts[i].$1.clamp(0.0, 24.0)), py = y(pts[i].$2);
        if (i == 0) {
          line.moveTo(px, py);
        } else {
          line.lineTo(px, py);
        }
      }
      canvas.drawPath(
        line,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = GB.accentDeep,
      );
      for (final p in pts) {
        final c = Offset(x(p.$1.clamp(0.0, 24.0)), y(p.$2));
        canvas.drawCircle(c, 6, Paint()..color = Colors.white);
        canvas.drawCircle(c, 4.5, Paint()..color = GB.accentDeep);
      }
    }
    final tp = TextPainter(text: TextSpan(text: 'tháng tuổi', style: GB.body(10, color: GB.inkMuted)), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(l + w - tp.width, t + h + 12));
  }

  @override
  bool shouldRepaint(_GrowthPainter old) => true;
}
