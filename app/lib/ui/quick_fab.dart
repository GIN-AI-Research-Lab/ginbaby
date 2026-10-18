import 'package:flutter/material.dart';

import '../core/art_catalog.dart';
import '../core/kit.dart';
import '../core/theme.dart';
import '../data/app_state.dart';
import 'diaper_screen.dart';
import 'feed_screen.dart';
import 'money.dart';
import 'pump_screen.dart';
import 'quick_logs.dart';
import 'sleep_screen.dart';

/// Nút "+" nổi ở góc dưới phải (trên thanh dưới): mở bảng ghi nhanh các việc hay làm.
class QuickAddButton extends StatelessWidget {
  const QuickAddButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Ghi nhanh',
      child: Pressable(
        scale: .9,
        onTap: () => showQuickLogSheet(context),
        child: minHit(Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: GB.accent,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: .5), width: 1.4),
            boxShadow: [BoxShadow(color: GB.accent.withValues(alpha: .45), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: const Icon(Icons.add_rounded, size: 32, color: Colors.white),
        )),
      ),
    );
  }
}

/// Bảng ghi nhanh: việc ghi được ngay (ngủ, tã ướt) thì ghi luôn; việc cần nhập thì mở màn tương ứng.
Future<void> showQuickLogSheet(BuildContext context) {
  return showGlassSheet(context, builder: (ctx) {
    final sleeping = app.activeSleep != null;
    void go(VoidCallback f) {
      Navigator.pop(ctx);
      // chờ bảng đóng rồi mới mở màn/hộp tiếp theo
      Future.delayed(const Duration(milliseconds: 220), () {
        if (context.mounted) f();
      });
    }

    final items = <({String label, String art, IconData icon, VoidCallback tap})>[
      (label: 'Ghi bú', art: 'ic_bottle', icon: Icons.local_drink_rounded, tap: () => go(() => openPage(context, const FeedScreen()))),
      (label: 'Hút sữa', art: 'ic_pump', icon: Icons.water_drop_rounded, tap: () => go(() => openPage(context, const PumpScreen()))),
      (label: sleeping ? 'Dậy rồi' : 'Ngủ ngay', art: 'ic_moon', icon: Icons.bedtime_rounded, tap: () => go(() => quickToggleSleep(context))),
      (label: 'Tã ướt', art: 'poop_mustard', icon: Icons.water_drop_outlined, tap: () => go(() => quickWetDiaper(context))),
      (label: 'Phân & tã', art: 'poop_mustard', icon: Icons.baby_changing_station_rounded, tap: () => go(() => openPage(context, const DiaperScreen()))),
      (label: 'Nhiệt độ', art: 'ic_thermometer', icon: Icons.thermostat_rounded, tap: () => go(() => showOtherLogSheet(context, initial: 0))),
      (label: 'Thuốc', art: 'ic_medicine', icon: Icons.medication_rounded, tap: () => go(() => showOtherLogSheet(context, initial: 1))),
      (label: 'Ghi chú', art: 'ic_note', icon: Icons.edit_note_rounded, tap: () => go(() => showOtherLogSheet(context, initial: 2))),
      (label: 'Giấc ngủ', art: 'ic_moon', icon: Icons.edit_calendar_rounded, tap: () => go(() => openPage(context, const SleepScreen()))),
      (label: 'Chi tiêu', art: 'ic_wallet', icon: Icons.account_balance_wallet_rounded, tap: () => go(() => openPage(context, const MoneyAddScreen()))),
    ];

    Widget tile(({String label, String art, IconData icon, VoidCallback tap}) it) => Semantics(
          button: true,
          label: it.label,
          child: GlassCard(
            radius: 18,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            onTap: it.tap,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(height: 34, child: (it.art == 'poop_mustard' || ArtCatalog.has(it.art)) ? Art(it.art, height: 34) : Icon(it.icon, size: 30, color: GB.accentDeep)),
              const SizedBox(height: 6),
              FittedBox(fit: BoxFit.scaleDown, child: Text(it.label, maxLines: 1, style: GB.body(12.5, w: FontWeight.w700))),
            ]),
          ),
        );

    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Ghi nhanh', style: GB.display(22, w: FontWeight.w700)),
      const SizedBox(height: 4),
      Text('Chạm để ghi ngay hoặc mở màn nhập.', style: GB.body(12.5, color: GB.inkMuted)),
      const SizedBox(height: 12),
      for (var r = 0; r < items.length; r += 4)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            for (var c = 0; c < 4; c++) ...[
              if (c > 0) const SizedBox(width: 8),
              Expanded(child: r + c < items.length ? tile(items[r + c]) : const SizedBox.shrink()),
            ],
          ]),
        ),
    ]);
  });
}
