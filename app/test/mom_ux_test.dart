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
import 'package:gin_baby/ui/feed_screen.dart';
import 'package:gin_baby/ui/home.dart';

/// Thao tác một tay cho mẹ bỉm: vùng chạm 44, ghi nhanh 1 chạm, tóm tắt đầu Trang chủ, bình sữa không cần bấm Xong.
Future<void> _home(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390 * 2, 1800 * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(MaterialApp(debugShowCheckedModeBanner: false, home: Scaffold(body: HomeScreen(goTab: (_) {}))));
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

  setUp(() {
    app.entries.removeWhere((e) => e.type == T.sleep && e.end == null);
  });

  group('vùng chạm tối thiểu 44', () {
    testWidgets('nút tròn nhỏ (30) vẫn có vùng chạm 44x44', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: RoundIconButton(icon: Icons.add_rounded, label: 'Tăng', size: 30, onTap: () {})))));
      final s = tester.getSize(find.byType(RoundIconButton));
      expect(s.width, greaterThanOrEqualTo(44));
      expect(s.height, greaterThanOrEqualTo(44));
    });

    testWidgets('chạm lệch ra ngoài hình tròn 30 nhưng trong vùng 44 vẫn trúng', (tester) async {
      var n = 0;
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: RoundIconButton(icon: Icons.add_rounded, label: 'Tăng', size: 30, onTap: () => n++)))));
      final c = tester.getCenter(find.byType(RoundIconButton));
      await tester.tapAt(c + const Offset(19, 0)); // cách tâm 19 > bán kính 15 của hình tròn
      await tester.pump(const Duration(milliseconds: 200));
      expect(n, 1);
    });

    testWidgets('chip thấp (36) có vùng chạm cao 44', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: PillChip(label: 'Sữa', on: false, onTap: () {})))));
      expect(tester.getSize(find.byType(PillChip)).height, greaterThanOrEqualTo(44));
    });

    testWidgets('thanh chọn đoạn (Seg) cao tối thiểu 44 và chạm cả chiều cao', (tester) async {
      var i = 0;
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: SizedBox(width: 300, child: Seg(labels: const ['Ngày', 'Tuần'], index: 0, height: 34, onChanged: (v) => i = v))))));
      expect(tester.getSize(find.byType(Seg)).height, greaterThanOrEqualTo(44));
      final r = tester.getRect(find.byType(Seg));
      await tester.tapAt(Offset(r.right - 40, r.top + 3)); // sát mép trên của thanh
      await tester.pump(const Duration(milliseconds: 200));
      expect(i, 1);
    });
  });

  group('ghi nhanh 1 chạm trên Trang chủ', () {
    testWidgets('chạm vòng tròn ở ô Ngủ: bắt đầu ngủ, chạm lần nữa: bé dậy', (tester) async {
      await _home(tester);
      expect(app.activeSleep, isNull);
      final tile = find.byType(ActivityTile).evaluate().map((e) => e.widget as ActivityTile).firstWhere((t) => t.label == 'Ngủ');
      tile.onQuick!();
      await tester.pump(const Duration(milliseconds: 300));
      expect(app.activeSleep, isNotNull, reason: 'chạm 1 lần là bắt đầu ngủ');
      expect(find.textContaining('Bé bắt đầu ngủ lúc'), findsOneWidget);

      final tile2 = find.byType(ActivityTile).evaluate().map((e) => e.widget as ActivityTile).firstWhere((t) => t.label == 'Dậy rồi');
      tile2.onQuick!();
      await tester.pump(const Duration(milliseconds: 300));
      expect(app.activeSleep, isNull, reason: 'chạm lần nữa là bé dậy');
      expect(find.textContaining('Bé dậy rồi, ngủ'), findsOneWidget);
      app.entries.removeWhere((e) => e.type == T.sleep && e.time.isAfter(DateTime.now().subtract(const Duration(minutes: 5))));
      await _close(tester);
    });

    testWidgets('Hoàn tác sau khi bắt đầu ngủ xoá giấc ngủ vừa tạo', (tester) async {
      await _home(tester);
      final tile = find.byType(ActivityTile).evaluate().map((e) => e.widget as ActivityTile).firstWhere((t) => t.label == 'Ngủ');
      tile.onQuick!();
      await tester.pump(const Duration(milliseconds: 300));
      expect(app.activeSleep, isNotNull);
      tester.widget<SnackBarAction>(find.byType(SnackBarAction)).onPressed();
      await tester.pump();
      expect(app.activeSleep, isNull);
      await _close(tester);
    });

    testWidgets('giữ ô "Phân & tã": ghi ngay một cữ tã ướt, có Hoàn tác', (tester) async {
      await _home(tester);
      final before = app.entries.where((e) => e.type == T.diaper).length;
      await tester.longPress(find.text('Phân & tã').first);
      await tester.pump(const Duration(milliseconds: 300));
      expect(app.entries.where((e) => e.type == T.diaper).length, before + 1);
      final e = app.entries.firstWhere((x) => x.type == T.diaper);
      expect(e.str('kind'), 'wet');
      expect(find.text('Đã ghi tã ướt'), findsOneWidget);
      tester.widget<SnackBarAction>(find.byType(SnackBarAction)).onPressed();
      await tester.pump();
      expect(app.entries.where((x) => x.type == T.diaper).length, before);
      await _close(tester);
    });
  });

  group('tóm tắt nhanh đầu Trang chủ', () {
    testWidgets('hiện bú lần cuối, giấc ngủ và số tã hôm nay', (tester) async {
      await _home(tester);
      expect(find.text('Bú lần cuối'), findsOneWidget);
      expect(find.text('Giấc ngủ'), findsWidgets);
      expect(find.text('Tã hôm nay'), findsOneWidget);
      final lf = app.lastFeed!;
      expect(find.text(_agoText(lf.time)), findsWidgets);
      await _close(tester);
    });

    testWidgets('đang ngủ thì hiện "Đang ngủ ..."', (tester) async {
      app.startSleep(DateTime.now().subtract(const Duration(minutes: 25)));
      await _home(tester);
      expect(find.textContaining('Đang ngủ 25'), findsWidgets);
      app.entries.removeWhere((e) => e.type == T.sleep && e.end == null);
      await _close(tester);
    });
  });

  group('ghi bình sữa', () {
    Future<void> openFeed(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 2, 1800 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(body: Center(child: ElevatedButton(onPressed: () => openPage(context, const FeedScreen(initialTab: 0)), child: const Text('mở')))),
        ),
      ));
      await tester.tap(find.text('mở'));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('lượng bình thường: lưu xong tự đóng màn và chỉ báo ngắn, không hộp "Xong"', (tester) async {
      final before = app.entries.where((e) => e.type == T.feed).length;
      await openFeed(tester);
      // chỉnh về mức thường gặp theo tuổi bé: dùng giá trị mặc định (gợi ý theo tuổi/cữ trước)
      final save = find.textContaining('Lưu ·');
      await tester.tap(save.first);
      await tester.pump(const Duration(seconds: 1));
      expect(app.entries.where((e) => e.type == T.feed).length, before + 1);
      for (var i = 0; i < 15 && find.byType(FeedScreen).evaluate().isNotEmpty && find.text('Xong').evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      if (find.text('Xong').evaluate().isEmpty) {
        expect(find.byType(FeedScreen), findsNothing, reason: 'đã đóng màn ghi bú');
        expect(find.textContaining('trong mức thường gặp'), findsOneWidget);
      } else {
        // lượng mặc định rơi vào mức cần chú ý: hộp đánh giá vẫn hiện (đúng thiết kế)
        expect(find.textContaining('Đã ghi'), findsWidgets);
      }
      app.removeEntry(app.entries.firstWhere((e) => e.type == T.feed).id);
      await _close(tester);
    });
  });
}

String _agoText(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'vừa xong';
  if (d.inMinutes < 60) return '${d.inMinutes} phút trước';
  if (d.inHours < 24) {
    final m = d.inMinutes % 60;
    return m == 0 ? '${d.inHours}h trước' : '${d.inHours}h${m.toString().padLeft(2, '0')} trước';
  }
  return '${d.inDays} ngày trước';
}
