import 'package:flutter/material.dart';

import '../core/kit.dart';
import '../core/pastel.dart';
import '../core/pickers.dart';
import '../core/theme.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import 'diaper_screen.dart';
import 'widgets.dart';

/// Lịch sử: dòng thời gian theo ngày, lọc theo loại, tìm kiếm và chọn ngày.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, this.asTab = false});
  final bool asTab;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _Kind {
  const _Kind(this.type, this.label, this.art, this.icon, this.tile, this.deep);
  final String? type;
  final String label;
  final String? art;
  final IconData? icon;
  final Color tile;
  final Color deep;
}

class _HistoryScreenState extends State<HistoryScreen> {
  String? filter;
  DateTime? day;
  String q = '';
  final search = TextEditingController();

  static final _kinds = <_Kind>[
    _Kind(null, 'Tất cả', null, Icons.grid_view_rounded, GB.pumpTile, GB.accentDeep),
    _Kind(T.feed, 'Bú', 'ic_breast', null, GB.breastTile, GB.breastDeep),
    _Kind(T.pump, 'Hút sữa', 'ic_pump', null, GB.bottleTile, GB.bottleDeep),
    _Kind(T.sleep, 'Ngủ', 'ic_moon', null, GB.sleepTile, GB.sleepDeep),
    _Kind(T.diaper, 'Tã', 'poop_mustard', null, GB.p(Color(0xFFFBF1D4)), Color(0xFFC79A2B)),
    _Kind(T.temp, 'Nhiệt độ', null, Icons.thermostat_rounded, GB.p(Color(0xFFD7EAF0)), Color(0xFF4B93AA)),
    _Kind(T.med, 'Thuốc', null, Icons.medication_rounded, GB.pumpTile, GB.pumpDeep),
    _Kind(T.solid, 'Ăn dặm', null, Icons.restaurant_rounded, GB.p(Color(0xFFE5EDC9)), Color(0xFF7C9A3A)),
    _Kind(T.note, 'Ghi chú', null, Icons.edit_note_rounded, GB.p(Color(0xFFEDE6E2)), GB.inkMuted),
  ];

  _Kind _kindOf(Entry e) {
    if (e.type == T.feed) {
      final breast = e.str('method') == 'breast';
      return breast ? _kinds[1] : _Kind(T.feed, 'Bình sữa', 'ic_bottle', null, GB.bottleTile, GB.bottleDeep);
    }
    if (e.type == T.diaper) {
      final art = e.str('kind') == 'wet' ? 'diaper_mid' : (poopArt(e.str('color')) ?? 'poop_mustard');
      return _Kind(T.diaper, 'Tã', art, null, GB.p(Color(0xFFFBF1D4)), const Color(0xFFC79A2B));
    }
    return _kinds.firstWhere((k) => k.type == e.type, orElse: () => _kinds.last);
  }

  String _title(Entry e) {
    switch (e.type) {
      case T.feed:
        if (e.str('method') == 'breast') {
          final side = e.str('side');
          return 'Cho bú (${side == 'L' ? 'bên trái' : side == 'R' ? 'bên phải' : 'hai bên'})';
        }
        return 'Bình sữa · ${e.str('source') == 'formula' ? 'công thức' : 'sữa mẹ'}';
      case T.sleep:
        return e.end == null ? 'Đang ngủ…' : 'Ngủ';
      case T.pump:
        return 'Hút sữa';
      case T.diaper:
        final k = e.str('kind');
        return k == 'wet' ? 'Tã ướt' : (k == 'both' ? 'Ướt + phân' : 'Phân');
      case T.temp:
        return 'Nhiệt độ ${GB.num1(e.num('v'))}°C';
      case T.med:
        return 'Thuốc';
      case T.solid:
        return 'Ăn dặm';
      default:
        return 'Ghi chú';
    }
  }

