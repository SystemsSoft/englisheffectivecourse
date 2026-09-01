// Sintetiza o tom de "chamando" (padrão brasileiro: ~425Hz, 1s ligado /
// 4s desligado) via Web Audio API, sem depender de nenhum arquivo de áudio.
import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

const double _kRingFrequencyHz = 425;
const double _kRingOnSeconds = 1.0;
const Duration _kRingCycle = Duration(seconds: 5);

class MeganRingbackPlayer {
  web.AudioContext? _ctx;
  web.OscillatorNode? _oscillator;
  web.GainNode? _gain;
  Timer? _cycleTimer;

  Future<void> start() async {
    if (_ctx != null) return;

    final ctx = web.AudioContext();
    _ctx = ctx;
    await ctx.resume().toDart;

    final oscillator = ctx.createOscillator()
      ..type = 'sine'
      ..frequency.setValueAtTime(_kRingFrequencyHz, ctx.currentTime);
    final gain = ctx.createGain()..gain.setValueAtTime(0, ctx.currentTime);

    oscillator.connect(gain);
    gain.connect(ctx.destination);
    oscillator.start();

    _oscillator = oscillator;
    _gain = gain;

    _ring();
    _cycleTimer = Timer.periodic(_kRingCycle, (_) => _ring());
  }

  void _ring() {
    final ctx = _ctx;
    final gain = _gain;
    if (ctx == null || gain == null) return;

    final now = ctx.currentTime;
    const fade = 0.02;
    gain.gain
      ..cancelScheduledValues(now)
      ..setValueAtTime(0, now)
      ..linearRampToValueAtTime(0.18, now + fade)
      ..setValueAtTime(0.18, now + _kRingOnSeconds - fade)
      ..linearRampToValueAtTime(0, now + _kRingOnSeconds);
  }

  Future<void> stop() async {
    _cycleTimer?.cancel();
    _cycleTimer = null;
    try {
      _oscillator?.stop();
    } catch (_) {
      // já pode ter parado
    }
    _oscillator = null;
    _gain = null;
    await _ctx?.close().toDart;
    _ctx = null;
  }
}
