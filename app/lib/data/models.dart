import 'dart:math' as math;

String uid() => '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${math.Random().nextInt(0xFFFF).toRadixString(36)}';

DateTime dtFrom(dynamic v) => DateTime.fromMillisecondsSinceEpoch((v as num).toInt());
int msOf(DateTime d) => d.millisecondsSinceEpoch;

enum Sex { girl, boy }

enum FeedMode { breast, formula, mixed }

/// Hồ sơ bé.
class Baby {
  Baby({
    required this.name,
    required this.sex,
    required this.dob,
    this.birthWeightKg = 3.2,
    this.birthLengthCm,
    this.gestWeeks = 40,
    this.mode = FeedMode.mixed,
  });

  String name;
  Sex sex;
  DateTime dob;
  double birthWeightKg;
  double? birthLengthCm;
  int gestWeeks;
  FeedMode mode;

  Map<String, dynamic> toJson() => {
        'name': name,
        'sex': sex.index,
        'dob': msOf(dob),
        'bw': birthWeightKg,
        'bl': birthLengthCm,
        'gest': gestWeeks,
        'mode': mode.index,
      };

  static Baby fromJson(Map<String, dynamic> j) => Baby(
        name: j['name'] as String,
        sex: Sex.values[(j['sex'] as num).toInt()],
        dob: dtFrom(j['dob']),
        birthWeightKg: (j['bw'] as num).toDouble(),
        birthLengthCm: (j['bl'] as num?)?.toDouble(),
        gestWeeks: (j['gest'] as num?)?.toInt() ?? 40,
        mode: FeedMode.values[(j['mode'] as num?)?.toInt() ?? 2],
      );
}

class T {
  static const feed = 'feed';
  static const sleep = 'sleep';
  static const diaper = 'diaper';
  static const pump = 'pump';
  static const temp = 'temp';
  static const med = 'med';
  static const solid = 'solid';
  static const note = 'note';
}

/// Một bản ghi nhật ký: bú, ngủ, tã, hút, nhiệt độ, thuốc, ăn dặm…
class Entry {
  Entry({String? id, required this.type, required this.time, this.end, Map<String, dynamic>? data})
      : id = id ?? uid(),
        data = data ?? {};

  final String id;
  String type;
  DateTime time;
  DateTime? end;
  Map<String, dynamic> data;

  Duration? get duration => end?.difference(time);
  double num(String k) {
    final v = data[k];
    if (v is int) return v.toDouble();
    if (v is double) return v;
    return 0;
  }

  int get ml => num('ml').round();
  String str(String k, [String d = '']) => (data[k] as String?) ?? d;
  bool flag(String k) => data[k] == true;

  Map<String, dynamic> toJson() => {'id': id, 't': type, 'time': msOf(time), 'end': end == null ? null : msOf(end!), 'd': data};

  static Entry fromJson(Map<String, dynamic> j) => Entry(
        id: j['id'] as String,
        type: j['t'] as String,
        time: dtFrom(j['time']),
        end: j['end'] == null ? null : dtFrom(j['end']),
        data: Map<String, dynamic>.from(j['d'] as Map? ?? {}),
      );
}

/// Bình sữa trong tủ.
class FridgeItem {
  FridgeItem({String? id, required this.ml, required this.storedAt, this.freezer = false, this.usedMl = 0, this.discarded = false, this.note = ''}) : id = id ?? uid();
  final String id;
  int ml;
  DateTime storedAt;
  bool freezer;
  int usedMl;
  bool discarded;
  String note;

  int get left => math.max(0, ml - usedMl);

  /// Hạn dùng tham khảo (CDC): ngăn mát 4 ngày, ngăn đông 6 tháng.
  DateTime get expires => freezer ? DateTime(storedAt.year, storedAt.month + 6, storedAt.day, storedAt.hour, storedAt.minute) : storedAt.add(const Duration(days: 4));

  Map<String, dynamic> toJson() => {'id': id, 'ml': ml, 'at': msOf(storedAt), 'fz': freezer, 'used': usedMl, 'dis': discarded, 'note': note};
  static FridgeItem fromJson(Map<String, dynamic> j) => FridgeItem(
        id: j['id'] as String,
        ml: (j['ml'] as num).toInt(),
        storedAt: dtFrom(j['at']),
        freezer: j['fz'] == true,
        usedMl: (j['used'] as num?)?.toInt() ?? 0,
        discarded: j['dis'] == true,
        note: (j['note'] as String?) ?? '',
      );
}

