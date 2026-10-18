import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gin_baby/core/kit.dart';
import 'package:gin_baby/core/pastel.dart';
import 'package:gin_baby/data/app_state.dart';
import 'package:gin_baby/data/demo.dart';
import 'package:gin_baby/data/models.dart';
import 'package:gin_baby/domain/easy.dart';
import 'package:gin_baby/domain/feeding_ref.dart';
import 'package:gin_baby/ui/easy_screen.dart';
import 'package:gin_baby/ui/feed_screen.dart';
import 'package:gin_baby/ui/features.dart';
import 'package:gin_baby/ui/guide.dart';
import 'package:gin_baby/ui/home.dart';
import 'package:gin_baby/ui/money.dart';
import 'package:gin_baby/ui/pump_screen.dart';
import 'package:gin_baby/ui/quick_fab.dart';

/// Đợt góp ý: Trang chủ, nhịp EASY, quỹ nhiều mục tiêu, nhiều bé, nút ghi nhanh, bước 5 ml, bỏ "Hai bên", Tiện ích hết trùng.
Future<void> _pump(WidgetTester tester, Widget w, {double h = 3000}) async {
  tester.view.physicalSize = Size(390 * 2, h * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(MaterialApp(debugShowCheckedModeBanner: false, home: Scaffold(body: w)));
  await tester.pump(const Duration(seconds: 2));
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

  group('Trang chủ: sắp xếp và nội dung', () {
    testWidgets('thứ tự: Tổng quan → Hoạt động/Đang thức → Cữ bú gần nhất → Cữ hút gần nhất → Giấc ngủ hôm nay', (tester) async {
      await _pump(tester, HomeScreen(goTab: (_) {}));
      double y(String t) => tester.getTopLeft(find.text(t).first).dy;
      final order = [y('Tổng quan hôm nay'), y('Hoạt động hôm nay'), y('Cữ bú gần nhất'), y('Cữ hút gần nhất'), y('Giấc ngủ hôm nay')];
      for (var i = 1; i < order.length; i++) {
        expect(order[i], greaterThan(order[i - 1]), reason: 'khối thứ $i phải nằm dưới khối trước');
      }
      await _close(tester);
    });

    testWidgets('Tổng quan có thời gian ngủ', (tester) async {
      await _pump(tester, HomeScreen(goTab: (_) {}));
      expect(find.text('Thời gian ngủ'), findsOneWidget);
      expect(find.text('Thời gian bú'), findsOneWidget);
      await _close(tester);
    });

    testWidgets('Cữ gần nhất có cả cữ bú và cữ hút', (tester) async {
      await _pump(tester, HomeScreen(goTab: (_) {}));
      expect(app.ofType(T.feed), isNotEmpty);
      expect(app.ofType(T.pump), isNotEmpty);
      // dòng của "Cữ gần nhất": cả "Hút sữa" và một trong "Bình sữa"/"Cho bú" nằm dưới tiêu đề khối
      final top = tester.getTopLeft(find.text('Cữ bú gần nhất').first).dy;
      final bottom = tester.getTopLeft(find.text('Giấc ngủ hôm nay').first).dy;
      bool inBlock(String t) => find.text(t).evaluate().any((e) {
            final y = tester.getTopLeft(find.byWidget(e.widget).first).dy;
            return y > top && y < bottom;
          });
      expect(inBlock('Hút sữa'), isTrue, reason: 'có dòng cữ hút');
      expect(inBlock('Bình sữa') || inBlock('Cho bú'), isTrue, reason: 'có dòng cữ bú');
      await _close(tester);
    });

    testWidgets('chỉ còn ô "Ghi bú" (không còn hai ô Cho bú và Bình sữa giống nhau)', (tester) async {
      await _pump(tester, HomeScreen(goTab: (_) {}));
      expect(find.text('Ghi bú'), findsOneWidget);
      // trên Trang chủ không còn ô riêng "Cho bú" / "Bình sữa" ở hàng ô lớn
      expect(find.byType(ActivityTile), findsNWidgets(3), reason: 'Hút sữa, Ghi bú, Ngủ');
      await _close(tester);
    });
  });

  group('Ghi bú', () {
    testWidgets('mở tự chọn tab theo lần ghi gần nhất (bú mẹ → tab bú, bình → tab bình)', (tester) async {
      app.settings.breastStart = null;
      app.entries.removeWhere((e) => e.type == T.feed);
      app.addEntry(Entry(type: T.feed, time: DateTime.now().subtract(const Duration(hours: 1)), end: DateTime.now().subtract(const Duration(minutes: 40)), data: {'method': 'breast', 'side': 'L', 'min': 20}));
      await _pump(tester, const FeedScreen());
      expect(find.text('Bú mẹ trực tiếp'), findsWidgets);
      expect(find.textContaining('Lưu · '), findsNothing, reason: 'tab bú không có nút Lưu · ml');
      await _close(tester);

      app.entries.removeWhere((e) => e.type == T.feed);
      app.addEntry(Entry(type: T.feed, time: DateTime.now().subtract(const Duration(hours: 1)), data: {'method': 'bottle', 'ml': 90, 'source': 'mom'}));
      await _pump(tester, const FeedScreen());
      expect(find.textContaining('Lưu · '), findsOneWidget, reason: 'tab bình có nút Lưu · ml');
      await _close(tester);
    });

    testWidgets('bú mẹ trực tiếp chỉ chọn Trái hoặc Phải, không có "Hai bên"', (tester) async {
      await _pump(tester, const FeedScreen(initialTab: 1));
      expect(find.text('Trái'), findsWidgets);
      expect(find.text('Phải'), findsWidgets);
      expect(find.text('Hai bên'), findsNothing);
      await _close(tester);
    });

    testWidgets('nút ± lượng sữa tăng giảm 5 ml', (tester) async {
      app.entries.removeWhere((e) => e.type == T.feed);
      await _pump(tester, const FeedScreen(initialTab: 0));
      final txt = tester.widget<Text>(find.textContaining('Lưu · ').first).data!;
      final before = int.parse(RegExp(r'(\d+)ml').firstMatch(txt)!.group(1)!);
      await tester.tap(find.bySemanticsLabel('Tăng 5ml'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));
      final after = int.parse(RegExp(r'(\d+)ml').firstMatch(tester.widget<Text>(find.textContaining('Lưu · ').first).data!)!.group(1)!);
      expect(after - before, 5);
      await tester.tap(find.bySemanticsLabel('Giảm 5ml'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));
      final back = int.parse(RegExp(r'(\d+)ml').firstMatch(tester.widget<Text>(find.textContaining('Lưu · ').first).data!)!.group(1)!);
      expect(back, before);
      await _close(tester);
    });

    test('dữ liệu cũ chọn "hai bên" được đưa về bên trái', () {
      final s = Settings.fromJson({'bside': 'B'});
      expect(s.breastSide, 'L');
      expect(Settings.fromJson({'bside': 'R'}).breastSide, 'R');
    });
  });

  group('Tiện ích', () {
    test('không còn mục "Sức khoẻ" gộp trùng Nhiệt độ/Thuốc và không còn hai mục Cho bú/Bình sữa', () {
      final ids = kFeatures.map((f) => f.id).toList();
      expect(ids, isNot(contains('health')));
      expect(ids, isNot(contains('breast')));
      expect(ids, isNot(contains('bottle')));
      expect(ids, contains('feed'));
      expect(ids.where((i) => i == 'temp'), hasLength(1));
      expect(kFeatures.where((f) => f.title == 'Nhiệt độ'), hasLength(1));
      // không có hai chức năng cùng tên
      final titles = kFeatures.map((f) => f.title).toList();
      expect(titles.toSet().length, titles.length, reason: 'tên chức năng không được trùng');
    });

    test('ghim cũ (Cho bú, Bình sữa, Sức khoẻ) được đổi sang Ghi bú và bỏ trùng', () {
      final s = Settings.fromJson({'fv': ['pump', 'breast', 'bottle', 'health', 'sleep']});
      expect(s.favs, ['pump', 'feed', 'sleep']);
    });
  });

  group('nhịp EASY đổi theo lựa chọn', () {
    test('nhịp dài hơn thì thức lâu hơn, ngủ ngày ít cữ hơn nhưng mỗi cữ dài hơn', () {
      final s = Settings()..easyAuto = false;
      const age = 150; // ~5 tháng
      Range wake(int e) {
        s.easy = e;
        return Easy.wakeFor(s, age);
      }

      final w25 = wake(25), w30 = wake(30), w35 = wake(35), w40 = wake(40);
      expect(w30.mid, greaterThan(w25.mid));
      expect(w35.mid, greaterThan(w30.mid));
      expect(w40.mid, greaterThan(w35.mid));
      expect(Easy.napsFor(150), greaterThan(Easy.napsFor(240)), reason: 'nhịp ngắn thì nhiều cữ ngủ ngày hơn');
      final sp25 = Easy.split(150, age, wake: w25);
      final sp40 = Easy.split(240, age, wake: w40);
      expect(sp40.sleep, greaterThan(sp25.sleep), reason: 'nhịp dài thì mỗi cữ ngủ dài hơn');
      expect(sp40.activity, greaterThan(sp25.activity));
    });

    test('chế độ tự chọn giữ nguyên thời gian thức theo tuổi', () {
      final s = Settings()..easyAuto = true;
      for (final age in [20, 70, 100, 150, 200, 300]) {
        expect(Easy.wakeFor(s, age).mid, closeTo(Easy.wakeWindow(age).mid, 0.6), reason: 'tuổi $age ngày');
      }
    });

    testWidgets('màn EASY: đổi E2.5 → E4 làm đổi thời gian thức, số cữ ngủ và lịch gợi ý', (tester) async {
      app.settings.easyAuto = false;
      app.settings.easy = 25;
      app.settingsChanged();
      await _pump(tester, const EasyScreen());
      String texts() => find.byType(Text).evaluate().map((e) => (e.widget as Text).data ?? '').join('|');
      final before = texts();
      expect(before, contains('E2.5'));
      await tester.tap(find.text('E4'));
      await tester.pump(const Duration(seconds: 1));
      final after = texts();
      expect(after, contains('E4'));
      expect(after, isNot(before), reason: 'lịch gợi ý và thời gian thức phải đổi theo nhịp');
      // số cữ ngủ ngày: E2.5 → 5 cữ, E4 → 3 cữ
      expect(before, contains('5 cữ'));
      expect(after, contains('3 cữ'));
      app.settings.easyAuto = true;
      await _close(tester);
    });
  });

  group('nút ghi nhanh', () {
    testWidgets('nút + mở bảng ghi nhanh có đủ việc hay làm', (tester) async {
      await _pump(tester, const Align(alignment: Alignment.bottomRight, child: QuickAddButton()), h: 1200);
      await tester.tap(find.byType(QuickAddButton));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(seconds: 1));
      for (final t in ['Ghi bú', 'Hút sữa', 'Ngủ ngay', 'Tã ướt', 'Phân & tã', 'Nhiệt độ', 'Thuốc', 'Ghi chú', 'Chi tiêu']) {
        expect(find.text(t), findsWidgets, reason: 'bảng ghi nhanh thiếu "$t"');
      }
      await _close(tester);
    });

    testWidgets('chạm "Tã ướt" trong bảng ghi nhanh ghi ngay một cữ tã ướt', (tester) async {
      app.entries.removeWhere((e) => e.type == T.diaper);
      await _pump(tester, const Align(alignment: Alignment.bottomRight, child: QuickAddButton()), h: 1200);
      await tester.tap(find.byType(QuickAddButton));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('Tã ướt').first);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(seconds: 1));
      expect(app.entries.where((e) => e.type == T.diaper), hasLength(1));
      expect(app.entries.firstWhere((e) => e.type == T.diaper).str('kind'), 'wet');
      await _close(tester);
    });

    testWidgets('chạm "Ngủ ngay" bắt đầu ngủ; mở lại thì nút đổi thành "Dậy rồi"', (tester) async {
      app.entries.removeWhere((e) => e.type == T.sleep && e.end == null);
      await _pump(tester, const Align(alignment: Alignment.bottomRight, child: QuickAddButton()), h: 1200);
      await tester.tap(find.byType(QuickAddButton));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('Ngủ ngay').first);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(seconds: 1));
      expect(app.activeSleep, isNotNull);
      await tester.tap(find.byType(QuickAddButton));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Dậy rồi'), findsWidgets);
      app.entries.removeWhere((e) => e.type == T.sleep && e.end == null);
      await _close(tester);
    });
  });

  group('quỹ nhiều mục tiêu', () {
    testWidgets('thẻ "Mục tiêu quỹ" nằm ngay dưới thẻ tổng quỹ và liệt kê nhiều mục tiêu', (tester) async {
      app.goals
        ..clear()
        ..addAll([FundGoal(name: 'Học phí lớp 1', target: 120000000), FundGoal(name: 'Du học', target: 800000000)]);
      await _pump(tester, const MoneyTab());
      await tester.tap(find.text('Quỹ của con'));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Mục tiêu quỹ'), findsOneWidget);
      expect(find.text('Học phí lớp 1'), findsOneWidget);
      expect(find.text('Du học'), findsOneWidget);
      final total = tester.getTopLeft(find.textContaining('Tổng quỹ của').first).dy;
      final goals = tester.getTopLeft(find.text('Mục tiêu quỹ')).dy;
      final goal1 = tester.getTopLeft(find.text('Học phí lớp 1')).dy;
      expect(goals, greaterThan(total), reason: 'thẻ mục tiêu nằm dưới thẻ tổng quỹ');
      expect(goal1, greaterThan(goals));
      await _close(tester);
    });

    testWidgets('thêm một mục tiêu mới và xoá một mục tiêu', (tester) async {
      app.goals
        ..clear()
        ..add(FundGoal(name: 'Học phí lớp 1', target: 120000000));
      await _pump(tester, const MoneyTab());
      await tester.tap(find.text('Quỹ của con'));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('+ Thêm mục tiêu'));
      await tester.pump(const Duration(seconds: 1));
      await tester.enterText(find.byType(TextField).at(0), 'Mua nhà');
      await tester.enterText(find.byType(TextField).at(1), '2ty');
      await tester.pump();
      await tester.tap(find.text('Lưu').last);
      await tester.pump(const Duration(seconds: 1));
      expect(app.goals.map((g) => g.name), ['Học phí lớp 1', 'Mua nhà']);
      expect(app.goals.last.target, 2000000000);
      expect(find.text('Mua nhà'), findsOneWidget);

      await tester.tap(find.text('Mua nhà'));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('Xoá').last);
      await tester.pump(const Duration(seconds: 1));
      expect(app.goals.map((g) => g.name), ['Học phí lớp 1']);
      await _close(tester);
    });
  });

  group('Thu chi: bỏ ô mã hàng', () {
    testWidgets('màn Thêm khoản chi không còn ô Mã hàng/SKU', (tester) async {
      await _pump(tester, const MoneyAddScreen());
      expect(find.text('Mã hàng / SKU / mã vạch'), findsNothing);
      expect(find.text('Tên món / loại hàng'), findsWidgets);
      await _close(tester);
    });
  });

  group('Hồ sơ: chọn bé', () {
    testWidgets('dải bé có chip tên bé đang xem và nút Thêm bé', (tester) async {
      await _pump(tester, GuideTab(goTab: (_) {}));
      expect(find.text(app.baby!.name), findsWidgets);
      expect(find.text('Thêm bé'), findsOneWidget);
      await _close(tester);
    });
  });
}
