# -*- coding: utf-8 -*-
p = r'F:\Project Ai\GinBaby\app\test\widget_test.dart'
s = open(p, encoding='utf-8').read()
s = s.replace("import 'package:gin_baby/domain/leaps.dart';", "import 'package:gin_baby/domain/leaps.dart';\nimport 'package:gin_baby/ui/export_report.dart';", 1)
new = """  test('xuất CSV và báo cáo bác sĩ', () {
    app.baby = Baby(name: 'Suri', sex: Sex.girl, dob: DateTime(2026, 4, 25, 6, 30));
    app.entries
      ..clear()
      ..add(Entry(type: T.feed, time: DateTime(2026, 10, 1, 8), data: {'method': 'bottle', 'source': 'mom', 'ml': 120, 'note': 'ngoan, ít'}))
      ..add(Entry(type: T.temp, time: DateTime(2026, 10, 2, 9), data: {'v': 37.2}));
    final csv = entriesCsv();
    expect(csv.contains('01/10/26 08:00'), true);
    expect(csv.contains('"ngoan, ít"'), true);
    final html = doctorReportHtml();
    expect(html.contains('Suri'), true);
    expect(html.contains('Báo cáo sức khoẻ của bé'), true);
  });

  test('hạn dùng sữa trong tủ'"""
s = s.replace("  test('hạn dùng sữa trong tủ'", new, 1)
open(p, 'w', encoding='utf-8').write(s)
print('ok')
