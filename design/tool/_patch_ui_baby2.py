# -*- coding: utf-8 -*-
import io
BASE = r'F:\Project Ai\GinBaby\app\lib'


def rw(path, f):
    p = BASE + '\\' + path
    s = io.open(p, encoding='utf-8').read()
    io.open(p, 'w', encoding='utf-8').write(f(s))


def rep(s, old, new, count=1):
    assert old in s, old[:70]
    return s.replace(old, new, count)


def home(s):
    s = rep(s, """            Flexible(
              child: GlassCard(
                radius: 22,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: FittedBox(fit: BoxFit.scaleDown, child: Text('${app.baby!.name} · $ageLabel', style: GB.body(13, w: FontWeight.w700, color: GB.accentDeep))),
              ),
            ),""", """            Flexible(
              child: Semantics(
                button: true,
                label: 'Chuyển bé. Đang xem ${app.baby!.name}',
                child: GlassCard(
                  radius: 22,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  onTap: () => showBabySwitcher(context),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text('${app.baby!.name} · $ageLabel', style: GB.body(13, w: FontWeight.w700, color: GB.accentDeep)))),
                    Icon(Icons.unfold_more_rounded, size: 18, color: GB.accentDeep),
                  ]),
                ),
              ),
            ),""")
    s = rep(s, "import 'features.dart';", "import 'babies.dart';\nimport 'features.dart';") if "import 'features.dart';" in s else rep(s, "import 'history.dart';", "import 'babies.dart';\nimport 'history.dart';")
    return s


rw('ui\\home.dart', home)


def guide(s):
    s = rep(s, """            GlassCard(
              radius: 26,
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                Row(children: [
                  Container(
                    width: 60,""", """            const BabyStrip(),
            const SizedBox(height: 10),
            GlassCard(
              radius: 26,
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                Row(children: [
                  Container(
                    width: 60,""")
    s = rep(s, "import 'articles_screen.dart';", "import 'articles_screen.dart';\nimport 'babies.dart';")
    return s


rw('ui\\guide.dart', guide)
print('ok')
