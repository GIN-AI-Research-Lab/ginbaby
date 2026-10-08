# -*- coding: utf-8 -*-
p = r'F:\Project Ai\GinBaby\app\lib\ui\overview.dart'
s = open(p, encoding='utf-8').read()


def rep(old, new, count=1):
    global s
    assert old in s, old[:70]
    s = s.replace(old, new, count)


# imports
rep("import '../core/kit.dart';\n", "import '../core/kit.dart';\nimport '../core/pastel.dart';\n")

# header + selector
a = s.index("        return ListView(\n          padding: Responsive.pad(context),\n          children: [\n            Text('Tổng quan'")
b = s.index("            if (period == 0) ..._day(),")
s = s[:a] + """        return ListView(
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 130),
          children: [
            SizedBox(
              height: 168,
              child: Stack(children: [
                const Positioned(right: -8, top: 0, child: Art('hero_mom_baby', width: 160)),
                Positioned(
                  left: 0,
                  top: 10,
                  right: 130,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text('Thống kê', style: GB.display(34, color: GB.title)),
                      const SizedBox(width: 8),
                      const Icon(Icons.bar_chart_rounded, color: Color(0xFFF08A97), size: 30),
                    ]),
                    const SizedBox(height: 4),
                    Text('Những nỗ lực nhỏ hôm nay đang tạo nên điều tuyệt vời', style: GB.script(13.5)),
                  ]),
                ),
              ]),
            ),
            Seg(labels: const ['Ngày', 'Tuần', 'Tháng'], index: period, onChanged: (i) => setState(() {
                  period = i;
                  if (i == 2) anchor = DateTime(anchor.year, anchor.month, 1);
                })),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(children: [
                RoundIconButton(icon: Icons.chevron_left_rounded, label: 'Trước', size: 44, onTap: () => _shift(-1)),
                const SizedBox(width: 10),
                Expanded(
                  child: GlassCard(
                    radius: 22,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.calendar_today_rounded, size: 18, color: GB.inkMuted),
                      const SizedBox(width: 8),
                      Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(_label, style: GB.body(14.5, w: FontWeight.w800)))),
                    ]),
                  ),
                ),
                const SizedBox(width: 10),
                Opacity(opacity: _atToday ? .35 : 1, child: RoundIconButton(icon: Icons.chevron_right_rounded, label: 'Sau', size: 44, onTap: _atToday ? () {} : () => _shift(1))),
              ]),
            ),
""" + s[b:]

# week: replace the dark summary card + highlights with pastel tiles and charts
a = s.index("        Container(\n          padding: const EdgeInsets.all(20),\n          decoration: BoxDecoration(color: GB.ink")
b = s.index("        const SectionTitle('Giấc ngủ mỗi ngày'),")
s = s[:a] + """        _weekTiles(cur, prev, sleepAvg, sleepPrev),
        const SizedBox(height: 14),
        if (cur.any((d) => d.pumpMl > 0)) ...[
          _pumpBars(cur),
          const SizedBox(height: 14),
        ],
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: _lineCard(
              'Thời gian bú',
              'phút',
              GB.breastDeep,
              Icons.timer_outlined,
              [for (final d in cur) d.hasData ? d.breastMin.toDouble() : null],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _lineCard(
              'Giấc ngủ của bé',
              'giờ',
              GB.bottleDeep,
              Icons.bedtime_rounded,
              [for (final d in cur) d.hasData ? d.sleepHours : null],
            ),
          ),
        ]),
        if (hl.isNotEmpty) ...[
          const SizedBox(height: 14),
          SectionCard(
            title: 'Những điểm nổi bật',
            icon: Icons.lightbulb_rounded,
            iconColor: const Color(0xFFF2B632),
            child: Column(children: [
              for (final h in hl)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const IconBadge(icon: Icons.auto_awesome_rounded, bg: GB.okBg, fg: GB.ok, size: 32),
                    const SizedBox(width: 10),
                    Expanded(child: Padding(padding: const EdgeInsets.only(top: 6), child: Text(h, style: GB.body(13.5, w: FontWeight.w700, height: 1.3)))),
                  ]),
                ),
            ]),
          ),
        ],
        const SizedBox(height: 14),
        BigButton('Xem thẻ tổng kết tuần', icon: Icons.ios_share_rounded, height: 50, onTap: () => openPage(context, RecapScreen(weekStart: Stats.weekStart(anchor)))),
""" + s[b:]

