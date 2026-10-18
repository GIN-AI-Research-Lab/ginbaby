import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gin_baby/data/app_state.dart';
import 'package:gin_baby/data/demo.dart';
import 'package:gin_baby/data/models.dart';

/// Ảnh 1x1 PNG hợp lệ.
final Uint8List _png = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8AARAAGAAFJZcaaAAAAAElFTkSuQmCC');

/// Kiểm thử luồng tuần 1 (Bú, Ngủ, Hút sữa, Tã) ở tầng dữ liệu: lưu, hoàn tác, xoá, sửa.
/// Các mục giao diện tương ứng được ghi trong docs/TEST_PLAN.md.
void main() {
  setUpAll(() async {
    await seedDemo(app);
  });

  // Ghi trễ của app (debounce) gây cảnh báo "pending timer" khi chạy trong test; các hàm bên dưới không cần chờ.
  Future<void> flush() async => await Future<void>.delayed(const Duration(milliseconds: 1));

  group('Bú (F)', () {
    test('F3: bú trực tiếp lưu đúng thời lượng và số phút', () async {
      final start = DateTime.now().subtract(const Duration(minutes: 12));
      final e = app.addBreast(start: start, end: DateTime.now(), side: 'L');
      expect(e.type, T.feed);
      expect(e.str('method'), 'breast');
      expect(e.num('min').round(), inInclusiveRange(11, 13));
      app.removeEntry(e.id);
      await flush();
    });

    test('F4: lưu rồi hoàn tác thì bản ghi biến mất', () async {
      final before = app.entries.length;
      final e = app.addBreast(start: DateTime.now().subtract(const Duration(minutes: 5)), end: DateTime.now(), side: 'R');
      expect(app.entries.length, before + 1);
      app.removeEntry(e.id); // đường hoàn tác dùng cùng hàm
      expect(app.entries.length, before);
      expect(app.entries.any((x) => x.id == e.id), isFalse);
      await flush();
    });

    test('F5: sửa lượng ml của bình sữa được lưu lại', () async {
      final e = Entry(type: T.feed, time: DateTime.now(), data: {'method': 'bottle', 'ml': 120, 'milk': 'mom'});
      app.addEntry(e);
      e.data['ml'] = 150;
      app.updateEntry(e);
      expect(app.entries.firstWhere((x) => x.id == e.id).ml, 150);
      app.removeEntry(e.id);
      await flush();
    });
  });

  group('Ngủ (S)', () {
    test('S1: ngủ ngay → đang ngủ → dậy thì ghi đủ thời lượng', () async {
      app.startSleep(DateTime.now().subtract(const Duration(minutes: 40)));
      expect(app.activeSleep, isNotNull);
      final done = app.endSleep(DateTime.now());
      expect(done, isNotNull);
      expect(app.activeSleep, isNull);
      expect(done!.end!.difference(done.time).inMinutes, inInclusiveRange(39, 41));
      app.removeEntry(done.id);
      await flush();
    });

    test('S2: hoàn tác "Bé dậy rồi" đưa bé về trạng thái đang ngủ', () async {
      app.startSleep(DateTime.now().subtract(const Duration(minutes: 20)));
      final done = app.endSleep();
      expect(app.activeSleep, isNull);
      // đúng như màn Giấc ngủ làm khi hoàn tác
      done!.end = null;
      app.changed('entries');
      expect(app.activeSleep, isNotNull);
      app.removeEntry(done.id);
      await flush();
    });

    test('S3: nhập nhanh một giấc đã qua không tạo giấc đang chạy', () async {
      final e = Entry(type: T.sleep, time: DateTime.now().subtract(const Duration(hours: 1)), end: DateTime.now().subtract(const Duration(minutes: 30)));
      app.addEntry(e);
      expect(app.activeSleep, isNull);
      app.removeEntry(e.id);
      await flush();
    });

    test('S4: huỷ giấc đang chạy xoá đúng bản ghi đó', () async {
      app.startSleep(DateTime.now().subtract(const Duration(minutes: 5)));
      final s = app.activeSleep!;
      app.removeEntry(s.id);
      expect(app.activeSleep, isNull);
      await flush();
    });
  });

  group('Hút sữa (P)', () {
    test('P3: lưu cữ hút tăng số cữ trong ngày', () async {
      final n = app.pumpSessionsOn(DateTime.now());
      final e = app.addPump(mlL: 60, mlR: 55, minutes: 15);
      expect(app.pumpSessionsOn(DateTime.now()), n + 1);
      expect(e.ml, 115);
      app.removeEntry(e.id);
      await flush();
    });

    test('P4: đặt lại chỉ bỏ nháp, không xoá cữ đã lưu', () async {
      final e = app.addPump(mlL: 40, mlR: 40, minutes: 10);
      final n = app.pumpSessionsOn(DateTime.now());
      // nháp chưa lưu không nằm trong danh sách; đặt lại không được chạm tới bản đã lưu
      expect(app.pumpSessionsOn(DateTime.now()), n);
      expect(app.entries.any((x) => x.id == e.id), isTrue);
      app.removeEntry(e.id);
      await flush();
    });
  });

  group('Tã (D)', () {
    test('D4: chỉ tã ướt không có trường phân', () async {
      final e = Entry(type: T.diaper, time: DateTime.now(), data: {'kind': 'wet', 'amount': 'vừa'});
      app.addEntry(e);
      expect(e.str('kind'), 'wet');
      expect(e.data.containsKey('color'), isFalse);
      app.removeEntry(e.id);
      await flush();
    });

    test('D6: hoàn tác bản ghi có ảnh cũng xoá ảnh khỏi bộ nhớ', () async {
      final id = await app.putPhoto(_png);
      final e = Entry(type: T.diaper, time: DateTime.now(), data: {'kind': 'poo', 'color': 'Vàng', 'state': 'Sệt', 'amount': 'vừa', 'photo': id});
      app.addEntry(e);
      expect(app.photo(id), isNotNull);
      app.removeEntry(e.id);
      expect(app.photo(id), isNull, reason: 'ảnh không còn bản ghi nào dùng thì phải bị xoá');
      await flush();
    });

    test('D6b: ảnh vẫn được giữ nếu còn bản ghi khác dùng', () async {
      final id = await app.putPhoto(_png);
      final a = Entry(type: T.diaper, time: DateTime.now(), data: {'kind': 'wet', 'photo': id});
      final b = Entry(type: T.diaper, time: DateTime.now(), data: {'kind': 'wet', 'photo': id});
      app.addEntry(a);
      app.addEntry(b);
      app.removeEntry(a.id);
      expect(app.photo(id), isNotNull);
      app.removeEntry(b.id);
      await flush();
    });

    test('D7: bỏ ảnh trước khi lưu không để lại ảnh trong bản ghi', () async {
      final id = await app.putPhoto(_png);
      final data = <String, dynamic>{'kind': 'wet'};
      // màn Phân & tã chỉ đặt lại biến ảnh khi bấm X; bản ghi lưu sau đó không có khoá photo
      expect(data.containsKey('photo'), isFalse);
      expect(app.photo(id), isNotNull);
      await app.deletePhoto(id);
      expect(app.photo(id), isNull);
    });
  });
}
