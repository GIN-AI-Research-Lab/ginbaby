import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'kit.dart';
import 'theme.dart';

/// Chọn ngày và giờ bằng cách gõ thẳng (dd/mm/yy, hh:mm), có nút ± và các lối tắt "Bây giờ", "15 phút trước"...
/// Trả về null nếu bỏ qua.
Future<DateTime?> pickDateTime(BuildContext context, DateTime initial, {DateTime? first, DateTime? last, bool timeToo = true, String title = ''}) {
  final now = DateTime.now();
  return showGlassSheet<DateTime>(
    context,
    builder: (ctx) => _WhenSheet(
      initial: initial,
      first: first ?? now.subtract(const Duration(days: 365 * 3)),
      last: last ?? now.add(const Duration(days: 365 * 2)),
      timeToo: timeToo,
      title: title.isEmpty ? (timeToo ? 'Chọn ngày giờ' : 'Chọn ngày') : title,
    ),
  );
}

class _WhenSheet extends StatefulWidget {
  const _WhenSheet({required this.initial, required this.first, required this.last, required this.timeToo, required this.title});
  final DateTime initial;
  final DateTime first;
  final DateTime last;
  final bool timeToo;
  final String title;

  @override
  State<_WhenSheet> createState() => _WhenSheetState();
}

class _WhenSheetState extends State<_WhenSheet> {
  final dd = TextEditingController();
  final mo = TextEditingController();
  final yy = TextEditingController();
  final hh = TextEditingController();
  final mi = TextEditingController();
  final fDd = FocusNode();
  final fMo = FocusNode();
  final fYy = FocusNode();
  final fHh = FocusNode();
  final fMi = FocusNode();
  late DateTime lastGood;

