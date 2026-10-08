import 'package:flutter/material.dart';

import '../core/kit.dart';
import '../core/theme.dart';
import '../domain/articles.dart';

/// Cẩm nang cho mẹ: bài ngắn có nguồn tham khảo.
class ArticlesScreen extends StatefulWidget {
  const ArticlesScreen({super.key});

  @override
  State<ArticlesScreen> createState() => _ArticlesScreenState();
}

class _ArticlesScreenState extends State<ArticlesScreen> {
  String cat = 'Tất cả';
  final q = TextEditingController();

  @override
  void dispose() {
    q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = q.text.trim().toLowerCase();
    final list = kArticles.where((a) => (cat == 'Tất cả' || a.cat == cat) && (query.isEmpty || a.title.toLowerCase().contains(query) || a.summary.toLowerCase().contains(query) || a.sections.any((s) => s.$2.any((t) => t.toLowerCase().contains(query))))).toList();
    return SubPage(
      title: 'Cẩm nang',
      subtitle: '${kArticles.length} bài · có nguồn tham khảo',
      art: 'hero_mom_baby',
      artWidth: 110,
      children: [
        GlassField(controller: q, label: 'Tìm trong cẩm nang', onChanged: (_) => setState(() {})),
        const SizedBox(height: 10),
        SizedBox(
          height: 44,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            for (final c in kArticleCats) ...[PillChip(label: c, on: cat == c, height: 44, onTap: () => setState(() => cat = c)), const SizedBox(width: 8)],
          ]),
        ),
        const SizedBox(height: 10),
        if (list.isEmpty) const GlassCard(child: EmptyState('Không có bài phù hợp.')),
        for (final a in list)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              radius: 22,
              tint: a.urgent ? GB.alertBg : null,
              opacity: a.urgent ? .8 : .5,
              onTap: () => openPage(context, ArticleDetail(a)),
              child: Row(children: [
                Orb(icon: a.urgent ? Icons.warning_amber_rounded : Icons.menu_book_rounded, color: a.urgent ? const Color(0xFFF0B5B9) : GB.p(Color(0xFFFBE3CF)), size: 42),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(a.title, style: GB.body(15, w: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(a.summary, style: GB.body(12.5, color: GB.inkMuted, height: 1.3)),
                    const SizedBox(height: 6),
                    Row(children: [Flexible(child: Tag(a.cat)), const SizedBox(width: 6), Flexible(child: Text('${a.minutes} phút đọc', maxLines: 1, overflow: TextOverflow.ellipsis, style: GB.body(11.5, color: GB.inkMuted)))]),
                  ]),
                ),
                Icon(Icons.chevron_right_rounded, color: GB.inkMuted),
              ]),
            ),
          ),
        const SizedBox(height: 4),
        Text('Nội dung mang tính tham khảo, cần bác sĩ/chuyên gia dinh dưỡng duyệt trước khi phát hành. Không thay thế tư vấn y tế.', style: GB.body(11.5, color: GB.inkMuted, height: 1.4)),
      ],
    );
  }
}

class ArticleDetail extends StatelessWidget {
  const ArticleDetail(this.a, {super.key});
  final Article a;

  @override
  Widget build(BuildContext context) {
    return SubPage(
      title: a.title,
      subtitle: a.cat,
      children: [
        if (a.urgent) const Callout(level: Level.alert, title: 'Khẩn cấp', body: 'Nếu bé hoặc mẹ có các dấu hiệu dưới đây, hãy đi khám hoặc gọi cấp cứu 115 ngay.'),
        if (a.urgent) const SizedBox(height: 12),
        for (final s in a.sections) ...[
          SectionTitle(s.$1, padTop: 12),
          GlassCard(
            radius: 22,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (final t in s.$2)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Padding(padding: const EdgeInsets.only(top: 7, right: 10), child: Container(width: 6, height: 6, decoration: BoxDecoration(color: GB.accent, shape: BoxShape.circle))),
                    Expanded(child: Text(t, style: GB.body(14, height: 1.5))),
                  ]),
                ),
            ]),
          ),
        ],
        const SizedBox(height: 14),
        Callout(level: Level.info, title: 'Nguồn tham khảo', body: a.source),
        const SizedBox(height: 8),
        Text('Cần chuyên gia duyệt trước khi phát hành. Không thay thế tư vấn của bác sĩ.', style: GB.body(11.5, color: GB.inkMuted)),
      ],
    );
  }
}
