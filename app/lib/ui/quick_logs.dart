import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/kit.dart';
import '../core/theme.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import 'diaper_screen.dart';
import 'widgets.dart';

/// Chọn ảnh (thư viện hoặc máy ảnh), nén nhẹ và lưu cục bộ. Trả về id ảnh.
Future<String?> pickAndStorePhoto(BuildContext context, {bool camera = false}) async {
  try {
    final x = await ImagePicker().pickImage(source: camera ? ImageSource.camera : ImageSource.gallery, maxWidth: 900, imageQuality: 62);
    if (x == null) return null;
    final bytes = await x.readAsBytes();
    return await app.putPhoto(bytes);
  } catch (_) {
    if (context.mounted) toast(context, 'Không mở được ảnh');
    return null;
  }
}

/// Ô ảnh nhỏ có nút xoá.
class PhotoThumb extends StatelessWidget {
  const PhotoThumb(this.id, {super.key, this.size = 64, this.onRemove});
  final String id;
  final double size;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final b = app.photo(id);
    return Stack(clipBehavior: Clip.none, children: [
      GestureDetector(
        onTap: b == null ? null : () => showDialog<void>(context: context, builder: (_) => Dialog(backgroundColor: Colors.transparent, child: Stack(children: [ClipRRect(borderRadius: BorderRadius.circular(20), child: InteractiveViewer(child: Image.memory(b))), const Positioned(right: 8, top: 8, child: PopupCloseButton())]))),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: GB.w(.6)),
          clipBehavior: Clip.antiAlias,
          child: b == null ? Icon(Icons.broken_image_rounded, color: GB.inkMuted) : Image.memory(b, fit: BoxFit.cover, gaplessPlayback: true),
        ),
      ),
      if (onRemove != null)
        Positioned(
          right: -6,
          top: -6,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(width: 24, height: 24, decoration: BoxDecoration(color: GB.ink, shape: BoxShape.circle), child: const Icon(Icons.close_rounded, size: 14, color: Colors.white)),
          ),
        ),
    ]);
  }
}

enum PhotoChoice { library, camera, remove }

/// Menu chọn nguồn ảnh hiện ngay bên dưới khung ảnh ([context] là của chính khung đó).
Future<PhotoChoice?> showPhotoMenu(BuildContext context, {String? removeLabel}) {
  final box = context.findRenderObject() as RenderBox;
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
  final topLeft = box.localToGlobal(Offset(0, box.size.height), ancestor: overlay);
  final rect = Rect.fromLTWH(topLeft.dx, topLeft.dy, box.size.width, 0);
  Widget item(IconData ic, String t, {Color? c}) => Row(children: [Icon(ic, size: 22, color: c ?? GB.accentDeep), const SizedBox(width: 12), Text(t, style: GB.body(14.5, w: FontWeight.w700, color: c))]);
  return showMenu<PhotoChoice>(
    context: context,
    position: RelativeRect.fromRect(rect, Offset.zero & overlay.size),
    color: GB.cream,
    elevation: 8,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: GB.line)),
    items: [
      PopupMenuItem(value: PhotoChoice.library, height: 48, child: item(Icons.photo_library_rounded, 'Thư viện ảnh')),
      PopupMenuItem(value: PhotoChoice.camera, height: 48, child: item(Icons.photo_camera_rounded, 'Chụp ảnh')),
      if (removeLabel != null) PopupMenuItem(value: PhotoChoice.remove, height: 48, child: item(Icons.delete_outline_rounded, removeLabel, c: GB.alert)),
    ],
  );
}

/// Hiện menu dưới khung ảnh rồi chọn/chụp ảnh; trả về id ảnh đã lưu (null nếu huỷ).
Future<String?> pickPhotoViaMenu(BuildContext context) async {
  final c = await showPhotoMenu(context);
  if (c == null || c == PhotoChoice.remove || !context.mounted) return null;
  return pickAndStorePhoto(context, camera: c == PhotoChoice.camera);
}

class AddPhotoButton extends StatelessWidget {
  const AddPhotoButton({super.key, required this.onPicked, this.size = 64});
  final ValueChanged<String> onPicked; // nhận id ảnh sau khi mẹ chọn từ menu hiện dưới nút
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Thêm ảnh',
        child: GestureDetector(
          onTap: () async {
            final id = await pickPhotoViaMenu(context);
            if (id != null) onPicked(id);
          },
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: GB.accent.withValues(alpha: .75), width: 1.5), color: GB.accentSoft.withValues(alpha: .6)),
            child: Icon(Icons.add_a_photo_rounded, color: GB.accentDeep),
          ),
        ),
      );
}

/// Mở màn "Phân của bé" (màu, kết cấu, số lượng kèm tranh).
Future<void> showDiaperSheet(BuildContext context) => openPage(context, const DiaperScreen());

Future<void> showSleepManualSheet(BuildContext context) {
  return showGlassSheet(context, builder: (ctx) {
    var start = DateTime.now().subtract(const Duration(hours: 1, minutes: 30));
    var end = DateTime.now();
    return StatefulBuilder(builder: (ctx, setS) {
      final d = end.difference(start);
      return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Thêm giấc ngủ đã qua', style: GB.display(22, w: FontWeight.w700)),
        const SizedBox(height: 12),
        TimeRow(label: 'Ngủ lúc', time: start, onChanged: (v) => setS(() => start = v)),
        const SizedBox(height: 10),
        TimeRow(label: 'Dậy lúc', time: end, onChanged: (v) => setS(() => end = v)),
        const SizedBox(height: 12),
        if (d.isNegative || d.inMinutes < 1)
          const Callout(level: Level.note, title: 'Giờ dậy phải sau giờ ngủ')
        else
          Text('Tổng ${GB.dur(d)}', style: GB.body(15, w: FontWeight.w700)),
        const SizedBox(height: 16),
        BigButton('Lưu', icon: Icons.check_rounded, enabled: !d.isNegative && d.inMinutes >= 1, onTap: () {
          app.addEntry(Entry(type: T.sleep, time: start, end: end));
          Navigator.pop(ctx);
          toast(context, 'Đã ghi giấc ngủ ${GB.dur(d)}');
        }),
      ]);
    });
  });
}

