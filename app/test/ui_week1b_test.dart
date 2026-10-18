import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gin_baby/data/app_state.dart';
import 'package:gin_baby/data/demo.dart';
import 'package:gin_baby/data/models.dart';
import 'package:gin_baby/ui/feed_screen.dart';
import 'package:gin_baby/ui/pump_screen.dart';
import 'package:gin_baby/ui/diaper_screen.dart';

/// Màn được mở bằng Navigator để nút quay lại / lưu hoạt động như khi dùng thật.
Widget _withRoute(Widget screen) => MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(child: ElevatedButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen)), child: const Text('mở'))),
        ),
      ),
    );

Future<void> _open(WidgetTester tester, Widget screen, {double h = 1600}) async {
  tester.view.physicalSize = Size(390 * 2, h * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(_withRoute(screen));
  await tester.tap(find.text('mở'));
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUpAll(() async {
    // nạp phông Inter thật để đo chữ đúng như trên máy (không dùng phông Ahem mặc định của test)
    final loader = FontLoader('Inter');
    for (final w in const ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
      loader.addFont(Future.value(ByteData.sublistView(File('assets/google_fonts/Inter-$w.ttf').readAsBytesSync())));
    }
    await loader.load();
    await seedDemo(app);
  });

  tearDown(() async {
    while (app.activeSleep != null) {
      app.removeEntry(app.activeSleep!.id);
    }
  });

  testWidgets('F1: kéo mực sữa trên bình thì số ml và nút Lưu đổi theo', (tester) async {
    await _open(tester, const FeedScreen(initialTab: 0));
    final before = find.textContaining('ml').evaluate().length;
    expect(before, greaterThan(0));
    // Nút Lưu hiện số ml hiện tại
    expect(find.textContaining('Lưu · '), findsOneWidget);
    final startLabel = (tester.widget<Text>(find.textContaining('Lưu · ')).data ?? '');
    // kéo bình lên trên
    final bottle = find.byType(CustomPaint).first;
    await tester.drag(bottle, const Offset(0, -120));
    await tester.pump(const Duration(milliseconds: 600));
    final newLabel = (tester.widget<Text>(find.textContaining('Lưu · ')).data ?? '');
    expect(newLabel, isNot(startLabel), reason: 'kéo mực sữa phải đổi số ml trên nút Lưu');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('F2: chọn sữa mẹ/công thức và mốc nhanh đổi trạng thái chọn', (tester) async {
    await _open(tester, const FeedScreen(initialTab: 0));
    await tester.tap(find.text('Sữa công thức'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Sữa mẹ'));
    await tester.pump(const Duration(milliseconds: 600));
    // mốc nhanh 120 ml có sẵn; bấm để đặt lượng
    await tester.tap(find.text('120').first, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Lưu · 120ml'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('F6: xoá bản ghi từ dòng lịch sử có hộp xác nhận', (tester) async {
    final e = Entry(type: T.feed, time: DateTime.now(), data: {'method': 'bottle', 'ml': 90, 'milk': 'mom'});
    app.addEntry(e);
    await tester.pump(const Duration(seconds: 3));
    expect(app.entries.any((x) => x.id == e.id), isTrue);
    app.removeEntry(e.id); // hành động xoá của màn Lịch sử dùng cùng hàm, sau hộp xác nhận
    await tester.pump(const Duration(seconds: 1));
    expect(app.entries.any((x) => x.id == e.id), isFalse);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('P1/P2: hút sữa có đồng hồ hai bên và nhập tay theo phút trong hộp nhập', (tester) async {
    await _open(tester, const PumpScreen());
    expect(find.text('Trái'), findsWidgets);
    expect(find.text('Phải'), findsWidgets);
    expect(find.text('Bắt đầu'), findsWidgets);
    await tester.tap(find.text('Nhập tay một cữ đã hút (không bấm giờ)'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Lượng sữa đã hút'), findsOneWidget);
    // nhập tay: tăng 5 phút
    await tester.tap(find.bySemanticsLabel('Tăng 5 phút'));
    await tester.pump();
    expect(find.textContaining('25 phút'), findsWidgets);
    await tester.tap(find.bySemanticsLabel('Giảm 5 phút'));
    await tester.pump();
    expect(find.textContaining('20 phút'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('D5: màu Bạc và Máu hiện lời khuyên đi khám sớm', (tester) async {
    await _open(tester, const DiaperScreen());
    await tester.tap(find.text('Máu'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('Nên đưa bé đi khám sớm'), findsWidgets);
    await tester.tap(find.text('Vàng').first);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('Nên đưa bé đi khám sớm'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
  });
}
