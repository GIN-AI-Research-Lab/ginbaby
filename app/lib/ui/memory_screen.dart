import 'package:flutter/cupertino.dart' show CupertinoPageRoute;
import 'package:flutter/material.dart';

import '../core/capture.dart';
import '../core/kit.dart';
import '../core/pastel.dart';
import '../core/pickers.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import '../domain/age.dart';
import '../domain/memories.dart';
import 'health_hub.dart';
import 'quick_logs.dart';

DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Ngày của một mốc theo ngày tuổi.
DateTime dayMarkDate(DayMark m) => _dayOnly(app.baby!.dob).add(Duration(days: m.days));

/// Nhật ký mốc: các mốc đáng nhớ của bé, kèm ảnh và thẻ chia sẻ.
class MemoryJournalScreen extends StatelessWidget {
  const MemoryJournalScreen({super.key});

  void _edit(BuildContext context, String key, String title, {DateTime? date, bool custom = false}) =>
      openPage(context, MemoryEditScreen(memoKey: key, title: title, suggested: date, custom: custom));

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final baby = app.baby!;
        final today = _dayOnly(DateTime.now());
        final list = app.memos.values.toList()..sort((a, b) => b.date.compareTo(a.date));
        final upcoming = [
          for (final d in kDayMarks)
            if (dayMarkDate(d).isAfter(today.subtract(const Duration(days: 1))) && !app.memos.containsKey(d.id)) d,
        ];
        final next = upcoming.isEmpty ? null : upcoming.first;

        return SubPage(
          title: 'Nhật ký mốc',
          subtitle: 'Giữ lại khoảnh khắc đầu đời của ${baby.name}',
          titleArt: 'ic_milestone',
          children: [
            GlassCard(
              radius: 26,
              child: Row(children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: GB.accentSoft, shape: BoxShape.circle, border: Border.all(color: GB.edgeOf(GB.accentSoft), width: 1.2)),
                  child: Text('${list.length}', style: GB.display(26, color: GB.accentDeep)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('kỷ niệm đã lưu', style: GB.body(15, w: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                      next == null ? '${baby.name} ${Age(baby).label} tuổi' : 'Còn ${dayMarkDate(next).difference(today).inDays} ngày nữa là ${next.title.toLowerCase()} của ${baby.name}',
                      style: GB.body(12.5, color: GB.inkMuted, height: 1.35),
                    ),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            const FormHeader('Mốc ngày đặc biệt', Icons.event_available_rounded, color: Color(0xFFF8E9A8), hint: 'Đầy tháng, trăm ngày, thôi nôi…'),
            for (final d in kDayMarks) ...[
              _dayRow(context, d, today),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 6),
            const FormHeader('Lần đầu của bé', Icons.auto_awesome_rounded, color: Color(0xFFE6DEF5), hint: 'Chạm để ghi lại khi bé làm được'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final f in kFirsts)
                PillChip(
                  label: f.title,
                  on: app.memos.containsKey(f.id),
                  color: f.color,
                  icon: app.memos.containsKey(f.id) ? Icons.check_circle_rounded : f.icon,
                  iconColor: GB.accentDeep,
                  height: 40,
                  onTap: () => _edit(context, f.id, f.title),
                ),
              PillChip(label: 'Mốc riêng', on: false, icon: Icons.add_rounded, iconColor: GB.accentDeep, height: 40, onTap: () => _edit(context, 'c_${uid()}', '', custom: true)),
            ]),
            if (list.isNotEmpty) ...[
              const SizedBox(height: 18),
              const FormHeader('Dòng thời gian', Icons.photo_library_rounded, color: Color(0xFFDCEBF5), hint: 'Chạm để sửa, nút chia sẻ để tạo thẻ'),
              for (final m in list) ...[
                _memoRow(context, m),
                const SizedBox(height: 8),
              ],
            ],
            const SizedBox(height: 10),
            GlassCard(
              radius: 22,
              onTap: () => openPage(context, const HealthHub(initial: 3)),
              child: Row(children: [
                IconBadge(icon: Icons.fact_check_rounded, bg: const Color(0xFFE4EBD2), fg: GB.ink, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Mốc phát triển theo tháng tuổi', style: GB.body(14, w: FontWeight.w800)),
                    Text('Danh sách mốc tham khảo (CDC) để mẹ đánh dấu', style: GB.body(11.5, color: GB.inkMuted)),
                  ]),
                ),
                Icon(Icons.chevron_right_rounded, color: GB.inkMuted),
              ]),
            ),
          ],
        );
      },
    );
  }

  Widget _dayRow(BuildContext context, DayMark d, DateTime today) {
    final date = dayMarkDate(d);
    final left = date.difference(today).inDays;
    final memo = app.memos[d.id];
    final reached = left <= 0;
    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      onTap: () {
        if (!reached && memo == null) {
          toast(context, 'Còn $left ngày nữa mới tới ${d.title.toLowerCase()}');
          return;
        }
        _edit(context, d.id, d.title, date: date);
      },
      child: Row(children: [
        memo?.photo != null && app.photo(memo!.photo!) != null
            ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.memory(app.photo(memo.photo!)!, width: 46, height: 46, fit: BoxFit.cover))
            : IconBadge(icon: d.icon, bg: d.color, fg: GB.ink, size: 46),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d.title, style: GB.body(14.5, w: FontWeight.w800)),
            Text(left > 0 ? '${GB.dmy(date)} · còn $left ngày' : GB.dmy(date), style: GB.body(12, color: GB.inkMuted)),
          ]),
        ),
        if (memo != null)
          const Tag('Đã lưu')
        else if (reached)
          const SoftPill('Lưu kỷ niệm', arrow: false)
        else
          Icon(Icons.lock_clock_rounded, color: GB.inkMuted, size: 22),
      ]),
    );
  }

  Widget _memoRow(BuildContext context, MilestoneMemo m) {
    final st = memoStyle(m.key);
    final bytes = m.photo == null ? null : app.photo(m.photo!);
    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
      onTap: () => openPage(context, MemoryEditScreen(memoKey: m.key, title: m.title, custom: m.custom)),
      child: Row(children: [
        bytes != null ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.memory(bytes, width: 58, height: 58, fit: BoxFit.cover)) : IconBadge(icon: st.icon, bg: st.color, fg: GB.ink, size: 58),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GB.body(14.5, w: FontWeight.w800)),
            Text('${GB.dmy(m.date)} · ${Age(app.baby!, m.date).short}', style: GB.body(12, color: GB.inkMuted)),
            if (m.note.isNotEmpty) Text(m.note, maxLines: 1, overflow: TextOverflow.ellipsis, style: GB.body(12, color: GB.inkMuted)),
          ]),
        ),
        RoundIconButton(icon: Icons.ios_share_rounded, label: 'Tạo thẻ chia sẻ', size: 40, iconColor: GB.accentDeep, onTap: () => openPage(context, MemoryCardScreen(m))),
      ]),
    );
  }
}

