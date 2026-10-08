import 'package:sembast/sembast.dart';

import 'kv_open_io.dart' if (dart.library.js_interop) 'kv_open_web.dart';

/// Kho khoá-giá trị bền vững: IndexedDB trên web (dung lượng lớn), tệp cơ sở dữ liệu trên điện thoại.
class KV {
  KV._(this._db);
  final Database _db;
  static final _store = StoreRef<String, String>('kv');

  static Future<KV> open() async => KV._(await openDatabaseFile('ginbaby'));

  Future<String?> get(String key) => _store.record(key).get(_db);

  Future<void> set(String key, String value) => _store.record(key).put(_db, value);

  Future<void> remove(String key) => _store.record(key).delete(_db);

  Future<List<String>> keys([String prefix = '']) async {
    final all = await _store.findKeys(_db);
    return prefix.isEmpty ? all : all.where((k) => k.startsWith(prefix)).toList();
  }

  Future<void> setMany(Map<String, String> values) => _db.transaction((txn) async {
        for (final e in values.entries) {
          await _store.record(e.key).put(txn, e.value);
        }
      });
}
