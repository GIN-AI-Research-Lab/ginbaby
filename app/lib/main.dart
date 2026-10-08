import 'dart:async';

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'core/kit.dart';
import 'core/art_catalog.dart';
import 'core/deeplink.dart';
import 'core/perf.dart';
import 'core/reminders.dart';
import 'core/platform.dart';
import 'core/update_banner.dart';
import 'core/theme.dart';
import 'data/app_state.dart';
import 'ui/home.dart';
import 'ui/history.dart';
import 'ui/money.dart';
import 'ui/onboarding.dart';
import 'ui/overview.dart';
import 'ui/features.dart';
import 'ui/guide.dart';
import 'ui/utilities_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ArtCatalog.load();
  disableBrowserHistory();
  runApp(const GinBabyApp());
  await app.init();
  requestPersistentStorage();
}

class GinBabyApp extends StatefulWidget {
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
        GB.glass = app.settings.glassMode > 0;
        GB.glassCards = app.settings.glassMode == 2;
        // Đổi sáng/tối thì dựng lại cả cây giao diện (các màn const cũng lấy lại màu).
        return KeyedSubtree(key: ValueKey(dark), child: _materialApp(dark));
      },
    );
  }

  Widget _materialApp(bool dark) {
    return MaterialApp(
        title: 'GinBaby',
        scaffoldMessengerKey: messengerKey,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: dark ? Brightness.dark : Brightness.light,
          colorScheme: ColorScheme.fromSeed(seedColor: GB.accent, surface: GB.bg, brightness: dark ? Brightness.dark : Brightness.light),
          scaffoldBackgroundColor: GB.bg,
          splashFactory: NoSplash.splashFactory,
        ),
        builder: (context, child) {
          // Trên màn hình rộng: hiện trong khung điện thoại để xem đúng tỷ lệ.
          final mq0 = MediaQuery.of(context);
          final size = mq0.size;
          // Giới hạn cỡ chữ hệ thống để bố cục không vỡ (tối đa 125%).
          Widget clampText(Widget c) => Builder(builder: (ctx) {
                final m = MediaQuery.of(ctx);
                return MediaQuery(data: m.copyWith(textScaler: m.textScaler.clamp(minScaleFactor: 1.0, maxScaleFactor: 1.25)), child: c);
              });
          if (size.width <= 600) return UpdateBanner(child: clampText(child!));
          final h = size.height < 900 ? size.height - 24 : 844.0;
          return ColoredBox(
            color: const Color(0xFF2A2320),
            child: Center(
              child: Container(
                width: 390,
                height: h,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(40), border: Border.all(color: const Color(0xFF4A3F39), width: 6)),
                child: MediaQuery(data: MediaQuery.of(context).copyWith(size: Size(390, h), padding: const EdgeInsets.only(top: 44)), child: UpdateBanner(child: clampText(child!))),
              ),
            ),
          );
        },
        home: const Root(),
    );
  }
}

