import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/kit.dart';
import '../core/theme.dart';

class NoiseKind {
  const NoiseKind(this.id, this.name, this.icon, this.desc);
  final String id;
  final String name;
  final IconData icon;
  final String desc;
}

const kNoises = <NoiseKind>[
  NoiseKind('white', 'Trắng', Icons.graphic_eq_rounded, 'Âm đều, che tiếng ồn'),
  NoiseKind('pink', 'Hồng', Icons.waves_rounded, 'Êm hơn, giống tiếng thác xa'),
  NoiseKind('brown', 'Nâu', Icons.volume_down_rounded, 'Trầm, giống tiếng gió'),
  NoiseKind('rain', 'Mưa', Icons.water_drop_rounded, 'Mưa rơi đều'),
  NoiseKind('fan', 'Quạt', Icons.air_rounded, 'Tiếng quạt máy'),
  NoiseKind('waves', 'Sóng', Icons.beach_access_rounded, 'Sóng vỗ nhẹ'),
  NoiseKind('heart', 'Nhịp tim', Icons.favorite_rounded, 'Nhịp tim mẹ trong bụng'),
  NoiseKind('shush', 'Suỵt suỵt', Icons.record_voice_over_rounded, 'Tiếng "suỵt" dỗ bé'),
];

/// Tạo âm thanh bằng code (không cần tệp âm thanh, không vướng bản quyền) và phát lặp.
class NoiseEngine extends ChangeNotifier {
  final AudioPlayer _p = AudioPlayer();
  final Map<String, Uint8List> _cache = {};
  String? current;
  bool playing = false;
  double volume = .6;
  Duration? remaining;
  Timer? _tick;
  int timerMin = 0; // 0 = không hẹn giờ

  Future<void> play(String id) async {
    current = id;
    notifyListeners();
    final bytes = _cache.putIfAbsent(id, () => _wav(_generate(id, 16000, id == 'heart' ? 6.4 : 8.0), 16000));
    await _p.setReleaseMode(ReleaseMode.loop);
    await _p.setVolume(volume);
    await _p.play(BytesSource(bytes, mimeType: 'audio/wav'));
    playing = true;
    _startTimer();
    notifyListeners();
  }

  Future<void> stop() async {
    await _p.stop();
    playing = false;
    _tick?.cancel();
    remaining = null;
    notifyListeners();
  }

  Future<void> setVolume(double v) async {
    volume = v;
    await _p.setVolume(v);
    notifyListeners();
  }

  void setTimer(int minutes) {
    timerMin = minutes;
    if (playing) _startTimer();
    notifyListeners();
  }

  void _startTimer() {
    _tick?.cancel();
    if (timerMin <= 0) {
      remaining = null;
      return;
    }
    remaining = Duration(minutes: timerMin);
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      final r = remaining;
      if (r == null) return;
      if (r.inSeconds <= 1) {
        stop();
      } else {
        remaining = r - const Duration(seconds: 1);
        notifyListeners();
      }
    });
  }

  static Float64List _generate(String id, int rate, double seconds) {
    final n = (rate * seconds).round();
    final out = Float64List(n);
    final rnd = math.Random(id.hashCode);
    double w() => rnd.nextDouble() * 2 - 1;
    var b0 = 0.0, b1 = 0.0, b2 = 0.0, b3 = 0.0, b4 = 0.0, b5 = 0.0, b6 = 0.0;
    double pink() {
      final x = w();
      b0 = 0.99886 * b0 + x * 0.0555179;
      b1 = 0.99332 * b1 + x * 0.0750759;
      b2 = 0.96900 * b2 + x * 0.1538520;
      b3 = 0.86650 * b3 + x * 0.3104856;
      b4 = 0.55000 * b4 + x * 0.5329522;
      b5 = -0.7616 * b5 - x * 0.0168980;
      final p = b0 + b1 + b2 + b3 + b4 + b5 + b6 + x * 0.5362;
      b6 = x * 0.115926;
      return p * 0.11;
    }

    var brownLast = 0.0;
    double brown() {
      brownLast = (brownLast + 0.02 * w()) / 1.02;
      return brownLast * 3.5;
    }

    var drop = 0.0, lp = 0.0;
    for (var i = 0; i < n; i++) {
      final t = i / rate;
      double v;
      switch (id) {
        case 'white':
          v = w() * .5;
        case 'pink':
          v = pink();
        case 'brown':
          v = brown();
        case 'rain':
          if (rnd.nextDouble() < 0.0016) drop = .5 + rnd.nextDouble() * .5;
          drop *= .985;
          v = pink() * .45 + drop * w() * .55;
        case 'fan':
          v = brown() * .7 + math.sin(2 * math.pi * 110 * t) * .05 * (1 + .2 * math.sin(2 * math.pi * 0.5 * t)) + math.sin(2 * math.pi * 220 * t) * .025;
        case 'waves':
          final m = 0.5 + 0.5 * math.sin(2 * math.pi * t / seconds * 1 - math.pi / 2);
          v = pink() * (0.2 + 0.8 * math.pow(m, 1.5));
        case 'heart':
          final beat = 0.8;
          final ph = t % beat;
          double thump(double at, double f, double amp, double decay) => ph >= at ? math.sin(2 * math.pi * f * (ph - at)) * amp * math.exp(-(ph - at) * decay) : 0;
          v = brown() * .12 + thump(0, 55, .9, 26) + thump(0.28, 46, .6, 30);
        case 'shush':
          final ph = (t % 2.0) / 2.0;
          final env = ph < .7 ? math.pow(math.sin(math.pi * ph / .7), 2).toDouble() : 0.04;
          final x = w();
          lp += (x - lp) * .25;
          v = (x - lp) * env * .9;
        default:
          v = 0;
      }
      out[i] = v;
    }
    // chuẩn hoá và làm mượt hai đầu để lặp không bị lách tách
    var peak = 0.0;
    for (final x in out) {
      peak = math.max(peak, x.abs());
    }
    final g = peak == 0 ? 1.0 : .8 / peak;
    final fade = (rate * .02).round();
    for (var i = 0; i < n; i++) {
      var f = 1.0;
      if (i < fade) f = i / fade;
      if (i > n - fade) f = (n - i) / fade;
      out[i] = out[i] * g * f;
    }
    return out;
  }

  static Uint8List _wav(Float64List s, int rate) {
    final dataLen = s.length * 2;
    final b = ByteData(44 + dataLen);
    void str(int o, String t) {
      for (var i = 0; i < t.length; i++) {
        b.setUint8(o + i, t.codeUnitAt(i));
      }
    }

    str(0, 'RIFF');
    b.setUint32(4, 36 + dataLen, Endian.little);
    str(8, 'WAVE');
    str(12, 'fmt ');
    b.setUint32(16, 16, Endian.little);
    b.setUint16(20, 1, Endian.little);
    b.setUint16(22, 1, Endian.little);
    b.setUint32(24, rate, Endian.little);
    b.setUint32(28, rate * 2, Endian.little);
    b.setUint16(32, 2, Endian.little);
    b.setUint16(34, 16, Endian.little);
    str(36, 'data');
    b.setUint32(40, dataLen, Endian.little);
    for (var i = 0; i < s.length; i++) {
      b.setInt16(44 + i * 2, (s[i].clamp(-1.0, 1.0) * 32767).round(), Endian.little);
    }
    return b.buffer.asUint8List();
  }
}

