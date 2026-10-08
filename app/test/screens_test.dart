import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gin_baby/data/app_state.dart';
import 'package:gin_baby/data/demo.dart';
import 'package:gin_baby/domain/articles.dart';
import 'package:gin_baby/domain/stats.dart';
import 'package:gin_baby/ui/articles_screen.dart';
import 'package:gin_baby/ui/onboarding.dart';
import 'package:gin_baby/ui/recap.dart';
import 'package:gin_baby/ui/diaper_screen.dart';
import 'package:gin_baby/ui/easy_screen.dart';
import 'package:gin_baby/ui/family_screen.dart';
import 'package:gin_baby/ui/feed_screen.dart';
import 'package:gin_baby/ui/growth_screen.dart';
import 'package:gin_baby/ui/fund.dart';
import 'package:gin_baby/ui/guide.dart';
import 'package:gin_baby/ui/memory_screen.dart';
import 'package:gin_baby/ui/offline_screen.dart';
import 'package:gin_baby/ui/utilities_screen.dart';
import 'package:gin_baby/ui/health_hub.dart';
import 'package:gin_baby/ui/history.dart';
import 'package:gin_baby/ui/home.dart';
import 'package:gin_baby/ui/leaps_screen.dart';
import 'package:gin_baby/ui/milk_hub.dart';
import 'package:gin_baby/ui/mind_screen.dart';
import 'package:gin_baby/ui/money.dart';
import 'package:gin_baby/ui/overview.dart';
import 'package:gin_baby/ui/premium.dart';
import 'package:gin_baby/ui/pump_screen.dart';
import 'package:gin_baby/ui/settings.dart';
import 'package:gin_baby/ui/sleep_screen.dart';
import 'package:gin_baby/ui/solids_screen.dart';
import 'package:gin_baby/ui/vaccine_screen.dart';

Widget _host(Widget child, {double scale = 1.0}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    builder: (context, c) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)), child: c!),
    home: Scaffold(body: child),
  );
}

