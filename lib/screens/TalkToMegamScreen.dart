import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/aluno_ia_model.dart';
import '../models/megan_call_state.dart';
import '../services/aluno_ia_service.dart';
import '../services/megan_call_service.dart';
import '../services/megan_user_id_store.dart';
import '../services/gemini_translation_service.dart';
import '../utils/ulid.dart';
import '../viewmodels/user_viewmodel.dart';
import '../app_theme.dart';

class TalkToMegamScreen extends StatefulWidget {
  const TalkToMegamScreen({super.key});

  @override
  State<TalkToMegamScreen> createState() => _TalkToMegamScreenState();
}

class _TalkToMegamScreenState extends State<TalkToMegamScreen> {
  final AlunoIaService _alunoIaService = AlunoIaService();
  final MeganUserIdStore _userIdStore = MeganUserIdStore();
  final GeminiTranslationService _translationService = GeminiTranslationService();
  MeganCallService? _callService;

  static const String _megamAvatarAsset = 'assets/logo-megan.jpeg';

  MeganCallState _state = MeganCallState.idle;
  bool _loadingAluno = true;
  String? _loadError;
  AlunoIaDto? _aluno;

  /// userId (ULID) do aluno na Megan — gerado e persistido localmente na
  /// primeira vez, reutilizado nas próximas (ver [MeganUserIdStore]).
  String? _meganUserId;

  int? _day;
  String? _topic;
  bool _meganSpeaking = false;
  bool _meganThinking = false;
  String _userTranscript = '';
  String _meganTranscript = '';
  String? _meganTranslation;
  bool _translating = false;
  String? _translateError;
  bool _muted = false;
  String? _callError;

  static const int _callDurationLimitSeconds = 15 * 60;

  Timer? _callTimer;
  int _callSecondsRemaining = _callDurationLimitSeconds;

  @override
  void initState() {
    super.initState();
    _loadAluno();
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _callService?.hangUp();
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
      var userId = await _userIdStore.getUserId(user.email);

      AlunoIaDto? aluno;
      if (userId != null) {
        aluno = await _alunoIaService.getAluno(userId);
      }

      if (aluno == null) {
        // Primeira vez do aluno (sem userId salvo) ou o registro sumiu do
        // backend apesar de já termos um userId local: (re)criar.
        userId ??= Ulid.generate();
        aluno = await _alunoIaService.criarAluno(AlunoIaDto(
          userId: userId,
          nome: user.name,
          email: user.email,
          stripeCustomerId: '',
          planoAtivo: '',
          moduloAtual: 'module1',
          missaoAtual: '1',
          ultimaSessao: '',
        ));
        await _userIdStore.saveUserId(user.email, userId);
      }

      if (!mounted) return;
      setState(() {
        _meganUserId = userId;
        _aluno = aluno;
        _loadingAluno = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Não foi possível carregar seus dados: $e';
        _loadingAluno = false;
      });
    }
  }

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

  Future<void> _beginCall() async {
    setState(() {
      _state = MeganCallState.connecting;
      _userTranscript = '';
      _meganTranscript = '';
      _meganTranslation = null;
      _translating = false;
      _translateError = null;
      _meganThinking = false;
    });

    final service = MeganCallService(
      userId: _meganUserId!,
      onSessionReady: (day, topic) {
        if (!mounted) return;
        setState(() {
          _day = day;
          _topic = topic;
          _state = MeganCallState.inCall;
        });
        _startCallTimer();
      },
      onServerError: (message) {
        if (!mounted) return;
        setState(() => _callError = message);
      },
      onMeganSpeakingChanged: (speaking) {
        if (!mounted) return;
        setState(() => _meganSpeaking = speaking);
      },
      onMeganThinkingChanged: (thinking) {
        if (!mounted) return;
        setState(() => _meganThinking = thinking);
      },
      onUserTranscriptChanged: (text) {
        if (!mounted) return;
        setState(() => _userTranscript = text);
      },
      onMeganTranscriptChanged: (text) {
        if (!mounted) return;
        setState(() {
          _meganTranscript = text;
          _meganTranslation = null;
          _translateError = null;
        });
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
      setState(() {
        _callError = 'Não foi possível acessar o microfone: $e';
        _state = MeganCallState.idle;
      });
    }
  }

  void _finishCall() {
    _callTimer?.cancel();
    setState(() {
      _state = MeganCallState.ended;
      _meganSpeaking = false;
      _meganThinking = false;
    });
  }

  Future<void> _onTranslatePressed() async {
    final textToTranslate = _meganTranscript;
    if (textToTranslate.isEmpty || _translating) return;
    setState(() {
      _translating = true;
      _translateError = null;
    });
    try {
      final translation = await _translationService.translate(textToTranslate);
      if (!mounted) return;
      setState(() {
        _translating = false;
        // Só aplica se o texto da Megan não tiver mudado nesse meio tempo
        // (evita mostrar tradução de uma rodada já superada).
        if (_meganTranscript == textToTranslate) _meganTranslation = translation;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _translating = false;
        _translateError = '$e';
      });
    }
  }

  Future<void> _hangUp() async {
    await _callService?.hangUp();
    _finishCall();
  }

  /// Chamado só quando os 15 minutos são completados de fato — avança a
  /// missão do aluno antes de encerrar a chamada.
  Future<void> _completeCallAndAdvanceMission() async {
    final userId = _meganUserId;
    if (userId != null) {
      try {
        await _alunoIaService.avancarMissao(userId);
      } catch (_) {
        // Não bloqueia o encerramento da chamada por causa disso — o aluno
        // já completou os 15 minutos mesmo que o avanço da missão falhe.
      }
    }
    await _hangUp();
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
      case MeganCallState.inCall:
        return _buildInCall();
      case MeganCallState.ended:
        return _buildEnded();
    }
  }

  Widget _buildAvatar({bool pulsing = false, Color ringColor = AppColors.navyBlueLight}) {
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAvatar(),
            const SizedBox(height: 24),
            const Text("Megan", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              "Dia $missao • Missão Fluência",
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _goToPermissionStep,
                icon: const Icon(Icons.call_rounded),
                label: const Text("Chamar a Megan"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),
          ],
        ),
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
              const SizedBox(height: 8),
              if (_meganTranslation != null)
                Text(
                  _meganTranslation!,
                  style: const TextStyle(color: Colors.white54, fontSize: 13, fontStyle: FontStyle.italic),
                )
              else
                InkWell(
                  onTap: _translating ? null : _onTranslatePressed,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_translating)
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
                          )
                        else
                          const Icon(Icons.translate_rounded, color: AppColors.redLight, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          _translating ? "Traduzindo..." : "Traduzir",
                          style: const TextStyle(
                            color: AppColors.redLight,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_translateError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    "Não foi possível traduzir: $_translateError",
                    style: const TextStyle(color: AppColors.redLight, fontSize: 11),
                  ),
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
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
