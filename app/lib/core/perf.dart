import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../data/app_state.dart';
import 'theme.dart';

final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

/// Theo dõi độ mượt: nếu nhiều khung hình bị chậm liên tục, tự bật chế độ nhẹ (tắt làm mờ kính).
class PerfGuard {
  static bool _started = false;
  static bool _done = false;
  static int _total = 0;
  static int _slow = 0;
  static final DateTime _t0 = DateTime.now();

  static void start() {
    if (_started) return;
    _started = true;
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  static void _onTimings(List<FrameTiming> ts) {
    if (_done || glassLite.value) return;
    if (DateTime.now().difference(_t0).inSeconds < 10) return; // bỏ qua giai đoạn khởi động
    for (final t in ts) {
      _total++;
      if (t.totalSpan.inMilliseconds > 26) _slow++;
      if (_total >= 300) {
        final ratio = _slow / _total;
        _total = 0;
        _slow = 0;
        if (ratio > .4) {
          _done = true;
          app.settings.lite = true;
          app.settingsChanged();
          messengerKey.currentState?.showSnackBar(const SnackBar(content: Text('Máy hơi chậm, đã bật chế độ nhẹ cho mượt hơn. Có thể đổi trong Cài đặt.')));
          return;
        }
      }
    }
  }
}
