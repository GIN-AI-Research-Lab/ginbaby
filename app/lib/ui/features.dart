import 'package:flutter/material.dart';

import '../core/art_catalog.dart';
import '../core/kit.dart';
import '../core/theme.dart';
import '../data/app_state.dart';
import '../domain/articles.dart';
import '../domain/leaps.dart';
import '../domain/stats.dart';
import '../domain/vaccines.dart';
import 'articles_screen.dart';
import 'diaper_screen.dart';
import 'easy_screen.dart';
import 'family_screen.dart';
import 'feed_screen.dart';
import 'growth_screen.dart';
import 'health_hub.dart';
import 'leaps_screen.dart';
import 'memory_screen.dart';
import 'milk_hub.dart';
import 'mind_screen.dart';
import 'noise_screen.dart';
import 'onboarding.dart';
import 'premium.dart';
import 'pump_screen.dart';
import 'recap.dart';
import 'settings.dart';
import 'sleep_screen.dart';
import 'solids_screen.dart';
import 'vaccine_screen.dart';

/// Chỉ số các tab chính trong Shell.
const kTabHome = 0, kTabHistory = 1, kTabStats = 2, kTabMoney = 3, kTabProfile = 4, kTabUtilities = 5;

/// Một chức năng của app: hiện ở tab Tiện ích, có thể ghim nhanh hoặc đặt lên thanh dưới.
class Feature {
  const Feature(this.id, this.title, this.icon, this.color, this.cat, {this.art, this.tab, this.page, this.sub});
  final String id;
  final String title;
  final IconData icon;
  final Color color; // màu pastel gốc
  final String cat; // mã nhóm
  final String? art; // tên tranh (tệp trong assets/art), nếu có
  final int? tab; // là tab chính thì mở bằng cách chuyển tab
  final Widget Function()? page; // còn lại mở thành màn riêng
  final String Function()? sub; // dòng phụ (cập nhật theo dữ liệu)
}

class FeatureCategory {
  const FeatureCategory(this.id, this.title, this.icon, this.color);
  final String id;
  final String title;
  final IconData icon;
  final Color color;
}

const List<FeatureCategory> kFeatureCats = [
  FeatureCategory('log', 'Ghi chép hằng ngày', Icons.edit_note_rounded, Color(0xFFFCE0E2)),
  FeatureCategory('health', 'Sức khoẻ và phát triển', Icons.monitor_heart_rounded, Color(0xFFDCEBF5)),
  FeatureCategory('grow', 'Ăn, ngủ và chơi', Icons.child_care_rounded, Color(0xFFF8E9A8)),
  FeatureCategory('mom', 'Dành cho mẹ', Icons.spa_rounded, Color(0xFFF8DEDF)),
  FeatureCategory('money', 'Tiền và gia đình', Icons.account_balance_wallet_rounded, Color(0xFFE4EBD2)),
  FeatureCategory('view', 'Xem lại và tổng kết', Icons.insights_rounded, Color(0xFFE6DEF5)),
  FeatureCategory('account', 'Tài khoản', Icons.person_rounded, Color(0xFFFBE3CF)),
];

String _leapSub() {
  final st = leapState(app.age.adjDays);
  if (st.current != null) return 'Đang gần bước nhảy ${st.current!.n}';
  if (st.next != null) return 'Kế tiếp: tuần ${st.next!.week}';
  return '10 bước nhảy';
}

