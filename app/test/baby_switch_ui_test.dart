import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gin_baby/core/kv.dart';
import 'package:gin_baby/data/app_state.dart';
import 'package:gin_baby/data/demo.dart';
import 'package:gin_baby/ui/home.dart';

/// Luồng nhiều bé trên giao diện: mở bảng chọn bé, thêm bé qua màn hồ sơ, chuyển qua lại, xoá bé.
void main() {
  setUpAll(() async {
    final loader = FontLoader('Inter');
    for (final w in const ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
      loader.addFont(Future.value(ByteData.sublistView(File('assets/google_fonts/Inter-$w.ttf').readAsBytesSync())));
    }
    await loader.load();
    await app.init(kv: await KV.memory()); // kho trong bộ nhớ để chuyển bé giữ được dữ liệu từng bé
    await seedDemo(app);
    await app.flushNow();
  });

  Future<void> pumpHome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 2, 2000 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(MaterialApp(debugShowCheckedModeBanner: false, home: Scaffold(body: HomeScreen(goTab: (_) {}))));
    await tester.pump(const Duration(seconds: 2));
  }

  Future<void> settle(WidgetTester tester, [int ms = 1200]) async {
    // lưu/nạp dữ liệu dùng bất đồng bộ thật: cho chạy ngoài đồng hồ giả của bộ test
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 250)));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(Duration(milliseconds: ms));
  }

  testWidgets('thêm bé thứ hai, chuyển qua lại, xoá bé', (tester) async {
    await pumpHome(tester);
    final firstName = app.baby!.name; // Suri (dữ liệu mẫu)
    final firstEntries = app.entries.length;
    expect(firstEntries, greaterThan(0));

    // mở bảng chọn bé
    await tester.tap(find.bySemanticsLabel(RegExp('Chuyển bé')));
    await settle(tester);
    expect(find.text('Chọn bé'), findsOneWidget);
    expect(find.text(firstName), findsWidgets);

    // thêm bé: màn hồ sơ ở chế độ thêm
    await tester.tap(find.text('Thêm bé').last);
    await settle(tester, 1500);
    expect(find.text('Thêm bé mới'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Bé Hai');
    await tester.pump();
    for (var i = 0; i < 4 && find.text('Tiếp tục').evaluate().isNotEmpty; i++) {
      await tester.tap(find.text('Tiếp tục').first);
      await settle(tester, 600);
    }
    await tester.tap(find.text('Thêm bé').last); // nút cuối cùng của luồng
    await settle(tester, 1500);

    expect(app.babies.map((b) => b.name), [firstName, 'Bé Hai']);
    expect(app.baby!.name, 'Bé Hai');
    expect(app.entries, isEmpty, reason: 'bé mới chưa có dữ liệu');

    // chuyển về bé đầu tiên bằng bảng chọn
    await pumpHome(tester);
    await tester.tap(find.bySemanticsLabel(RegExp('Chuyển bé')));
    await settle(tester);
    expect(find.text('Bé Hai'), findsWidgets);
    await tester.tap(find.bySemanticsLabel(RegExp('Bé $firstName')).first);
    await settle(tester, 1500);
    expect(app.baby!.name, firstName);
    expect(app.entries.length, firstEntries, reason: 'dữ liệu của bé đầu tiên còn nguyên');

    // xoá bé thứ hai
    await tester.runAsync(() => app.removeBaby(app.babies.last.id));
    expect(app.babies.map((b) => b.name), [firstName]);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
  });
}
