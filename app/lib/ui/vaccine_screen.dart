import 'package:flutter/material.dart';

import '../core/kit.dart';
import '../core/pickers.dart';
import '../core/theme.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import '../domain/vaccines.dart';

enum VStatus { done, overdue, due, soon, later }

class VaxView {
  VaxView(this.v, this.status, this.dueDate, this.rec);
  final Vax v;
  final VStatus status;
  final DateTime dueDate;
  final VaxRecord? rec;
}

List<VaxView> vaccineViews() {
  final dob = app.baby!.dob;
  final now = DateTime.now();
  return kVaccines.map((v) {
    final due = DateTime(dob.year, dob.month, dob.day).add(Duration(days: v.dueDays));
    final rec = app.vax[v.id];
    VStatus s;
    if (rec != null) {
      s = VStatus.done;
    } else if (now.isAfter(due.add(Duration(days: v.windowDays)))) {
      s = VStatus.overdue;
    } else if (!now.isBefore(due)) {
      s = VStatus.due;
    } else if (due.difference(now).inDays <= 14) {
      s = VStatus.soon;
    } else {
      s = VStatus.later;
    }
    return VaxView(v, s, due, rec);
  }).toList();
}

/// Mũi tiêm TCMR cần nhắc (đến hạn hoặc quá hạn, hoặc trong 7 ngày tới).
VaxView? nextVaccineReminder() {
  final l = vaccineViews().where((x) => x.v.epi && (x.status == VStatus.due || x.status == VStatus.overdue || (x.status == VStatus.soon && x.dueDate.difference(DateTime.now()).inDays <= 7))).toList();
  if (l.isEmpty) return null;
  l.sort((a, b) => a.dueDate.compareTo(b.dueDate));
  return l.first;
}

class VaccineScreen extends StatefulWidget {
  const VaccineScreen({super.key});

  @override
  State<VaccineScreen> createState() => _VaccineScreenState();
}