  /// Dòng mô tả: thời lượng, lượng sữa, chi tiết.
  Widget _meta(Entry e) {
    final parts = <Widget>[];
    Widget chip(IconData ic, String t, {Color? c}) => Row(mainAxisSize: MainAxisSize.min, children: [Icon(ic, size: 15, color: c ?? GB.inkMuted), const SizedBox(width: 4), Text(t, style: GB.body(13, color: GB.inkMuted))]);
    final mins = e.end == null ? null : e.end!.difference(e.time).inMinutes;
    if ((e.type == T.sleep || e.type == T.feed || e.type == T.pump) && e.end != null && mins != null && mins >= 1) {
      parts.add(chip(Icons.schedule_rounded, e.type == T.sleep ? GB.dur(e.end!.difference(e.time)) : '$mins phút'));
    }
    if ((e.type == T.feed || e.type == T.pump) && e.ml > 0) {
      parts.add(Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.water_drop_rounded, size: 15, color: Color(0xFFF2B632)),
        const SizedBox(width: 3),
        Flexible(child: Text('${e.ml} ml${e.data['est'] == true ? ' (ước tính)' : ''}', style: GB.body(13.5, w: FontWeight.w800))),
      ]));
    }
    if (e.type == T.pump && e.num('l') > 0 && e.num('r') > 0) parts.add(Text('${e.num('l').round()} + ${e.num('r').round()}', style: GB.body(12.5, color: GB.inkMuted)));
    if (e.type == T.diaper) {
      final d = [if (e.str('state').isNotEmpty) e.str('state'), if (e.str('color').isNotEmpty) e.str('color')].join(' · ');
      final am = e.str('amount');
      final all = [d, if (am.isNotEmpty) am].where((x) => x.isNotEmpty).join(' · ');
      if (all.isNotEmpty) parts.add(Text(all, style: GB.body(13, color: GB.inkMuted)));
    }
    if (e.type == T.med) parts.add(Text('${e.str('name')}${e.str('dose').isEmpty ? '' : ' · ${e.str('dose')}'}', style: GB.body(13, color: GB.inkMuted)));
    if (e.type == T.solid) parts.add(Text(e.str('food'), style: GB.body(13, color: GB.inkMuted)));
    if (e.type == T.note) parts.add(Text(e.str('text'), style: GB.body(13, color: GB.inkMuted)));
    if (parts.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 12, runSpacing: 2, crossAxisAlignment: WrapCrossAlignment.center, children: parts);
  }

  // Tối: mọi loại cùng một nền kính tím, chỉ ám nhẹ màu của loại ghi (chữ luôn là màu sáng, đủ tương phản).
  Color _cardFill(_Kind k) => GB.dark ? Color.alphaBlend(k.deep.withValues(alpha: .16), Colors.white.withValues(alpha: .10)) : k.tile.withValues(alpha: .42);

  Widget _row(Entry e, {required bool first, required bool last}) {
    final k = _kindOf(e);
    final note = e.str('note');
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(width: 46, child: Padding(padding: const EdgeInsets.only(top: 18), child: Text(GB.hm(e.time), style: GB.body(13.5, color: GB.inkMuted)))),
        SizedBox(
          width: 22,
          child: Stack(alignment: Alignment.topCenter, children: [
            Positioned(top: first ? 24 : 0, bottom: last ? null : 0, height: last ? 24 : null, child: Container(width: 2, color: GB.line)),
            Positioned(top: 20, child: Container(width: 14, height: 14, decoration: BoxDecoration(color: k.deep.withValues(alpha: .65), shape: BoxShape.circle, border: Border.all(color: GB.card, width: 2)))),
          ]),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => showEntrySheet(context, e),
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
                decoration: BoxDecoration(color: _cardFill(k), borderRadius: BorderRadius.circular(20), border: Border.all(color: GB.dark ? k.deep.withValues(alpha: .45) : GB.edgeOf(k.tile.withValues(alpha: .42)), width: 1)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Container(
                    width: 50,
                    height: 50,
                    padding: EdgeInsets.all(k.art == null ? 0 : 6),
                    decoration: BoxDecoration(color: GB.dark ? Color.alphaBlend(k.deep.withValues(alpha: .28), const Color(0xFF3A3262)) : k.tile.withValues(alpha: .8), shape: BoxShape.circle),
                    child: k.art != null ? Art(k.art!) : Icon(k.icon, size: 24, color: k.deep),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_title(e), style: GB.body(15, w: FontWeight.w800, color: e.type == T.feed && e.str('method') == 'breast' ? GB.f(Color(0xFF9B3B36)) : GB.ink)),
                      const SizedBox(height: 2),
                      _meta(e),
                      if (note.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Padding(padding: EdgeInsets.only(top: 2), child: Icon(Icons.favorite_rounded, size: 13, color: Color(0xFFF08A97))),
                            const SizedBox(width: 5),
                            Expanded(child: Text(note, style: GB.body(12.5, color: GB.inkMuted, height: 1.3))),
                          ]),
                        ),
                      if (e.data['photo'] != null) Padding(padding: EdgeInsets.only(top: 3), child: Icon(Icons.photo_camera_rounded, size: 15, color: GB.inkMuted)),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Future<void> _pickDay() async {
    final d = await pickDateTime(context, day ?? DateTime.now(), timeToo: false, last: DateTime.now(), title: 'Xem nhật ký ngày');
    if (d != null) setState(() => day = AppState.dayStart(d));
  }

  Widget _filters() => SizedBox(
        height: 50,
        child: ListView(scrollDirection: Axis.horizontal, clipBehavior: Clip.none, children: [
          for (final k in _kinds) ...[
            GestureDetector(
              onTap: () => setState(() => filter = k.type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  // tối: ô kính trong; đang chọn thì phủ màu loại ghi để nổi lên mà chữ vẫn là màu sáng, dễ đọc
                  color: GB.dark ? (filter == k.type ? Color.alphaBlend(k.deep.withValues(alpha: .42), const Color(0xFF3A3262)) : Colors.white.withValues(alpha: .12)) : (filter == k.type ? k.tile : k.tile.withValues(alpha: .7)),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: filter == k.type ? k.deep.withValues(alpha: .9) : (GB.dark ? Colors.white.withValues(alpha: .30) : GB.edgeOf(k.tile)), width: filter == k.type ? 1.6 : 1.1),
                  boxShadow: filter == k.type ? [BoxShadow(color: k.deep.withValues(alpha: .28), blurRadius: 10, offset: const Offset(0, 4))] : null,
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (k.art != null) SizedBox(width: 26, height: 26, child: Art(k.art!)) else Icon(k.icon, size: 22, color: k.deep),
                  const SizedBox(width: 7),
                  Text(k.label, style: GB.body(14, w: filter == k.type ? FontWeight.w800 : FontWeight.w600, color: filter == k.type && k.type == null && !GB.dark ? GB.accentDeep : GB.ink)),
                ]),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final query = q.trim().toLowerCase();
        final list = app.entries.where((e) {
          if (filter != null && e.type != filter) return false;
          if (day != null && AppState.dayStart(e.time) != day) return false;
          if (query.isNotEmpty) {
            final hay = '${_title(e)} ${entryTitle(e)} ${e.str('note')} ${e.str('text')} ${e.str('name')} ${e.str('food')}'.toLowerCase();
            if (!hay.contains(query)) return false;
          }
          return true;
        }).toList();
        final groups = <DateTime, List<Entry>>{};
        for (final e in list) {
          groups.putIfAbsent(AppState.dayStart(e.time), () => []).add(e);
        }
        final days = groups.keys.toList()..sort((a, b) => b.compareTo(a));

        final header = _header();
        final controls = <Widget>[
          const SizedBox(height: 4),
          _filters(),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(color: GB.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: GB.edgeOf(GB.line), width: 1.3)),
                child: TextField(
                  controller: search,
                  onChanged: (v) => setState(() => q = v),
                  style: GB.body(14.5, w: FontWeight.w600),
                  cursorColor: GB.accentDeep,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm hoạt động...',
                    hintStyle: GB.body(14, color: GB.inkMuted.withValues(alpha: .7)),
                    prefixIcon: Icon(Icons.search_rounded, color: GB.inkMuted),
                    suffixIcon: q.isEmpty ? null : IconButton(icon: const Icon(Icons.close_rounded, size: 18), onPressed: () => setState(() {
                          q = '';
                          search.clear();
                        })),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _pickDay,
              child: Semantics(
                button: true,
                label: 'Chọn ngày',
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: day == null ? GB.card : GB.accentSoft, borderRadius: BorderRadius.circular(18), border: Border.all(color: GB.line)),
                  child: Icon(Icons.calendar_month_rounded, color: day == null ? GB.inkMuted : GB.accentDeep),
                ),
              ),
            ),
          ]),
          if (day != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(children: [
                SoftPill('Ngày ${GB.dmy(day!)} · bỏ lọc', arrow: false, onTap: () => setState(() => day = null)),
              ]),
            ),
          const SizedBox(height: 8),
          if (days.isEmpty) const EmptyState('Chưa có hoạt động nào.'),
          for (final d in days.take(60)) ...[
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 10),
              child: Row(children: [
                Text(GB.dayLabel(d), style: GB.display(17, w: FontWeight.w800)),
                const Spacer(),
                Text('Tổng ${groups[d]!.length} hoạt động', style: GB.body(12.5, color: GB.inkMuted)),
              ]),
            ),
            for (var i = 0; i < groups[d]!.length; i++) _row(groups[d]![i], first: i == 0, last: i == groups[d]!.length - 1),
          ],
        ];

        if (widget.asTab) {
          return ListView(
            padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 16, 100),
            children: [header, ...controls],
          );
        }
        return SubPage(title: 'Lịch sử', subtitle: 'Lưu giữ từng khoảnh khắc đồng hành cùng con yêu', art: 'hero_mom_baby', artWidth: 150, children: controls);
      },
    );
  }

  Widget _header() => SizedBox(
        height: 140,
        child: Stack(children: [
          const Positioned(right: -8, top: 0, child: Art('hero_mom_baby', width: 140)),
          Positioned(
            left: 0,
            top: 12,
            right: 122,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('Lịch sử', style: GB.display(30, color: GB.title)),
                  const SizedBox(width: 6),
                  const Icon(Icons.favorite_rounded, color: Color(0xFFF08A97), size: 24),
                ]),
              ),
              const SizedBox(height: 4),
              Text('Lưu giữ từng khoảnh khắc đồng hành cùng con yêu', style: GB.script(13.5)),
            ]),
          ),
        ]),
      );
}
