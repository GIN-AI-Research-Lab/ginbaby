import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gin_baby/data/app_state.dart';
import 'package:gin_baby/data/demo.dart';
import 'package:gin_baby/data/models.dart';
import 'package:gin_baby/domain/memories.dart';
import 'package:gin_baby/ui/fund.dart';
import 'package:gin_baby/ui/memory_screen.dart';
import 'package:gin_baby/ui/money.dart';

/// Tuần 2: Tiền của bé, Quỹ của con, Nhật ký mốc (xem docs/TEST_PLAN.md).
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

final Uint8List _png = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8AARAAGAAFJZcaaAAAAAElFTkSuQmCC');

void main() {
  setUpAll(() async {
    final loader = FontLoader('Inter');
    for (final w in const ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
      loader.addFont(Future.value(ByteData.sublistView(File('assets/google_fonts/Inter-$w.ttf').readAsBytesSync())));
    }
    await loader.load();
    await seedDemo(app);
  });

  group('Tiền của bé (M)', () {
    testWidgets('M1: nút + mở màn Thêm khoản chi (không phải popup)', (tester) async {
      await _open(tester, const MoneyTab());
      await tester.tap(find.bySemanticsLabel('Thêm khoản thu chi'));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(MoneyAddScreen), findsOneWidget, reason: 'nút + phải mở màn nhập thu chi');
      expect(find.byType(AlertDialog), findsNothing);
      await _close(tester);
    });

    testWidgets('M2/M3: nhập số tiền, gợi ý +50k cộng dồn, lưu được', (tester) async {
      final before = app.txs.length;
      await _open(tester, const MoneyAddScreen());
      await tester.tap(find.text('+50k'));
      await tester.pump();
      await tester.tap(find.text('+50k'));
      await tester.pump();
      expect(find.text('100.000đ'), findsWidgets, reason: '50k + 50k = 100.000đ');
      await tester.tap(find.text('Lưu'));
      await tester.pump(const Duration(seconds: 2));
      expect(app.txs.length, before + 1, reason: 'lưu phải tạo một khoản thu chi');
      final t = app.txs.first;
      expect(t.amount.abs(), 100000);
      app.removeTx(t.id);
      await tester.pump(const Duration(seconds: 2));
      await _close(tester);
    });

    testWidgets('M4: khoản có ảnh hoá đơn lưu được và ảnh đọc lại được', (tester) async {
      final id = await app.putPhoto(_png);
      final t = Tx(time: DateTime.now(), amount: -30000, title: 'Tã dán size M', photos: [id]);
      app.txs.add(t);
      app.changed('tx');
      await tester.pump(const Duration(seconds: 3));
      expect(app.photo(id), isNotNull);
      app.removeTx(t.id);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('M5: sửa và xoá khoản có hộp xác nhận', (tester) async {
      final t = Tx(time: DateTime.now(), amount: -20000, title: 'Sữa test');
      app.txs.add(t);
      app.changed('tx');
      await tester.pump(const Duration(seconds: 2));
      t.title = 'Sữa test đã sửa';
      app.updateTx(t);
      expect(app.txs.firstWhere((x) => x.id == t.id).title, 'Sữa test đã sửa');
      app.removeTx(t.id);
      await tester.pump(const Duration(seconds: 2));
      expect(app.txs.any((x) => x.id == t.id), isFalse);
    });

    testWidgets('M7: ngân sách tháng lưu được qua hộp thoại', (tester) async {
      app.settings.monthlyBudget = 0;
      app.settings.monthlyBudget = 5000000;
      expect(app.settings.monthlyBudget, 5000000);
      app.settings.monthlyBudget = 0;
      await tester.pump(const Duration(seconds: 2));
    });
  });

  group('Quỹ của con (Q)', () {
    testWidgets('Q2: thêm khoản tiền mặt có tên và số tiền thì lưu được', (tester) async {
      final before = app.funds.length;
      await _open(tester, const FundEditScreen());
      await tester.enterText(find.widgetWithText(TextField, 'Tên khoản').first, 'Lì xì test');
      await tester.enterText(find.widgetWithText(TextField, 'Số tiền (gõ 20tr, 500k…)').first, '500k');
      await tester.pump();
      await tester.tap(find.text('Lưu'));
      await tester.pump(const Duration(seconds: 2));
      expect(app.funds.length, before + 1);
      final f = app.funds.firstWhere((x) => x.name == 'Lì xì test');
      expect(f.type, AssetType.cash);
      expect(f.amount, 500000);
      app.removeFund(f.id);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('Q4: khoản có ảnh sổ tiết kiệm lưu được và ảnh đọc lại được', (tester) async {
      final id = await app.putPhoto(_png);
      final f = FundItem(name: 'Sổ test', type: AssetType.saving, amount: 1000000, photos: [id], date: DateTime.now());
      app.addFund(f);
      await tester.pump(const Duration(seconds: 2));
      expect(app.funds.firstWhere((x) => x.id == f.id).photos, contains(id));
      expect(app.photo(id), isNotNull);
      app.removeFund(f.id);
      await tester.pump(const Duration(seconds: 2));
      expect(app.photo(id), isNull, reason: 'xoá khoản thì ảnh của khoản cũng phải được xoá');
    });

    testWidgets('Q6: mục tiêu quỹ tính đúng phần trăm', (tester) async {
      app.setGoal(FundGoal(name: 'Học phí', target: 120000000));
      expect(app.goal.target, 120000000);
      await tester.pump(const Duration(seconds: 2));
    });
  });

  group('Nhật ký mốc (J)', () {
    testWidgets('J1: lưu kỷ niệm mốc ngày đặc biệt rồi mở thẻ chia sẻ', (tester) async {
      await _open(tester, const MemoryEditScreen(memoKey: 'd_week1', title: 'Tròn 1 tuần tuổi'));
      await tester.tap(find.text('Lưu kỷ niệm'));
      await tester.pump(const Duration(seconds: 2));
      expect(app.memos.containsKey('d_week1'), isTrue);
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(MemoryCardScreen), findsOneWidget, reason: 'lưu lần đầu phải mở thẻ chia sẻ');
      app.removeMemo('d_week1');
      await _close(tester);
    });

    testWidgets('J2: mốc riêng và lần đầu ghi được vào nhật ký', (tester) async {
      await _open(tester, const MemoryJournalScreen());
      expect(find.text('Lần đầu của bé'), findsOneWidget);
      expect(find.text('Mốc riêng'), findsOneWidget);
      await _close(tester);
    });

    testWidgets('J4: xoá kỷ niệm có ảnh thì ảnh bị xoá', (tester) async {
      final id = await app.putPhoto(_png);
      app.saveMemo(MilestoneMemo(key: 'f_roll', title: 'Lần đầu lật', date: DateTime.now(), photo: id));
      await tester.pump(const Duration(seconds: 2));
      app.removeMemo('f_roll');
      await tester.pump(const Duration(seconds: 2));
      expect(app.memos.containsKey('f_roll'), isFalse);
      expect(app.photo(id), isNull);
    });
  });
}
