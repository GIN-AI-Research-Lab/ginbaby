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


def models(s):
    s = rep(s, "  bool notify = false;", "  int themeMode = 0; // 0 theo máy, 1 sáng, 2 tối\n  bool notify = false;")
    s = rep(s, "        'nf': notify,\n", "        'nf': notify,\n        'tm': themeMode,\n")
    s = rep(s, "    s.notify = j['nf'] == true;\n", "    s.notify = j['nf'] == true;\n    s.themeMode = (j['tm'] as num?)?.toInt() ?? 0;\n")
    return s


edit(r'data\models.dart', models)


def main(s):
    a = s.index("class GinBabyApp extends StatelessWidget {")
    b = s.index("        builder: (context, child) {")
    head = """class GinBabyApp extends StatefulWidget {
  const GinBabyApp({super.key});

  @override
  State<GinBabyApp> createState() => _GinBabyAppState();
}

class _GinBabyAppState extends State<GinBabyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() => setState(() {});

  /// Chế độ tối: theo cài đặt của mẹ, hoặc theo hệ thống.
  bool get _dark {
    final m = app.settings.themeMode;
    if (m == 1) return false;
    if (m == 2) return true;
    return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final dark = _dark;
        GB.dark = dark;
        // Đổi sáng/tối thì dựng lại cả cây giao diện (các màn const cũng lấy lại màu).
        return KeyedSubtree(key: ValueKey(dark), child: _materialApp(dark));
      },
    );
  }

  Widget _materialApp(bool dark) {
    return MaterialApp(
"""
    # giữ phần thân MaterialApp cũ nhưng bỏ ValueListenableBuilder
    old = s[a:b]
    assert "MaterialApp(" in old
    tail = s[b:]
    s = s[:a] + head + """        title: 'GinBaby',
        scaffoldMessengerKey: messengerKey,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: dark ? Brightness.dark : Brightness.light,
          colorScheme: ColorScheme.fromSeed(seedColor: GB.accent, surface: GB.bg, brightness: dark ? Brightness.dark : Brightness.light),
          scaffoldBackgroundColor: GB.bg,
          splashFactory: NoSplash.splashFactory,
        ),
""" + tail
    return s


edit(r'main.dart', main)
