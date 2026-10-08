import 'package:flutter/material.dart';

import '../core/kit.dart';
import '../core/pastel.dart';
import '../core/theme.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import 'history.dart';
import 'quick_logs.dart';
import 'widgets.dart';

/// Màu, kết cấu và lượng phân kèm tranh minh hoạ (assets/art).
final kPoopColors = <(String label, String art, Color dot)>[
  ('Vàng', 'poop_yellow', Color(0xFFE3B93C)),
  ('Vàng nâu', 'poop_mustard', Color(0xFFC9972B)),
  ('Xanh rêu', 'poop_green', Color(0xFF6E8F3A)),
  ('Nâu', 'poop_brown', GB.f(Color(0xFF8A5A3C))),
  ('Đen', 'poop_black', GB.f(Color(0xFF2B2623))),
  ('Có nhầy', 'poop_mucus', GB.p(Color(0xFFE8E4C8))),
  ('Bạc', 'poop_silver', GB.p(Color(0xFFD9D9D9))),
  ('Máu', 'poop_blood', GB.f(Color(0xFFA3262A))),
];
const kPoopTextures = <(String label, String art)>[
  ('Lỏng', 'tex_liquid'),
  ('Sệt', 'tex_soft'),
  ('Sệt hạt', 'tex_chunky'),
  ('Đặc', 'tex_hard'),
  ('Có bọt', 'tex_foam'),
];
const kDiaperAmounts = <(String label, String art)>[
  ('Ít', 'diaper_few'),
  ('Vừa', 'diaper_mid'),
  ('Nhiều', 'diaper_lots'),
];

String? poopArt(String color) {
  final c = color == 'Xanh' ? 'Xanh rêu' : color;
  for (final k in kPoopColors) {
    if (k.$1 == c) return k.$2;
  }
  return null;
}

String? textureArt(String t) {
  for (final k in kPoopTextures) {
    if (k.$1 == t) return k.$2;
  }
  return null;
}

String? amountArt(String t) {
  for (final k in kDiaperAmounts) {
    if (k.$1 == t) return k.$2;
  }
  return null;
}

/// Đánh giá nhẹ nhàng đặc điểm phân (tham khảo, không thay bác sĩ).
class DiaperVerdict {
  const DiaperVerdict(this.level, this.title, this.body, this.pill);
  final Level level;
  final String title;
  final String body;
  final String pill;
}

DiaperVerdict diaperVerdict({required String kind, String color = '', String state = '', String amount = '', required int ageDays}) {
  if (kind == 'wet') {
    return const DiaperVerdict(Level.ok, 'Bình thường', 'Tã ướt cho thấy bé đang đủ nước.', 'Bình thường');
  }
  final blackOk = color == 'Đen' && ageDays < 4; // phân su
  if (color == 'Bạc') return const DiaperVerdict(Level.alert, 'Nên đưa bé đi khám sớm', 'Phân trắng hoặc bạc có thể là dấu hiệu bệnh gan mật, cần khám sớm.', 'Nên đi khám');
  if (color == 'Máu') return const DiaperVerdict(Level.alert, 'Nên đưa bé đi khám sớm', 'Phân có máu cần được bác sĩ kiểm tra.', 'Nên đi khám');
  if (color == 'Đen' && !blackOk) return const DiaperVerdict(Level.alert, 'Nên đưa bé đi khám sớm', 'Phân đen sau những ngày đầu cần được bác sĩ kiểm tra.', 'Nên đi khám');
  if (blackOk) return const DiaperVerdict(Level.info, 'Phân su', 'Vài ngày đầu bé thường đi phân đen/xanh đen (phân su), đây là bình thường.', 'Bình thường');
  if (state == 'Lỏng' && amount == 'Nhiều') return const DiaperVerdict(Level.note, 'Cần theo dõi', 'Phân lỏng và nhiều. Cho bé bú đủ và theo dõi số tã ướt. Hãy liên hệ bác sĩ nếu kéo dài hoặc bé mệt.', 'Cần theo dõi');
  if (state == 'Đặc' && amount == 'Ít') return const DiaperVerdict(Level.note, 'Cần theo dõi', 'Phân đặc và ít, có thể bé hơi táo. Theo dõi thêm vài ngày và hỏi bác sĩ nếu bé khó chịu.', 'Cần theo dõi');
  if (color == 'Xanh rêu' || color == 'Xanh') return const DiaperVerdict(Level.note, 'Cần theo dõi', 'Phân xanh thường gặp. Nếu kéo dài kèm quấy khóc hoặc bé bú kém, hãy hỏi bác sĩ.', 'Cần theo dõi');
  if (color == 'Có nhầy') return const DiaperVerdict(Level.note, 'Cần theo dõi', 'Phân có nhầy đôi khi gặp khi bé mọc răng hoặc cảm nhẹ. Theo dõi nếu nhiều hoặc kéo dài.', 'Cần theo dõi');
  return const DiaperVerdict(Level.ok, 'Bình thường', 'Đặc điểm phân của bé đang trong mức thường gặp.', 'Bình thường');
}

