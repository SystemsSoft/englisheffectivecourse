// Implementação Web: captura o microfone como PCM 16kHz cru via AudioWorklet
// e toca de volta o áudio da Megan (PCM 24kHz) através de uma fila de
// AudioBufferSourceNode agendados sequencialmente, sem cortes entre chunks.
import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

const int _kMicSampleRate = 16000;
const int _kPlaybackSampleRate = 24000;

class MeganMicCapture {
  web.MediaStream? _mediaStream;
  web.AudioContext? _audioContext;
  web.AudioWorkletNode? _workletNode;
  final _chunkController = StreamController<Uint8List>.broadcast();

  Stream<Uint8List> get onChunk => _chunkController.stream;

  /// Pede permissão de microfone e inicia a captura PCM16 a 16kHz.
  /// Lança [DOMException] se o usuário negar a permissão.
  Future<void> start() async {
    final stream = await web.window.navigator.mediaDevices
        .getUserMedia(
          web.MediaStreamConstraints(
            audio: web.MediaTrackConstraints(
              channelCount: 1.toJS,
              sampleRate: _kMicSampleRate.toJS,
            ),
            video: false.toJS,
          ),
        )
        .toDart;
    _mediaStream = stream;

    final ctx = web.AudioContext(
      web.AudioContextOptions(sampleRate: _kMicSampleRate),
    );
    _audioContext = ctx;

    await ctx.audioWorklet.addModule('/audio/pcm-worklet.js').toDart;

    final source = ctx.createMediaStreamSource(stream);
    final node = web.AudioWorkletNode(ctx, 'pcm-capture-processor');
    _workletNode = node;

    node.port.onmessage = ((web.MessageEvent event) {
      final data = event.data;
      if (data.isA<JSArrayBuffer>()) {
        final buffer = (data as JSArrayBuffer).toDart;
        _chunkController.add(buffer.asUint8List());
      }
    }).toJS;

    source.connect(node);
  }

  /// Libera o microfone e fecha o AudioContext de captura.
  Future<void> stop() async {
    for (final track in _mediaStream?.getTracks().toDart ?? const []) {
      track.stop();
    }
    _mediaStream = null;
    _workletNode?.port.close();
    _workletNode = null;
    await _audioContext?.close().toDart;
    _audioContext = null;
    await _chunkController.close();
  }
}

class MeganAudioPlayback {
  web.AudioContext? _audioContext;
  double _nextStart = 0;
  final List<web.AudioBufferSourceNode> _scheduled = [];

  Future<void> init() async {
    _audioContext ??= web.AudioContext(
      web.AudioContextOptions(sampleRate: _kPlaybackSampleRate),
    );
  }

  /// Agenda a reprodução de um chunk PCM 16-bit a 24kHz, encadeando após o
  /// chunk anterior para não haver sobreposição/cortes.
  void enqueuePcm16(Uint8List pcm16Bytes) {
    final ctx = _audioContext;
    if (ctx == null) return;

    final samples = pcm16Bytes.buffer.asInt16List(
      pcm16Bytes.offsetInBytes,
      pcm16Bytes.lengthInBytes ~/ 2,
    );
    final floats = Float32List(samples.length);
    for (var i = 0; i < samples.length; i++) {
      floats[i] = samples[i] / 32768.0;
    }

    final buffer = ctx.createBuffer(1, floats.length, _kPlaybackSampleRate);
    buffer.copyToChannel(floats.toJS, 0);

    final source = ctx.createBufferSource()..buffer = buffer;
    source.connect(ctx.destination);

    final startAt = _nextStart < ctx.currentTime ? ctx.currentTime : _nextStart;
    source.start(startAt);
    _nextStart = startAt + buffer.duration;

    _scheduled.add(source);
  }

  /// Esvazia a fila de reprodução (aluno interrompeu a Megan no meio da fala).
  void clearQueue() {
    for (final source in _scheduled) {
      try {
        source.stop();
      } catch (_) {
        // já pode ter terminado a reprodução
      }
    }
    _scheduled.clear();
    _nextStart = _audioContext?.currentTime ?? 0;
  }

  Future<void> dispose() async {
    clearQueue();
    await _audioContext?.close().toDart;
    _audioContext = null;
  }
}