/// Nhãn thu chi.
class MoneyTag {
  MoneyTag({required this.id, required this.label, required this.colorIdx, this.income = false});
  final String id;
  String label;
  int colorIdx;
  bool income;
  Map<String, dynamic> toJson() => {'id': id, 'l': label, 'c': colorIdx, 'in': income};
  static MoneyTag fromJson(Map<String, dynamic> j) => MoneyTag(id: j['id'] as String, label: j['l'] as String, colorIdx: (j['c'] as num).toInt(), income: j['in'] == true);
}

/// Một khoản thu/chi.
class Tx {
  Tx({
    String? id,
    required this.time,
    required this.amount,
    this.title = '',
    List<String>? tags,
    this.code = '',
    this.qty = 1,
    this.unitPrice,
    this.store = '',
    this.payer = '',
    this.note = '',
    List<String>? photos,
  })  : id = id ?? uid(),
        tags = tags ?? [],
        photos = photos ?? [];

  final String id;
  DateTime time;
  int amount; // dương = thu, âm = chi (đồng)
  String title;
  List<String> tags;
  String code;
  double qty;
  int? unitPrice;
  String store;
  String payer;
  String note;
  List<String> photos;

  bool get income => amount > 0;

  Map<String, dynamic> toJson() => {'id': id, 'time': msOf(time), 'a': amount, 'title': title, 'tags': tags, 'code': code, 'qty': qty, 'up': unitPrice, 'store': store, 'payer': payer, 'note': note, 'ph': photos};
  static Tx fromJson(Map<String, dynamic> j) => Tx(
        id: j['id'] as String,
        time: dtFrom(j['time']),
        amount: (j['a'] as num).toInt(),
        title: (j['title'] as String?) ?? '',
        tags: List<String>.from(j['tags'] as List? ?? const []),
        code: (j['code'] as String?) ?? '',
        qty: (j['qty'] as num?)?.toDouble() ?? 1,
        unitPrice: (j['up'] as num?)?.toInt(),
        store: (j['store'] as String?) ?? '',
        payer: (j['payer'] as String?) ?? '',
        note: (j['note'] as String?) ?? '',
        photos: List<String>.from(j['ph'] as List? ?? const []),
      );
}

enum AssetType { cash, saving, gold, other }

/// Một khoản trong quỹ của con.
class FundItem {
  FundItem({
    String? id,
    required this.name,
    required this.type,
    this.amount = 0,
    this.qty = 0,
    this.unit = 'chỉ',
    this.buyPrice = 0,
    this.curPrice = 0,
    this.rate = 0,
    this.maturity,
    this.holder = '',
    this.note = '',
    required this.date,
    List<String>? photos,
    List<FundMove>? moves,
  })  : id = id ?? uid(),
        photos = photos ?? [],
        moves = moves ?? [];

  final String id;
  String name;
  AssetType type;
  int amount; // tiền mặt, tiết kiệm, khác: giá trị đồng
  double qty; // vàng: số lượng
  String unit; // chỉ | lượng | gram
  int buyPrice; // đồng / đơn vị
  int curPrice; // giá tạm tính nhập tay
  double rate; // lãi suất %/năm (tiết kiệm)
  DateTime? maturity;
  String holder;
  String note;
  DateTime date;
  List<String> photos;
  List<FundMove> moves;

  int get value => type == AssetType.gold ? (qty * (curPrice > 0 ? curPrice : buyPrice)).round() : amount;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.index,
        'amount': amount,
        'qty': qty,
        'unit': unit,
        'bp': buyPrice,
        'cp': curPrice,
        'rate': rate,
        'mat': maturity == null ? null : msOf(maturity!),
        'holder': holder,
        'note': note,
        'date': msOf(date),
        'ph': photos,
        'moves': moves.map((m) => m.toJson()).toList(),
      };

  static FundItem fromJson(Map<String, dynamic> j) => FundItem(
        id: j['id'] as String,
        name: j['name'] as String,
        type: AssetType.values[(j['type'] as num).toInt()],
        amount: (j['amount'] as num?)?.toInt() ?? 0,
        qty: (j['qty'] as num?)?.toDouble() ?? 0,
        unit: (j['unit'] as String?) ?? 'chỉ',
        buyPrice: (j['bp'] as num?)?.toInt() ?? 0,
        curPrice: (j['cp'] as num?)?.toInt() ?? 0,
        rate: (j['rate'] as num?)?.toDouble() ?? 0,
        maturity: j['mat'] == null ? null : dtFrom(j['mat']),
        holder: (j['holder'] as String?) ?? '',
        note: (j['note'] as String?) ?? '',
        date: dtFrom(j['date']),
        photos: List<String>.from(j['ph'] as List? ?? const []),
        moves: ((j['moves'] as List?) ?? const []).map((e) => FundMove.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      );
}

