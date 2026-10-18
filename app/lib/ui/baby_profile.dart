import 'package:flutter/material.dart';

import '../core/kit.dart';
import '../core/pickers.dart';
import '../core/theme.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import 'quick_logs.dart';
import 'settings.dart';

/// Ảnh đại diện của bé: ảnh đã chọn hoặc chữ cái đầu của tên. Chạm để đổi ảnh khi [editable].
class BabyAvatar extends StatelessWidget {
  const BabyAvatar({super.key, this.size = 64, this.editable = false});
  final double size;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    final b = app.baby!;
    final bytes = b.photo == null ? null : app.photo(b.photo!);
    final avatar = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: b.sex == Sex.girl ? GB.accentSoft : GB.bottleTile,
        shape: BoxShape.circle,
        border: Border.all(color: GB.edgeOf(GB.line), width: 1.4),
        image: bytes == null ? null : DecorationImage(image: MemoryImage(bytes), fit: BoxFit.cover),
      ),
      child: bytes == null ? Text(b.name.isEmpty ? '?' : b.name.characters.first.toUpperCase(), style: GB.display(size * .46, color: GB.title)) : null,
    );
    if (!editable) return avatar;
    return Semantics(
      button: true,
      label: 'Đổi ảnh đại diện của bé',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _photoSheet(context),
        child: Stack(clipBehavior: Clip.none, children: [
          avatar,
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(color: GB.accent, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.6)),
              child: const Icon(Icons.photo_camera_rounded, size: 13, color: Colors.white),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _photoSheet(BuildContext context) async {
    final c = await showPhotoMenu(context, removeLabel: app.baby!.photo != null ? 'Xoá ảnh' : null);
    if (c == null || !context.mounted) return;
    final old = app.baby!.photo;
    if (c == PhotoChoice.remove) {
      app.saveBaby(app.baby!..photo = null);
      if (old != null) app.deletePhoto(old);
      return;
    }
    final id = await pickAndStorePhoto(context, camera: c == PhotoChoice.camera);
    if (id == null) return;
    app.saveBaby(app.baby!..photo = id);
    if (old != null && old != id) app.deletePhoto(old);
  }
}

/// Thẻ "Thông tin của bé": mỗi dòng chạm để sửa ngay (tên, giới tính, ngày sinh, cân nặng/chiều dài lúc sinh, tuổi thai, cách ăn).
class BabyInfoCard extends StatelessWidget {
  const BabyInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final b = app.baby!;
    final modes = const ['Bú mẹ', 'Công thức', 'Kết hợp'];
    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 2),
          child: Row(children: [
            Icon(Icons.badge_rounded, size: 20, color: GB.accentDeep),
            const SizedBox(width: 8),
            Text('Thông tin của bé', style: GB.body(15, w: FontWeight.w800)),
          ]),
        ),
        _row(context, 'Tên', b.name, () => _editName(context)),
        _row(context, 'Giới tính', b.sex == Sex.girl ? 'Bé gái' : 'Bé trai', () => _editSex(context)),
        _row(context, 'Ngày giờ sinh', GB.dmyhm(b.dob), () => _editDob(context)),
        _row(context, 'Cân nặng hiện tại', '${GB.num1(app.weightKg)} kg', () => _editNumber(context, 'Cân nặng hiện tại', app.weightKg, 0.1, 1.0, 30.0, 'kg', (v) => app.setCurrentWeight(v))),
        _row(context, 'Cân nặng lúc sinh', '${GB.num1(b.birthWeightKg)} kg', () => _editNumber(context, 'Cân nặng lúc sinh', b.birthWeightKg, 0.1, 1.0, 6.0, 'kg', (v) => b.birthWeightKg = v)),
        _row(context, 'Chiều dài lúc sinh', b.birthLengthCm == null ? 'Chưa nhập' : '${GB.num1(b.birthLengthCm!)} cm', () => _editNumber(context, 'Chiều dài lúc sinh', b.birthLengthCm ?? 50, 0.5, 30, 60, 'cm', (v) => b.birthLengthCm = v)),
        _row(context, 'Tuổi thai khi sinh', '${b.gestWeeks} tuần${b.gestWeeks < 37 ? ' (sinh non)' : ''}', () => _editNumber(context, 'Tuổi thai khi sinh', b.gestWeeks.toDouble(), 1, 24, 42, 'tuần', (v) => b.gestWeeks = v.round(), decimals: 0)),
        _row(context, 'Cách ăn', modes[b.mode.index], () => _editMode(context), last: true),
      ]),
    );
  }

  Widget _row(BuildContext context, String label, String value, VoidCallback onTap, {bool last = false}) {
    return Semantics(
      button: true,
      label: '$label, $value',
      child: Pressable(
        scale: .985,
        dim: .85,
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: GB.line, width: 1))),
          padding: const EdgeInsets.only(right: 4),
          child: Row(children: [
            Expanded(child: Text(label, style: GB.body(14, color: GB.inkMuted))),
            Flexible(child: Text(value, textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis, style: GB.body(14.5, w: FontWeight.w700))),
            const SizedBox(width: 2),
            Icon(Icons.chevron_right_rounded, color: GB.inkMuted),
          ]),
        ),
      ),
    );
  }

  Future<void> _editName(BuildContext context) async {
    final c = TextEditingController(text: app.baby!.name);
    final v = await showDialog<String>(
      context: context,
      builder: (dctx) => GlassAlert(
        backgroundColor: GB.cream,
        title: Text('Tên bé', style: GB.display(20, w: FontWeight.w700)),
        content: GlassField(controller: c, label: 'Tên bé hoặc biệt danh'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dctx), child: Text('Huỷ', style: GB.body(14, w: FontWeight.w700, color: GB.inkMuted))),
          TextButton(onPressed: () => Navigator.pop(dctx, c.text.trim()), child: Text('Lưu', style: GB.body(14, w: FontWeight.w800, color: GB.accentDeep))),
        ],
      ),
    );
    if (v != null) app.saveBaby(app.baby!..name = v.isEmpty ? 'Bé' : v);
  }

  Future<void> _editSex(BuildContext context) {
    return showGlassSheet(context, builder: (ctx) {
      return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Giới tính', style: GB.display(22, w: FontWeight.w700)),
        const SizedBox(height: 14),
        Seg(labels: const ['Bé gái', 'Bé trai'], index: app.baby!.sex == Sex.girl ? 0 : 1, onChanged: (i) {
          app.saveBaby(app.baby!..sex = i == 0 ? Sex.girl : Sex.boy);
          Navigator.pop(ctx);
        }),
      ]);
    });
  }

  Future<void> _editMode(BuildContext context) {
    return showGlassSheet(context, builder: (ctx) {
      return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Cách ăn của bé', style: GB.display(22, w: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Dùng để đánh giá lượng sữa và nhắc giờ hút.', style: GB.body(12.5, color: GB.inkMuted)),
        const SizedBox(height: 14),
        Seg(labels: const ['Bú mẹ', 'Công thức', 'Kết hợp'], index: app.baby!.mode.index, onChanged: (i) {
          app.saveBaby(app.baby!..mode = FeedMode.values[i]);
          Navigator.pop(ctx);
        }),
      ]);
    });
  }

  Future<void> _editDob(BuildContext context) async {
    final d = await pickDateTime(context, app.baby!.dob, last: DateTime.now(), title: 'Ngày giờ sinh');
    if (d != null) app.saveBaby(app.baby!..dob = d);
  }

  /// Sửa một số bằng nút − / + (bước [step]) rồi Lưu.
  Future<void> _editNumber(BuildContext context, String title, double value, double step, double min, double max, String unit, void Function(double) apply, {int decimals = 1}) {
    return showGlassSheet(context, builder: (ctx) {
      var v = value;
      return StatefulBuilder(builder: (ctx, setS) {
        String fmt(double x) => decimals == 0 ? '${x.round()}' : GB.num1(x);
        return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GB.display(22, w: FontWeight.w700)),
          const SizedBox(height: 14),
          Row(children: [
            RoundIconButton(icon: Icons.remove_rounded, label: 'Giảm $title', size: 52, onTap: () => setS(() => v = ((v - step).clamp(min, max) * 10).round() / 10)),
            Expanded(child: Center(child: Text('${fmt(v)} $unit', style: GB.display(32)))),
            RoundIconButton(icon: Icons.add_rounded, label: 'Tăng $title', size: 52, filled: true, onTap: () => setS(() => v = ((v + step).clamp(min, max) * 10).round() / 10)),
          ]),
          const SizedBox(height: 16),
          BigButton('Lưu', icon: Icons.check_rounded, onTap: () {
            apply(v);
            app.saveBaby(app.baby!);
            Navigator.pop(ctx);
          }),
        ]);
      });
    });
  }
}

