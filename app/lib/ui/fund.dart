import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/art_catalog.dart';
import '../core/kit.dart';
import '../core/pickers.dart';
import '../core/theme.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import 'money.dart';
import 'quick_logs.dart';

final _typeInfo = <AssetType, (String, Color, Color, IconData)>{
  AssetType.cash: ('Tiền mặt', GB.p(Color(0xFFE4EBD2)), GB.f(Color(0xFF4F6330)), Icons.payments_rounded),
  AssetType.saving: ('Tiết kiệm', GB.p(Color(0xFFE3E6F6)), GB.f(Color(0xFF3F4A8A)), Icons.savings_rounded),
  AssetType.gold: ('Vàng', GB.p(Color(0xFFF8E9A8)), GB.f(Color(0xFF6B5410)), Icons.diamond_rounded),
  AssetType.other: ('Khác', GB.p(Color(0xFFF8DEDF)), GB.f(Color(0xFF9A3F49)), Icons.account_balance_rounded),
};

final _filterState = ValueNotifier<AssetType?>(null);

/// Nội dung tab "Quỹ của con".
List<Widget> fundView(BuildContext context, VoidCallback refresh) {
  final total = app.fundTotal;
  final goal = app.goal;
  final pct = goal.target > 0 ? (total / goal.target) : 0.0;
  final byType = <AssetType, int>{for (final t in AssetType.values) t: app.funds.where((f) => f.type == t).fold(0, (a, f) => a + f.value)};
  final active = _filterState.value;
  final list = app.funds.where((f) => active == null || f.type == active).toList();
  final lsum = list.fold(0, (a, f) => a + f.value);
  final name = app.baby?.name ?? 'bé';
  final latest = app.funds.isEmpty ? null : app.funds.map((f) => f.moves.isEmpty ? f.date : f.moves.last.time).reduce((a, b) => a.isAfter(b) ? a : b);

  return [
    GlassCard(
      radius: 26,
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Tổng quỹ của $name', style: GB.body(12.5, w: FontWeight.w700, color: GB.inkMuted)),
            FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(maskVnd(total), style: GB.display(34))),
            const SizedBox(height: 4),
            Text(latest == null ? 'Chưa có khoản nào' : 'Cập nhật ${GB.dmy(latest)} · vàng tính theo giá nhập tay', style: GB.body(11.5, color: GB.inkMuted)),
            const SizedBox(height: 10),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _goalDialog(context),
              child: goal.target > 0
                  ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${goal.name.isEmpty ? 'Mục tiêu' : goal.name}: ${app.settings.hideMoney ? '••' : '${(pct * 100).round()}'}%', style: GB.body(12.5, w: FontWeight.w800)),
                      const SizedBox(height: 4),
                      ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: pct.clamp(0.0, 1.0), minHeight: 6, backgroundColor: GB.w(.7), valueColor: AlwaysStoppedAnimation(GB.gold))),
                      Text('Đích ${maskVnd(goal.target)}', style: GB.body(11.5, color: GB.inkMuted)),
                    ])
                  : Text('+ Đặt mục tiêu (học phí, du học…)', style: GB.body(12.5, w: FontWeight.w800, color: GB.accentDeep)),
            ),
          ]),
        ),
        const SizedBox(width: 8),
        SizedBox(width: 84, height: 118, child: JarView(fill: pct.clamp(0.0, 1.0))),
      ]),
    ),
    const SizedBox(height: 10),
    if (total > 0) ...[
      Row(children: [
        for (final t in AssetType.values)
          if (byType[t]! > 0) Expanded(flex: math.max(1, (byType[t]! / total * 1000).round()), child: Container(height: 12, margin: const EdgeInsets.only(right: 3), decoration: BoxDecoration(color: _typeInfo[t]!.$3.withValues(alpha: .6), borderRadius: BorderRadius.circular(6)))),
      ]),
      const SizedBox(height: 6),
      Wrap(spacing: 12, runSpacing: 4, children: [
        for (final t in AssetType.values)
          if (byType[t]! > 0)
            Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: _typeInfo[t]!.$3.withValues(alpha: .6), shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text('${_typeInfo[t]!.$1} ${app.settings.hideMoney ? '' : '${(byType[t]! / total * 100).round()}%'}', style: GB.body(11.5, color: GB.inkMuted)),
            ]),
      ]),
    ],
    const SizedBox(height: 10),
    SizedBox(
      height: 44,
      child: ListView(scrollDirection: Axis.horizontal, children: [
        PillChip(label: 'Tất cả', on: active == null, height: 44, onTap: () {
          _filterState.value = null;
          refresh();
        }),
        for (final t in AssetType.values) ...[
          const SizedBox(width: 8),
          PillChip(label: _typeInfo[t]!.$1, on: active == t, height: 44, onTap: () {
            _filterState.value = t;
            refresh();
          }),
        ],
      ]),
    ),
    const SizedBox(height: 6),
    Text(active == null ? '${app.funds.length} khoản trong quỹ' : '${_typeInfo[active]!.$1} · ${list.length} khoản · ${maskVnd(lsum)}', style: GB.body(12.5, w: FontWeight.w600, color: GB.inkMuted)),
    const SizedBox(height: 8),
    if (list.isEmpty)
      const GlassCard(child: EmptyState('Chưa có khoản nào trong quỹ.\nBấm nút + ở góc trên bên phải để ghi tiền, sổ tiết kiệm hay vàng.', icon: Icons.savings_rounded))
    else
      GlassCard(
        radius: 22,
        padding: EdgeInsets.zero,
        child: Column(children: [for (var i = 0; i < list.length; i++) _fundRow(context, list[i], i == 0)]),
      ),
    const SizedBox(height: 14),
    Text('App chỉ là sổ ghi chép, không thực hiện giao dịch tiền thật và không đưa lời khuyên đầu tư. Giá vàng và giá trị khác do mẹ nhập tay.', style: GB.body(11.5, color: GB.inkMuted, height: 1.4)),
  ];
}

