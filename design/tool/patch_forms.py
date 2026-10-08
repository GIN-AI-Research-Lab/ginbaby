# -*- coding: utf-8 -*-
"""Làm màn nhập (Thêm khoản chi, Thêm vào quỹ) bớt đơn điệu: tiêu đề nhóm có biểu tượng màu, ô nhập có biểu tượng, chip có màu."""
import os

ROOT = r'F:\Project Ai\GinBaby\app\lib'


def rd(rel):
    return open(os.path.join(ROOT, rel), encoding='utf-8').read()


def wr(rel, s):
    open(os.path.join(ROOT, rel), 'w', encoding='utf-8').write(s)


def rep(s, old, new, cnt=1):
    assert old in s, old[:100]
    return s.replace(old, new, cnt)


# ---------- kit: FormHeader, GlassField.icon, PillChip.dot
k = rd(r'core\kit.dart')
k = rep(k, "  const PillChip({super.key, required this.label, required this.on, required this.onTap, this.color, this.height = 36, this.icon, this.hPad = 14});",
        "  const PillChip({super.key, required this.label, required this.on, required this.onTap, this.color, this.height = 36, this.icon, this.hPad = 14, this.dot, this.iconColor});")
k = rep(k, "  final IconData? icon;\n  final double hPad;\n\n  @override\n  Widget build(BuildContext context) {\n    return Semantics(\n      button: true,\n      selected: on,",
        "  final IconData? icon;\n  final double hPad;\n  final Color? dot; // chấm màu đầu chip (nhận biết nhanh nhãn)\n  final Color? iconColor; // màu biểu tượng khi chip chưa chọn\n\n  @override\n  Widget build(BuildContext context) {\n    return Semantics(\n      button: true,\n      selected: on,")
k = rep(k, "              if (icon != null) ...[Icon(icon, size: 16, color: on ? (color == null ? Colors.white : GB.ink) : GB.ink), const SizedBox(width: 6)],",
        "              if (dot != null) ...[Container(width: 9, height: 9, decoration: BoxDecoration(color: dot, shape: BoxShape.circle, border: Border.all(color: on ? Colors.white.withValues(alpha: .9) : GB.edgeOf(dot!), width: 1))), const SizedBox(width: 6)],\n              if (icon != null) ...[Icon(icon, size: 16, color: on ? (color == null ? Colors.white : GB.ink) : (iconColor ?? GB.ink)), const SizedBox(width: 6)],")
# GlassField icon
k = rep(k, "  const GlassField({super.key, required this.controller, required this.label, this.keyboard, this.maxLines = 1, this.suffix, this.onChanged, this.hint});",
        "  const GlassField({super.key, required this.controller, required this.label, this.keyboard, this.maxLines = 1, this.suffix, this.onChanged, this.hint, this.icon, this.iconColor});")
k = rep(k, "  final ValueChanged<String>? onChanged;\n\n  @override\n  Widget build(BuildContext context) {\n    return TextField(",
        "  final ValueChanged<String>? onChanged;\n  final IconData? icon; // biểu tượng đầu ô để nhận ra loại thông tin\n  final Color? iconColor;\n\n  @override\n  Widget build(BuildContext context) {\n    return TextField(")
k = rep(k, "        suffixText: suffix,\n        labelStyle: GB.body(13.5, color: GB.inkMuted),",
        "        suffixText: suffix,\n        prefixIcon: icon == null ? null : Padding(padding: const EdgeInsets.only(left: 14, right: 8), child: Icon(icon, size: 21, color: iconColor ?? GB.accentDeep)),\n        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),\n        labelStyle: GB.body(13.5, color: GB.inkMuted),")
k += """

/// Tiêu đề nhóm trong màn nhập: biểu tượng tròn tô màu pastel + tên nhóm (+ phần phụ bên phải).
class FormHeader extends StatelessWidget {
  const FormHeader(this.title, this.icon, {super.key, required this.color, this.trailing, this.hint});
  final String title;
  final IconData icon;
  final Color color; // màu pastel gốc của nhóm
  final Widget? trailing;
  final String? hint;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          IconBadge(icon: icon, bg: color, fg: GB.ink, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: GB.body(14.5, w: FontWeight.w800)),
              if (hint != null) Text(hint!, style: GB.body(11.5, color: GB.inkMuted, height: 1.25)),
            ]),
          ),
          if (trailing != null) trailing!,
        ]),
      );
}
"""
if "import 'pastel.dart';" not in k:
    k = rep(k, "import 'theme.dart';", "import 'pastel.dart';\nimport 'theme.dart';")