final List<Feature> kFeatures = [
  // Ghi chép hằng ngày
  Feature('pump', 'Hút sữa', Icons.water_drop_rounded, const Color(0xFFFDE3E5), 'log', art: 'ic_pump', page: () => const PumpScreen(), sub: () => 'Ghi lượng sữa hai bên'),
  Feature('breast', 'Cho bú', Icons.favorite_rounded, const Color(0xFFFDEBDF), 'log', art: 'ic_breast', page: () => const FeedScreen(initialTab: 1), sub: () => 'Đồng hồ bú trái, phải'),
  Feature('bottle', 'Bình sữa', Icons.local_drink_rounded, const Color(0xFFEFE6F6), 'log', art: 'ic_bottle', page: () => const FeedScreen(initialTab: 0), sub: () => 'Ghi lượng ml, sữa mẹ hoặc công thức'),
  Feature('sleep', 'Giấc ngủ', Icons.bedtime_rounded, const Color(0xFFE3EBDD), 'log', art: 'ic_moon', page: () => const SleepScreen(), sub: () => app.activeSleep != null ? 'Bé đang ngủ' : 'Ngủ ngay, dậy rồi'),
  Feature('diaper', 'Phân và tã', Icons.baby_changing_station_rounded, const Color(0xFFFBF1D4), 'log', art: 'poop_mustard', page: () => const DiaperScreen(), sub: () => 'Màu, kết cấu, số lượng'),
  Feature('temp', 'Nhiệt độ', Icons.thermostat_rounded, const Color(0xFFDCEBF5), 'log', art: 'ic_thermometer', page: () => const HealthHub(initial: 0), sub: () => 'Theo dõi sốt'),
  Feature('med', 'Thuốc', Icons.medication_rounded, const Color(0xFFF8DEDF), 'log', art: 'ic_medicine', page: () => const HealthHub(initial: 1), sub: () => 'Liều dùng và nhắc'),
  Feature('fridge', 'Tủ sữa', Icons.kitchen_rounded, const Color(0xFFDCEBF5), 'log', art: 'ic_fridge', page: () => const MilkHub(), sub: () => 'Sữa trữ ngăn mát, ngăn đông'),
  // Sức khoẻ và phát triển
  Feature('vaccine', 'Tiêm chủng', Icons.vaccines_rounded, const Color(0xFFF0B5B9), 'health', art: 'ic_vaccine', page: () => const VaccineScreen(), sub: () => '${app.vax.length}/${kVaccines.length} mũi đã tiêm'),
  Feature('growth', 'Tăng trưởng', Icons.show_chart_rounded, const Color(0xFFC9DBA6), 'health', art: 'ic_growth', page: () => const GrowthScreen(), sub: () {
    final w = app.measurements.where((m) => m.weightKg != null).firstOrNull;
    return w == null ? 'Biểu đồ chuẩn WHO' : '${GB.num1(w.weightKg!)}kg · chuẩn WHO';
  }),
  Feature('health', 'Sức khoẻ', Icons.monitor_heart_rounded, const Color(0xFFDCEBF5), 'health', art: 'ic_health', page: () => const HealthHub(), sub: () => 'Nhiệt độ, thuốc, hẹn, mốc, răng'),
  Feature('appt', 'Lịch hẹn khám', Icons.event_rounded, const Color(0xFFE6E4F6), 'health', art: 'ic_clock', page: () => const HealthHub(initial: 2), sub: () => 'Khám, tái khám, nhắc hẹn'),
  Feature('teeth', 'Mọc răng', Icons.tag_faces_rounded, const Color(0xFFFCE0E2), 'health', art: 'ic_health', page: () => const HealthHub(initial: 4), sub: () => 'Đánh dấu răng đã mọc'),
  Feature('memory', 'Nhật ký mốc', Icons.child_friendly_rounded, const Color(0xFFFBE3CF), 'health', art: 'ic_milestone', page: () => const MemoryJournalScreen(), sub: () => '${app.memos.length} kỷ niệm · thẻ chia sẻ'),
  Feature('redflag', 'Khi nào cần đi khám', Icons.warning_amber_rounded, const Color(0xFFF0B5B9), 'health', art: 'ic_health', page: () => ArticleDetail(kArticles.firstWhere((a) => a.id == 'red_flags')), sub: () => 'Dấu hiệu nguy hiểm không nên chờ'),
  // Ăn, ngủ và chơi
  Feature('solids', 'Ăn dặm', Icons.restaurant_rounded, const Color(0xFFF8E9A8), 'grow', art: 'ic_solids', page: () => const SolidsScreen(), sub: () => 'Thực phẩm và dị ứng'),
  Feature('easy', 'Lịch EASY', Icons.schedule_rounded, const Color(0xFFE6DEF5), 'grow', art: 'ic_clock', page: () => const EasyScreen(), sub: () => 'Ăn, chơi, ngủ theo giờ'),
  Feature('leaps', 'Wonder Weeks', Icons.bolt_rounded, const Color(0xFFFCE0E2), 'grow', art: 'ic_wonder', page: () => const LeapsScreen(), sub: _leapSub),
  Feature('noise', 'Tiếng ồn trắng', Icons.graphic_eq_rounded, const Color(0xFFE3E6F6), 'grow', art: 'ic_noise', page: () => const NoiseScreen(), sub: () => '8 âm dỗ bé ngủ'),
  Feature('articles', 'Cẩm nang', Icons.menu_book_rounded, const Color(0xFFFBE3CF), 'grow', art: 'ic_book', page: () => const ArticlesScreen(), sub: () => '${kArticles.length} bài có nguồn'),
  // Dành cho mẹ
  Feature('mind', 'Góc của mẹ', Icons.spa_rounded, const Color(0xFFF8DEDF), 'mom', art: 'ic_mind', page: () => const MindScreen(), sub: () => 'Tâm trạng, thở, tự kiểm tra'),
  Feature('epds', 'Tự kiểm tra sau sinh', Icons.favorite_rounded, const Color(0xFFFCE0E2), 'mom', art: 'ic_mind', page: () => const EpdsScreen(), sub: () => 'Thang EPDS 10 câu'),
  // Tiền và gia đình
  Feature('money', 'Tiền của bé', Icons.account_balance_wallet_rounded, const Color(0xFFE4EBD2), 'money', art: 'ic_wallet', tab: kTabMoney, sub: () => 'Thu chi và quỹ của con'),
  Feature('family', 'Gia đình', Icons.groups_rounded, const Color(0xFFE4EBD2), 'money', art: 'ic_family', page: () => const FamilyScreen(), sub: () => '${app.members.length} thành viên'),
  // Xem lại và tổng kết
  Feature('history', 'Lịch sử', Icons.receipt_long_rounded, const Color(0xFFFDE3E5), 'view', art: 'ic_note', tab: kTabHistory, sub: () => 'Mọi lần ghi theo ngày'),
  Feature('stats', 'Thống kê', Icons.bar_chart_rounded, const Color(0xFFE6DEF5), 'view', art: 'ic_growth', tab: kTabStats, sub: () => 'Ngày, tuần, tháng'),
  Feature('recap', 'Thẻ tổng kết tuần', Icons.auto_awesome_rounded, const Color(0xFFF8E9A8), 'view', art: 'ic_star', page: () => RecapScreen(weekStart: Stats.weekStart(DateTime.now())), sub: () => 'Ảnh chia sẻ cả tuần'),
  // Tài khoản
  Feature('profile', 'Hồ sơ của bé', Icons.person_rounded, const Color(0xFFFBE3CF), 'account', art: 'ic_family', tab: kTabProfile, sub: () => app.baby == null ? '' : '${app.baby!.name} · ${app.age.label}'),
  Feature('editbaby', 'Sửa hồ sơ bé', Icons.edit_rounded, const Color(0xFFFCE0E2), 'account', art: 'ic_note', page: () => const Onboarding(edit: true), sub: () => 'Tên, ngày sinh, cân nặng'),
  Feature('settings', 'Cài đặt', Icons.settings_rounded, const Color(0xFFE6E4F6), 'account', art: 'ic_settings', page: () => const SettingsScreen(), sub: () => 'Giao diện, nhắc nhở, sao lưu'),
  Feature('premium', 'GinBaby Premium', Icons.star_rounded, const Color(0xFFFBEFC8), 'account', art: 'ic_star', page: () => const PremiumScreen(), sub: () => 'Miễn phí và Premium'),
];

