# -*- coding: utf-8 -*-
"""Ba mức kính mờ: 0 tắt, 1 nhẹ (chỉ làm mờ thanh dưới và bảng popup), 2 đầy đủ (làm mờ cả thẻ). Mặc định 1 cho mượt trên iPhone."""
import io

ROOT = r'F:\Project Ai\GinBaby\app\lib'


def edit(rel, fn):
    p = ROOT + '\\' + rel
    s = io.open(p, encoding='utf-8').read()
    s = fn(s)
    io.open(p, 'w', encoding='utf-8').write(s)


def rep(s, a, b):
    assert a in s, a[:80]
    return s.replace(a, b, 1)


edit(r'data\models.dart', lambda s: rep(rep(rep(s,
    "  bool glass = true; // hiệu ứng kính mờ", "  int glassMode = 1; // kính mờ: 0 tắt, 1 nhẹ (thanh dưới, popup), 2 đầy đủ (cả thẻ)"),
    "        'gl': glass,", "        'gm': glassMode,"),
    "    s.glass = j['gl'] != false;", "    s.glassMode = (j['gm'] as num?)?.toInt() ?? (j['gl'] == false ? 0 : 1);"))

edit(r'core\theme.dart', lambda s: rep(s, "  static bool glass = true;", "  static bool glass = true; // có dùng kiểu kính (nền trong mờ, viền sáng, làm mờ thanh dưới và popup)\n  static bool glassCards = false; // làm mờ cả nền phía sau từng thẻ (nặng hơn, chỉ ở mức Đầy đủ)"))


def main(s):
    s = rep(s, "        GB.glass = app.settings.glass;", "        GB.glass = app.settings.glassMode > 0;\n        GB.glassCards = app.settings.glassMode == 2;")
    s = rep(s, "      app.settings.glass = gl != '0';", "      app.settings.glassMode = int.tryParse(gl) ?? 1;")
    return s


edit('main.dart', main)


def kit(s):
    s = rep(s, "    this.shadow = true,\n  });", "    this.shadow = true,\n    this.forceBlur = false,\n  });")
    s = rep(s, "  final bool shadow;\n\n  @override", "  final bool shadow;\n  final bool forceBlur; // luôn làm mờ nền phía sau (popup), kể cả khi thẻ thường không làm mờ\n\n  @override")
    s = rep(s, "      child: glass ? ClipRRect(borderRadius: br, child: BackdropFilter(filter: ImageFilter.blur(sigmaX: blur * .7, sigmaY: blur * .7), child: inner)) : inner,",
            "      child: glass && (GB.glassCards || forceBlur) ? ClipRRect(borderRadius: br, child: BackdropFilter(filter: ImageFilter.blur(sigmaX: blur * .7, sigmaY: blur * .7), child: inner)) : inner,")
    s = rep(s, "blurRadius: glass ? 22 : 14, offset: const Offset(0, 6))] : null,", "blurRadius: GB.glassCards ? 22 : 12, offset: const Offset(0, 4))] : null,")
    s = rep(s, "        child: GlassCard(\n          radius: 30,\n          padding: EdgeInsets.zero,\n          child: Stack(children: [", "        child: GlassCard(\n          radius: 30,\n          padding: EdgeInsets.zero,\n          forceBlur: true,\n          child: Stack(children: [")
    return s


edit(r'core\kit.dart', kit)


def settings(s):
    a = s.index("              _switch('Hiệu ứng kính mờ',")
    b = s.index("              Text('Chế độ tối dịu mắt khi cho bé bú ban đêm.")
    new = """              Text('Hiệu ứng kính mờ', style: GB.body(14.5, w: FontWeight.w700)),
              const SizedBox(height: 6),
              Seg(labels: const ['Tắt', 'Nhẹ', 'Đầy đủ'], index: s.glassMode.clamp(0, 2), height: 42, onChanged: (i) {
                s.glassMode = i;
                app.settingsChanged();
              }),
              const SizedBox(height: 6),
              Text('Nhẹ: làm mờ thanh dưới và bảng popup, mượt nhất. Đầy đủ: làm mờ cả từng thẻ, đẹp hơn nhưng nặng, có thể giật trên máy cũ. Tắt: thẻ phẳng, nhẹ nhất.', style: GB.body(12, color: GB.inkMuted, height: 1.35)),
              const SizedBox(height: 10),
"""
    return s[:a] + new + s[b:]


edit(r'ui\settings.dart', settings)
print('ok')