/// Lịch sử thêm vào / rút ra / cập nhật giá trị.
class FundMove {
  FundMove({required this.time, required this.kind, required this.delta, this.note = ''});
  final DateTime time;
  final String kind; // add | out | adjust
  final int delta; // đồng (dương/âm)
  final String note;
  Map<String, dynamic> toJson() => {'t': msOf(time), 'k': kind, 'd': delta, 'n': note};
  static FundMove fromJson(Map<String, dynamic> j) => FundMove(time: dtFrom(j['t']), kind: j['k'] as String, delta: (j['d'] as num).toInt(), note: (j['n'] as String?) ?? '');
}

class FundGoal {
  FundGoal({this.name = '', this.target = 0});
  String name;
  int target;
  Map<String, dynamic> toJson() => {'n': name, 't': target};
  static FundGoal fromJson(Map<String, dynamic> j) => FundGoal(name: (j['n'] as String?) ?? '', target: (j['t'] as num?)?.toInt() ?? 0);
}

class Measurement {
  Measurement({String? id, required this.date, this.weightKg, this.heightCm, this.headCm}) : id = id ?? uid();
  final String id;
  DateTime date;
  double? weightKg;
  double? heightCm;
  double? headCm;
  Map<String, dynamic> toJson() => {'id': id, 'd': msOf(date), 'w': weightKg, 'h': heightCm, 'c': headCm};
  static Measurement fromJson(Map<String, dynamic> j) => Measurement(id: j['id'] as String, date: dtFrom(j['d']), weightKg: (j['w'] as num?)?.toDouble(), heightCm: (j['h'] as num?)?.toDouble(), headCm: (j['c'] as num?)?.toDouble());
}

class VaxRecord {
  VaxRecord({required this.date, this.place = '', this.lot = '', this.note = ''});
  DateTime date;
  String place;
  String lot;
  String note;
  Map<String, dynamic> toJson() => {'d': msOf(date), 'p': place, 'l': lot, 'n': note};
  static VaxRecord fromJson(Map<String, dynamic> j) => VaxRecord(date: dtFrom(j['d']), place: (j['p'] as String?) ?? '', lot: (j['l'] as String?) ?? '', note: (j['n'] as String?) ?? '');
}

class Appointment {
  Appointment({String? id, required this.time, required this.title, this.place = '', this.note = '', this.done = false}) : id = id ?? uid();
  final String id;
  DateTime time;
  String title;
  String place;
  String note;
  bool done;
  Map<String, dynamic> toJson() => {'id': id, 't': msOf(time), 'title': title, 'p': place, 'n': note, 'done': done};
  static Appointment fromJson(Map<String, dynamic> j) => Appointment(id: j['id'] as String, time: dtFrom(j['t']), title: j['title'] as String, place: (j['p'] as String?) ?? '', note: (j['n'] as String?) ?? '', done: j['done'] == true);
}

/// Một kỷ niệm về mốc của bé: ngày, ảnh, ghi chú. [key] là mã mốc (d_ mốc ngày, f_ lần đầu, c_ mốc riêng, m2_0… mốc CDC).
class MilestoneMemo {
  MilestoneMemo({required this.key, required this.title, required this.date, this.note = '', this.photo, this.custom = false});
  final String key;
  String title;
  DateTime date;
  String note;
  String? photo;
  bool custom;
  Map<String, dynamic> toJson() => {'k': key, 't': title, 'd': msOf(date), if (note.isNotEmpty) 'n': note, if (photo != null) 'p': photo, if (custom) 'c': true};
  static MilestoneMemo fromJson(Map<String, dynamic> j) => MilestoneMemo(key: j['k'] as String, title: j['t'] as String, date: dtFrom(j['d']), note: (j['n'] as String?) ?? '', photo: j['p'] as String?, custom: j['c'] == true);
}

class MoodEntry {
  MoodEntry({String? id, required this.time, required this.mood, this.note = ''}) : id = id ?? uid();
  final String id;
  DateTime time;
  int mood; // 0 mệt, 1 bình thường, 2 ổn, 3 vui
  String note;
  Map<String, dynamic> toJson() => {'id': id, 't': msOf(time), 'm': mood, 'n': note};
  static MoodEntry fromJson(Map<String, dynamic> j) => MoodEntry(id: j['id'] as String, time: dtFrom(j['t']), mood: (j['m'] as num).toInt(), note: (j['n'] as String?) ?? '');
}

class EpdsResult {
  EpdsResult({required this.time, required this.answers});
  final DateTime time;
  final List<int> answers;
  int get score => answers.fold(0, (a, b) => a + b);
  Map<String, dynamic> toJson() => {'t': msOf(time), 'a': answers};
  static EpdsResult fromJson(Map<String, dynamic> j) => EpdsResult(time: dtFrom(j['t']), answers: List<int>.from(j['a'] as List));
}

