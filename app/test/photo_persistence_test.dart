import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gin_baby/data/app_state.dart';
import 'package:gin_baby/data/demo.dart';
import 'package:gin_baby/data/models.dart';
import 'package:gin_baby/ui/widgets.dart';

/// Ảnh 1x1 PNG hợp lệ (để Image.memory giải mã được thật).
final Uint8List _png = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8AARAAGAAFJZcaaAAAAAElFTkSuQmCC');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await seedDemo(app);
  });

  testWidgets('ảnh lưu cùng bản ghi tã được hiển thị lại trong dòng nhật ký và chi tiết', (tester) async {
    final id = await app.putPhoto(_png);
    final e = Entry(type: T.diaper, time: DateTime.now(), data: {'kind': 'wet', 'amount': 'vừa', 'photo': id});
    app.addEntry(e);
    await tester.pump(const Duration(seconds: 3)); // để bộ hẹn giờ lưu của app hết (như các bài test khác)

    // Ảnh đọc lại được từ bộ nhớ đệm đúng với bản ghi
    expect(entryPhoto(e), isNotNull, reason: 'bản ghi có ảnh phải đọc lại được ảnh');

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ListView(children: [EntryRow(e)])),
    ));
    await tester.pump();
    // Dòng nhật ký hiện thumbnail (Image), không chỉ biểu tượng
    expect(find.byType(Image), findsWidgets);
    expect(find.byIcon(Icons.photo_camera_rounded), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    app.removeEntry(e.id);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('bản ghi không có ảnh không hiện ô ảnh trống', (tester) async {
    final e = Entry(type: T.diaper, time: DateTime.now(), data: {'kind': 'wet', 'amount': 'ít'});
    expect(entryPhoto(e), isNull);
  });
}
