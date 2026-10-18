import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gin_baby/core/kit.dart';
import 'package:gin_baby/core/theme.dart';
import 'package:gin_baby/data/app_state.dart';
import 'package:gin_baby/data/demo.dart';
import 'package:gin_baby/data/models.dart';
import 'package:gin_baby/main.dart';
import 'package:gin_baby/ui/settings.dart';

/// Chế độ giao diện "Theo giờ": từ 20h tối tự đổi sang giao diện tối, 6h sáng trở lại sáng.
void main() {
  group('khung giờ tối (Settings.isNight)', () {
    Settings s0(int from, int to) => Settings()
      ..darkFrom = from
      ..darkTo = to;
    DateTime at(int h, [int m = 0]) => DateTime(2026, 10, 8, h, m);

    test('mặc định 20h đến 6h: 8 giờ tối là tối, 6 giờ sáng là sáng', () {
      final s = Settings();
      expect(s.darkFrom, 20);
      expect(s.darkTo, 6);
      expect(s.isNight(at(19, 59)), isFalse, reason: '19:59 chưa tới 20h');
      expect(s.isNight(at(20)), isTrue, reason: 'đúng 20:00 đổi sang tối');
      expect(s.isNight(at(23, 59)), isTrue);
      expect(s.isNight(at(0)), isTrue, reason: 'qua nửa đêm vẫn tối');
      expect(s.isNight(at(5, 59)), isTrue);
      expect(s.isNight(at(6)), isFalse, reason: 'đúng 6:00 trở lại sáng');
      expect(s.isNight(at(12)), isFalse);
    });

    test('khung trong cùng một ngày (vd. 13h đến 15h)', () {
      final s = s0(13, 15);
      expect(s.isNight(at(12, 59)), isFalse);
      expect(s.isNight(at(13)), isTrue);
      expect(s.isNight(at(14, 59)), isTrue);
      expect(s.isNight(at(15)), isFalse);
    });

    test('giờ bắt đầu trùng giờ kết thúc thì không bao giờ tối', () {
      final s = s0(8, 8);
      for (var h = 0; h < 24; h++) {
        expect(s.isNight(at(h)), isFalse, reason: '$h giờ');
      }
    });

    test('lưu và đọc lại cài đặt giữ nguyên chế độ và khung giờ', () {
      final s = Settings()
        ..themeMode = 3
        ..darkFrom = 21
        ..darkTo = 5;
      final r = Settings.fromJson(Map<String, dynamic>.from(s.toJson()));
      expect(r.themeMode, 3);
      expect(r.darkFrom, 21);
      expect(r.darkTo, 5);
    });

    test('dữ liệu cũ chưa có khung giờ thì dùng 20h và 6h', () {
      final r = Settings.fromJson({'tm': 1});
      expect(r.themeMode, 1);
      expect(r.darkFrom, 20);
      expect(r.darkTo, 6);
    });
  });

  group('giao diện', () {
    setUpAll(() async {
      final loader = FontLoader('Inter');
      for (final w in const ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
        loader.addFont(Future.value(ByteData.sublistView(File('assets/google_fonts/Inter-$w.ttf').readAsBytesSync())));
      }
      await loader.load();
      await seedDemo(app);
      app.ready = true; // để Root hiện Trang chủ thay vì màn chờ
    });

    toggleTests();

    tearDown(() {
      app.settings.themeMode = 0;
      app.settings.darkFrom = 20;
      app.settings.darkTo = 6;
      GB.dark = false;
    });

    testWidgets('Cài đặt: chọn "Theo giờ" hiện hai hàng chỉnh giờ, +/− đổi giờ và quay vòng qua nửa đêm', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 1800 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SettingsScreen())));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Giao diện tối từ'), findsNothing, reason: 'chưa chọn Theo giờ thì chưa hiện');

      await tester.tap(find.text('Theo giờ'));
      await tester.pump(const Duration(seconds: 1));
      expect(app.settings.themeMode, 3);
      expect(find.text('Giao diện tối từ'), findsOneWidget);
      expect(find.text('Trở lại sáng lúc'), findsOneWidget);
      // chữ giờ của hai hàng chỉnh (khác các chip giờ hút sữa ở phần khác)
      Finder hour(String t) => find.byWidgetPredicate((w) => w is SizedBox && w.width == 64 && w.child is Text && (w.child as Text).data == t);
      expect(hour('20h'), findsOneWidget);
      expect(hour('6h'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Tăng 1 giờ (Giao diện tối từ)'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));
      expect(app.settings.darkFrom, 21);
      expect(hour('21h'), findsOneWidget, reason: 'số giờ hiển thị cập nhật theo');

      app.settings.darkFrom = 23;
      app.settingsChanged();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.bySemanticsLabel('Tăng 1 giờ (Giao diện tối từ)'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));
      expect(app.settings.darkFrom, 0, reason: '23h + 1 giờ quay về 0h');

      await tester.tap(find.bySemanticsLabel('Giảm 1 giờ (Trở lại sáng lúc)'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));
      expect(app.settings.darkTo, 5);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('App đang mở: tới giờ tối thì tự đổi sau tối đa 30 giây mà không cần chạm gì', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 1800 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      final h = DateTime.now().hour;
      app.settings.themeMode = 3;
      app.settings.darkFrom = (h + 3) % 24; // chưa tới giờ tối
      app.settings.darkTo = (h + 5) % 24;
      await tester.pumpWidget(const GinBabyApp());
      await tester.pump(const Duration(seconds: 2));
      expect(GB.dark, isFalse);

      // "Đồng hồ trôi tới giờ tối": đổi khung mà không báo cho app, chỉ có bộ hẹn định kỳ phát hiện
      app.settings.darkFrom = (h + 23) % 24;
      app.settings.darkTo = (h + 2) % 24;
      await tester.pump(const Duration(seconds: 31));
      await tester.pump(const Duration(seconds: 1));
      expect(GB.dark, isTrue, reason: 'bộ hẹn 30 giây phải đổi sang tối');

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('Đang ở màn con thì hoãn đổi sang tối, quay về màn chính mới đổi (không mất dữ liệu đang nhập)', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 1800 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      final h = DateTime.now().hour;
      app.settings.themeMode = 3;
      app.settings.darkFrom = (h + 3) % 24;
      app.settings.darkTo = (h + 5) % 24;
      await tester.pumpWidget(const GinBabyApp());
      await tester.pump(const Duration(seconds: 2));
      expect(GB.dark, isFalse);

      // mẹ mở một màn con và đang nhập
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      nav.push(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Center(child: Text('man-con-dang-nhap')))));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('man-con-dang-nhap', skipOffstage: false), findsOneWidget);

      // tới giờ tối trong lúc đang ở màn con
      app.settings.darkFrom = (h + 23) % 24;
      app.settings.darkTo = (h + 2) % 24;
      await tester.pump(const Duration(seconds: 31));
      await tester.pump(const Duration(seconds: 31));
      expect(GB.dark, isFalse, reason: 'đang ở màn con nên chưa đổi');
      expect(find.text('man-con-dang-nhap', skipOffstage: false), findsOneWidget, reason: 'màn con đang mở vẫn còn, không bị dựng lại về Trang chủ');

      // quay về màn chính: đổi sang tối ở lần kiểm tra kế tiếp
      nav.pop();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 31));
      await tester.pump(const Duration(seconds: 1));
      expect(GB.dark, isTrue);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('App: chế độ Theo giờ tối khi giờ hiện tại nằm trong khung và sáng khi nằm ngoài', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 1800 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      final h = DateTime.now().hour;

      // khung tối bao quanh giờ hiện tại
      app.settings.themeMode = 3;
      app.settings.darkFrom = (h + 23) % 24;
      app.settings.darkTo = (h + 2) % 24;
      await tester.pumpWidget(const GinBabyApp());
      await tester.pump(const Duration(seconds: 2));
      expect(GB.dark, isTrue, reason: 'giờ hiện tại $h nằm trong khung tối');

      // đổi khung ra xa giờ hiện tại: app dựng lại ở chế độ sáng
      app.settings.darkFrom = (h + 3) % 24;
      app.settings.darkTo = (h + 5) % 24;
      app.settingsChanged();
      await tester.pump(const Duration(seconds: 2));
      expect(GB.dark, isFalse, reason: 'giờ hiện tại $h nằm ngoài khung tối');

      // chế độ Sáng cố định luôn sáng dù khung đang bao quanh giờ hiện tại
      app.settings.themeMode = 1;
      app.settings.darkFrom = (h + 23) % 24;
      app.settings.darkTo = (h + 2) % 24;
      app.settingsChanged();
      await tester.pump(const Duration(seconds: 2));
      expect(GB.dark, isFalse);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
    });
  });
}