Widget _fundRow(BuildContext context, FundItem f, bool first) {
  final info = _typeInfo[f.type]!;
  final sub = switch (f.type) {
    AssetType.gold => '${_num(f.qty)} ${f.unit} · mua ${GB.dmy(f.date)}${f.curPrice > 0 ? ' · ${app.settings.hideMoney ? '••' : GB.vndShort(f.curPrice)}/${f.unit}' : ''}',
    AssetType.saving => '${f.rate > 0 ? '${_num(f.rate)}%/năm' : 'Tiết kiệm'}${f.maturity != null ? ' · đáo hạn ${GB.dmy(f.maturity!)}' : ''}',
    _ => f.note.isEmpty ? 'Từ ${GB.dmy(f.date)}' : f.note,
  };
  return InkWell(
    onTap: () => showFundDetail(context, f),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(border: first ? null : Border(top: BorderSide(color: GB.f(Color(0xFF785A46)).withValues(alpha: .10)))),
      child: Row(children: [
        Container(width: 46, height: 46, decoration: BoxDecoration(color: info.$2, borderRadius: BorderRadius.circular(14), border: Border.all(color: GB.edgeOf(info.$2), width: 1)), child: _fundArt(f.type) != null ? Padding(padding: const EdgeInsets.all(7), child: Art(_fundArt(f.type)!)) : Icon(info.$4, color: info.$3)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(f.name, style: GB.body(14.5, w: FontWeight.w700)),
            Text(sub, style: GB.body(11.5, color: GB.inkMuted, height: 1.3)),
            const SizedBox(height: 3),
            Wrap(spacing: 6, children: [
              Tag(info.$1, bg: info.$2, fg: info.$3),
              if (f.holder.isNotEmpty) Tag(f.holder, bg: GB.w(.7), fg: GB.ink),
              if (f.photos.isNotEmpty) Icon(Icons.photo_camera_rounded, size: 14, color: GB.inkMuted),
            ]),
          ]),
        ),
        const SizedBox(width: 8),
        Text(maskVnd(f.value), style: GB.body(14.5, w: FontWeight.w800)),
      ]),
    ),
  );
}

/// Tranh màu nước cho từng loại tài sản (cùng bộ với các icon khác); chưa có tranh thì dùng icon hệ thống.
String? _fundArt(AssetType t) {
  final n = switch (t) { AssetType.cash => 'ic_wallet', AssetType.saving => 'ic_fund', AssetType.gold => 'ic_star', _ => null };
  return n != null && ArtCatalog.has(n) ? n : null;
}