wr(r'core\kit.dart', k)

# ---------- ảnh thêm: viền theo màu nhấn thay vì nâu
q = rd(r'ui\quick_logs.dart')
q = rep(q, "border: Border.all(color: const Color(0xFFB79F88), width: 1.5), color: GB.w(.35)),\n            child: Icon(Icons.add_a_photo_rounded, color: GB.inkMuted),",
        "border: Border.all(color: GB.accent.withValues(alpha: .75), width: 1.5), color: GB.accentSoft.withValues(alpha: .6)),\n            child: Icon(Icons.add_a_photo_rounded, color: GB.accentDeep),")
wr(r'ui\quick_logs.dart', q)

# ---------- màn Thêm khoản chi
m = rd(r'ui\money.dart')
m = rep(m, "    return SubPage(\n      title: widget.edit == null ? 'Thêm khoản ${income ? 'thu' : 'chi'}' : 'Sửa khoản',",
        "    return SubPage(\n      title: widget.edit == null ? 'Thêm khoản ${income ? 'thu' : 'chi'}' : 'Sửa khoản',\n      titleArt: 'ic_wallet',")
# số tiền
m = rep(m, "            Text('Số tiền', style: GB.body(12.5, w: FontWeight.w700, color: GB.inkMuted)),\n            Row(children: [",
        "            FormHeader('Số tiền', income ? Icons.south_west_rounded : Icons.north_east_rounded, color: income ? const Color(0xFFD7EAC4) : const Color(0xFFFAD0D3), hint: income ? 'Khoản tiền mẹ nhận được' : 'Khoản tiền mẹ đã chi cho bé'),\n            Row(children: [")
m = rep(m, "                    hintText: '0',\n                    hintStyle: GB.display(40, color: GB.inkMuted.withValues(alpha: .4)),\n                    suffixText: 'đ',",
        "                    prefixIcon: Padding(padding: const EdgeInsets.only(left: 12, right: 6), child: Icon(Icons.payments_rounded, size: 28, color: income ? GB.ok : GB.accentDeep)),\n                    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),\n                    hintText: '0',\n                    hintStyle: GB.display(40, color: GB.inkMuted.withValues(alpha: .4)),\n                    suffixText: 'đ',")
# gợi ý nhanh: chip hồng nhạt có viền
a = m.index("                GestureDetector(\n                  onTap: () => setState(() => amount.text = (amt + p).toString()),")
b = m.index("                ),\n            ]),\n          ]),\n        ),\n        const SizedBox(height: 12),\n        GlassCard(\n          radius: 24,\n          padding: const EdgeInsets.all(14),")
m = m[:a] + "                PillChip(label: '+${GB.vndShort(p)}', on: false, height: 36, icon: Icons.add_rounded, iconColor: GB.accentDeep, onTap: () => setState(() => amount.text = (amt + p).toString())),\n" + m[b + len("                ),\n"):]
# nhãn
m = rep(m, "            Row(children: [\n              Expanded(child: Text('Nhãn (chọn nhiều)', style: GB.body(13.5, w: FontWeight.w800))),\n            ]),\n            const SizedBox(height: 8),",
        "            const FormHeader('Nhãn', Icons.sell_rounded, color: Color(0xFFE6DEF5), hint: 'Chọn một hoặc nhiều nhãn'),")
m = rep(m, "              for (final t in tagList) PillChip(label: t.label, on: tags.contains(t.id), onTap:",
        "              for (final t in tagList) PillChip(label: t.label, on: tags.contains(t.id), color: tagColor(t).$1, dot: tagColor(t).$2, onTap:")
