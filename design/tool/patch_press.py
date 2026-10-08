# -*- coding: utf-8 -*-
import os
ROOT = r'F:\Project Ai\GinBaby\app\lib'


def edit(rel, fn):
    p = os.path.join(ROOT, rel)
    s = open(p, encoding='utf-8').read()
    s = fn(s)
    open(p, 'w', encoding='utf-8').write(s)


def rep(s, old, new, cnt=1):
    assert old in s, old[:90]
    return s.replace(old, new, cnt)


PRESSABLE = '''
/// Hiệu ứng chạm kiểu iOS: nhấn xuống thì co nhẹ và mờ đi, thả ra thì bật lại mềm (lò xo), kèm rung nhẹ trên điện thoại.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap, this.onLongPress, this.scale = .95, this.dim = .78, this.haptic = true, this.behavior = HitTestBehavior.opaque});
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale; // tỉ lệ khi nhấn (thẻ lớn nên dùng .985)
  final double dim; // độ đậm khi nhấn
  final bool haptic;
  final HitTestBehavior behavior;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;
  DateTime _since = DateTime.now();

  void _press() {
    _since = DateTime.now();
    if (!_down) setState(() => _down = true);
  }

  // Chạm rất nhanh vẫn giữ trạng thái nhấn đủ lâu để mắt kịp thấy.
  void _release() {
    final left = 90 - DateTime.now().difference(_since).inMilliseconds;
    if (left > 0) {
      Future.delayed(Duration(milliseconds: left), () {
        if (mounted) setState(() => _down = false);
      });
    } else if (_down) {
      setState(() => _down = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null && widget.onLongPress == null) return widget.child;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: (_) => _press(),
      onTapUp: (_) => _release(),
      onTapCancel: _release,
      onTap: widget.onTap == null
          ? null
          : () {
              if (widget.haptic) HapticFeedback.selectionClick();
              widget.onTap!();
            },
      onLongPress: widget.onLongPress == null
          ? null
          : () {
              if (widget.haptic) HapticFeedback.mediumImpact();
              widget.onLongPress!();
            },
      child: reduce
          ? widget.child
          : AnimatedScale(
              scale: _down ? widget.scale : 1,
              duration: Duration(milliseconds: _down ? 90 : 320),
              curve: _down ? Curves.easeOut : Curves.elasticOut,
              child: AnimatedOpacity(
                opacity: _down ? widget.dim : 1,
                duration: Duration(milliseconds: _down ? 70 : 220),
                child: widget.child,
              ),
            ),
    );
  }
}
'''


def kit(s):
    s = rep(s, "import 'package:flutter/material.dart';\n", "import 'package:flutter/material.dart';\nimport 'package:flutter/services.dart';\n")
    s = rep(s, "/// Hình minh hoạ màu nước trong assets/art", PRESSABLE.lstrip('\n') + "\n/// Hình minh hoạ màu nước trong assets/art")
    # thẻ bấm được: co rất nhẹ
    s = rep(s, "card = GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: card);", "card = Pressable(scale: .985, dim: .88, onTap: onTap, child: card);")
    # Seg
    s = rep(s, "            child: GestureDetector(\n              behavior: HitTestBehavior.opaque,\n              onTap: () => onChanged(i),", "            child: Pressable(\n              scale: .94,\n              dim: .8,\n              onTap: () => onChanged(i),")
    # PillChip
    s = rep(s, "      child: GestureDetector(\n        behavior: HitTestBehavior.opaque,\n        onTap: onTap,\n        child: Container(\n          height: height,\n          padding: EdgeInsets.symmetric(horizontal: hPad),", "      child: Pressable(\n        scale: .93,\n        onTap: onTap,\n        child: Container(\n          height: height,\n          padding: EdgeInsets.symmetric(horizontal: hPad),")
    # BigButton
    s = rep(s, "      child: GestureDetector(\n        behavior: HitTestBehavior.opaque,\n        onTap: on ? onTap : null,", "      child: Pressable(\n        scale: .965,\n        dim: .86,\n        onTap: on ? onTap : null,")
    # RoundIconButton
    s = rep(s, "      child: GestureDetector(\n        behavior: HitTestBehavior.opaque,\n        onTap: onTap,\n        child: Container(\n          width: size,\n          height: size,", "      child: Pressable(\n        scale: .9,\n        onTap: onTap,\n        child: Container(\n          width: size,\n          height: size,")
    # SectionTitle trailing
    s = rep(s, "            GestureDetector(\n              behavior: HitTestBehavior.opaque,\n              onTap: onTrailing,", "            Pressable(\n              scale: .94,\n              onTap: onTrailing,")
    # back
    s = rep(s, "    final back = GestureDetector(\n      behavior: HitTestBehavior.opaque,\n      onTap: () => Navigator.of(context).maybePop(),", "    final back = Pressable(\n      scale: .88,\n      onTap: () => Navigator.of(context).maybePop(),")
    # chuyển trang kiểu iOS: trượt từ phải, vuốt cạnh trái để quay lại
    a = s.index("Future<T?> openPage<T>(BuildContext context, Widget page) {")
    b = s.index("Future<T?> showGlassSheet")
    s = s[:a] + "Future<T?> openPage<T>(BuildContext context, Widget page) {\n  return Navigator.of(context).push<T>(CupertinoPageRoute<T>(builder: (_) => page));\n}\n\n" + s[b:]
    s = rep(s, "import 'package:flutter/material.dart';\n", "import 'package:flutter/cupertino.dart' show CupertinoPageRoute;\nimport 'package:flutter/material.dart';\n")
    return s


edit(r'core\kit.dart', kit)


def pastel(s):
    s = rep(s, "      child: GestureDetector(\n        behavior: HitTestBehavior.opaque,\n        onTap: onTap,\n        onLongPress: onLong,", "      child: Pressable(\n        scale: .93,\n        dim: .85,\n        onTap: onTap,\n        onLongPress: onLong,")
    s = rep(s, "    return GestureDetector(\n      behavior: HitTestBehavior.opaque,\n      onTap: onTap,\n      child: Container(\n        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),", "    return Pressable(\n      scale: .93,\n      onTap: onTap,\n      child: Container(\n        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),")
    return s


edit(r'core\pastel.dart', pastel)


def main(s):
    s = rep(s, "              child: GestureDetector(\n                behavior: HitTestBehavior.opaque,\n                onTap: () => onTap(i),", "              child: Pressable(\n                scale: .88,\n                dim: .7,\n                onTap: () => onTap(i),")
    return s


edit(r'main.dart', main)
print('ok')
