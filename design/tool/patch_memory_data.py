# -*- coding: utf-8 -*-
import os

ROOT = r'F:\Project Ai\GinBaby\app\lib'


def edit(rel, fn):
    p = os.path.join(ROOT, rel)
    s = open(p, encoding='utf-8').read()
    s = fn(s)
    open(p, 'w', encoding='utf-8').write(s)


def rep(s, old, new, cnt=1):
    assert old in s, old[:100]
    return s.replace(old, new, cnt)


def models(s):
    return rep(s, "class MoodEntry {", """/// Một kỷ niệm về mốc của bé: ngày, ảnh, ghi chú. [key] là mã mốc (d_ mốc ngày, f_ lần đầu, c_ mốc riêng, m2_0… mốc CDC).
class MilestoneMemo {
  MilestoneMemo({required this.key, required this.title, required this.date, this.note = '', this.photo, this.custom = false});
  final String key;
  String title;
  DateTime date;
  String note;
  String? photo;
  bool custom;
  Map<String, dynamic> toJson() => {'k': key, 't': title, 'd': msOf(date), if (note.isNotEmpty) 'n': note, if (photo != null) 'p': photo, if (custom) 'c': true};
  static MilestoneMemo fromJson(Map<String, dynamic> j) => MilestoneMemo(key: j['k'] as String, title: j['t'] as String, date: dtFrom(j['d']), note: (j['n'] as String?) ?? '', photo: j['p'] as String?, custom: j['c'] == true);
}

class MoodEntry {""")


edit(r'data\models.dart', models)


def state(s):
    s = rep(s, "  final Map<String, DateTime> milestones = {};", "  final Map<String, DateTime> milestones = {};\n  final Map<String, MilestoneMemo> memos = {}; // nhật ký mốc: kỷ niệm kèm ảnh, ghi chú")
    s = rep(s, "    final th = await obj('teeth');", "    final mm = await obj('memos');\n    if (mm != null) mm.forEach((k, e) => memos[k] = MilestoneMemo.fromJson(Map<String, dynamic>.from(e as Map)));\n    final th = await obj('teeth');")
    s = rep(s, "        case 'teeth':\n          v = jsonEncode(teeth.map((k, e) => MapEntry(k, msOf(e))));", "        case 'memos':\n          v = jsonEncode(memos.map((k, e) => MapEntry(k, e.toJson())));\n        case 'teeth':\n          v = jsonEncode(teeth.map((k, e) => MapEntry(k, msOf(e))));")
    s = rep(s, "        for (final f in funds) ...f.photos,\n", "        for (final f in funds) ...f.photos,\n        for (final m in memos.values)\n          if (m.photo != null) m.photo!,\n")
    s = rep(s, "  void toggleTooth(String id, [DateTime? at]) {", """  /// Lưu kỷ niệm của một mốc. Mốc CDC (m2_0…) cũng được đánh dấu đã đạt vào ngày đó.
  void saveMemo(MilestoneMemo m) {
    final old = memos[m.key];
    if (old?.photo != null && old!.photo != m.photo) deletePhoto(old.photo!);
    memos[m.key] = m;
    if (RegExp(r'^m\\d+_\\d+$').hasMatch(m.key)) {
      milestones[m.key] = m.date;
      changed('miles');
    }
    changed('memos');
  }

  void removeMemo(String key) {
    final old = memos.remove(key);
    if (old?.photo != null) deletePhoto(old!.photo!);
    changed('memos');
  }

  void toggleTooth(String id, [DateTime? at]) {""")
    s = rep(s, "        'teeth': teeth.map((k, e) => MapEntry(k, msOf(e))),\n        'fussy': fussyDays,\n        'settings': settings.toJson(),", "        'memos': memos.map((k, e) => MapEntry(k, e.toJson())),\n        'teeth': teeth.map((k, e) => MapEntry(k, msOf(e))),\n        'fussy': fussyDays,\n        'settings': settings.toJson(),")
    s = rep(s, "    teeth.clear();\n    (j['teeth'] as Map? ?? {}).forEach((k, e) => teeth['$k'] = dtFrom(e));", "    memos.clear();\n    (j['memos'] as Map? ?? {}).forEach((k, e) => memos['$k'] = MilestoneMemo.fromJson(Map<String, dynamic>.from(e as Map)));\n    teeth.clear();\n    (j['teeth'] as Map? ?? {}).forEach((k, e) => teeth['$k'] = dtFrom(e));")
    s = rep(s, "'epds', 'miles', 'teeth', 'fussy', 'members', 'settings']) {", "'epds', 'miles', 'memos', 'teeth', 'fussy', 'members', 'settings']) {")
    s = rep(s, "    milestones.clear();\n    teeth.clear();\n    fussyDays.clear();", "    milestones.clear();\n    memos.clear();\n    teeth.clear();\n    fussyDays.clear();")
    return s


edit(r'data\app_state.dart', state)

# ---- dữ liệu mẫu để xem thử và kiểm thử
def demo(s):
    return rep(s, "  a.changed('miles');\n}", """  a.changed('miles');

  a.memos
    ..clear()
    ..['d_month1'] = MilestoneMemo(key: 'd_month1', title: 'Đầy tháng', date: dob.add(const Duration(days: 30)), note: 'Cả nhà có mặt, bé ngủ ngoan suốt buổi tiệc.')
    ..['f_smile'] = MilestoneMemo(key: 'f_smile', title: 'Nụ cười đầu tiên', date: dob.add(const Duration(days: 52)), note: 'Bé cười khi mẹ hát ru.');
  a.changed('memos');
}""")


edit(r'data\demo.dart', demo)
print('ok')