/// Nút sáng/tối trên Trang chủ: bấm khi đang sáng phải sang tối (ở mọi chế độ giao diện).
void toggleTests() {
  for (final mode in [0, 1, 3]) {
    testWidgets('nút sáng/tối: đang sáng (chế độ $mode) bấm thì sang tối', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 1800 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      final h = DateTime.now().hour;
      app.settings.themeMode = mode;
      app.settings.darkFrom = (h + 3) % 24; // khung tối ở xa giờ hiện tại: đang sáng
      app.settings.darkTo = (h + 5) % 24;
      await tester.pumpWidget(const GinBabyApp());
      await tester.pump(const Duration(seconds: 2));
      expect(GB.dark, isFalse);
      // chạm nút (ứng dụng nằm trong Offstage lúc khởi động nên gọi thẳng hành động chạm của nút)
      tester.widget<Pressable>(find.descendant(of: find.byType(ThemeToggle, skipOffstage: false), matching: find.byType(Pressable, skipOffstage: false)).first).onTap!();
      await tester.pump(const Duration(seconds: 2));
      expect(GB.dark, isTrue, reason: 'bấm nút khi đang sáng phải sang tối (chế độ $mode)');
      expect(app.settings.themeMode, 2);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
      app.settings.themeMode = 0;
    });
  }
}
