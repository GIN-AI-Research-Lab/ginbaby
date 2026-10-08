import 'package:flutter/material.dart';

import '../core/kit.dart';
import '../core/theme.dart';
import '../data/app_state.dart';

/// Màn giới thiệu Free / Premium (bản thử: chưa tính phí, chưa khoá tính năng).
class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  static const _free = [
    'Ghi bú, ngủ, tã, hút sữa không giới hạn thời gian',
    'Đánh giá lượng sữa theo tuổi và cân nặng',
    'Nhắc giờ ngủ theo nhịp EASY',
    'Nhật ký, thống kê ngày/tuần/tháng',
    'Tiêm chủng, tăng trưởng WHO, cẩm nang',
    'Sao lưu và khôi phục tệp',
  ];

  static const _premium = [
    'Tủ sữa: hạn dùng, dùng trước, trừ hao tự động',
    'Mục tiêu và nhắc cữ hút theo nhu cầu của bé',
    'Thu chi cho con và Quỹ của con',
    'Thẻ tổng kết tuần/tháng đẹp để chia sẻ',
    'Gia đình cùng ghi và đồng bộ iCloud (khi bật)',
    'Tiếng ồn trắng không giới hạn thời gian',
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final on = app.settings.premium;
        return SubPage(
          title: 'GinBaby Premium',
          subtitle: 'Bản thử: mọi tính năng đang mở miễn phí',
          children: [
            GlassCard(
              radius: 26,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Miễn phí, không quảng cáo', style: GB.display(22, w: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Mẹ dùng các tính năng cơ bản mãi mãi, không có "dùng thử còn 1 ngày".', style: GB.body(13, color: GB.inkMuted)),
                const SizedBox(height: 10),
                for (final t in _free) _row(Icons.check_circle_rounded, GB.ok, t),
              ]),
            ),
            const SizedBox(height: 12),
            GlassCard(
              radius: 26,
              tint: GB.warnBg,
              opacity: .75,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Expanded(child: Text('Premium', style: GB.display(22, w: FontWeight.w700))), Tag('Sắp có', bg: Colors.white, fg: GB.warn)]),
                const SizedBox(height: 4),
                Text('Dành cho mẹ cần bộ sữa nâng cao, thu chi và chia sẻ gia đình.', style: GB.body(13, color: GB.warn)),
                const SizedBox(height: 10),
                for (final t in _premium) _row(Icons.star_rounded, GB.accentDeep, t),
              ]),
            ),
            const SizedBox(height: 12),
            GlassCard(
              radius: 22,
              child: Row(children: [
                Expanded(child: Text('Bật giao diện Premium (thử)', style: GB.body(14.5, w: FontWeight.w700))),
                Switch(value: on, activeThumbColor: GB.accent, onChanged: (v) {
                  app.settings.premium = v;
                  app.settingsChanged();
                }),
              ]),
            ),
            const SizedBox(height: 8),
            Text('Giá và hình thức (theo tháng, năm hoặc mua một lần) chưa được chốt. Việc thanh toán sẽ dùng StoreKit/Google Play khi phát hành, bản thử không thu tiền.', style: GB.body(11.5, color: GB.inkMuted, height: 1.4)),
          ],
        );
      },
    );
  }

  Widget _row(IconData i, Color c, String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(i, size: 20, color: c),
          const SizedBox(width: 10),
          Expanded(child: Text(t, style: GB.body(14, height: 1.4))),
        ]),
      );
}
