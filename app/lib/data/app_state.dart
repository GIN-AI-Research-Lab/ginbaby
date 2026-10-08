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
  FundGoal goal = FundGoal();
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

  Future<void> init() async {
    final kv = await KV.open();
    _kv = kv;
    await _migrateFromPrefs(kv);

    Future<Map<String, dynamic>?> obj(String k) async {
      final s = await kv.get('$_k$k');
      if (s == null) return null;
      try {
        return Map<String, dynamic>.from(jsonDecode(s) as Map);
      } catch (_) {
        return null;
      }
    }

    Future<List<Map<String, dynamic>>> list(String k) async {
      final s = await kv.get('$_k$k');
      if (s == null) return [];
      try {
        return (jsonDecode(s) as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } catch (_) {
        return [];
      }
    }

    final b = await obj('baby');
    if (b != null) baby = Baby.fromJson(b);
    entries.addAll((await list('entries')).map(Entry.fromJson));
    fridge.addAll((await list('fridge')).map(FridgeItem.fromJson));
    tags.addAll((await list('tags')).map(MoneyTag.fromJson));
    txs.addAll((await list('tx')).map(Tx.fromJson));
    funds.addAll((await list('funds')).map(FundItem.fromJson));
    final g = await obj('goal');
    if (g != null) goal = FundGoal.fromJson(g);
    measurements.addAll((await list('meas')).map(Measurement.fromJson));
    final v = await obj('vax');
    if (v != null) {
      v.forEach((k, e) => vax[k] = VaxRecord.fromJson(Map<String, dynamic>.from(e as Map)));
    }
    appts.addAll((await list('appts')).map(Appointment.fromJson));
    moods.addAll((await list('moods')).map(MoodEntry.fromJson));
    epds.addAll((await list('epds')).map(EpdsResult.fromJson));
    final ms = await obj('miles');
    if (ms != null) ms.forEach((k, e) => milestones[k] = dtFrom(e));
    final mm = await obj('memos');
    if (mm != null) mm.forEach((k, e) => memos[k] = MilestoneMemo.fromJson(Map<String, dynamic>.from(e as Map)));
    final th = await obj('teeth');
    if (th != null) th.forEach((k, e) => teeth[k] = dtFrom(e));
    final fz = await obj('fussy');
    if (fz != null) fz.forEach((k, e) => fussyDays[k] = (e as num).toInt());
    members.addAll((await list('members')).map(Member.fromJson));
    final s = await obj('settings');
    if (s != null) settings = Settings.fromJson(s);
    glassLite.value = settings.lite;
    if (tags.isEmpty) _seedTags();
    if (members.isEmpty) members.add(Member(name: settings.ownerName, role: 'owner'));
    ready = true;
    notifyListeners();
    unawaited(_loadPhotos());
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
        case 'goal':
          v = jsonEncode(goal.toJson());
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
        removes.add('$_k$k');
      } else {
        batch['$_k$k'] = v;
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
      };

  // ---------- hồ sơ bé ----------
  bool get hasBaby => baby != null;
  Age get age => Age(baby!);

  void saveBaby(Baby b) {
    baby = b;
    changed('baby');
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
    funds.removeWhere((f) => f.id == id);
    changed('funds');
  }

  void fundChanged() => changed('funds');

  void setGoal(FundGoal g) {
    goal = g;
    changed('goal');
  }

  // ---------- sức khoẻ ----------
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
    if (withPhotos) {
      final photos = <String, String>{};
      for (final id in usedPhotoIds) {
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
    baby = j['baby'] == null ? null : Baby.fromJson(Map<String, dynamic>.from(j['baby'] as Map));
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
    if (j['goal'] != null) goal = FundGoal.fromJson(Map<String, dynamic>.from(j['goal'] as Map));
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
    for (final k in ['baby', 'entries', 'fridge', 'tags', 'tx', 'funds', 'goal', 'meas', 'vax', 'appts', 'moods', 'epds', 'miles', 'memos', 'teeth', 'fussy', 'members', 'settings']) {
      _dirty.add(k);
    }
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
    entries.clear();
    fridge.clear();
    tags.clear();
    txs.clear();
    funds.clear();
    goal = FundGoal();
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