class DiaperScreen extends StatefulWidget {
  const DiaperScreen({super.key});

  @override
  State<DiaperScreen> createState() => _DiaperScreenState();
}

class _DiaperScreenState extends State<DiaperScreen> {
  bool wetToo = true; // tã vừa có phân vừa ướt (mặc định)
  String get kind => wetToo ? 'both' : 'poop';
  String color = 'Vàng';
  String state = 'Sệt';
  String amount = 'Vừa';
  DateTime time = DateTime.now();
  String? photo;
  bool more = false;
  final note = TextEditingController();

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  Widget _head(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Row(children: [
          Icon(icon, size: 20, color: GB.pumpDeep),
          const SizedBox(width: 8),
          Text(text, style: GB.display(15, w: FontWeight.w800)),
        ]),
      );

  /// Một hàng các lựa chọn có tranh, chia đều chiều ngang.
  Widget _row(List<(String, String?)> items, String value, ValueChanged<String> pick, {double height = 66, double artH = 34}) {
    return Row(children: [
      for (var i = 0; i < items.length; i++) ...[
        if (i > 0) SizedBox(width: items.length > 4 ? 4 : 8),
        Expanded(child: _OptionTile(label: items[i].$1, art: items[i].$2, selected: items[i].$1 == value, height: height, artH: artH, onTap: () => setState(() => pick(items[i].$1)))),
      ],
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final age = app.age.days;
    final v = diaperVerdict(kind: kind, color: color, state: state, amount: amount, ageDays: age);
    final recent = app.ofType(T.diaper).take(3).toList();
    final bad = v.level == Level.alert;
    final Color vBg = v.level == Level.ok ? GB.p(Color(0xFFEAF3E4)) : (bad ? GB.alertBg : (v.level == Level.info ? GB.infoBg : GB.warnBg));
    final Color vFg = v.level == Level.ok ? GB.ok : (bad ? GB.alert : (v.level == Level.info ? GB.info : GB.warn));
    final main = [for (final k in kPoopColors.take(6)) (k.$1, k.$2)];
    final warn = [for (final k in kPoopColors.skip(6)) (k.$1, k.$2)];

    return SubPage(
      title: 'Phân của bé',
      subtitle: 'Theo dõi đặc điểm phân giúp ba mẹ hiểu rõ hệ tiêu hoá của con hơn',
      art: 'hero_diaper',
      artWidth: 150,
      titleArt: 'poop_brown',
      children: [
        GlassCard(
          radius: 24,
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.edit_note_rounded, color: GB.pumpDeep, size: 24),
              const SizedBox(width: 8),
              Expanded(child: Text('Ghi nhận phân mới', style: GB.display(17, w: FontWeight.w800))),
            ]),
            ...[
              _head(Icons.palette_outlined, '1. Màu sắc'),
              _row(main, color, (x) => color = x, height: 70, artH: 34),
              const SizedBox(height: 6),
              Row(children: [
                SizedBox(width: 44, child: _OptionTile(label: warn[0].$1, art: warn[0].$2, selected: color == warn[0].$1, height: 58, artH: 28, onTap: () => setState(() => color = warn[0].$1))),
                const SizedBox(width: 4),
                SizedBox(width: 44, child: _OptionTile(label: warn[1].$1, art: warn[1].$2, selected: color == warn[1].$1, height: 58, artH: 28, onTap: () => setState(() => color = warn[1].$1))),
                const SizedBox(width: 10),
                Expanded(child: Text('Phân bạc hoặc có máu: nên đưa bé đi khám sớm', style: GB.body(11, color: GB.alert, height: 1.3))),
              ]),
              _head(Icons.waves_rounded, '2. Kết cấu'),
              _row([for (final k in kPoopTextures) (k.$1, k.$2)], state, (x) => state = x, height: 60, artH: 22),
            ],
            _head(Icons.baby_changing_station_rounded, '3. Số lượng'),
            _row([for (final k in kDiaperAmounts) (k.$1, k.$2)], amount, (x) => amount = x, height: 66, artH: 34),
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.water_drop_rounded, size: 20, color: GB.health),
              const SizedBox(width: 8),
              Expanded(child: Text('Tã cũng ướt', style: GB.body(13.5, w: FontWeight.w700))),
              Switch(value: wetToo, activeThumbColor: Colors.white, activeTrackColor: GB.pumpDeep, onChanged: (x) => setState(() => wetToo = x)),
            ]),
            const SizedBox(height: 4),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => showGlassSheet(context, builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(v.title, style: GB.display(20, w: FontWeight.w800, color: vFg)),
                    const SizedBox(height: 8),
                    Text(v.body, style: GB.body(14, height: 1.5)),
                    const SizedBox(height: 14),
                    BigButton('Đã hiểu', onTap: () => Navigator.pop(ctx)),
                  ])),
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
                decoration: BoxDecoration(color: vBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: GB.edgeOf(vBg), width: 1)),
                child: Row(children: [
                  Icon(bad ? Icons.warning_amber_rounded : (v.level == Level.ok ? Icons.sentiment_satisfied_alt_rounded : Icons.sentiment_neutral_rounded), size: 38, color: vFg),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(v.title, style: GB.body(15, w: FontWeight.w800, color: vFg)),
                      const SizedBox(height: 1),
                      Text(v.level == Level.ok ? 'Đặc điểm phân của bé đang trong mức bình thường' : 'Chạm để xem gợi ý', style: GB.body(11.5, color: vFg.withValues(alpha: .85), height: 1.3)),
                    ]),
                  ),
                  Icon(Icons.chevron_right_rounded, color: vFg),
                ]),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => more = !more),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                decoration: BoxDecoration(color: GB.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: GB.line)),
                child: Row(children: [
                  Icon(Icons.schedule_rounded, size: 20, color: GB.inkMuted),
                  const SizedBox(width: 8),
                  Expanded(child: Text('${GB.dmyhm(time)} · thêm ảnh, ghi chú', style: GB.body(12.5, color: GB.inkMuted))),
                  Icon(more ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: GB.inkMuted),
                ]),
              ),
            ),
            if (more) ...[
              const SizedBox(height: 10),
              TimeRow(time: time, onChanged: (d) => setState(() => time = d)),
              const SizedBox(height: 10),
              Row(children: [
                Text('Ảnh', style: GB.body(14, w: FontWeight.w700)),
                const SizedBox(width: 12),
                if (photo != null) PhotoThumb(photo!, onRemove: () => setState(() => photo = null)) else AddPhotoButton(onTap: () async {
                      final id = await pickAndStorePhoto(context);
                      if (id != null) setState(() => photo = id);
                    }),
                const SizedBox(width: 12),
                Expanded(child: Text('Ảnh chỉ lưu trên máy', style: TextStyle(fontSize: 12, color: GB.inkMuted))),
              ]),
              const SizedBox(height: 10),
              GlassField(controller: note, label: 'Ghi chú (tuỳ chọn)'),
            ],
            const SizedBox(height: 12),
            BigButton('Lưu cữ thay tã', icon: Icons.save_alt_rounded, onTap: _save),
            const SizedBox(height: 4),
            Center(
              child: TextButton(
                onPressed: _saveWetOnly,
                child: Text('Chỉ có tã ướt, không có phân', style: GB.body(13, w: FontWeight.w700, color: GB.accentDeep)),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Nhật ký gần đây',
          icon: Icons.history_rounded,
          iconColor: GB.pumpDeep,
          trailing: 'Xem tất cả',
          onTrailing: () => openPage(context, const HistoryScreen()),
          padding: const EdgeInsets.fromLTRB(12, 14, 8, 6),
          child: recent.isEmpty ? const EmptyState('Chưa có lần thay tã nào.') : Column(children: [for (final e in recent) _recentRow(e, age)]),
        ),
        const SizedBox(height: 12),
        Text('Đặc điểm phân chỉ mang tính tham khảo, không thay thế bác sĩ. Khi thấy phân trắng, bạc, có máu hoặc bé có dấu hiệu bất thường, hãy đưa bé đi khám.', style: GB.body(11, color: GB.inkMuted, height: 1.4)),
      ],
    );
  }

  Widget _recentRow(Entry e, int age) {
    final k = e.str('kind');
    final col = e.str('color');
    final st = e.str('state');
    final am = e.str('amount');
    final vv = diaperVerdict(kind: k, color: col, state: st, amount: am, ageDays: age);
    Widget item(String? art, String text, {int flex = 1}) => Expanded(
          flex: flex,
          child: Row(children: [
            if (art != null) SizedBox(width: 26, height: 24, child: Art(art)),
            const SizedBox(width: 2),
            Flexible(child: Text(text, style: GB.body(10.5, color: GB.inkMuted, height: 1.1))),
          ]),
        );
    final ok = vv.level == Level.ok;
    final pillColor = ok ? GB.okBg : (vv.level == Level.alert ? GB.alertBg : GB.warnBg);
    final pillFg = ok ? GB.ok : (vv.level == Level.alert ? GB.alert : GB.warn);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showEntrySheet(context, e),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          SizedBox(
            width: 52,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(GB.dayLabel(e.time), style: GB.body(11.5, w: FontWeight.w800)),
              Text(GB.hm(e.time), style: GB.body(11, color: GB.inkMuted)),
            ]),
          ),
          if (k == 'wet')
            item('diaper_mid', am.isEmpty ? 'Tã ướt' : 'Tã ướt · $am', flex: 4)
          else ...[
            item(poopArt(col), col, flex: 2),
            item(textureArt(st), st, flex: 2),
            item(amountArt(am), am, flex: 2),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            decoration: BoxDecoration(color: pillColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: GB.edgeOf(pillColor), width: 1)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(ok ? Icons.sentiment_satisfied_alt_rounded : Icons.sentiment_neutral_rounded, size: 14, color: pillFg),
              const SizedBox(width: 2),
              Text(ok ? 'Ổn' : (vv.level == Level.alert ? 'Khám' : 'Theo dõi'), style: GB.body(10.5, w: FontWeight.w800, color: pillFg)),
            ]),
          ),
          Icon(Icons.chevron_right_rounded, size: 18, color: GB.inkMuted),
        ]),
      ),
    );
  }

  void _saveWetOnly() {
    final saved = Entry(type: T.diaper, time: time, data: {
      'kind': 'wet',
      'amount': amount,
      if (photo != null) 'photo': photo,
      if (note.text.trim().isNotEmpty) 'note': note.text.trim(),
    });
    app.addEntry(saved);
    toast(context, 'Đã ghi tã ướt', undo: () => app.removeEntry(saved.id));
    Navigator.of(context).pop();
  }

  void _save() {
    final saved = Entry(type: T.diaper, time: time, data: {
      'kind': kind,
      'amount': amount,
      'state': state,
      'color': color,
      if (photo != null) 'photo': photo,
      if (note.text.trim().isNotEmpty) 'note': note.text.trim(),
    });
    app.addEntry(saved);
    toast(context, 'Đã ghi phân', undo: () => app.removeEntry(saved.id));
    Navigator.of(context).pop();
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.label, required this.art, required this.selected, required this.onTap, this.height = 66, this.artH = 34});
  final String label;
  final String? art;
  final bool selected;
  final VoidCallback onTap;
  final double height;
  final double artH;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Stack(clipBehavior: Clip.none, fit: StackFit.passthrough, children: [
          Container(
            constraints: BoxConstraints(minHeight: height),
            padding: const EdgeInsets.fromLTRB(2, 6, 2, 4),
            decoration: BoxDecoration(
              // tối: ô tím nhạt trong như kính, ô chọn đậm hơn một bậc (không dùng nâu đào)
              color: GB.dark ? (selected ? const Color(0xFF6B5FB8) : Colors.white.withValues(alpha: .12)) : (selected ? Color(0xFFFEECEB) : Color(0xFFFFF6F2)),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: selected ? (GB.dark ? const Color(0xFFD8C8FF) : GB.accent) : (GB.dark ? Colors.white.withValues(alpha: .30) : GB.edgeOf(Color(0xFFFFE9E2))), width: selected ? 1.8 : 1.1),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
              if (art != null) SizedBox(height: artH, child: Art(art!)),
              const SizedBox(height: 3),
              FittedBox(fit: BoxFit.scaleDown, child: Text(label, maxLines: 1, style: GB.body(10.5, w: selected ? FontWeight.w800 : FontWeight.w600))),
            ]),
          ),
          if (selected)
            Positioned(
              right: -3,
              top: -3,
              child: Container(width: 18, height: 18, decoration: BoxDecoration(color: GB.accent, shape: BoxShape.circle), child: const Icon(Icons.check_rounded, size: 12, color: Colors.white)),
            ),
        ]),
      ),
    );
  }
}
