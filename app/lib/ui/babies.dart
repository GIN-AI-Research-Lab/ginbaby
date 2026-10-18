import 'package:flutter/material.dart';

import '../core/kit.dart';
import '../core/theme.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import '../domain/age.dart';
import 'onboarding.dart';

/// Tuổi ngắn của một bé trong danh sách (vd. "5 tháng"), rỗng nếu chưa biết ngày sinh.
String babyAgeShort(BabyRef r) {
  final d = r.dob;
  if (d == null) return '';
  return Age(Baby(name: r.name, sex: r.girl ? Sex.girl : Sex.boy, dob: d), DateTime.now()).short;
}

/// Mở màn hình thêm một bé mới.
Future<void> addBabyFlow(BuildContext context) => openPage(context, const Onboarding(addNew: true));

/// Bảng chọn bé: chạm một bé để chuyển, thêm bé mới, xoá bé (khi có từ hai bé).
Future<void> showBabySwitcher(BuildContext context) {
  return showGlassSheet(context, builder: (ctx) {
    return ListenableBuilder(
      listenable: app,
      builder: (ctx, _) {
        final list = app.babies;
        return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Chọn bé', style: GB.display(22, w: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Mỗi bé có nhật ký, tiền và tiêm chủng riêng.', style: GB.body(12.5, color: GB.inkMuted)),
          const SizedBox(height: 12),
          for (final r in list)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _BabyRow(
                r: r,
                active: r.id == app.activeId,
                canDelete: list.length > 1,
                onTap: () async {
                  await app.switchBaby(r.id);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                onDelete: () async {
                  final ok = await confirmDialog(ctx, 'Xoá hồ sơ của ${r.name}?', 'Mọi nhật ký, thu chi, quỹ và tiêm chủng của bé này sẽ bị xoá và không khôi phục được.', ok: 'Xoá bé');
                  if (ok) await app.removeBaby(r.id);
                },
              ),
            ),
          const SizedBox(height: 6),
          BigButton('Thêm bé', icon: Icons.add_rounded, onTap: () {
            Navigator.pop(ctx);
            addBabyFlow(context);
          }),
        ]);
      },
    );
  });
}

class _BabyRow extends StatelessWidget {
  const _BabyRow({required this.r, required this.active, required this.canDelete, required this.onTap, required this.onDelete});
  final BabyRef r;
  final bool active;
  final bool canDelete;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final age = babyAgeShort(r);
    return Semantics(
      button: true,
      selected: active,
      label: 'Bé ${r.name}${age.isEmpty ? '' : ', $age'}${active ? ', đang xem' : ''}',
      child: GlassCard(
        radius: 20,
        padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
        tint: active ? GB.accentSoft : null,
        onTap: onTap,
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: r.girl ? GB.accentSoft : GB.bottleTile, shape: BoxShape.circle, border: Border.all(color: GB.edgeOf(GB.line), width: 1.2)),
            child: Text(r.name.isEmpty ? '?' : r.name.characters.first.toUpperCase(), style: GB.display(20, color: GB.title)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GB.body(15.5, w: FontWeight.w800)),
              if (age.isNotEmpty) Text(age, style: GB.body(12.5, color: GB.inkMuted)),
            ]),
          ),
          if (active) Icon(Icons.check_circle_rounded, color: GB.accent, size: 24),
          if (canDelete) RoundIconButton(icon: Icons.delete_outline_rounded, label: 'Xoá bé ${r.name}', size: 36, onTap: onDelete),
        ]),
      ),
    );
  }
}

/// Dải chọn bé ngang (Hồ sơ): mỗi bé một chip, chip "Thêm bé" ở cuối.
class BabyStrip extends StatelessWidget {
  const BabyStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(scrollDirection: Axis.horizontal, children: [
        for (final r in app.babies) ...[
          PillChip(label: r.name, on: r.id == app.activeId, height: 44, onTap: () => app.switchBaby(r.id)),
          const SizedBox(width: 8),
        ],
        PillChip(label: 'Thêm bé', icon: Icons.add_rounded, on: false, height: 44, onTap: () => addBabyFlow(context)),
      ]),
    );
  }
}
