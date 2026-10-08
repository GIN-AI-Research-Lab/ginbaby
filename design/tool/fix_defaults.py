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


def kit(s):
    # BigButton
    s = rep(s, "this.icon, this.color = GB.accent, this.fg = Colors.white, this.height = 48, this.enabled = true});\n  final String label;\n  final VoidCallback? onTap;\n  final IconData? icon;\n  final Color color;\n  final Color fg;",
            "this.icon, this.color, this.fg, this.height = 48, this.enabled = true});\n  final String label;\n  final VoidCallback? onTap;\n  final IconData? icon;\n  final Color? color;\n  final Color? fg;")
    s = rep(s, "    final fg = color == GB.accent ? Colors.white : this.fg;\n", "    final color = this.color ?? GB.accent;\n    final fg = color == GB.accent ? Colors.white : (this.fg ?? Colors.white);\n")
    # Tag
    s = rep(s, "  Tag(this.text, {super.key, this.bg = GB.p(Color(0xFFFBE3CF)), this.fg = GB.f(Color(0xFF8A4A1E))});\n  final String text;\n  final Color bg;\n  final Color fg;",
            "  const Tag(this.text, {super.key, this.bg, this.fg});\n  final String text;\n  final Color? bg;\n  final Color? fg;")
    s = rep(s, "        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),\n        child: Text(text, style: GB.body(11.5, w: FontWeight.w700, color: fg)),",
            "        decoration: BoxDecoration(color: bg ?? GB.p(const Color(0xFFFBE3CF)), borderRadius: BorderRadius.circular(9)),\n        child: Text(text, style: GB.body(11.5, w: FontWeight.w700, color: fg ?? GB.f(const Color(0xFF8A4A1E)))),")
    # RangeBar
    s = rep(s, "this.maxV, this.color = GB.accent});\n  final double value;\n  final double lo;\n  final double hi;\n  final double? maxV;\n  final Color color;",
            "this.maxV, this.color});\n  final double value;\n  final double lo;\n  final double hi;\n  final double? maxV;\n  final Color? color;")
    s = rep(s, "height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)))),\n        ]),\n      );\n    });", "height: 8, decoration: BoxDecoration(color: color ?? GB.accent, borderRadius: BorderRadius.circular(4)))),\n        ]),\n      );\n    });")
    return s


edit(r'core\kit.dart', kit)


def pastel(s):
    s = rep(s, "this.arrow = true, this.bg = GB.accentSoft, this.fg = GB.accentDeep});", "this.arrow = true, this.bg, this.fg});")
    return s


edit(r'core\pastel.dart', pastel)
