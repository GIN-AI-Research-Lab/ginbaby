# -*- coding: utf-8 -*-
"""Thêm viền cho thẻ, ô, nút để phân biệt với nền (đủ rõ ở cả sáng và tối)."""
import os
import re

ROOT = r'F:\Project Ai\GinBaby\app\lib'


def rd(rel):
    return open(os.path.join(ROOT, rel), encoding='utf-8').read()


def wr(rel, s):
    open(os.path.join(ROOT, rel), 'w', encoding='utf-8').write(s)


def rep(s, old, new, cnt=1):
    assert old in s, old[:90]
    return s.replace(old, new, cnt)


# ---- theme: màu nền, thẻ, viền
t = rd(r'core\theme.dart')
t = rep(t, "dark ? const Color(0xFF2B2430) : const Color(0xFFFDF6F0)", "dark ? const Color(0xFF2B2430) : const Color(0xFFFBEEE8)")
t = rep(t, "dark ? const Color(0xFF362D3C) : const Color(0xFFFCEFEA)", "dark ? const Color(0xFF362D3C) : const Color(0xFFFAE6E1)")
t = rep(t, "get card => dark ? const Color(0xFF3A3040) : const Color(0xFFFFFAF8)", "get card => dark ? const Color(0xFF3A3040) : const Color(0xFFFFFFFF)")
t = rep(t, "get line => dark ? const Color(0xFF50445A) : const Color(0xFFF3E4DF)", "get line => dark ? const Color(0xFF5E506B) : const Color(0xFFE6CDC6)")
t = rep(t, "  static Color get bg =>", """  /// Viền cho ô tô màu [fill]: cùng sắc nhưng đậm hơn (sáng) hoặc sáng hơn (tối) để nổi lên khỏi nền.
  static Color edgeOf(Color fill) {
    final o = fill.withValues(alpha: 1);
    return dark ? Color.lerp(o, Colors.white, .30)!.withValues(alpha: .55) : Color.lerp(o, const Color(0xFF8B4A47), .30)!.withValues(alpha: .70);
  }

  static Color get bg =>""")
wr(r'core\theme.dart', t)

# ---- kit: thẻ, tag
k = rd(r'core\kit.dart')
k = rep(k, "        borderRadius: br,\n        boxShadow: shadow ? [BoxShadow(color: const Color(0xFFD9A79F).withValues(alpha: .13), blurRadius: 16, offset: const Offset(0, 5))] : null,",
        "        borderRadius: br,\n        border: Border.all(color: tint != null ? GB.edgeOf(tint!) : GB.line, width: 1.2),\n        boxShadow: shadow ? [BoxShadow(color: const Color(0xFFC98C84).withValues(alpha: GB.dark ? .10 : .20), blurRadius: 14, offset: const Offset(0, 4))] : null,")
k = rep(k, "decoration: BoxDecoration(color: bg ?? GB.p(const Color(0xFFFBE3CF)), borderRadius: BorderRadius.circular(9)),",
        "decoration: BoxDecoration(color: bg ?? GB.p(const Color(0xFFFBE3CF)), borderRadius: BorderRadius.circular(9), border: Border.all(color: GB.edgeOf(bg ?? GB.p(const Color(0xFFFBE3CF))), width: 1)),")
# nút chính: viền sáng bên trong cho nổi, bóng đậm hơn
k = rep(k, "boxShadow: [BoxShadow(color: color.withValues(alpha: .28), blurRadius: 14, offset: const Offset(0, 6))],",
        "border: Border.all(color: Colors.white.withValues(alpha: .35), width: 1.2),\n              boxShadow: [BoxShadow(color: color.withValues(alpha: .38), blurRadius: 14, offset: const Offset(0, 6))],")
# chip chưa chọn: viền đậm hơn
k = rep(k, "border: Border.all(color: on ? Colors.transparent : GB.line),", "border: Border.all(color: on ? Colors.transparent : GB.edgeOf(GB.line), width: 1.2),")
wr(r'core\kit.dart', k)

# ---- pastel: ô hoạt động, pill
p = rd(r'core\pastel.dart')
p = rep(p, "            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [tile.withValues(alpha: .75), tile]),\n            boxShadow: [BoxShadow(color: deep.withValues(alpha: .22), blurRadius: 14, offset: const Offset(0, 6))],",
        "            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [tile.withValues(alpha: .85), tile]),\n            border: Border.all(color: deep.withValues(alpha: GB.dark ? .55 : .75), width: 1.4),\n            boxShadow: [BoxShadow(color: deep.withValues(alpha: .30), blurRadius: 14, offset: const Offset(0, 6))],")
p = rep(p, "decoration: BoxDecoration(color: bg ?? GB.accentSoft, borderRadius: BorderRadius.circular(18)),",
        "decoration: BoxDecoration(color: bg ?? GB.accentSoft, borderRadius: BorderRadius.circular(18), border: Border.all(color: (fg ?? GB.accentDeep).withValues(alpha: .45), width: 1.1)),")
p = rep(p, "decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),", "decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: GB.edgeOf(bg), width: 1)),")
wr(r'core\pastel.dart', p)


# ---- các ô tô màu ở màn tổng quan, lịch sử, trang chủ: thêm viền cùng sắc
def add_edge(src):
    out = []
    i = 0
    key = "BoxDecoration(color: "
    n = 0
    while True:
        j = src.find(key, i)
        if j < 0:
            out.append(src[i:])
            break
        a = j + len(key)
        depth = 0
        k = a
        while k < len(src):
            c = src[k]
            if c in '([{':
                depth += 1
            elif c in ')]}':
                if depth == 0:
                    break
                depth -= 1
            elif c == ',' and depth == 0:
                break
            k += 1
        expr = src[a:k]
        rest = src[k:k + 120]
        m = re.match(r",\s*borderRadius: BorderRadius\.circular\((\d+(?:\.\d+)?)\)\)", rest)
        if m and float(m.group(1)) >= 9 and 'GB.card' not in expr and 'Colors.transparent' not in expr:
            out.append(src[i:k + m.end() - 1])
            out.append(f", border: Border.all(color: GB.edgeOf({expr}), width: 1)")
            i = k + m.end() - 1
            n += 1
        else:
            out.append(src[i:k])
            i = k
    return ''.join(out), n


for rel in [r'ui\home.dart', r'ui\overview.dart', r'ui\history.dart']:
    s, n = add_edge(rd(rel))
    wr(rel, s)
    print(rel, n)
print('ok')
