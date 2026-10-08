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


def growth(s):
    s = rep(s, "import '../core/kit.dart';", "import '../core/kit.dart';\nimport '../core/pastel.dart';")
    a = s.index("              GlassCard(\n                radius: 24,\n                padding: const EdgeInsets.fromLTRB(8, 14, 14, 10),")
    b = s.index("            const SizedBox(height: 12),\n            if (last != null && z != null) ...[")
    new = """              SectionCard(
                title: '${Growth.name(kind)} (${Growth.unit(kind)})',
                icon: kind == GrowthKind.weight ? Icons.monitor_weight_rounded : (kind == GrowthKind.length ? Icons.height_rounded : Icons.face_rounded),
                iconColor: GB.pumpDeep,
                trailingWidget: Text('P3 · P15 · P50 · P85 · P97', style: GB.body(10.5, color: GB.inkMuted)),
                padding: const EdgeInsets.fromLTRB(8, 14, 12, 10),
                child: SizedBox(height: 250, child: CustomPaint(size: const Size(double.infinity, 250), painter: _GrowthPainter(kind, baby.sex, [for (final m in pts) (_months(m.date), _val(m)!)], ageM))),
              ),
"""
    s = s[:a] + new + s[b:]
    s = rep(s, "canvas.drawPath(band(Growth.zP3, Growth.zP97), Paint()..color = GB.okBg.withValues(alpha: .55));", "canvas.drawPath(band(Growth.zP3, Growth.zP97), Paint()..color = GB.pumpTile.withValues(alpha: .7));")
    s = rep(s, "canvas.drawPath(band(Growth.zP15, Growth.zP85), Paint()..color = const Color(0xFFC9DBA6).withValues(alpha: .55));", "canvas.drawPath(band(Growth.zP15, Growth.zP85), Paint()..color = const Color(0xFFF6C4C8).withValues(alpha: .55));")
    s = rep(s, "          ..color = z == 0 ? GB.ok : GB.ok.withValues(alpha: .55),", "          ..color = z == 0 ? GB.bottleDeep : GB.bottleDeep.withValues(alpha: .5),")
    return s


edit(r'lib\ui\growth_screen.dart', growth)


def money(s):
    s = rep(s, "import '../core/kit.dart';", "import '../core/kit.dart';\nimport '../core/pastel.dart';")
    a = s.index("        SectionTitle('Chi theo nhãn', trailing:")
    b = s.index("      ],\n      if (days.isEmpty)")
    new = """        const SizedBox(height: 12),
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
"""
    s = s[:a] + new + s[b:]
    return s


edit(r'lib\ui\money.dart', money)
print('ok')
