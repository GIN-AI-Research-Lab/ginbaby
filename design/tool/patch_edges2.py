# -*- coding: utf-8 -*-
import os, re, glob
ROOT = r'F:\Project Ai\GinBaby\app\lib'
def rd(rel): return open(os.path.join(ROOT, rel), encoding='utf-8').read()
def wr(rel, s): open(os.path.join(ROOT, rel), 'w', encoding='utf-8').write(s)
def rep(s, old, new, cnt=1):
    assert old in s, old[:90]
    return s.replace(old, new, cnt)

# viền thẻ kính ở chế độ sáng: nâu hồng nhạt (viền trắng bị chìm vào nền sáng)
t = rd(r'core\theme.dart')
t = rep(t, "get line => dark ? const Color(0xFF7468B0) : const Color(0xFFE6CDC6)", "get line => dark ? const Color(0xFF7468B0) : const Color(0xFFDDB9B0)")
wr(r'core\theme.dart', t)

k = rd(r'core\kit.dart')
k = rep(k, "border: Border.all(color: GB.dark ? Colors.white.withValues(alpha: .28) : Colors.white.withValues(alpha: .95), width: 1.2),",
        "border: Border.all(color: GB.dark ? Colors.white.withValues(alpha: .30) : const Color(0xFFD3A097).withValues(alpha: .60), width: 1.2),")
# nút phụ (nền trong suốt) cần viền đậm
k = rep(k, "border: Border.all(color: Colors.white.withValues(alpha: .35), width: 1.2),\n              boxShadow: [BoxShadow(color: color.withValues(alpha: .38)",
        "border: Border.all(color: color.a < .95 ? GB.edgeOf(GB.line) : Colors.white.withValues(alpha: .35), width: 1.2),\n              boxShadow: [BoxShadow(color: color.withValues(alpha: color.a < .95 ? .12 : .38)")
# ô nhập
k = rep(k, "        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: GB.line)),\n        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: GB.line)),",
        "        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: GB.edgeOf(GB.line), width: 1.3)),\n        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: GB.edgeOf(GB.line), width: 1.3)),")
wr(r'core\kit.dart', k)

# thanh tab kính: viền nâu hồng ở chế độ sáng
m = rd('main.dart')
m = rep(m, "border: Border.all(color: glass ? (GB.dark ? Colors.white.withValues(alpha: .3) : Colors.white) : GB.line, width: 1.2),",
        "border: Border.all(color: glass ? (GB.dark ? Colors.white.withValues(alpha: .3) : const Color(0xFFD3A097).withValues(alpha: .65)) : GB.line, width: 1.2),")
wr('main.dart', m)

# bộ lọc lịch sử
h = rd(r'ui\history.dart')
h = rep(h, "                  boxShadow: filter == k.type ? [BoxShadow(color: k.deep.withValues(alpha: .28), blurRadius: 10, offset: const Offset(0, 4))] : null,",
        "                  border: Border.all(color: filter == k.type ? k.deep.withValues(alpha: .85) : GB.edgeOf(k.tile), width: filter == k.type ? 1.6 : 1.1),\n                  boxShadow: filter == k.type ? [BoxShadow(color: k.deep.withValues(alpha: .28), blurRadius: 10, offset: const Offset(0, 4))] : null,")
h = rep(h, "color: filter == k.type ? k.tile : k.tile.withValues(alpha: .45),", "color: filter == k.type ? k.tile : k.tile.withValues(alpha: .7),")
wr(r'ui\history.dart', h)

# ô chọn ảnh (màu phân, kết cấu, số lượng)
d = rd(r'ui\diaper_screen.dart')
d = rep(d, "border: Border.all(color: selected ? GB.accent.withValues(alpha: .55) : Colors.transparent, width: 1.4),",
        "border: Border.all(color: selected ? GB.accent : GB.edgeOf(GB.p(Color(0xFFFFE9E2))), width: selected ? 1.8 : 1.1),")
wr(r'ui\diaper_screen.dart', d)

# viền cùng sắc cho mọi ô tô màu còn thiếu viền
def add_edge(src):
    out, i, key, n = [], 0, "BoxDecoration(color: ", 0
    while True:
        j = src.find(key, i)
        if j < 0:
            out.append(src[i:]); break
        a = j + len(key); depth = 0; k = a
        while k < len(src):
            c = src[k]
            if c in '([{': depth += 1
            elif c in ')]}':
                if depth == 0: break
                depth -= 1
            elif c == ',' and depth == 0: break
            k += 1
        expr = src[a:k]
        m = re.match(r",\s*borderRadius: BorderRadius\.circular\((\d+(?:\.\d+)?)\)\)", src[k:k + 120])
        if m and float(m.group(1)) >= 9 and 'GB.card' not in expr and 'Colors.transparent' not in expr:
            out.append(src[i:k + m.end() - 1]); out.append(f", border: Border.all(color: GB.edgeOf({expr}), width: 1)")
            i = k + m.end() - 1; n += 1
        else:
            out.append(src[i:k]); i = k
    return ''.join(out), n

tot = 0
for f in glob.glob(os.path.join(ROOT, 'ui', '*.dart')) + [os.path.join(ROOT, 'core', 'kit.dart'), os.path.join(ROOT, 'core', 'pastel.dart'), os.path.join(ROOT, 'core', 'pickers.dart')]:
    s = open(f, encoding='utf-8').read()
    s2, n = add_edge(s)
    if n:
        open(f, 'w', encoding='utf-8').write(s2)
        print(os.path.basename(f), n)
        tot += n
print('added', tot)