# chi tiết: bọc thẻ, biểu tượng
a = m.index("        Text('Chi tiết (tuỳ chọn)', style: GB.body(13.5, w: FontWeight.w800, color: GB.inkMuted)),")
b = m.index("        const SizedBox(height: 6),\n        Text('Ảnh chỉ lưu trên máy.'")
new = """        GlassCard(
          radius: 24,
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const FormHeader('Chi tiết', Icons.receipt_long_rounded, color: Color(0xFFFBE3CF), hint: 'Không bắt buộc'),
            GlassField(controller: title, label: 'Tên món / loại hàng', hint: 'Ví dụ: tã dán size M', icon: Icons.shopping_bag_rounded),
            const SizedBox(height: 10),
            GlassField(controller: code, label: 'Mã hàng / SKU / mã vạch', icon: Icons.qr_code_2_rounded, iconColor: GB.info),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: GlassField(controller: qty, label: 'Số lượng', icon: Icons.numbers_rounded, iconColor: GB.ok, keyboard: const TextInputType.numberWithOptions(decimal: true), onChanged: (_) => _autoTotal())),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: GlassField(controller: unit, label: 'Đơn giá', suffix: 'đ', icon: Icons.sell_outlined, iconColor: GB.warn, onChanged: (_) => _autoTotal())),
            ]),
            const SizedBox(height: 10),
            GlassField(controller: store, label: 'Nơi mua', icon: Icons.storefront_rounded, iconColor: GB.health),
            const SizedBox(height: 10),
            if (app.members.length > 1) ...[
              Wrap(spacing: 8, runSpacing: 8, children: [
                PillChip(label: 'Ai chi: chưa chọn', on: payer.isEmpty, icon: Icons.person_outline_rounded, iconColor: GB.accentDeep, onTap: () => setState(() => payer = '')),
                for (final m in app.members) PillChip(label: m.name, on: payer == m.name, icon: Icons.person_rounded, iconColor: GB.accentDeep, onTap: () => setState(() => payer = m.name)),
              ]),
              const SizedBox(height: 10),
            ],
            GlassField(controller: note, label: 'Ghi chú', maxLines: 2, icon: Icons.edit_note_rounded, iconColor: GB.accentDeep),
          ]),
        ),
        const SizedBox(height: 12),
        GlassCard(
          radius: 24,
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const FormHeader('Ảnh', Icons.photo_camera_rounded, color: Color(0xFFDCEBF5), hint: 'Hoá đơn, sản phẩm. Ảnh chỉ lưu trên máy'),
            Wrap(spacing: 10, runSpacing: 10, children: [
              for (final p in photos) PhotoThumb(p, size: 72, onRemove: () => setState(() => photos.remove(p))),
              AddPhotoButton(size: 72, onTap: () async {
                final id = await pickAndStorePhoto(context);
                if (id != null) setState(() => photos.add(id));
              }),
            ]),
          ]),
        ),
"""
c_end = m.index("      ],\n    );\n  }\n}\n\nclass TimeRowMoney")
m = m[:a] + new + m[c_end:]
# nút nhãn mới
m = rep(m, "border: Border.all(color: const Color(0xFFB79F88), width: 1.5)", "border: Border.all(color: GB.accent.withValues(alpha: .75), width: 1.5)")
wr(r'ui\money.dart', m)
print('money ok')