String _num(double v) => v == v.roundToDouble() ? v.round().toString() : v.toString().replaceAll('.', ',');

Future<void> _goalDialog(BuildContext context) async {
  final n = TextEditingController(text: app.goal.name);
  final t = TextEditingController(text: app.goal.target > 0 ? app.goal.target.toString() : '');
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => GlassAlert(
      backgroundColor: GB.cream,
      title: Text('Mục tiêu của quỹ', style: GB.display(20, w: FontWeight.w700)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        GlassField(controller: n, label: 'Tên mục tiêu', hint: 'Học phí lớp 1'),
        const SizedBox(height: 10),
        GlassField(controller: t, label: 'Số tiền đích (gõ 120tr…)', suffix: 'đ'),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Huỷ', style: GB.body(14, w: FontWeight.w700, color: GB.inkMuted))),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Lưu', style: GB.body(14, w: FontWeight.w800, color: GB.accentDeep))),
      ],
    ),
  );
  if (ok == true) app.setGoal(FundGoal(name: n.text.trim(), target: parseMoney(t.text) ?? 0));
}

/// Thêm hoặc sửa một khoản trong quỹ: mở thành màn hình riêng giống màn nhập thu chi.
Future<void> showFundEditor(BuildContext context, {FundItem? edit}) => openPage(context, FundEditScreen(edit: edit));

class FundEditScreen extends StatefulWidget {
  const FundEditScreen({super.key, this.edit});
  final FundItem? edit;

  @override
  State<FundEditScreen> createState() => _FundEditScreenState();
}

class _FundEditScreenState extends State<FundEditScreen> {
  late AssetType type;
  late final TextEditingController name, amount, qty, buy, cur, rate, holder, note;
  late String unit;
  DateTime? maturity;
  late DateTime date;
  late final List<String> photos;

  @override
  void initState() {
    super.initState();
    final edit = widget.edit;
    type = edit?.type ?? AssetType.cash;
    name = TextEditingController(text: edit?.name ?? '');
    amount = TextEditingController(text: edit != null && edit.type != AssetType.gold ? edit.amount.toString() : '');
    qty = TextEditingController(text: edit != null && edit.qty > 0 ? _num(edit.qty) : '');
    unit = edit?.unit ?? 'chỉ';
    buy = TextEditingController(text: edit != null && edit.buyPrice > 0 ? edit.buyPrice.toString() : '');
    cur = TextEditingController(text: edit != null && edit.curPrice > 0 ? edit.curPrice.toString() : '');
    rate = TextEditingController(text: edit != null && edit.rate > 0 ? _num(edit.rate) : '');
    maturity = edit?.maturity;
    holder = TextEditingController(text: edit?.holder ?? '');
    note = TextEditingController(text: edit?.note ?? '');
    date = edit?.date ?? DateTime.now();
    photos = <String>[...?edit?.photos];
  }

