import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gin_baby/core/kv.dart';
import 'package:gin_baby/data/app_state.dart';
import 'package:gin_baby/data/models.dart';

/// Quản lý nhiều bé: dữ liệu mỗi bé tách biệt, chuyển bé, lưu qua khởi động lại, tương thích dữ liệu cũ, sao lưu/khôi phục.
Baby _baby(String name) => Baby(name: name, sex: Sex.girl, dob: DateTime(2026, 6, 1));

Future<AppState> _fresh(KV kv) async {
  final a = AppState();
  await a.init(kv: kv);
  return a;
}

void main() {
  group('nhiều bé', () {
    test('mỗi bé có dữ liệu riêng và chuyển qua lại không lẫn', () async {
      final kv = await KV.memory();
      final a = await _fresh(kv);
      a.saveBaby(_baby('An'));
      a.addEntry(Entry(type: T.feed, time: DateTime(2026, 10, 1, 8), data: {'method': 'bottle', 'ml': 100}));
      a.addTx(Tx(time: DateTime(2026, 10, 1), amount: -50000, title: 'Tã An'));
      expect(a.babies.map((b) => b.name), ['An']);

      await a.addBaby(_baby('Bình'));
      expect(a.baby!.name, 'Bình');
      expect(a.entries, isEmpty, reason: 'bé mới chưa có dữ liệu');
      expect(a.txs, isEmpty);
      a.addEntry(Entry(type: T.sleep, time: DateTime(2026, 10, 2, 9), end: DateTime(2026, 10, 2, 10)));
      expect(a.babies.map((b) => b.name), ['An', 'Bình']);

      await a.switchBaby(a.babies.first.id);
      expect(a.baby!.name, 'An');
      expect(a.entries.map((e) => e.type), [T.feed], reason: 'dữ liệu của An còn nguyên');
      expect(a.txs.single.title, 'Tã An');

      await a.switchBaby(a.babies.last.id);
      expect(a.baby!.name, 'Bình');
      expect(a.entries.map((e) => e.type), [T.sleep]);
      expect(a.txs, isEmpty);
    });

    test('khởi động lại: nhớ bé đang xem và đủ dữ liệu cả hai bé', () async {
      final kv = await KV.memory();
      var a = await _fresh(kv);
      a.saveBaby(_baby('An'));
      a.addEntry(Entry(type: T.feed, time: DateTime(2026, 10, 1, 8), data: {'method': 'bottle', 'ml': 100}));
      await a.addBaby(_baby('Bình'));
      a.addEntry(Entry(type: T.sleep, time: DateTime(2026, 10, 2, 9), end: DateTime(2026, 10, 2, 10)));
      await a.flushNow();

      a = await _fresh(kv); // mở lại app
      expect(a.babies.map((b) => b.name), ['An', 'Bình']);
      expect(a.baby!.name, 'Bình', reason: 'nhớ bé đang xem');
      expect(a.entries.single.type, T.sleep);
      await a.switchBaby(a.babies.first.id);
      expect(a.entries.single.type, T.feed);
    });

    test('dữ liệu cũ một bé (chưa có danh sách bé) vẫn nạp được thành bé đầu tiên', () async {
      final kv = await KV.memory();
      await kv.set('gb1.baby', jsonEncode(_baby('Cũ').toJson()));
      await kv.set('gb1.entries', jsonEncode([Entry(type: T.note, time: DateTime(2026, 9, 1), data: {'text': 'x'}).toJson()]));
      final a = await _fresh(kv);
      expect(a.baby!.name, 'Cũ');
      expect(a.entries, hasLength(1));
      expect(a.babies.map((b) => b.name), ['Cũ']);
      expect(a.activeId, 'main');
      // thêm bé mới không làm mất dữ liệu cũ
      await a.addBaby(_baby('Mới'));
      await a.switchBaby('main');
      expect(a.entries, hasLength(1));
    });

    test('đổi tên bé cập nhật danh sách bé', () async {
      final a = await _fresh(await KV.memory());
      a.saveBaby(_baby('An'));
      a.saveBaby(a.baby!..name = 'An An');
      expect(a.babies.single.name, 'An An');
    });

    test('xoá bé: không xoá được khi chỉ còn một; xoá bé đang xem thì chuyển sang bé còn lại', () async {
      final a = await _fresh(await KV.memory());
      a.saveBaby(_baby('An'));
      await a.removeBaby(a.babies.single.id);
      expect(a.babies, hasLength(1), reason: 'chỉ còn một bé thì không được xoá');

      await a.addBaby(_baby('Bình'));
      a.addEntry(Entry(type: T.note, time: DateTime(2026, 10, 3), data: {'text': 'của Bình'}));
      final binhId = a.activeId;
      await a.removeBaby(binhId);
      expect(a.babies.map((b) => b.name), ['An']);
      expect(a.baby!.name, 'An');
      expect(a.entries.any((e) => e.str('text') == 'của Bình'), isFalse);
    });

    test('sao lưu rồi khôi phục giữ cả hai bé và bé đang xem', () async {
      final a = await _fresh(await KV.memory());
      a.saveBaby(_baby('An'));
      a.addEntry(Entry(type: T.feed, time: DateTime(2026, 10, 1, 8), data: {'method': 'bottle', 'ml': 100}));
      await a.addBaby(_baby('Bình'));
      a.addEntry(Entry(type: T.sleep, time: DateTime(2026, 10, 2, 9), end: DateTime(2026, 10, 2, 10)));
      a.addGoal(FundGoal(name: 'Học phí', target: 100000000));
      await a.flushNow();
      final file = jsonDecode(jsonEncode(await a.exportAll())) as Map<String, dynamic>;

      final b = await _fresh(await KV.memory()); // máy khác, trống
      await b.importAll(file);
      await b.flushNow();
      expect(b.babies.map((x) => x.name), unorderedEquals(['An', 'Bình']));
      expect(b.baby!.name, 'Bình');
      expect(b.entries.single.type, T.sleep);
      expect(b.goals.single.name, 'Học phí');
      await b.switchBaby(b.babies.firstWhere((x) => x.name == 'An').id);
      expect(b.entries.single.type, T.feed, reason: 'bé An khôi phục đủ dữ liệu');
    });

    test('khôi phục tệp cũ (một bé, mục tiêu cũ) vẫn dùng được', () async {
      final a = await _fresh(await KV.memory());
      final file = <String, dynamic>{
        'app': 'GinBaby',
        'version': 2,
        'baby': _baby('Cũ').toJson(),
        'entries': [Entry(type: T.note, time: DateTime(2026, 9, 1), data: {'text': 'x'}).toJson()],
        'goal': {'n': 'Du học', 't': 500000000},
      };
      await a.importAll(file);
      expect(a.baby!.name, 'Cũ');
      expect(a.babies.single.name, 'Cũ');
      expect(a.goals.single.name, 'Du học');
      expect(a.goals.single.target, 500000000);
    });

    test('xoá toàn bộ xoá mọi bé', () async {
      final a = await _fresh(await KV.memory());
      a.saveBaby(_baby('An'));
      await a.addBaby(_baby('Bình'));
      await a.wipe();
      expect(a.babies, isEmpty);
      expect(a.baby, isNull);
      expect(a.activeId, 'main');
    });
  });

  group('nhiều mục tiêu quỹ', () {
    test('thêm, sửa, xoá nhiều mục tiêu và lưu qua khởi động lại', () async {
      final kv = await KV.memory();
      var a = await _fresh(kv);
      a.saveBaby(_baby('An'));
      a.addGoal(FundGoal(name: 'Học phí lớp 1', target: 120000000));
      a.addGoal(FundGoal(name: 'Du học', target: 800000000));
      expect(a.goals, hasLength(2));
      final g = a.goals.last;
      g.target = 900000000;
      a.updateGoal(g);
      await a.flushNow();

      a = await _fresh(kv);
      expect(a.goals.map((x) => x.name), ['Học phí lớp 1', 'Du học']);
      expect(a.goals.last.target, 900000000);
      a.removeGoal(a.goals.first.id);
      expect(a.goals.map((x) => x.name), ['Du học']);
    });

    test('mục tiêu mỗi bé riêng', () async {
      final a = await _fresh(await KV.memory());
      a.saveBaby(_baby('An'));
      a.addGoal(FundGoal(name: 'Của An', target: 1000000));
      await a.addBaby(_baby('Bình'));
      expect(a.goals, isEmpty);
      a.addGoal(FundGoal(name: 'Của Bình', target: 2000000));
      await a.switchBaby('main');
      expect(a.goals.single.name, 'Của An');
    });

    test('dữ liệu cũ có một mục tiêu ở khoá cũ được nạp thành danh sách', () async {
      final kv = await KV.memory();
      await kv.set('gb1.baby', jsonEncode(_baby('Cũ').toJson()));
      await kv.set('gb1.goal', jsonEncode({'n': 'Học phí lớp 1', 't': 120000000}));
      final a = await _fresh(kv);
      expect(a.goals.single.name, 'Học phí lớp 1');
      expect(a.goals.single.target, 120000000);
    });
  });
}
