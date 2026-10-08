import 'package:flutter/material.dart';

import '../core/kit.dart';
import '../core/pastel.dart';
import '../core/theme.dart';
import '../data/app_state.dart';
import '../domain/leaps.dart';
import '../domain/stats.dart';

/// Tuần khủng hoảng (Wonder Weeks): mốc theo tuổi, mô tả kỹ từng bước nhảy, đối chiếu với dữ liệu của bé.
class LeapsScreen extends StatefulWidget {
  const LeapsScreen({super.key});

  @override
  State<LeapsScreen> createState() => _LeapsScreenState();
}

class _LeapsScreenState extends State<LeapsScreen> {
  int? open;

  @override
  void initState() {
    super.initState();
    final st = leapState(app.age.adjDays);
    open = (st.current ?? st.next ?? st.prev)?.n;
  }

  String _w(double v) => v.round().toString();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final age = app.age;
        final st = leapState(age.adjDays);
        return SubPage(
          title: 'Wonder Weeks',
          subtitle: 'Bước nhảy phát triển của bé',
          art: 'hero_baby_awake',
          artWidth: 110,
          children: [
            const Callout(
              level: Level.info,
              title: 'Chỉ để tham khảo',
              body: 'Các mốc này đến từ cuốn "The Wonder Weeks". Cơ sở khoa học còn hạn chế và mỗi bé một khác, nhiều bé không quấy đúng tuần. Bé quấy kéo dài, bỏ bú, sốt hoặc có dấu hiệu bất thường thì cần đi khám, đừng vội cho là do bước nhảy.',
            ),
            const SizedBox(height: 12),
            _statusCard(st, age.preterm),
            const SizedBox(height: 12),
            _dataCard(),
            const SectionTitle('10 bước nhảy'),
            for (final l in kLeaps) ...[_leapCard(l, st.weeks), const SizedBox(height: 10)],
            const SectionTitle('Dễ bị nhầm với bước nhảy'),
            for (final c in kConfusables) ...[_confusable(c), const SizedBox(height: 10)],
            const SizedBox(height: 4),
            Text(
              'Mốc tuần tính từ ngày dự sinh (bé sinh non dùng tuổi hiệu chỉnh). Khoảng quấy chỉ là ước lượng. Nguồn: van de Rijt và Plooij, The Wonder Weeks; tổng quan trên Wikipedia; bài phân tích của Your Parenting Mojo về giới hạn của nghiên cứu. Nội dung cần chuyên gia nhi duyệt trước khi phát hành.',
              style: GB.body(11, color: GB.inkMuted, height: 1.4),
            ),
          ],
        );
      },
    );
  }

  // ───────── Bé đang ở đâu
  Widget _statusCard(LeapState st, bool preterm) {
    final String big, sub;
    if (st.current != null) {
      final l = st.current!;
      big = 'Đang gần bước nhảy ${l.n}';
      sub = 'Bé khoảng ${_w(st.weeks)} tuần tuổi, tuần ${l.week} là bước "${l.name}". Bé có thể quấy, bám mẹ và ngủ chập chờn hơn vài ngày đến vài tuần. Mẹ cố lên nhé.';
    } else if (st.next != null) {
      final l = st.next!;
      final toStart = (l.fussyFrom - st.weeks);
      final days = (toStart * 7).round();
      big = days <= 14 ? 'Sắp tới bước nhảy ${l.n}' : 'Bước nhảy kế tiếp: tuần ${l.week}';
      sub = 'Bé khoảng ${_w(st.weeks)} tuần tuổi. Giai đoạn có thể quấy hơn bắt đầu sau khoảng ${days <= 7 ? 'vài ngày' : '${(days / 7).round()} tuần'}. Hiện chưa phải lúc.';
    } else {
      big = 'Đã qua các bước nhảy đầu đời';
      sub = 'Bé khoảng ${_w(st.weeks)} tuần tuổi. Bé vẫn tiếp tục học những điều mới, mỗi bé một nhịp riêng.';
    }
    return SectionCard(
      title: 'Bé đang ở đâu?',
      icon: Icons.child_care_rounded,
      iconColor: GB.pumpDeep,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(big, style: GB.display(20, color: GB.title)),
        const SizedBox(height: 6),
        Text(sub, style: GB.body(13.5, height: 1.45)),
        if (preterm) ...[
          const SizedBox(height: 8),
          Text('Bé sinh non nên mốc tuần được tính theo tuổi hiệu chỉnh.', style: GB.body(12, color: GB.inkMuted)),
        ],
      ]),
    );
  }

  // ───────── Đối chiếu với dữ liệu của bé
  Widget _dataCard() {
    final now = DateTime.now();
    final cur = Stats.week(app, now);
    final prev = Stats.week(app, now.subtract(const Duration(days: 7)));
    final hasCur = cur.any((d) => d.hasData);
    final hasPrev = prev.any((d) => d.hasData);
    final sleep = Stats.avgOf(cur, (d) => d.sleepHours);
    final sleepPrev = Stats.avgOf(prev, (d) => d.sleepHours);
    final feeds = Stats.avgOf(cur, (d) => d.feedCount.toDouble());
    final feedsPrev = Stats.avgOf(prev, (d) => d.feedCount.toDouble());
    final today = AppState.dayStart(now);
    final fussyToday = app.isFussy(today);
    final fussyWeek = cur.where((d) => app.isFussy(d.day)).length;

    String cmp(double a, double b, String unit, {int dec = 1}) {
      final d = a - b;
      if (d.abs() < (dec == 0 ? .5 : .1)) return 'gần như không đổi';
      final v = dec == 0 ? d.abs().round().toString() : GB.num1(d.abs());
      return '${d > 0 ? 'nhiều hơn' : 'ít hơn'} $v $unit';
    }

    Widget line(IconData ic, Color c, String text) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            IconBadge(icon: ic, bg: c.withValues(alpha: .2), fg: c, size: 30),
            const SizedBox(width: 10),
            Expanded(child: Padding(padding: const EdgeInsets.only(top: 5), child: Text(text, style: GB.body(13.5, height: 1.35)))),
          ]),
        );

    return SectionCard(
      title: 'Tuần này của bé',
      icon: Icons.insights_rounded,
      iconColor: GB.bottleDeep,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (!hasCur)
          Text('Tuần này chưa có dữ liệu. Ghi bú, ngủ, tã để GinBaby đối chiếu với giai đoạn hiện tại.', style: GB.body(13.5, color: GB.inkMuted, height: 1.4))
        else ...[
          line(Icons.bedtime_rounded, GB.sleepDeep, 'Ngủ trung bình ${GB.num1(sleep)} giờ mỗi ngày${hasPrev ? ', ${cmp(sleep, sleepPrev, 'giờ')} so với tuần trước' : ''}.'),
          line(Icons.local_drink_rounded, GB.breastDeep, 'Khoảng ${feeds.round()} cữ bú mỗi ngày${hasPrev ? ', ${cmp(feeds, feedsPrev, 'cữ', dec: 0)} so với tuần trước' : ''}.'),
          line(Icons.sentiment_dissatisfied_rounded, GB.pumpDeep, fussyWeek == 0 ? 'Chưa đánh dấu ngày nào bé quấy trong tuần này.' : 'Đã đánh dấu $fussyWeek ngày bé quấy trong tuần này.'),
        ],
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: PillChip(
            label: fussyToday ? 'Hôm nay đã đánh dấu bé quấy (bấm để bỏ)' : 'Đánh dấu hôm nay bé quấy',
            on: fussyToday,
            height: 40,
            color: GB.pumpDeep,
            onTap: () {
              app.toggleFussy(today);
              toast(context, app.isFussy(today) ? 'Đã đánh dấu hôm nay bé quấy' : 'Đã bỏ đánh dấu');
            },
          ),
        ),
        const SizedBox(height: 8),
        Text('Thay đổi nhỏ trong giấc ngủ và cữ bú là bình thường. Chỉ nên lo khi bé bỏ bú, ít tã ướt, sốt hoặc lờ đờ.', style: GB.body(11.5, color: GB.inkMuted, height: 1.4)),
      ]),
    );
  }

  // ───────── Thẻ từng bước nhảy
  Widget _leapCard(Leap l, double weeks) {
    final label = leapStatusLabel(l, weeks);
    final isOpen = open == l.n;
    final inNow = label == 'Đang trong giai đoạn';
    final past = label == 'Đã qua';
    final Color chipBg = inNow ? GB.accentSoft : (past ? GB.okBg : GB.infoBg);
    final Color chipFg = inNow ? GB.accentDeep : (past ? GB.ok : GB.info);

    Widget group(String title, IconData ic, Color c, List<String> items) => Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Icon(ic, size: 18, color: c), const SizedBox(width: 6), Text(title, style: GB.body(13.5, w: FontWeight.w800))]),
            const SizedBox(height: 6),
            for (final t in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 2),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Padding(padding: const EdgeInsets.only(top: 7), child: Container(width: 5, height: 5, decoration: BoxDecoration(color: c, shape: BoxShape.circle))),
                  const SizedBox(width: 8),
                  Expanded(child: Text(t, style: GB.body(13, height: 1.4))),
                ]),
              ),
          ]),
        );

    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.all(14),
      tint: inNow ? GB.p(Color(0xFFFFF1F0)) : null,
      onTap: () => setState(() => open = isOpen ? null : l.n),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: GB.bottleTile, shape: BoxShape.circle),
            child: Text('${l.n}', style: GB.display(16, color: GB.title)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Tuần ${l.week}', style: GB.body(12, color: GB.inkMuted)),
              Text(l.name, style: GB.body(14.5, w: FontWeight.w800, height: 1.2)),
            ]),
          ),
          const SizedBox(width: 6),
          Tag(label, bg: chipBg, fg: chipFg),
          Icon(isOpen ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: GB.inkMuted),
        ]),
        if (isOpen) ...[
          const SizedBox(height: 10),
          Text(l.summary, style: GB.body(13.5, height: 1.45)),
          const SizedBox(height: 4),
          Text('Giai đoạn có thể quấy hơn: khoảng tuần ${l.fussyFrom == l.fussyFrom.roundToDouble() ? l.fussyFrom.round() : GB.num1(l.fussyFrom)} đến ${l.week}, mỗi bé một khác.', style: GB.body(12, color: GB.inkMuted, height: 1.35)),
          group('Bé có thể học được', Icons.auto_awesome_rounded, GB.sleepDeep, l.skills),
          group('Dấu hiệu thường gặp', Icons.sentiment_neutral_rounded, GB.breastDeep, l.signs),
          group('Mẹ có thể làm', Icons.favorite_rounded, GB.pumpDeep, l.tips),
        ],
      ]),
    );
  }

  Widget _confusable(Confusable c) => GlassCard(
        radius: 22,
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(c.title, style: GB.body(14.5, w: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(c.when, style: GB.body(12, color: GB.accentDeep, w: FontWeight.w700, height: 1.3)),
          const SizedBox(height: 6),
          Text(c.what, style: GB.body(13, height: 1.4)),
          const SizedBox(height: 4),
          Text(c.help, style: GB.body(12.5, color: GB.inkMuted, height: 1.4)),
        ]),
      );
}
