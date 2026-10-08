import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/kit.dart';
import '../core/pastel.dart';
import '../core/pickers.dart';
import '../core/theme.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import 'fund.dart';
import 'quick_logs.dart';

final _tagColors = <(Color, Color)>[
  (GB.p(Color(0xFFFBE3CF)), GB.f(Color(0xFF8A4A1E))),
  (GB.p(Color(0xFFE3E6F6)), GB.f(Color(0xFF3F4A8A))),
  (GB.p(Color(0xFFF8DEDF)), GB.f(Color(0xFF9A3F49))),
  (GB.p(Color(0xFFE4EBD2)), GB.f(Color(0xFF4F6330))),
  (GB.p(Color(0xFFF8E9A8)), GB.f(Color(0xFF6B5410))),
  (GB.p(Color(0xFFFFD9D2)), GB.f(Color(0xFF8A3A2E))),
];

(Color, Color) tagColor(MoneyTag? t) => _tagColors[(t?.colorIdx ?? 0) % _tagColors.length];

/// "50k", "1,5tr", "1.250.000" → đồng.
int? parseMoney(String s) {
  var t = s.trim().toLowerCase().replaceAll('đ', '').replaceAll(' ', '');
  if (t.isEmpty) return null;
  var mult = 1;
  if (t.endsWith('tr') || t.endsWith('m')) {
    mult = 1000000;
    t = t.replaceAll('tr', '').replaceAll('m', '');
  } else if (t.endsWith('k') || t.endsWith('n')) {
    mult = 1000;
    t = t.replaceAll('k', '').replaceAll('n', '');
  } else if (t.endsWith('tỷ') || t.endsWith('ty')) {
    mult = 1000000000;
    t = t.replaceAll('tỷ', '').replaceAll('ty', '');
  }
  if (mult == 1) {
    final digits = t.replaceAll(RegExp(r'[.,]'), '');
    return int.tryParse(digits);
  }
  final n = double.tryParse(t.replaceAll(',', '.'));
  if (n == null) return null;
  return (n * mult).round();
}

String maskVnd(int n, {bool sign = false}) => app.settings.hideMoney ? '••••••' : GB.vnd(n, sign: sign);

class MoneyFilter {
  Set<String> tags = {};
  int type = 0; // 0 tất cả, 1 chi, 2 thu
  DateTimeRange? range;
  int? minAmt;
  int? maxAmt;
  bool photoOnly = false;
  String payer = '';
  String store = '';
  String query = '';

  bool get active => tags.isNotEmpty || type != 0 || range != null || minAmt != null || maxAmt != null || photoOnly || payer.isNotEmpty || store.isNotEmpty || query.isNotEmpty;

  bool match(Tx t) {
    if (type == 1 && t.income) return false;
    if (type == 2 && !t.income) return false;
    if (tags.isNotEmpty && !t.tags.any(tags.contains)) return false;
    if (range != null && (t.time.isBefore(range!.start) || !t.time.isBefore(range!.end.add(const Duration(days: 1))))) return false;
    if (minAmt != null && t.amount.abs() < minAmt!) return false;
    if (maxAmt != null && t.amount.abs() > maxAmt!) return false;
    if (photoOnly && t.photos.isEmpty) return false;
    if (payer.isNotEmpty && t.payer != payer) return false;
    if (store.isNotEmpty && !t.store.toLowerCase().contains(store.toLowerCase())) return false;
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      if (!(t.title.toLowerCase().contains(q) || t.code.toLowerCase().contains(q) || t.note.toLowerCase().contains(q) || t.store.toLowerCase().contains(q))) return false;
    }
    return true;
  }
}

/// Tab Tiền: Thu chi · Quỹ của con.
class MoneyTab extends StatefulWidget {
  const MoneyTab({super.key});

  @override
  State<MoneyTab> createState() => _MoneyTabState();
}

