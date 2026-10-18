import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gin_baby/core/kit.dart';

/// Thông báo có "Hoàn tác" của màn trước không được nằm đè lên màn mở sau đó
/// (lỗi thật: chạm nút Lưu lại trúng Hoàn tác và mở lại giấc ngủ đã kết thúc).
void main() {
  testWidgets('mở màn mới thì ẩn thông báo Hoàn tác của màn trước', (tester) async {
    var undone = 0;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Column(children: [
            ElevatedButton(onPressed: () => toast(context, 'Đã ghi', undo: () => undone++), child: const Text('ghi')),
            ElevatedButton(onPressed: () => openPage(context, const Scaffold(body: Text('màn mới'))), child: const Text('mở')),
          ]),
        ),
      ),
    ));
    await tester.tap(find.text('ghi'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Hoàn tác'), findsOneWidget);

    await tester.tap(find.text('mở'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('màn mới'), findsOneWidget);
    expect(find.text('Hoàn tác'), findsNothing, reason: 'thông báo cũ không được đè lên màn mới');
    expect(undone, 0);
  });

  testWidgets('thông báo vẫn hiện bình thường khi không chuyển màn', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) => Scaffold(body: ElevatedButton(onPressed: () => toast(context, 'Đã ghi', undo: () {}), child: const Text('ghi')))),
    ));
    await tester.tap(find.text('ghi'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Đã ghi'), findsOneWidget);
    expect(find.text('Hoàn tác'), findsOneWidget);
  });
}