Feature? featureById(String id) => kFeatures.where((f) => f.id == id).firstOrNull;

/// Mở một chức năng: chuyển tab chính hoặc mở màn riêng.
void openFeature(BuildContext context, Feature f, void Function(int) goTab) {
  if (f.tab != null) {
    goTab(f.tab!);
  } else if (f.page != null) {
    openPage(context, f.page!());
  }
}

/// Biểu tượng tròn của một chức năng: tranh màu nước nếu có, không thì icon hệ thống.
class FeatureBadge extends StatelessWidget {
  const FeatureBadge(this.f, {super.key, this.size = 44});
  final Feature f;
  final double size;

  @override
  Widget build(BuildContext context) {
    final a = f.art;
    final hasArt = a != null && ArtCatalog.has(a);
    final h = HSLColor.fromColor(f.color);
    final disc = GB.dark ? HSLColor.fromAHSL(1, h.hue, h.saturation > .12 ? .30 : .08, .35).toColor() : f.color.withValues(alpha: .6);
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(hasArt ? size * .12 : 0),
      decoration: BoxDecoration(color: disc, shape: BoxShape.circle, border: Border.all(color: GB.edgeOf(disc), width: 1)),
      child: hasArt ? Art(a) : Icon(f.icon, size: size * .5, color: GB.dark ? HSLColor.fromAHSL(1, h.hue, .72, .82).toColor() : GB.accentDeep),
    );
  }
}
