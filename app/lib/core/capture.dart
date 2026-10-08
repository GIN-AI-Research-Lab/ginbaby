import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Chụp một widget (bọc RepaintBoundary có [key]) thành ảnh PNG.
Future<Uint8List?> capturePng(GlobalKey key, {double pixelRatio = 3}) async {
  final b = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (b == null) return null;
  final img = await b.toImage(pixelRatio: pixelRatio);
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  return data?.buffer.asUint8List();
}
