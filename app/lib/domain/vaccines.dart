/// Lịch tiêm chủng tham khảo cho trẻ ở Việt Nam.
///
/// Nhóm "TCMR" (Chương trình Tiêm chủng mở rộng, miễn phí) tổng hợp từ lịch TCMR năm 2025 do các cơ sở y tế công bố
/// (sơ sinh: lao, viêm gan B; 2–3–4 tháng: DPT-VGB-Hib, bại liệt uống, Rota; 5 và 9 tháng: bại liệt tiêm IPV;
/// 9 tháng: sởi; 12 tháng: viêm não Nhật Bản; 18 tháng: DPT nhắc, sởi-rubella). Vắc xin phế cầu được đưa vào TCMR
/// từ năm 2026 theo lộ trình từng địa phương.
/// Nhóm "Dịch vụ" là khuyến nghị tham khảo phổ biến tại các trung tâm tiêm chủng, không bắt buộc, tuỳ loại vắc xin được cấp phép.
/// LƯU Ý: lịch thay đổi theo thông báo của Bộ Y tế và địa phương; luôn theo chỉ định của cơ sở tiêm chủng. Cần chuyên gia duyệt.
class Vax {
  const Vax({required this.id, required this.name, required this.disease, required this.dueDays, this.windowDays = 30, this.epi = true, this.note = ''});
  final String id;
  final String name; // tên mũi
  final String disease;
  final int dueDays; // tuổi (ngày) nên tiêm
  final int windowDays; // sau bao nhiêu ngày thì coi là trễ
  final bool epi;
  final String note;
}

const kVaxSource = 'Nguồn: lịch Tiêm chủng mở rộng 2025 (Bộ Y tế, qua các cơ sở y tế). Lịch có thể thay đổi, hãy theo chỉ định của cơ sở tiêm chủng.';