Future<void> _load(WidgetTester tester) async {
  await tester.pump();
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Nạp phông Inter thật (bộ test không tự nạp phông của app) để kiểm tra tràn chữ sát thực tế.
    final loader = FontLoader('Inter');
    for (final w in const ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
      loader.addFont(Future.value(ByteData.sublistView(File('assets/google_fonts/Inter-$w.ttf').readAsBytesSync())));
    }
    await loader.load();
    await seedDemo(app);
  });

  final screens = <String, Widget Function()>{
    'Trang chủ': () => HomeScreen(goTab: (_) {}),
    'Lịch sử (tab)': () => const HistoryScreen(asTab: true),
    'Thống kê': () => const OverviewScreen(),
    'Tiền': () => const MoneyTab(),
    'Hồ sơ': () => GuideTab(goTab: (_) {}),
    'Tiện ích': () => UtilitiesTab(goTab: (_) {}),
    'Tuỳ chỉnh menu': () => const MenuCustomizeScreen(),
    'Hút sữa': () => const PumpScreen(),
    'Ghi bú': () => const FeedScreen(),
    'Cho bú': () => const FeedScreen(initialTab: 1),
    'Giấc ngủ': () => const SleepScreen(),
    'Phân của bé': () => const DiaperScreen(),
    'Wonder Weeks': () => const LeapsScreen(),
    'Tủ sữa': () => const MilkHub(),
    'Nhịp EASY': () => const EasyScreen(),
    'Tiêm chủng': () => const VaccineScreen(),
    'Tăng trưởng': () => const GrowthScreen(),
    'Ăn dặm': () => const SolidsScreen(),
    'Cẩm nang': () => const ArticlesScreen(),
    'Sức khoẻ': () => const HealthHub(),
    'Góc của mẹ': () => const MindScreen(),
    'Gia đình': () => const FamilyScreen(),
    'Premium': () => const PremiumScreen(),
    'Cài đặt': () => const SettingsScreen(),
    'Hồ sơ bé (sửa)': () => const Onboarding(edit: true),
    'Thêm khoản chi': () => const MoneyAddScreen(),
    'Thêm vào quỹ': () => const FundEditScreen(),
    'Nhật ký mốc': () => const MemoryJournalScreen(),
    'Ghi kỷ niệm': () => const MemoryEditScreen(memoKey: 'f_roll', title: 'Lần đầu lật'),
    'Thẻ kỷ niệm': () => MemoryCardScreen(app.memos.values.first),
    'Thẻ tổng kết': () => RecapScreen(weekStart: Stats.weekStart(DateTime.now())),
    'Bài cẩm nang': () => ArticleDetail(kArticles.first),
    'Lịch sử (trang)': () => const HistoryScreen(),
    'Kiểm tra ngoại tuyến': () => const OfflineScreen(),
  };

  // Không có ngoại lệ bố cục (tràn chữ, RenderFlex) ở màn hẹp 320px và cỡ chữ hệ thống 125%.
  for (final e in screens.entries) {
    for (final scale in const [1.0, 1.25]) {
      testWidgets('${e.key} không tràn ở 320px, chữ x$scale', (tester) async {
        tester.view.physicalSize = const Size(320 * 2, 700 * 2);
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.resetPhysicalSize);
        await tester.pumpWidget(_host(e.value(), scale: scale));
        await _load(tester);
        // Ngoại lệ bố cục (tràn chữ) làm test thất bại và in vị trí widget gây lỗi.
      });
    }
  }

  testWidgets('Quỹ của con: mở tab Quỹ không tràn ở 320px', (tester) async {
    tester.view.physicalSize = const Size(320 * 2, 700 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(_host(const MoneyTab()));
    await _load(tester);
    await tester.tap(find.text('Quỹ của con'));
    await tester.pump(const Duration(seconds: 1));
    await _load(tester);
    expect(find.textContaining('quỹ'), findsWidgets);
  });

  testWidgets('Giấc ngủ: Ngủ ngay rồi Bé dậy rồi', (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 800 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    app.entries.removeWhere((x) => x.type == 'sleep' && x.end == null);
    await tester.pumpWidget(_host(const SleepScreen()));
    await tester.pump();
    expect(app.activeSleep, isNull);
    await tester.tap(find.text('Ngủ ngay'));
    await tester.pump(const Duration(seconds: 3));
    expect(app.activeSleep, isNotNull);
    expect(find.text('Bé dậy rồi'), findsOneWidget);
    await tester.tap(find.text('Bé dậy rồi'));
    await tester.pump(const Duration(seconds: 3));
    expect(app.activeSleep, isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Phân của bé: lưu một cữ phân và một cữ chỉ tã ướt', (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 1600 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    final before = app.entries.where((x) => x.type == 'diaper').length;
    await tester.pumpWidget(_host(const DiaperScreen()));
    await tester.pump();
    await tester.tap(find.text('Xanh rêu'));
    await tester.pump();
    await tester.tap(find.text('Nhiều'));
    await tester.pump();
    await tester.tap(find.text('Lưu cữ thay tã'));
    await tester.pump(const Duration(seconds: 3));
    var list = app.entries.where((x) => x.type == 'diaper').toList();
    expect(list.length, before + 1);
    final saved = list.firstWhere((x) => x.str('color') == 'Xanh rêu' && x.str('amount') == 'Nhiều');
    expect(saved.str('kind'), 'both');

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(_host(const DiaperScreen()));
    await tester.pump();
    await tester.tap(find.text('Chỉ có tã ướt, không có phân'));
    await tester.pump(const Duration(seconds: 3));
    list = app.entries.where((x) => x.type == 'diaper').toList();
    expect(list.length, before + 2);
    expect(list.where((x) => x.str('kind') == 'wet').isNotEmpty, true);
    await tester.pumpWidget(const SizedBox());
  });
}
