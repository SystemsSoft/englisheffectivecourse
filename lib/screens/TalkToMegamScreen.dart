import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/aluno_ia_model.dart';
import '../models/assinatura_status_model.dart';
import '../models/curriculo_model.dart';
import '../models/megan_call_state.dart';
import '../services/aluno_ia_service.dart';
import '../services/curriculo_service.dart';
import '../services/megan_call_service.dart';
import '../services/megan_ringback_player.dart';
import '../services/megan_user_resolver.dart';
import '../viewmodels/user_viewmodel.dart';
import '../app_theme.dart';

class TalkToMegamScreen extends StatefulWidget {
  const TalkToMegamScreen({super.key});

  @override
  State<TalkToMegamScreen> createState() => _TalkToMegamScreenState();
}

class _TalkToMegamScreenState extends State<TalkToMegamScreen> {
  final AlunoIaService _alunoIaService = AlunoIaService();
  final CurriculoService _curriculoService = CurriculoService();
  final MeganUserResolver _userResolver = MeganUserResolver();
  final MeganRingbackPlayer _ringback = MeganRingbackPlayer();
  MeganCallService? _callService;

  static const String _megamAvatarAsset = 'assets/logo-megan.jpeg';

  MeganCallState _state = MeganCallState.idle;
  bool _loadingAluno = true;
  String? _loadError;
  AlunoIaDto? _aluno;

  /// Só consultado quando o aluno já passou da missão 1 (ver [_loadAluno]).
  AssinaturaStatusDto? _assinaturaStatus;

  /// Todos os módulos do currículo, usados para alimentar o card "Agenda de
  /// Desafios Diários". Null se ainda não carregou ou se o endpoint
  /// /curriculo falhar (card cai num fallback).
  List<CurriculoModuloDto>? _curriculo;
  String? _curriculoError;

  /// userId (ULID) do aluno na Megan — gerado e persistido localmente na
  /// primeira vez, reutilizado nas próximas (ver [MeganUserIdStore]).
  String? _meganUserId;

  int? _day;
  String? _topic;
  bool _meganSpeaking = false;
  bool _meganThinking = false;
  String _userTranscript = '';
  String _meganTranscript = '';
  bool _muted = false;
  String? _callError;
  String? _advanceMissionError;
  bool _advancingMission = false;

  final ScrollController _transcriptScrollController = ScrollController();
  final ScrollController _dailyChallengesScrollController = ScrollController();

  static const int _callDurationLimitSeconds = 15 * 60;
  static const int _finishChallengeUnlockSeconds = 10 * 60;

  Timer? _callTimer;
  int _callSecondsRemaining = _callDurationLimitSeconds;

  Timer? _subscriptionPollTimer;
  bool _checkingSubscription = false;
  static const Duration _subscriptionPollInterval = Duration(seconds: 5);
  static const int _subscriptionPollMaxAttempts = 120; // ~10 minutos

  @override
  void initState() {
    super.initState();
    _loadAluno();
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _callService?.hangUp();
    _ringback.stop();
    _subscriptionPollTimer?.cancel();
    _transcriptScrollController.dispose();
    _dailyChallengesScrollController.dispose();
    super.dispose();
  }