/// Thành viên gia đình (bản thử: chỉ lưu cục bộ, chưa đồng bộ).
class Member {
  Member({required this.name, required this.role});
  String name;
  String role; // owner | edit | view
  Map<String, dynamic> toJson() => {'n': name, 'r': role};
  static Member fromJson(Map<String, dynamic> j) => Member(name: j['n'] as String, role: j['r'] as String);
}

/// Cài đặt người dùng.
class Settings {
  Settings();
  bool lite = false;
  bool ozUnits = false;
  int pumpSessions = 6; // số cữ hút/ngày
  int pumpShare = 60; // % nhu cầu sữa của bé muốn lấy từ sữa hút
  int easy = 3; // E2.5=25, E3=30, E3.5=35, E4=40 (nhân 10)
  bool easyAuto = true;
  List<int> pumpTimes = [6, 9, 12, 15, 18, 21];
  bool premium = false;
  bool hideMoney = false;
  bool remind = true;
  DateTime? breastStart; // giờ bắt đầu bú mẹ (đồng hồ đang chạy nếu chưa có giờ kết thúc)
  DateTime? breastEnd; // giờ kết thúc bú mẹ chưa lưu
  String breastSide = 'L';
  String ownerName = 'Mẹ';
  int themeMode = 0; // 0 theo máy, 1 sáng, 2 tối
  int glassMode = 0; // kính mờ: 0 tắt, 1 nhẹ (thanh dưới, popup), 2 đầy đủ (cả thẻ)
  List<String> footer = ['history', 'stats', 'money']; // ba nút giữa của thanh dưới (mã chức năng)
  List<String> favs = ['pump', 'breast', 'bottle', 'sleep']; // mục ghim nhanh ở tab Tiện ích
  int feedRemindHours = 0; // nhắc cữ bú sau X giờ kể từ cữ trước (0 = tắt)
  bool notify = false; // bật thông báo của trình duyệt
  List<String> notified = []; // các nhắc nhở đã báo (tránh báo lặp)
  String? heroPhoto; // id ảnh đầu trang do mẹ chọn (null = tranh mặc định)
  int monthlyBudget = 0;

  Map<String, dynamic> toJson() => {
        'mb': monthlyBudget,
        'lite': lite,
        'oz': ozUnits,
        'ps': pumpSessions,
        'psh': pumpShare,
        'easy': easy,
        'ea': easyAuto,
        'pt': pumpTimes,
        'prem': premium,
        'hm': hideMoney,
        'rem': remind,
        'bs': breastStart == null ? null : msOf(breastStart!),
        'be': breastEnd == null ? null : msOf(breastEnd!),
        'bside': breastSide,
        'owner': ownerName,
        if (heroPhoto != null) 'hp': heroPhoto,
        'nf': notify,
        'fr': feedRemindHours,
        'tm': themeMode,
        'gm': glassMode,
        'ft': footer,
        'fv': favs,
        'nt': notified,
      };

  static Settings fromJson(Map<String, dynamic> j) {
    final s = Settings();
    s.lite = j['lite'] == true;
    s.ozUnits = j['oz'] == true;
    s.pumpSessions = (j['ps'] as num?)?.toInt() ?? 6;
    s.pumpShare = (j['psh'] as num?)?.toInt() ?? 60;
    s.easy = (j['easy'] as num?)?.toInt() ?? 3;
    s.easyAuto = j['ea'] != false;
    s.pumpTimes = List<int>.from(j['pt'] as List? ?? const [6, 9, 12, 15, 18, 21]);
    s.premium = j['prem'] == true;
    s.hideMoney = j['hm'] == true;
    s.remind = j['rem'] != false;
    s.breastStart = j['bs'] == null ? null : dtFrom(j['bs']);
    s.breastEnd = j['be'] == null ? null : dtFrom(j['be']);
    s.breastSide = (j['bside'] as String?) ?? 'L';
    s.ownerName = (j['owner'] as String?) ?? 'Mẹ';
    s.heroPhoto = j['hp'] as String?;
    s.notify = j['nf'] == true;
    s.feedRemindHours = (j['fr'] as num?)?.toInt() ?? 0;
    s.themeMode = (j['tm'] as num?)?.toInt() ?? 0;
    s.glassMode = (j['gm'] as num?)?.toInt() ?? 0;
    final ft = (j['ft'] as List?)?.map((e) => '$e').toList();
    if (ft != null && ft.length == 3) s.footer = ft;
    final fv = (j['fv'] as List?)?.map((e) => '$e').toList();
    if (fv != null) s.favs = fv;
    s.notified = List<String>.from(j['nt'] as List? ?? const []);
    s.monthlyBudget = (j['mb'] as num?)?.toInt() ?? 0;
    return s;
  }
}
