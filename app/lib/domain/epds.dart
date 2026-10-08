/// Thang tự kiểm tra tâm trạng sau sinh Edinburgh (EPDS, Cox và cs. 1987), 10 câu, điểm 0–3 mỗi câu, tối đa 30.
/// CHỈ LÀ SÀNG LỌC, không phải chẩn đoán. Bản dịch tiếng Việt dưới đây là bản tham khảo, CHƯA được kiểm chứng,
/// cần thay bằng bản dịch đã thẩm định (và kiểm tra điều khoản sử dụng) trước khi phát hành.
class EpdsQ {
  const EpdsQ(this.text, this.options);
  final String text;
  final List<(String, int)> options;
}

const kEpdsIntro =
    'Trong 7 ngày qua, mẹ chọn câu trả lời gần nhất với cảm giác của mẹ (không phải cảm giác hôm nay). Không có đáp án đúng hay sai.';

const List<EpdsQ> kEpds = [
  EpdsQ('Mẹ có thể cười và thấy mặt vui của sự việc', [('Như trước đây', 0), ('Ít hơn trước một chút', 1), ('Chắc chắn ít hơn trước', 2), ('Hoàn toàn không', 3)]),
  EpdsQ('Mẹ nhìn về phía trước với niềm vui', [('Như trước đây', 0), ('Ít hơn trước một chút', 1), ('Chắc chắn ít hơn trước', 2), ('Hầu như không', 3)]),
  EpdsQ('Mẹ tự trách mình một cách không cần thiết khi có chuyện không tốt', [('Có, phần lớn thời gian', 3), ('Có, đôi khi', 2), ('Không thường xuyên', 1), ('Không bao giờ', 0)]),
  EpdsQ('Mẹ thấy lo lắng hoặc bất an mà không có lý do rõ ràng', [('Hoàn toàn không', 0), ('Hầu như không', 1), ('Có, đôi khi', 2), ('Có, rất thường xuyên', 3)]),
  EpdsQ('Mẹ thấy sợ hãi hoặc hoảng loạn mà không có lý do rõ ràng', [('Có, khá nhiều', 3), ('Có, đôi khi', 2), ('Không nhiều', 1), ('Hoàn toàn không', 0)]),
  EpdsQ('Mẹ thấy mọi việc dồn lại quá sức', [('Có, phần lớn thời gian mẹ không xoay xở nổi', 3), ('Có, đôi khi mẹ xoay xở không tốt như thường lệ', 2), ('Không, phần lớn mẹ xoay xở khá tốt', 1), ('Không, mẹ vẫn xoay xở tốt như trước', 0)]),
  EpdsQ('Mẹ buồn đến mức khó ngủ', [('Có, phần lớn thời gian', 3), ('Có, đôi khi', 2), ('Không thường xuyên', 1), ('Hoàn toàn không', 0)]),
  EpdsQ('Mẹ thấy buồn hoặc khổ sở', [('Có, phần lớn thời gian', 3), ('Có, khá thường xuyên', 2), ('Không thường xuyên', 1), ('Hoàn toàn không', 0)]),
  EpdsQ('Mẹ buồn đến mức phải khóc', [('Có, phần lớn thời gian', 3), ('Có, khá thường xuyên', 2), ('Chỉ thỉnh thoảng', 1), ('Không bao giờ', 0)]),
  EpdsQ('Mẹ từng có ý nghĩ làm hại bản thân', [('Có, khá thường xuyên', 3), ('Đôi khi', 2), ('Hầu như không', 1), ('Không bao giờ', 0)]),
];

class EpdsOutcome {
  const EpdsOutcome(this.level, this.title, this.body, this.urgent);
  final int level; // 0 thấp, 1 cần lưu ý, 2 nên gặp bác sĩ
  final String title;
  final String body;
  final bool urgent;
}

EpdsOutcome epdsOutcome(List<int> answers) {
  final score = answers.fold(0, (a, b) => a + b);
  final self = answers.length >= 10 && answers[9] > 0;
  if (self) {
    return EpdsOutcome(2, 'Mẹ đang không ổn, hãy tìm sự giúp đỡ ngay', 'Điểm $score/30. Mẹ có ý nghĩ làm hại bản thân. Điều này không phải lỗi của mẹ và có thể được giúp. Hãy nói ngay với người thân tin cậy, liên hệ bác sĩ hoặc cơ sở y tế gần nhất. Nếu mẹ thấy không an toàn, hãy gọi cấp cứu 115 hoặc đến cơ sở y tế gần nhất ngay lập tức.', true);
  }
  if (score >= 13) {
    return EpdsOutcome(2, 'Nên gặp bác sĩ sớm', 'Điểm $score/30, cao hơn ngưỡng thường dùng để sàng lọc. Đây chưa phải chẩn đoán, nhưng mẹ nên trao đổi với bác sĩ hoặc chuyên gia tâm lý sớm. Trầm cảm sau sinh khá phổ biến và điều trị được.', false);
  }
  if (score >= 10) {
    return EpdsOutcome(1, 'Mẹ nên chia sẻ với bác sĩ', 'Điểm $score/30, ở mức cần lưu ý. Hãy nói chuyện với người thân và với bác sĩ ở lần khám tới, đồng thời chăm sóc bản thân: ngủ khi bé ngủ, nhờ người giúp, ra ngoài hít thở.', false);
  }
  return EpdsOutcome(0, 'Mức thấp', 'Điểm $score/30. Hiện chưa thấy dấu hiệu rõ, nhưng cảm xúc có thể thay đổi. Nếu mẹ thấy buồn, lo âu kéo dài trên 2 tuần hoặc ảnh hưởng sinh hoạt, hãy gặp bác sĩ.', false);
}

const kEpdsDisclaimer =
    'Thang EPDS chỉ để sàng lọc, không phải chẩn đoán. Bản dịch tiếng Việt chưa được kiểm chứng. Kết quả được lưu riêng trên máy của mẹ, không chia sẻ.';