const List<Vax> kVaccines = [
  // ===== TCMR (miễn phí) =====
  Vax(id: 'hepb0', name: 'Viêm gan B sơ sinh', disease: 'Viêm gan B', dueDays: 0, windowDays: 2, note: 'Trong vòng 24 giờ sau sinh.'),
  Vax(id: 'bcg', name: 'Lao (BCG)', disease: 'Lao', dueDays: 0, windowDays: 30, note: 'Trong tháng đầu sau sinh.'),
  Vax(id: 'dpt1', name: 'DPT-VGB-Hib (5 trong 1) mũi 1', disease: 'Bạch hầu, ho gà, uốn ván, viêm gan B, Hib', dueDays: 61),
  Vax(id: 'opv1', name: 'Bại liệt uống (OPV) liều 1', disease: 'Bại liệt', dueDays: 61),
  Vax(id: 'rota1', name: 'Rota liều 1 (uống)', disease: 'Tiêu chảy do Rota', dueDays: 61, note: 'Uống khi đủ 2 tháng, nên uống liều 1 trước 15 tuần tuổi.'),
  Vax(id: 'dpt2', name: 'DPT-VGB-Hib mũi 2', disease: 'Bạch hầu, ho gà, uốn ván, viêm gan B, Hib', dueDays: 91),
  Vax(id: 'opv2', name: 'Bại liệt uống (OPV) liều 2', disease: 'Bại liệt', dueDays: 91),
  Vax(id: 'rota2', name: 'Rota liều 2 (uống)', disease: 'Tiêu chảy do Rota', dueDays: 91, note: 'Cách liều 1 ít nhất 1 tháng.'),
  Vax(id: 'dpt3', name: 'DPT-VGB-Hib mũi 3', disease: 'Bạch hầu, ho gà, uốn ván, viêm gan B, Hib', dueDays: 122),
  Vax(id: 'opv3', name: 'Bại liệt uống (OPV) liều 3', disease: 'Bại liệt', dueDays: 122),
  Vax(id: 'ipv1', name: 'Bại liệt tiêm (IPV) mũi 1', disease: 'Bại liệt', dueDays: 152),
  Vax(id: 'measles', name: 'Sởi mũi 1', disease: 'Sởi', dueDays: 274),
  Vax(id: 'ipv2', name: 'Bại liệt tiêm (IPV) mũi 2', disease: 'Bại liệt', dueDays: 274),
  Vax(id: 'je1', name: 'Viêm não Nhật Bản mũi 1', disease: 'Viêm não Nhật Bản B', dueDays: 365, note: 'Mũi 2 sau mũi 1 từ 1–2 tuần, mũi 3 sau 1 năm.'),
  Vax(id: 'je2', name: 'Viêm não Nhật Bản mũi 2', disease: 'Viêm não Nhật Bản B', dueDays: 380),
  Vax(id: 'je3', name: 'Viêm não Nhật Bản mũi 3', disease: 'Viêm não Nhật Bản B', dueDays: 730),
  Vax(id: 'dptb', name: 'DPT nhắc lại', disease: 'Bạch hầu, ho gà, uốn ván', dueDays: 548),
  Vax(id: 'mr', name: 'Sởi - Rubella (MR)', disease: 'Sởi, rubella', dueDays: 548),
  // ===== Dịch vụ (tham khảo) =====
  Vax(id: 's_pcv1', name: 'Phế cầu mũi 1', disease: 'Phế cầu (viêm phổi, viêm màng não)', dueDays: 61, epi: false, note: 'Một số địa phương đã đưa vào TCMR từ 2026; nếu chưa, có thể tiêm dịch vụ.'),
  Vax(id: 's_pcv2', name: 'Phế cầu mũi 2', disease: 'Phế cầu', dueDays: 122, epi: false),
  Vax(id: 's_pcv3', name: 'Phế cầu mũi 3', disease: 'Phế cầu', dueDays: 183, epi: false),
  Vax(id: 's_mc', name: 'Não mô cầu (BC hoặc ACYW)', disease: 'Viêm màng não mô cầu', dueDays: 180, epi: false, note: 'Tuỳ loại vắc xin, hỏi bác sĩ lịch cụ thể.'),
  Vax(id: 's_flu1', name: 'Cúm mũi 1', disease: 'Cúm mùa', dueDays: 183, epi: false, note: 'Từ 6 tháng; lần đầu 2 mũi cách nhau 4 tuần, sau đó mỗi năm 1 mũi.'),
  Vax(id: 's_flu2', name: 'Cúm mũi 2', disease: 'Cúm mùa', dueDays: 211, epi: false),
  Vax(id: 's_ev71a', name: 'Tay chân miệng (EV71) mũi 1', disease: 'Tay chân miệng do EV71', dueDays: 183, epi: false, note: 'Chỉ định cho trẻ từ 6 tháng theo vắc xin được cấp phép; hỏi cơ sở tiêm về loại và lịch.'),
  Vax(id: 's_ev71b', name: 'Tay chân miệng (EV71) mũi 2', disease: 'Tay chân miệng do EV71', dueDays: 213, epi: false, note: 'Thường cách mũi 1 khoảng 1 tháng.'),
  Vax(id: 's_mmr', name: 'Sởi - Quai bị - Rubella (MMR)', disease: 'Sởi, quai bị, rubella', dueDays: 365, epi: false),
  Vax(id: 's_var', name: 'Thuỷ đậu mũi 1', disease: 'Thuỷ đậu', dueDays: 365, epi: false),
  Vax(id: 's_hepa', name: 'Viêm gan A', disease: 'Viêm gan A', dueDays: 365, epi: false),
];

String vaxAgeLabel(int days) {
  if (days <= 0) return 'Sơ sinh';
  if (days < 60) return '${(days / 7).round()} tuần';
  final m = (days / 30.4375).round();
  return m >= 24 ? '${(m / 12).toStringAsFixed(m % 12 == 0 ? 0 : 1)} tuổi' : '$m tháng';
}
