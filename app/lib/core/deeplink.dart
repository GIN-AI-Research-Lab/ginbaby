import 'package:flutter/material.dart';

import '../domain/articles.dart';
import '../ui/articles_screen.dart';
import '../ui/diaper_screen.dart';
import '../ui/easy_screen.dart';
import '../ui/family_screen.dart';
import '../ui/feed_screen.dart';
import '../ui/growth_screen.dart';
import '../ui/health_hub.dart';
import '../ui/history.dart';
import '../ui/leaps_screen.dart';
import '../ui/memory_screen.dart';
import '../data/models.dart';
import '../ui/milk_hub.dart';
import '../ui/mind_screen.dart';
import '../ui/money.dart';
import '../ui/noise_screen.dart';
import '../ui/onboarding.dart';
import '../ui/premium.dart';
import '../ui/pump_screen.dart';
import '../ui/recap.dart';
import '../ui/settings.dart';
import '../ui/sleep_screen.dart';
import '../ui/solids_screen.dart';
import '../ui/vaccine_screen.dart';
import '../data/app_state.dart';
import '../data/demo.dart';
import '../domain/stats.dart';
import 'kit.dart';

/// Mở thẳng một màn qua tham số go của đường dẫn, ví dụ `/?go=vaccine`.
/// Dùng khi kiểm thử và để chia sẻ link tới một màn.
Widget? screenForFragment(String frag) {
  final f = frag.replaceFirst(RegExp(r'^/'), '');
  if (f.startsWith('article:')) {
    final a = kArticles.where((x) => x.id == f.substring(8)).firstOrNull;
    return a == null ? null : ArticleDetail(a);
  }
  if (f.startsWith('health')) return HealthHub(initial: int.tryParse(f.substring(6)) ?? 0);
  switch (f) {
    case 'feed':
      return const FeedScreen();
    case 'pump':
      return const PumpScreen();
    case 'vaccine':
      return const VaccineScreen();
    case 'growth':
      return const GrowthScreen();
    case 'solids':
      return const SolidsScreen();
    case 'articles':
      return const ArticlesScreen();
    case 'mind':
      return const MindScreen();
    case 'epds':
      return const EpdsScreen();
    case 'noise':
      return const NoiseScreen();
    case 'family':
      return const FamilyScreen();
    case 'premium':
      return const PremiumScreen();
    case 'settings':
      return const SettingsScreen();
    case 'easy':
      return const EasyScreen();
    case 'milk':
      return const MilkHub();
    case 'sleep':
      return const SleepScreen();
    case 'leaps':
      return const LeapsScreen();
    case 'memory':
      return const MemoryJournalScreen();
    case 'memedit':
      return const MemoryEditScreen(memoKey: 'f_roll', title: 'Lần đầu lật');
    case 'memcard':
      return MemoryCardScreen(MilestoneMemo(key: 'f_roll', title: 'Lần đầu lật', date: DateTime.now(), note: 'Bé tự lật từ nằm ngửa sang nằm sấp, cả nhà reo hò.'));
    case 'diaper':
      return const DiaperScreen();
    case 'history':
      return const HistoryScreen();
    case 'moneyadd':
      return const MoneyAddScreen();
    case 'profile':
      return const Onboarding(edit: true);
    case 'recap':
      return RecapScreen(weekStart: Stats.weekStart(DateTime.now().subtract(const Duration(days: 7))));
  }
  return null;
}

/// Gọi một lần sau khi giao diện chính đã hiện.
void openDeepLink(BuildContext context) {
  final frag = Uri.base.queryParameters['go'] ?? '';
  if (frag == 'seed') {
    seedDemo(app);
    return;
  }
  if (frag.isEmpty || !app.hasBaby) return;
  final w = screenForFragment(frag);
  if (w != null) openPage(context, w);
}
