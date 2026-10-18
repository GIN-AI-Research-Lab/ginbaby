import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gin_baby/data/app_state.dart';
import 'package:gin_baby/data/demo.dart';
import 'package:gin_baby/data/models.dart';
import 'package:gin_baby/ui/baby_profile.dart';
import 'package:gin_baby/ui/guide.dart';

/// Hút sữa: chọn nhanh lượng và "như lần trước". Hồ sơ: ảnh đại diện, thông tin bé sửa từng dòng, cài đặt nhanh.
Future<void> _pump(WidgetTester tester, Widget w, {double h = 3200}) async {
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

Future<void> _sheet(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(seconds: 1));
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

  group('Hồ sơ: thông tin của bé', () {
    testWidgets('hiện đủ các dòng thông tin và dải bé', (tester) async {
      await _pump(tester, GuideTab(goTab: (_) {}));
      expect(find.text('Thông tin của bé'), findsOneWidget);
      for (final t in ['Tên', 'Giới tính', 'Ngày giờ sinh', 'Cân nặng lúc sinh', 'Chiều dài lúc sinh', 'Tuổi thai khi sinh', 'Cách ăn']) {
        expect(find.text(t), findsOneWidget, reason: 'thiếu dòng "$t"');
      }
      expect(find.text('Cài đặt nhanh'), findsOneWidget);
      await _close(tester);
    });

    testWidgets('sửa tên bé', (tester) async {
      final old = app.baby!.name;
      await _pump(tester, GuideTab(goTab: (_) {}));
      await tester.tap(find.bySemanticsLabel(RegExp('^Tên, ')).first);
      await _sheet(tester);
      await tester.enterText(find.byType(TextField).first, 'Gin Gin');
      await tester.pump();
      await tester.tap(find.text('Lưu').last);
      await _sheet(tester);
      expect(app.baby!.name, 'Gin Gin');
      app.saveBaby(app.baby!..name = old);
      await _close(tester);
    });

    testWidgets('đổi giới tính và cách ăn', (tester) async {
      final oldSex = app.baby!.sex, oldMode = app.baby!.mode;
      await _pump(tester, GuideTab(goTab: (_) {}));
      await tester.tap(find.bySemanticsLabel(RegExp('^Giới tính, ')).first);
      await _sheet(tester);
      await tester.tap(find.text(oldSex == Sex.girl ? 'Bé trai' : 'Bé gái').last);
      await _sheet(tester);
      expect(app.baby!.sex, oldSex == Sex.girl ? Sex.boy : Sex.girl);

      await tester.tap(find.bySemanticsLabel(RegExp('^Cách ăn, ')).first);
      await _sheet(tester);
      await tester.tap(find.text('Công thức').last);
      await _sheet(tester);
      expect(app.baby!.mode, FeedMode.formula);
      app.saveBaby(app.baby!
        ..sex = oldSex
        ..mode = oldMode);
      await _close(tester);
    });

    testWidgets('sửa cân nặng lúc sinh bằng nút −/+ rồi Lưu', (tester) async {
      final old = app.baby!.birthWeightKg;
      await _pump(tester, GuideTab(goTab: (_) {}));
      await tester.tap(find.bySemanticsLabel(RegExp('^Cân nặng lúc sinh, ')).first);
      await _sheet(tester);
      await tester.tap(find.bySemanticsLabel('Tăng Cân nặng lúc sinh'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.bySemanticsLabel('Tăng Cân nặng lúc sinh'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('Lưu').last);
      await _sheet(tester);
      expect(app.baby!.birthWeightKg, closeTo(old + 0.2, 0.001));
      app.saveBaby(app.baby!..birthWeightKg = old);
      await _close(tester);
    });

    testWidgets('sửa cân nặng hiện tại đổi số cân dù đã có các lần cân trước (lỗi: trước đây không đổi)', (tester) async {
      expect(app.measurements, isNotEmpty);
      final old = app.weightKg;
      await _pump(tester, GuideTab(goTab: (_) {}));
      await tester.tap(find.bySemanticsLabel(RegExp('^Cân nặng hiện tại, ')).first);
      await _sheet(tester);
      await tester.tap(find.bySemanticsLabel('Tăng Cân nặng hiện tại'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('Lưu').last);
      await _sheet(tester);
      expect(app.weightKg, closeTo(old + 0.1, 0.001));
      // sửa lần nữa trong cùng ngày thì cập nhật lần cân hôm nay, không thêm bản ghi mới
      final n = app.measurements.length;
      app.setCurrentWeight(old + 0.3);
      expect(app.measurements.length, n);
      expect(app.weightKg, closeTo(old + 0.3, 0.001));
      app.measurements.removeWhere((m) => m.date.isAfter(DateTime.now().subtract(const Duration(hours: 1))));
      await _close(tester);
    });

    testWidgets('tuổi thai < 37 tuần hiện nhãn "sinh non"', (tester) async {
      final old = app.baby!.gestWeeks;
      app.saveBaby(app.baby!..gestWeeks = 34);
      await _pump(tester, GuideTab(goTab: (_) {}));
      expect(find.textContaining('34 tuần (sinh non)'), findsOneWidget);
      app.saveBaby(app.baby!..gestWeeks = old);
      await _close(tester);
    });

    testWidgets('cài đặt nhanh: bật/tắt nhắc nhở và đổi giao diện', (tester) async {
      final oldRemind = app.settings.remind;
      await _pump(tester, GuideTab(goTab: (_) {}));
      await tester.tap(find.byType(Switch).first);
      await tester.pump(const Duration(milliseconds: 300));
      expect(app.settings.remind, !oldRemind);
      await tester.tap(find.text('Theo giờ').last);
      await tester.pump(const Duration(milliseconds: 600));
      expect(app.settings.themeMode, 3);
      app.settings.remind = oldRemind;
      app.settings.themeMode = 0;
      await _close(tester);
    });

    testWidgets('ảnh đại diện: chạm mở bảng chọn ảnh', (tester) async {
      await _pump(tester, GuideTab(goTab: (_) {}));
      await tester.tap(find.byType(BabyAvatar).first);
      await _sheet(tester);
      expect(find.text('Thư viện ảnh'), findsOneWidget);
      expect(find.text('Chụp ảnh'), findsOneWidget);
      await _close(tester);
    });

    test('ảnh đại diện lưu trong hồ sơ, sao lưu và được tính là ảnh đang dùng', () {
      final b = Baby(name: 'An', sex: Sex.girl, dob: DateTime(2026, 6, 1), photo: 'abc123');
      final r = Baby.fromJson(Map<String, dynamic>.from(b.toJson()));
      expect(r.photo, 'abc123');
      expect(Baby.fromJson(Map<String, dynamic>.from(Baby(name: 'B', sex: Sex.boy, dob: DateTime(2026, 6, 1)).toJson())).photo, isNull);
      final old = app.baby!.photo;
      app.baby!.photo = 'xyz789';
      expect(app.usedPhotoIds, contains('xyz789'));
      app.baby!.photo = old;
    });
  });
}