class _MoneyTabState extends State<MoneyTab> {
  int sub = 0;
  int period = 1; // 0 tuần, 1 tháng, 2 năm, 3 tất cả
  final f = MoneyFilter();
  bool showStats = false;
  final searchCtl = TextEditingController();

  @override
  void dispose() {
    searchCtl.dispose();
    super.dispose();
  }

  bool _inPeriod(Tx t) {
    final n = DateTime.now();
    switch (period) {
      case 0:
        final s = AppState.dayStart(n).subtract(Duration(days: n.weekday - 1));
        return !t.time.isBefore(s);
      case 1:
        return t.time.year == n.year && t.time.month == n.month;
      case 2:
        return t.time.year == n.year;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        return ListView(
          padding: Responsive.pad(context),
          children: [
            Row(children: [
              Expanded(child: Text('Tiền của bé', style: GB.display(30, color: GB.title))),
              RoundIconButton(
                icon: app.settings.hideMoney ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                label: app.settings.hideMoney ? 'Hiện số tiền' : 'Ẩn số tiền',
                size: 44,
                onTap: () {
                  app.settings.hideMoney = !app.settings.hideMoney;
                  app.settingsChanged();
                },
              ),
              const SizedBox(width: 8),
              RoundIconButton(
                icon: Icons.add_rounded,
                label: sub == 0 ? 'Thêm khoản thu chi' : 'Thêm vào quỹ',
                size: 44,
                iconColor: GB.accentDeep,
                onTap: () => sub == 0 ? openPage(context, const MoneyAddScreen()) : showFundEditor(context),
              ),
            ]),
            const SizedBox(height: 10),
            Seg(labels: const ['Thu chi', 'Quỹ của con'], index: sub, onChanged: (i) => setState(() => sub = i)),
            const SizedBox(height: 12),
            if (sub == 0) ..._txView() else ...fundView(context, () => setState(() {})),
          ],
        );
      },
    );
  }

  // ===== thu chi =====
  List<Widget> _txView() {
    final all = app.txs.where(_inPeriod).toList();
    var income = 0, expense = 0;
    for (final t in all) {
      if (t.income) {
        income += t.amount;
      } else {
        expense += -t.amount;
      }
    }
    final filtered = all.where(f.match).toList();
    final fsum = filtered.fold(0, (a, t) => a + t.amount);
    final usedTags = app.tags.where((t) => all.any((x) => x.tags.contains(t.id))).toList();
    final groups = <DateTime, List<Tx>>{};
    for (final t in filtered) {
      groups.putIfAbsent(AppState.dayStart(t.time), () => []).add(t);
    }
    final days = groups.keys.toList()..sort((a, b) => b.compareTo(a));
    final label = ['Tuần này', 'Tháng ${DateTime.now().month}', 'Năm nay', 'Tất cả'][period];

    // chi theo nhãn
    final byTag = <String, int>{};
    for (final t in all.where((t) => !t.income)) {
      if (t.tags.isEmpty) {
        byTag['_none'] = (byTag['_none'] ?? 0) + -t.amount;
      } else {
        for (final id in t.tags) {
          byTag[id] = (byTag[id] ?? 0) + (-t.amount / t.tags.length).round();
        }
      }
    }
    final tagList = byTag.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maxTag = tagList.isEmpty ? 1 : tagList.first.value;

    return [
      GlassCard(
        radius: 26,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('Số dư · $label', style: GB.body(13, w: FontWeight.w700, color: GB.inkMuted))),
            for (var i = 0; i < 4; i++)
              GestureDetector(
                onTap: () => setState(() => period = i),
                child: Padding(
                  padding: const EdgeInsets.only(left: 10, top: 6, bottom: 6),
                  child: Text(const ['Tuần', 'Tháng', 'Năm', 'Tất cả'][i], style: GB.body(12.5, w: period == i ? FontWeight.w800 : FontWeight.w600, color: period == i ? GB.ink : GB.inkMuted)),
                ),
              ),
          ]),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(maskVnd(income - expense, sign: true), style: GB.display(38))),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _mini('Tổng thu', maskVnd(income), GB.okBg, GB.ok)),
            const SizedBox(width: 10),
            Expanded(child: _mini('Tổng chi', maskVnd(expense), GB.alertBg, GB.alert)),
          ]),
          if (period == 1) ...[
            const SizedBox(height: 12),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _budgetDialog,
              child: budget() > 0 ? _budgetBar(expense) : Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('+ Đặt ngân sách tháng để được nhắc khi gần vượt', style: GB.body(13, w: FontWeight.w700, color: GB.accentDeep))),
            ),
          ],
        ]),
      ),
      const SizedBox(height: 10),
      GlassField(controller: searchCtl, label: 'Tìm theo tên món, mã hàng, nơi mua', onChanged: (v) => setState(() => f.query = v.trim())),
      const SizedBox(height: 8),
      SizedBox(
        height: 44,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          PillChip(label: f.active ? 'Bộ lọc •' : 'Bộ lọc', on: f.active, icon: Icons.tune_rounded, height: 44, onTap: _filterSheet),
          const SizedBox(width: 8),
          PillChip(label: 'Tất cả ${all.length}', on: f.tags.isEmpty, height: 44, onTap: () => setState(() => f.tags.clear())),
          for (final t in usedTags) ...[
            const SizedBox(width: 8),
            PillChip(label: '${t.label} ${all.where((x) => x.tags.contains(t.id)).length}', on: f.tags.contains(t.id), height: 44, onTap: () => setState(() => f.tags.contains(t.id) ? f.tags.remove(t.id) : f.tags.add(t.id))),
          ],
        ]),
      ),
      const SizedBox(height: 6),
      Row(children: [
        Expanded(child: Text(f.active ? '${filtered.length} khoản · ${maskVnd(fsum, sign: true)}' : 'Tất cả ${all.length} khoản', style: GB.body(12.5, w: FontWeight.w600, color: GB.inkMuted))),
        if (f.active)
          GestureDetector(
            onTap: () => setState(() {
              final q = f.query;
              f
                ..tags = {}
                ..type = 0
                ..range = null
                ..minAmt = null
                ..maxAmt = null
                ..photoOnly = false
                ..payer = ''
                ..store = ''
                ..query = '';
              if (q.isNotEmpty) searchCtl.clear();
            }),
            child: Padding(padding: const EdgeInsets.all(6), child: Text('Xoá lọc', style: GB.body(12.5, w: FontWeight.w800, color: GB.accentDeep))),
          ),
      ]),
      if (tagList.isNotEmpty) ...[
        const SizedBox(height: 12),
        SectionCard(
          title: 'Chi theo nhãn',
          icon: Icons.pie_chart_rounded,
          iconColor: GB.pumpDeep,
          trailing: showStats ? 'Thu gọn' : 'Xem hết',
          onTrailing: () => setState(() => showStats = !showStats),
          child: Column(children: [
            for (final e in (showStats ? tagList : tagList.take(4)))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(children: [
                  SizedBox(width: 92, child: Text(e.key == '_none' ? 'Chưa gắn nhãn' : (app.tagById(e.key)?.label ?? e.key), style: GB.body(13, w: FontWeight.w600))),
                  Expanded(
                    child: Stack(children: [
                      Container(height: 10, decoration: BoxDecoration(color: GB.line.withValues(alpha: .7), borderRadius: BorderRadius.circular(5))),
                      FractionallySizedBox(widthFactor: e.value / maxTag, child: Container(height: 10, decoration: BoxDecoration(gradient: LinearGradient(colors: [tagColor(app.tagById(e.key)).$2.withValues(alpha: .45), tagColor(app.tagById(e.key)).$2.withValues(alpha: .8)]), borderRadius: BorderRadius.circular(5)))),
                    ]),
                  ),
                  SizedBox(width: 78, child: Text(app.settings.hideMoney ? '••••' : GB.vndShort(e.value), textAlign: TextAlign.right, style: GB.body(12.5, w: FontWeight.w800))),
                ]),
              ),
          ]),
        ),
      ],
      if (days.isEmpty)
        const Padding(padding: EdgeInsets.only(top: 12), child: GlassCard(child: EmptyState('Chưa có khoản nào.\nBấm dấu + để thêm thu chi.', icon: Icons.receipt_long_rounded))),
      for (final d in days) ...[
        SectionTitle(GB.dayLabel(d), padTop: 14),
        GlassCard(
          radius: 22,
          padding: EdgeInsets.zero,
          child: Column(children: [for (var i = 0; i < groups[d]!.length; i++) _row(groups[d]![i], i == 0)]),
        ),
      ],
    ];
  }

  int budget() => app.settings.monthlyBudget;

  Future<void> _budgetDialog() async {
    final c = TextEditingController(text: budget() > 0 ? budget().toString() : '');
    final v = await showDialog<int>(
      context: context,
      builder: (ctx) => GlassAlert(
        backgroundColor: GB.cream,
        title: Text('Ngân sách chi mỗi tháng', style: GB.display(20, w: FontWeight.w700)),
        content: GlassField(controller: c, label: 'Số tiền (gõ 5tr, 3,5tr…)', suffix: 'đ'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, 0), child: Text('Bỏ ngân sách', style: GB.body(14, w: FontWeight.w700, color: GB.alert))),
          TextButton(onPressed: () => Navigator.pop(ctx, parseMoney(c.text)), child: Text('Lưu', style: GB.body(14, w: FontWeight.w800, color: GB.accentDeep))),
        ],
      ),
    );
    if (v != null) {
      app.settings.monthlyBudget = v;
      app.settingsChanged();
    }
  }

  Widget _budgetBar(int expense) {
    final b = budget();
    final r = expense / b;
    final col = r >= 1 ? GB.alert : r >= .8 ? GB.f(Color(0xFFC2453B)) : GB.accent;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text('Ngân sách tháng: ${maskVnd(b)}', style: GB.body(12.5, w: FontWeight.w700, color: GB.inkMuted))),
        Text('${(r * 100).round()}%', style: GB.body(12.5, w: FontWeight.w800, color: col)),
      ]),
      const SizedBox(height: 4),
      ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: r.clamp(0.0, 1.0), minHeight: 8, backgroundColor: GB.w(.7), valueColor: AlwaysStoppedAnimation(col))),
      if (r >= .8) Padding(padding: const EdgeInsets.only(top: 4), child: Text(r >= 1 ? 'Đã vượt ngân sách tháng.' : 'Sắp chạm ngân sách tháng.', style: GB.body(12, w: FontWeight.w700, color: col))),
    ]);
  }

  Widget _mini(String label, String v, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: bg.withValues(alpha: .9), borderRadius: BorderRadius.circular(16), border: Border.all(color: GB.edgeOf(bg.withValues(alpha: .9)), width: 1)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GB.body(11.5, w: FontWeight.w700, color: fg)),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(v, style: GB.body(17, w: FontWeight.w800, color: fg))),
        ]),
      );

  Widget _row(Tx t, bool first) {
    final first1 = t.tags.isEmpty ? null : app.tagById(t.tags.first);
    final c = tagColor(first1);
    final photo = t.photos.isEmpty ? null : app.photo(t.photos.first);
    return InkWell(
      onTap: () => openPage(context, MoneyAddScreen(edit: t)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(border: first ? null : Border(top: BorderSide(color: GB.f(Color(0xFF785A46)).withValues(alpha: .10)))),
        child: Row(children: [
          Stack(clipBehavior: Clip.none, children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(color: c.$1, borderRadius: BorderRadius.circular(14), border: Border.all(color: GB.edgeOf(c.$1), width: 1)),
              child: photo != null ? Image.memory(photo, width: 46, height: 46, fit: BoxFit.cover, gaplessPlayback: true) : Text((first1?.label ?? (t.title.isEmpty ? '?' : t.title)).characters.first.toUpperCase(), style: GB.display(18, color: c.$2)),
            ),
            if (t.photos.length > 1) Positioned(right: -4, bottom: -4, child: Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1), decoration: BoxDecoration(color: GB.ink, borderRadius: BorderRadius.circular(9), border: Border.all(color: GB.edgeOf(GB.ink), width: 1)), child: Text('${t.photos.length}', style: GB.body(10, w: FontWeight.w800, color: GB.cream)))),
          ]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.title.isEmpty ? (first1?.label ?? (t.income ? 'Khoản thu' : 'Khoản chi')) : t.title, style: GB.body(14.5, w: FontWeight.w700)),
              const SizedBox(height: 3),
              Wrap(spacing: 6, runSpacing: 3, crossAxisAlignment: WrapCrossAlignment.center, children: [
                for (final id in t.tags.take(2)) Tag(app.tagById(id)?.label ?? id, bg: tagColor(app.tagById(id)).$1, fg: tagColor(app.tagById(id)).$2),
                Text([if (t.code.isNotEmpty) t.code, GB.hm(t.time)].join(' · '), style: GB.body(11.5, color: GB.inkMuted)),
              ]),
            ]),
          ),
          const SizedBox(width: 8),
          Text(maskVnd(t.amount, sign: true), style: GB.body(14.5, w: FontWeight.w800, color: t.income ? GB.f(Color(0xFF3F5223)) : GB.ink)),
        ]),
      ),
    );
  }

  void _filterSheet() {
    showGlassSheet(context, builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setS) {
        final minC = TextEditingController(text: f.minAmt?.toString() ?? '');
        final maxC = TextEditingController(text: f.maxAmt?.toString() ?? '');
        final storeC = TextEditingController(text: f.store);
        return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Bộ lọc', style: GB.display(22, w: FontWeight.w700)),
          const SizedBox(height: 12),
          Seg(labels: const ['Tất cả', 'Chi', 'Thu'], index: f.type, height: 40, onChanged: (i) => setS(() => f.type = i)),
          const SizedBox(height: 12),
          Text('Nhãn', style: GB.body(13.5, w: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final t in app.tags) PillChip(label: t.label, on: f.tags.contains(t.id), onTap: () => setS(() => f.tags.contains(t.id) ? f.tags.remove(t.id) : f.tags.add(t.id))),
          ]),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final r = await showDateRangePicker(context: ctx, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 1)), initialDateRange: f.range, builder: (c, w) => Theme(data: Theme.of(c).copyWith(colorScheme: Theme.of(c).colorScheme.copyWith(primary: GB.accentDeep, surface: GB.cream)), child: w!));
              if (r != null) setS(() => f.range = r);
            },
            child: GlassCard(radius: 18, padding: const EdgeInsets.all(14), child: Row(children: [const Icon(Icons.date_range_rounded), const SizedBox(width: 10), Expanded(child: Text(f.range == null ? 'Khoảng thời gian: tất cả' : '${GB.dmy(f.range!.start)} – ${GB.dmy(f.range!.end)}', style: GB.body(14, w: FontWeight.w700))), if (f.range != null) GestureDetector(onTap: () => setS(() => f.range = null), child: const Icon(Icons.close_rounded))])),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: GlassField(controller: minC, label: 'Từ (đồng)', keyboard: TextInputType.number, onChanged: (v) => f.minAmt = parseMoney(v))),
            const SizedBox(width: 10),
            Expanded(child: GlassField(controller: maxC, label: 'Đến (đồng)', keyboard: TextInputType.number, onChanged: (v) => f.maxAmt = parseMoney(v))),
          ]),
          const SizedBox(height: 10),
          GlassField(controller: storeC, label: 'Nơi mua', onChanged: (v) => f.store = v.trim()),
          const SizedBox(height: 10),
          if (app.members.length > 1)
            Wrap(spacing: 8, children: [
              PillChip(label: 'Ai chi: tất cả', on: f.payer.isEmpty, onTap: () => setS(() => f.payer = '')),
              for (final m in app.members) PillChip(label: m.name, on: f.payer == m.name, onTap: () => setS(() => f.payer = m.name)),
            ]),
          Row(children: [
            Expanded(child: Text('Chỉ khoản có ảnh', style: GB.body(14.5, w: FontWeight.w700))),
            Switch(value: f.photoOnly, activeThumbColor: GB.accent, onChanged: (v) => setS(() => f.photoOnly = v)),
          ]),
          const SizedBox(height: 12),
          BigButton('Áp dụng', onTap: () {
            Navigator.pop(ctx);
            setState(() {});
          }),
        ]);
      });
    });
  }
}