  /// Busca o cadastro do aluno na Megan. Se o aluno logado ainda não tiver
  /// um userId (ULID) salvo localmente, gera um novo e já cria o cadastro
  /// automaticamente no backend — sem exibir formulário nenhum.
  Future<void> _loadAluno() async {
    final user = context.read<UserViewModel>().user!;
    setState(() {
      _loadingAluno = true;
      _loadError = null;
    });
    try {
      final (userId, aluno) = await _userResolver.resolve(user);

      // Busca sempre (não só a partir da missão 2): além de liberar
      // "Chamar a Megan", também decide se mostra "Aceitar Missão"
      // (escondido quando o aluno já tem assinatura ativa).
      final assinatura = await _alunoIaService.getAssinaturaStatus(userId);

      if (!mounted) return;
      setState(() {
        _meganUserId = userId;
        _aluno = aluno;
        _assinaturaStatus = assinatura;
        _loadingAluno = false;
      });

      // Isolado do resto: se o currículo falhar, o card mostra um
      // fallback, mas não trava a tela inteira.
      unawaited(_loadCurriculo());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Não foi possível carregar seus dados: $e';
        _loadingAluno = false;
      });
    }
  }

  /// Busca todos os módulos do currículo, para alimentar o card "Agenda de
  /// Desafios Diários" com module1 e module2 (e os que vierem depois).
  Future<void> _loadCurriculo() async {
    if (!mounted) return;
    setState(() => _curriculoError = null);
    try {
      final modulos = await _curriculoService.getCurriculo();
      if (!mounted) return;
      setState(() => _curriculo = modulos);
    } catch (e) {
      if (!mounted) return;
      setState(() => _curriculoError = '$e');
    }
  }

  /// Libera o botão "Chamar a Megan": sempre na missão 1, ou a partir da
  /// missão 2 apenas se a assinatura estiver ativa.
  bool get _canCallMegan {
    final aluno = _aluno;
    if (aluno == null) return false;
    if (aluno.missaoAtual == '1') return true;
    return _hasActiveSubscription;
  }

  /// True quando o aluno já tem assinatura ativa (statusAssinatura == ATIVA
  /// no backend).
  bool get _hasActiveSubscription => _assinaturaStatus?.ativa ?? false;

  /// Mostra o botão "Aceitar Missão" só quando faz sentido: o aluno já
  /// passou da missão 1 (onde o acesso é livre) e ainda não tem assinatura
  /// ativa.
  bool get _shouldShowAcceptMission =>
      !_hasActiveSubscription && _aluno?.missaoAtual != '1';

  void _startCallTimer() {
    _callSecondsRemaining = _callDurationLimitSeconds;
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_callSecondsRemaining <= 0) {
        timer.cancel();
        // Chamada atingiu os 15 minutos — encerra automaticamente e só
        // aqui avança a missão (nunca em desligamento manual antes do tempo).
        _completeCallAndAdvanceMission();
        return;
      }
      setState(() => _callSecondsRemaining--);
    });
  }

  /// Libera o atalho "Finalizar Desafio" depois de 10 minutos de chamada.
  bool get _canFinishChallenge =>
      (_callDurationLimitSeconds - _callSecondsRemaining) >= _finishChallengeUnlockSeconds;

  String get _formattedCallDuration {
    final minutes = (_callSecondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_callSecondsRemaining % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  void _goToPermissionStep() {
    setState(() {
      _state = MeganCallState.requestingPermission;
      _callError = null;
    });
  }

  Future<void> _acceptMission() async {
    final baseUri = Uri.parse('https://buy.stripe.com/test_8x2aEWbdj4E12mG3wY9AA01');
    // client_reference_id permite ao webhook do Stripe identificar qual
    // aluno (userId/ULID na Megan) completou o pagamento.
    final uri = baseUri.replace(queryParameters: {
      ...baseUri.queryParameters,
      'client_reference_id': _meganUserId ?? '',
    });
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      _startSubscriptionPolling();
    }
  }

  /// Depois que o aluno vai para o checkout do Stripe, fica checando em
  /// segundo plano se a assinatura virou ativa — assim que virar, libera o
  /// botão "Chamar a Megan" sem precisar recarregar a tela.
  void _startSubscriptionPolling() {
    final userId = _meganUserId;
    if (userId == null || _hasActiveSubscription) return;

    _subscriptionPollTimer?.cancel();
    setState(() => _checkingSubscription = true);

    var attempts = 0;
    _subscriptionPollTimer = Timer.periodic(_subscriptionPollInterval, (timer) async {
      attempts++;
      try {
        final status = await _alunoIaService.getAssinaturaStatus(userId);
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (status.ativa) {
          timer.cancel();
          setState(() {
            _assinaturaStatus = status;
            _checkingSubscription = false;
          });
          return;
        }
      } catch (_) {
        // Erro passageiro de rede — tenta de novo no próximo ciclo.
      }
      if (attempts >= _subscriptionPollMaxAttempts) {
        timer.cancel();
        if (mounted) setState(() => _checkingSubscription = false);
      }
    });
  }

  Future<void> _beginCall() async {
    setState(() {
      _state = MeganCallState.connecting;
      _userTranscript = '';
      _meganTranscript = '';
      _meganThinking = false;
      _advanceMissionError = null;
    });

    final service = MeganCallService(
      userId: _meganUserId!,
      onSessionReady: (day, topic) async {
        if (!mounted) return;
        setState(() {
          _day = day;
          _topic = topic;
          _state = MeganCallState.ringing;
        });
        // Toca o tom de "chamando" enquanto a saudação (mandada em segundo
        // plano pelo MeganCallService) ainda não teve resposta.
        await _ringback.start();
      },
      onServerError: (message) {
        if (!mounted) return;
        setState(() => _callError = message);
      },
      onMeganSpeakingChanged: (speaking) {
        if (!mounted) return;
        if (speaking) _handleMeganAnswered();
        setState(() => _meganSpeaking = speaking);
      },
      onMeganThinkingChanged: (thinking) {
        if (!mounted) return;
        setState(() => _meganThinking = thinking);
      },
      onUserTranscriptChanged: (text) {
        if (!mounted) return;
        setState(() => _userTranscript = text);
        _scrollTranscriptToBottom();
      },
      onMeganTranscriptChanged: (text) {
        if (!mounted) return;
        if (text.isNotEmpty) _handleMeganAnswered();
        setState(() => _meganTranscript = text);
        _scrollTranscriptToBottom();
      },
      onClosed: () {
        if (!mounted) return;
        _finishCall();
      },
    );
    _callService = service;

    try {
      await service.start();
    } catch (e) {
      if (!mounted) return;
      await _ringback.stop();
      setState(() {
        _callError = 'Não foi possível acessar o microfone: $e';
        _state = MeganCallState.idle;
      });
    }
  }

  /// Chamado assim que a Megan dá o primeiro sinal de resposta (áudio ou
  /// transcrição) — "atende" a ligação de fato: para o tom de chamando,
  /// entra na tela de chamada e só agora começa a contar os 15 minutos.
  void _handleMeganAnswered() {
    if (_state != MeganCallState.ringing) return;
    _ringback.stop();
    setState(() => _state = MeganCallState.inCall);
    _startCallTimer();
  }

  /// Rola a caixa de transcrição até o fim, para sempre mostrar a última
  /// linha do que está sendo dito. Espera o frame do setState terminar de
  /// reconstruir (para o novo texto já contar no maxScrollExtent).
  void _scrollTranscriptToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_transcriptScrollController.hasClients) return;
      _transcriptScrollController.animateTo(
        _transcriptScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  void _finishCall() {
    _callTimer?.cancel();
    _ringback.stop();
    setState(() {
      _state = MeganCallState.ended;
      _meganSpeaking = false;
      _meganThinking = false;
    });
  }

  Future<void> _hangUp() async {
    await _callService?.hangUp();
    _finishCall();
  }

  /// Chamado quando os 15 minutos são completados, ou quando o aluno clica
  /// em "Finalizar Desafio" (liberado a partir de 10 minutos) — avança a
  /// missão do aluno antes de encerrar a chamada.
  Future<void> _completeCallAndAdvanceMission() async {
    await _advanceMission();
    await _hangUp();
  }

  /// Chama POST /aluno-ia/{userId}/avancar-missao. Não silencia falhas: se
  /// der erro, guarda a mensagem para mostrar na tela de "chamada
  /// encerrada" com um botão de tentar de novo — antes o erro era ignorado
  /// e a missão simplesmente não avançava sem nenhum aviso.
  Future<void> _advanceMission() async {
    final userId = _meganUserId;
    if (userId == null) return;
    setState(() {
      _advancingMission = true;
      _advanceMissionError = null;
    });
    try {
      final atualizado = await _alunoIaService.avancarMissao(userId);
      if (!mounted) return;
      setState(() {
        _aluno = atualizado;
        _advancingMission = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _advancingMission = false;
        _advanceMissionError = 'Não foi possível avançar sua missão: $e';
      });
    }
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    _callService?.setMuted(_muted);
  }

  Future<void> _backToIdle() async {
    setState(() {
      _state = MeganCallState.idle;
      _day = null;
      _topic = null;
      _muted = false;
      _callError = null;
    });
    await _loadAluno();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F142D),
              Color(0xFF182042),
              Color(0xFF0A0D1F),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      "MEGAN",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case MeganCallState.idle:
        return _buildIdle();
      case MeganCallState.requestingPermission:
        return _buildPermissionStep();
      case MeganCallState.connecting:
        return _buildConnecting();
      case MeganCallState.ringing:
        return _buildRinging();
      case MeganCallState.inCall:
        return _buildInCall();
      case MeganCallState.ended:
        return _buildEnded();
    }
  }

  static const Color _neonCyan = Color(0xFF22E5F5);

  Widget _buildAvatar({
    bool pulsing = false,
    Color ringColor = AppColors.navyBlueLight,
    bool neonGlow = false,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (pulsing)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.95, end: 1.15),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ringColor.withValues(alpha: 0.25),
                  ),
                ),
              );
            },
          ),
        if (neonGlow)
          Container(
            width: 168,
            height: 168,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _neonCyan, width: 3),
              boxShadow: [
                BoxShadow(color: _neonCyan.withValues(alpha: 0.65), blurRadius: 22, spreadRadius: 1),
                BoxShadow(color: _neonCyan.withValues(alpha: 0.35), blurRadius: 46, spreadRadius: 6),
              ],
            ),
          ),
        Container(
          width: 140,
          height: 140,
          child: ClipOval(
            child: Image.asset(
              _megamAvatarAsset,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded, size: 80, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIdle() {
    if (_loadingAluno) {
      return const Center(child: CircularProgressIndicator(color: Colors.white70));
    }
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_loadError!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadAluno, child: const Text("Tentar novamente")),
            ],
          ),
        ),
      );
    }

    final missao = _aluno?.missaoAtual ?? '1';
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          _buildAvatar(neonGlow: true),
          const SizedBox(height: 24),
          const Text(
            "MEGAN",
            style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),
          const Text(
            "Sua Tutora de Simulação de Conversa em Tempo Real",
            style: TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Dia $missao • Missão Fluência",
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 32),
          if (_canCallMegan)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: AppColors.red.withValues(alpha: 0.55), blurRadius: 24, spreadRadius: 1),
                ],
              ),
              child: ElevatedButton(
                onPressed: _goToPermissionStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mic_rounded),
                    SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        "INICIAR SIMULAÇÃO DE CONVERSA (TEMPO REAL)",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.3),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            const Text(
              "Sua assinatura precisa estar ativa para continuar a partir "
              "da missão 2. Aceite a missão abaixo para assinar.",
              style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
              textAlign: TextAlign.center,
            ),
          if (_shouldShowAcceptMission) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _acceptMission,
                icon: const Icon(Icons.flag_rounded),
                label: const Text("Aceitar Missão"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),
          ],
          if (_checkingSubscription) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
                ),
                const SizedBox(width: 8),
                Text(
                  "Verificando pagamento...",
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                ),
              ],
            ),
          ],
          const SizedBox(height: 32),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildDailyChallengesCard()),
                const SizedBox(width: 12),
                Expanded(child: _buildImmersionCard()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyChallengesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_note_rounded, color: AppColors.redLight, size: 18),
              const SizedBox(width: 8),
              const Flexible(
                child: Text(
                  "Agenda de Desafios Diários",
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 260,
            child: RawScrollbar(
              controller: _dailyChallengesScrollController,
              thumbVisibility: true,
              interactive: true,
              thickness: 5,
              radius: const Radius.circular(8),
              thumbColor: Colors.white.withValues(alpha: 0.25),
              trackColor: Colors.white.withValues(alpha: 0.04),
              trackVisibility: true,
              child: SingleChildScrollView(
                controller: _dailyChallengesScrollController,
                padding: const EdgeInsets.only(right: 12),
                child: _buildDailyChallengesContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Extrai o número final do moduleId (ex.: "module2" -> 2), para ordenar
  /// e comparar módulos com segurança.
  int _moduleNumber(String moduleId) {
    final match = RegExp(r'(\d+)$').firstMatch(moduleId);
    return int.tryParse(match?.group(1) ?? '') ?? 0;
  }

  Widget _buildDailyChallengesContent() {
    if (_curriculoError != null) {
      return const Text(
        "Não foi possível carregar a agenda de desafios.",
        style: TextStyle(color: Colors.white38, fontSize: 11, height: 1.3),
      );
    }
    final modulos = _curriculo;
    if (modulos == null || modulos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white38),
          ),
        ),
      );
    }

    final missaoAtualInt = int.tryParse(_aluno?.missaoAtual ?? '1') ?? 1;
    final moduloAtualNumero = _moduleNumber(_aluno?.moduloAtual ?? 'module1');

    final ordenados = [...modulos]
      ..sort((a, b) => _moduleNumber(a.moduleId).compareTo(_moduleNumber(b.moduleId)));

    final children = <Widget>[];
    for (final modulo in ordenados) {
      final numero = _moduleNumber(modulo.moduleId);
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Módulo $numero',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );

      for (final dia in modulo.dias) {
        final bool concluido;
        if (numero < moduloAtualNumero) {
          concluido = true; // módulo já totalmente ultrapassado
        } else if (numero == moduloAtualNumero) {
          concluido = dia.day <= missaoAtualInt;
        } else {
          concluido = false; // módulo futuro, ainda não liberado
        }

        children.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                concluido ? Icons.check_circle_rounded : Icons.lock_rounded,
                color: concluido ? Colors.lightBlueAccent : Colors.white24,
                size: 15,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Dia ${dia.day}: ${dia.topic}',
                  style: TextStyle(
                    color: concluido ? Colors.white : Colors.white38,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        );
        children.add(const SizedBox(height: 6));
        children.add(
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: concluido ? 1 : 0,
              minHeight: 4,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation(Colors.lightBlueAccent),
            ),
          ),
        );
        children.add(const SizedBox(height: 12));
      }
    }

    // "Desbloqueado" só quando o aluno passou de todos os módulos que já
    // existem no currículo — o que vem depois é o próximo módulo, ainda
    // não implementado, representado pelo footer "Desafios bloqueados".
    final ultimoModulo = ordenados.last;
    final ultimoModuloNumero = _moduleNumber(ultimoModulo.moduleId);
    final tudoConcluido = moduloAtualNumero > ultimoModuloNumero ||
        (moduloAtualNumero == ultimoModuloNumero && missaoAtualInt > ultimoModulo.totalDias);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...children,
        _buildLockedChallengesFooter(unlocked: tudoConcluido),
      ],
    );
  }

  /// Seção final da agenda: enquanto o aluno não termina todas as missões
  /// do módulo, mostra os "desafios bloqueados" com uma animação de pulso
  /// no cadeado, incentivando a completar tudo.
  Widget _buildLockedChallengesFooter({required bool unlocked}) {
    if (unlocked) {
      return Row(
        children: [
          const Icon(Icons.emoji_events_rounded, color: Colors.amberAccent, size: 18),
          const SizedBox(width: 8),
          const Flexible(
            child: Text(
              "Parabéns! Você desbloqueou sua primeira medalha de conquista.",
              style: TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold, height: 1.3),
            ),
          ),
        ],
      );
    }

    return const _LockedChallengesFooter();
  }

  Widget _buildImmersionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.headset_mic_rounded, color: AppColors.redLight, size: 22),
          const SizedBox(height: 10),
          const Text(
            "Imersão Realista (Tempo Real)",
            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Treine em cenários autênticos. Receba feedback instantâneo da sua "
            "pronúncia e fluência.",
            style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.35),
          ),
          const SizedBox(height: 8),
          const Text(
            "Experiência de imersão total.",
            style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionStep() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mic_rounded, color: Colors.white70, size: 56),
            const SizedBox(height: 20),
            const Text(
              "Antes de começar",
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              "Seu microfone será ativado e sua voz será enviada a um serviço de "
              "inteligência artificial de terceiros (Google Gemini) para a prática "
              "de conversação em inglês. A conversa não é gravada nem transcrita "
              "no nosso servidor.",
              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
              textAlign: TextAlign.center,
            ),
            if (_callError != null) ...[
              const SizedBox(height: 16),
              Text(_callError!, style: const TextStyle(color: AppColors.redLight), textAlign: TextAlign.center),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _beginCall,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text("Permitir microfone e ligar"),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() => _state = MeganCallState.idle),
              child: const Text("Cancelar", style: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnecting() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.white70),
          SizedBox(height: 16),
          Text("Conectando com a Megan...", style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildRinging() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAvatar(pulsing: true, ringColor: AppColors.navyBlueLight),
            const SizedBox(height: 24),
            const Text("Megan", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.call_rounded, color: Colors.white54, size: 16),
                SizedBox(width: 6),
                Text("Chamando...", style: TextStyle(color: Colors.white54, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 40),
            _CallActionButton(
              icon: Icons.call_end_rounded,
              label: "Cancelar",
              backgroundColor: AppColors.red,
              iconColor: Colors.white,
              onPressed: _hangUp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInCall() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                _formattedCallDuration,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
              ),
            ],
          ),
        ),
        const Spacer(flex: 1),
        _buildAvatar(pulsing: true, ringColor: _meganSpeaking ? AppColors.navyBlueLight : AppColors.red),
        const SizedBox(height: 16),
        const Text("Megan", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        if (_topic != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              "Dia $_day • $_topic",
              style: const TextStyle(color: Colors.white54, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: 12),
        _buildCallStatusRow(),
        if (_userTranscript.isNotEmpty || _meganTranscript.isNotEmpty || _meganThinking)
          _buildTranscriptBox(),
        if (_callError != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
            child: Text(_callError!, style: const TextStyle(color: AppColors.redLight, fontSize: 12), textAlign: TextAlign.center),
          ),
        const Spacer(flex: 2),
        Container(
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _CallActionButton(
                icon: _muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                label: _muted ? "Mudo" : "Mic ativo",
                isActive: !_muted,
                onPressed: _toggleMute,
              ),
              _CallActionButton(
                icon: Icons.call_end_rounded,
                label: "Desligar",
                backgroundColor: AppColors.red,
                iconColor: Colors.white,
                onPressed: _hangUp,
              ),
              if (_canFinishChallenge)
                _CallActionButton(
                  icon: Icons.flag_circle_rounded,
                  label: "Finalizar Desafio",
                  backgroundColor: AppColors.navyBlueLight,
                  iconColor: Colors.white,
                  onPressed: _completeCallAndAdvanceMission,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCallStatusRow() {
    final IconData icon;
    final String label;
    final Color color;
    if (_meganSpeaking) {
      icon = Icons.graphic_eq_rounded;
      label = "Megan está falando...";
      color = AppColors.navyBlueLight;
    } else if (_meganThinking) {
      icon = Icons.more_horiz_rounded;
      label = "Megan está pensando...";
      color = Colors.amberAccent;
    } else {
      icon = Icons.hearing_rounded;
      label = "Megan está ouvindo você...";
      color = AppColors.redLight;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTranscriptBox() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(maxHeight: 160),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: SingleChildScrollView(
        controller: _transcriptScrollController,
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_userTranscript.isNotEmpty) ...[
              const Text(
                "VOCÊ DISSE",
                style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              const SizedBox(height: 2),
              Text(
                _userTranscript,
                style: const TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 10),
            ],
            if (_meganTranscript.isNotEmpty) ...[
              const Text(
                "MEGAN DIZ",
                style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              const SizedBox(height: 2),
              Text(
                _meganTranscript,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500, height: 1.3),
              ),
            ] else if (_meganThinking) ...[
              const Text(
                "MEGAN DIZ",
                style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              const SizedBox(height: 2),
              const Text(
                "...",
                style: TextStyle(color: Colors.white54, fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEnded() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_rounded, color: Colors.amberAccent, size: 56),
            const SizedBox(height: 20),
            const Text(
              "Bom trabalho hoje!",
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Sua conversa com a Megan foi encerrada.",
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            if (_advanceMissionError != null) ...[
              const SizedBox(height: 16),
              Text(
                _advanceMissionError!,
                style: const TextStyle(color: AppColors.redLight, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _advancingMission ? null : _advanceMission,
                child: _advancingMission
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
                      )
                    : const Text("Tentar avançar a missão de novo", style: TextStyle(color: Colors.white70)),
              ),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _backToIdle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyBlueLight,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text("Voltar"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isActive;
  final Color? backgroundColor;
  final Color? iconColor;

  const _CallActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isActive = false,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? (isActive ? AppColors.navyBlueLight : Colors.white.withValues(alpha: 0.15));
    final icColor = iconColor ?? Colors.white;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: bg,
          shape: const CircleBorder(),
          elevation: isActive ? 4 : 0,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Icon(icon, color: icColor, size: 24),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

/// Seção "Desafios bloqueados" da agenda, com o cadeado pulsando
/// continuamente até o aluno concluir todas as missões do módulo.
class _LockedChallengesFooter extends StatefulWidget {
  const _LockedChallengesFooter();

  @override
  State<_LockedChallengesFooter> createState() => _LockedChallengesFooterState();
}

class _LockedChallengesFooterState extends State<_LockedChallengesFooter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: 0.5 + _controller.value * 0.5,
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lock_rounded, color: Colors.white38, size: 16),
                SizedBox(width: 8),
                Text(
                  "Desafios bloqueados",
                  style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              "Cumpra todas as missões para desbloqueá-los e ganhe sua "
              "primeira medalha de conquista.",
              style: TextStyle(color: Colors.white38, fontSize: 11, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}
