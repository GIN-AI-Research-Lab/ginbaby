import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gin_baby/data/app_state.dart';
import 'package:gin_baby/data/demo.dart';
import 'package:gin_baby/ui/onboarding.dart';

/// U5: sửa hồ sơ bé. Có lưu thì tên đổi và còn sau khi mở lại; thoát không lưu thì giữ nguyên.
Widget _withRoute(Widget screen) => MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(child: ElevatedButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen)), child: const Text('mở'))),
        ),
      ),
    );

Future<void> _open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390 * 2, 1600 * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(_withRoute(const Onboarding(edit: true)));
  await tester.tap(find.text('mở'));
  await tester.pump(const Duration(milliseconds: 800));
  await tester.pump(const Duration(seconds: 1));
}

/// Bấm "Tiếp tục" cho tới bước cuối, rồi trả về true nếu có nút "Lưu hồ sơ".
Future<bool> _toLastStep(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    if (find.text('Lưu hồ sơ').evaluate().isNotEmpty) return true;
    await tester.tap(find.text('Tiếp tục').first);
    await tester.pump(const Duration(milliseconds: 500));
  }
  return find.text('Lưu hồ sơ').evaluate().isNotEmpty;
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

  testWidgets('U5a: sửa tên bé, bấm Lưu hồ sơ thì tên đổi và được lưu', (tester) async {
    final before = app.baby!.name;
    await _open(tester);
    final nameField = find.byType(TextField).first;
    await tester.enterText(nameField, 'Bé test U5');
    await tester.pump();
    expect(await _toLastStep(tester), isTrue, reason: 'phải tới bước cuối có nút Lưu hồ sơ');
    await tester.tap(find.text('Lưu hồ sơ'));
    await tester.pump(const Duration(seconds: 1));
    expect(app.baby!.name, 'Bé test U5');
    expect(find.text('Bé test U5'), findsNothing, reason: 'sau khi lưu phải đóng màn hồ sơ');
    app.saveBaby(app.baby!..name = before);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('U5b: sửa tên rồi thoát bằng Quay lại thì tên không đổi', (tester) async {
    final before = app.baby!.name;
    await _open(tester);
    await tester.enterText(find.byType(TextField).first, 'Tên không được lưu');
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Quay lại').first);
    await tester.pump(const Duration(seconds: 1));
    expect(app.baby!.name, before, reason: 'thoát mà không lưu thì tên giữ nguyên');
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('U5c: tên để trống thì lưu thành "Bé"', (tester) async {
    final before = app.baby!.name;
    await _open(tester);
    await tester.enterText(find.byType(TextField).first, '   ');
    await tester.pump();
    expect(await _toLastStep(tester), isTrue);
    await tester.tap(find.text('Lưu hồ sơ'));
    await tester.pump(const Duration(seconds: 1));
    expect(app.baby!.name, 'Bé');
    app.saveBaby(app.baby!..name = before);
    await tester.pump(const Duration(seconds: 2));
  });
}
