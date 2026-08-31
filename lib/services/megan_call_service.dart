import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'megan_audio_io.dart';
import '../utils/api_config.dart';

/// Orquestra a chamada de voz com a Megan: abre o WebSocket de relay
/// (`/ws/megan/{userId}`), trata o handshake `session_ready`/`error` e, a
/// partir daí, fala o protocolo bruto `BidiGenerateContent` da Gemini Live
/// API — capturando o microfone (PCM 16kHz) e tocando a resposta (PCM 24kHz).
class MeganCallService {
  MeganCallService({
    required this.userId,
    required this.onSessionReady,
    required this.onServerError,
    required this.onMeganSpeakingChanged,
    required this.onClosed,
  });

  final String userId;

  /// Chamado ao receber o primeiro frame `session_ready` do servidor.
  final void Function(int day, String topic) onSessionReady;

  /// Chamado quando o servidor não conseguiu iniciar a sessão com a Gemini,
  /// ou quando a conexão falha/cai.
  final void Function(String message) onServerError;

  /// Chamado a cada mudança de "Megan está falando" (true) / silêncio (false).
  final void Function(bool speaking) onMeganSpeakingChanged;

  /// Chamado quando o socket é fechado (pelo servidor ou pelo aluno).
  final void Function() onClosed;

  WebSocketChannel? _channel;
  StreamSubscription? _socketSubscription;
  StreamSubscription? _micSubscription;
  MeganMicCapture? _micCapture;
  final MeganAudioPlayback _playback = MeganAudioPlayback();

  bool _sessionReadyReceived = false;
  bool _closing = false;
  bool _muted = false;

  /// Silencia/reativa o envio de áudio do microfone para a Megan. O
  /// microfone continua capturando (não fecha a track), só paramos de
  /// repassar os chunks pro socket.
  void setMuted(bool muted) => _muted = muted;

  /// Pede permissão de microfone e abre a chamada. [onSessionReady] ou
  /// [onServerError] é chamado assim que o handshake inicial responder.
  Future<void> start() async {
    final micCapture = MeganMicCapture();
    _micCapture = micCapture;
    await micCapture.start();
    await _playback.init();

    final uri = Uri.parse('${ApiConfig.wsBaseUrl}/ws/megan/${Uri.encodeComponent(userId)}');
    final channel = WebSocketChannel.connect(uri);
    _channel = channel;

    _socketSubscription = channel.stream.listen(
      _handleSocketData,
      onError: (Object error, StackTrace _) {
        onServerError('Conexão com a Megan perdida: $error');
        onClosed();
      },
      onDone: () {
        if (!_closing) onClosed();
      },
    );

    _micSubscription = micCapture.onChunk.listen(_sendAudioChunk);
  }

  void _sendAudioChunk(Uint8List pcm16) {
    if (_muted) return;
    _channel?.sink.add(jsonEncode({
      'realtimeInput': {
        'audio': {
          'data': base64Encode(pcm16),
          'mimeType': 'audio/pcm;rate=16000',
        },
      },
    }));
  }

  void _handleSocketData(dynamic event) {
    final String text;
    if (event is String) {
      text = event;
    } else if (event is List<int>) {
      text = utf8.decode(event);
    } else {
      return;
    }

    final Map<String, dynamic> msg;
    try {
      msg = jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    if (!_sessionReadyReceived) {
      _sessionReadyReceived = true;
      if (msg['type'] == 'session_ready') {
        onSessionReady(msg['day'] as int, msg['topic'] as String);
        return;
      }
      if (msg['type'] == 'error') {
        onServerError(msg['message'] as String? ?? 'Não foi possível iniciar a chamada com a Megan agora.');
        return;
      }
    }

    _handleGeminiEvent(msg);
  }

  void _handleGeminiEvent(Map<String, dynamic> msg) {
    final serverContent = msg['serverContent'] as Map<String, dynamic>?;
    if (serverContent == null) return;

    if (serverContent['interrupted'] == true) {
      _playback.clearQueue();
      onMeganSpeakingChanged(false);
      return;
    }

    final parts = (serverContent['modelTurn']
        as Map<String, dynamic>?)?['parts'] as List?;
    var playedSomething = false;
    for (final part in parts ?? const []) {
      final b64 = (part as Map<String, dynamic>)['inlineData']?['data'] as String?;
      if (b64 != null) {
        _playback.enqueuePcm16(base64Decode(b64));
        playedSomething = true;
      }
    }
    if (playedSomething) onMeganSpeakingChanged(true);

    if (serverContent['turnComplete'] == true) {
      onMeganSpeakingChanged(false);
    }
  }

  /// Encerra a chamada: fecha o socket e libera microfone/alto-falante.
  Future<void> hangUp() async {
    _closing = true;
    await _micSubscription?.cancel();
    await _socketSubscription?.cancel();
    await _micCapture?.stop();
    await _playback.dispose();
    await _channel?.sink.close();
  }
}