final noise = NoiseEngine();

class NoiseScreen extends StatelessWidget {
  const NoiseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: noise,
      builder: (context, _) {
        final cur = kNoises.where((k) => k.id == noise.current).firstOrNull;
        return SubPage(
          title: 'Tiếng ồn trắng',
          subtitle: 'Âm thanh êm dịu giúp bé ngủ ngon',
          art: 'baby_sleep',
          artWidth: 110,
          bottom: BigButton(noise.playing ? 'Dừng' : (cur == null ? 'Chọn một âm để phát' : 'Phát ${cur.name}'), icon: noise.playing ? Icons.stop_rounded : Icons.play_arrow_rounded, color: noise.playing ? GB.ink : GB.accent, fg: noise.playing ? GB.cream : GB.ink, enabled: cur != null, onTap: () => noise.playing ? noise.stop() : noise.play(cur!.id)),
          children: [
            ...pairRows([
              for (final k in kNoises)
                GlassCard(
                  radius: 22,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  tint: noise.current == k.id ? GB.warnBg : null,
                  opacity: noise.current == k.id ? .9 : .5,
                  onTap: () => noise.play(k.id),
                  child: Row(children: [
                    Orb(icon: k.icon, color: noise.current == k.id && noise.playing ? GB.accent : GB.p(Color(0xFFE3E6F6)), size: 38),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(k.name, style: GB.body(14.5, w: FontWeight.w800)),
                        Text(k.desc, style: GB.body(11, color: GB.inkMuted, height: 1.25)),
                      ]),
                    ),
                  ]),
                ),
            ]),
            const SectionTitle('Hẹn giờ tắt'),
            Seg(labels: const ['Không', '15 phút', '30 phút', '60 phút'], index: const [0, 15, 30, 60].indexOf(noise.timerMin).clamp(0, 3), height: 42, onChanged: (i) => noise.setTimer(const [0, 15, 30, 60][i])),
            if (noise.remaining != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Tắt sau ${noise.remaining!.inMinutes}:${GB.two(noise.remaining!.inSeconds % 60)}', style: GB.body(13, w: FontWeight.w700, color: GB.accentDeep))),
            const SectionTitle('Âm lượng'),
            GlassCard(
              radius: 22,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(children: [
                const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.volume_mute_rounded)),
                Expanded(child: Slider(value: noise.volume, activeColor: GB.accent, onChanged: noise.setVolume)),
                const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.volume_up_rounded)),
              ]),
            ),
            const SizedBox(height: 10),
            Text('Nên đặt âm lượng vừa phải và đặt thiết bị cách xa tầm với của bé (khuyến cáo giữ dưới khoảng 50 dB, cách giường bé ít nhất 2 mét). Âm thanh được tạo bằng thuật toán nên không cần tải tệp.', style: GB.body(11.5, color: GB.inkMuted, height: 1.4)),
          ],
        );
      },
    );
  }
}