/// Ghi hoặc sửa kỷ niệm của một mốc: ngày, ảnh, ghi chú.
class MemoryEditScreen extends StatefulWidget {
  const MemoryEditScreen({super.key, required this.memoKey, required this.title, this.suggested, this.custom = false});
  final String memoKey;
  final String title;
  final DateTime? suggested;
  final bool custom;

  @override
  State<MemoryEditScreen> createState() => _MemoryEditScreenState();
}

class _MemoryEditScreenState extends State<MemoryEditScreen> {
  late final TextEditingController title;
  late final TextEditingController note;
  late DateTime date;
  String? photo;
  MilestoneMemo? existing;

  @override
  void initState() {
    super.initState();
    existing = app.memos[widget.memoKey];
    title = TextEditingController(text: existing?.title ?? widget.title);
    note = TextEditingController(text: existing?.note ?? '');
    final today = _dayOnly(DateTime.now());
    final s = widget.suggested;
    date = existing?.date ?? (s != null && !s.isAfter(today) ? s : today);
    photo = existing?.photo;
  }

  @override
  void dispose() {
    title.dispose();
    note.dispose();
    super.dispose();
  }

  void _save() {
    final t = title.text.trim();
    if (t.isEmpty) {
      toast(context, 'Nhập tên mốc');
      return;
    }
    final memo = MilestoneMemo(key: widget.memoKey, title: t, date: date, note: note.text.trim(), photo: photo, custom: widget.custom || (existing?.custom ?? false));
    final isNew = existing == null;
    app.saveMemo(memo);
    if (isNew) {
      // Lưu lần đầu thì mở luôn thẻ chia sẻ cho mẹ
      Navigator.of(context).pushReplacement(CupertinoPageRoute<void>(builder: (_) => MemoryCardScreen(memo)));
    } else {
      Navigator.of(context).pop();
      toast(context, 'Đã lưu kỷ niệm');
    }
  }

  Future<void> _pickDate() async {
    final d = await pickDateTime(context, date, timeToo: false, last: DateTime.now(), title: 'Ngày xảy ra');
    if (d != null) setState(() => date = _dayOnly(d));
  }