  @override
  void dispose() {
    for (final c in [name, amount, qty, buy, cur, rate, holder, note]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final edit = widget.edit;
      final nm = name.text.trim();
      if (nm.isEmpty) {
        toast(context, 'Nhập tên khoản');
        return;
      }
      final amt = parseMoney(amount.text) ?? 0;
      final q = double.tryParse(qty.text.replaceAll(',', '.')) ?? 0;
      if (type == AssetType.gold ? q <= 0 : amt <= 0) {
        toast(context, type == AssetType.gold ? 'Nhập số lượng vàng' : 'Nhập số tiền');
        return;
      }
      if (edit == null) {
        final f = FundItem(
          name: nm,
          type: type,
          amount: type == AssetType.gold ? 0 : amt,
          qty: q,
          unit: unit,
          buyPrice: parseMoney(buy.text) ?? 0,
          curPrice: parseMoney(cur.text) ?? 0,
          rate: double.tryParse(rate.text.replaceAll(',', '.')) ?? 0,
          maturity: maturity,
          holder: holder.text.trim(),
          note: note.text.trim(),
          date: date,
          photos: photos,
        );
        f.moves.add(FundMove(time: date, kind: 'add', delta: f.value, note: 'Tạo khoản'));
        app.addFund(f);
      } else {
        edit
          ..name = nm
          ..type = type
          ..amount = type == AssetType.gold ? 0 : amt
          ..qty = q
          ..unit = unit
          ..buyPrice = parseMoney(buy.text) ?? 0
          ..curPrice = parseMoney(cur.text) ?? 0
          ..rate = double.tryParse(rate.text.replaceAll(',', '.')) ?? 0
          ..maturity = maturity
          ..holder = holder.text.trim()
          ..note = note.text.trim()
          ..date = date
          ..photos = photos;
        app.fundChanged();
      }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final holders = {'Mẹ', 'Ba', ...app.members.map((m) => m.name)}.toList();
    final edit = widget.edit;
    return SubPage(
      title: edit == null ? 'Thêm vào quỹ' : 'Sửa khoản quỹ',
      titleArt: 'ic_fund',
      bottom: BigButton('Lưu', icon: Icons.check_rounded, onTap: _save),
      children: [
        GlassCard(
          radius: 24,
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const FormHeader('Loại tài sản', Icons.category_rounded, color: Color(0xFFE6DEF5), hint: 'Tiền mặt, sổ tiết kiệm, vàng…'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final t in AssetType.values) PillChip(label: _typeInfo[t]!.$1, on: type == t, color: _typeInfo[t]!.$2, icon: _typeInfo[t]!.$4, iconColor: _typeInfo[t]!.$3, onTap: () => setState(() => type = t)),
            ]),
          ]),
        ),
        const SizedBox(height: 12),
        GlassCard(
          radius: 24,
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            FormHeader('Thông tin khoản', _typeInfo[type]!.$4, color: _typeInfo[type]!.$2, hint: 'Tên và giá trị'),
            GlassField(controller: name, label: type == AssetType.gold ? 'Tên (vàng nhẫn 9999…)' : type == AssetType.saving ? 'Tên sổ (Sổ tiết kiệm 12 tháng…)' : 'Tên khoản', icon: Icons.drive_file_rename_outline_rounded),
            const SizedBox(height: 10),
        if (type == AssetType.gold) ...[
          Row(children: [
            Expanded(child: GlassField(controller: qty, label: 'Số lượng', icon: Icons.scale_rounded, iconColor: GB.ok, keyboard: const TextInputType.numberWithOptions(decimal: true))),
            const SizedBox(width: 10),
            for (final u in const ['chỉ', 'lượng', 'gram']) Padding(padding: const EdgeInsets.only(left: 6), child: PillChip(label: u, on: unit == u, onTap: () => setState(() => unit = u))),
          ]),
          const SizedBox(height: 10),
          GlassField(controller: buy, label: 'Giá mua mỗi $unit', icon: Icons.shopping_cart_rounded, iconColor: GB.warn, suffix: 'đ'),
          const SizedBox(height: 10),
          GlassField(controller: cur, label: 'Giá hiện tại mỗi $unit (nhập tay)', icon: Icons.trending_up_rounded, iconColor: GB.ok, suffix: 'đ'),
        ] else ...[
          GlassField(controller: amount, label: 'Số tiền (gõ 20tr, 500k…)', icon: Icons.payments_rounded, iconColor: GB.ok, suffix: 'đ'),
          if (type == AssetType.saving) ...[
            const SizedBox(height: 10),
            GlassField(controller: rate, label: 'Lãi suất %/năm', icon: Icons.percent_rounded, iconColor: GB.info, keyboard: const TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () async {
                final d = await pickDateTime(context, maturity ?? DateTime.now().add(const Duration(days: 365)), timeToo: false, last: DateTime.now().add(const Duration(days: 365 * 10)));
                if (d != null) setState(() => maturity = d);
              },
              child: GlassCard(radius: 18, padding: const EdgeInsets.all(14), blur: 12, child: Row(children: [Icon(Icons.event_rounded, color: GB.info), const SizedBox(width: 10), Expanded(child: Text(maturity == null ? 'Ngày đáo hạn' : 'Đáo hạn ${GB.dmy(maturity!)}', style: GB.body(14, w: FontWeight.w700)))])),
            ),
          ],
        ],
          ]),
        ),
        const SizedBox(height: 12),
        GlassCard(
          radius: 24,
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const FormHeader('Ai đang giữ', Icons.family_restroom_rounded, color: Color(0xFFF8DEDF), hint: 'Chạm để chọn nhanh'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final h in holders) PillChip(label: '$h giữ', on: holder.text == '$h giữ', icon: Icons.person_rounded, iconColor: GB.accentDeep, onTap: () => setState(() => holder.text = holder.text == '$h giữ' ? '' : '$h giữ')),
            ]),
            const SizedBox(height: 10),
            GlassField(controller: holder, label: 'Hoặc nhập người giữ', icon: Icons.person_add_alt_1_rounded, onChanged: (_) => setState(() {})),
            const SizedBox(height: 10),
            GlassField(controller: note, label: 'Ghi chú (ai tặng, dịp nào…)', maxLines: 2, icon: Icons.edit_note_rounded),
          ]),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () async {
            final d = await pickDateTime(context, date, timeToo: false, last: DateTime.now());
            if (d != null) setState(() => date = d);
          },
          child: GlassCard(radius: 20, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), blur: 14, child: Row(children: [Icon(Icons.today_rounded, color: GB.info), const SizedBox(width: 12), Text('Ngày', style: GB.body(13, w: FontWeight.w600, color: GB.inkMuted)), const SizedBox(width: 8), Expanded(child: Text(GB.dmy(date), style: GB.body(15, w: FontWeight.w700))), Text('Sửa', style: GB.body(13, w: FontWeight.w700, color: GB.accentDeep))])),
        ),
        const SizedBox(height: 12),
        GlassCard(
          radius: 24,
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const FormHeader('Ảnh', Icons.photo_camera_rounded, color: Color(0xFFDCEBF5), hint: 'Sổ tiết kiệm, biên nhận. Ảnh chỉ lưu trên máy'),
            Wrap(spacing: 10, runSpacing: 10, children: [
              for (final p in photos) PhotoThumb(p, onRemove: () => setState(() => photos.remove(p))),
              AddPhotoButton(onTap: () async {
                final id = await pickAndStorePhoto(context);
                if (id != null) setState(() => photos.add(id));
              }),
            ]),
          ]),
        ),
      ],
    );
  }
}

