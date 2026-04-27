// ─── Implementação WEB ────────────────────────────────────────────────────────
// Usa dart:html AudioElement diretamente, SEM o atributo crossOrigin.
// Isso permite que o browser reproduza qualquer stream de áudio externo
// sem precisar de cabeçalhos CORS no servidor.
import 'dart:async';
import 'dart:html' as html;

class RadioPlayer {
  html.AudioElement? _el;
  bool _playing = false;
  bool _disposed = false;

  final _playingController = StreamController<bool>.broadcast();

  /// Stream que emite true quando tocando, false quando pausado/parado.
  Stream<bool> get playingStream => _playingController.stream;

  bool get playing => _playing;

  /// Carrega a URL e prepara o player (sem iniciar a reprodução).
  Future<void> setUrl(String url) async {
    _destroyElement();
    _el = html.AudioElement()
      ..preload = 'none'
      ..src = url;
    // NÃO definimos crossOrigin → sem restrição de CORS

    _el!.onPlay.listen((_) {
      if (_disposed) return;
      _playing = true;
      _playingController.add(true);
    });
    _el!.onPause.listen((_) {
      if (_disposed) return;
      _playing = false;
      _playingController.add(false);
    });
    _el!.onEnded.listen((_) {
      if (_disposed) return;
      _playing = false;
      _playingController.add(false);
    });
    _el!.onError.listen((_) {
      if (_disposed) return;
      _playing = false;
      _playingController.add(false);
    });
  }

  Future<void> play() async {
    if (_el == null) return;
    try {
      await _el!.play();
    } catch (_) {
      // Ignora erros de reprodução (ex.: autoplay policy)
    }
  }

  Future<void> pause() async {
    _el?.pause();
  }

  Future<void> stop() async {
    _destroyElement();
    if (!_disposed) _playingController.add(false);
  }

  void _destroyElement() {
    _el?.pause();
    try {
      _el?.src = '';
    } catch (_) {}
    _el = null;
    _playing = false;
  }

  void dispose() {
    _disposed = true;
    _destroyElement();
    _playingController.close();
  }
}

