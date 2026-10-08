# -*- coding: utf-8 -*-
import os
ROOT = r'F:\Project Ai\GinBaby\app\lib'


def edit(rel, fn):
    p = os.path.join(ROOT, rel)
    s = open(p, encoding='utf-8').read()
    s = fn(s)
    open(p, 'w', encoding='utf-8').write(s)


def rep(s, old, new):
    assert old in s, old[:90]
    return s.replace(old, new, 1)


# ---------- toast có "Hoàn tác"
def kit(s):
    s = rep(s, "void toast(BuildContext context, String msg) {\n  ScaffoldMessenger.of(context)\n    ..hideCurrentSnackBar()\n    ..showSnackBar(SnackBar(\n      content: Text(msg, style: GB.body(14, color: GB.cream)),",
            "void toast(BuildContext context, String msg, {VoidCallback? undo}) {\n  ScaffoldMessenger.of(context)\n    ..hideCurrentSnackBar()\n    ..showSnackBar(SnackBar(\n      content: Text(msg, style: GB.body(14, color: GB.cream)),\n      action: undo == null ? null : SnackBarAction(label: 'Hoàn tác', textColor: GB.accent, onPressed: undo),")
    s = rep(s, "      duration: const Duration(seconds: 2),\n    ));\n}", "      duration: Duration(seconds: undo == null ? 2 : 5),\n    ));\n}")
    return s


edit(r'core\kit.dart', kit)


def feed(s):
    s = rep(s, "                child: BigButton('Lưu cữ bú ${GB.dur(elapsed)}', icon: Icons.check_rounded, onTap: () {\n                  app.addBreast(start: st, end: en, side: s.breastSide, mlEst: estOverride);\n                  final text = GB.dur(elapsed);\n                  _resetBreast();\n                  toast(context, 'Đã ghi bú mẹ $text');",
            "                child: BigButton('Lưu cữ bú ${GB.dur(elapsed)}', icon: Icons.check_rounded, onTap: () {\n                  final saved = app.addBreast(start: st, end: en, side: s.breastSide, mlEst: estOverride);\n                  final text = GB.dur(elapsed);\n                  _resetBreast();\n                  toast(context, 'Đã ghi bú mẹ $text', undo: () => app.removeEntry(saved.id));")
    return s


edit(r'ui\feed_screen.dart', feed)


def sleep(s):
    s = rep(s, "                    Expanded(child: BigButton('Bé dậy rồi', icon: Icons.wb_sunny_rounded, color: GB.sleepDeep, onTap: () {\n                      app.endSleep();\n                      toast(context, 'Đã ghi giấc ngủ ${GB.dur(elapsed)}');",
            "                    Expanded(child: BigButton('Bé dậy rồi', icon: Icons.wb_sunny_rounded, color: GB.sleepDeep, onTap: () {\n                      final done = app.endSleep();\n                      toast(context, 'Đã ghi giấc ngủ ${GB.dur(elapsed)}', undo: () {\n                        if (done != null) {\n                          done.end = null;\n                          app.changed('entries');\n                        }\n                      });")
    s = rep(s, "                      app.addEntry(Entry(type: T.sleep, time: s, end: e));\n                      toast(context, 'Đã ghi giấc ngủ ${GB.dur(elapsed)}');",
            "                      final saved = Entry(type: T.sleep, time: s, end: e);\n                      app.addEntry(saved);\n                      toast(context, 'Đã ghi giấc ngủ ${GB.dur(elapsed)}', undo: () => app.removeEntry(saved.id));")
    return s


edit(r'ui\sleep_screen.dart', sleep)


def diaper(s):
    s = rep(s, "  void _save() {\n    app.addEntry(Entry(type: T.diaper, time: time, data: {", "  void _save() {\n    final saved = Entry(type: T.diaper, time: time, data: {")
    s = rep(s, "      if (note.text.trim().isNotEmpty) 'note': note.text.trim(),\n    }));\n    toast(context, 'Đã ghi phân');", "      if (note.text.trim().isNotEmpty) 'note': note.text.trim(),\n    });\n    app.addEntry(saved);\n    toast(context, 'Đã ghi phân', undo: () => app.removeEntry(saved.id));")
    s = rep(s, "  void _saveWetOnly() {\n    app.addEntry(Entry(type: T.diaper, time: time, data: {", "  void _saveWetOnly() {\n    final saved = Entry(type: T.diaper, time: time, data: {")
    s = rep(s, "      if (note.text.trim().isNotEmpty) 'note': note.text.trim(),\n    }));\n    toast(context, 'Đã ghi tã ướt');", "      if (note.text.trim().isNotEmpty) 'note': note.text.trim(),\n    });\n    app.addEntry(saved);\n    toast(context, 'Đã ghi tã ướt', undo: () => app.removeEntry(saved.id));")
    return s


