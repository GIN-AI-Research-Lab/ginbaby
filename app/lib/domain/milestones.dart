/// Mốc phát triển theo tuổi, tham khảo danh sách mốc của CDC (Learn the Signs. Act Early, bản 2022).
/// Mốc là điều phần lớn trẻ làm được ở tuổi đó. Bé chậm một vài mốc chưa chắc có vấn đề, nhưng nếu lo lắng
/// hãy trao đổi với bác sĩ nhi. Cần chuyên gia duyệt bản dịch.
class MilestoneGroup {
  const MilestoneGroup(this.months, this.items);
  final int months;
  final List<String> items;
}

const kMilestoneSource = 'Nguồn tham khảo: CDC, "Learn the Signs. Act Early" (mốc phát triển 2022). Không dùng để chẩn đoán.';

const List<MilestoneGroup> kMilestones = [
  MilestoneGroup(2, [
    'Bình tĩnh lại khi được nói chuyện hoặc bế lên',
    'Nhìn vào mặt mẹ',
    'Có vẻ vui khi thấy mẹ',
    'Mỉm cười khi mẹ nói chuyện hoặc cười với bé',
    'Phát ra âm thanh ngoài tiếng khóc',
    'Giật mình hoặc phản ứng với tiếng động lớn',
    'Dõi theo vật bằng mắt',
    'Ngóc đầu khi nằm sấp',
    'Cử động cả hai tay và hai chân',
    'Mở bàn tay trong chốc lát',
  ]),
  MilestoneGroup(4, [
    'Tự mỉm cười để thu hút sự chú ý',
    'Cười khúc khích',
    'Nhìn, cử động hoặc phát âm để giữ sự chú ý của mẹ',
    'Phát âm "ooo", "aaa"',
    'Đáp lại bằng âm thanh khi mẹ nói chuyện',
    'Quay đầu về phía có tiếng động',
    'Há miệng khi đói',
    'Với tay chạm đồ chơi bằng một tay',
    'Giữ đầu vững không cần đỡ',
    'Chống khuỷu tay nâng người khi nằm sấp',
    'Cầm đồ chơi khi đặt vào tay',
    'Đưa tay vẫy đồ chơi',
    'Đưa tay lên miệng',
  ]),
  MilestoneGroup(6, [
    'Nhận ra người quen',
    'Thích nhìn mình trong gương',
    'Cười thành tiếng',
    'Thay phiên "nói chuyện" với mẹ',
    'Thổi bong bóng nước bọt',
    'Phát ra tiếng rít vui',
    'Đưa đồ vật vào miệng để khám phá',
    'Với tay lấy đồ chơi',
    'Mím môi khi không muốn ăn thêm',
    'Lật từ sấp sang ngửa',
    'Chống thẳng tay nâng người khi nằm sấp',
    'Chống tay để ngồi',
  ]),
  MilestoneGroup(9, [
    'Ngại hoặc bám mẹ khi gặp người lạ',
    'Biểu lộ nhiều nét mặt khác nhau',
    'Quay lại khi nghe gọi tên',
    'Phản ứng khi mẹ rời đi (nhìn theo, với, khóc)',
    'Cười hoặc thích trò ú oà',
    'Phát âm "mamama", "bababa"',
    'Giơ tay đòi bế',
    'Tìm vật rơi khuất tầm nhìn',
    'Đập hai vật vào nhau',
    'Tự ngồi dậy',
    'Chuyền đồ vật từ tay này sang tay kia',
    'Dùng ngón tay "cào" thức ăn về phía mình',
    'Ngồi vững không cần đỡ',
  ]),
  MilestoneGroup(12, [
    'Chơi các trò như vỗ tay, "tạm biệt"',
    'Vẫy tay tạm biệt',
    'Gọi "mẹ", "ba" hoặc một tên riêng',
    'Hiểu từ "không"',
    'Bỏ đồ vật vào hộp',
    'Tìm đồ vật mẹ giấu đi',
    'Vịn đứng dậy',
    'Vịn đồ đạc đi men',
    'Uống nước từ cốc không nắp khi mẹ cầm giúp',
    'Nhặt đồ nhỏ bằng ngón cái và ngón trỏ',
  ]),
];

/// Răng sữa: tên, nhóm, độ tuổi mọc thường gặp (tháng). Tham khảo bảng của Hiệp hội Nha khoa Hoa Kỳ (ADA).
class Tooth {
  const Tooth(this.id, this.name, this.upper, this.from, this.to);
  final String id;
  final String name;
  final bool upper;
  final int from;
  final int to;
}

const List<Tooth> kTeeth = [
  Tooth('u_c', 'Cửa giữa trên', true, 8, 12),
  Tooth('u_l', 'Cửa bên trên', true, 9, 13),
  Tooth('u_ca', 'Nanh trên', true, 16, 22),
  Tooth('u_m1', 'Hàm nhỏ trên', true, 13, 19),
  Tooth('u_m2', 'Hàm lớn trên', true, 25, 33),
  Tooth('l_c', 'Cửa giữa dưới', false, 6, 10),
  Tooth('l_l', 'Cửa bên dưới', false, 10, 16),
  Tooth('l_ca', 'Nanh dưới', false, 17, 23),
  Tooth('l_m1', 'Hàm nhỏ dưới', false, 14, 18),
  Tooth('l_m2', 'Hàm lớn dưới', false, 23, 31),
];

const kTeethSource = 'Tuổi mọc răng thường gặp theo bảng của ADA; mỗi bé mỗi khác. Mỗi loại răng có 2 chiếc (trái/phải). Cần đi nha sĩ khi bé 1 tuổi hoặc khi mọc răng đầu tiên.';
