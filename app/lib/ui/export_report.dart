import 'dart:convert';
import 'dart:typed_data';

import '../core/platform.dart';
import '../core/theme.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import '../domain/stats.dart';
import '../domain/vaccines.dart';
import 'widgets.dart';

String _esc(String s) => const HtmlEscape().convert(s);

String _csvCell(String s) {
  final needs = s.contains(',') || s.contains('"') || s.contains('\n');
  final t = s.replaceAll('"', '""');
  return needs ? '"$t"' : t;
}

String _typeName(Entry e) {
  switch (e.type) {
    case T.feed:
      return e.str('method') == 'breast' ? 'Bú mẹ' : 'Bú bình';
    case T.sleep:
      return 'Ngủ';
    case T.diaper:
      return 'Tã/phân';
    case T.pump:
      return 'Hút sữa';
    case T.temp:
      return 'Nhiệt độ';
    case T.med:
      return 'Thuốc';
    case T.solid:
      return 'Ăn dặm';
    default:
      return 'Ghi chú';
  }
}

/// Nhật ký dạng CSV (mở bằng Excel/Google Sheets). Ngày dd/mm/yy hh:mm.
String entriesCsv() {
  final b = StringBuffer('Bắt đầu,Kết thúc,Loại,Chi tiết,Lượng (ml),Ghi chú\n');
  final list = [...app.entries]..sort((a, b) => a.time.compareTo(b.time));
  for (final e in list) {
    b.writeln([
      GB.dmyhm(e.time),
      e.end == null ? '' : GB.dmyhm(e.end!),
      _typeName(e),
      entryTitle(e),
      (e.type == T.feed || e.type == T.pump) && e.ml > 0 ? '${e.ml}' : '',
      e.str('note'),
    ].map(_csvCell).join(','));
  }
  return b.toString();
}

