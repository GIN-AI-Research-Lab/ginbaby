import 'package:flutter/material.dart';

import '../core/kit.dart';
import '../core/theme.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import 'vaccine_screen.dart';
import 'widgets.dart';

const _wd = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
const _wdFull = ['Thứ hai', 'Thứ ba', 'Thứ tư', 'Thứ năm', 'Thứ sáu', 'Thứ bảy', 'Chủ nhật'];

/// Các loại việc đã ghi trong một ngày (để chấm màu trên lịch).
Set<String> _kinds(Iterable<Entry> es) {
  final out = <String>{};
  for (final e in es) {
    switch (e.type) {
      case T.feed:
        out.add('feed');
      case T.pump:
        out.add('pump');
      case T.sleep:
        out.add('sleep');
      case T.diaper:
        out.add('diaper');
      default:
        out.add('other');
    }
  }
  return out;
}

Color _kindDot(String k) => switch (k) {
      'feed' => GB.bottleDeep,
      'pump' => GB.pumpDeep,
      'sleep' => GB.sleepDeep,
      'diaper' => const Color(0xFFD9A441),
      _ => GB.inkMuted,
    };

/// Lịch cả tháng: chấm màu theo việc đã ghi, dấu ô vuông cho việc cần làm (lịch hẹn, mũi tiêm); chạm một ngày để xem và thêm việc.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, this.initial});
  final DateTime? initial;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime month; // ngày 1 của tháng đang xem
  late DateTime sel; // ngày đang chọn

  @override
  void initState() {
    super.initState();
    final d = AppState.dayStart(widget.initial ?? DateTime.now());
    sel = d;
    month = DateTime(d.year, d.month);
  }

  bool _same(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  /// Mũi tiêm chưa tiêm có hạn rơi vào ngày [d] (chỉ đọc, mở màn Tiêm chủng).
  List<VaxView> _vaxOn(DateTime d) => vaccineViews().where((x) => x.status != VStatus.done && _same(x.dueDate, d)).toList();

  void _go(int delta) => setState(() => month = DateTime(month.year, month.month + delta));

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final today = AppState.dayStart(DateTime.now());
        final first = month;
        final daysIn = DateTime(month.year, month.month + 1, 0).day;
        final lead = first.weekday - 1; // ô trống đầu tháng (T2 là cột đầu)
        final rows = ((lead + daysIn) / 7).ceil();

        // gom việc đã ghi và việc cần làm theo ngày của tháng
        final kinds = <int, Set<String>>{};
        final plans = <int, int>{};
        final end = DateTime(month.year, month.month + 1);
        for (final e in app.entries) {
          if (e.time.isBefore(first) || !e.time.isBefore(end)) continue;
          kinds.putIfAbsent(e.time.day, () => <String>{}).addAll(_kinds([e]));
        }
        for (final a in app.appts) {
          if (a.time.isBefore(first) || !a.time.isBefore(end)) continue;
          plans[a.time.day] = (plans[a.time.day] ?? 0) + 1;
        }
        for (final v in vaccineViews()) {
          if (v.status == VStatus.done || v.dueDate.isBefore(first) || !v.dueDate.isBefore(end)) continue;
          plans[v.dueDate.day] = (plans[v.dueDate.day] ?? 0) + 1;
        }

        Widget cell(int dayNum) {
          final d = DateTime(month.year, month.month, dayNum);
          final isSel = _same(d, sel);
          final isToday = _same(d, today);
          final ks = (kinds[dayNum] ?? const <String>{}).toList()..sort();
          final hasPlan = (plans[dayNum] ?? 0) > 0;
          return Expanded(
            child: Semantics(
              button: true,
              selected: isSel,
              label: 'Ngày $dayNum${isToday ? ', hôm nay' : ''}${hasPlan ? ', có việc cần làm' : ''}',
              child: Pressable(
                scale: .92,
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => sel = d),
                child: Container(
                  height: 54,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSel ? GB.accent : (isToday ? GB.accentSoft : Colors.transparent),
                    borderRadius: BorderRadius.circular(14),
                    border: isToday && !isSel ? Border.all(color: GB.accent, width: 1.4) : null,
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('$dayNum', style: GB.body(15, w: isSel || isToday ? FontWeight.w800 : FontWeight.w600, color: isSel ? Colors.white : GB.ink)),
                    const SizedBox(height: 3),
                    SizedBox(
                      height: 7,
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        for (final k in ks.take(3)) Container(width: 6, height: 6, margin: const EdgeInsets.symmetric(horizontal: 1), decoration: BoxDecoration(color: isSel ? Colors.white : _kindDot(k), shape: BoxShape.circle)),
                        if (hasPlan) Container(width: 6, height: 6, margin: const EdgeInsets.symmetric(horizontal: 1), decoration: BoxDecoration(color: isSel ? Colors.white : GB.accentDeep, borderRadius: BorderRadius.circular(2))),
                      ]),
                    ),
                  ]),
                ),
              ),
            ),
          );
        }

        final weeks = <Widget>[];
        for (var r = 0; r < rows; r++) {
          weeks.add(Row(children: [
            for (var c = 0; c < 7; c++)
              () {
                final n = r * 7 + c - lead + 1;
                return n < 1 || n > daysIn ? Expanded(child: Container(height: 54, margin: const EdgeInsets.all(2))) : cell(n);
              }(),
          ]));
        }

        return SubPage(
          title: 'Lịch',
          subtitle: 'Nhật ký và việc cần làm theo tháng',
          children: [
            GlassCard(
              radius: 26,
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
              child: Column(children: [
                Row(children: [
                  RoundIconButton(icon: Icons.chevron_left_rounded, label: 'Tháng trước', size: 40, onTap: () => _go(-1)),
                  Expanded(
                    child: Center(
                      child: Semantics(
                        header: true,
                        child: Text('Tháng ${month.month}/${month.year}', style: GB.display(20, w: FontWeight.w800)),
                      ),
                    ),
                  ),
                  RoundIconButton(icon: Icons.chevron_right_rounded, label: 'Tháng sau', size: 40, onTap: () => _go(1)),
                ]),
                const SizedBox(height: 8),
                Row(children: [for (final w in _wd) Expanded(child: Center(child: Text(w, style: GB.body(12, w: FontWeight.w700, color: GB.inkMuted))))]),
                const SizedBox(height: 4),
                ...weeks,
                const SizedBox(height: 8),
                Wrap(spacing: 12, runSpacing: 4, alignment: WrapAlignment.center, children: [
                  _legend(_kindDot('feed'), 'Bú'),
                  _legend(_kindDot('pump'), 'Hút'),
                  _legend(_kindDot('sleep'), 'Ngủ'),
                  _legend(_kindDot('diaper'), 'Tã'),
                  _legend(GB.accentDeep, 'Việc cần làm', square: true),
                ]),
              ]),
            ),
            if (!(month.year == today.year && month.month == today.month))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(child: PillChip(label: 'Về hôm nay', icon: Icons.today_rounded, on: false, onTap: () => setState(() {
                      sel = today;
                      month = DateTime(today.year, today.month);
                    }))),
              ),
            const SizedBox(height: 14),
            _dayPanel(context),
          ],
        );
      },
    );
  }

  Widget _legend(Color c, String t, {bool square = false}) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: square ? BoxShape.rectangle : BoxShape.circle, borderRadius: square ? BorderRadius.circular(2) : null)),
        const SizedBox(width: 4),
        Text(t, style: GB.body(11.5, color: GB.inkMuted)),
      ]);

  // ───────── Chi tiết ngày đang chọn: việc cần làm + việc đã ghi
  Widget _dayPanel(BuildContext context) {
    final es = app.entriesOn(sel)..sort((a, b) => a.time.compareTo(b.time));
    final appts = app.appts.where((a) => _same(a.time, sel)).toList()..sort((a, b) => a.time.compareTo(b.time));
    final vax = _vaxOn(sel);
    final feeds = es.where((e) => e.type == T.feed).length;
    final diapers = es.where((e) => e.type == T.diaper).length;
    final sleep = app.sleepOn(sel);
    final title = '${_wdFull[sel.weekday - 1]}, ${GB.dmy(sel)}';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(title, style: GB.display(18, w: FontWeight.w800))),
        PillChip(label: 'Thêm việc', icon: Icons.add_rounded, on: true, onTap: () => _planDialog(context)),
      ]),
      const SizedBox(height: 10),
      GlassCard(
        radius: 22,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.checklist_rounded, size: 20, color: GB.accentDeep),
            const SizedBox(width: 8),
            Text('Việc cần làm', style: GB.body(14.5, w: FontWeight.w800)),
          ]),
          const SizedBox(height: 6),
          if (appts.isEmpty && vax.isEmpty)
            Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('Chưa có việc nào trong ngày này. Bấm "Thêm việc" để lên kế hoạch (đi khám, mua đồ, tiêm…).', style: GB.body(13, color: GB.inkMuted, height: 1.4)))
          else ...[
            for (final v in vax)
              _planRow(
                done: false,
                time: null,
                title: 'Tiêm: ${v.v.name}',
                sub: 'Theo lịch tiêm chủng · chạm để xem',
                icon: Icons.vaccines_rounded,
                onTap: () => openPage(context, const VaccineScreen()),
              ),
            for (final a in appts)
              _planRow(
                done: a.done,
                time: GB.hm(a.time),
                title: a.title,
                sub: [if (a.place.isNotEmpty) a.place, if (a.note.isNotEmpty) a.note].join(' · '),
                icon: Icons.event_rounded,
                onCheck: () {
                  a.done = !a.done;
                  app.apptChanged();
                },
                onTap: () => _planDialog(context, edit: a),
              ),
          ],
        ]),
      ),
      const SizedBox(height: 10),
      GlassCard(
        radius: 22,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.edit_note_rounded, size: 20, color: GB.pumpDeep),
            const SizedBox(width: 8),
            Text('Đã ghi', style: GB.body(14.5, w: FontWeight.w800)),
            const Spacer(),
            if (es.isNotEmpty) Text('$feeds cữ bú · ngủ ${GB.dur(sleep)} · $diapers tã', style: GB.body(12, color: GB.inkMuted)),
          ]),
          const SizedBox(height: 4),
          if (es.isEmpty)
            Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('Chưa ghi gì trong ngày này.', style: GB.body(13, color: GB.inkMuted)))
          else
            for (var i = 0; i < es.length; i++) ...[
              if (i > 0) Divider(height: 1, color: GB.line),
              EntryRow(es[i]),
            ],
        ]),
      ),
      const SizedBox(height: 10),
      Center(
        child: PillChip(label: 'Mở nhật ký ngày này', icon: Icons.receipt_long_rounded, on: false, onTap: () => Navigator.of(context).pop(sel)),
      ),
    ]);
  }

  Widget _planRow({required bool done, required String? time, required String title, required String sub, required IconData icon, VoidCallback? onCheck, required VoidCallback onTap}) {
    return Semantics(
      container: true,
      label: '${time ?? ''} $title${done ? ', đã xong' : ''}',
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            if (onCheck != null)
              Semantics(
                button: true,
                label: done ? 'Bỏ đánh dấu xong' : 'Đánh dấu đã xong',
                child: Pressable(
                  onTap: onCheck,
                  behavior: HitTestBehavior.opaque,
                  child: minHit(Icon(done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, size: 26, color: done ? GB.ok : GB.inkMuted)),
                ),
              )
            else
              SizedBox(width: 44, height: 44, child: Icon(icon, size: 22, color: GB.accentDeep)),
            const SizedBox(width: 4),
            if (time != null) SizedBox(width: 46, child: Text(time, style: GB.body(13, w: FontWeight.w700, color: GB.inkMuted))),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: GB.body(14.5, w: FontWeight.w700, color: done ? GB.inkMuted : GB.ink).copyWith(decoration: done ? TextDecoration.lineThrough : null)),
                if (sub.isNotEmpty) Text(sub, style: GB.body(12, color: GB.inkMuted)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  /// Thêm hoặc sửa một việc cần làm (sửa thì có thêm nút Xoá).
  Future<void> _planDialog(BuildContext context, {Appointment? edit}) async {
    final title = TextEditingController(text: edit?.title ?? '');
    final place = TextEditingController(text: edit?.place ?? '');
    final note = TextEditingController(text: edit?.note ?? '');
    var time = edit?.time ?? DateTime(sel.year, sel.month, sel.day, 9);
    final r = await showGlassSheet<String>(context, builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setS) {
        return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(edit == null ? 'Thêm việc cần làm' : 'Sửa việc', style: GB.display(22, w: FontWeight.w700)),
          const SizedBox(height: 12),
          GlassField(controller: title, label: 'Việc cần làm', hint: 'Đi khám nhi, mua tã, tiêm mũi 5 trong 1…', icon: Icons.checklist_rounded),
          const SizedBox(height: 10),
          TimeRow(label: 'Thời gian', time: time, onChanged: (v) => setS(() => time = v)),
          const SizedBox(height: 10),
          GlassField(controller: place, label: 'Nơi (không bắt buộc)', icon: Icons.place_rounded),
          const SizedBox(height: 10),
          GlassField(controller: note, label: 'Ghi chú (không bắt buộc)', icon: Icons.notes_rounded),
          const SizedBox(height: 16),
          Row(children: [
            if (edit != null) ...[
              Expanded(child: BigButton('Xoá', icon: Icons.delete_outline_rounded, color: GB.w(.75), fg: GB.alert, onTap: () => Navigator.pop(ctx, 'delete'))),
              const SizedBox(width: 10),
            ],
            Expanded(flex: 2, child: BigButton('Lưu', icon: Icons.check_rounded, onTap: () => Navigator.pop(ctx, 'save'))),
          ]),
        ]);
      });
    });
    if (r == 'delete' && edit != null) {
      app.removeAppt(edit.id);
    } else if (r == 'save') {
      if (title.text.trim().isEmpty) return;
      if (edit == null) {
        app.addAppt(Appointment(time: time, title: title.text.trim(), place: place.text.trim(), note: note.text.trim()));
      } else {
        edit
          ..time = time
          ..title = title.text.trim()
          ..place = place.text.trim()
          ..note = note.text.trim();
        app.apptChanged();
      }
      setState(() => sel = AppState.dayStart(time)); // chuyển tới ngày vừa đặt để thấy ngay
      if (time.month != month.month || time.year != month.year) setState(() => month = DateTime(time.year, time.month));
    }
  }
}
