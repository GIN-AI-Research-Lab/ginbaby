import 'package:flutter/material.dart';

import '../core/kit.dart';
import '../core/pastel.dart';
import '../core/theme.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import 'quick_logs.dart';
import 'widgets.dart';

/// Màu, kết cấu và lượng phân kèm tranh minh hoạ (assets/art).
const kPoopColors = <(String label, String art, Color dot)>[
  ('Vàng', 'poop_yellow', Color(0xFFE3B93C)),
  ('Vàng nâu', 'poop_mustard', Color(0xFFC9972B)),
  ('Xanh rêu', 'poop_green', Color(0xFF6E8F3A)),
  ('Nâu', 'poop_brown', Color(0xFF8A5A3C)),
  ('Đen', 'poop_black', Color(0xFF2B2623)),
  ('Có nhầy', 'poop_mucus', Color(0xFFE8E4C8)),
  ('Bạc', 'poop_silver', Color(0xFFD9D9D9)),
  ('Máu', 'poop_blood', Color(0xFFA3262A)),
];
const kPoopTextures = <(String label, String art)>[
  ('Lỏng', 'tex_liquid'),
  ('Sệt', 'tex_soft'),
  ('Sệt hạt', 'tex_chunky'),
  ('Đặc', 'tex_hard'),
  ('Có bọt', 'tex_foam'),
];
const kDiaperAmounts = <(String label, String art)>[
  ('Ít', 'diaper_few'),
  ('Vừa', 'diaper_mid'),
  ('Nhiều', 'diaper_lots'),
];

String? poopArt(String color) {
  final c = color == 'Xanh' ? 'Xanh rêu' : color;
  for (final k in kPoopColors) {
    if (k.$1 == c) return k.$2;
  }
  return null;
}

String? textureArt(String t) {
  for (final k in kPoopTextures) {
    if (k.$1 == t) return k.$2;
  }
  return null;
}

String? amountArt(String t) {
  for (final k in kDiaperAmounts) {
    if (k.$1 == t) return k.$2;
  }
  return null;
}

/// Đánh giá nhẹ nhàng đặc điểm phân (tham khảo, không thay bác sĩ).
class DiaperVerdict {
  const DiaperVerdict(this.level, this.title, this.body, this.pill);
  final Level level;
  final String title;
  final String body;
  final String pill;
}

DiaperVerdict diaperVerdict({required String kind, String color = '', String state = '', String amount = '', required int ageDays}) {
  if (kind == 'wet') {
    return const DiaperVerdict(Level.ok, 'Bình thường', 'Tã ướt cho thấy bé đang đủ nước.', 'Bình thường');
  }
  final blackOk = color == 'Đen' && ageDays < 4; // phân su
  if (color == 'Bạc') return const DiaperVerdict(Level.alert, 'Nên đưa bé đi khám sớm', 'Phân trắng hoặc bạc có thể là dấu hiệu bệnh gan mật, cần khám sớm.', 'Nên đi khám');
  if (color == 'Máu') return const DiaperVerdict(Level.alert, 'Nên đưa bé đi khám sớm', 'Phân có máu cần được bác sĩ kiểm tra.', 'Nên đi khám');
  if (color == 'Đen' && !blackOk) return const DiaperVerdict(Level.alert, 'Nên đưa bé đi khám sớm', 'Phân đen sau những ngày đầu cần được bác sĩ kiểm tra.', 'Nên đi khám');
  if (blackOk) return const DiaperVerdict(Level.info, 'Phân su', 'Vài ngày đầu bé thường đi phân đen/xanh đen (phân su), đây là bình thường.', 'Bình thường');
  if (state == 'Lỏng' && amount == 'Nhiều') return const DiaperVerdict(Level.note, 'Cần theo dõi', 'Phân lỏng và nhiều. Cho bé bú đủ và theo dõi số tã ướt. Hãy liên hệ bác sĩ nếu kéo dài hoặc bé mệt.', 'Cần theo dõi');
  if (state == 'Đặc' && amount == 'Ít') return const DiaperVerdict(Level.note, 'Cần theo dõi', 'Phân đặc và ít, có thể bé hơi táo. Theo dõi thêm vài ngày và hỏi bác sĩ nếu bé khó chịu.', 'Cần theo dõi');
  if (color == 'Xanh rêu' || color == 'Xanh') return const DiaperVerdict(Level.note, 'Cần theo dõi', 'Phân xanh thường gặp. Nếu kéo dài kèm quấy khóc hoặc bé bú kém, hãy hỏi bác sĩ.', 'Cần theo dõi');
  if (color == 'Có nhầy') return const DiaperVerdict(Level.note, 'Cần theo dõi', 'Phân có nhầy đôi khi gặp khi bé mọc răng hoặc cảm nhẹ. Theo dõi nếu nhiều hoặc kéo dài.', 'Cần theo dõi');
  return const DiaperVerdict(Level.ok, 'Bình thường', 'Đặc điểm phân của bé đang trong mức thường gặp.', 'Bình thường');
}