/// Chi tiết một khoản: lịch sử, thêm vào / rút ra / cập nhật giá trị.
Future<void> showFundDetail(BuildContext context, FundItem f) {
  return showGlassSheet(context, builder: (ctx) {
    return ListenableBuilder(
      listenable: app,
      builder: (ctx, _) {
        final info = _typeInfo[f.type]!;
        final gain = f.type == AssetType.gold && f.buyPrice > 0 ? f.value - (f.qty * f.buyPrice).round() : null;
        int? interest;
        if (f.type == AssetType.saving && f.rate > 0) {
          final days = DateTime.now().difference(f.date).inDays;
          interest = (f.amount * f.rate / 100 * days / 365).round();
        }
        return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: info.$2, borderRadius: BorderRadius.circular(14), border: Border.all(color: GB.edgeOf(info.$2), width: 1)), child: Icon(info.$4, color: info.$3)),
            const SizedBox(width: 12),
            Expanded(child: Text(f.name, style: GB.display(22, w: FontWeight.w700))),
          ]),
          const SizedBox(height: 10),
          Text(maskVnd(f.value), style: GB.display(36)),
          if (gain != null) Text('${gain >= 0 ? 'Lãi' : 'Lỗ'} tạm tính ${maskVnd(gain.abs())} so với giá mua', style: GB.body(13, w: FontWeight.w700, color: gain >= 0 ? GB.ok : GB.alert)),
          if (interest != null && interest > 0) Text('Lãi ước tính đến nay ~${maskVnd(interest)} (lãi đơn)', style: GB.body(13, w: FontWeight.w700, color: GB.ok)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 6, children: [
            Tag(info.$1, bg: info.$2, fg: info.$3),
            if (f.holder.isNotEmpty) Tag(f.holder, bg: GB.w(.7), fg: GB.ink),
            if (f.type == AssetType.gold) Tag('${_num(f.qty)} ${f.unit}', bg: info.$2, fg: info.$3),
            if (f.maturity != null) Tag('Đáo hạn ${GB.dmy(f.maturity!)}', bg: GB.infoBg, fg: GB.info),
          ]),
          if (f.note.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Ghi chú: ${f.note}', style: GB.body(13.5, color: GB.inkMuted))),
          if (f.photos.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 10, runSpacing: 10, children: [for (final p in f.photos) PhotoThumb(p)]),
          ],
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: BigButton(f.type == AssetType.gold ? 'Thêm vàng' : 'Thêm vào', icon: Icons.add_rounded, height: 48, onTap: () => _moveDialog(ctx, f, 'add'))),
            const SizedBox(width: 10),
            if (f.type != AssetType.gold) Expanded(child: BigButton('Rút ra', icon: Icons.remove_rounded, height: 48, color: GB.w(.75), fg: GB.ink, onTap: () => _moveDialog(ctx, f, 'out'))),
            if (f.type == AssetType.gold) Expanded(child: BigButton('Cập nhật giá', icon: Icons.trending_up_rounded, height: 48, color: GB.w(.75), fg: GB.ink, onTap: () => _moveDialog(ctx, f, 'price'))),
          ]),
          if (f.type != AssetType.gold) ...[
            const SizedBox(height: 8),
            BigButton('Cập nhật giá trị', icon: Icons.edit_rounded, height: 44, color: GB.w(.75), fg: GB.ink, onTap: () => _moveDialog(ctx, f, 'adjust')),
          ],
          const SectionTitle('Lịch sử', padTop: 16),
          if (f.moves.isEmpty) const EmptyState('Chưa có lịch sử.') else for (final m in f.moves.reversed.take(12)) _moveRow(m),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: BigButton('Sửa', icon: Icons.edit_rounded, height: 46, color: GB.w(.75), fg: GB.ink, onTap: () {
              Navigator.pop(ctx);
              showFundEditor(context, edit: f);
            })),
            const SizedBox(width: 10),
            Expanded(child: BigButton('Xoá', icon: Icons.delete_outline_rounded, height: 46, color: GB.alertBg, fg: GB.alert, onTap: () async {
              if (await confirmDialog(ctx, 'Xoá khoản này khỏi quỹ?', 'Lịch sử của khoản cũng bị xoá.')) {
                app.removeFund(f.id);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            })),
          ]),
        ]);
      },
    );
  });
}

