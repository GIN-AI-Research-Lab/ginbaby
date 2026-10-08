import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/kit.dart';
import '../core/theme.dart';
import '../data/app_state.dart';
import '../data/models.dart';

/// Gia đình cùng ghi (bản thử): quản lý người thân và quyền. Đồng bộ giữa các máy cần máy chủ hoặc iCloud, chưa bật.
class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  String code = _newCode();
  int role = 0;

  static String _newCode() {
    const c = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = math.Random();
    return List.generate(6, (_) => c[r.nextInt(c.length)]).join();
  }

  static const _roles = [('owner', 'Chủ'), ('edit', 'Được ghi'), ('view', 'Chỉ xem')];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        return SubPage(
          title: 'Gia đình cùng ghi',
          subtitle: 'Mẹ bận thì ba ghi thay',
          art: 'hero_mom_baby',
          artWidth: 110,
          children: [
            const Callout(level: Level.note, title: 'Bản thử: chưa đồng bộ giữa các máy', body: 'Để mẹ và ba ghi trên hai điện thoại và thấy nhau ngay, app cần đồng bộ qua iCloud (CloudKit) hoặc máy chủ. Phần đó chưa bật trong bản thử. Hiện mẹ có thể dùng chung một máy, hoặc xuất/khôi phục tệp sao lưu trong Cài đặt.'),
            const SectionTitle('Thành viên'),
            GlassCard(
              radius: 24,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Column(children: [
                for (final m in app.members)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(children: [
                      Container(width: 42, height: 42, alignment: Alignment.center, decoration: BoxDecoration(color: m.role == 'owner' ? GB.accent : GB.p(Color(0xFFE3E6F6)), shape: BoxShape.circle), child: Text(m.name.characters.first.toUpperCase(), style: GB.display(18))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(m.name, style: GB.body(15, w: FontWeight.w800)),
                          Text(_roles.firstWhere((r) => r.$1 == m.role).$2 == 'Chủ' ? 'Chủ · toàn quyền' : _roles.firstWhere((r) => r.$1 == m.role).$2, style: GB.body(12, color: GB.inkMuted)),
                        ]),
                      ),
                      if (m.role != 'owner')
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded),
                          color: GB.cream,
                          onSelected: (v) {
                            if (v == 'del') {
                              app.removeMember(m);
                            } else {
                              m.role = v;
                              app.membersChanged();
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'edit', child: Text('Được ghi')),
                            const PopupMenuItem(value: 'view', child: Text('Chỉ xem')),
                            const PopupMenuItem(value: 'del', child: Text('Xoá khỏi nhóm')),
                          ],
                        ),
                    ]),
                  ),
              ]),
            ),
            const SectionTitle('Mời người thân'),
            GlassCard(
              radius: 24,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Quyền của người mới', style: GB.body(13, w: FontWeight.w700, color: GB.inkMuted)),
                const SizedBox(height: 8),
                Seg(labels: const ['Được ghi', 'Chỉ xem'], index: role, height: 42, onChanged: (i) => setState(() => role = i)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: Text(code, style: GB.display(34))),
                  RoundIconButton(icon: Icons.copy_rounded, label: 'Sao chép mã', onTap: () {
                    Clipboard.setData(ClipboardData(text: code));
                    toast(context, 'Đã sao chép mã mời');
                  }),
                ]),
                Text('Mã mời để dùng khi bật đồng bộ. Mã đổi mỗi lần tạo mới.', style: GB.body(12, color: GB.inkMuted)),
                const SizedBox(height: 10),
                BigButton('Tạo mã mới', icon: Icons.refresh_rounded, color: GB.w(.7), fg: GB.ink, height: 46, onTap: () => setState(() => code = _newCode())),
                const SizedBox(height: 8),
                BigButton('Thêm người thân (cục bộ)', icon: Icons.person_add_rounded, height: 46, onTap: _add),
              ]),
            ),
            const SizedBox(height: 12),
            const Callout(level: Level.info, title: 'Phần riêng tư', body: 'Góc của mẹ (tâm trạng, tự kiểm tra) luôn riêng tư, không chia sẻ cho thành viên khác. Mẹ chọn ai được xem mục Tiền của bé trong tương lai.'),
          ],
        );
      },
    );
  }

  void _add() {
    final n = TextEditingController();
    showGlassSheet(context, builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Thêm người thân', style: GB.display(22, w: FontWeight.w700)),
          const SizedBox(height: 12),
          GlassField(controller: n, label: 'Tên (Ba, Bà ngoại…)'),
          const SizedBox(height: 14),
          BigButton('Thêm', icon: Icons.check_rounded, onTap: () {
            if (n.text.trim().isEmpty) return;
            app.addMember(Member(name: n.text.trim(), role: role == 0 ? 'edit' : 'view'));
            Navigator.pop(ctx);
          }),
        ]));
  }
}
