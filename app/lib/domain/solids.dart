/// Ăn dặm: gợi ý theo tháng và danh mục thực phẩm (có đánh dấu nhóm dễ dị ứng).
class Food {
  const Food(this.name, this.group, {this.allergen = false});
  final String name;
  final String group;
  final bool allergen;
}

const kFoodGroups = ['Tinh bột', 'Rau củ', 'Trái cây', 'Đạm', 'Khác'];

const List<Food> kFoods = [
  Food('Gạo', 'Tinh bột'),
  Food('Yến mạch', 'Tinh bột'),
  Food('Khoai lang', 'Tinh bột'),
  Food('Khoai tây', 'Tinh bột'),
  Food('Bột mì / mì', 'Tinh bột', allergen: true),
  Food('Bí đỏ', 'Rau củ'),
  Food('Cà rốt', 'Rau củ'),
  Food('Bông cải xanh', 'Rau củ'),
  Food('Rau ngót / rau muống', 'Rau củ'),
  Food('Đậu Hà Lan', 'Rau củ'),
  Food('Chuối', 'Trái cây'),
  Food('Bơ', 'Trái cây'),
  Food('Táo / lê', 'Trái cây'),
  Food('Đu đủ', 'Trái cây'),
  Food('Thịt gà', 'Đạm'),
  Food('Thịt heo', 'Đạm'),
  Food('Thịt bò', 'Đạm'),
  Food('Cá (trắng, hồi)', 'Đạm', allergen: true),
  Food('Tôm cua', 'Đạm', allergen: true),
  Food('Trứng', 'Đạm', allergen: true),
  Food('Đậu hũ / đậu nành', 'Đạm', allergen: true),
  Food('Đậu phộng', 'Đạm', allergen: true),
  Food('Hạt cây (hạnh nhân, óc chó…)', 'Đạm', allergen: true),
  Food('Mè', 'Khác', allergen: true),
  Food('Sữa chua / phô mai', 'Khác', allergen: true),
  Food('Dầu ăn / bơ', 'Khác'),
];

class SolidStage {
  const SolidStage(this.fromMonths, this.title, this.texture, this.meals);
  final int fromMonths;
  final String title;
  final String texture;
  final String meals;
}

const List<SolidStage> kSolidStages = [
  SolidStage(6, '6–7 tháng', 'Bột loãng đến sệt, nghiền mịn', '2–3 bữa ăn dặm nhỏ, vẫn bú là chính'),
  SolidStage(8, '8 tháng', 'Bột đặc, nghiền thô, thức ăn mềm', '2–3 bữa + bú'),
  SolidStage(9, '9–11 tháng', 'Cháo hạt, thức ăn băm nhỏ, finger food mềm', '3 bữa + 1–2 bữa phụ'),
  SolidStage(12, '12 tháng trở lên', 'Cơm nát, thức ăn cắt nhỏ như cả nhà', '3 bữa + 1–2 bữa phụ'),
];

const kSolidSource = 'Nguồn: WHO (Complementary feeding), AAP, Viện Dinh dưỡng Quốc gia. Bé ốm, dị ứng hoặc chậm tăng cân: hãy hỏi bác sĩ.';