/// Cài đặt nhanh trong Hồ sơ: nhắc nhở, giao diện, mở cài đặt đầy đủ.
class QuickSettingsCard extends StatelessWidget {
  const QuickSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final s = app.settings;
    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.tune_rounded, size: 20, color: GB.accentDeep),
          const SizedBox(width: 8),
          Text('Cài đặt nhanh', style: GB.body(15, w: FontWeight.w800)),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: Text('Nhắc nhở cữ hút, bú, tiêm chủng', style: GB.body(14))),
          Switch(value: s.remind, activeThumbColor: Colors.white, activeTrackColor: GB.accent, onChanged: (v) {
            s.remind = v;
            app.settingsChanged();
          }),
        ]),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Seg(labels: const ['Theo máy', 'Sáng', 'Tối', 'Theo giờ'], index: s.themeMode.clamp(0, 3), height: 44, onChanged: (i) {
            s.themeMode = i;
            app.settingsChanged();
          }),
        ),
        const SizedBox(height: 8),
        Pressable(
          scale: .985,
          behavior: HitTestBehavior.opaque,
          onTap: () => openPage(context, const SettingsScreen()),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.only(right: 4),
            child: Row(children: [
              Expanded(child: Text('Tất cả cài đặt, sao lưu và khôi phục', style: GB.body(14, w: FontWeight.w700, color: GB.accentDeep))),
              Icon(Icons.chevron_right_rounded, color: GB.accentDeep),
            ]),
          ),
        ),
      ]),
    );
  }
}
