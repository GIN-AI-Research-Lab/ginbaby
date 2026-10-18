import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gin_baby/data/app_state.dart';
import 'package:gin_baby/data/demo.dart';
import 'package:gin_baby/data/models.dart';
import 'package:gin_baby/ui/history.dart';
import 'package:gin_baby/ui/overview.dart';
import 'package:gin_baby/ui/settings.dart';
import 'package:gin_baby/ui/utilities_screen.dart';

/// Tuần 3: Lịch sử, Thống kê, Tiện ích, Cài đặt (xem docs/TEST_PLAN.md).
Widget _withRoute(Widget screen) => MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(child: ElevatedButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => Scaffold(body: screen))), child: const Text('mở'))),
        ),
      ),
    );

Future<void> _open(WidgetTester tester, Widget screen, {double h = 1600}) async {
  tester.view.physicalSize = Size(390 * 2, h * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(_withRoute(screen));
  await tester.tap(find.text('mở'));
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(seconds: 1));
}

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

  group('Lịch sử (L)', () {
    testWidgets('L2: tìm kiếm theo từ khoá lọc danh sách', (tester) async {
      await _open(tester, const HistoryScreen());
      final search = find.byType(TextField).first;
      await tester.enterText(search, 'zzzkhongco');
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Tã ướt'), findsNothing, reason: 'từ khoá không khớp thì không hiện bản ghi nào');
      await tester.enterText(search, 'tã');
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.textContaining('Tã'), findsWidgets);
      await _close(tester);
    });

    testWidgets('L4: sửa và xoá bản ghi từ chi tiết', (tester) async {
      final e = Entry(type: T.feed, time: DateTime.now(), data: {'method': 'bottle', 'ml': 90, 'milk': 'mom'});
      app.addEntry(e);
      await tester.pump(const Duration(seconds: 2));
      e.data['ml'] = 110;
      app.updateEntry(e);
      expect(app.entries.firstWhere((x) => x.id == e.id).ml, 110);
      app.removeEntry(e.id);
      await tester.pump(const Duration(seconds: 2));
      expect(app.entries.any((x) => x.id == e.id), isFalse);
    });
  });

  group('Thống kê (O)', () {
    testWidgets('O1: chuyển Ngày / Tuần / Tháng không lỗi', (tester) async {
      await _open(tester, const OverviewScreen());
      for (final label in const ['Ngày', 'Tháng', 'Tuần']) {
        await tester.tap(find.text(label).first);
        await tester.pump(const Duration(milliseconds: 600));
        expect(tester.takeException(), isNull, reason: 'đổi sang $label không được lỗi');
      }
      await _close(tester);
    });

    testWidgets('O2: mũi tên lùi tuần đổi khoảng ngày', (tester) async {
      await _open(tester, const OverviewScreen());
      final before = find.textContaining('/26').evaluate().map((e) => (e.widget as Text).data).join();
      await tester.tap(find.byIcon(Icons.chevron_left_rounded).first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 600));
      final after = find.textContaining('/26').evaluate().map((e) => (e.widget as Text).data).join();
      expect(after, isNot(before), reason: 'lùi một tuần phải đổi khoảng ngày');
      await _close(tester);
    });
  });

  group('Tiện ích (U)', () {
    testWidgets('U1: tìm chức năng theo tên, không dấu cũng tìm được', (tester) async {
      await _open(tester, const UtilitiesTab(goTab: _noop));
      await tester.enterText(find.byType(TextField).first, 'tiem chung');
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Tiêm chủng'), findsWidgets);
      await tester.enterText(find.byType(TextField).first, 'khongco');
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Tiêm chủng'), findsNothing);
      await _close(tester);
    });

    testWidgets('U4: về mặc định khôi phục thanh dưới và ghim nhanh', (tester) async {
      app.settings.footer = const ['money', 'stats', 'history'];
      app.settings.favs = const ['sleep'];
      await _open(tester, const MenuCustomizeScreen());
      await tester.tap(find.bySemanticsLabel('Về mặc định'));
      await tester.pump(const Duration(seconds: 1));
      expect(app.settings.footer, const ['history', 'stats', 'money']);
      expect(app.settings.favs, const ['pump', 'feed', 'sleep', 'diaper']);
      await _close(tester);
    });
  });

  group('Cài đặt (C)', () {
    testWidgets('C1: đổi Theo máy / Sáng / Tối lưu lại trong cài đặt', (tester) async {
      await _open(tester, const SettingsScreen());
      await tester.tap(find.text('Tối'));
      await tester.pump(const Duration(seconds: 1));
      expect(app.settings.themeMode, 2);
      await tester.tap(find.text('Sáng'));
      await tester.pump(const Duration(seconds: 1));
      expect(app.settings.themeMode, 1);
      app.settings.themeMode = 0;
      await _close(tester);
    });

    testWidgets('C2: hiệu ứng kính mờ có đủ ba mức', (tester) async {
      await _open(tester, const SettingsScreen());
      await tester.tap(find.text('Đầy đủ').first);
      await tester.pump(const Duration(seconds: 1));
      expect(app.settings.glassMode, 2);
      await tester.tap(find.text('Tắt').first);
      await tester.pump(const Duration(seconds: 1));
      expect(app.settings.glassMode, 0);
      app.settings.glassMode = 0;
      await _close(tester);
    });

    testWidgets('C5: xoá toàn bộ dữ liệu có hộp xác nhận', (tester) async {
      await _open(tester, const SettingsScreen());
      await tester.dragUntilVisible(find.text('Xoá toàn bộ dữ liệu'), find.byType(Scrollable).first, const Offset(0, -300));
      await tester.ensureVisible(find.text('Xoá toàn bộ dữ liệu'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Xoá toàn bộ dữ liệu'), warnIfMissed: false);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Xoá toàn bộ dữ liệu?'), findsOneWidget, reason: 'phải hỏi xác nhận trước khi xoá');
      await tester.tap(find.text('Huỷ').last);
      await tester.pump(const Duration(seconds: 1));
      expect(app.entries, isNotEmpty, reason: 'bấm Huỷ không được xoá gì');
      await _close(tester);
    });
  });
}

void _noop(int _) {}