Widget _moveRow(FundMove m) {
  final label = switch (m.kind) { 'add' => 'Thêm vào', 'out' => 'Rút ra', 'price' => 'Cập nhật giá', _ => 'Điều chỉnh' };
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      SizedBox(width: 74, child: Text(GB.dmy(m.time), style: GB.body(12.5, color: GB.inkMuted))),
      Expanded(child: Text('$label${m.note.isEmpty ? '' : ' · ${m.note}'}', style: GB.body(13.5, w: FontWeight.w600))),
      Text(m.kind == 'price' ? '' : maskVnd(m.delta, sign: true), style: GB.body(13.5, w: FontWeight.w800, color: m.delta >= 0 ? GB.ok : GB.alert)),
    ]),
  );
}

Future<void> _moveDialog(BuildContext context, FundItem f, String kind) async {
  final c = TextEditingController();
  final n = TextEditingController();
  final gold = f.type == AssetType.gold;
  final title = switch (kind) { 'add' => gold ? 'Thêm vàng' : 'Thêm vào quỹ', 'out' => 'Rút ra', 'price' => 'Giá hiện tại mỗi ${f.unit}', _ => 'Giá trị mới' };
  final label = kind == 'price' ? 'Giá mỗi ${f.unit} (đồng)' : gold && kind == 'add' ? 'Số lượng thêm (${f.unit})' : 'Số tiền (gõ 5tr, 500k…)';
  final p = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => GlassAlert(
      backgroundColor: GB.cream,
      title: Text(title, style: GB.display(20, w: FontWeight.w700)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        GlassField(controller: c, label: label, keyboard: gold && kind == 'add' ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text),
        if (gold && kind == 'add') ...[const SizedBox(height: 10), GlassField(controller: p, label: 'Giá mua mỗi ${f.unit} (đồng)')],
        const SizedBox(height: 10),
        GlassField(controller: n, label: 'Ghi chú (tuỳ chọn)'),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Huỷ', style: GB.body(14, w: FontWeight.w700, color: GB.inkMuted))),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Lưu', style: GB.body(14, w: FontWeight.w800, color: GB.accentDeep))),
      ],
    ),
  );
  if (ok != true) return;
  final now = DateTime.now();
  if (gold) {
    if (kind == 'price') {
      final v = parseMoney(c.text);
      if (v == null || v <= 0) return;
      final before = f.value;
      f.curPrice = v;
      f.moves.add(FundMove(time: now, kind: 'price', delta: f.value - before, note: '${GB.vndShort(v)}/${f.unit}${n.text.isEmpty ? '' : ' · ${n.text}'}'));
    } else if (kind == 'add') {
      final q = double.tryParse(c.text.replaceAll(',', '.')) ?? 0;
      final price = parseMoney(p.text) ?? f.buyPrice;
      if (q <= 0) return;
      final total = f.qty + q;
      f.buyPrice = total == 0 ? price : (((f.qty * f.buyPrice) + q * price) / total).round();
      f.qty = total;
      f.moves.add(FundMove(time: now, kind: 'add', delta: (q * price).round(), note: '+${_num(q)} ${f.unit}${n.text.isEmpty ? '' : ' · ${n.text}'}'));
    }
  } else {
    final v = parseMoney(c.text);
    if (v == null || v < 0) return;
    if (kind == 'add') {
      f.amount += v;
      f.moves.add(FundMove(time: now, kind: 'add', delta: v, note: n.text.trim()));
    } else if (kind == 'out') {
      final out = math.min(v, f.amount);
      f.amount -= out;
      f.moves.add(FundMove(time: now, kind: 'out', delta: -out, note: n.text.trim()));
    } else {
      final d = v - f.amount;
      f.amount = v;
      f.moves.add(FundMove(time: now, kind: 'adjust', delta: d, note: n.text.trim()));
    }
  }
  app.fundChanged();
}

