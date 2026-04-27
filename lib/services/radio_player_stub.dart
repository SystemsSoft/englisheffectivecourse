// ─── Implementação NATIVA (Android / iOS / Desktop) ──────────────────────────
// Usa just_audio normalmente.
import 'dart:async';
import 'package:just_audio/just_audio.dart';

class RadioPlayer {
  final AudioPlayer _player = AudioPlayer();

  Stream<bool> get playingStream => _player.playingStream;

  bool get playing => _player.playing;

  Future<void> setUrl(String url) async {
    await _player.setUrl(url);
  }

  Future<void> play() async {
    await _player.play();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> stop() async {
    await _player.stop();
  }

  void dispose() {
    _player.dispose();
  }
}