/// Ghi nhanh: nhiệt độ, thuốc, ghi chú.
Future<void> showOtherLogSheet(BuildContext context, {int initial = 0}) {
  return showGlassSheet(context, builder: (ctx) {
    var kind = initial;
    var time = DateTime.now();
    var temp = 36.8;
    final name = TextEditingController();
    final dose = TextEditingController();
    final text = TextEditingController();
    return StatefulBuilder(builder: (ctx, setS) {
      final ageDays = app.age.days;
      Widget advice() {
        if (temp >= 38.0 && ageDays < 90) {
          return const Callout(level: Level.alert, title: 'Bé dưới 3 tháng sốt từ 38°C', body: 'Cần đưa bé đi khám hoặc gọi bác sĩ ngay, không tự theo dõi ở nhà (khuyến cáo AAP).');
        }
        if (temp >= 39.0) return const Callout(level: Level.alert, title: 'Sốt cao', body: 'Liên hệ bác sĩ. Đưa bé đi khám ngay nếu bé li bì, khó thở, co giật hoặc nôn nhiều.');
        if (temp >= 38.0) return const Callout(level: Level.note, title: 'Bé đang sốt', body: 'Theo dõi sát, cho bé uống đủ sữa/nước và liên hệ bác sĩ nếu sốt kéo dài hoặc bé mệt.');
        if (temp < 36.0) return const Callout(level: Level.note, title: 'Nhiệt độ thấp', body: 'Giữ ấm cho bé và đo lại. Liên hệ bác sĩ nếu vẫn thấp, đặc biệt ở trẻ sơ sinh.');
        return const Callout(level: Level.ok, title: 'Nhiệt độ bình thường', body: 'Thường gặp 36,5–37,5°C.');
      }

      return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Ghi nhanh khác', style: GB.display(22, w: FontWeight.w700)),
        const SizedBox(height: 12),
        Seg(labels: const ['Nhiệt độ', 'Thuốc', 'Ghi chú'], index: kind, height: 40, onChanged: (i) => setS(() => kind = i)),
        const SizedBox(height: 10),
        TimeRow(time: time, onChanged: (v) => setS(() => time = v)),
        const SizedBox(height: 12),
        if (kind == 0) ...[
          Row(children: [
            RoundIconButton(icon: Icons.remove_rounded, label: 'Giảm 0,1°C', onTap: () => setS(() => temp = ((temp - 0.1) * 10).round() / 10)),
            Expanded(child: Center(child: Text('${GB.num1(temp)}°C', style: GB.display(40)))),
            RoundIconButton(icon: Icons.add_rounded, label: 'Tăng 0,1°C', filled: true, onTap: () => setS(() => temp = ((temp + 0.1) * 10).round() / 10)),
          ]),
          Slider(value: temp.clamp(34.0, 42.0), min: 34, max: 42, divisions: 80, activeColor: GB.accent, onChanged: (v) => setS(() => temp = (v * 10).round() / 10)),
          advice(),
        ] else if (kind == 1) ...[
          GlassField(controller: name, label: 'Tên thuốc'),
          const SizedBox(height: 10),
          GlassField(controller: dose, label: 'Liều (theo chỉ định bác sĩ)'),
          const SizedBox(height: 8),
          Text('App chỉ ghi lại, không tư vấn liều thuốc.', style: GB.body(12, color: GB.inkMuted)),
        ] else
          GlassField(controller: text, label: 'Ghi chú', maxLines: 3),
        const SizedBox(height: 16),
        BigButton('Lưu', icon: Icons.check_rounded, onTap: () {
          if (kind == 0) {
            app.addEntry(Entry(type: T.temp, time: time, data: {'v': temp}));
          } else if (kind == 1) {
            if (name.text.trim().isEmpty) return;
            app.addEntry(Entry(type: T.med, time: time, data: {'name': name.text.trim(), 'dose': dose.text.trim()}));
          } else {
            if (text.text.trim().isEmpty) return;
            app.addEntry(Entry(type: T.note, time: time, data: {'text': text.text.trim()}));
          }
          Navigator.pop(ctx);
          toast(context, 'Đã lưu');
        }),
      ]);
    });
  });
}

/// Bắt đầu hoặc kết thúc giấc ngủ ngay (1 chạm), có Hoàn tác.
void quickToggleSleep(BuildContext context) {
  final act = app.activeSleep;
  if (act == null) {
    app.startSleep();
    final started = app.activeSleep;
    toast(context, 'Bé bắt đầu ngủ lúc ${GB.hm(DateTime.now())}', undo: () {
      if (started != null) app.removeEntry(started.id);
    });
  } else {
    final done = app.endSleep();
    toast(context, 'Bé dậy rồi, ngủ ${GB.dur(done?.end?.difference(done.time) ?? Duration.zero)}', undo: () {
      if (done != null) {
        done.end = null;
        app.changed('entries');
      }
    });
  }
}

/// Ghi ngay một cữ tã ướt (1 thao tác), có Hoàn tác.
void quickWetDiaper(BuildContext context) {
  final e = Entry(type: T.diaper, time: DateTime.now(), data: {'kind': 'wet', 'amount': 'Vừa'});
  app.addEntry(e);
  toast(context, 'Đã ghi tã ướt', undo: () => app.removeEntry(e.id));
}