# new helper widgets inserted before _band
helpers = """  // ───────── Thẻ số liệu tuần (pastel)
  Widget _weekTiles(List<DayStat> cur, List<DayStat> prev, double sleepAvg, double sleepPrev) {
    final pumpSum = cur.fold(0, (a, d) => a + d.pumpMl);
    final pumpPrev = prev.fold(0, (a, d) => a + d.pumpMl);
    final milkSum = cur.fold(0, (a, d) => a + d.milk);
    final milkPrevSum = prev.fold(0, (a, d) => a + d.milk);
    final usePump = pumpSum > 0 || pumpPrev > 0;
    final main = usePump ? pumpSum : milkSum;
    final mainPrev = usePump ? pumpPrev : milkPrevSum;
    final dMain = pctDelta(main, mainPrev);
    final bmSum = cur.fold(0, (a, d) => a + d.breastMin);
    final bmCnt = cur.fold(0, (a, d) => a + d.breastCount);
    final bmPrevSum = prev.fold(0, (a, d) => a + d.breastMin);
    final bmPrevCnt = prev.fold(0, (a, d) => a + d.breastCount);
    final bmAvg = bmCnt == 0 ? 0 : (bmSum / bmCnt).round();
    final bmPrevAvg = bmPrevCnt == 0 ? 0 : bmPrevSum / bmPrevCnt;
    final dBm = pctDelta(bmAvg, bmPrevAvg);
    final cnt = cur.fold(0, (a, d) => a + d.feedCount);
    final cntPrev = prev.fold(0, (a, d) => a + d.feedCount);
    final dCnt = cnt - cntPrev;
    final dSleepMin = ((sleepAvg - sleepPrev) * 60).round();

    Widget tile(Color bg, Widget icon, String label, String value, String unit, Widget? delta) => Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          decoration: BoxDecoration(color: bg.withValues(alpha: .6), borderRadius: BorderRadius.circular(22)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [icon, const SizedBox(width: 8), Expanded(child: Text(label, maxLines: 2, style: GB.body(12, w: FontWeight.w600, height: 1.2)))]),
            const SizedBox(height: 8),
            BigNumber(value, unit, size: 27),
            const SizedBox(height: 8),
            delta ?? Text('chưa có kỳ trước để so', style: GB.body(11, color: GB.inkMuted)),
          ]),
        );
    return Column(children: [
      IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: tile(GB.pumpTile, const Icon(Icons.water_drop_rounded, color: GB.pumpDeep, size: 26), usePump ? 'Tổng sữa hút' : 'Tổng sữa uống', GB.thousands(main), 'ml', dMain == null ? null : DeltaChip(dMain.text, up: dMain.up, hint: 'so với tuần trước'))),
          const SizedBox(width: 10),
          Expanded(child: tile(GB.breastTile, const Icon(Icons.timer_outlined, color: GB.breastDeep, size: 26), 'Thời gian bú TB', '$bmAvg', 'phút', dBm == null ? null : DeltaChip(dBm.text, up: dBm.up, hint: 'so với tuần trước'))),
        ]),
      ),
      const SizedBox(height: 10),
      IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: tile(GB.bottleTile, const Art('ic_bottle', height: 28), 'Số cữ trong tuần', '$cnt', 'cữ', cntPrev == 0 && cnt == 0 ? null : DeltaChip('${dCnt >= 0 ? '+' : ''}$dCnt', up: dCnt >= 0, hint: 'so với tuần trước'))),
          const SizedBox(width: 10),
          Expanded(child: tile(GB.sleepTile, const Icon(Icons.bedtime_rounded, color: GB.sleepDeep, size: 26), 'Thời gian ngủ TB', GB.num1(sleepAvg), 'giờ', sleepPrev <= 0 ? null : DeltaChip('${dSleepMin >= 0 ? '+' : '−'}${GB.num1(dSleepMin.abs() / 60)} giờ', up: dSleepMin >= 0, hint: 'so với tuần trước'))),
        ]),
      ),
    ]);
  }

  // ───────── Biểu đồ cột sữa hút mỗi ngày
  Widget _pumpBars(List<DayStat> cur) {
    final mx = math.max(100.0, maxOf(cur.map((d) => d.pumpMl)) * 1.15);
    const wd = ['Th 2', 'Th 3', 'Th 4', 'Th 5', 'Th 6', 'Th 7', 'CN'];
    return SectionCard(
      title: 'Lượng sữa hút được',
      icon: Icons.water_drop_rounded,
      iconColor: GB.pumpDeep,
      child: SizedBox(
        height: 190,
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Text(cur[i].pumpMl > 0 ? '${cur[i].pumpMl}' : '', style: GB.body(11, w: FontWeight.w700)),
                  const SizedBox(height: 3),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: math.max(4, cur[i].pumpMl / mx * 120),
                    decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF3A5AA), Color(0xFFF9D3D5)]), borderRadius: BorderRadius.circular(9)),
                  ),
                  const SizedBox(height: 6),
                  FittedBox(fit: BoxFit.scaleDown, child: Text(GB.dm(cur[i].day).replaceFirst(RegExp(r'^0'), '').replaceFirst(RegExp(r'/0'), '/'), style: GB.body(10.5, color: GB.inkMuted))),
                  Text(wd[i], style: GB.body(10, color: GB.inkMuted)),
                ]),
              ),
            ),
        ]),
      ),
    );
  }

  // ───────── Biểu đồ đường nhỏ (kèm điểm cao nhất)
  Widget _lineCard(String title, String unit, Color color, IconData icon, List<double?> v) {
    final vals = v.whereType<double>().toList();
    final hasAny = vals.isNotEmpty && vals.any((x) => x > 0);
    final peak = hasAny ? vals.reduce(math.max) : 0.0;
    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 5),
          Expanded(child: Text(title, maxLines: 2, style: GB.body(13.5, w: FontWeight.w800, height: 1.15))),
        ]),
        const SizedBox(height: 10),
        SizedBox(height: 110, child: CustomPaint(size: const Size(double.infinity, 110), painter: LineChartPainter(v, color, hasAny ? '${peak == peak.roundToDouble() ? peak.round() : GB.num1(peak)} $unit' : ''))),
      ]),
    );
  }

"""
rep("  Widget _band(double lo, double hi, double mx, double h) {", helpers + "  Widget _band(double lo, double hi, double mx, double h) {")

