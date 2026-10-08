/// "Tuần khủng hoảng" (Wonder Weeks) và các giai đoạn dễ nhầm.
///
/// Nguồn: Hetty van de Rijt và Frans Plooij, "The Wonder Weeks" (xem https://en.wikipedia.org/wiki/The_Wonder_Weeks).
/// Cơ sở khoa học còn hạn chế (nghiên cứu nhỏ, các nhà chuyên môn còn tranh luận), chỉ dùng để tham khảo và trấn an.
/// Mốc tính theo tuổi từ ngày dự sinh (với bé sinh non dùng tuổi hiệu chỉnh). Cần chuyên gia nhi duyệt trước khi phát hành.
class Leap {
  const Leap({
    required this.n,
    required this.week,
    required this.fussyFrom,
    required this.name,
    required this.summary,
    required this.skills,
    required this.signs,
    required this.tips,
  });

  final int n;
  final int week; // tuần của bước nhảy
  final double fussyFrom; // tuần bắt đầu giai đoạn có thể quấy hơn (ước lượng)
  final String name;
  final String summary;
  final List<String> skills;
  final List<String> signs;
  final List<String> tips;

  double get fussyTo => week + .5;
}

const kLeaps = <Leap>[
  Leap(
    n: 1,
    week: 5,
    fussyFrom: 4.5,
    name: 'Thế giới của các giác quan',
    summary: 'Bé bắt đầu cảm nhận ánh sáng, âm thanh, mùi và cái chạm rõ nét hơn, nên dễ bị "choáng ngợp".',
    skills: ['Nhìn chăm vào mặt mẹ lâu hơn', 'Giật mình hoặc quay đầu theo tiếng động', 'Nhận ra mùi và giọng của mẹ rõ hơn'],
    signs: ['Khóc nhiều hơn, khó dỗ', 'Bú thất thường, đòi bú liên tục', 'Ngủ chập chờn, muốn được bế'],
    tips: ['Ôm ấp, da kề da, giữ không gian yên tĩnh', 'Hạn chế quá nhiều người và tiếng ồn cùng lúc', 'Giữ nhịp ăn và ngủ đều'],
  ),
  Leap(
    n: 2,
    week: 8,
    fussyFrom: 7.5,
    name: 'Thế giới của các hoa văn',
    summary: 'Bé nhận ra những hình dạng và hoa văn đơn giản, kể cả đôi bàn tay của mình.',
    skills: ['Nhìn chăm vào bàn tay và đồ vật có hoa văn', 'Cười đáp lại và "ê a" nhiều hơn', 'Cử động tay chân có chủ ý hơn'],
    signs: ['Bám mẹ, hay đòi bế', 'Ngủ ngắn hơn, dễ thức giấc', 'Quấy vào buổi chiều tối'],
    tips: ['Chơi với hình tương phản đen trắng, nói chuyện và hát cho bé', 'Cho bé nằm sấp có mẹ bên cạnh', 'Nghỉ ngơi khi có người phụ giúp'],
  ),
  Leap(
    n: 3,
    week: 12,
    fussyFrom: 11.5,
    name: 'Thế giới của những chuyển động mượt mà',
    summary: 'Cử động của bé mượt hơn, bé nhận ra các chuyển động và sự thay đổi diễn ra từ từ.',
    skills: ['Nhìn theo vật di chuyển chậm', 'Giữ đầu vững hơn khi nằm sấp', 'Phát ra âm thanh có điệu hơn, cười thành tiếng'],
    signs: ['Hay khóc vô cớ, thích được bế', 'Bú ít hoặc xao nhãng khi bú', 'Giấc ngủ ngắn hơn bình thường'],
    tips: ['Cho bé theo dõi đồ chơi di chuyển, lắc nhẹ cho bé nhìn theo', 'Bú ở nơi yên tĩnh để bé tập trung', 'Giữ lịch EASY linh hoạt, không ép'],
  ),
  Leap(
    n: 4,
    week: 19,
    fussyFrom: 14.5,
    name: 'Thế giới của các sự kiện',
    summary: 'Bé hiểu một chuỗi hành động ngắn dẫn đến kết quả (với tay, chạm, đổ). Giai đoạn này thường kéo dài hơn các bước trước.',
    skills: ['Với và nắm đồ vật có mục đích', 'Lật, xoay người, tập bò', 'Hiểu "cái này dẫn tới cái kia" (lắc thì kêu)'],
    signs: ['Dễ cáu, khóc nhiều trong vài tuần', 'Ngủ ngắn, thức giấc nhiều (đôi khi trùng với thoái lui giấc ngủ 4 tháng)', 'Bú nhiều hoặc bỏ cữ bất chợt'],
    tips: ['Dành thời gian chơi sàn, cho bé tự khám phá an toàn', 'Giữ giờ đi ngủ đều và thói quen ru ngủ quen thuộc', 'Mẹ thay phiên nghỉ ngơi, nhờ người thân'],
  ),
  Leap(
    n: 5,
    week: 26,
    fussyFrom: 22.5,
    name: 'Thế giới của các mối quan hệ',
    summary: 'Bé hiểu khoảng cách và mối quan hệ giữa người và vật, nên bắt đầu lo khi mẹ rời đi.',
    skills: ['Nhận ra khoảng cách (xa, gần, trong, ngoài)', 'Bắt đầu sợ người lạ, lo lắng khi xa mẹ', 'Bò, ngồi, với lấy đồ vật xa'],
    signs: ['Bám mẹ, khóc khi mẹ ra khỏi tầm nhìn', 'Giấc ngủ xáo trộn, hay thức đêm', 'Kén ăn hoặc đòi bú nhiều hơn'],
    tips: ['Chơi ú òa để bé hiểu mẹ vẫn ở đó', 'Chào tạm biệt rõ ràng, đừng lén rời đi', 'Kiên nhẫn: đây là dấu hiệu bé gắn bó an toàn'],
  ),
  Leap(
    n: 6,
    week: 37,
    fussyFrom: 33.5,
    name: 'Thế giới của các phân loại',
    summary: 'Bé bắt đầu phân loại: con vật, đồ vật, người quen và người lạ.',
    skills: ['Phân biệt các nhóm đồ vật, con vật đơn giản', 'Chỉ trỏ, bắt chước âm thanh', 'Bò và vịn đứng'],
    signs: ['Bám mẹ nhiều hơn, dễ khóc', 'Đòi được chú ý, hay cáu', 'Ngủ và ăn thất thường'],
    tips: ['Gọi tên đồ vật, đọc sách tranh cùng bé', 'Giữ thói quen quen thuộc để bé thấy an toàn', 'Cho bé thử nhiều chất liệu khi chơi'],
  ),
  Leap(
    n: 7,
    week: 46,
    fussyFrom: 41.5,
    name: 'Thế giới của các trình tự',
    summary: 'Bé hiểu các bước nối tiếp nhau, như xếp chồng, đóng mở, bỏ vào lấy ra.',
    skills: ['Xếp chồng, bỏ vào lấy ra, mở đóng đồ vật', 'Bắt chước hành động quen thuộc', 'Tập đứng, men theo đồ vật'],
    signs: ['Đòi bế, quấn mẹ', 'Dễ bực khi không làm được', 'Ngủ ngắn, thức dậy sớm'],
    tips: ['Cho bé chơi đồ vật xếp, hộp đựng đồ chơi an toàn', 'Khen ngợi khi bé cố gắng', 'Giữ lịch ngủ đều và đơn giản'],
  ),
  Leap(
    n: 8,
    week: 55,
    fussyFrom: 50.5,
    name: 'Thế giới của các chương trình',
    summary: 'Bé bắt đầu hiểu cả một "chương trình" hành động, như dọn dẹp, cho ăn, chải tóc, và muốn tự làm.',
    skills: ['Bắt chước việc nhà: lau, chải, nghe điện thoại', 'Muốn tự cầm thìa, tự làm', 'Đi men hoặc chập chững'],
    signs: ['Bướng hơn, đòi tự làm', 'Hay quấy và đòi mẹ', 'Ngủ chập chờn'],
    tips: ['Cho bé "phụ giúp" việc nhà vừa sức', 'Cho bé chọn giữa hai lựa chọn', 'Giữ bình tĩnh khi bé khóc ăn vạ'],
  ),
  Leap(
    n: 9,
    week: 64,
    fussyFrom: 59.5,
    name: 'Thế giới của các nguyên tắc',
    summary: 'Bé bắt đầu hiểu các nguyên tắc ứng xử và thử giới hạn của người lớn.',
    skills: ['Hiểu nhiều lời nói hơn, nói được vài từ', 'Biết nên hoặc không nên làm', 'Thử xem người lớn phản ứng thế nào'],
    signs: ['Hay giận dỗi, ăn vạ', 'Bám mẹ, sợ chia xa', 'Khó ngủ, đòi bế'],
    tips: ['Đặt giới hạn rõ ràng, nhất quán và nhẹ nhàng', 'Gọi tên cảm xúc ("con đang giận")', 'Dành thời gian gần gũi mỗi ngày'],
  ),
  Leap(
    n: 10,
    week: 75,
    fussyFrom: 71.5,
    name: 'Thế giới của các hệ thống',
    summary: 'Bé nhận ra mình là một cá nhân riêng, có cá tính, sở thích và ý muốn riêng.',
    skills: ['Nói "con", "của con", đòi tự quyết', 'Bắt đầu chơi giả vờ', 'Hiểu quy tắc, thứ tự đơn giản'],
    signs: ['Bướng, nói "không" nhiều', 'Khóc, ăn vạ khi không được ý', 'Thay đổi thói quen ăn ngủ'],
    tips: ['Cho bé quyền chọn trong khuôn khổ an toàn', 'Khen khi bé hợp tác', 'Kiên nhẫn, giữ nếp sinh hoạt'],
  ),
];

