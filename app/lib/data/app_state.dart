import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/kv.dart';
import '../core/theme.dart';
import '../domain/age.dart';
import '../domain/feeding_ref.dart';
import 'models.dart';

/// Toàn bộ trạng thái và dữ liệu của app (lưu cục bộ trên máy bằng JSON).
class AppState extends ChangeNotifier {
  KV? _kv;
  Timer? _debounce;
  final Set<String> _dirty = {};

  Baby? baby;
  final List<Entry> entries = [];
  final List<FridgeItem> fridge = [];
  final List<MoneyTag> tags = [];
  final List<Tx> txs = [];
  final List<FundItem> funds = [];
  final List<FundGoal> goals = [];

  /// Mục tiêu quỹ đầu tiên (tương thích bản cũ chỉ có một mục tiêu).
  FundGoal get goal => goals.firstOrNull ?? FundGoal(id: '_none');
  set goal(FundGoal g) {
    goals
      ..clear()
      ..add(g);
  }

  // Nhiều bé: mỗi bé có kho dữ liệu riêng (bé đầu tiên 'main' giữ nguyên khoá cũ, bé thêm dùng tiền tố b.<id>.).
  final List<BabyRef> babies = [];
  String activeId = 'main';
  final List<Measurement> measurements = [];
  final Map<String, VaxRecord> vax = {};
  final List<Appointment> appts = [];
  final List<MoodEntry> moods = [];
  final List<EpdsResult> epds = [];
  final Map<String, DateTime> milestones = {};
  final Map<String, MilestoneMemo> memos = {}; // nhật ký mốc: kỷ niệm kèm ảnh, ghi chú
  final Map<String, DateTime> teeth = {};
  final Map<String, int> fussyDays = {}; // 'yyyy-m-d' -> 1 (quấy)
  final List<Member> members = [];
  Settings settings = Settings();

  bool ready = false;

  static const _k = 'gb1.';

  /// Các khoá dữ liệu riêng của từng bé; còn lại (cài đặt, thành viên, nhãn thu chi, tâm trạng mẹ, EPDS) dùng chung.
  static const _scoped = {'baby', 'entries', 'fridge', 'tx', 'funds', 'goals', 'meas', 'vax', 'appts', 'miles', 'memos', 'teeth', 'fussy'};
  static String _pre(String id) => id == 'main' ? '' : 'b.$id.';
  String _key(String k, [String? id]) => _scoped.contains(k) ? '$_k${_pre(id ?? activeId)}$k' : '$_k$k';

