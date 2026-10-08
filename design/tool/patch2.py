# -*- coding: utf-8 -*-
import re
base = r'F:\Project Ai\GinBaby\app\lib\ui'


def edit(name, fn):
    p = base + '\\' + name
    s = open(p, encoding='utf-8').read()
    s = fn(s)
    open(p, 'w', encoding='utf-8').write(s)


def rep(s, old, new, count=1):
    assert old in s, old[:80]
    return s.replace(old, new, count)


# ---------- history: art for diaper
def hist(s):
    s = rep(s, "import 'widgets.dart';", "import 'diaper_screen.dart';\nimport 'widgets.dart';")
    s = rep(s, "_Kind(T.diaper, 'Tã', null, Icons.water_drop_rounded, Color(0xFFF7E8BC), Color(0xFFC79A2B)),", "_Kind(T.diaper, 'Tã', 'poop_mustard', null, Color(0xFFFBF1D4), Color(0xFFC79A2B)),")
    s = rep(s, "    return _kinds.firstWhere((k) => k.type == e.type, orElse: () => _kinds.last);",
            "    if (e.type == T.diaper) {\n      final art = e.str('kind') == 'wet' ? 'diaper_mid' : (poopArt(e.str('color')) ?? 'poop_mustard');\n      return _Kind(T.diaper, 'Tã', art, null, const Color(0xFFFBF1D4), const Color(0xFFC79A2B));\n    }\n    return _kinds.firstWhere((k) => k.type == e.type, orElse: () => _kinds.last);")
    s = rep(s, "      if (d.isNotEmpty) parts.add(Text(d, style: GB.body(13, color: GB.inkMuted)));",
            "      final am = e.str('amount');\n      final all = [d, if (am.isNotEmpty) am].where((x) => x.isNotEmpty).join(' · ');\n      if (all.isNotEmpty) parts.add(Text(all, style: GB.body(13, color: GB.inkMuted)));")
    return s


edit('history.dart', hist)


