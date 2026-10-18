import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gin_baby/core/kit.dart';
import 'package:gin_baby/core/theme.dart';

/// Nút nền nhạt (vd. Ngủ ngay màu bạc hà ở chế độ tối) phải dùng chữ tối; nút chính và nền đậm dùng chữ trắng.
Color _textColor(WidgetTester t) => t.widget<Text>(find.text('Nút')).style!.color!;

Future<void> _show(WidgetTester t, Color? color) => t.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: BigButton('Nút', color: color, onTap: () {})))));

void main() {
  testWidgets('nút nền nhạt dùng chữ tối', (t) async {
    await _show(t, const Color(0xFFB0F0DC));
    expect(_textColor(t), const Color(0xFF2A2433));
  });

  testWidgets('nút nền đậm dùng chữ trắng', (t) async {
    await _show(t, const Color(0xFF86AA82));
    expect(_textColor(t), Colors.white);
  });

  testWidgets('nút chính (màu nhấn) luôn chữ trắng ở cả hai chế độ', (t) async {
    for (final dark in [false, true]) {
      GB.dark = dark;
      await _show(t, null);
      expect(_textColor(t), Colors.white, reason: dark ? 'tối' : 'sáng');
    }
    GB.dark = false;
  });
}
