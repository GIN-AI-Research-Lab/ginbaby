import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gin_baby/core/capture.dart';
import 'package:gin_baby/data/app_state.dart';
import 'package:gin_baby/data/demo.dart';
import 'package:gin_baby/domain/stats.dart';
import 'package:gin_baby/ui/recap.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader('Inter');
    for (final w in const ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
      loader.addFont(Future.value(ByteData.sublistView(File('assets/google_fonts/Inter-$w.ttf').readAsBytesSync())));
    }
    await loader.load();
    await seedDemo(app);
  });

  testWidgets('O4: thẻ tổng kết chụp ra ảnh PNG thật (có chữ ký PNG)', (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 1600 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    final key = GlobalKey();
    final start = Stats.weekStart(DateTime.now());
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: RepaintBoundary(key: key, child: RecapScreen(weekStart: start))),
    ));
    await tester.pump(const Duration(seconds: 1));
    final bytes = await tester.runAsync(() => capturePng(key, pixelRatio: 2));
    expect(bytes, isNotNull, reason: 'thẻ tổng kết phải chụp được thành ảnh');
    expect(bytes!.sublist(1, 4), [0x50, 0x4E, 0x47], reason: 'tệp xuất ra phải là PNG');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
  });
}