/// Thêm / sửa một khoản thu chi. Chỉ số tiền và loại thu/chi là bắt buộc.
class MoneyAddScreen extends StatefulWidget {
  const MoneyAddScreen({super.key, this.edit});
  final Tx? edit;

  @override
  State<MoneyAddScreen> createState() => _MoneyAddScreenState();
}

class _MoneyAddScreenState extends State<MoneyAddScreen> {
  bool income = false;
  final amount = TextEditingController();
  final title = TextEditingController();
  final code = TextEditingController();
  final qty = TextEditingController(text: '1');
  final unit = TextEditingController();
  final store = TextEditingController();
  final note = TextEditingController();
  Set<String> tags = {};
  DateTime time = DateTime.now();
  String payer = '';
  List<String> photos = [];

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    if (e != null) {
      income = e.income;
      amount.text = e.amount.abs().toString();
      title.text = e.title;
      code.text = e.code;
      qty.text = e.qty == e.qty.roundToDouble() ? e.qty.round().toString() : e.qty.toString();
      unit.text = e.unitPrice?.toString() ?? '';
      store.text = e.store;
      note.text = e.note;
      tags = {...e.tags};
      time = e.time;
      payer = e.payer;
      photos = [...e.photos];
    } else {
      tags = {'bim'};
    }
  }

  @override
  void dispose() {
    for (final c in [amount, title, code, qty, unit, store, note]) {
      c.dispose();
    }
    super.dispose();
  }

  int get amt => parseMoney(amount.text) ?? 0;

  void _autoTotal() {
    final q = double.tryParse(qty.text.replaceAll(',', '.')) ?? 1;
    final u = parseMoney(unit.text);
    if (u != null && u > 0) {
      amount.text = (u * q).round().toString();
    }
    setState(() {});
  }

  void _addTag() async {
    final c = TextEditingController();
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => GlassAlert(
        backgroundColor: GB.cream,
        title: Text('Nhãn mới', style: GB.display(20, w: FontWeight.w700)),
        content: GlassField(controller: c, label: 'Tên nhãn'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Huỷ', style: GB.body(14, w: FontWeight.w700, color: GB.inkMuted))),
          TextButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: Text('Thêm', style: GB.body(14, w: FontWeight.w800, color: GB.accentDeep))),
        ],
      ),
    );
    if (v != null && v.isNotEmpty) {
      final id = 'c${uid()}';
      app.addTag(MoneyTag(id: id, label: v, colorIdx: app.tags.length % 6, income: income));
      setState(() => tags.add(id));
    }
  }

  void _save() {
    final a = amt;
    if (a <= 0) {
      toast(context, 'Nhập số tiền lớn hơn 0');
      return;
    }
    final signed = income ? a : -a;
    final q = double.tryParse(qty.text.replaceAll(',', '.')) ?? 1;
    final e = widget.edit;
    if (e == null) {
      app.addTx(Tx(time: time, amount: signed, title: title.text.trim(), tags: tags.toList(), code: code.text.trim(), qty: q, unitPrice: parseMoney(unit.text), store: store.text.trim(), payer: payer, note: note.text.trim(), photos: photos));
    } else {
      e
        ..time = time
        ..amount = signed
        ..title = title.text.trim()
        ..tags = tags.toList()
        ..code = code.text.trim()
        ..qty = q
        ..unitPrice = parseMoney(unit.text)
        ..store = store.text.trim()
        ..payer = payer
        ..note = note.text.trim()
        ..photos = photos;
      app.updateTx(e);
    }
    Navigator.of(context).pop();
    toast(context, 'Đã lưu khoản ${income ? 'thu' : 'chi'}');
  }

  @override
  Widget build(BuildContext context) {
    final tagList = app.tags.where((t) => t.income == income).toList();
    return SubPage(
      title: widget.edit == null ? 'Thêm khoản ${income ? 'thu' : 'chi'}' : 'Sửa khoản',
      titleArt: 'ic_wallet',
      actions: [
        if (widget.edit != null)
          RoundIconButton(icon: Icons.delete_outline_rounded, label: 'Xoá khoản', size: 44, onTap: () async {
            if (await confirmDialog(context, 'Xoá khoản này?', 'Khoản thu chi sẽ bị xoá.')) {
              app.removeTx(widget.edit!.id);
              if (context.mounted) Navigator.of(context).pop();
            }
          }),
      ],
      bottom: BigButton('Lưu', icon: Icons.check_rounded, onTap: _save),
      children: [
        Seg(labels: const ['Chi', 'Thu'], index: income ? 1 : 0, onChanged: (i) => setState(() {
              income = i == 1;
              tags = {};
            })),
        const SizedBox(height: 12),
        GlassCard(
          radius: 24,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            FormHeader('Số tiền', income ? Icons.south_west_rounded : Icons.north_east_rounded, color: income ? const Color(0xFFD7EAC4) : const Color(0xFFFAD0D3), hint: income ? 'Khoản tiền mẹ nhận được' : 'Khoản tiền mẹ đã chi cho bé'),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: amount,
                  keyboardType: TextInputType.text,
                  onChanged: (_) => setState(() {}),
                  style: GB.display(40, color: income ? GB.f(Color(0xFF3F5223)) : GB.ink),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: GB.card,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: GB.edgeOf(GB.line), width: 1.3)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: GB.edgeOf(GB.line), width: 1.3)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: GB.accent, width: 1.8)),
                    prefixIcon: Padding(padding: const EdgeInsets.only(left: 12, right: 6), child: Icon(Icons.payments_rounded, size: 28, color: income ? GB.ok : GB.accentDeep)),
                    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                    hintText: '0',
                    hintStyle: GB.display(40, color: GB.inkMuted.withValues(alpha: .4)),
                    suffixText: 'đ',
                    suffixStyle: GB.body(20, w: FontWeight.w700, color: GB.inkMuted),
                  ),
                ),
              ),
            ]),
            Text(amt > 0 ? GB.vnd(amt) : 'Gõ nhanh: 50k, 1,5tr, 285000', style: GB.body(12.5, color: GB.inkMuted)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final p in const [50000, 100000, 200000, 500000, 1000000])
                PillChip(label: '+${GB.vndShort(p)}', on: false, height: 36, icon: Icons.add_rounded, iconColor: GB.accentDeep, onTap: () => setState(() => amount.text = (amt + p).toString())),
            ]),
          ]),
        ),
        const SizedBox(height: 12),
        GlassCard(
          radius: 24,
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const FormHeader('Nhãn', Icons.sell_rounded, color: Color(0xFFE6DEF5), hint: 'Chọn một hoặc nhiều nhãn'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final t in tagList) PillChip(label: t.label, on: tags.contains(t.id), color: tagColor(t).$1, dot: tagColor(t).$2, onTap: () => setState(() => tags.contains(t.id) ? tags.remove(t.id) : tags.add(t.id))),
              GestureDetector(
                onTap: _addTag,
                child: Container(height: 40, padding: const EdgeInsets.symmetric(horizontal: 14), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: GB.accent.withValues(alpha: .75), width: 1.5)), child: Center(widthFactor: 1, child: Text('+ Nhãn mới', style: GB.body(13, w: FontWeight.w700, color: GB.inkMuted)))),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 12),
        TimeRowMoney(time: time, onChanged: (d) => setState(() => time = d)),
        const SizedBox(height: 12),
        GlassCard(
          radius: 24,
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const FormHeader('Chi tiết', Icons.receipt_long_rounded, color: Color(0xFFFBE3CF), hint: 'Không bắt buộc'),
            GlassField(controller: title, label: 'Tên món / loại hàng', hint: 'Ví dụ: tã dán size M', icon: Icons.shopping_bag_rounded),
            const SizedBox(height: 10),
            GlassField(controller: code, label: 'Mã hàng / SKU / mã vạch', icon: Icons.qr_code_2_rounded, iconColor: GB.info),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: GlassField(controller: qty, label: 'Số lượng', icon: Icons.numbers_rounded, iconColor: GB.ok, keyboard: const TextInputType.numberWithOptions(decimal: true), onChanged: (_) => _autoTotal())),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: GlassField(controller: unit, label: 'Đơn giá', suffix: 'đ', icon: Icons.sell_outlined, iconColor: GB.warn, onChanged: (_) => _autoTotal())),
            ]),
            const SizedBox(height: 10),
            GlassField(controller: store, label: 'Nơi mua', icon: Icons.storefront_rounded, iconColor: GB.health),
            const SizedBox(height: 10),
            if (app.members.length > 1) ...[
              Wrap(spacing: 8, runSpacing: 8, children: [
                PillChip(label: 'Ai chi: chưa chọn', on: payer.isEmpty, icon: Icons.person_outline_rounded, iconColor: GB.accentDeep, onTap: () => setState(() => payer = '')),
                for (final m in app.members) PillChip(label: m.name, on: payer == m.name, icon: Icons.person_rounded, iconColor: GB.accentDeep, onTap: () => setState(() => payer = m.name)),
              ]),
              const SizedBox(height: 10),
            ],
            GlassField(controller: note, label: 'Ghi chú', maxLines: 2, icon: Icons.edit_note_rounded, iconColor: GB.accentDeep),
          ]),
        ),
        const SizedBox(height: 12),
        GlassCard(
          radius: 24,
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const FormHeader('Ảnh', Icons.photo_camera_rounded, color: Color(0xFFDCEBF5), hint: 'Hoá đơn, sản phẩm. Ảnh chỉ lưu trên máy'),
            Wrap(spacing: 10, runSpacing: 10, children: [
              for (final p in photos) PhotoThumb(p, size: 72, onRemove: () => setState(() => photos.remove(p))),
              AddPhotoButton(size: 72, onTap: () async {
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

class TimeRowMoney extends StatelessWidget {
  const TimeRowMoney({super.key, required this.time, required this.onChanged});
  final DateTime time;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          final d = await pickDateTime(context, time, last: DateTime.now().add(const Duration(days: 1)));
          if (d != null) onChanged(d);
        },
        child: GlassCard(
          radius: 20,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          blur: 14,
          child: Row(children: [
            const Icon(Icons.schedule_rounded, size: 22),
            const SizedBox(width: 12),
            Text('Thời gian', style: GB.body(13, w: FontWeight.w600, color: GB.inkMuted)),
            const SizedBox(width: 8),
            Expanded(child: Text(GB.dmyhm(time), style: GB.body(15, w: FontWeight.w700))),
            Text('Sửa', style: GB.body(13, w: FontWeight.w700, color: GB.accentDeep)),
          ]),
        ),
      );
}

double maxD(Iterable<double> v) => v.fold(0, math.max);