# ---------- overview: highlight tiles
def ov(s):
    a = s.index("        if (hl.isNotEmpty) ...[\n          const SizedBox(height: 14),\n          SectionCard(\n            title: 'Những điểm nổi bật',")
    b = s.index("        const SizedBox(height: 14),\n        BigButton('Xem thẻ tổng kết tuần'")
    s = s[:a] + "        const SizedBox(height: 14),\n        _weekHighlights(cur, prev, sleepAvg, sleepPrev),\n" + s[b:]
    s = rep(s, "    final hl = highlights(cur, prev);\n", "")
    helper = """  // ───────── 3 thẻ "Những điểm nổi bật"
  Widget _weekHighlights(List<DayStat> cur, List<DayStat> prev, double sleepAvg, double sleepPrev) {
    final usePump = cur.any((d) => d.pumpMl > 0) || prev.any((d) => d.pumpMl > 0);
    final a = cur.fold(0, (x, d) => x + (usePump ? d.pumpMl : d.milk));
    final b = prev.fold(0, (x, d) => x + (usePump ? d.pumpMl : d.milk));
    final dm = pctDelta(a, b);
    final cnt = cur.fold(0, (x, d) => x + d.feedCount) - prev.fold(0, (x, d) => x + d.feedCount);
    final sleepMin = ((sleepAvg - sleepPrev) * 60).round();

    final t1 = dm == null
        ? ('Sữa mỗi ngày', 'Chưa có tuần trước để so sánh.')
        : (dm.up ? ('Tăng ${dm.text.replaceAll('+', '')}', 'Lượng sữa so với tuần trước. Mẹ đang làm rất tốt!') : ('Giảm ${dm.text.replaceAll('-', '')}', 'Lượng sữa so với tuần trước. Cứ từ từ, mẹ nhé.'));
    final t2 = cnt == 0 ? ('Đều như tuần trước', 'Số cữ bú trong tuần không đổi.') : (cnt > 0 ? ('Nhiều hơn $cnt cữ', 'Số cữ bú trong tuần so với tuần trước.') : ('Ít hơn ${-cnt} cữ', 'Số cữ bú trong tuần so với tuần trước.'));
    final t3 = sleepPrev <= 0
        ? ('Giấc ngủ của bé', 'Chưa có tuần trước để so sánh.')
        : (sleepMin >= 10 ? ('Bé ngủ ngon hơn', 'Thời gian ngủ tăng ${GB.num1(sleepMin / 60)} giờ mỗi ngày.') : (sleepMin <= -10 ? ('Bé ngủ ít hơn', 'Giảm ${GB.num1(-sleepMin / 60)} giờ mỗi ngày. Giữ nhịp đều nhé.') : ('Giấc ngủ ổn định', 'Gần như không đổi so với tuần trước.')));

    Widget tile(Color bg, Color fg, IconData icon, (String, String) t) => Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 12, 8, 12),
            decoration: BoxDecoration(color: bg.withValues(alpha: .7), borderRadius: BorderRadius.circular(18)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icon, color: fg, size: 28),
              const SizedBox(height: 6),
              Text(t.$1, style: GB.body(13.5, w: FontWeight.w800, color: fg, height: 1.15)),
              const SizedBox(height: 4),
              Text(t.$2, style: GB.body(11, color: GB.inkMuted, height: 1.3)),
            ]),
          ),
        );
    return SectionCard(
      title: 'Những điểm nổi bật',
      icon: Icons.lightbulb_rounded,
      iconColor: const Color(0xFFF2B632),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          tile(GB.pumpTile, GB.pumpDeep, Icons.trending_up_rounded, t1),
          const SizedBox(width: 8),
          tile(GB.sleepTile, const Color(0xFF4F7A4B), Icons.star_rounded, t2),
          const SizedBox(width: 8),
          tile(GB.bottleTile, const Color(0xFF7B68C4), Icons.bedtime_rounded, t3),
        ]),
      ),
    );
  }

"""
    s = rep(s, "  // ───────── Thẻ số liệu tuần (pastel)", helper + "  // ───────── Thẻ số liệu tuần (pastel)")
    # stat tiles centered like the mockup
    s = rep(s, "            Row(children: [icon, const SizedBox(width: 8), Expanded(child: Text(label, maxLines: 2, style: GB.body(12, w: FontWeight.w600, height: 1.2)))]),\n            const SizedBox(height: 8),\n            BigNumber(value, unit, size: 27),",
            "            Row(children: [icon, const SizedBox(width: 8), Expanded(child: Text(label, maxLines: 2, style: GB.body(12, w: FontWeight.w600, height: 1.2)))]),\n            const SizedBox(height: 8),\n            BigNumber(value, unit, size: 27),")
    return s


edit('overview.dart', ov)


# ---------- BackHeader: compact header option for screens with small art
p = r'F:\Project Ai\GinBaby\app\lib\core\kit.dart'
s = open(p, encoding='utf-8').read()
s = rep(s, "    return SizedBox(\n      height: 170,\n      child: Stack(children: [\n        Positioned(right: -6, top: 0, bottom: 0, child: Art(art!, width: artWidth, alignment: Alignment.topRight, fit: BoxFit.contain)),",
        "    return SizedBox(\n      height: artWidth <= 120 ? 128 : 170,\n      child: Stack(children: [\n        Positioned(right: -6, top: 0, bottom: 0, child: Art(art!, width: artWidth, alignment: Alignment.topRight, fit: BoxFit.contain)),")
s = rep(s, "Text(title, style: GB.display(art != null ? 34 : 26, color: GB.title)),", "Text(title, style: GB.display(art != null ? (artWidth <= 120 ? 28 : 34) : 26, color: GB.title)),")
open(p, 'w', encoding='utf-8').write(s)
print('ok')
