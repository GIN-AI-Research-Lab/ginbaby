import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gin_baby/data/app_state.dart';
import 'package:gin_baby/data/demo.dart';
import 'package:gin_baby/data/models.dart';
import 'package:gin_baby/ui/pump_screen.dart';

/// Hút sữa: màn chính gọn; Kết thúc thì hiện ngay hộp nhập số ml; nhập tay một cữ; không tràn bố cục.
Future<void> _open(WidgetTester tester, {double w = 390, double h = 1800}) async {
  tester.view.physicalSize = Size(w * 2, h * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Builder(
      builder: (context) => Scaffold(body: Center(child: ElevatedButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PumpScreen())), child: const Text('mở')))),
    ),
  ));
  await tester.tap(find.text('mở'));
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(seconds: 1));
}

Future<void> _wait(WidgetTester tester, [int ms = 900]) async {
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(Duration(milliseconds: ms));
  await tester.pump(const Duration(seconds: 1)); // hộp trượt lên cần thêm khung hình sau khi được mở
}

Future<void> _close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 3));
}

int _total(WidgetTester tester) {
  final all = find.byType(Text).evaluate().map((e) => (e.widget as Text).data ?? '').join('|');
  final m = RegExp(r'Tổng cộng (\d+) ml').firstMatch(all);
  return int.parse(m!.group(1)!);
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
    app.entries.removeWhere((e) => e.type == T.pump);
    app.fridge.clear();
  });

  testWidgets('màn chính gọn: đồng hồ, tóm tắt hôm nay, nhập tay, cữ gần đây (không còn ô nhập ml ngay trên màn)', (tester) async {
    await _open(tester);
    expect(find.text('Bắt đầu hút'), findsOneWidget);
    expect(find.text('Hôm nay'), findsOneWidget);
    expect(find.text('Nhập tay một cữ đã hút (không bấm giờ)'), findsOneWidget);
    expect(find.text('Các cữ hút gần đây'), findsOneWidget);
    expect(find.textContaining('Tăng Trái 5ml'), findsNothing, reason: 'ô nhập ml chuyển vào hộp nhập');
    expect(find.text('Lượng sữa sau cữ hút'), findsNothing);
    await _close(tester);
  });

  testWidgets('Bắt đầu rồi Kết thúc: hiện ngay hộp nhập lượng sữa; lưu thì ghi cữ và đóng màn', (tester) async {
    await _open(tester);
    await tester.tap(find.text('Bắt đầu hút'));
    await _wait(tester, 300);
    expect(find.text('Kết thúc và nhập lượng sữa'), findsOneWidget);
    await tester.tap(find.text('Kết thúc và nhập lượng sữa'));
    await _wait(tester);
    expect(find.text('Lượng sữa đã hút'), findsOneWidget, reason: 'Kết thúc xong hộp nhập số ml hiện luôn');

    // nhập lượng bằng chọn nhanh "30+30" rồi chỉnh thêm 5ml bên trái
    await tester.tap(find.text('30+30'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(_total(tester), 60);
    await tester.tap(find.bySemanticsLabel('Tăng Trái 5ml'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(_total(tester), 65);
    await tester.tap(find.text('Lưu · 65ml'));
    await _wait(tester, 1500);

    final e = app.entries.firstWhere((x) => x.type == T.pump);
    expect(e.num('l').round(), 35);
    expect(e.num('r').round(), 30);
    expect(e.ml, 65);
    await _close(tester);
  });

  testWidgets('đóng hộp nhập rồi mở lại bằng nút "Nhập lượng sữa" (không mất cữ vừa bấm giờ)', (tester) async {
    await _open(tester);
    await tester.tap(find.text('Bắt đầu hút'));
    await _wait(tester, 300);
    await tester.tap(find.text('Kết thúc và nhập lượng sữa'));
    await _wait(tester);
    await tester.tap(find.bySemanticsLabel('Đóng').last); // nút X của hộp
    await _wait(tester);
    expect(find.text('Lượng sữa đã hút'), findsNothing);
    expect(find.text('Nhập lượng sữa'), findsOneWidget);
    expect(app.entries.where((x) => x.type == T.pump), isEmpty, reason: 'chưa lưu gì khi chỉ đóng hộp');
    await tester.tap(find.text('Nhập lượng sữa'));
    await _wait(tester);
    expect(find.text('Lượng sữa đã hút'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('nhập tay một cữ đã hút: chọn giờ, số phút, lượng rồi lưu', (tester) async {
    await _open(tester);
    await tester.tap(find.text('Nhập tay một cữ đã hút (không bấm giờ)'));
    await _wait(tester);
    await tester.tap(find.bySemanticsLabel('Tăng 5 phút'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('25 phút'), findsOneWidget);
    await tester.tap(find.text('40+40'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Lưu · 80ml'));
    await _wait(tester, 1500);
    final e = app.entries.firstWhere((x) => x.type == T.pump);
    expect(e.ml, 80);
    expect(e.num('min').round(), 25);
    await _close(tester);
  });

  testWidgets('không nhập lượng vẫn lưu được cữ hút (chỉ có số phút)', (tester) async {
    await _open(tester);
    await tester.tap(find.text('Nhập tay một cữ đã hút (không bấm giờ)'));
    await _wait(tester);
    for (var i = 0; i < 40; i++) {
      await tester.tap(find.bySemanticsLabel('Giảm Trái 5ml'), warnIfMissed: false);
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Giảm Phải 5ml'), warnIfMissed: false);
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 200));
    expect(_total(tester), 0);
    expect(find.text('Lưu cữ hút'), findsOneWidget);
    await tester.tap(find.text('Lưu cữ hút'));
    await _wait(tester, 1500);
    final e = app.entries.firstWhere((x) => x.type == T.pump);
    expect(e.ml, 0);
    await _close(tester);
  });

  testWidgets('lưu vào ngăn mát tạo bình sữa trong tủ; chọn "Không" thì không tạo', (tester) async {
    await _open(tester);
    await tester.tap(find.text('Nhập tay một cữ đã hút (không bấm giờ)'));
    await _wait(tester);
    await tester.tap(find.text('50+50'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.bySemanticsLabel('Thêm một bình'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('Chia thành 2 bình'), findsOneWidget);
    await tester.tap(find.text('Lưu · 100ml'));
    await _wait(tester, 1500);
    expect(app.fridge, hasLength(2));
    expect(app.fridge.fold(0, (a, f) => a + f.ml), 100);
    await _close(tester);

    app.fridge.clear();
    await _open(tester);
    await tester.tap(find.text('Nhập tay một cữ đã hút (không bấm giờ)'));
    await _wait(tester);
    await tester.tap(find.text('Không'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.textContaining('Lưu ·'));
    await _wait(tester, 1500);
    expect(app.fridge, isEmpty);
    await _close(tester);
  });

  testWidgets('"Như lần trước" lấy đúng lượng Trái/Phải của cữ hút gần nhất', (tester) async {
    app.addPump(mlL: 70, mlR: 55, minutes: 18, time: DateTime.now().subtract(const Duration(hours: 3)));
    await _open(tester);
    await tester.tap(find.text('Nhập tay một cữ đã hút (không bấm giờ)'));
    await _wait(tester);
    await tester.tap(find.textContaining('Lần trước ('));
    await tester.pump(const Duration(milliseconds: 200));
    expect(_total(tester), 125);
    await _close(tester);
  });

  for (final w in [320.0, 360.0, 390.0, 430.0]) {
    testWidgets('hộp nhập không tràn bố cục ở bề rộng $w px (các chip xuống dòng, không bể khung)', (tester) async {
      app.addPump(mlL: 70, mlR: 55, minutes: 18, time: DateTime.now().subtract(const Duration(hours: 3)));
      await _open(tester, w: w, h: 1400);
      await tester.tap(find.text('Nhập tay một cữ đã hút (không bấm giờ)'));
      await _wait(tester);
      expect(tester.takeException(), isNull);
      for (final t in ['30+30', '60+60']) {
        final r = tester.getRect(find.text(t));
        expect(r.left, greaterThanOrEqualTo(0));
        expect(r.right, lessThanOrEqualTo(w), reason: 'chip $t tràn ra ngoài ở $w px');
      }
      await _close(tester);
    });
  }
}
