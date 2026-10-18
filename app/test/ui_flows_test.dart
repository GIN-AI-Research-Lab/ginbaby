import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gin_baby/data/app_state.dart';
import 'package:gin_baby/data/demo.dart';
import 'package:gin_baby/data/models.dart';
import 'package:gin_baby/ui/diaper_screen.dart';
import 'package:gin_baby/ui/sleep_screen.dart';

/// Màn được mở bằng Navigator để các nút "quay lại / đóng" hoạt động như khi dùng thật.
Widget _withRoute(Widget screen) => MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Builder(builder: (context) => Scaffold(
            body: Center(child: ElevatedButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen)), child: const Text('mở'))),
          )),
    );

Future<void> _open(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(_withRoute(screen));
  await tester.tap(find.text('mở'));
  await tester.pumpAndSettle(const Duration(milliseconds: 400));
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUpAll(() async {
    await seedDemo(app);
  });

  tearDown(() async {
    // dọn các giấc ngủ đang chạy do test tạo ra
    while (app.activeSleep != null) {
      app.removeEntry(app.activeSleep!.id);
    }
  });

  testWidgets('S4 (giao diện): huỷ giấc đang ngủ phải hỏi xác nhận rồi xoá', (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 1600 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    await _open(tester, const SleepScreen());

    await tester.tap(find.text('Ngủ ngay'));
    await tester.pump(const Duration(seconds: 2));
    expect(app.activeSleep, isNotNull);

    await tester.tap(find.bySemanticsLabel('Huỷ giấc ngủ'));
    await tester.pumpAndSettle();
    expect(find.text('Huỷ giấc ngủ này?'), findsOneWidget, reason: 'phải hỏi xác nhận trước khi xoá');

    // bấm Không/Huỷ ở hộp thoại thì giấc ngủ vẫn còn
    await tester.tap(find.text('Huỷ').last);
    await tester.pumpAndSettle();
    expect(app.activeSleep, isNotNull, reason: 'bấm Huỷ ở hộp thoại không được xoá');

    // xác nhận thì xoá
    await tester.tap(find.bySemanticsLabel('Huỷ giấc ngủ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Huỷ giấc ngủ').last);
    await tester.pumpAndSettle();
    expect(app.activeSleep, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('S2 (giao diện): Bé dậy rồi → Hoàn tác đưa bé về trạng thái đang ngủ', (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 1600 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    await _open(tester, const SleepScreen());

    await tester.tap(find.text('Ngủ ngay'));
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.text('Bé dậy rồi'));
    await tester.pump(const Duration(seconds: 1));
    expect(app.activeSleep, isNull);

    expect(find.byType(SnackBar), findsOneWidget, reason: 'sau khi dậy phải có thanh thông báo có nút Hoàn tác');
    // Bấm trực tiếp vào hàm của nút: thao tác chạm vào thanh thông báo không tới được trong môi trường test.
    final action = tester.widget<SnackBarAction>(find.byType(SnackBarAction));
    action.onPressed();
    await tester.pump(const Duration(seconds: 1));
    expect(app.activeSleep, isNotNull, reason: 'hoàn tác phải đưa giấc ngủ về đang chạy');
    expect(tester.takeException(), isNull);
  });

  testWidgets('D4 (giao diện): chỉ tã ướt, không có phân, lưu được và đóng màn', (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 1600 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    final before = app.ofType(T.diaper).length;
    await _open(tester, const DiaperScreen());

    await tester.tap(find.text('Chỉ có tã ướt, không có phân'));
    await tester.pump(const Duration(seconds: 2));
    expect(app.ofType(T.diaper).length, before + 1);
    final e = app.ofType(T.diaper).first;
    expect(e.str('kind'), 'wet');
    expect(e.data.containsKey('color'), isFalse);
    expect(find.text('mở'), findsOneWidget, reason: 'sau khi lưu phải quay về màn trước');
    app.removeEntry(e.id);
    await tester.pump(const Duration(seconds: 2));
  });
}