# painter at the end
s += """

/// Đường + vùng tô nhẹ cho 7 ngày; ngày không có dữ liệu bị bỏ qua. Đánh dấu điểm cao nhất.
class LineChartPainter extends CustomPainter {
  LineChartPainter(this.v, this.color, this.peakLabel);
  final List<double?> v;
  final Color color;
  final String peakLabel;

  @override
  void paint(Canvas canvas, Size size) {
    final vals = v.whereType<double>();
    final top = vals.isEmpty ? 1.0 : math.max(1.0, vals.reduce(math.max) * 1.25);
    const padB = 16.0, padT = 22.0;
    final h = size.height - padB - padT;
    final n = v.length;
    Offset pt(int i) => Offset(n == 1 ? size.width / 2 : 6 + i * (size.width - 12) / (n - 1), padT + h - (v[i]! / top) * h);

    final grid = Paint()
      ..color = GB.line
      ..strokeWidth = 1;
    for (var k = 0; k <= 2; k++) {
      final y = padT + h * k / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final pts = <Offset>[for (var i = 0; i < n; i++) if (v[i] != null) pt(i)];
    if (pts.length >= 2) {
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (var i = 1; i < pts.length; i++) {
        final p0 = pts[i - 1], p1 = pts[i];
        final cx = (p0.dx + p1.dx) / 2;
        path.cubicTo(cx, p0.dy, cx, p1.dy, p1.dx, p1.dy);
      }
      final area = Path.from(path)
        ..lineTo(pts.last.dx, padT + h)
        ..lineTo(pts.first.dx, padT + h)
        ..close();
      canvas.drawPath(area, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [color.withValues(alpha: .28), color.withValues(alpha: .02)]).createShader(Rect.fromLTWH(0, padT, size.width, h)));
      canvas.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = 2.4..strokeCap = StrokeCap.round..color = color);
    }
    for (final p in pts) {
      canvas.drawCircle(p, 3, Paint()..color = color);
    }
    // điểm cao nhất
    if (vals.isNotEmpty && peakLabel.isNotEmpty) {
      var bi = 0;
      for (var i = 0; i < n; i++) {
        if (v[i] != null && (v[bi] == null || v[i]! > v[bi]!)) bi = i;
      }
      final p = pt(bi);
      canvas.drawCircle(p, 6, Paint()..color = color);
      canvas.drawCircle(p, 3, Paint()..color = Colors.white);
      final tp = TextPainter(text: TextSpan(text: peakLabel, style: GB.body(10.5, w: FontWeight.w800, color: color)), textDirection: TextDirection.ltr)..layout();
      final bw = tp.width + 12;
      final bx = (p.dx - bw / 2).clamp(0.0, size.width - bw);
      final rr = RRect.fromRectAndRadius(Rect.fromLTWH(bx, math.max(0, p.dy - 28), bw, 20), const Radius.circular(10));
      canvas.drawRRect(rr, Paint()..color = color.withValues(alpha: .16));
      tp.paint(canvas, Offset(bx + 6, rr.top + 4));
    }
    const wd = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    for (var i = 0; i < n; i += 2) {
      final tp = TextPainter(text: TextSpan(text: n == 7 ? wd[i] : '${i + 1}', style: GB.body(10, color: GB.inkMuted)), textDirection: TextDirection.ltr)..layout();
      final x = (n == 1 ? size.width / 2 : 6 + i * (size.width - 12) / (n - 1)) - tp.width / 2;
      tp.paint(canvas, Offset(x.clamp(0.0, size.width - tp.width), size.height - 13));
    }
  }

  @override
  bool shouldRepaint(LineChartPainter old) => true;
}
"""

