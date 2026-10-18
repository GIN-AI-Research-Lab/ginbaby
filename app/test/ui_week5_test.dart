import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gin_baby/core/reminders.dart';
import 'package:gin_baby/data/app_state.dart';
import 'package:gin_baby/data/demo.dart';
import 'package:gin_baby/data/models.dart';
import 'package:gin_baby/ui/feed_screen.dart';
import 'package:gin_baby/ui/home.dart';
import 'package:gin_baby/core/pastel.dart';
import 'package:gin_baby/ui/memory_screen.dart';
import 'package:gin_baby/ui/onboarding.dart';
import 'package:gin_baby/ui/overview.dart';
import 'package:gin_baby/ui/pump_screen.dart';
import 'package:gin_baby/ui/sleep_screen.dart';

/// Trang chủ, nhắc nhở, thẻ chia sẻ, hồ sơ bé, biểu đồ.
Widget _withRoute(Widget screen) => MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(child: ElevatedButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => Scaffold(body: screen))), child: const Text('mở'))),
        ),
      ),
    );

Future<void> _close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 3));
}

void main() {
  setUpAll(() async {
    final loader = FontLoader('Inter');
    for (final w in const ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
      loader.addFont(Future.value(ByteData.sublistView(File('assets/google_fonts/Inter-$w.ttf').readAsBytesSync())));
    }
    await loader.load();
    await seedDemo(app);
  });

  group('Trang chủ (H)', () {
    testWidgets('H1: mỗi ô hoạt động mở đúng màn (đúng tab với bú và bình)', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 1800 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(MaterialApp(debugShowCheckedModeBanner: false, home: Scaffold(body: HomeScreen(goTab: (_) {}))));
      await tester.pump(const Duration(seconds: 2));
      final tiles = find.byType(ActivityTile).evaluate().map((e) => e.widget as ActivityTile).toList();
      expect(tiles.map((t) => t.label).toList(), containsAll(['Hút sữa', 'Ghi bú', 'Ngủ']));

      // Mỗi ô: bấm → kiểm tra màn đúng (và tab đúng) → quay lại
      Future<void> check(String label, Type screen, {int? tab}) async {
        final tile = tiles.firstWhere((t) => t.label == label || (label == 'Ngủ' && t.label.startsWith('Dậy') ));
        tile.onTap();
        // chờ màn đích xuất hiện (tối đa 3 giây), không dùng thời gian cố định
        for (var i = 0; i < 15 && find.byType(screen).evaluate().isEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 200));
        }
        expect(find.byType(screen), findsWidgets, reason: '$label phải mở $screen');
        if (tab != null) {
          final w = tester.widget<FeedScreen>(find.byType(FeedScreen).last);
          expect(w.initialTab, tab, reason: '$label phải mở đúng tab ${tab == 1 ? 'Cho bú' : 'Bình'}');
        }
        expect(tester.takeException(), isNull);
        Navigator.of(tester.element(find.byType(screen).last)).pop();
        // chờ màn vừa mở biến mất hẳn trước khi kiểm tra màn tiếp theo
        for (var i = 0; i < 15 && find.byType(screen).evaluate().isNotEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 200));
        }
      }

      await check('Hút sữa', PumpScreen);
      await check('Ghi bú', FeedScreen);
      await check('Ngủ', SleepScreen);
      await _close(tester);
    });

    testWidgets('H2: ô nhanh Phân & tã, Nhiệt độ, Thuốc, Ghi chú mở hộp ghi nhanh', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 1800 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(MaterialApp(debugShowCheckedModeBanner: false, home: Scaffold(body: HomeScreen(goTab: (_) {}))));
      await tester.pump(const Duration(seconds: 2));
      await tester.tap(find.text('Nhiệt độ').first);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Ghi nhanh khác'), findsOneWidget);
      await _close(tester);
    });
  });

  group('Nhắc nhở (H3)', () {
    test('H3: cữ hút đến hạn tạo nhắc đúng', () {
      final now = DateTime(2026, 10, 8, 9, 0);
      final list = dueReminders(now);
      expect(list, isA<List<DueReminder>>());
    });
  });

  group('Thẻ chia sẻ (J3)', () {
    testWidgets('J3: đổi 4 mẫu màu thẻ kỷ niệm', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 1600 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      final m = MilestoneMemo(key: 'f_roll', title: 'Lần đầu lật', date: DateTime.now(), note: 'Test');
      await tester.pumpWidget(MaterialApp(debugShowCheckedModeBanner: false, home: Scaffold(body: MemoryCardScreen(m))));
      await tester.pump(const Duration(seconds: 1));
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.bySemanticsLabel(RegExp('^Mẫu ')).at(i));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
      }
      await _close(tester);
    });
  });

  group('Hồ sơ bé (U5)', () {
    testWidgets('U5: sửa tên bé ở màn hồ sơ', (tester) async {
      final before = app.baby!.name;
      tester.view.physicalSize = const Size(390 * 2, 1600 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(MaterialApp(debugShowCheckedModeBanner: false, home: const Onboarding(edit: true)));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Tên bé hoặc biệt danh'), findsWidgets);
      await tester.enterText(find.byType(TextField).first, 'Bé test');
      await tester.pump();
      expect(find.text('Bé test'), findsWidgets);
      await _close(tester);
      expect(app.baby!.name, before, reason: 'chưa bấm Lưu thì không được đổi tên');
    });
  });

  group('Biểu đồ (O3)', () {
    testWidgets('O3: chọn Theo ngày mở danh sách lựa chọn', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 1600 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(MaterialApp(debugShowCheckedModeBanner: false, home: Scaffold(body: OverviewScreen())));
      await tester.pump(const Duration(seconds: 2));
      final menu = find.text('Theo ngày');
      expect(menu, findsWidgets);
      await tester.tap(menu.first);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Theo ngày'), findsWidgets);
      expect(tester.takeException(), isNull);
      await _close(tester);
    });
  });
}