  @override
  Widget build(BuildContext context) {
    final st = memoStyle(widget.memoKey);
    final bytes = photo == null ? null : app.photo(photo!);
    return SubPage(
      title: existing == null ? 'Ghi kỷ niệm' : 'Sửa kỷ niệm',
      titleArt: 'ic_camera',
      actions: [
        if (existing != null)
          RoundIconButton(icon: Icons.delete_outline_rounded, label: 'Xoá kỷ niệm', size: 44, onTap: () async {
            if (await confirmDialog(context, 'Xoá kỷ niệm này?', 'Ảnh và ghi chú của kỷ niệm sẽ bị xoá.')) {
              app.removeMemo(widget.memoKey);
              if (context.mounted) Navigator.of(context).pop();
            }
          }),
      ],
      bottom: BigButton('Lưu kỷ niệm', icon: Icons.check_rounded, onTap: _save),
      children: [
        GlassCard(
          radius: 24,
          padding: const EdgeInsets.all(14),
          child: widget.custom
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const FormHeader('Tên mốc', Icons.flag_rounded, color: Color(0xFFF8DEDF), hint: 'Ví dụ: Lần đầu gặp ông bà'),
                  GlassField(controller: title, label: 'Tên mốc', icon: Icons.favorite_rounded),
                ])
              : Row(children: [
                  IconBadge(icon: st.icon, bg: st.color, fg: GB.ink, size: 48),
                  const SizedBox(width: 12),
                  Expanded(child: Text(widget.title, style: GB.display(20, w: FontWeight.w700))),
                ]),
        ),
        const SizedBox(height: 12),
        GlassCard(
          radius: 24,
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const FormHeader('Ngày', Icons.event_rounded, color: Color(0xFFDCEBF5)),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(color: GB.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: GB.edgeOf(GB.line), width: 1.3)),
                child: Row(children: [
                  Icon(Icons.today_rounded, color: GB.info),
                  const SizedBox(width: 12),
                  Expanded(child: Text('${GB.dmy(date)} · bé ${Age(app.baby!, date).short}', style: GB.body(15, w: FontWeight.w700))),
                  Text('Sửa', style: GB.body(13, w: FontWeight.w700, color: GB.accentDeep)),
                ]),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        GlassCard(
          radius: 24,
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const FormHeader('Ảnh', Icons.photo_camera_rounded, color: Color(0xFFFCE0E2), hint: 'Ảnh sẽ nằm trên thẻ chia sẻ'),
            if (bytes != null)
              Stack(clipBehavior: Clip.none, children: [
                ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.memory(bytes, width: double.infinity, height: 220, fit: BoxFit.cover)),
                Positioned(
                  right: 8,
                  top: 8,
                  child: RoundIconButton(icon: Icons.close_rounded, label: 'Bỏ ảnh', size: 36, onTap: () => setState(() => photo = null)),
                ),
              ])
            else
              AddPhotoButton(size: 96, onTap: () async {
                final id = await pickAndStorePhoto(context);
                if (id != null) setState(() => photo = id);
              }),
          ]),
        ),
        const SizedBox(height: 12),
        GlassCard(
          radius: 24,
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const FormHeader('Ghi chú', Icons.edit_note_rounded, color: Color(0xFFFBE3CF), hint: 'Cảm xúc, ai có mặt, bé làm gì…'),
            GlassField(controller: note, label: 'Ghi chú ngắn', maxLines: 3, icon: Icons.edit_note_rounded),
          ]),
        ),
        if (existing != null) ...[
          const SizedBox(height: 14),
          BigButton('Tạo thẻ chia sẻ', icon: Icons.ios_share_rounded, color: GB.w(.75), fg: GB.ink, onTap: () {
            final m = app.memos[widget.memoKey];
            if (m != null) openPage(context, MemoryCardScreen(m));
          }),
        ],
      ],
    );
  }
}

class _CardTheme {
  const _CardTheme(this.name, this.bg, this.fg, this.card, this.accent, this.muted);
  final String name;
  final Color bg;
  final Color fg;
  final Color card;
  final Color accent;
  final Color muted;
}

/// Thẻ kỷ niệm để chia sẻ (xuất ảnh PNG), có ảnh bé hoặc tranh màu nước nếu chưa có ảnh.
class MemoryCardScreen extends StatefulWidget {
  const MemoryCardScreen(this.memo, {super.key});
  final MilestoneMemo memo;

  @override
  State<MemoryCardScreen> createState() => _MemoryCardScreenState();
}

