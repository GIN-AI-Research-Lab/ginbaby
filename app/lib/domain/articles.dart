/// Cẩm nang cho mẹ. Nội dung ngắn gọn, bám theo khuyến cáo của WHO, CDC, AAP, ACOG và tài liệu trong nước.
/// Mọi bài đều cần bác sĩ/chuyên gia dinh dưỡng duyệt trước khi phát hành. Không thay thế tư vấn y tế.
class Article {
  const Article({required this.id, required this.title, required this.cat, required this.summary, required this.sections, required this.source, this.urgent = false, this.minutes = 3});
  final String id;
  final String title;
  final String cat;
  final String summary;
  final List<(String, List<String>)> sections;
  final String source;
  final bool urgent;
  final int minutes;
}

const kArticleCats = ['Tất cả', 'Sữa & bú', 'Ăn dặm', 'Sức khoẻ bé', 'Mẹ sau sinh', 'Giấc ngủ'];

const List<Article> kArticles = [
  Article(
    id: 'red_flags',
    title: 'Khi nào cần đưa bé đi khám ngay',
    cat: 'Sức khoẻ bé',
    urgent: true,
    summary: 'Những dấu hiệu không nên chờ đợi ở nhà.',
    sections: [
      ('Đưa bé đi khám hoặc gọi cấp cứu 115 ngay khi', [
        'Bé dưới 3 tháng sốt từ 38°C trở lên.',
        'Khó thở, thở nhanh, rút lõm ngực, môi hoặc da tím tái.',
        'Bé li bì, khó đánh thức, bỏ bú hoặc bú rất yếu.',
        'Co giật.',
        'Nôn liên tục, nôn ra màu xanh vàng hoặc có máu; bụng chướng căng.',
        'Phân màu trắng/bạc, có máu hoặc đen (sau những ngày đầu).',
        'Dấu hiệu mất nước: tã khô trên 8 giờ, khóc không nước mắt, thóp lõm, miệng khô.',
        'Thóp phồng căng, bé khóc thét không dỗ được.',
        'Vàng da xuất hiện trong 24 giờ đầu, vàng lan xuống bụng/chân, hoặc kéo dài quá 2 tuần.',
        'Vết thương ở rốn đỏ, chảy mủ, có mùi hôi.',
      ]),
      ('Mẹ nên làm gì', [
        'Giữ bình tĩnh, ghi lại giờ khởi phát và nhiệt độ (đo hậu môn là chính xác nhất ở trẻ nhỏ).',
        'Mang theo sổ khám, danh sách thuốc đã dùng, nhật ký bú/ngủ/tã trong app.',
      ]),
    ],
    source: 'AAP/HealthyChildren; WHO IMCI (Xử trí lồng ghép bệnh trẻ em).',
  ),
  Article(
    id: 'enough_milk',
    title: 'Bé bú đủ chưa?',
    cat: 'Sữa & bú',
    summary: 'Dấu hiệu bé nhận đủ sữa và khi nào cần hỏi bác sĩ.',
    sections: [
      ('Dấu hiệu bé bú đủ', [
        'Từ ngày thứ 5 trở đi: ít nhất 6 tã ướt mỗi ngày, nước tiểu nhạt màu.',
        'Bú 8–12 cữ mỗi 24 giờ khi còn sơ sinh; bé nuốt rõ, thỏa mãn sau bú.',
        'Phân chuyển từ phân su sang vàng; đi phân thường xuyên ở những tuần đầu.',
        'Tăng cân đều: thường lấy lại cân lúc sinh trong khoảng 2 tuần đầu.',
      ]),
      ('Hãy hỏi bác sĩ nếu', [
        'Ít tã ướt hơn mức trên, nước tiểu sẫm màu.',
        'Bé sụt cân nhiều hoặc không lấy lại được cân lúc sinh sau 2 tuần.',
        'Bé li bì, ngủ li bì không chịu bú, vàng da tăng.',
      ]),
      ('Lưu ý', [
        'Bé bú mẹ trực tiếp: đừng đo từng cữ. Hãy nhìn tổng cả ngày và cân nặng.',
        'Bé có những giai đoạn đòi bú nhiều hơn (tăng tốc tăng trưởng) rất bình thường.',
      ]),
    ],
    source: 'AAP; WHO; Kent và cs. 2006 (Pediatrics 117:e387).',
  ),
  Article(
    id: 'store_milk',
    title: 'Trữ và dùng sữa mẹ đúng cách',
    cat: 'Sữa & bú',
    summary: 'Thời gian bảo quản, rã đông và những điều không nên làm.',
    sections: [
      ('Thời gian bảo quản sữa mẹ mới hút', [
        'Nhiệt độ phòng (tối đa 25°C): tối đa 4 giờ.',
        'Ngăn mát tủ lạnh (4°C): tối đa 4 ngày, để phía trong, không để ở cánh cửa.',
        'Ngăn đông: tốt nhất trong 6 tháng, chấp nhận được đến 12 tháng.',
      ]),
      ('Rã đông và sử dụng', [
        'Rã đông trong ngăn mát qua đêm hoặc ngâm bình trong nước ấm. Không dùng lò vi sóng.',
        'Sữa đã rã đông dùng trong 24 giờ, không cấp đông lại.',
        'Sữa bé đã bú dở nên dùng trong 1–2 giờ, bỏ phần còn lại.',
        'Sữa có thể tách lớp, lắc nhẹ trước khi cho bú.',
      ]),
      ('Mẹo trữ sữa', [
        'Ghi ngày giờ hút lên mỗi túi/bình; dùng sữa cũ trước (FIFO).',
        'Trữ từng phần 60–120ml để đỡ lãng phí.',
        'Để chừa chỗ trong túi vì sữa nở ra khi đông.',
      ]),
    ],
    source: 'CDC: Proper Storage and Preparation of Breast Milk.',
  ),
  Article(
    id: 'pumping',
    title: 'Hút sữa: kỳ vọng thực tế và mẹo',
    cat: 'Sữa & bú',
    summary: 'Vì sao lượng hút thay đổi và cách hút hiệu quả hơn.',
    sections: [
      ('Điều mẹ nên biết', [
        'Máy hút thường lấy được ít hơn bé bú trực tiếp. Lượng hút không phản ánh toàn bộ lượng sữa mẹ.',
        'Khi sữa ổn định (từ khoảng 6 tuần), nhiều mẹ hút được khoảng 60–150ml mỗi cữ (cả hai bên). Mỗi mẹ mỗi khác.',
        'Lượng sữa thay đổi theo giờ trong ngày, thường nhiều hơn vào buổi sáng, ít hơn vào buổi tối.',
        'Những ngày đầu chỉ hút được vài ml là bình thường.',
      ]),
      ('Mẹo hút hiệu quả', [
        'Hút đều đặn, thường 6–8 cữ mỗi ngày nếu mẹ hút hoàn toàn.',
        'Chườm ấm, massage ngực, nhìn ảnh hoặc nghe tiếng bé trước khi hút.',
        'Chọn phễu đúng size, kiểm tra áp lực hút không gây đau.',
        'Vệ sinh và tiệt trùng dụng cụ theo hướng dẫn nhà sản xuất.',
      ]),
      ('Gặp bác sĩ hoặc tư vấn viên sữa mẹ nếu', [
        'Lượng hút giảm nhiều nhiều ngày liên tiếp kèm bé có dấu hiệu bú không đủ.',
        'Ngực đau, đỏ, có cục cứng, sốt (tắc tia sữa, viêm vú).',
      ]),
    ],
    source: 'Kent và cs. 2006; tổng hợp của tư vấn viên sữa mẹ (IBCLC); CDC.',
  ),
  Article(
    id: 'mom_nutrition',
    title: 'Mẹ cho con bú nên ăn uống thế nào',
    cat: 'Mẹ sau sinh',
    summary: 'Ăn đủ, đa dạng và bớt kiêng khem không cần thiết.',
    sections: [
      ('Nguyên tắc', [
        'Ăn đa dạng: đạm (thịt, cá, trứng, đậu), rau xanh, trái cây, ngũ cốc, sữa hoặc sản phẩm từ sữa, chất béo tốt.',
        'Cần thêm khoảng 300–500 kcal mỗi ngày so với bình thường; uống nước theo cảm giác khát.',
        'Bổ sung vitamin/sắt/canxi theo chỉ định của bác sĩ.',
      ]),
      ('Nên hạn chế', [
        'Rượu bia: tốt nhất không uống; nếu uống, chờ ít nhất 2 giờ trước khi cho bú.',
        'Caffeine: vừa phải, dưới khoảng 300mg mỗi ngày (khoảng 2–3 tách cà phê nhỏ).',
        'Cá có hàm lượng thuỷ ngân cao (cá kiếm, cá thu vua). Không hút thuốc lá.',
      ]),
      ('Kiêng cữ dân gian', [
        'Nhiều cách kiêng truyền thống (chỉ ăn cơm với muối vừng, kiêng gần như mọi loại rau thịt) không có cơ sở và có thể làm mẹ thiếu chất, ít sữa hơn.',
        'Tắm gội nhẹ nhàng, giữ ấm và sạch sẽ là tốt cho mẹ; không cần kiêng hoàn toàn.',
        'Nếu bé có dấu hiệu dị ứng liên quan đến một thức ăn của mẹ (nổi mẩn, phân có máu), hãy hỏi bác sĩ trước khi tự bỏ thức ăn.',
      ]),
    ],
    source: 'WHO; ACOG; AAP; hướng dẫn dinh dưỡng của Viện Dinh dưỡng Quốc gia.',
  ),
  Article(
    id: 'safe_sleep',
    title: 'Ngủ an toàn cho bé',
    cat: 'Giấc ngủ',
    summary: 'Giảm nguy cơ đột tử ở trẻ nhỏ (SIDS) và ngạt.',
    sections: [
      ('Khuyến cáo', [
        'Luôn đặt bé nằm ngửa mỗi lần ngủ, kể cả ngủ ngày.',
        'Nệm phẳng, chắc, trải ga vừa khít. Không gối, chăn dày, thú bông, thành chắn mềm trong nôi.',
        'Ngủ chung phòng với mẹ ít nhất 6 tháng đầu nhưng không chung giường. Không cho bé ngủ trên sofa hoặc ghế bành.',
        'Không để bé quá nóng, không trùm đầu. Dùng túi ngủ thay chăn.',
        'Không hút thuốc trong nhà, bú mẹ giúp giảm nguy cơ.',
        'Có thể dùng núm vú giả khi ngủ sau khi bé đã quen bú.',
      ]),
    ],
    source: 'AAP: Safe Sleep Recommendations.',
  ),
  Article(
    id: 'solids_start',
    title: 'Bắt đầu ăn dặm',
    cat: 'Ăn dặm',
    summary: 'Khi nào bắt đầu, cho ăn gì và tránh gì.',
    sections: [
      ('Khi nào', [
        'Từ khi bé đủ 6 tháng (180 ngày), tiếp tục bú mẹ hoặc sữa công thức.',
        'Dấu hiệu sẵn sàng: ngồi được khi có đỡ, giữ đầu vững, quan tâm thức ăn, không còn đẩy thức ăn ra bằng lưỡi.',
      ]),
      ('Cách cho ăn', [
        '6–8 tháng: 2–3 bữa mỗi ngày; 9–23 tháng: 3–4 bữa và 1–2 bữa phụ, bú mẹ vẫn là chính ở giai đoạn đầu.',
        'Bắt đầu từ ít (2–3 thìa), tăng dần; kết cấu từ nhuyễn đến đặc dần theo tuổi.',
        'Ưu tiên thực phẩm giàu sắt: thịt, cá, trứng, đậu; thêm rau củ, trái cây, chất béo tốt.',
        'Cho ăn theo tín hiệu đói no của bé, không ép.',
      ]),
      ('Tránh', [
        'Mật ong dưới 12 tháng; sữa bò làm đồ uống chính dưới 12 tháng.',
        'Muối, đường, nước ngọt, bánh kẹo.',
        'Thức ăn dễ hóc: hạt nguyên, nho nguyên quả, xúc xích khoanh tròn, kẹo cứng, bắp rang.',
      ]),
    ],
    source: 'WHO (Complementary feeding); AAP; Viện Dinh dưỡng Quốc gia.',
  ),
  Article(
    id: 'allergens',
    title: 'Giới thiệu thực phẩm dễ dị ứng',
    cat: 'Ăn dặm',
    summary: 'Cho thử từng loại, theo dõi phản ứng 3–5 ngày.',
    sections: [
      ('Các nhóm thường gặp', [
        'Sữa bò, trứng, đậu phộng, hạt cây, lúa mì, đậu nành, cá, tôm cua (giáp xác), mè.',
        'Hướng dẫn hiện nay không khuyên trì hoãn quá lâu: có thể giới thiệu từ khoảng 6 tháng khi bé đã ăn dặm được.',
      ]),
      ('Cách thử', [
        'Cho từng loại mới một, lượng nhỏ, buổi sáng khi bé khỏe, chờ 3–5 ngày trước khi thêm loại khác.',
        'Ghi lại trong app: thực phẩm, lượng và phản ứng.',
        'Bé bị chàm nặng hoặc đã dị ứng một loại: hãy hỏi bác sĩ trước khi cho thử đậu phộng hoặc trứng.',
      ]),
      ('Dấu hiệu dị ứng', [
        'Nhẹ: nổi mẩn, nôn nhẹ, tiêu chảy, quấy khóc.',
        'Nặng (gọi cấp cứu 115 ngay): khó thở, thở khò khè, sưng môi/mặt/lưỡi, nôn liên tục, tái xám, li bì.',
      ]),
    ],
    source: 'AAP; NIAID Addendum Guidelines; WHO.',
  ),
  Article(
    id: 'spit_up',
    title: 'Bé ọc sữa và ợ hơi',
    cat: 'Sức khoẻ bé',
    summary: 'Khi nào là bình thường, khi nào cần khám.',
    sections: [
      ('Bình thường', [
        'Ọc/trớ một ít sau bú rất phổ biến và thường giảm dần trước 12 tháng nếu bé vẫn tăng cân, vui khoẻ.',
      ]),
      ('Giúp bé đỡ ọc', [
        'Cho bú chậm, nghỉ giữa chừng để ợ hơi; không để bé quá đói rồi bú vội.',
        'Bế đứng 20–30 phút sau bú; không đặt nằm ngay.',
        'Không cho bú quá nhiều một lần so với nhu cầu.',
      ]),
      ('Cần khám nếu', [
        'Nôn vọt thành tia, nôn xanh vàng hoặc có máu.',
        'Sụt cân, bỏ bú, khóc nhiều khi bú, thở khò khè hoặc ho sau bú.',
      ]),
    ],
    source: 'AAP; NHS.',
  ),
  Article(
    id: 'jaundice',
    title: 'Vàng da ở trẻ sơ sinh',
    cat: 'Sức khoẻ bé',
    summary: 'Phân biệt vàng da sinh lý và dấu hiệu cần khám.',
    sections: [
      ('Thường gặp', [
        'Vàng da nhẹ thường xuất hiện ngày thứ 2–3 và giảm trong 1–2 tuần.',
        'Cho bú đủ giúp thải bilirubin nhanh hơn.',
      ]),
      ('Cần khám sớm nếu', [
        'Vàng da xuất hiện trong 24 giờ đầu hoặc vàng đậm lan xuống bụng, tay chân.',
        'Bé li bì, bú kém, sốt.',
        'Phân bạc màu hoặc nước tiểu sẫm.',
        'Vàng da kéo dài quá 2 tuần ở bé đủ tháng (quá 3 tuần ở bé sinh non).',
      ]),
    ],
    source: 'AAP; NICE.',
  ),
  Article(
    id: 'mom_warning',
    title: 'Mẹ sau sinh: dấu hiệu cần gặp bác sĩ',
    cat: 'Mẹ sau sinh',
    urgent: true,
    summary: 'Những biến chứng sau sinh không nên chờ.',
    sections: [
      ('Đi khám hoặc gọi cấp cứu ngay khi', [
        'Chảy máu nhiều: thấm đẫm hơn 1 băng vệ sinh mỗi giờ, hoặc ra máu cục lớn.',
        'Sốt từ 38°C trở lên, ớn lạnh.',
        'Vết mổ hoặc tầng sinh môn đau tăng, sưng đỏ, chảy mủ, có mùi.',
        'Đau, sưng, nóng đỏ ở một bên bắp chân; khó thở hoặc đau ngực.',
        'Đau đầu dữ dội, nhìn mờ, sưng phù tay mặt nhanh.',
        'Vú sưng đỏ đau kèm sốt (viêm vú) hoặc có cục cứng không hết.',
      ]),
      ('Về tâm trạng', [
        'Buồn, dễ khóc vài ngày đầu rất thường gặp. Nếu buồn, lo âu, mất hứng thú kéo dài quá 2 tuần hoặc có ý nghĩ làm hại bản thân, hãy nói với bác sĩ và người thân ngay. Trầm cảm sau sinh điều trị được.',
      ]),
    ],
    source: 'ACOG; WHO (Chăm sóc sau sinh).',
  ),
  Article(
    id: 'vaccine_care',
    title: 'Trước và sau khi tiêm chủng',
    cat: 'Sức khoẻ bé',
    summary: 'Chuẩn bị, theo dõi và xử trí phản ứng thường gặp.',
    sections: [
      ('Trước khi tiêm', [
        'Mang sổ tiêm chủng. Báo cho bác sĩ nếu bé đang sốt, ốm, đang dùng thuốc hoặc từng có phản ứng nặng.',
        'Cho bé ăn no nhưng không quá no.',
      ]),
      ('Sau khi tiêm', [
        'Ở lại theo dõi ít nhất 30 phút tại điểm tiêm.',
        'Phản ứng thường gặp: đau, sưng đỏ chỗ tiêm, sốt nhẹ, quấy khóc, bú kém trong 1–2 ngày.',
        'Cho bé bú đủ, mặc đồ thoáng, theo dõi nhiệt độ. Không bôi, đắp lá hay chích lễ chỗ tiêm.',
      ]),
      ('Đưa bé đi khám ngay nếu', [
        'Khó thở, sưng môi/mặt, nổi mề đay lan rộng, li bì, co giật, sốt cao hoặc sốt kéo dài.',
      ]),
    ],
    source: 'CDC; Bộ Y tế (hướng dẫn tiêm chủng).',
  ),
  Article(
    id: 'cord_bath',
    title: 'Chăm sóc rốn và tắm cho bé',
    cat: 'Sức khoẻ bé',
    summary: 'Giữ rốn sạch, khô và tắm an toàn.',
    sections: [
      ('Rốn', [
        'Giữ rốn sạch và khô; gấp mép tã dưới rốn cho thoáng.',
        'Nếu rốn bẩn, rửa bằng nước sạch và xà phòng nhẹ rồi lau khô. Không cần bôi thuốc.',
        'Rốn thường rụng sau 1–3 tuần. Đỏ lan quanh rốn, chảy mủ, có mùi, bé sốt: cần đi khám.',
      ]),
      ('Tắm', [
        'Nước ấm khoảng 37°C (thử bằng khuỷu tay), phòng kín gió, tắm 5–10 phút, 2–3 lần mỗi tuần là đủ ở sơ sinh.',
        'Không bao giờ để bé một mình trong chậu tắm.',
      ]),
    ],
    source: 'WHO (Chăm sóc rốn); AAP.',
  ),
];
