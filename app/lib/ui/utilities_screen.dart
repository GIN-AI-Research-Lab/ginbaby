import 'package:flutter/material.dart';

import '../core/kit.dart';
import '../core/theme.dart';
import '../data/app_state.dart';
import 'features.dart';

String _fold(String s) {
  const from = 'àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ';
  const to = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
  final b = StringBuffer();
  for (final c in s.toLowerCase().split('')) {
    final i = from.indexOf(c);
    b.write(i >= 0 ? to[i] : c);
  }
  return b.toString();
}

/// Tab Tiện ích: toàn bộ chức năng của app chia theo nhóm, có ô tìm kiếm và mục ghim nhanh.
class UtilitiesTab extends StatefulWidget {
  const UtilitiesTab({super.key, required this.goTab});
  final void Function(int) goTab;

  @override
  State<UtilitiesTab> createState() => _UtilitiesTabState();
}

class _UtilitiesTabState extends State<UtilitiesTab> {
  final search = TextEditingController();
  String q = '';

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Widget _tile(Feature f) => GlassCard(
        radius: 20,
        padding: const EdgeInsets.all(12),
        onTap: () => openFeature(context, f, widget.goTab),
        child: Row(children: [
          FeatureBadge(f, size: 44),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(f.title, maxLines: 2, style: GB.body(13.5, w: FontWeight.w800, height: 1.2)),
              if (f.sub != null) Text(f.sub!(), maxLines: 2, overflow: TextOverflow.ellipsis, style: GB.body(11, color: GB.inkMuted, height: 1.25)),
            ]),
          ),
        ]),
      );

  List<Widget> _grid(List<Feature> items) {
    final out = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      out.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(child: _tile(items[i])),
            const SizedBox(width: 10),
            Expanded(child: i + 1 < items.length ? _tile(items[i + 1]) : const SizedBox.shrink()),
          ]),
        ),
      ));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final key = _fold(q.trim());
        final favs = [for (final id in app.settings.favs) if (featureById(id) != null) featureById(id)!];
        return ListView(
          padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 16, 110),
          children: [
            Row(children: [
              Expanded(child: Text('Tiện ích', style: GB.display(30, color: GB.title))),
              RoundIconButton(icon: Icons.tune_rounded, label: 'Tuỳ chỉnh menu', size: 44, iconColor: GB.accentDeep, onTap: () => openPage(context, const MenuCustomizeScreen())),
            ]),
            const SizedBox(height: 2),
            Text('Tất cả chức năng của GinBaby, chia theo nhóm', style: GB.script(13.5)),
            const SizedBox(height: 12),
            GlassField(controller: search, label: 'Tìm chức năng', icon: Icons.search_rounded, onChanged: (v) => setState(() => q = v)),
            const SizedBox(height: 14),
            if (key.isEmpty && favs.isNotEmpty) ...[
              const FormHeader('Ghim nhanh', Icons.push_pin_rounded, color: Color(0xFFFCE0E2), hint: 'Chức năng mẹ dùng nhiều nhất'),
              SizedBox(
                height: 92,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: favs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) => SizedBox(
                    width: 84,
                    child: GlassCard(
                      radius: 20,
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                      onTap: () => openFeature(context, favs[i], widget.goTab),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        FeatureBadge(favs[i], size: 38),
                        const SizedBox(height: 5),
                        FittedBox(fit: BoxFit.scaleDown, child: Text(favs[i].title, maxLines: 1, style: GB.body(11.5, w: FontWeight.w800))),
                      ]),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            for (final c in kFeatureCats) ...[
              Builder(builder: (_) {
                final items = [
                  for (final f in kFeatures)
                    if (f.cat == c.id && (key.isEmpty || _fold('${f.title} ${f.sub?.call() ?? ''}').contains(key))) f,
                ];
                if (items.isEmpty) return const SizedBox.shrink();
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  FormHeader(c.title, c.icon, color: c.color),
                  ..._grid(items),
                  const SizedBox(height: 6),
                ]);
              }),
            ],
            if (key.isEmpty) ...[
              const FormHeader('Sắp có', Icons.hourglass_top_rounded, color: Color(0xFFE3E6F6)),
              _soon(Icons.chat_bubble_rounded, 'Hỏi Gin (trợ lý AI)', 'Cần máy chủ và duyệt y khoa'),
              const SizedBox(height: 10),
              _soon(Icons.forum_rounded, 'Cộng đồng: nhóm chat, kênh tin', 'Cần máy chủ và kiểm duyệt'),
            ],
          ],
        );
      },
    );
  }

  Widget _soon(IconData icon, String title, String sub) => GlassCard(
        radius: 20,
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: GB.line.withValues(alpha: .6), shape: BoxShape.circle), child: Icon(icon, color: GB.inkMuted)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: GB.body(13.5, w: FontWeight.w800, color: GB.inkMuted)),
              Text(sub, style: GB.body(11, color: GB.inkMuted)),
            ]),
          ),
          const Tag('Làm sau'),
        ]),
      );
}