/// Các giai đoạn dễ bị nhầm với "khủng hoảng": bú tăng vọt và thoái lui giấc ngủ.
class Confusable {
  const Confusable(this.title, this.when, this.what, this.help);
  final String title;
  final String when;
  final String what;
  final String help;
}

const kConfusables = <Confusable>[
  Confusable('Bú tăng vọt (growth spurt)', 'Thường gặp khoảng 2–3 tuần, 6 tuần, 3 tháng và 6 tháng tuổi', 'Bé đòi bú dày hơn trong vài ngày, có thể bú sát cữ (bú dồn) và quấy vì đói.', 'Cho bú theo nhu cầu, nghỉ ngơi và uống đủ nước. Lượng sữa thường điều chỉnh sau 2–3 ngày. Hãy đi khám nếu bé bú kém, ít tã ướt hoặc sụt cân.'),
  Confusable('Thoái lui giấc ngủ', 'Hay gặp quanh 4 tháng, 8–10 tháng, 12 tháng và 18 tháng', 'Bé đang ngủ ổn bỗng thức giấc nhiều hơn, ngủ ngắn hơn, khó đi ngủ.', 'Giữ thói quen trước giờ ngủ, cho bé ngủ đủ giấc ngày và tránh đổi nhiều thứ cùng lúc. Thường qua sau vài tuần.'),
  Confusable('Mọc răng', 'Thường từ khoảng 4–10 tháng tuổi', 'Chảy dãi, gặm đồ vật, quấy, ngủ chập chờn.', 'Cho bé gặm đồ gặm nướu sạch, mát. Sốt cao hoặc tiêu chảy nặng không phải do mọc răng, cần hỏi bác sĩ.'),
];

enum LeapPhase { before, fussy, after }

class LeapState {
  const LeapState({required this.weeks, required this.current, required this.next, required this.prev, required this.inFussy});
  final double weeks; // tuổi tính theo tuần (từ ngày dự sinh)
  final Leap? current; // bước nhảy đang trong giai đoạn có thể quấy
  final Leap? next;
  final Leap? prev;
  final bool inFussy;
}

LeapState leapState(int adjDays) {
  final w = adjDays / 7.0;
  Leap? cur, nxt, prv;
  for (final l in kLeaps) {
    if (w >= l.fussyFrom && w <= l.fussyTo) cur = l;
    if (w < l.fussyFrom && nxt == null) nxt = l;
    if (w > l.fussyTo) prv = l;
  }
  return LeapState(weeks: w, current: cur, next: nxt, prev: prv, inFussy: cur != null);
}

String leapStatusLabel(Leap l, double weeks) {
  if (weeks > l.fussyTo) return 'Đã qua';
  if (weeks >= l.fussyFrom) return 'Đang trong giai đoạn';
  return 'Sắp tới';
}