class _MemoryCardScreenState extends State<MemoryCardScreen> {
  final key = GlobalKey();
  int themeIdx = 0;
  bool busy = false;

  // Thẻ là ảnh chia sẻ nên dùng màu cố định, không đổi theo chế độ sáng/tối của app.
  static const themes = [
    _CardTheme('Hồng', Color(0xFFF6B9BD), Color(0xFF2B2634), Color(0xFFFFFBF8), Color(0xFF8B2F33), Color(0xFF6F6470)),
    _CardTheme('Kem', Color(0xFFFCEDE6), Color(0xFF2B2634), Colors.white, Color(0xFFE5666F), Color(0xFF6F6470)),
    _CardTheme('Tím', Color(0xFFD9D2F0), Color(0xFF2B2634), Color(0xFFFBF9FF), Color(0xFF5B4B9A), Color(0xFF6A6285)),
    _CardTheme('Xanh', Color(0xFFCFE6DA), Color(0xFF263A31), Color(0xFFF7FCF9), Color(0xFF3F7A5E), Color(0xFF5E7568)),
  ];

  Future<void> _export() async {
    setState(() => busy = true);
    final png = await capturePng(key, pixelRatio: 3);
    setState(() => busy = false);
    if (png == null || !mounted) return;
    final slug = widget.memo.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    final name = 'ginbaby-ky-niem-$slug.png';
    if (await shareFileBytes(name, png, 'image/png', title: widget.memo.title)) return;
    downloadBytes(name, png, 'image/png');
    if (mounted) toast(context, kIsWebPlatform ? 'Đã tải thẻ kỷ niệm' : 'Chỉ hỗ trợ lưu ảnh trên bản web');
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.memo;
    final baby = app.baby!;
    final t = themes[themeIdx];
    final bytes = m.photo == null ? null : app.photo(m.photo!);
    return SubPage(
      title: 'Thẻ kỷ niệm',
      subtitle: m.title,
      titleArt: 'ic_milestone',
      bottom: BigButton(busy ? 'Đang tạo ảnh…' : 'Lưu ảnh', icon: Icons.ios_share_rounded, onTap: busy ? null : _export),
      children: [
        Center(
          child: RepaintBoundary(
            key: key,
            child: Container(
              width: 350,
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
              decoration: BoxDecoration(color: t.bg, borderRadius: BorderRadius.circular(32)),
              child: Column(children: [
                Row(children: [
                  Expanded(child: Text('GinBaby', style: GB.display(18, color: t.fg))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(14)),
                    child: Text(GB.dmy(m.date), style: GB.body(12.5, w: FontWeight.w700, color: t.fg)),
                  ),
                ]),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .10), blurRadius: 14, offset: const Offset(0, 6))]),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 270,
                      child: bytes != null
                          ? Image.memory(bytes, fit: BoxFit.cover, alignment: Alignment.topCenter)
                          : Container(color: t.bg.withValues(alpha: .35), padding: const EdgeInsets.all(14), child: Art(m.key.startsWith('d_') ? 'hero_mom_baby' : 'hero_baby_awake', plate: false)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(m.title, textAlign: TextAlign.center, style: GB.display(28, color: t.accent)),
                const SizedBox(height: 4),
                Text('${baby.name} · ${Age(baby, m.date).label}', textAlign: TextAlign.center, style: GB.body(14, w: FontWeight.w700, color: t.fg)),
                if (m.note.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('“${m.note}”', textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis, style: GB.body(13, color: t.muted, height: 1.4)),
                ],
                const SizedBox(height: 14),
                Text('Ghi lại cùng GinBaby', style: GB.body(11.5, color: t.muted)),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Text('Mẫu thẻ', style: GB.body(13, w: FontWeight.w700, color: GB.inkMuted)),
          const SizedBox(width: 12),
          for (var i = 0; i < themes.length; i++) ...[
            GestureDetector(
              onTap: () => setState(() => themeIdx = i),
              child: Semantics(
                button: true,
                selected: i == themeIdx,
                label: 'Mẫu ${themes[i].name}',
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: themes[i].bg, shape: BoxShape.circle, border: Border.all(color: i == themeIdx ? GB.accent : GB.edgeOf(themes[i].bg), width: i == themeIdx ? 3 : 1.2)),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
        ]),
        const SizedBox(height: 10),
        Text('Ảnh lưu về máy, mẹ gửi cho gia đình hoặc đăng lên mạng xã hội.', style: GB.body(11.5, color: GB.inkMuted)),
      ],
    );
  }
}