class Root extends StatelessWidget {
  const Root({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        if (!app.ready) {
          return Scaffold(backgroundColor: GB.bg, body: GlassBackground(child: Center(child: CircularProgressIndicator(color: GB.accent))));
        }
        if (!app.hasBaby) return const Onboarding();
        return const Shell();
      },
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  // Đổi sáng/tối dựng lại cả cây giao diện: nhớ tab đang xem, và chỉ xử lý tham số ?dark=, ?go= ở lần mở đầu tiên.
  static bool _booted = false;
  static int _lastTab = 0;
  int tab = 0;
  Timer? _remind;

  @override
  void initState() {
    super.initState();
    // Thông báo trình duyệt: kiểm tra nhắc nhở đến hạn mỗi 45 giây khi app còn mở.
    _remind = Timer.periodic(const Duration(seconds: 45), (_) => checkAndNotify());
    final first = !_booted;
    _booted = true;
    if (!first) tab = _lastTab;
    final gl = first ? Uri.base.queryParameters['glass'] : null;
    if (gl != null) {
      app.settings.glassMode = int.tryParse(gl) ?? 1;
      app.settingsChanged();
    }
    final dk = first ? Uri.base.queryParameters['dark'] : null;
    if (dk != null) {
      app.settings.themeMode = dk == '1' ? 2 : 1;
      app.settingsChanged();
    }
    final f = first ? (Uri.base.queryParameters['go'] ?? '') : '';
    final t = RegExp(r'^/?tab(\d)$').firstMatch(f);
    if (t != null) tab = _lastTab = int.parse(t.group(1)!).clamp(0, 5);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Nạp sẵn tranh minh hoạ để không bị hiện muộn.
      for (final n in const ['hero_mom_baby', 'hero_pump', 'ic_pump', 'ic_breast', 'ic_bottle', 'ic_moon', 'baby_sleep', 'rainbow', 'pump_left', 'pump_right', 'hero_baby_awake', 'hero_diaper', 'poop_yellow', 'poop_mustard', 'poop_green', 'poop_brown', 'poop_black', 'poop_mucus', 'poop_silver', 'poop_blood', 'tex_liquid', 'tex_soft', 'tex_chunky', 'tex_hard', 'tex_foam', 'diaper_few', 'diaper_mid', 'diaper_lots']) {
        precacheImage(AssetImage('assets/art/$n.png'), context);
      }
      if (first) openDeepLink(context);
    });
  }

  @override
  void dispose() {
    _remind?.cancel();
    super.dispose();
  }

  void _go(int i) => setState(() => tab = _lastTab = i);

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(goTab: _go),
      const HistoryScreen(asTab: true),
      const OverviewScreen(),
      const MoneyTab(),
      GuideTab(goTab: _go),
      UtilitiesTab(goTab: _go),
    ];
    return Scaffold(
      body: GlassBackground(
        child: Stack(
          children: [
            Positioned.fill(
              child: KeyedSubtree(key: ValueKey(tab), child: pages[tab]),
            ),
            Positioned(left: 0, right: 0, bottom: 0, child: _TabBar(index: tab, goTab: _go)),
          ],
        ),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.index, required this.goTab});
  final int index;
  final void Function(int) goTab;

  /// Thanh dưới: Trang chủ, ba nút giữa mẹ tự chọn (mặc định Lịch sử, Thống kê, Tiền), Tiện ích và Hồ sơ.
  List<({String label, IconData icon, bool on, VoidCallback tap})> _items(BuildContext context) {
    final out = <({String label, IconData icon, bool on, VoidCallback tap})>[
      (label: 'Trang chủ', icon: Icons.home_rounded, on: index == kTabHome, tap: () => goTab(kTabHome)),
    ];
    for (final id in app.settings.footer) {
      final f = featureById(id);
      if (f == null) continue;
      out.add((label: f.id == 'money' ? 'Tiền' : f.title, icon: f.icon, on: f.tab != null && f.tab == index, tap: () => openFeature(context, f, goTab)));
    }
    out.add((label: 'Tiện ích', icon: Icons.apps_rounded, on: index == kTabUtilities, tap: () => goTab(kTabUtilities)));
    out.add((label: 'Hồ sơ', icon: Icons.person_rounded, on: index == kTabProfile, tap: () => goTab(kTabProfile)));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final glass = GB.glass;
    final bar = Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      decoration: BoxDecoration(
        color: glass ? null : GB.card,
        gradient: glass ? LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: GB.dark ? [Colors.white.withValues(alpha: .22), Colors.white.withValues(alpha: .12)] : [Colors.white.withValues(alpha: .86), Colors.white.withValues(alpha: .62)]) : null,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: glass ? (GB.dark ? Colors.white.withValues(alpha: .3) : const Color(0xFFD3A097).withValues(alpha: .65)) : GB.line, width: 1.2),
      ),
      child: Row(children: [
        for (final it in _items(context))
          Expanded(
            child: Semantics(
              button: true,
              selected: it.on,
              label: it.label,
              child: Pressable(
                scale: .88,
                dim: .7,
                onTap: it.tap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(it.icon, size: 24, color: it.on ? GB.accent : GB.inkMuted),
                    const SizedBox(height: 1),
                    FittedBox(fit: BoxFit.scaleDown, child: Text(it.label, maxLines: 1, style: GB.body(11.5, w: it.on ? FontWeight.w800 : FontWeight.w600, color: it.on ? GB.accent : GB.inkMuted))),
                  ]),
                ),
              ),
            ),
          ),
      ]),
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, (bottom > 0 ? bottom : 8) + 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: (GB.dark ? const Color(0xFF120A2E) : const Color(0xFFC98F86)).withValues(alpha: GB.dark ? .45 : .30), blurRadius: 26, offset: const Offset(0, 8))],
        ),
        child: glass ? ClipRRect(borderRadius: BorderRadius.circular(30), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22), child: bar)) : bar,
      ),
    );
  }
}
