import 'package:flutter/material.dart';

import '../core/kit.dart';
import '../core/pastel.dart';
import '../core/theme.dart';
import '../data/app_state.dart';
import '../domain/articles.dart';
import '../domain/vaccines.dart';
import 'articles_screen.dart';
import 'family_screen.dart';
import 'features.dart';
import 'hero_photo.dart';
import 'health_hub.dart';
import 'milk_hub.dart';
import 'mind_screen.dart';
import 'onboarding.dart';
import 'premium.dart';
import 'settings.dart';
import 'vaccine_screen.dart';

/// Tab Cho mẹ: tiêm chủng, tăng trưởng, ăn dặm, cẩm nang, sức khoẻ, góc của mẹ, tiếng ồn trắng, gia đình.
class GuideTab extends StatelessWidget {
  const GuideTab({super.key, required this.goTab});
  final void Function(int) goTab;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final now = DateTime.now();
        final vr = nextVaccineReminder();
        final appt = app.appts.where((a) => !a.done && a.time.isAfter(now) && a.time.difference(now).inDays <= 7).toList();
        final moodDone = app.moods.any((m) => AppState.dayStart(m.time) == AppState.dayStart(now));
        final red = kArticles.firstWhere((a) => a.id == 'red_flags');

        return ListView(
          padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 16, 100),
          children: [
            SizedBox(
              height: 140,
              child: Stack(children: [
                const Positioned(right: -4, top: 0, child: HeroPhoto(width: 130)),
                const Positioned(right: 0, top: 0, child: ThemeToggle()),
                Positioned(
                  left: 0,
                  top: 10,
                  right: 122,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('Hồ sơ', style: GB.display(30, color: GB.title)),
                        const SizedBox(width: 6),
                        const Icon(Icons.favorite_rounded, color: Color(0xFFF08A97), size: 24),
                      ]),
                    ),
                    const SizedBox(height: 4),
                    Text('Sức khoẻ, kiến thức và góc nghỉ của mẹ', style: GB.script(13.5)),
                  ]),
                ),
              ]),
            ),
            GlassCard(
              radius: 26,
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                Row(children: [
                  Container(
                    width: 60,
                    height: 60,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: GB.accentSoft, shape: BoxShape.circle),
                    child: Text(app.baby!.name.characters.first.toUpperCase(), style: GB.display(28, color: GB.title)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(app.baby!.name, style: GB.display(22)),
                      Text('${app.age.label} · ${GB.num1(app.weightKg)}kg', style: GB.body(13, color: GB.inkMuted)),
                      Text('Sinh ${GB.dmy(app.baby!.dob)}', style: GB.body(12, color: GB.inkMuted)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _action('Sửa hồ sơ', Icons.edit_rounded, () => openPage(context, const Onboarding(edit: true)))),
                  const SizedBox(width: 8),
                  Expanded(child: _action('Tủ sữa', Icons.kitchen_rounded, () => openPage(context, const MilkHub()))),
                  const SizedBox(width: 8),
                  Expanded(child: _action('Cài đặt', Icons.settings_rounded, () => openPage(context, const SettingsScreen()))),
                ]),
              ]),
            ),
            const SizedBox(height: 10),
            GlassCard(
              radius: 22,
              tint: GB.warnBg,
              onTap: () => openPage(context, const PremiumScreen()),
              child: Row(children: [
                IconBadge(icon: Icons.star_rounded, bg: GB.p(Color(0xFFFBEFC8)), fg: GB.gold, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('GinBaby Premium', style: GB.body(14.5, w: FontWeight.w800)),
                    Text('Miễn phí và Premium', style: GB.body(12, color: GB.warn)),
                  ]),
                ),
                const Icon(Icons.chevron_right_rounded),
              ]),
            ),
            const SizedBox(height: 14),
            if (vr != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  radius: 22,
                  tint: vr.status == VStatus.overdue ? GB.alertBg : GB.warnBg,
                  opacity: .8,
                  onTap: () => openPage(context, const VaccineScreen()),
                  child: Row(children: [
                    const Orb(icon: Icons.vaccines_rounded, color: Color(0xFFF0B5B9), size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(vr.status == VStatus.overdue ? 'Đã quá lịch: ${vr.v.name}' : 'Mũi tiêm: ${vr.v.name}', style: GB.body(14.5, w: FontWeight.w800)),
                        Text('${vaxAgeLabel(vr.v.dueDays)} · dự kiến ${GB.dmy(vr.dueDate)}', style: GB.body(12, color: GB.inkMuted)),
                      ]),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ]),
                ),
              ),
            for (final a in appt)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  radius: 22,
                  onTap: () => openPage(context, const HealthHub(initial: 2)),
                  child: Row(children: [
                    Orb(icon: Icons.event_rounded, color: GB.infoBg, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(a.title, style: GB.body(14.5, w: FontWeight.w800)),
                        Text('${GB.dmyhm(a.time)}${a.place.isEmpty ? '' : ' · ${a.place}'}', style: GB.body(12, color: GB.inkMuted)),
                      ]),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ]),
                ),
              ),
            if (!moodDone)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  radius: 22,
                  onTap: () => openPage(context, const MindScreen()),
                  child: Row(children: [
                    Orb(icon: Icons.favorite_rounded, color: GB.p(Color(0xFFF8DEDF)), size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Hôm nay mẹ thế nào?', style: GB.body(14.5, w: FontWeight.w800)),
                        Text('Ghi nhanh tâm trạng trong Góc của mẹ', style: GB.body(12, color: GB.inkMuted)),
                      ]),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ]),
                ),
              ),
            GlassCard(
              radius: 22,
              tint: GB.alertBg,
              opacity: .75,
              onTap: () => openPage(context, ArticleDetail(red)),
              child: Row(children: [
                const Orb(icon: Icons.warning_amber_rounded, color: Color(0xFFF0B5B9), size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Khi nào cần đưa bé đi khám ngay', style: GB.body(14.5, w: FontWeight.w800, color: GB.alert)),
                    Text('Dấu hiệu nguy hiểm không nên chờ ở nhà', style: GB.body(12, color: GB.alert)),
                  ]),
                ),
                Icon(Icons.chevron_right_rounded, color: GB.alert),
              ]),
            ),
            const SizedBox(height: 14),
            GlassCard(
              radius: 22,
              onTap: () => openPage(context, const FamilyScreen()),
              child: Row(children: [
                IconBadge(icon: Icons.groups_rounded, bg: const Color(0xFFE4EBD2), fg: GB.ink, size: 40, art: 'family'),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Gia đình', style: GB.body(14.5, w: FontWeight.w800)),
                    Text('${app.members.length} thành viên · mời ba, ông bà cùng ghi', style: GB.body(12, color: GB.inkMuted)),
                  ]),
                ),
                const Icon(Icons.chevron_right_rounded),
              ]),
            ),
            const SizedBox(height: 10),
            GlassCard(
              radius: 22,
              onTap: () => goTab(kTabUtilities),
              child: Row(children: [
                IconBadge(icon: Icons.apps_rounded, bg: const Color(0xFFE6DEF5), fg: GB.ink, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Tất cả tiện ích', style: GB.body(14.5, w: FontWeight.w800)),
                    Text('Tiêm chủng, tăng trưởng, ăn dặm, cẩm nang… chia theo nhóm', style: GB.body(12, color: GB.inkMuted)),
                  ]),
                ),
                const Icon(Icons.chevron_right_rounded),
              ]),
            ),
          ],
        );
      },
    );
  }

  Widget _action(String label, IconData icon, VoidCallback onTap) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: GB.accentSoft.withValues(alpha: .55), borderRadius: BorderRadius.circular(16), border: Border.all(color: GB.edgeOf(GB.accentSoft.withValues(alpha: .55)), width: 1)),
          child: Column(children: [
            Icon(icon, size: 22, color: GB.accentDeep),
            const SizedBox(height: 3),
            FittedBox(fit: BoxFit.scaleDown, child: Text(label, style: GB.body(12.5, w: FontWeight.w800, color: GB.accentDeep))),
          ]),
        ),
      );
}
