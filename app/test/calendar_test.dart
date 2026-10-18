import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gin_baby/data/app_state.dart';
import 'package:gin_baby/data/demo.dart';
import 'package:gin_baby/data/models.dart';
import 'package:gin_baby/ui/calendar_screen.dart';
import 'package:gin_baby/ui/history.dart';

/// Lịch cả tháng: chấm màu việc đã ghi, việc cần làm (kế hoạch), lịch tiêm, thêm/sửa/xoá/đánh dấu xong.
Future<void> _open(WidgetTester tester, {DateTime? initial}) async {
  tester.view.physicalSize = const Size(390 * 2, 2400 * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(MaterialApp(debugShowCheckedModeBanner: false, home: CalendarScreen(initial: initial)));
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

  setUp(() {
    app.appts.clear();
  });

  testWidgets('Lịch Lịch sử: biểu tượng lịch mở lịch tháng', (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 1600 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(MaterialApp(debugShowCheckedModeBanner: false, home: Scaffold(body: HistoryScreen())));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byIcon(Icons.calendar_month_rounded).first);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(CalendarScreen), findsOneWidget);
    expect(find.text('Thêm việc'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('hiện tháng hiện tại, đổi tháng bằng mũi tên và về hôm nay', (tester) async {
    await _open(tester);
    final now = DateTime.now();
    expect(find.text('Tháng ${now.month}/${now.year}'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Tháng trước'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 300));
    final prev = DateTime(now.year, now.month - 1);
    expect(find.text('Tháng ${prev.month}/${prev.year}'), findsOneWidget);
    expect(find.text('Về hôm nay'), findsOneWidget);
    await tester.tap(find.text('Về hôm nay'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Tháng ${now.month}/${now.year}'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('chọn một ngày có nhật ký thì hiện các bản ghi và tóm tắt trong ngày đó', (tester) async {
    final day = DateTime.now().subtract(const Duration(days: 1)); // demo có dữ liệu 14 ngày
    await _open(tester, initial: day);
    expect(find.text('Đã ghi'), findsOneWidget);
    expect(find.textContaining('cữ bú'), findsWidgets, reason: 'dòng tóm tắt trong ngày');
    expect(find.text('Chưa ghi gì trong ngày này.'), findsNothing);
    await _close(tester);
  });

  testWidgets('thêm việc cần làm vào ngày đã chọn: hiện trong danh sách và có dấu trên lịch', (tester) async {
    final day = DateTime.now().add(const Duration(days: 3));
    await _open(tester, initial: day);
    expect(app.appts, isEmpty);
    await tester.tap(find.text('Thêm việc'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(seconds: 1));
    await tester.enterText(find.byType(TextField).first, 'Đi khám nhi');
    await tester.pump();
    await tester.tap(find.text('Lưu').last);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(seconds: 1));
    expect(app.appts, hasLength(1));
    expect(app.appts.single.title, 'Đi khám nhi');
    expect(app.appts.single.time.day, day.day, reason: 'việc mới nằm đúng ngày đang chọn');
    expect(find.text('Đi khám nhi'), findsOneWidget);
    // ô ngày có đánh dấu "có việc cần làm"
    expect(find.bySemanticsLabel(RegExp('Ngày ${day.day}.*có việc cần làm')), findsOneWidget);
    await _close(tester);
  });

  testWidgets('đánh dấu xong rồi bỏ đánh dấu; xoá việc', (tester) async {
    final day = DateTime.now().add(const Duration(days: 2));
    final a = Appointment(time: DateTime(day.year, day.month, day.day, 10), title: 'Mua tã');
    app.addAppt(a);
    await _open(tester, initial: day);
    expect(find.text('Mua tã'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Đánh dấu đã xong'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 300));
    expect(a.done, isTrue);
    await tester.tap(find.bySemanticsLabel('Bỏ đánh dấu xong'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 300));
    expect(a.done, isFalse);

    await tester.tap(find.text('Mua tã'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Xoá').last);
    await tester.pump(const Duration(milliseconds: 600));
    expect(app.appts, isEmpty);
    await _close(tester);
  });

  testWidgets('sửa tên việc đã có', (tester) async {
    final day = DateTime.now().add(const Duration(days: 2));
    final a = Appointment(time: DateTime(day.year, day.month, day.day, 10), title: 'Mua tã');
    app.addAppt(a);
    await _open(tester, initial: day);
    await tester.tap(find.text('Mua tã'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(seconds: 1));
    await tester.enterText(find.byType(TextField).first, 'Mua tã và sữa');
    await tester.pump();
    await tester.tap(find.text('Lưu').last);
    await tester.pump(const Duration(milliseconds: 600));
    expect(a.title, 'Mua tã và sữa');
    await _close(tester);
  });

  testWidgets('"Mở nhật ký ngày này" trả về ngày đã chọn cho Lịch sử', (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 2400 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    DateTime? got;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async => got = await Navigator.of(context).push<DateTime?>(MaterialPageRoute(builder: (_) => CalendarScreen(initial: DateTime.now().subtract(const Duration(days: 2))))),
              child: const Text('mở'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('mở'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Mở nhật ký ngày này'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(seconds: 1));
    final expected = DateTime.now().subtract(const Duration(days: 2));
    expect(got, isNotNull);
    expect([got!.year, got!.month, got!.day], [expected.year, expected.month, expected.day]);
    await _close(tester);
  });
}