# stat card in day view -> pastel
rep("""    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Orb(icon: icon, color: color, size: 28), const SizedBox(width: 8), Expanded(child: Text(label, style: GB.body(13, w: FontWeight.w700, color: GB.inkMuted)))]),""",
    """    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [IconBadge(icon: icon, bg: color.withValues(alpha: .28), fg: color, size: 30), const SizedBox(width: 8), Expanded(child: Text(label, style: GB.body(13, w: FontWeight.w700, color: GB.inkMuted)))]),""")

# month heat colours
rep("if (!d.hasData) return Colors.white.withValues(alpha: .35);", "if (!d.hasData) return GB.line.withValues(alpha: .55);")
rep("return Color.lerp(const Color(0xFFE3E6F6), const Color(0xFF8E9AD8), t)!;", "return Color.lerp(const Color(0xFFE6E0F5), const Color(0xFF9D8DD0), t)!;")
rep("border: d.day == today ? Border.all(color: GB.ink, width: 2) : null", "border: d.day == today ? Border.all(color: GB.accent, width: 2.2) : null")
rep("Container(width: 14, height: 14, decoration: BoxDecoration(color: const Color(0xFF8E9AD8), borderRadius: BorderRadius.circular(4))),", "Container(width: 14, height: 14, decoration: BoxDecoration(color: const Color(0xFF9D8DD0), borderRadius: BorderRadius.circular(4))),")
rep("Container(width: 14, height: 14, decoration: BoxDecoration(color: const Color(0xFFE3E6F6), borderRadius: BorderRadius.circular(4))),", "Container(width: 14, height: 14, decoration: BoxDecoration(color: const Color(0xFFE6E0F5), borderRadius: BorderRadius.circular(4))),")
rep("final track = Paint()..color = Colors.white.withValues(alpha: .65);", "final track = Paint()..color = GB.line.withValues(alpha: .7);")
rep("canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x(now) - 1, -4, 2.4, 110), const Radius.circular(2)), Paint()..color = GB.ink);", "canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x(now) - 1, -4, 2.4, 110), const Radius.circular(2)), Paint()..color = GB.accent);")
open(p, 'w', encoding='utf-8').write(s)

# stats: breast minutes/count per day
p2 = r'F:\Project Ai\GinBaby\app\lib\domain\stats.dart'
t = open(p2, encoding='utf-8').read()
t = t.replace("    required this.pumpCount,\n    required this.hasData,\n  });", "    required this.pumpCount,\n    required this.hasData,\n    this.breastMin = 0,\n    this.breastCount = 0,\n  });")
t = t.replace("  final bool hasData;\n\n  int get milk", "  final bool hasData;\n  final int breastMin; // tổng phút bú mẹ trực tiếp\n  final int breastCount; // số cữ bú mẹ trực tiếp\n\n  int get milk")
t = t.replace("    final pumps = list.where((e) => e.type == T.pump).toList();\n", "    final pumps = list.where((e) => e.type == T.pump).toList();\n    final breasts = list.where((e) => e.type == T.feed && e.str('method') == 'breast').toList();\n")
t = t.replace("      hasData: list.isNotEmpty || a.sleepOn(s) > Duration.zero,\n    );", "      hasData: list.isNotEmpty || a.sleepOn(s) > Duration.zero,\n      breastMin: breasts.fold(0, (x, e) => x + e.num('min').round()),\n      breastCount: breasts.length,\n    );")
open(p2, 'w', encoding='utf-8').write(t)
print('ok')