/// Báo cáo một trang cho bác sĩ nhi: hồ sơ, tăng trưởng, tiêm chủng, 14 ngày gần nhất, nhiệt độ và thuốc.
String doctorReportHtml() {
  final baby = app.baby!;
  final age = app.age;
  final now = DateTime.now();
  final h = StringBuffer();
  h.write('''<!doctype html><html lang="vi"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Báo cáo GinBaby - ${_esc(baby.name)}</title>
<style>
body{font-family:-apple-system,"Segoe UI",Roboto,sans-serif;color:#2b2634;max-width:820px;margin:24px auto;padding:0 16px;line-height:1.45}
h1{color:#8b2f33;margin:0 0 4px}h2{color:#8b2f33;border-bottom:2px solid #f3e4df;padding-bottom:4px;margin-top:26px;font-size:18px}
table{border-collapse:collapse;width:100%;font-size:13.5px}th,td{border:1px solid #e8d8d3;padding:6px 8px;text-align:left}th{background:#fcefea}
.muted{color:#6f6470;font-size:12.5px}.btn{background:#e5666f;color:#fff;border:0;border-radius:20px;padding:10px 20px;font-size:15px;cursor:pointer}
@media print{.btn{display:none}body{margin:0}}
</style></head><body>
<button class="btn" onclick="window.print()">In hoặc lưu thành PDF</button>
<h1>Báo cáo sức khoẻ của bé</h1>
<div class="muted">Tạo bởi GinBaby ngày ${GB.dmyhm(now)}. Số liệu do ba mẹ tự ghi, chỉ để tham khảo, không thay thế chẩn đoán của bác sĩ.</div>
<h2>Hồ sơ</h2>
<table><tr><th>Tên</th><td>${_esc(baby.name)}</td><th>Giới tính</th><td>${baby.sex == Sex.girl ? 'Bé gái' : 'Bé trai'}</td></tr>
<tr><th>Ngày sinh</th><td>${GB.dmyhm(baby.dob)}</td><th>Tuổi</th><td>${_esc(age.label)}${age.preterm ? ' (sinh non ${baby.gestWeeks} tuần)' : ''}</td></tr>
<tr><th>Cân nặng sinh</th><td>${GB.num1(baby.birthWeightKg)} kg</td><th>Cân nặng gần nhất</th><td>${GB.num1(app.weightKg)} kg</td></tr></table>
''');

  final ms = [...app.measurements]..sort((a, b) => a.date.compareTo(b.date));
  h.write('<h2>Tăng trưởng</h2>');
  if (ms.isEmpty) {
    h.write('<div class="muted">Chưa có số đo.</div>');
  } else {
    h.write('<table><tr><th>Ngày</th><th>Cân nặng (kg)</th><th>Chiều dài (cm)</th><th>Vòng đầu (cm)</th></tr>');
    for (final m in ms) {
      h.write('<tr><td>${GB.dmy(m.date)}</td><td>${m.weightKg == null ? '' : GB.num2(m.weightKg!)}</td><td>${m.heightCm == null ? '' : GB.num1(m.heightCm!)}</td><td>${m.headCm == null ? '' : GB.num1(m.headCm!)}</td></tr>');
    }
    h.write('</table>');
  }

  h.write('<h2>Tiêm chủng đã ghi</h2>');
  final done = kVaccines.where((v) => app.vax.containsKey(v.id)).toList();
  if (done.isEmpty) {
    h.write('<div class="muted">Chưa ghi mũi tiêm nào.</div>');
  } else {
    h.write('<table><tr><th>Mũi</th><th>Ngày tiêm</th><th>Nơi tiêm</th></tr>');
    for (final v in done) {
      final r = app.vax[v.id]!;
      h.write('<tr><td>${_esc(v.name)}</td><td>${GB.dmy(r.date)}</td><td>${_esc(r.place)}</td></tr>');
    }
    h.write('</table>');
  }

  h.write('<h2>14 ngày gần nhất</h2><table><tr><th>Ngày</th><th>Ngủ</th><th>Số cữ bú</th><th>Sữa (ml)</th><th>Hút (ml)</th><th>Tã ướt</th><th>Phân</th></tr>');
  for (var i = 13; i >= 0; i--) {
    final d = Stats.day(app, now.subtract(Duration(days: i)));
    if (!d.hasData) continue;
    h.write('<tr><td>${GB.dmy(d.day)}</td><td>${GB.dur(d.sleep)}</td><td>${d.feedCount}</td><td>${d.milk}</td><td>${d.pumpMl}</td><td>${d.wet}</td><td>${d.poop}</td></tr>');
  }
  h.write('</table><div class="muted">Sữa gồm bú bình và bú mẹ trực tiếp (ước tính).</div>');

  final since = now.subtract(const Duration(days: 30));
  final hm = app.entries.where((e) => (e.type == T.temp || e.type == T.med) && e.time.isAfter(since)).toList()..sort((a, b) => a.time.compareTo(b.time));
  h.write('<h2>Nhiệt độ và thuốc (30 ngày)</h2>');
  if (hm.isEmpty) {
    h.write('<div class="muted">Không có ghi chép.</div>');
  } else {
    h.write('<table><tr><th>Thời gian</th><th>Nội dung</th></tr>');
    for (final e in hm) {
      h.write('<tr><td>${GB.dmyhm(e.time)}</td><td>${_esc(entryTitle(e))}</td></tr>');
    }
    h.write('</table>');
  }

  final bad = app.entries.where((e) => e.type == T.diaper && e.time.isAfter(since) && ['Bạc', 'Máu', 'Đen'].contains(e.str('color'))).toList();
  if (bad.isNotEmpty) {
    h.write('<h2>Phân cần chú ý (30 ngày)</h2><table><tr><th>Thời gian</th><th>Mô tả</th></tr>');
    for (final e in bad) {
      h.write('<tr><td>${GB.dmyhm(e.time)}</td><td>${_esc(entryTitle(e))}</td></tr>');
    }
    h.write('</table>');
  }
  h.write('</body></html>');
  return h.toString();
}

/// Tải tệp về máy (bản web). CSV có BOM để Excel đọc đúng tiếng Việt.
bool exportCsv() {
  if (!kIsWebPlatform) return false;
  final bytes = Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(entriesCsv())]);
  downloadBytes('ginbaby-nhat-ky-${AppState.dayKey(DateTime.now())}.csv', bytes, 'text/csv');
  return true;
}

bool exportDoctorReport() {
  if (!kIsWebPlatform) return false;
  downloadBytes('ginbaby-bao-cao-${AppState.dayKey(DateTime.now())}.html', Uint8List.fromList(utf8.encode(doctorReportHtml())), 'text/html');
  return true;
}
