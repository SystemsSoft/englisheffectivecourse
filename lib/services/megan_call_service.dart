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
    this.onMeganThinkingChanged,
    this.onUserTranscriptChanged,
    this.onMeganTranscriptChanged,
    this.onMeganTurnComplete,
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

  /// Chamado quando o aluno terminou de falar e a Megan ainda não começou a
  /// responder (nem em texto nem em áudio) — útil para um indicador de
  /// "pensando". Depende do backend habilitar transcrição na Gemini; se não
  /// habilitar, este callback simplesmente nunca dispara com `true`.
  final void Function(bool thinking)? onMeganThinkingChanged;

  /// Transcrição incremental do que o aluno disse na rodada atual. Só chega
  /// se o backend tiver habilitado `inputAudioTranscription` no setup da
  /// Gemini; caso contrário nunca é chamado.
  final void Function(String textSoFar)? onUserTranscriptChanged;

  /// Transcrição incremental do que a Megan está dizendo na rodada atual.
  /// Só chega se o backend tiver habilitado `outputAudioTranscription` no
  /// setup da Gemini; caso contrário nunca é chamado.
  final void Function(String textSoFar)? onMeganTranscriptChanged;

  /// Chamado quando a Megan termina uma rodada de fala (`turnComplete`), com
  /// o texto completo que ela disse nessa rodada — momento ideal para pedir
  /// a tradução, em vez de traduzir cada fragmento incremental.
  final void Function(String finalText)? onMeganTurnComplete;

  WebSocketChannel? _channel;
  StreamSubscription? _socketSubscription;
  StreamSubscription? _micSubscription;
  StreamSubscription<bool>? _vadSubscription;
  MeganMicCapture? _micCapture;
  final MeganAudioPlayback _playback = MeganAudioPlayback();

  bool _sessionReadyReceived = false;
  bool _closing = false;
  bool _socketActive = false;
  bool _muted = false;
  final StringBuffer _userTranscript = StringBuffer();
  final StringBuffer _meganTranscript = StringBuffer();

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
    _socketActive = true;

    _socketSubscription = channel.stream.listen(
      _handleSocketData,
      onError: (Object error, StackTrace _) {
        _socketActive = false;
        if (!_closing) {
          _stopMicAndPlayback();
          onServerError('Conexão com a Megan perdida: $error');
          onClosed();
        }
      },
      onDone: () {
        _socketActive = false;
        if (!_closing) {
          _stopMicAndPlayback();
          onClosed();
        }
      },
    );

    _micSubscription = micCapture.onChunk.listen(_sendAudioChunk);

    // VAD local: dá feedback imediato de "pensando" assim que o áudio
    // capturado indica silêncio sustentado, sem depender de nenhum sinal
    // do servidor/Gemini (que só chega se inputAudioTranscription estiver
    // habilitado no setup, e mesmo assim com a latência real do modelo).
    _vadSubscription = micCapture.onSpeechActivity.listen((speaking) {
      onMeganThinkingChanged?.call(!speaking);
    });
  }

  /// Manda uma saudação de texto assim que a sessão conecta, para a Megan
  /// "atender" a ligação com uma resposta natural — sem esperar o aluno
  /// falar primeiro. Usa `clientContent` (turno de texto), que é diferente
  /// de `realtimeInput.audio` e não passa pelo reconhecimento de voz, então
  /// não aparece na transcrição do aluno.
  void _sendGreeting() {
    _channel?.sink.add(jsonEncode({
      'clientContent': {
        'turns': [
          {
            'role': 'user',
            'parts': [
              {'text': 'Hi!'},
            ],
          },
        ],
        'turnComplete': true,
      },
    }));
  }

  void _sendAudioChunk(Uint8List pcm16) {
    if (_muted || !_socketActive) return;
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
        // Dispara a Megan a "atender" a ligação: manda uma saudação em
        // segundo plano, como se o aluno tivesse dito "Hi!" assim que a
        // chamada conectou.
        _sendGreeting();
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
      onMeganThinkingChanged?.call(false);
      return;
    }

    // Transcrição do que o aluno disse: chega enquanto ele ainda está
    // falando, antes de qualquer resposta da Megan — é o sinal de que a
    // Megan "ouviu" o aluno e está prestes a processar a resposta.
    final inputTranscription = serverContent['inputTranscription'] as Map<String, dynamic>?;
    final inputPiece = inputTranscription?['text'] as String?;
    if (inputPiece != null && inputPiece.isNotEmpty) {
      _userTranscript.write(inputPiece);
      onUserTranscriptChanged?.call(_userTranscript.toString());
      onMeganThinkingChanged?.call(true);
    }

    // Transcrição do que a Megan está dizendo, em paralelo ao áudio.
    final outputTranscription = serverContent['outputTranscription'] as Map<String, dynamic>?;
    final outputPiece = outputTranscription?['text'] as String?;
    if (outputPiece != null && outputPiece.isNotEmpty) {
      _meganTranscript.write(outputPiece);
      onMeganTranscriptChanged?.call(_meganTranscript.toString());
      onMeganThinkingChanged?.call(false);
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
    if (playedSomething) {
      onMeganSpeakingChanged(true);
      onMeganThinkingChanged?.call(false);
    }

    if (serverContent['turnComplete'] == true) {
      onMeganSpeakingChanged(false);
      onMeganThinkingChanged?.call(false);
      final finalText = _meganTranscript.toString();
      if (finalText.isNotEmpty) onMeganTurnComplete?.call(finalText);
      // Nova rodada: limpa os acumuladores para a próxima fala do aluno.
      _userTranscript.clear();
      _meganTranscript.clear();
    }
  }

  /// Cancela a captura de mic e libera o alto-falante. Chamado tanto no
  /// desligamento manual (hangUp) quanto quando o socket cai sozinho — sem
  /// isso, a captura continuava mandando áudio para um socket já
  /// fechado/errado, gerando erros repetidos no console.
  Future<void> _stopMicAndPlayback() async {
    await _micSubscription?.cancel();
    await _vadSubscription?.cancel();
    await _micCapture?.stop();
    await _playback.dispose();
  }

  /// Encerra a chamada: fecha o socket e libera microfone/alto-falante.
  Future<void> hangUp() async {
    if (_closing) return;
    _closing = true;
    _socketActive = false;
    await _stopMicAndPlayback();
    await _socketSubscription?.cancel();
    await _channel?.sink.close();
  }
}