/// Chọn một chức năng từ danh sách theo nhóm; trả về mã chức năng.
class FeaturePickerScreen extends StatelessWidget {
  const FeaturePickerScreen({super.key, required this.title, this.selected = const {}, this.exclude = const {}});
  final String title;
  final Set<String> selected;
  final Set<String> exclude;

  @override
  Widget build(BuildContext context) {
    return SubPage(
      title: title,
      children: [
        for (final c in kFeatureCats) ...[
          Builder(builder: (_) {
            final items = [for (final f in kFeatures) if (f.cat == c.id && !exclude.contains(f.id)) f];
            if (items.isEmpty) return const SizedBox.shrink();
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              FormHeader(c.title, c.icon, color: c.color),
              GlassCard(
                radius: 22,
                padding: EdgeInsets.zero,
                child: Column(children: [
                  for (var i = 0; i < items.length; i++)
                    Pressable(
                      scale: .99,
                      onTap: () => Navigator.of(context).pop(items[i].id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(border: i == 0 ? null : Border(top: BorderSide(color: GB.line.withValues(alpha: .6)))),
                        child: Row(children: [
                          FeatureBadge(items[i], size: 38),
                          const SizedBox(width: 12),
                          Expanded(child: Text(items[i].title, style: GB.body(14, w: FontWeight.w700))),
                          if (selected.contains(items[i].id)) Icon(Icons.check_circle_rounded, color: GB.accent),
                        ]),
                      ),
                    ),
                ]),
              ),
              const SizedBox(height: 14),
            ]);
          }),
        ],
      ],
    );
  }
}

/// Tuỳ chỉnh: ba nút giữa của thanh dưới và danh sách ghim nhanh (kéo để sắp xếp).
class MenuCustomizeScreen extends StatefulWidget {
  const MenuCustomizeScreen({super.key});

  @override
  State<MenuCustomizeScreen> createState() => _MenuCustomizeScreenState();
}

class _MenuCustomizeScreenState extends State<MenuCustomizeScreen> {
  Future<void> _pickSlot(int i) async {
    final s = app.settings;
    final id = await Navigator.of(context).push<String>(MaterialPageRoute(
      builder: (_) => FeaturePickerScreen(title: 'Chọn nút ${i + 1} cho thanh dưới', selected: {s.footer[i]}, exclude: {'profile', for (var j = 0; j < s.footer.length; j++) if (j != i) s.footer[j]}),
    ));
    if (id == null) return;
    final next = [...s.footer];
    next[i] = id;
    s.footer = next;
    app.settingsChanged();
  }