# ---------- màn Thêm vào quỹ
f = rd(r'ui\fund.dart')
f = rep(f, "      title: edit == null ? 'Thêm vào quỹ' : 'Sửa khoản quỹ',", "      title: edit == null ? 'Thêm vào quỹ' : 'Sửa khoản quỹ',\n      titleArt: 'ic_fund',")
a = f.index("        Wrap(spacing: 8, runSpacing: 8, children: [\n          for (final t in AssetType.values) PillChip")
b = f.index("      ],\n    );\n  }\n}\n\n/// Chi tiết một khoản")
body = f[a:b]
# tách các phần cũ
new_children = """        GlassCard(
          radius: 24,
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const FormHeader('Loại tài sản', Icons.category_rounded, color: Color(0xFFE6DEF5), hint: 'Tiền mặt, sổ tiết kiệm, vàng…'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final t in AssetType.values) PillChip(label: _typeInfo[t]!.$1, on: type == t, color: _typeInfo[t]!.$2, icon: _typeInfo[t]!.$4, iconColor: _typeInfo[t]!.$3, onTap: () => setState(() => type = t)),
            ]),
          ]),
        ),
        const SizedBox(height: 12),
        GlassCard(
          radius: 24,
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            FormHeader('Thông tin khoản', _typeInfo[type]!.$4, color: _typeInfo[type]!.$2, hint: 'Tên và giá trị'),
            GlassField(controller: name, label: type == AssetType.gold ? 'Tên (vàng nhẫn 9999…)' : type == AssetType.saving ? 'Tên sổ (Sổ tiết kiệm 12 tháng…)' : 'Tên khoản', icon: Icons.drive_file_rename_outline_rounded),
            const SizedBox(height: 10),
"""
# giữ phần điều kiện vàng/tiền từ body cũ: lấy từ "        if (type == AssetType.gold) ...[" đến trước "        const SizedBox(height: 10),\n        Text('Ai đang giữ'"
g0 = body.index("        if (type == AssetType.gold) ...[")
g1 = body.index("        const SizedBox(height: 10),\n        Text('Ai đang giữ'")
mid = body[g0:g1]
mid = mid.replace("GlassField(controller: qty, label: 'Số lượng',", "GlassField(controller: qty, label: 'Số lượng', icon: Icons.scale_rounded, iconColor: GB.ok,")
mid = mid.replace("GlassField(controller: buy, label: 'Giá mua mỗi $unit',", "GlassField(controller: buy, label: 'Giá mua mỗi $unit', icon: Icons.shopping_cart_rounded, iconColor: GB.warn,")
mid = mid.replace("GlassField(controller: cur, label: 'Giá hiện tại mỗi $unit (nhập tay)',", "GlassField(controller: cur, label: 'Giá hiện tại mỗi $unit (nhập tay)', icon: Icons.trending_up_rounded, iconColor: GB.ok,")
mid = mid.replace("GlassField(controller: amount, label: 'Số tiền (gõ 20tr, 500k…)',", "GlassField(controller: amount, label: 'Số tiền (gõ 20tr, 500k…)', icon: Icons.payments_rounded, iconColor: GB.ok,")
mid = mid.replace("GlassField(controller: rate, label: 'Lãi suất %/năm',", "GlassField(controller: rate, label: 'Lãi suất %/năm', icon: Icons.percent_rounded, iconColor: GB.info,")
mid = mid.replace("const Icon(Icons.event_rounded)", "Icon(Icons.event_rounded, color: GB.info)")
new_children += mid + """          ]),
        ),
        const SizedBox(height: 12),
        GlassCard(
          radius: 24,
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const FormHeader('Ai đang giữ', Icons.family_restroom_rounded, color: Color(0xFFF8DEDF), hint: 'Chạm để chọn nhanh'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final h in holders) PillChip(label: '$h giữ', on: holder.text == '$h giữ', icon: Icons.person_rounded, iconColor: GB.accentDeep, onTap: () => setState(() => holder.text = holder.text == '$h giữ' ? '' : '$h giữ')),
            ]),
            const SizedBox(height: 10),
            GlassField(controller: holder, label: 'Hoặc nhập người giữ', icon: Icons.person_add_alt_1_rounded, onChanged: (_) => setState(() {})),
            const SizedBox(height: 10),
            GlassField(controller: note, label: 'Ghi chú (ai tặng, dịp nào…)', maxLines: 2, icon: Icons.edit_note_rounded),
          ]),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () async {
            final d = await pickDateTime(context, date, timeToo: false, last: DateTime.now());
            if (d != null) setState(() => date = d);
          },
          child: GlassCard(radius: 20, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), blur: 14, child: Row(children: [Icon(Icons.today_rounded, color: GB.info), const SizedBox(width: 12), Text('Ngày', style: GB.body(13, w: FontWeight.w600, color: GB.inkMuted)), const SizedBox(width: 8), Expanded(child: Text(GB.dmy(date), style: GB.body(15, w: FontWeight.w700))), Text('Sửa', style: GB.body(13, w: FontWeight.w700, color: GB.accentDeep))])),
        ),
        const SizedBox(height: 12),
        GlassCard(
          radius: 24,
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const FormHeader('Ảnh', Icons.photo_camera_rounded, color: Color(0xFFDCEBF5), hint: 'Sổ tiết kiệm, biên nhận. Ảnh chỉ lưu trên máy'),
            Wrap(spacing: 10, runSpacing: 10, children: [
              for (final p in photos) PhotoThumb(p, onRemove: () => setState(() => photos.remove(p))),
              AddPhotoButton(onTap: () async {
                final id = await pickAndStorePhoto(context);
                if (id != null) setState(() => photos.add(id));
              }),
            ]),
          ]),
        ),
"""
f = f[:a] + new_children + f[b:]
wr(r'ui\fund.dart', f)
print('fund ok')
