# -*- coding: utf-8 -*-
import os
ROOT = r'F:\Project Ai\GinBaby\app'


def edit(rel, fn):
    p = os.path.join(ROOT, rel)
    s = open(p, encoding='utf-8').read()
    s = fn(s)
    open(p, 'w', encoding='utf-8').write(s)


def rep(s, old, new):
    assert old in s, old[:80]
    return s.replace(old, new, 1)


def pastel(s):
    s = rep(s, "this.trailing, this.onTrailing, this.padding = const EdgeInsets.fromLTRB(14, 14, 14, 14)});", "this.trailing, this.onTrailing, this.trailingWidget, this.padding = const EdgeInsets.fromLTRB(14, 14, 14, 14)});")
    s = rep(s, "  final VoidCallback? onTrailing;\n  final EdgeInsetsGeometry padding;", "  final VoidCallback? onTrailing;\n  final Widget? trailingWidget; // thay cho nút chữ, ví dụ ô chọn \"Theo ngày\"\n  final EdgeInsetsGeometry padding;")
    s = rep(s, "          if (trailing != null) ...[const SizedBox(width: 8), SoftPill(trailing!, onTap: onTrailing)],", "          if (trailingWidget != null) ...[const SizedBox(width: 8), trailingWidget!] else if (trailing != null) ...[const SizedBox(width: 8), SoftPill(trailing!, onTap: onTrailing)],")
    return s


edit(r'lib\core\pastel.dart', pastel)


def ov(s):
    a = s.index("  Widget _pumpBars(List<DayStat> cur) {")
    b = s.index("  // ───────── Biểu đồ đường nhỏ")
    new = """  Widget _pumpBars(List<DayStat> cur) {
    const wd = ['Th 2', 'Th 3', 'Th 4', 'Th 5', 'Th 6', 'Th 7', 'CN'];
    // Hai cách xem: theo ngày (7 cột) hoặc theo từng cữ hút trong tuần.
    final w0 = Stats.weekStart(anchor);
    final sessions = app.entriesBetween(w0, w0.add(const Duration(days: 7)), type: T.pump).toList()..sort((a, b) => a.time.compareTo(b.time));
    final bySession = pumpView == 1;
    final shown = sessions.length > 12 ? sessions.sublist(sessions.length - 12) : sessions;
    final values = bySession ? [for (final e in shown) e.ml] : [for (final d in cur) d.pumpMl];
    final labels = bySession ? [for (final e in shown) ('${GB.dm(e.time)}'.replaceFirst(RegExp(r'^0'), '').replaceFirst(RegExp(r'/0'), '/'), GB.hm(e.time))] : [for (var i = 0; i < 7; i++) (GB.dm(cur[i].day).replaceFirst(RegExp(r'^0'), '').replaceFirst(RegExp(r'/0'), '/'), wd[i])];
    final mx = math.max(100.0, (values.isEmpty ? 0 : values.reduce(math.max)) * 1.15);
    return SectionCard(
      title: 'Lượng sữa hút được',
      icon: Icons.water_drop_rounded,
      iconColor: GB.pumpDeep,
      trailingWidget: PopupMenuButton<int>(
        initialValue: pumpView,
        onSelected: (v) => setState(() => pumpView = v),
        color: GB.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        itemBuilder: (_) => [
          PopupMenuItem(value: 0, child: Text('Theo ngày', style: GB.body(14, w: FontWeight.w700))),
          PopupMenuItem(value: 1, child: Text('Theo từng cữ hút', style: GB.body(14, w: FontWeight.w700))),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: GB.accentSoft, borderRadius: BorderRadius.circular(18)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(bySession ? 'Theo cữ' : 'Theo ngày', style: GB.body(12.5, w: FontWeight.w700, color: GB.accentDeep)),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: GB.accentDeep),
          ]),
        ),
      ),
      child: values.isEmpty
          ? const EmptyState('Tuần này chưa có cữ hút nào.')
          : SizedBox(
              height: 190,
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                for (var i = 0; i < values.length; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: values.length > 8 ? 1.5 : 3),
                      child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                        FittedBox(fit: BoxFit.scaleDown, child: Text(values[i] > 0 ? '${values[i]}' : '', style: GB.body(11, w: FontWeight.w700))),
                        const SizedBox(height: 3),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          height: math.max(4, values[i] / mx * 120),
                          decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF3A5AA), Color(0xFFF9D3D5)]), borderRadius: BorderRadius.circular(9)),
                        ),
                        const SizedBox(height: 6),
                        FittedBox(fit: BoxFit.scaleDown, child: Text(labels[i].$1, style: GB.body(10.5, color: GB.inkMuted))),
                        FittedBox(fit: BoxFit.scaleDown, child: Text(labels[i].$2, style: GB.body(10, color: GB.inkMuted))),
                      ]),
                    ),
                  ),
              ]),
            ),
    );
  }

"""
    s = s[:a] + new + s[b:]
    s = rep(s, "  int period = 1;\n", "  int period = 1;\n  int pumpView = 0; // 0: theo ngày, 1: theo từng cữ hút\n")
    return s


edit(r'lib\ui\overview.dart', ov)
print('ok')