  Future<void> _addFav() async {
    final s = app.settings;
    final id = await Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => FeaturePickerScreen(title: 'Thêm vào ghim nhanh', exclude: s.favs.toSet())));
    if (id == null) return;
    s.favs = [...s.favs, id];
    app.settingsChanged();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final s = app.settings;
        final favs = [for (final id in s.favs) if (featureById(id) != null) featureById(id)!];
        return SubPage(
          title: 'Tuỳ chỉnh menu',
          subtitle: 'Chọn nút trên thanh dưới và sắp xếp mục ghim nhanh',
          actions: [
            RoundIconButton(icon: Icons.restart_alt_rounded, label: 'Về mặc định', size: 44, onTap: () {
              s.footer = const ['history', 'stats', 'money'];
              s.favs = const ['pump', 'breast', 'bottle', 'sleep'];
              app.settingsChanged();
              toast(context, 'Đã đưa menu về mặc định');
            }),
          ],
          children: [
            GlassCard(
              radius: 24,
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const FormHeader('Thanh dưới', Icons.dock_rounded, color: Color(0xFFE6DEF5), hint: 'Trang chủ, Tiện ích và Hồ sơ luôn có. Chọn ba nút ở giữa'),
                for (var i = 0; i < s.footer.length; i++) ...[
                  Builder(builder: (_) {
                    final f = featureById(s.footer[i]);
                    return Pressable(
                      scale: .98,
                      onTap: () => _pickSlot(i),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(color: GB.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: GB.edgeOf(GB.line), width: 1.3)),
                        child: Row(children: [
                          Text('${i + 1}', style: GB.display(18, color: GB.accentDeep)),
                          const SizedBox(width: 12),
                          if (f != null) FeatureBadge(f, size: 36),
                          const SizedBox(width: 10),
                          Expanded(child: Text(f?.title ?? 'Chưa chọn', style: GB.body(14.5, w: FontWeight.w700))),
                          Text('Đổi', style: GB.body(13, w: FontWeight.w700, color: GB.accentDeep)),
                        ]),
                      ),
                    );
                  }),
                ],
              ]),
            ),
            const SizedBox(height: 12),
            GlassCard(
              radius: 24,
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                FormHeader('Ghim nhanh', Icons.push_pin_rounded, color: const Color(0xFFFCE0E2), hint: 'Kéo biểu tượng bên phải để sắp xếp', trailing: PillChip(label: 'Thêm', on: false, icon: Icons.add_rounded, iconColor: GB.accentDeep, height: 34, onTap: _addFav)),
                if (favs.isEmpty)
                  Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('Chưa có mục nào. Bấm Thêm để ghim chức năng hay dùng.', style: GB.body(12.5, color: GB.inkMuted)))
                else
                  ReorderableListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    onReorder: (a, b) {
                      final l = [...s.favs];
                      if (b > a) b--;
                      final it = l.removeAt(a);
                      l.insert(b, it);
                      s.favs = l;
                      app.settingsChanged();
                    },
                    children: [
                      for (var i = 0; i < favs.length; i++)
                        Container(
                          key: ValueKey(favs[i].id),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                          decoration: BoxDecoration(color: GB.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: GB.edgeOf(GB.line), width: 1.3)),
                          child: Row(children: [
                            FeatureBadge(favs[i], size: 36),
                            const SizedBox(width: 10),
                            Expanded(child: Text(favs[i].title, style: GB.body(14, w: FontWeight.w700))),
                            IconButton(
                              icon: Icon(Icons.remove_circle_outline_rounded, color: GB.alert),
                              tooltip: 'Bỏ ghim',
                              onPressed: () {
                                s.favs = [for (final id in s.favs) if (id != favs[i].id) id];
                                app.settingsChanged();
                              },
                            ),
                            ReorderableDragStartListener(index: i, child: Padding(padding: const EdgeInsets.all(8), child: Icon(Icons.drag_indicator_rounded, color: GB.inkMuted))),
                          ]),
                        ),
                    ],
                  ),
              ]),
            ),
          ],
        );
      },
    );
  }
}
