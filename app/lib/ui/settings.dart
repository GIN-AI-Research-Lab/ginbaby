import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/kit.dart';
import 'offline_screen.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../data/app_state.dart';
import '../data/demo.dart';
import '../data/models.dart';
import 'export_report.dart';
import 'onboarding.dart';
import 'premium.dart';

const kBuild = String.fromEnvironment('BUILD', defaultValue: 'dev');

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Widget _card(String title, List<Widget> children) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GlassCard(
          radius: 24,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GB.body(13, w: FontWeight.w700, color: GB.inkMuted)),
            const SizedBox(height: 8),
            ...children,
          ]),
        ),
      );

  Widget _switch(String label, String? sub, bool v, ValueChanged<bool> on) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: GB.body(14.5, w: FontWeight.w700)),
              if (sub != null) Text(sub, style: GB.body(12, color: GB.inkMuted, height: 1.35)),
            ]),
          ),
          Switch(value: v, activeThumbColor: GB.accent, onChanged: on),
        ]),
      );

  Widget _stepRow(String label, String value, VoidCallback minus, VoidCallback plus) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Expanded(child: Text(label, style: GB.body(14.5, w: FontWeight.w700))),
          RoundIconButton(icon: Icons.remove_rounded, label: 'Giảm $label', size: 40, onTap: minus),
          SizedBox(width: 64, child: Text(value, textAlign: TextAlign.center, style: GB.body(15, w: FontWeight.w800))),
          RoundIconButton(icon: Icons.add_rounded, label: 'Tăng $label', size: 40, filled: true, onTap: plus),
        ]),
      );

  Widget _action(String label, IconData icon, VoidCallback onTap, {Color? color}) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(children: [
            Icon(icon, size: 22, color: color ?? GB.ink),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: GB.body(14.5, w: FontWeight.w700, color: color ?? GB.ink))),
            Icon(Icons.chevron_right_rounded, color: GB.inkMuted),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final s = app.settings;
        final b = app.baby;
        return SubPage(
          title: 'Cài đặt',
          children: [
            if (b != null)
              _card('Hồ sơ bé', [
                Row(children: [
                  Container(width: 48, height: 48, alignment: Alignment.center, decoration: BoxDecoration(color: GB.accent, shape: BoxShape.circle), child: Text(b.name.characters.first.toUpperCase(), style: GB.display(24))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(b.name, style: GB.body(16, w: FontWeight.w800)),
                      Text('${app.age.label} · ${GB.num1(app.weightKg)}kg', style: GB.body(12.5, color: GB.inkMuted)),
                      Text('Sinh ${GB.dmyhm(b.dob)}${b.gestWeeks < 37 ? ' · sinh non ${b.gestWeeks} tuần' : ''}', style: GB.body(12, color: GB.inkMuted)),
                    ]),
                  ),
                ]),
                _action('Sửa hồ sơ bé', Icons.edit_rounded, () => openPage(context, const Onboarding(edit: true))),
              ]),
            GestureDetector(
              onTap: () => openPage(context, const PremiumScreen()),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  radius: 24,
                  tint: GB.warnBg,
                  opacity: .7,
                  child: Row(children: [
                    Orb(icon: Icons.star_rounded, color: GB.gold, size: 42),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('GinBaby Premium', style: GB.body(15, w: FontWeight.w800)),
                        Text('Miễn phí vs Premium', style: GB.body(12, color: GB.warn)),
                      ]),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ]),
                ),
              ),
            ),
            _card('Giao diện', [
              Seg(labels: const ['Theo máy', 'Sáng', 'Tối'], index: s.themeMode, height: 42, onChanged: (i) {
                s.themeMode = i;
                app.settingsChanged();
              }),
              const SizedBox(height: 6),
              Text('Hiệu ứng kính mờ', style: GB.body(14.5, w: FontWeight.w700)),
              const SizedBox(height: 6),
              Seg(labels: const ['Tắt', 'Nhẹ', 'Đầy đủ'], index: s.glassMode.clamp(0, 2), height: 42, onChanged: (i) {
                s.glassMode = i;
                app.settingsChanged();
              }),
              const SizedBox(height: 6),
              Text('Nhẹ: làm mờ thanh dưới và bảng popup, mượt nhất. Đầy đủ: làm mờ cả từng thẻ, đẹp hơn nhưng nặng, có thể giật trên máy cũ. Tắt: thẻ phẳng, nhẹ nhất.', style: GB.body(12, color: GB.inkMuted, height: 1.35)),
              const SizedBox(height: 10),
              Text('Chế độ tối dịu mắt khi cho bé bú ban đêm. Cũng có thể đổi nhanh bằng nút mặt trăng/mặt trời ở Trang chủ và Hồ sơ.', style: GB.body(12, color: GB.inkMuted, height: 1.35)),
            ]),
            _card('Cách ăn của bé', [
              Seg(labels: const ['Bú mẹ', 'Công thức', 'Kết hợp'], index: b?.mode.index ?? 2, height: 42, onChanged: (i) {
                b!.mode = FeedMode.values[i];
                app.saveBaby(b);
              }),
              const SizedBox(height: 6),
              Text('Dùng để chọn cách đánh giá lượng sữa và nhắc giờ hút.', style: GB.body(12, color: GB.inkMuted)),
            ]),
            _card('Hút sữa', [
              Text('Giờ hút mỗi ngày', style: GB.body(14.5, w: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Chạm để chọn các giờ mẹ thường hút. Số cữ mỗi ngày tính theo số giờ đã chọn, và dùng để nhắc cữ hút.', style: GB.body(12, color: GB.inkMuted, height: 1.35)),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (var h = 0; h < 24; h++)
                  PillChip(
                    label: '${h}h',
                    on: s.pumpTimes.contains(h),
                    height: 34,
                    hPad: 10,
                    onTap: () {
                      final t = [...s.pumpTimes];
                      if (t.contains(h)) {
                        if (t.length <= 2) {
                          toast(context, 'Giữ ít nhất 2 cữ hút mỗi ngày');
                          return;
                        }
                        t.remove(h);
                      } else {
                        t.add(h);
                      }
                      t.sort();
                      s.pumpTimes = t;
                      s.pumpSessions = t.length;
                      app.settingsChanged();
                    },
                  ),
              ]),
              const SizedBox(height: 4),
              Text('Đã chọn ${s.pumpTimes.length} cữ mỗi ngày', style: GB.body(12.5, w: FontWeight.w700, color: GB.accentDeep)),
              const SizedBox(height: 6),
              _stepRow('Mục tiêu từ sữa hút', '${s.pumpShare}%', () {
                if (s.pumpShare > 10) s.pumpShare -= 10;
                app.settingsChanged();
              }, () {
                if (s.pumpShare < 100) s.pumpShare += 10;
                app.settingsChanged();
              }),
              Text('Phần trăm nhu cầu sữa của bé muốn lấy từ sữa hút. Đặt 100% nếu mẹ hút hoàn toàn.', style: GB.body(12, color: GB.inkMuted, height: 1.35)),
            ]),
            _card('Nhịp EASY', [
              _switch('Tự chọn theo tuổi', 'App chọn E2.5 / E3 / E3.5 / E4 theo tuổi của bé', s.easyAuto, (v) {
                s.easyAuto = v;
                app.settingsChanged();
              }),
              if (!s.easyAuto)
                Seg(labels: const ['E2.5', 'E3', 'E3.5', 'E4'], index: const [25, 30, 35, 40].indexOf(s.easy < 10 ? s.easy * 10 : s.easy).clamp(0, 3), height: 42, onChanged: (i) {
                  s.easy = const [25, 30, 35, 40][i];
                  app.settingsChanged();
                }),
            ]),
            _card('Nhắc nhở', [
              _stepRow('Nhắc cữ bú sau', s.feedRemindHours == 0 ? 'Tắt' : '${s.feedRemindHours} giờ', () {
                if (s.feedRemindHours > 0) s.feedRemindHours--;
                app.settingsChanged();
              }, () {
                if (s.feedRemindHours < 6) s.feedRemindHours++;
                app.settingsChanged();
              }),
              Text('Nhắc khi đã qua số giờ này kể từ cữ bú gần nhất (hiện ở Trang chủ và thông báo).', style: GB.body(12, color: GB.inkMuted, height: 1.35)),
              const SizedBox(height: 6),
              _switch('Nhắc nhở trong app', 'Cữ hút, sữa sắp hết hạn, lịch hẹn', s.remind, (v) {
                s.remind = v;
                app.settingsChanged();
              }),
              if (kIsWebPlatform && notificationState() != 'unsupported')
                _switch('Thông báo của trình duyệt', 'Hiện khi GinBaby còn mở (kể cả tab nền): cữ hút, sữa sắp hết hạn, tiêm chủng, lịch hẹn. Bản iPhone sẽ nhắc cả khi đã đóng app.', s.notify && notificationState() == 'granted', (v) async {
                  if (v) {
                    final r = await requestNotifications();
                    if (r != 'granted') {
                      if (context.mounted) toast(context, r == 'denied' ? 'Trình duyệt đang chặn thông báo, hãy bật lại trong cài đặt trang web' : 'Chưa bật được thông báo');
                      return;
                    }
                    s.notify = true;
                    app.settingsChanged();
                    showNotification('GinBaby', 'Đã bật thông báo. Mẹ sẽ được nhắc khi đến giờ.', 'welcome');
                  } else {
                    s.notify = false;
                    app.settingsChanged();
                  }
                }),
            ]),
            _card('Sao lưu dữ liệu', [
              Text('Dữ liệu lưu trên máy này. Hãy xuất tệp sao lưu để tránh mất khi xoá dữ liệu trình duyệt hoặc đổi máy.', style: GB.body(12, color: GB.inkMuted, height: 1.4)),
              FutureBuilder(
                future: storageEstimate(),
                builder: (context, snap) {
                  final e = snap.data;
                  if (e == null) return const SizedBox.shrink();
                  String mb(int b) => b < 1024 * 1024 ? '${(b / 1024).round()} KB' : '${(b / 1048576).toStringAsFixed(1).replaceAll('.', ',')} MB';
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('Đã dùng ${mb(e.used)} trong kho dữ liệu (tối đa ~${mb(e.quota)}). ${app.usedPhotoIds.length} ảnh.', style: GB.body(12, w: FontWeight.w700, color: GB.accentDeep)),
                  );
                },
              ),
              _action('Xuất tệp sao lưu kèm ảnh (.json)', Icons.download_rounded, () async {
                final data = await app.exportAll();
                final bytes = Uint8List.fromList(utf8.encode(jsonEncode(data)));
                downloadBytes('ginbaby-${AppState.dayKey(DateTime.now())}.json', bytes, 'application/json');
                if (context.mounted) toast(context, kIsWebPlatform ? 'Đã tải tệp sao lưu (${(bytes.length / 1048576).toStringAsFixed(1)} MB)' : 'Chỉ hỗ trợ xuất trên bản web');
              }),
              _action('Khôi phục từ tệp', Icons.upload_rounded, () async {
                final t = await pickTextFile();
                if (t == null) return;
                try {
                  await app.importAll(Map<String, dynamic>.from(jsonDecode(t) as Map));
                  if (context.mounted) toast(context, 'Đã khôi phục dữ liệu');
                } catch (e) {
                  if (context.mounted) toast(context, 'Tệp không hợp lệ');
                }
              }),
            ]),
            if (kIsWebPlatform)
              _card('Chạy khi không có mạng', [
                Text('Kiểm tra GinBaby đã được lưu đủ trong điện thoại để mở khi mất mạng chưa. Mở app một lần khi có mạng và đợi khoảng 30 giây để app tự lưu.', style: GB.body(12, color: GB.inkMuted, height: 1.4)),
                _action('Kiểm tra chế độ ngoại tuyến', Icons.cloud_off_rounded, () => openPage(context, const OfflineScreen())),
              ]),
            _card('Xuất báo cáo', [
              Text('Mang cho bác sĩ nhi hoặc lưu trữ. Báo cáo mở trong trình duyệt, bấm "In hoặc lưu thành PDF".', style: GB.body(12, color: GB.inkMuted, height: 1.4)),
              _action('Báo cáo cho bác sĩ (in / PDF)', Icons.medical_information_rounded, () {
                final ok = exportDoctorReport();
                toast(context, ok ? 'Đã tải báo cáo, hãy mở tệp vừa tải' : 'Chỉ hỗ trợ xuất trên bản web');
              }),
              _action('Nhật ký dạng bảng (CSV, mở bằng Excel)', Icons.table_chart_rounded, () {
                final ok = exportCsv();
                toast(context, ok ? 'Đã tải tệp CSV' : 'Chỉ hỗ trợ xuất trên bản web');
              }),
            ]),
            _card('Dữ liệu thử', [
              _action('Nạp dữ liệu mẫu 14 ngày', Icons.science_rounded, () async {
                final ok = await confirmDialog(context, 'Nạp dữ liệu mẫu?', 'Dữ liệu hiện tại của bé sẽ được thay bằng dữ liệu mẫu.', ok: 'Nạp');
                if (ok) {
                  await seedDemo(app);
                  if (context.mounted) toast(context, 'Đã nạp dữ liệu mẫu');
                }
              }),
              _action('Xoá toàn bộ dữ liệu', Icons.delete_forever_rounded, () async {
                final ok = await confirmDialog(context, 'Xoá toàn bộ dữ liệu?', 'Mọi nhật ký, thu chi, quỹ và hồ sơ bé trên máy này sẽ bị xoá và không khôi phục được.');
                if (ok) {
                  await app.wipe();
                  if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
                }
              }, color: GB.alert),
            ]),
            _card('Về GinBaby', [
              Text('Bản thử · build $kBuild', style: GB.body(13, w: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('GinBaby không thay thế bác sĩ. Các khoảng tham khảo về lượng sữa, giấc ngủ, tiêm chủng và tăng trưởng dựa trên AAP, WHO, CDC, nghiên cứu đã công bố và tài liệu trong nước; cần chuyên gia nhi duyệt trước khi phát hành. Khi bé có dấu hiệu bất thường, hãy đưa bé đi khám.', style: GB.body(12, color: GB.inkMuted, height: 1.45)),
            ]),
          ],
        );
      },
    );
  }
}
