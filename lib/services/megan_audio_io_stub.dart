// Implementação nativa (não-Web): a chamada de voz com a Megan hoje só é
// suportada no Flutter Web, onde a captura PCM cru via AudioWorklet é possível.
import 'dart:async';
import 'dart:typed_data';

class MeganMicCapture {
  Stream<Uint8List> get onChunk => const Stream.empty();
  Stream<bool> get onSpeechActivity => const Stream.empty();

  Future<void> start() {
    throw UnsupportedError(
      'Captura de áudio da Megan só é suportada no Flutter Web.',
    );
  }

  Future<void> stop() async {}
}

class MeganAudioPlayback {
  Future<void> init() async {}

  void enqueuePcm16(Uint8List bytes) {}

  void clearQueue() {}

  Future<void> dispose() async {}
}
