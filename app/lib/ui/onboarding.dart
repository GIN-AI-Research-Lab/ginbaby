import 'package:flutter/material.dart';

import '../core/kit.dart';
import '../core/pickers.dart';
import '../core/theme.dart';
import '../data/app_state.dart';
import '../data/demo.dart';
import '../data/models.dart';

/// Nhập hồ sơ bé lần đầu (và dùng để sửa hồ sơ trong Cài đặt).
class Onboarding extends StatefulWidget {
  const Onboarding({super.key, this.edit = false});
  final bool edit;

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  int step = 0;
  final name = TextEditingController();
  Sex sex = Sex.girl;
  DateTime dob = DateTime.now().subtract(const Duration(days: 1));
  bool preterm = false;
  int gest = 40;
  double birthW = 3.2;
  double curW = 3.2;
  bool curTouched = false;
  FeedMode mode = FeedMode.mixed;

  @override
  void initState() {
    super.initState();
    final b = app.baby;
    if (b != null) {
      name.text = b.name;
      sex = b.sex;
      dob = b.dob;
      gest = b.gestWeeks;
      preterm = gest < 37;
      birthW = b.birthWeightKg;
      curW = app.weightKg;
      curTouched = true;
      mode = b.mode;
    }
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  void _finish() {
    final b = Baby(name: name.text.trim().isEmpty ? 'Bé' : name.text.trim(), sex: sex, dob: dob, birthWeightKg: birthW, gestWeeks: preterm ? gest : 40, mode: mode);
    app.saveBaby(b);
    if (curTouched && (curW - birthW).abs() > .001 && app.measurements.isEmpty) {
      app.addMeasurement(Measurement(date: DateTime.now(), weightKg: curW));
    }
    if (widget.edit) Navigator.of(context).pop();
  }

  Widget _stepper(String label, double v, ValueChanged<double> on, {double min = 0.8, double max = 12}) {
    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GB.body(13, w: FontWeight.w700, color: GB.inkMuted)),
        Row(children: [
          RoundIconButton(icon: Icons.remove_rounded, label: 'Giảm 0,1kg', onTap: () => on(((v - 0.1).clamp(min, max) * 10).round() / 10)),
          Expanded(child: Center(child: Text('${GB.num1(v)} kg', style: GB.display(30)))),
          RoundIconButton(icon: Icons.add_rounded, label: 'Tăng 0,1kg', filled: true, onTap: () => on(((v + 0.1).clamp(min, max) * 10).round() / 10)),
        ]),
        Slider(value: v.clamp(min, max), min: min, max: max, activeColor: GB.accent, onChanged: (x) => on((x * 10).round() / 10)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = <Widget>[_s1(), _s2(), _s3()];
    final last = step == steps.length - 1;
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: GB.bg,
      body: GlassBackground(
        child: Column(children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20, top + 16, 20, 0),
            child: Row(children: [
              if (widget.edit || step > 0)
                RoundIconButton(icon: Icons.arrow_back_ios_new_rounded, label: 'Quay lại', size: 44, onTap: () => step > 0 ? setState(() => step--) : Navigator.of(context).pop())
              else
                const SizedBox(width: 44),
              const SizedBox(width: 14),
              Expanded(
                child: Row(children: [
                  for (var i = 0; i < steps.length; i++) ...[
                    Expanded(child: Container(height: 6, decoration: BoxDecoration(color: i <= step ? GB.accent : GB.w(.7), borderRadius: BorderRadius.circular(3)))),
                    if (i < steps.length - 1) const SizedBox(width: 6),
                  ]
                ]),
              ),
            ]),
          ),
          Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 20), children: [steps[step]])),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + MediaQuery.of(context).padding.bottom),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              BigButton(last ? (widget.edit ? 'Lưu hồ sơ' : 'Bắt đầu') : 'Tiếp tục', icon: last ? Icons.check_rounded : Icons.arrow_forward_rounded, onTap: () {
                if (!last) {
                  setState(() => step++);
                } else {
                  _finish();
                }
              }),
              if (!widget.edit && step == 0) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async => seedDemo(app),
                  child: Padding(padding: const EdgeInsets.all(10), child: Text('Xem thử với dữ liệu mẫu', style: GB.body(14, w: FontWeight.w700, color: GB.accentDeep))),
                ),
              ],
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _s1() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.edit ? 'Hồ sơ của bé' : 'Chào mẹ, mình làm quen với bé nhé', style: GB.display(30, color: GB.title)),
        const SizedBox(height: 6),
        Text('Thông tin này giúp app đánh giá lượng sữa, giấc ngủ và lịch tiêm đúng theo tuổi của bé. Dữ liệu chỉ lưu trên máy của mẹ.', style: GB.body(14, color: GB.inkMuted, height: 1.45)),
        const SizedBox(height: 20),
        GlassField(controller: name, label: 'Tên bé hoặc biệt danh'),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: PillChip(label: 'Bé gái', on: sex == Sex.girl, height: 48, onTap: () => setState(() => sex = Sex.girl))),
          const SizedBox(width: 10),
          Expanded(child: PillChip(label: 'Bé trai', on: sex == Sex.boy, height: 48, onTap: () => setState(() => sex = Sex.boy))),
        ]),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () async {
            final d = await pickDateTime(context, dob, first: DateTime.now().subtract(const Duration(days: 365 * 3)), last: DateTime.now());
            if (d != null) setState(() => dob = d);
          },
          child: GlassCard(
            radius: 22,
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Icon(Icons.cake_rounded, color: GB.accentDeep),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Ngày giờ sinh', style: GB.body(12.5, w: FontWeight.w600, color: GB.inkMuted)),
                  Text(GB.dmyhm(dob), style: GB.body(17, w: FontWeight.w800)),
                ]),
              ),
              Text('Sửa', style: GB.body(13, w: FontWeight.w700, color: GB.accentDeep)),
            ]),
          ),
        ),
      ]);

  Widget _s2() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Cân nặng và tuổi thai', style: GB.display(30, color: GB.title)),
        const SizedBox(height: 6),
        Text('Cân nặng giúp tính lượng sữa phù hợp (ml/kg/ngày). Mẹ có thể cập nhật sau mỗi lần cân.', style: GB.body(14, color: GB.inkMuted, height: 1.45)),
        const SizedBox(height: 16),
        _stepper('Cân nặng lúc sinh', birthW, (v) => setState(() {
              birthW = v;
              if (!curTouched) curW = v;
            })),
        const SizedBox(height: 12),
        _stepper('Cân nặng hiện tại', curW, (v) => setState(() {
              curW = v;
              curTouched = true;
            })),
        const SizedBox(height: 12),
        GlassCard(
          radius: 22,
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text('Bé sinh non (dưới 37 tuần)', style: GB.body(14.5, w: FontWeight.w700))),
              Switch(value: preterm, activeThumbColor: GB.accent, onChanged: (v) => setState(() {
                    preterm = v;
                    if (v && gest >= 37) gest = 34;
                  })),
            ]),
            if (preterm) ...[
              Text('Sinh lúc $gest tuần', style: GB.body(13.5, w: FontWeight.w700)),
              Slider(value: gest.toDouble(), min: 24, max: 36, divisions: 12, activeColor: GB.accent, onChanged: (v) => setState(() => gest = v.round())),
              Text('App sẽ dùng tuổi hiệu chỉnh khi đánh giá lượng sữa và mốc phát triển (đến 24 tháng).', style: GB.body(12, color: GB.inkMuted, height: 1.4)),
            ],
          ]),
        ),
      ]);

  Widget _s3() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Bé đang ăn sữa thế nào?', style: GB.display(30, color: GB.title)),
        const SizedBox(height: 6),
        Text('Chọn cách ăn chính hiện tại để app đánh giá phù hợp. Mẹ đổi lại được bất cứ lúc nào.', style: GB.body(14, color: GB.inkMuted, height: 1.45)),
        const SizedBox(height: 16),
        for (final m in const [
          (FeedMode.breast, 'Chủ yếu bú mẹ trực tiếp', 'Theo dõi số cữ, thời gian bú, tã ướt. Lượng sữa là ước tính.'),
          (FeedMode.formula, 'Chủ yếu sữa công thức', 'Đánh giá theo ml mỗi cữ và ml/kg/ngày.'),
          (FeedMode.mixed, 'Kết hợp (bú mẹ + bình + hút sữa)', 'Đánh giá phần bình, cộng thêm bú mẹ ước tính.'),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              radius: 22,
              tint: mode == m.$1 ? GB.warnBg : null,
              opacity: mode == m.$1 ? .85 : .5,
              onTap: () => setState(() => mode = m.$1),
              child: Row(children: [
                Icon(mode == m.$1 ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: mode == m.$1 ? GB.accentDeep : GB.inkMuted),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(m.$2, style: GB.body(15, w: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(m.$3, style: GB.body(12.5, color: GB.inkMuted, height: 1.35)),
                  ]),
                ),
              ]),
            ),
          ),
      ]);
}