/// Hũ tiết kiệm có mức tiền dâng theo tỷ lệ đạt mục tiêu.
class JarView extends StatefulWidget {
  const JarView({super.key, required this.fill});
  final double fill;

  @override
  State<JarView> createState() => _JarViewState();
}

class _JarViewState extends State<JarView> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    return Semantics(
      label: 'Hũ tiết kiệm',
      value: '${(widget.fill * 100).round()}% mục tiêu',
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: widget.fill),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => AnimatedBuilder(animation: _c, builder: (context, _) => CustomPaint(painter: _JarPainter(v, reduce ? 0 : _c.value))),
      ),
    );
  }
}

class _JarPainter extends CustomPainter {
  _JarPainter(this.fill, this.phase);
  final double fill;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 84, size.height / 118);
    final body = RRect.fromRectAndRadius(const Rect.fromLTWH(10, 22, 64, 90), const Radius.circular(18));
    canvas.drawRRect(body, Paint()..color = GB.w(.7));
    canvas.save();
    canvas.clipRRect(body);
    final top = 112 - (fill.clamp(0.0, 1.0) * 86);
    if (fill > 0.01) {
      final p = Path()..moveTo(0, 130)..lineTo(0, top);
      for (double x = 0; x <= 90; x += 3) {
        p.lineTo(x, top + math.sin(((x / 30) + phase * 2) * math.pi) * 2.2);
      }
      p..lineTo(90, 130)..close();
      canvas.drawPath(p, Paint()..color = GB.gold);
      final coin = Paint()..color = GB.p(Color(0xFFFFD66B));
      final edge = Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xFFB88400)
        ..strokeWidth = 1.4;
      for (final o in const [Offset(30, 100), Offset(48, 104), Offset(58, 94), Offset(38, 88)]) {
        if (o.dy > top + 6) {
          canvas.drawCircle(o, 6, coin);
          canvas.drawCircle(o, 6, edge);
        }
      }
    }
    canvas.restore();
    canvas.drawRRect(body, Paint()
      ..style = PaintingStyle.stroke
      ..color = GB.ink
      ..strokeWidth = 2.5);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(18, 8, 48, 16), const Radius.circular(6)), Paint()..color = GB.ink);
    canvas.drawLine(const Offset(32, 15), const Offset(52, 15), Paint()
      ..color = GB.accent
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_JarPainter old) => old.fill != fill || old.phase != phase;
}
