import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/aluno_ia_model.dart';
import '../models/megan_call_state.dart';
import '../services/aluno_ia_service.dart';
import '../services/megan_call_service.dart';
import '../viewmodels/user_viewmodel.dart';
import '../app_theme.dart';

class TalkToMegamScreen extends StatefulWidget {
  const TalkToMegamScreen({super.key});

  @override
  State<TalkToMegamScreen> createState() => _TalkToMegamScreenState();
}

class _TalkToMegamScreenState extends State<TalkToMegamScreen> {
  final AlunoIaService _alunoIaService = AlunoIaService();
  MeganCallService? _callService;

  static const String _megamAvatarUrl =
      'https://repo-english-class.s3.us-east-2.amazonaws.com/lessons/perfil_image.png';

  MeganCallState _state = MeganCallState.idle;
  bool _loadingAluno = true;
  String? _loadError;
  AlunoIaDto? _aluno;

  int? _day;
  String? _topic;
  bool _meganSpeaking = false;
  bool _muted = false;
  String? _callError;

  Timer? _callTimer;
  int _callDurationSeconds = 0;

  String get _userId => context.read<UserViewModel>().user!.email;

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

  Future<void> _loadAluno() async {
    final userId = _userId;
    final userName = context.read<UserViewModel>().user!.name;
    setState(() {
      _loadingAluno = true;
      _loadError = null;
    });
    try {
      var aluno = await _alunoIaService.getAluno(userId);
      aluno ??= await _alunoIaService.criarAluno(AlunoIaDto(
        userId: userId,
        nome: userName,
        email: userId,
        stripeCustomerId: '',
        planoAtivo: '',
        moduloAtual: 'module1',
        missaoAtual: '1',
        ultimaSessao: '',
      ));
      if (!mounted) return;
      setState(() {
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
    _callDurationSeconds = 0;
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _callDurationSeconds++);
    });
  }

  String get _formattedCallDuration {
    final minutes = (_callDurationSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_callDurationSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  void _goToPermissionStep() {
    setState(() {
      _state = MeganCallState.requestingPermission;
      _callError = null;
    });
  }

  Future<void> _beginCall() async {
    setState(() => _state = MeganCallState.connecting);

    final service = MeganCallService(
      userId: _userId,
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
    });
  }

  Future<void> _hangUp() async {
    await _callService?.hangUp();
    _finishCall();
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
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 3),
            boxShadow: [
              BoxShadow(color: AppColors.navyBlue.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 2),
            ],
          ),
          child: ClipOval(
            child: Image.network(
              _megamAvatarUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded, size: 70, color: Colors.white),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _meganSpeaking ? Icons.graphic_eq_rounded : Icons.hearing_rounded,
              color: _meganSpeaking ? AppColors.navyBlueLight : AppColors.redLight,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              _meganSpeaking ? "Megan está falando..." : "Megan está ouvindo você...",
              style: TextStyle(
                color: _meganSpeaking ? AppColors.navyBlueLight : AppColors.redLight,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
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
