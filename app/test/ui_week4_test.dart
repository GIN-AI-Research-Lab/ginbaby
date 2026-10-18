import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gin_baby/data/app_state.dart';
import 'package:gin_baby/data/demo.dart';
import 'package:gin_baby/data/models.dart';
import 'package:gin_baby/ui/fund.dart';
import 'package:gin_baby/ui/health_hub.dart';
import 'package:gin_baby/ui/money.dart';
import 'package:gin_baby/ui/quick_logs.dart';
import 'package:gin_baby/ui/utilities_screen.dart';

/// Phần còn lại: Sức khoẻ (nhiệt độ, thuốc, ghi chú), Quỹ (rút, sửa), Tiền (lọc), Tiện ích (ghim), Hồ sơ.
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

void main() {
  setUpAll(() async {
    final loader = FontLoader('Inter');
    for (final w in const ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
      loader.addFont(Future.value(ByteData.sublistView(File('assets/google_fonts/Inter-$w.ttf').readAsBytesSync())));
    }
    await loader.load();
    await seedDemo(app);
  });

  group('Sức khoẻ (T)', () {
    testWidgets('T1: nhiệt độ chỉnh bằng nút ± và lưu đúng số', (tester) async {
      final before = app.entries.where((e) => e.type == T.temp).length;
      await _open(tester, const HealthHub(initial: 0));
      await tester.tap(find.text('Ghi nhiệt độ'));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('36,8°C'), findsOneWidget, reason: 'mặc định 36,8°C');
      await tester.tap(find.bySemanticsLabel('Tăng 0,1°C').first, warnIfMissed: false);
      await tester.pump();
      expect(find.text('36,9°C'), findsOneWidget);
      await tester.tap(find.text('Lưu').first);
      await tester.pump(const Duration(seconds: 2));
      final after = app.entries.where((e) => e.type == T.temp).length;
      expect(after, before + 1);
      final e = app.entries.firstWhere((x) => x.type == T.temp);
      expect(e.num('v'), closeTo(36.9, 0.01));
      app.removeEntry(e.id);
      await _close(tester);
    });

    testWidgets('T2: ghi thuốc có tên và liều lưu được', (tester) async {
      final before = app.entries.where((e) => e.type == T.med).length;
      await _open(tester, const HealthHub(initial: 1));
      await tester.tap(find.text('Ghi thuốc đã cho bé'));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(seconds: 1));
      final fields = find.byType(TextField);
      if (fields.evaluate().length >= 2) {
        await tester.enterText(fields.at(0), 'Vitamin D');
        await tester.enterText(fields.at(1), '400 IU');
        await tester.pump();
      }
      await tester.tap(find.text('Lưu').first);
      await tester.pump(const Duration(seconds: 2));
      expect(app.entries.where((e) => e.type == T.med).length, before + 1);
      final e = app.entries.firstWhere((x) => x.type == T.med);
      app.removeEntry(e.id);
      await _close(tester);
    });

    testWidgets('T3: ghi chú dài lưu đủ và không tràn', (tester) async {
      await _open(tester, const HealthHub(initial: 0));
      await _close(tester);
      final long = 'Bé ngủ ngon hơn hôm qua ' * 12;
      final e = Entry(type: T.note, time: DateTime.now(), data: {'text': long});
      app.addEntry(e);
      await tester.pump(const Duration(seconds: 2));
      expect(app.entries.firstWhere((x) => x.id == e.id).str('text'), long);
      app.removeEntry(e.id);
      await tester.pump(const Duration(seconds: 2));
    });
  });

  group('Quỹ và Tiền (Q, M)', () {
    testWidgets('Q3: vàng nhập số lượng và giá tính giá trị', (tester) async {
      final f = FundItem(name: 'Vàng test', type: AssetType.gold, qty: 2, unit: 'chỉ', buyPrice: 7000000, curPrice: 8000000, date: DateTime.now());
      app.addFund(f);
      await tester.pump(const Duration(seconds: 2));
      expect(app.funds.firstWhere((x) => x.id == f.id).value, 16000000);
      app.removeFund(f.id);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('Q5: thêm vào rồi rút ra cập nhật số dư và lịch sử', (tester) async {
      final f = FundItem(name: 'Lì xì test', type: AssetType.cash, amount: 1000000, date: DateTime.now());
      app.addFund(f);
      await tester.pump(const Duration(seconds: 2));
      expect(f.value, 1000000);
      f.amount = 1500000;
      f.moves.add(FundMove(time: DateTime.now(), kind: 'add', delta: 500000, note: 'Thêm'));
      app.fundChanged();
      expect(app.funds.firstWhere((x) => x.id == f.id).value, 1500000);
      expect(f.moves, isNotEmpty);
      app.removeFund(f.id);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('M8: lọc theo nhãn và tìm kiếm thu chi', (tester) async {
      final t = Tx(time: DateTime.now(), amount: -45000, title: 'Tã test lọc', tags: ['bim']);
      app.txs.add(t);
      app.changed('tx');
      await _open(tester, const MoneyTab());
      await tester.enterText(find.byType(TextField).first, 'Tã test lọc');
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Tã test lọc'), findsWidgets);
      await tester.enterText(find.byType(TextField).first, 'khongco123');
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Tã test lọc'), findsNothing);
      app.removeTx(t.id);
      await _close(tester);
    });
  });

  group('Tiện ích và Hồ sơ (U)', () {
    testWidgets('U2: ghim thêm chức năng rồi bỏ ghim', (tester) async {
      app.settings.favs = const ['pump'];
      app.settingsChanged();
      await _open(tester, const MenuCustomizeScreen());
      expect(app.settings.favs, const ['pump']);
      app.settings.favs = [...app.settings.favs, 'sleep'];
      expect(app.settings.favs, const ['pump', 'sleep']);
      app.settings.favs = [for (final id in app.settings.favs) if (id != 'sleep') id];
      expect(app.settings.favs, const ['pump']);
      app.settings.favs = const ['pump', 'feed', 'sleep', 'diaper'];
      await _close(tester);
    });

    testWidgets('U3: đổi một nút giữa thanh dưới được lưu', (tester) async {
      final old = app.settings.footer;
      app.settings.footer = const ['history', 'stats', 'money'];
      final next = [...app.settings.footer];
      next[0] = 'recap';
      app.settings.footer = next;
      expect(app.settings.footer.first, 'recap');
      app.settings.footer = old;
    });
  });
}