  @override
  void initState() {
    super.initState();
    lastGood = widget.initial;
    _fill(widget.initial);
    for (final f in [fDd, fMo, fYy, fHh, fMi]) {
      f.addListener(() {
        if (f.hasFocus) {
          final c = _ctrlOf(f);
          c.selection = TextSelection(baseOffset: 0, extentOffset: c.text.length);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final c in [dd, mo, yy, hh, mi]) {
      c.dispose();
    }
    for (final f in [fDd, fMo, fYy, fHh, fMi]) {
      f.dispose();
    }
    super.dispose();
  }

  TextEditingController _ctrlOf(FocusNode f) => f == fDd ? dd : f == fMo ? mo : f == fYy ? yy : f == fHh ? hh : mi;

  void _fill(DateTime v) {
    dd.text = GB.two(v.day);
    mo.text = GB.two(v.month);
    yy.text = GB.two(v.year % 100);
    hh.text = GB.two(v.hour);
    mi.text = GB.two(v.minute);
  }

  /// Ngày giờ đang gõ, hoặc null nếu chưa hợp lệ.
  DateTime? get parsed {
    final d = int.tryParse(dd.text), m = int.tryParse(mo.text), y = int.tryParse(yy.text);
    final h = widget.timeToo ? int.tryParse(hh.text) : widget.initial.hour;
    final n = widget.timeToo ? int.tryParse(mi.text) : widget.initial.minute;
    if (d == null || m == null || y == null || h == null || n == null) return null;
    if (m < 1 || m > 12 || d < 1 || h < 0 || h > 23 || n < 0 || n > 59) return null;
    final v = DateTime(2000 + y, m, d, h, n);
    if (v.day != d || v.month != m) return null; // ví dụ 31/02
    return v;
  }

  String? get error {
    final v = parsed;
    if (v == null) return 'Ngày giờ chưa đúng, hãy kiểm tra lại';
    if (widget.timeToo) {
      if (v.isAfter(widget.last.add(const Duration(minutes: 1)))) {
        return widget.last.isAfter(DateTime.now().add(const Duration(days: 1))) ? 'Ngày này còn quá xa' : 'Không chọn được thời điểm ở tương lai';
      }
      if (v.isBefore(widget.first)) return 'Ngày này quá xa trong quá khứ';
    } else {
      final dOnly = DateTime(v.year, v.month, v.day);
      if (dOnly.isAfter(DateTime(widget.last.year, widget.last.month, widget.last.day))) {
        return widget.last.isAfter(DateTime.now().add(const Duration(days: 1))) ? 'Ngày này còn quá xa' : 'Không chọn được ngày ở tương lai';
      }
      if (dOnly.isBefore(DateTime(widget.first.year, widget.first.month, widget.first.day))) return 'Ngày này quá xa trong quá khứ';
    }
    return null;
  }

  void _set(DateTime v) {
    var x = v;
    if (x.isAfter(widget.last)) x = widget.last;
    if (x.isBefore(widget.first)) x = widget.first;
    lastGood = x;
    setState(() => _fill(x));
  }

  DateTime get _base => parsed ?? lastGood;

  void _onChanged(FocusNode? next, TextEditingController c, int len) {
    if (c.text.length >= len && next != null) next.requestFocus();
    final v = parsed;
    if (v != null) lastGood = v;
    setState(() {});
  }

  Widget _box(TextEditingController c, FocusNode f, String hint, {FocusNode? next}) {
    return SizedBox(
      width: 42,
      height: 56,
      child: TextField(
        controller: c,
        focusNode: f,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        textInputAction: next == null ? TextInputAction.done : TextInputAction.next,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
        style: GB.display(22, w: FontWeight.w700),
        cursorColor: GB.accentDeep,
        onChanged: (_) => _onChanged(next, c, 2),
        onTap: () => c.selection = TextSelection(baseOffset: 0, extentOffset: c.text.length),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GB.display(20, w: FontWeight.w600, color: GB.inkMuted.withValues(alpha: .4)),
          filled: true,
          fillColor: GB.card,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: GB.edgeOf(GB.line), width: 1.3)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: GB.edgeOf(GB.line), width: 1.3)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: GB.accent, width: 2)),
        ),
      ),
    );
  }

  Widget _sep(String s) => SizedBox(width: 14, child: Center(child: Text(s, style: GB.display(22, color: GB.inkMuted))));

  Widget _line(String label, List<Widget> boxes, VoidCallback minus, VoidCallback plus, String minusLabel, String plusLabel) {
    return Row(children: [
      SizedBox(width: 42, child: Text(label, style: GB.body(12.5, w: FontWeight.w700, color: GB.inkMuted))),
      ...boxes,
      const Spacer(),
      RoundIconButton(icon: Icons.remove_rounded, label: minusLabel, size: 34, onTap: minus),
      const SizedBox(width: 6),
      RoundIconButton(icon: Icons.add_rounded, label: plusLabel, size: 34, filled: true, onTap: plus),
    ]);
  }

  List<(String, DateTime)> _chips() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, widget.initial.hour, widget.initial.minute);
    final canFuture = widget.last.isAfter(now.add(const Duration(days: 1)));
    if (widget.timeToo) {
      return [
        ('Bây giờ', now),
        ('5p trước', now.subtract(const Duration(minutes: 5))),
        ('15p trước', now.subtract(const Duration(minutes: 15))),
        ('30p trước', now.subtract(const Duration(minutes: 30))),
        ('1h trước', now.subtract(const Duration(hours: 1))),
        if (!canFuture) ('Hôm qua', _base.subtract(const Duration(days: 1))),
        if (canFuture) ('Ngày mai', _base.add(const Duration(days: 1))),
        if (canFuture) ('Tuần sau', _base.add(const Duration(days: 7))),
      ];
    }
    return [
      ('Hôm nay', today),
      ('Hôm qua', today.subtract(const Duration(days: 1))),
      ('Tuần trước', today.subtract(const Duration(days: 7))),
      if (canFuture) ('Ngày mai', today.add(const Duration(days: 1))),
      if (canFuture) ('Tuần sau', today.add(const Duration(days: 7))),
      if (canFuture) ('Tháng sau', DateTime(today.year, today.month + 1, today.day)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final v = parsed;
    final err = error;
    final weekday = v == null ? '' : const ['Chủ nhật', 'Thứ hai', 'Thứ ba', 'Thứ tư', 'Thứ năm', 'Thứ sáu', 'Thứ bảy'][v.weekday % 7];
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(widget.title, style: GB.display(20, w: FontWeight.w700)),
      const SizedBox(height: 4),
      Text(v == null ? 'dd/mm/yy${widget.timeToo ? ' hh:mm' : ''}' : '$weekday · ${widget.timeToo ? GB.dmyhm(v) : GB.dmy(v)}', style: GB.body(13.5, w: FontWeight.w700, color: err == null ? GB.accentDeep : GB.alert)),
      const SizedBox(height: 14),
      _line(
        'Ngày',
        [_box(dd, fDd, 'dd', next: fMo), _sep('/'), _box(mo, fMo, 'mm', next: fYy), _sep('/'), _box(yy, fYy, 'yy', next: widget.timeToo ? fHh : null)],
        () => _set(_base.subtract(const Duration(days: 1))),
        () => _set(_base.add(const Duration(days: 1))),
        'Lùi 1 ngày',
        'Tới 1 ngày',
      ),
      if (widget.timeToo) ...[
        const SizedBox(height: 10),
        _line(
          'Giờ',
          [_box(hh, fHh, 'hh', next: fMi), _sep(':'), _box(mi, fMi, 'mm')],
          () => _set(_base.subtract(const Duration(minutes: 5))),
          () => _set(_base.add(const Duration(minutes: 5))),
          'Lùi 5 phút',
          'Tới 5 phút',
        ),
      ],
      const SizedBox(height: 14),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final c in _chips()) PillChip(label: c.$1, on: false, height: 40, onTap: () => _set(c.$2)),
      ]),
      if (err != null) ...[
        const SizedBox(height: 10),
        Text(err, style: GB.body(12.5, w: FontWeight.w700, color: GB.alert)),
      ],
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: BigButton('Xong', icon: Icons.check_rounded, enabled: err == null, height: 52, onTap: () => Navigator.pop(context, parsed))),
        const SizedBox(width: 10),
        RoundIconButton(icon: Icons.close_rounded, label: 'Huỷ', size: 52, onTap: () => Navigator.pop(context)),
      ]),
    ]);
  }
}