  Future<Map<String, dynamic>?> _obj(String k) async {
    final s = await _kv?.get(_key(k));
    if (s == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(s) as Map);
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _list(String k) async {
    final s = await _kv?.get(_key(k));
    if (s == null) return [];
    try {
      return (jsonDecode(s) as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Di chuyển dữ liệu cũ (localStorage/SharedPreferences) sang kho mới một lần.
  Future<void> _migrateFromPrefs(KV kv) async {
    if (await kv.get('${_k}migrated') != null) return;
    try {
      final p = await SharedPreferences.getInstance();
      final old = p.getKeys().where((k) => k.startsWith(_k)).toList();
      final batch = <String, String>{};
      for (final k in old) {
        final v = p.getString(k);
        if (v != null) batch[k] = v;
      }
      if (batch.isNotEmpty) await kv.setMany(batch);
      await kv.set('${_k}migrated', '1');
      for (final k in old) {
        await p.remove(k);
      }
    } catch (_) {
      await kv.set('${_k}migrated', '1');
    }
  }

  Future<void> init({KV? kv}) async {
    final store = kv ?? await KV.open();
    _kv = store;
    await _migrateFromPrefs(store);

    // danh sách bé và bé đang xem (khoá chung)
    babies
      ..clear()
      ..addAll((await _list('babies')).map(BabyRef.fromJson));
    activeId = await store.get('${_k}active') ?? 'main';
    if (!babies.any((b) => b.id == activeId)) activeId = babies.isEmpty ? 'main' : babies.first.id;
    await _loadScoped();
    if (baby != null && !babies.any((b) => b.id == activeId)) babies.add(BabyRef(id: activeId, name: baby!.name, dob: baby!.dob, girl: baby!.sex == Sex.girl));
    final cur = babies.where((b) => b.id == activeId).firstOrNull;
    if (cur != null && baby != null && cur.dob == null) {
      cur
        ..dob = baby!.dob
        ..girl = baby!.sex == Sex.girl;
    }

    tags.addAll((await _list('tags')).map(MoneyTag.fromJson));
    moods.addAll((await _list('moods')).map(MoodEntry.fromJson));
    epds.addAll((await _list('epds')).map(EpdsResult.fromJson));
    members.addAll((await _list('members')).map(Member.fromJson));
    final s = await _obj('settings');
    if (s != null) settings = Settings.fromJson(s);
    glassLite.value = settings.lite;
    if (tags.isEmpty) _seedTags();
    if (members.isEmpty) members.add(Member(name: settings.ownerName, role: 'owner'));
    ready = true;
    notifyListeners();
    unawaited(_loadPhotos());
  }

  /// Nạp dữ liệu của bé đang xem (xoá dữ liệu bé trước trong bộ nhớ).
  Future<void> _loadScoped() async {
    baby = null;
    entries.clear();
    fridge.clear();
    txs.clear();
    funds.clear();
    goals.clear();
    measurements.clear();
    vax.clear();
    appts.clear();
    milestones.clear();
    memos.clear();
    teeth.clear();
    fussyDays.clear();
    final b = await _obj('baby');
    if (b != null) baby = Baby.fromJson(b);
    entries.addAll((await _list('entries')).map(Entry.fromJson));
    fridge.addAll((await _list('fridge')).map(FridgeItem.fromJson));
    txs.addAll((await _list('tx')).map(Tx.fromJson));
    funds.addAll((await _list('funds')).map(FundItem.fromJson));
    goals.addAll((await _list('goals')).map(FundGoal.fromJson));
    if (goals.isEmpty && activeId == 'main') {
      // bản cũ chỉ có một mục tiêu lưu ở khoá 'goal'
      final g = await _kv?.get('${_k}goal');
      if (g != null) {
        try {
          final fg = FundGoal.fromJson(Map<String, dynamic>.from(jsonDecode(g) as Map));
          if (fg.target > 0 || fg.name.isNotEmpty) goals.add(fg);
        } catch (_) {}
      }
    }
    measurements.addAll((await _list('meas')).map(Measurement.fromJson));
    final v = await _obj('vax');
    if (v != null) {
      v.forEach((k, e) => vax[k] = VaxRecord.fromJson(Map<String, dynamic>.from(e as Map)));
    }
    appts.addAll((await _list('appts')).map(Appointment.fromJson));
    final ms = await _obj('miles');
    if (ms != null) ms.forEach((k, e) => milestones[k] = dtFrom(e));
    final mm = await _obj('memos');
    if (mm != null) mm.forEach((k, e) => memos[k] = MilestoneMemo.fromJson(Map<String, dynamic>.from(e as Map)));
    final th = await _obj('teeth');
    if (th != null) th.forEach((k, e) => teeth[k] = dtFrom(e));
    final fz = await _obj('fussy');
    if (fz != null) fz.forEach((k, e) => fussyDays[k] = (e as num).toInt());
  }

  /// Nạp ảnh sau khi giao diện đã hiện (không chặn lúc mở app).
  Future<void> _loadPhotos() async {
    final kv = _kv;
    if (kv == null) return;
    final ids = await kv.keys('${_k}ph.');
    var any = false;
    for (final key in ids) {
      final id = key.substring('${_k}ph.'.length);
      if (_photoCache.containsKey(id)) continue;
      final s = await kv.get(key);
      if (s != null) {
        _photoCache[id] = base64Decode(s);
        any = true;
      }
    }
    if (any) notifyListeners();
  }

  void _seedTags() {
    final defs = <(String, String, int, bool)>[
      ('bim', 'Bỉm/tã', 0, false),
      ('sua', 'Sữa', 1, false),
      ('thuoc', 'Thuốc', 2, false),
      ('kham', 'Khám bệnh', 3, false),
      ('tiem', 'Tiêm chủng', 3, false),
      ('quanao', 'Quần áo', 4, false),
      ('dochoi', 'Đồ chơi', 5, false),
      ('andam', 'Ăn dặm', 0, false),
      ('vesinh', 'Vệ sinh/tắm', 1, false),
      ('hocphi', 'Học phí', 2, false),
      ('dodung', 'Đồ dùng', 4, false),
      ('mung', 'Tiền mừng', 4, true),
      ('lixi', 'Lì xì', 5, true),
      ('qua', 'Quà', 0, true),
      ('khacthu', 'Khác (thu)', 1, true),
    ];
    for (final d in defs) {
      tags.add(MoneyTag(id: d.$1, label: d.$2, colorIdx: d.$3, income: d.$4));
    }
  }

  // ---------- lưu ----------
  void changed(String key) {
    _dirty.add(key);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _flush);
    notifyListeners();
  }

  Future<void> _writing = Future.value();

  void _flush() {
    final kv = _kv;
    if (kv == null) return;
    final batch = <String, String>{};
    final removes = <String>[];
    final keys = _dirty.toList();
    _dirty.clear();
    for (final k in keys) {
      String? v;
      switch (k) {
        case 'baby':
          v = baby == null ? null : jsonEncode(baby!.toJson());
        case 'entries':
          v = jsonEncode(entries.map((e) => e.toJson()).toList());
        case 'fridge':
          v = jsonEncode(fridge.map((e) => e.toJson()).toList());
        case 'tags':
          v = jsonEncode(tags.map((e) => e.toJson()).toList());
        case 'tx':
          v = jsonEncode(txs.map((e) => e.toJson()).toList());
        case 'funds':
          v = jsonEncode(funds.map((e) => e.toJson()).toList());
        case 'goals':
          v = jsonEncode(goals.map((e) => e.toJson()).toList());
        case 'babies':
          v = jsonEncode(babies.map((e) => e.toJson()).toList());
        case 'meas':
          v = jsonEncode(measurements.map((e) => e.toJson()).toList());
        case 'vax':
          v = jsonEncode(vax.map((k, e) => MapEntry(k, e.toJson())));
        case 'appts':
          v = jsonEncode(appts.map((e) => e.toJson()).toList());
        case 'moods':
          v = jsonEncode(moods.map((e) => e.toJson()).toList());
        case 'epds':
          v = jsonEncode(epds.map((e) => e.toJson()).toList());
        case 'miles':
          v = jsonEncode(milestones.map((k, e) => MapEntry(k, msOf(e))));
        case 'memos':
          v = jsonEncode(memos.map((k, e) => MapEntry(k, e.toJson())));
        case 'teeth':
          v = jsonEncode(teeth.map((k, e) => MapEntry(k, msOf(e))));
        case 'fussy':
          v = jsonEncode(fussyDays);
        case 'members':
          v = jsonEncode(members.map((e) => e.toJson()).toList());
        case 'settings':
          v = jsonEncode(settings.toJson());
      }
      if (v == null) {
        removes.add(_key(k));
      } else {
        batch[_key(k)] = v;
      }
    }
    _writing = _writing.then((_) async {
      try {
        if (batch.isNotEmpty) await kv.setMany(batch);
        for (final r in removes) {
          await kv.remove(r);
        }
      } catch (_) {}
    });
  }

  Future<void> flushNow() async {
    _debounce?.cancel();
    _flush();
    await _writing;
  }

  // ---------- ảnh ----------
  final Map<String, Uint8List> _photoCache = {};

  Future<String> putPhoto(Uint8List bytes) async {
    final id = uid();
    _photoCache[id] = bytes;
    await _kv?.set('${_k}ph.$id', base64Encode(bytes));
    return id;
  }

  Uint8List? photo(String id) => _photoCache[id];

  Future<void> deletePhoto(String id) async {
    _photoCache.remove(id);
    await _kv?.remove('${_k}ph.$id');
  }

  /// Các id ảnh đang được dùng (nhật ký tã, thu chi, quỹ).
  Set<String> get usedPhotoIds => {
        for (final e in entries)
          if (e.data['photo'] is String) e.data['photo'] as String,
        for (final t in txs) ...t.photos,
        for (final f in funds) ...f.photos,
        for (final m in memos.values)
          if (m.photo != null) m.photo!,
        if (settings.heroPhoto != null) settings.heroPhoto!,
        if (baby?.photo != null) baby!.photo!,
      };

  // ---------- hồ sơ bé ----------
  bool get hasBaby => baby != null;
  Age get age => Age(baby!);

  void saveBaby(Baby b) {
    baby = b;
    final r = babies.where((x) => x.id == activeId).firstOrNull;
    if (r == null) {
      babies.add(BabyRef(id: activeId, name: b.name, dob: b.dob, girl: b.sex == Sex.girl));
    } else {
      r
        ..name = b.name
        ..dob = b.dob
        ..girl = b.sex == Sex.girl;
    }
    changed('baby');
    changed('babies');
  }

  /// Chuyển sang xem một bé khác (lưu bé hiện tại trước, rồi nạp dữ liệu bé kia).
  Future<void> switchBaby(String id) async {
    if (id == activeId || !babies.any((b) => b.id == id)) return;
    await flushNow();
    activeId = id;
    await _kv?.set('${_k}active', id);
    await _loadScoped();
    notifyListeners();
  }

  /// Thêm một bé mới (dữ liệu riêng, trống) và chuyển sang xem bé đó.
  Future<void> addBaby(Baby b) async {
    await flushNow();
    final id = uid();
    babies.add(BabyRef(id: id, name: b.name, dob: b.dob, girl: b.sex == Sex.girl));
    changed('babies');
    await flushNow();
    activeId = id;
    await _kv?.set('${_k}active', id);
    await _loadScoped();
    saveBaby(b);
  }

  /// Xoá hẳn một bé và dữ liệu riêng của bé đó (không xoá được khi chỉ còn một bé).
  Future<void> removeBaby(String id) async {
    if (babies.length <= 1 || !babies.any((b) => b.id == id)) return;
    await flushNow();
    final kv = _kv;
    if (kv != null) {
      for (final k in _scoped) {
        await kv.remove(_key(k, id));
      }
    }
    babies.removeWhere((b) => b.id == id);
    changed('babies');
    await flushNow();
    if (id == activeId) {
      activeId = babies.first.id;
      await kv?.set('${_k}active', activeId);
      await _loadScoped();
      notifyListeners();
    }
  }

  double get weightKg {
    if (measurements.isNotEmpty) {
      final w = measurements.where((m) => m.weightKg != null).toList()..sort((a, b) => b.date.compareTo(a.date));
      if (w.isNotEmpty) return w.first.weightKg!;
    }
    return baby?.birthWeightKg ?? 3.5;
  }

  // ---------- nhật ký ----------
  void addEntry(Entry e) {
    entries.add(e);
    entries.sort((a, b) => b.time.compareTo(a.time));
    changed('entries');
  }

  void updateEntry(Entry e) {
    entries.sort((a, b) => b.time.compareTo(a.time));
    changed('entries');
  }

  void removeEntry(String id) {
    final i = entries.indexWhere((e) => e.id == id);
    if (i < 0) return;
    final e = entries[i];
    // hoàn lại sữa trong tủ nếu có
    if (e.type == T.feed && e.str('fridgeId').isNotEmpty) {
      final f = fridge.where((x) => x.id == e.str('fridgeId')).firstOrNull;
      if (f != null) {
        f.usedMl = math.max(0, f.usedMl - e.ml - (e.data['waste'] as num? ?? 0).toInt());
        changed('fridge');
      }
    }
    entries.removeAt(i);
    changed('entries');
    // xoá luôn ảnh đính kèm nếu không còn bản ghi nào dùng (không để ảnh mồ côi trong bộ nhớ)
    final ph = e.data['photo'];
    if (ph is String && !usedPhotoIds.contains(ph)) deletePhoto(ph);
  }

  Iterable<Entry> ofType(String type) => entries.where((e) => e.type == type);

  static DateTime dayStart(DateTime d) => DateTime(d.year, d.month, d.day);

  List<Entry> entriesOn(DateTime day, {String? type}) {
    final s = dayStart(day);
    final e = s.add(const Duration(days: 1));
    return entries.where((x) => !x.time.isBefore(s) && x.time.isBefore(e) && (type == null || x.type == type)).toList();
  }

  List<Entry> entriesBetween(DateTime from, DateTime to, {String? type}) =>
      entries.where((x) => !x.time.isBefore(from) && x.time.isBefore(to) && (type == null || x.type == type)).toList();

  // ---------- ngủ ----------
  Entry? get activeSleep => entries.where((e) => e.type == T.sleep && e.end == null).firstOrNull;

  void startSleep([DateTime? at]) {
    if (activeSleep != null) return;
    addEntry(Entry(type: T.sleep, time: at ?? DateTime.now()));
  }

  Entry? endSleep([DateTime? at]) {
    final s = activeSleep;
    if (s == null) return null;
    final end = at ?? DateTime.now();
    s.end = end.isBefore(s.time) ? s.time : end;
    changed('entries');
    return s;
  }

  /// Lúc bé dậy gần nhất (kết thúc cữ ngủ gần nhất).
  DateTime? get lastWake {
    final now = DateTime.now();
    final done = entries.where((e) => e.type == T.sleep && e.end != null && !e.end!.isAfter(now)).toList();
    if (done.isEmpty) return null;
    done.sort((a, b) => b.end!.compareTo(a.end!));
    return done.first.end;
  }

  Duration sleepOn(DateTime day) {
    final s = dayStart(day);
    final e = s.add(const Duration(days: 1));
    var total = Duration.zero;
    final now = DateTime.now();
    for (final x in entries) {
      if (x.type != T.sleep) continue;
      final xs = x.time;
      final xe = x.end ?? now;
      final a = xs.isBefore(s) ? s : xs;
      final b = xe.isAfter(e) ? e : xe;
      if (b.isAfter(a)) total += b.difference(a);
    }
    return total;
  }

  // ---------- bú ----------
  Entry? get lastFeed => entries.where((e) => e.type == T.feed).firstOrNull;

  /// Ghi bú bình. source: mom | formula. Nếu lấy từ tủ: truyền fridgeId.
  Entry addBottle({required int ml, required String source, String? fridgeId, DateTime? time}) {
    var waste = 0;
    if (fridgeId != null) {
      final f = fridge.where((x) => x.id == fridgeId).firstOrNull;
      if (f != null) {
        final take = math.min(ml, f.left);
        f.usedMl += take;
        // phần còn lại trong bình sau khi bé bú: đổ bỏ (sữa đã tiếp xúc nước bọt)
        waste = math.max(0, f.left);
        f.usedMl = f.ml;
        changed('fridge');
      }
    }
    final e = Entry(type: T.feed, time: time ?? DateTime.now(), data: {
      'method': 'bottle',
      'source': source,
      'ml': ml,
      if (fridgeId != null) 'fridgeId': fridgeId,
      if (waste > 0) 'waste': waste,
    });
    addEntry(e);
    return e;
  }

  Entry addBreast({required DateTime start, required DateTime end, required String side, int? mlEst}) {
    final minutes = math.max(1, end.difference(start).inMinutes);
    final est = mlEst ?? FeedingRef.breastEstimate(age.adjDays, minutes);
    final e = Entry(type: T.feed, time: start, end: end, data: {
      'method': 'breast',
      'source': 'mom',
      'ml': est,
      'est': true,
      'min': minutes,
      'side': side,
    });
    addEntry(e);
    return e;
  }

  /// Tổng ml trong ngày: (bình, bú mẹ ước tính, tổng, trong đó sữa mẹ/công thức)
  ({int bottleMom, int bottleFormula, int breastEst, int total, int count}) feedTotals(DateTime day) {
    var bm = 0, bf = 0, br = 0, c = 0;
    for (final e in entriesOn(day, type: T.feed)) {
      c++;
      if (e.str('method') == 'breast') {
        br += e.ml;
      } else if (e.str('source') == 'formula') {
        bf += e.ml;
      } else {
        bm += e.ml;
      }
    }
    return (bottleMom: bm, bottleFormula: bf, breastEst: br, total: bm + bf + br, count: c);
  }

  // ---------- hút sữa ----------
  Entry addPump({required int mlL, required int mlR, required int minutes, DateTime? time, DateTime? end, String store = 'none', int bottles = 1, String note = ''}) {
    final t = time ?? DateTime.now();
    final e = Entry(type: T.pump, time: t, end: end, data: {'l': mlL, 'r': mlR, 'ml': mlL + mlR, 'min': minutes, 'store': store, if (note.isNotEmpty) 'note': note});
    addEntry(e);
    if (store != 'none' && mlL + mlR > 0) {
      final total = mlL + mlR;
      final n = math.max(1, bottles);
      final each = (total / n).floor();
      for (var i = 0; i < n; i++) {
        final ml = i == n - 1 ? total - each * (n - 1) : each;
        fridge.add(FridgeItem(ml: ml, storedAt: t, freezer: store == 'freezer'));
      }
      changed('fridge');
    }
    return e;
  }

  /// Trung bình các cữ hút gần nhất (để so với chính mẹ).
  double? pumpBaseline({int last = 10, String? excludeId}) {
    final l = entries.where((e) => e.type == T.pump && e.id != excludeId && e.ml > 0).take(last).toList();
    if (l.length < 3) return null;
    return l.map((e) => e.ml).reduce((a, b) => a + b) / l.length;
  }

  int pumpedOn(DateTime day) => entriesOn(day, type: T.pump).fold(0, (a, e) => a + e.ml);
  int pumpSessionsOn(DateTime day) => entriesOn(day, type: T.pump).length;

  List<FridgeItem> get fridgeActive {
    final l = fridge.where((f) => !f.discarded && f.left > 0).toList();
    l.sort((a, b) => a.expires.compareTo(b.expires));
    return l;
  }

  int get fridgeTotalMl => fridgeActive.where((f) => f.expires.isAfter(DateTime.now())).fold(0, (a, f) => a + f.left);

  void fridgeAdd(FridgeItem f) {
    fridge.add(f);
    changed('fridge');
  }

  void fridgeDiscard(String id) {
    final f = fridge.where((x) => x.id == id).firstOrNull;
    if (f == null) return;
    f.discarded = true;
    changed('fridge');
  }

  // ---------- tã ----------
  int diaperCount(DateTime day, {bool? wet, bool? poop}) {
    var c = 0;
    for (final e in entriesOn(day, type: T.diaper)) {
      final k = e.str('kind');
      if (wet == true && k == 'poop') continue;
      if (poop == true && k == 'wet') continue;
      c++;
    }
    return c;
  }

  // ---------- thu chi ----------
  MoneyTag? tagById(String id) => tags.where((t) => t.id == id).firstOrNull;

  void addTx(Tx t) {
    txs.add(t);
    txs.sort((a, b) => b.time.compareTo(a.time));
    changed('tx');
  }

  void updateTx(Tx t) {
    txs.sort((a, b) => b.time.compareTo(a.time));
    changed('tx');
  }

  void removeTx(String id) {
    final i = txs.indexWhere((t) => t.id == id);
    if (i < 0) return;
    for (final p in txs[i].photos) {
      deletePhoto(p);
    }
    txs.removeAt(i);
    changed('tx');
  }

  void addTag(MoneyTag t) {
    tags.add(t);
    changed('tags');
  }

  void removeTag(String id) {
    tags.removeWhere((t) => t.id == id);
    for (final x in txs) {
      x.tags.remove(id);
    }
    changed('tags');
    changed('tx');
  }

  // ---------- quỹ ----------
  int get fundTotal => funds.fold(0, (a, f) => a + f.value);

  void addFund(FundItem f) {
    funds.add(f);
    changed('funds');
  }

  void removeFund(String id) {
    final gone = funds.where((f) => f.id == id).toList();
    funds.removeWhere((f) => f.id == id);
    changed('funds');
    // xoá ảnh của khoản quỹ đã bị xoá (nếu không còn nơi nào dùng)
    for (final f in gone) {
      for (final p in f.photos) {
        if (!usedPhotoIds.contains(p)) deletePhoto(p);
      }
    }
  }

  void fundChanged() => changed('funds');

  void setGoal(FundGoal g) {
    if (goals.isEmpty) {
      goals.add(g);
    } else {
      goals[0] = g;
    }
    changed('goals');
  }

  void addGoal(FundGoal g) {
    goals.add(g);
    changed('goals');
  }

  void updateGoal(FundGoal g) {
    final i = goals.indexWhere((x) => x.id == g.id);
    if (i >= 0) goals[i] = g;
    changed('goals');
  }

  void removeGoal(String id) {
    goals.removeWhere((g) => g.id == id);
    changed('goals');
  }

  // ---------- sức khoẻ ----------
  /// Đặt cân nặng hiện tại: cập nhật lần cân hôm nay nếu có, không thì thêm một lần cân mới.
  void setCurrentWeight(double kg) {
    final now = DateTime.now();
    final today = measurements.where((m) => m.weightKg != null && dayKey(m.date) == dayKey(now)).firstOrNull;
    if (today != null) {
      today.weightKg = kg;
      changed('meas');
    } else {
      addMeasurement(Measurement(date: now, weightKg: kg));
    }
  }

  void addMeasurement(Measurement m) {
    measurements.add(m);
    measurements.sort((a, b) => b.date.compareTo(a.date));
    changed('meas');
  }

  void removeMeasurement(String id) {
    measurements.removeWhere((m) => m.id == id);
    changed('meas');
  }

  void setVax(String key, VaxRecord? r) {
    if (r == null) {
      vax.remove(key);
    } else {
      vax[key] = r;
    }
    changed('vax');
  }

  void addAppt(Appointment a) {
    appts.add(a);
    appts.sort((a, b) => a.time.compareTo(b.time));
    changed('appts');
  }

  void apptChanged() => changed('appts');

  void removeAppt(String id) {
    appts.removeWhere((a) => a.id == id);
    changed('appts');
  }

  void addMood(MoodEntry m) {
    moods.insert(0, m);
    changed('moods');
  }

  void addEpds(EpdsResult r) {
    epds.insert(0, r);
    changed('epds');
  }

  void toggleMilestone(String id) {
    if (milestones.containsKey(id)) {
      milestones.remove(id);
    } else {
      milestones[id] = DateTime.now();
    }
    changed('miles');
  }

  /// Lưu kỷ niệm của một mốc. Mốc CDC (m2_0…) cũng được đánh dấu đã đạt vào ngày đó.
  void saveMemo(MilestoneMemo m) {
    final old = memos[m.key];
    if (old?.photo != null && old!.photo != m.photo) deletePhoto(old.photo!);
    memos[m.key] = m;
    if (RegExp(r'^m\d+_\d+$').hasMatch(m.key)) {
      milestones[m.key] = m.date;
      changed('miles');
    }
    changed('memos');
  }

  void removeMemo(String key) {
    final old = memos.remove(key);
    if (old?.photo != null) deletePhoto(old!.photo!);
    changed('memos');
  }

  void toggleTooth(String id, [DateTime? at]) {
    if (teeth.containsKey(id)) {
      teeth.remove(id);
    } else {
      teeth[id] = at ?? DateTime.now();
    }
    changed('teeth');
  }

  static String dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  bool isFussy(DateTime d) => fussyDays.containsKey(dayKey(d));

  void toggleFussy(DateTime d) {
    final k = dayKey(d);
    if (fussyDays.containsKey(k)) {
      fussyDays.remove(k);
    } else {
      fussyDays[k] = 1;
    }
    changed('fussy');
  }

  // ---------- gia đình / cài đặt ----------
  void addMember(Member m) {
    members.add(m);
    changed('members');
  }

  void removeMember(Member m) {
    members.remove(m);
    changed('members');
  }

  void membersChanged() => changed('members');

  void settingsChanged() {
    glassLite.value = settings.lite;
    changed('settings');
  }

  // ---------- sao lưu ----------
  /// Xuất toàn bộ dữ liệu, **kèm ảnh** (base64) đang được dùng.
  Future<Map<String, dynamic>> exportAll({bool withPhotos = true}) async {
    final m = _exportData();
    // các bé khác (dữ liệu riêng đọc thẳng từ kho)
    final others = <Map<String, dynamic>>[];
    final kv = _kv;
    if (kv != null) {
      for (final r in babies) {
        if (r.id == activeId) continue;
        final data = <String, dynamic>{};
        for (final k in _scoped) {
          final raw = await kv.get(_key(k, r.id));
          if (raw != null) data[k] = jsonDecode(raw);
        }
        others.add({'id': r.id, 'n': r.name, 'data': data});
      }
    }
    if (others.isNotEmpty) m['otherBabies'] = others;
    if (withPhotos) {
      final photos = <String, String>{};
      // nhiều bé: ảnh của các bé khác nằm trong bộ nhớ ảnh chung nên xuất cả
      for (final id in others.isEmpty ? usedPhotoIds : _photoCache.keys) {
        final b = _photoCache[id];
        if (b != null) photos[id] = base64Encode(b);
      }
      m['photos'] = photos;
    }
    return m;
  }

  Map<String, dynamic> _exportData() => {
        'app': 'GinBaby',
        'version': 2,
        'members': members.map((e) => e.toJson()).toList(),
        'exportedAt': DateTime.now().toIso8601String(),
        'baby': baby?.toJson(),
        'entries': entries.map((e) => e.toJson()).toList(),
        'fridge': fridge.map((e) => e.toJson()).toList(),
        'tags': tags.map((e) => e.toJson()).toList(),
        'tx': txs.map((e) => e.toJson()).toList(),
        'funds': funds.map((e) => e.toJson()).toList(),
        'goal': goal.toJson(),
        'goals': goals.map((e) => e.toJson()).toList(),
        'activeId': activeId,
        'babies': babies.map((e) => e.toJson()).toList(),
        'meas': measurements.map((e) => e.toJson()).toList(),
        'vax': vax.map((k, e) => MapEntry(k, e.toJson())),
        'appts': appts.map((e) => e.toJson()).toList(),
        'moods': moods.map((e) => e.toJson()).toList(),
        'epds': epds.map((e) => e.toJson()).toList(),
        'miles': milestones.map((k, e) => MapEntry(k, msOf(e))),
        'memos': memos.map((k, e) => MapEntry(k, e.toJson())),
        'teeth': teeth.map((k, e) => MapEntry(k, msOf(e))),
        'fussy': fussyDays,
        'settings': settings.toJson(),
      };

  Future<void> importAll(Map<String, dynamic> j) async {
    if (j['app'] != 'GinBaby') throw const FormatException('Không phải tập sao lưu GinBaby');
    List<Map<String, dynamic>> l(String k) => ((j[k] as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    // khôi phục là thay thế toàn bộ: xoá dữ liệu mọi bé hiện có (trừ ảnh) rồi nạp từ tệp
    final kv0 = _kv;
    if (kv0 != null) {
      for (final key in await kv0.keys(_k)) {
        if (key != '${_k}migrated' && !key.startsWith('${_k}ph.')) await kv0.remove(key);
      }
    }
    activeId = (j['activeId'] as String?) ?? 'main';
    babies
      ..clear()
      ..addAll(l('babies').map(BabyRef.fromJson));
    baby = j['baby'] == null ? null : Baby.fromJson(Map<String, dynamic>.from(j['baby'] as Map));
    if (baby != null && !babies.any((b) => b.id == activeId)) babies.add(BabyRef(id: activeId, name: baby!.name));
    entries
      ..clear()
      ..addAll(l('entries').map(Entry.fromJson));
    fridge
      ..clear()
      ..addAll(l('fridge').map(FridgeItem.fromJson));
    tags
      ..clear()
      ..addAll(l('tags').map(MoneyTag.fromJson));
    if (tags.isEmpty) _seedTags();
    txs
      ..clear()
      ..addAll(l('tx').map(Tx.fromJson));
    funds
      ..clear()
      ..addAll(l('funds').map(FundItem.fromJson));
    goals.clear();
    if (j['goals'] != null) {
      goals.addAll(l('goals').map(FundGoal.fromJson));
    } else if (j['goal'] != null) {
      final g = FundGoal.fromJson(Map<String, dynamic>.from(j['goal'] as Map));
      if (g.target > 0 || g.name.isNotEmpty) goals.add(g);
    }
    measurements
      ..clear()
      ..addAll(l('meas').map(Measurement.fromJson));
    vax.clear();
    (j['vax'] as Map? ?? {}).forEach((k, e) => vax['$k'] = VaxRecord.fromJson(Map<String, dynamic>.from(e as Map)));
    appts
      ..clear()
      ..addAll(l('appts').map(Appointment.fromJson));
    moods
      ..clear()
      ..addAll(l('moods').map(MoodEntry.fromJson));
    epds
      ..clear()
      ..addAll(l('epds').map(EpdsResult.fromJson));
    milestones.clear();
    (j['miles'] as Map? ?? {}).forEach((k, e) => milestones['$k'] = dtFrom(e));
    memos.clear();
    (j['memos'] as Map? ?? {}).forEach((k, e) => memos['$k'] = MilestoneMemo.fromJson(Map<String, dynamic>.from(e as Map)));
    teeth.clear();
    (j['teeth'] as Map? ?? {}).forEach((k, e) => teeth['$k'] = dtFrom(e));
    fussyDays.clear();
    (j['fussy'] as Map? ?? {}).forEach((k, e) => fussyDays['$k'] = (e as num).toInt());
    if (j['settings'] != null) settings = Settings.fromJson(Map<String, dynamic>.from(j['settings'] as Map));
    members
      ..clear()
      ..addAll(l('members').map(Member.fromJson));
    if (members.isEmpty) members.add(Member(name: settings.ownerName, role: 'owner'));
    glassLite.value = settings.lite;
    // khôi phục ảnh
    final ph = j['photos'];
    if (ph is Map) {
      final batch = <String, String>{};
      ph.forEach((id, v) {
        final s = '$v';
        _photoCache['$id'] = base64Decode(s);
        batch['${_k}ph.$id'] = s;
      });
      if (batch.isNotEmpty) await _kv?.setMany(batch);
    }
    for (final k in ['baby', 'babies', 'entries', 'fridge', 'tags', 'tx', 'funds', 'goals', 'meas', 'vax', 'appts', 'moods', 'epds', 'miles', 'memos', 'teeth', 'fussy', 'members', 'settings']) {
      _dirty.add(k);
    }
    // các bé khác trong tệp: ghi thẳng vào kho với khoá riêng
    final others = j['otherBabies'];
    if (others is List && _kv != null) {
      final batch = <String, String>{};
      for (final o in others) {
        final m = Map<String, dynamic>.from(o as Map);
        final id = '${m['id']}';
        if (!babies.any((b) => b.id == id)) babies.add(BabyRef(id: id, name: (m['n'] as String?) ?? 'Bé'));
        final data = Map<String, dynamic>.from((m['data'] as Map?) ?? const {});
        data.forEach((k, v) {
          if (_scoped.contains(k)) batch[_key(k, id)] = jsonEncode(v);
        });
      }
      if (batch.isNotEmpty) await _kv!.setMany(batch);
    }
    await _kv?.set('${_k}active', activeId);
    _flush();
    notifyListeners();
  }

  Future<void> wipe() async {
    final kv = _kv;
    if (kv != null) {
      for (final k in await kv.keys(_k)) {
        if (k != '${_k}migrated') await kv.remove(k);
      }
    }
    baby = null;
    babies.clear();
    activeId = 'main';
    goals.clear();
    entries.clear();
    fridge.clear();
    tags.clear();
    txs.clear();
    funds.clear();
    measurements.clear();
    vax.clear();
    appts.clear();
    moods.clear();
    epds.clear();
    milestones.clear();
    memos.clear();
    teeth.clear();
    fussyDays.clear();
    members.clear();
    settings = Settings();
    _photoCache.clear();
    _seedTags();
    members.add(Member(name: settings.ownerName, role: 'owner'));
    glassLite.value = false;
    notifyListeners();
  }
}

final app = AppState();
