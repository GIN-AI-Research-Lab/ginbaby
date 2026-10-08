class DiaperScreen extends StatefulWidget {
  const DiaperScreen({super.key});

  @override
  State<DiaperScreen> createState() => _DiaperScreenState();
}

class _DiaperScreenState extends State<DiaperScreen> {
  String kind = 'poop';
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
    final Color vBg = v.level == Level.ok ? const Color(0xFFEAF3E4) : (bad ? GB.alertBg : (v.level == Level.info ? GB.infoBg : GB.warnBg));
    final Color vFg = v.level == Level.ok ? GB.ok : (bad ? GB.alert : (v.level == Level.info ? GB.info : GB.warn));
    final main = [for (final k in kPoopColors.take(6)) (k.$1, k.$2)];
    final warn = [for (final k in kPoopColors.skip(6)) (k.$1, k.$2)];

    return SubPage(
      title: 'Phân của bé',
      subtitle: 'Theo dõi đặc điểm phân giúp ba mẹ hiểu rõ hệ tiêu hoá của con hơn',
      art: 'hero_diaper',
      artWidth: 150,
      children: [
        GlassCard(
          radius: 24,
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.edit_note_rounded, color: GB.pumpDeep, size: 24),
              const SizedBox(width: 8),
              Expanded(child: Text(kind == 'wet' ? 'Ghi nhận tã ướt' : 'Ghi nhận phân mới', style: GB.display(17, w: FontWeight.w800))),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              for (final k in const [('wet', 'Tã ướt'), ('poop', 'Phân'), ('both', 'Cả hai')]) ...[
                Expanded(child: PillChip(label: k.$2, on: kind == k.$1, height: 34, onTap: () => setState(() => kind = k.$1))),
                if (k.$1 != 'both') const SizedBox(width: 6),
              ],
            ]),
            if (kind != 'wet') ...[
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
            _head(Icons.baby_changing_station_rounded, kind == 'wet' ? 'Lượng tã ướt' : '3. Số lượng'),
            _row([for (final k in kDiaperAmounts) (k.$1, k.$2)], amount, (x) => amount = x, height: 66, artH: 34),
            const SizedBox(height: 12),
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
                decoration: BoxDecoration(color: vBg, borderRadius: BorderRadius.circular(16)),
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
                  const Icon(Icons.schedule_rounded, size: 20, color: GB.inkMuted),
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
                const Expanded(child: Text('Ảnh chỉ lưu trên máy', style: TextStyle(fontSize: 12, color: GB.inkMuted))),
              ]),
              const SizedBox(height: 10),
              GlassField(controller: note, label: 'Ghi chú (tuỳ chọn)'),
            ],
            const SizedBox(height: 12),
            BigButton('Lưu cữ thay tã', icon: Icons.save_alt_rounded, onTap: _save),
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
            decoration: BoxDecoration(color: pillColor, borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(ok ? Icons.sentiment_satisfied_alt_rounded : Icons.sentiment_neutral_rounded, size: 14, color: pillFg),
              const SizedBox(width: 2),
              Text(ok ? 'Ổn' : (vv.level == Level.alert ? 'Khám' : 'Theo dõi'), style: GB.body(10.5, w: FontWeight.w800, color: pillFg)),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded, size: 18, color: GB.inkMuted),
        ]),
      ),
    );
  }

  void _save() {
    app.addEntry(Entry(type: T.diaper, time: time, data: {
      'kind': kind,
      'amount': amount,
      if (kind != 'wet') 'state': state,
      if (kind != 'wet') 'color': color,
      if (photo != null) 'photo': photo,
      if (note.text.trim().isNotEmpty) 'note': note.text.trim(),
    }));
    toast(context, 'Đã ghi ${kind == 'wet' ? 'tã ướt' : 'phân'}');
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
            height: height,
            padding: const EdgeInsets.fromLTRB(2, 6, 2, 4),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFFEECEB) : const Color(0xFFFFF6F2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: selected ? GB.accent.withValues(alpha: .55) : Colors.transparent, width: 1.4),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (art != null) SizedBox(height: artH, child: Art(art!)),
              const SizedBox(height: 3),
              FittedBox(fit: BoxFit.scaleDown, child: Text(label, maxLines: 1, style: GB.body(10.5, w: selected ? FontWeight.w800 : FontWeight.w600))),
            ]),
          ),
          if (selected)
            Positioned(
              right: -3,
              top: -3,
              child: Container(width: 18, height: 18, decoration: const BoxDecoration(color: GB.accent, shape: BoxShape.circle), child: const Icon(Icons.check_rounded, size: 12, color: Colors.white)),
            ),
        ]),
      ),
    );
  }
}