class _VaccineScreenState extends State<VaccineScreen> {
  int filter = 0; // 0 tất cả, 1 TCMR, 2 dịch vụ, 3 chưa tiêm

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        var all = vaccineViews();
        final overdue = all.where((x) => x.status == VStatus.overdue).length;
        final dueNow = all.where((x) => x.status == VStatus.due).toList();
        final doneCount = all.where((x) => x.status == VStatus.done).length;
        final upcoming = all.where((x) => x.status == VStatus.soon || x.status == VStatus.later).toList()..sort((a, b) => a.dueDate.compareTo(b.dueDate));
        if (filter == 1) all = all.where((x) => x.v.epi).toList();
        if (filter == 2) all = all.where((x) => !x.v.epi).toList();
        if (filter == 3) all = all.where((x) => x.status != VStatus.done).toList();
        final groups = <int, List<VaxView>>{};
        for (final x in all) {
          groups.putIfAbsent(x.v.dueDays, () => []).add(x);
        }
        final keys = groups.keys.toList()..sort();
        return SubPage(
          title: 'Tiêm chủng',
          subtitle: 'Đã tiêm $doneCount/${kVaccines.length} mũi · bảo vệ con từng bước',
          art: 'hero_baby_awake',
          artWidth: 110,
          children: [
            if (overdue + dueNow.length > 0)
              Callout(
                level: overdue > 0 ? Level.alert : Level.note,
                title: overdue > 0 ? '$overdue mũi đã quá lịch' : '${dueNow.length} mũi đến hạn',
                body: overdue > 0 ? 'Hãy liên hệ cơ sở tiêm chủng để được tiêm bù. Bé không cần tiêm lại từ đầu.' : 'Đã tới tuổi tiêm. Mẹ đặt lịch tại trạm y tế hoặc trung tâm tiêm chủng.',
              )
            else if (upcoming.isNotEmpty)
              Callout(level: Level.info, title: 'Mũi tiếp theo: ${upcoming.first.v.name}', body: 'Dự kiến ${GB.dmy(upcoming.first.dueDate)} (${vaxAgeLabel(upcoming.first.v.dueDays)}).'),
            if (overdue + dueNow.length > 0) ...[
              const SizedBox(height: 10),
              GlassCard(
                radius: 20,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                onTap: () async {
                  final ok = await confirmDialog(context, 'Bé đã tiêm đủ lịch TCMR đến hiện tại?', 'App sẽ đánh dấu mọi mũi TCMR đã đến hạn là đã tiêm đúng ngày dự kiến. Mẹ có thể sửa ngày hoặc bỏ đánh dấu từng mũi sau.', ok: 'Đánh dấu');
                  if (ok) {
                    for (final x in vaccineViews().where((x) => x.v.epi && (x.status == VStatus.overdue || x.status == VStatus.due))) {
                      app.setVax(x.v.id, VaxRecord(date: x.dueDate.isAfter(DateTime.now()) ? DateTime.now() : x.dueDate));
                    }
                  }
                },
                child: Row(children: [
                  Icon(Icons.done_all_rounded, color: GB.accentDeep),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Bé đã tiêm đủ lịch? Đánh dấu nhanh các mũi TCMR đến hạn', style: GB.body(13.5, w: FontWeight.w700))),
                ]),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                for (var i = 0; i < 4; i++) ...[PillChip(label: const ['Tất cả', 'TCMR (miễn phí)', 'Dịch vụ', 'Chưa tiêm'][i], on: filter == i, height: 44, onTap: () => setState(() => filter = i)), const SizedBox(width: 8)],
              ]),
            ),
            for (final k in keys) ...[
              SectionTitle(vaxAgeLabel(k), padTop: 16),
              GlassCard(
                radius: 22,
                padding: EdgeInsets.zero,
                child: Column(children: [for (var i = 0; i < groups[k]!.length; i++) _row(groups[k]![i], i == 0)]),
              ),
            ],
            const SizedBox(height: 12),
            Text('$kVaxSource Nhóm dịch vụ chỉ là gợi ý tham khảo, không bắt buộc. Cần chuyên gia duyệt.', style: GB.body(11.5, color: GB.inkMuted, height: 1.4)),
          ],
        );
      },
    );
  }

  Widget _row(VaxView x, bool first) {
    late String label;
    late Color bg, fg;
    switch (x.status) {
      case VStatus.done:
        label = 'Đã tiêm ${GB.dmy(x.rec!.date)}';
        bg = GB.okBg;
        fg = GB.ok;
      case VStatus.overdue:
        label = 'Quá lịch';
        bg = GB.alertBg;
        fg = GB.alert;
      case VStatus.due:
        label = 'Đến hạn';
        bg = GB.warnBg;
        fg = GB.warn;
      case VStatus.soon:
        label = 'Sắp tới ${GB.dmy(x.dueDate)}';
        bg = GB.infoBg;
        fg = GB.info;
      case VStatus.later:
        label = GB.dmy(x.dueDate);
        bg = GB.w(.7);
        fg = GB.inkMuted;
    }
    return InkWell(
      onTap: () => _sheet(x),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(border: first ? null : Border(top: BorderSide(color: GB.f(Color(0xFF785A46)).withValues(alpha: .10)))),
        child: Row(children: [
          Icon(x.status == VStatus.done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: x.status == VStatus.done ? GB.ok : GB.inkMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(x.v.name, style: GB.body(14.5, w: FontWeight.w700)),
              Text(x.v.disease, style: GB.body(12, color: GB.inkMuted, height: 1.3)),
              const SizedBox(height: 4),
              Row(children: [Tag(x.v.epi ? 'TCMR' : 'Dịch vụ', bg: x.v.epi ? GB.okBg : GB.infoBg, fg: x.v.epi ? GB.ok : GB.info)]),
            ]),
          ),
          const SizedBox(width: 8),
          Tag(label, bg: bg, fg: fg),
        ]),
      ),
    );
  }

  void _sheet(VaxView x) {
    showGlassSheet(context, builder: (ctx) {
      var date = x.rec?.date ?? DateTime.now();
      final place = TextEditingController(text: x.rec?.place ?? '');
      final lot = TextEditingController(text: x.rec?.lot ?? '');
      final note = TextEditingController(text: x.rec?.note ?? '');
      return StatefulBuilder(builder: (ctx, setS) {
        return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(x.v.name, style: GB.display(22, w: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('${x.v.disease} · dự kiến ${GB.dmy(x.dueDate)} (${vaxAgeLabel(x.v.dueDays)})', style: GB.body(13, color: GB.inkMuted)),
          if (x.v.note.isNotEmpty) ...[const SizedBox(height: 8), Callout(level: Level.info, title: x.v.note)],
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () async {
              final d = await pickDateTime(ctx, date, timeToo: false, last: DateTime.now());
              if (d != null) setS(() => date = d);
            },
            child: GlassCard(radius: 18, padding: const EdgeInsets.all(14), blur: 12, child: Row(children: [const Icon(Icons.event_available_rounded), const SizedBox(width: 10), Expanded(child: Text('Ngày tiêm ${GB.dmy(date)}', style: GB.body(14.5, w: FontWeight.w700))), Text('Sửa', style: GB.body(13, w: FontWeight.w700, color: GB.accentDeep))])),
          ),
          const SizedBox(height: 10),
          GlassField(controller: place, label: 'Nơi tiêm (tuỳ chọn)'),
          const SizedBox(height: 10),
          GlassField(controller: lot, label: 'Số lô (tuỳ chọn)'),
          const SizedBox(height: 10),
          GlassField(controller: note, label: 'Ghi chú, phản ứng sau tiêm (tuỳ chọn)', maxLines: 2),
          const SizedBox(height: 16),
          BigButton(x.rec == null ? 'Đánh dấu đã tiêm' : 'Lưu', icon: Icons.check_rounded, onTap: () {
            app.setVax(x.v.id, VaxRecord(date: date, place: place.text.trim(), lot: lot.text.trim(), note: note.text.trim()));
            Navigator.pop(ctx);
          }),
          if (x.rec != null) ...[
            const SizedBox(height: 10),
            BigButton('Bỏ đánh dấu', icon: Icons.undo_rounded, color: GB.alertBg, fg: GB.alert, onTap: () {
              app.setVax(x.v.id, null);
              Navigator.pop(ctx);
            }),
          ],
        ]);
      });
    });
  }
}