edit(r'ui\diaper_screen.dart', diaper)

# ---------- cài đặt: giờ hút theo chip, nhắc cữ bú
def models(s):
    s = rep(s, "  bool notify = false;", "  int feedRemindHours = 0; // nhắc cữ bú sau X giờ kể từ cữ trước (0 = tắt)\n  bool notify = false;")
    s = rep(s, "        'nf': notify,\n", "        'nf': notify,\n        'fr': feedRemindHours,\n")
    s = rep(s, "    s.notify = j['nf'] == true;\n", "    s.notify = j['nf'] == true;\n    s.feedRemindHours = (j['fr'] as num?)?.toInt() ?? 0;\n")
    return s


edit(r'data\models.dart', models)


def settings(s):
    a = s.index("              _stepRow('Số cữ hút/ngày'")
    b = s.index("              _stepRow('Mục tiêu từ sữa hút'")
    new = """              Text('Giờ hút mỗi ngày', style: GB.body(14.5, w: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Chạm để chọn các giờ mẹ thường hút. Số cữ mỗi ngày tính theo số giờ đã chọn, và dùng để nhắc cữ hút.', style: GB.body(12, color: GB.inkMuted, height: 1.35)),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (var h = 0; h < 24; h++)
                  PillChip(
                    label: '${h}h',
                    on: s.pumpTimes.contains(h),
                    height: 34,
                    hPad: 10,
                    onTap: () {
                      final t = [...s.pumpTimes];
                      if (t.contains(h)) {
                        if (t.length <= 2) {
                          toast(context, 'Giữ ít nhất 2 cữ hút mỗi ngày');
                          return;
                        }
                        t.remove(h);
                      } else {
                        t.add(h);
                      }
                      t.sort();
                      s.pumpTimes = t;
                      s.pumpSessions = t.length;
                      app.settingsChanged();
                    },
                  ),
              ]),
              const SizedBox(height: 4),
              Text('Đã chọn ${s.pumpTimes.length} cữ mỗi ngày', style: GB.body(12.5, w: FontWeight.w700, color: GB.accentDeep)),
              const SizedBox(height: 6),
"""
    s = s[:a] + new + s[b:]
    old = "            _card('Nhắc nhở', [\n"
    s = rep(s, old, old + """              _stepRow('Nhắc cữ bú sau', s.feedRemindHours == 0 ? 'Tắt' : '${s.feedRemindHours} giờ', () {
                if (s.feedRemindHours > 0) s.feedRemindHours--;
                app.settingsChanged();
              }, () {
                if (s.feedRemindHours < 6) s.feedRemindHours++;
                app.settingsChanged();
              }),
              Text('Nhắc khi đã qua số giờ này kể từ cữ bú gần nhất (hiện ở Trang chủ và thông báo).', style: GB.body(12, color: GB.inkMuted, height: 1.35)),
              const SizedBox(height: 6),
""")
    return s


edit(r'ui\settings.dart', settings)


def reminders(s):
    return rep(s, "  // sữa trong tủ sắp hết hạn trong 2 giờ", """  // nhắc cữ bú: đã qua X giờ kể từ cữ bú gần nhất (trong 30 phút đầu sau mốc đó)
  final last = app.lastFeed;
  if (s.feedRemindHours > 0 && last != null) {
    final since = now.difference(last.time);
    final h = s.feedRemindHours;
    if (since.inMinutes >= h * 60 && since.inMinutes < h * 60 + 30) {
      out.add(DueReminder('feed-${last.id}', 'Đến cữ bú', 'Đã ${GB.dur(since)} kể từ cữ bú trước (${GB.hm(last.time)}).'));
    }
  }
  // sữa trong tủ sắp hết hạn trong 2 giờ""")


edit(r'core\reminders.dart', reminders)


def home(s):
    return rep(s, "      final exp = app.fridgeActive.where(", """      final lf = app.lastFeed;
      final fr = app.settings.feedRemindHours;
      if (fr > 0 && lf != null && now.difference(lf.time).inMinutes >= fr * 60) {
        items.add(_remind(Icons.local_drink_rounded, GB.breastDeep, 'Đến cữ bú', 'Đã ${GB.dur(now.difference(lf.time))} kể từ cữ bú trước', () => openPage(context, const FeedScreen())));
      }
      final exp = app.fridgeActive.where(""")


edit(r'ui\home.dart', home)
print('ok')
