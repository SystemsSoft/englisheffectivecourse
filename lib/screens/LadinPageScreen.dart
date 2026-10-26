import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_theme.dart';
import '../widgets/ui_kit.dart';
import 'LoginScreen.dart';

// Paleta da landing (navy da marca + verde de destaque do hero)
const Color _kNavyDeep = Color(0xFF0D1B6E);
const Color _kInk = Color(0xFF1A1A1A);
const Color _kBody = Color(0xFF555555);
const Color _kMint = Color(0xFF90EFB0);
const Color _kWhatsApp = Color(0xFF25D366);

Future<void> _openWhatsApp() async {
  final uri = Uri.parse(
    'https://wa.me/5524992611560?text=Ol%C3%A1%20Renata%2C%20gostaria%20de%20saber%20mais%20sobre%20as%20aulas%20de%20ingl%C3%AAs!',
  );
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

void _openLogin(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
  );
}

class LandingPageScreen extends StatelessWidget {
  const LandingPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Usa o MaterialApp principal (tema do app); só define o título da aba
    return Title(
      title: 'Effective English Course - Renata Cerqueira',
      color: AppColors.navyBlue,
      child: const LandingPage(),
    );
  }
}

// ── ANIMAÇÃO UTILITÁRIA: fade + slide quando o widget entra na tela ──────────

class _RevealOnScroll extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Offset slideFrom;

  const _RevealOnScroll({
    required this.child,
    this.delay = Duration.zero,
    this.slideFrom = const Offset(0, 40),
  });

  @override
  State<_RevealOnScroll> createState() => _RevealOnScrollState();
}

class _RevealOnScrollState extends State<_RevealOnScroll>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final Animation<double> _curve =
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
  ScrollPosition? _position;
  bool _shown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _position?.removeListener(_check);
    if (_shown) return;
    _position = Scrollable.maybeOf(context)?.position;
    _position?.addListener(_check);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  // Dispara a animação quando o topo do widget passa de ~90% da altura da tela
  void _check() {
    if (_shown || !mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) return;
    final top = box.localToGlobal(Offset.zero).dy;
    if (top < MediaQuery.sizeOf(context).height * 0.92) {
      _shown = true;
      _position?.removeListener(_check);
      Future.delayed(widget.delay, () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _position?.removeListener(_check);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: AnimatedBuilder(
        animation: _curve,
        builder: (_, child) => Transform.translate(
          offset: widget.slideFrom * (1 - _curve.value),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

// ── ANIMAÇÃO DE FLUTUAÇÃO CONTÍNUA (elementos decorativos) ──────────────────

class _Floating extends StatefulWidget {
  final Widget child;
  final double amplitude;
  final Duration period;

  const _Floating({
    required this.child,
    this.amplitude = 10,
    this.period = const Duration(seconds: 4),
  });

  @override
  State<_Floating> createState() => _FloatingState();
}

class _FloatingState extends State<_Floating> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: widget.period)..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, math.sin(_ctrl.value * 2 * math.pi) * widget.amplitude),
        child: child,
      ),
      child: widget.child,
    );
  }
}

// ── CARD COM HOVER (sobe e ganha sombra) ────────────────────────────────────

class _HoverCard extends StatefulWidget {
  final Widget Function(bool hovered) builder;
  final Color accent = AppColors.navyBlue;

  const _HoverCard({required this.builder});

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hovered ? -6 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _hovered ? widget.accent.withValues(alpha: 0.25) : kCardBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.accent.withValues(alpha: _hovered ? 0.16 : 0.05),
              blurRadius: _hovered ? 30 : 14,
              offset: Offset(0, _hovered ? 14 : 4),
            ),
          ],
        ),
        child: widget.builder(_hovered),
      ),
    );
  }
}

// ── LANDING PAGE ─────────────────────────────────────────────────────────────

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _scroll = ScrollController();
  final _aboutKey = GlobalKey();
  bool _scrolled = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final scrolled = _scroll.offset > 40;
      if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToAbout() {
    final ctx = _aboutKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < kTabletBreakpoint;

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: const _WhatsAppFab(),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scroll,
            child: Column(
              children: [
                _HeroSection(isMobile: isMobile, onScrollDown: _scrollToAbout),
                _AboutSection(key: _aboutKey, isMobile: isMobile),
                _BenefitsSection(width: screenWidth),
                _AppSection(isMobile: isMobile),
                _CtaSection(isMobile: isMobile),
                const _Footer(),
              ],
            ),
          ),
          // Barra superior: transparente no topo, sólida ao rolar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _TopBar(scrolled: _scrolled, isMobile: isMobile),
          ),
        ],
      ),
    );
  }
}

// ── TOP BAR ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final bool scrolled;
  final bool isMobile;

  const _TopBar({required this.scrolled, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: scrolled ? _kNavyDeep.withValues(alpha: 0.96) : Colors.transparent,
        boxShadow: scrolled
            ? const [BoxShadow(color: Color(0x331A2150), blurRadius: 20, offset: Offset(0, 6))]
            : const [],
      ),
      child: SafeArea(
        bottom: false,
        child: ContentConstrained(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 40, vertical: 10),
          child: Row(
            children: [
              // Logo aparece quando a barra fica sólida
              AnimatedOpacity(
                opacity: scrolled ? 1 : 0,
                duration: const Duration(milliseconds: 300),
                child: Image.asset('assets/logo.png', height: isMobile ? 40 : 48),
              ),
              const Spacer(),
              Tooltip(
                message: 'Acesso do Aluno',
                child: PressableScale(
                  onTap: () => _openLogin(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Acesso Aluno',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── WHATSAPP FAB com pulso ──────────────────────────────────────────────────

class _WhatsAppFab extends StatefulWidget {
  const _WhatsAppFab();

  @override
  State<_WhatsAppFab> createState() => _WhatsAppFabState();
}

class _WhatsAppFabState extends State<_WhatsAppFab> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Anel que se expande atrás do botão
        AnimatedBuilder(
          animation: _pulse,
          builder: (_, __) => IgnorePointer(
            child: Transform.scale(
              scale: 1 + 0.25 * _pulse.value,
              child: Container(
                width: 150,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  color: _kWhatsApp.withValues(alpha: 0.35 * (1 - _pulse.value)),
                ),
              ),
            ),
          ),
        ),
        const FloatingActionButton.extended(
          onPressed: _openWhatsApp,
          backgroundColor: _kWhatsApp,
          foregroundColor: Colors.white,
          icon: Icon(Icons.chat),
          label: Text('WhatsApp', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

// ── HERO ────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final bool isMobile;
  final VoidCallback onScrollDown;

  const _HeroSection({required this.isMobile, required this.onScrollDown});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: isMobile ? 0 : math.min(screenHeight, 820)),
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xD0273795),
              const Color(0xA6283A91),
              const Color(0xB54155B3),
              const Color(0xA35060B6).withValues(alpha: 0.8),
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(40),
            bottomRight: Radius.circular(40),
          ),
        ),
        child: Stack(
          children: [
            // Gradiente nas bordas para efeito de claridade
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2,
                    colors: [
                      const Color(0xFF2A4A9E).withValues(alpha: 0.3),
                      _kNavyDeep.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Imagem de fundo sem cortes — entra com fade e leve zoom
            Positioned.fill(
              child: Image.network(
                'https://repo-english-class.s3.us-east-2.amazonaws.com/lessons/perfil_image.png',
                fit: BoxFit.contain,
                alignment: isMobile ? Alignment.bottomCenter : Alignment.centerRight,
                frameBuilder: (_, child, frame, wasSyncLoaded) {
                  if (wasSyncLoaded) return child;
                  return AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOut,
                    child: AnimatedScale(
                      scale: frame == null ? 1.06 : 1,
                      duration: const Duration(milliseconds: 1400),
                      curve: Curves.easeOutCubic,
                      child: child,
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            // Overlay gradiente: cobre a esquerda fortemente, vai abrindo para a direita
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xF00D1B6E), // esquerda: quase sólido
                      Color(0xBB0D1B6E), // centro-esquerda
                      Color(0x660D1B6E), // centro
                      Color(0x220D1B6E), // direita: quase transparente
                    ],
                    stops: [0.0, 0.40, 0.65, 1.0],
                  ),
                ),
              ),
            ),
            // Overlay de cima para baixo (legibilidade do texto)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _kNavyDeep.withValues(alpha: isMobile ? 0.6 : 0.3),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5],
                  ),
                ),
              ),
            ),
            // Elementos decorativos flutuando
            const Positioned(
              top: 120,
              left: -40,
              child: _Floating(amplitude: 14, child: GlowCircle(size: 140, alpha: 0.06)),
            ),
            const Positioned(
              bottom: 80,
              right: 60,
              child: _Floating(
                amplitude: 8,
                period: Duration(seconds: 5),
                child: GlowCircle(size: 16, alpha: 0.9, color: AppColors.redLight),
              ),
            ),
            // Conteúdo
            SafeArea(
              bottom: false,
              child: ContentConstrained(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 24 : 56,
                  isMobile ? 84 : 140,
                  isMobile ? 24 : 56,
                  isMobile ? 56 : 110,
                ),
                child: isMobile ? _mobileContent() : _desktopContent(),
              ),
            ),
            // Indicador "role para baixo" (desktop)
            if (!isMobile)
              Positioned(
                left: 0,
                right: 0,
                bottom: 24,
                child: Center(
                  child: PressableScale(
                    onTap: onScrollDown,
                    child: _Floating(
                      amplitude: 6,
                      period: const Duration(milliseconds: 1800),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                        ),
                        child: const Icon(Icons.keyboard_arrow_down_rounded,
                            color: Colors.white, size: 26),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _mobileContent() => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: _contentWidgets(center: true),
      );

  Widget _desktopContent() => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: _contentWidgets(center: false),
            ),
          ),
          const Spacer(flex: 4),
        ],
      );

  List<Widget> _contentWidgets({required bool center}) => [
        // Logo
        FadeSlideIn(
          child: Image.asset('assets/logo.png', height: center ? 120 : 150),
        ),
        const SizedBox(height: 8),
        // Badge
        FadeSlideIn(
          delay: const Duration(milliseconds: 100),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _kWhatsApp.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kWhatsApp.withValues(alpha: 0.5)),
            ),
            child: const Text(
              '🌎  O inglês é o idioma do mundo',
              style: TextStyle(
                color: _kMint,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        // Título principal
        FadeSlideIn(
          delay: const Duration(milliseconds: 260),
          child: Text(
            'Inglês não é\nmais opcional.',
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: TextStyle(
              color: Colors.white,
              fontSize: center ? 38 : 60,
              fontWeight: FontWeight.w900,
              height: 1.08,
              letterSpacing: -1.5,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        // Subtítulo
        FadeSlideIn(
          delay: const Duration(milliseconds: 420),
          child: Text(
            'Em um mundo conectado, quem fala inglês acessa melhores empregos, viagens e oportunidades que os outros simplesmente não enxergam.',
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: center ? 15 : 18,
              height: 1.65,
              shadows: [
                Shadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Destaque Renata
        FadeSlideIn(
          delay: const Duration(milliseconds: 540),
          child: Text(
            'Com Renata Cerqueira, você aprende de verdade — de forma simples, prática e eficiente.',
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: TextStyle(
              color: _kMint,
              fontSize: center ? 14 : 17,
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 32),
        // Chamadas para ação
        FadeSlideIn(
          delay: const Duration(milliseconds: 640),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: center ? WrapAlignment.center : WrapAlignment.start,
            children: const [
              _HeroButton(
                label: 'Quero aprender inglês',
                icon: Icons.arrow_forward_rounded,
                primary: true,
                onTap: _openWhatsApp,
              ),
              _HeroLoginButton(),
            ],
          ),
        ),
        const SizedBox(height: 32),
        // Stats chips
        FadeSlideIn(
          delay: const Duration(milliseconds: 740),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: center ? WrapAlignment.center : WrapAlignment.start,
            children: [
              _statChip('20+', 'anos de experiência'),
              _statChip('100%', 'online'),
              _statChip('👥', 'individual ou em grupo'),
            ],
          ),
        ),
      ];

  Widget _statChip(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12)),
        ],
      ),
    );
  }
}

class _HeroLoginButton extends StatelessWidget {
  const _HeroLoginButton();

  @override
  Widget build(BuildContext context) {
    return _HeroButton(
      label: 'Área do Aluno',
      icon: Icons.person_rounded,
      primary: false,
      onTap: () => _openLogin(context),
    );
  }
}

class _HeroButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool primary;
  final VoidCallback onTap;

  const _HeroButton({
    required this.label,
    required this.icon,
    required this.primary,
    required this.onTap,
  });

  @override
  State<_HeroButton> createState() => _HeroButtonState();
}

class _HeroButtonState extends State<_HeroButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final primary = widget.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: PressableScale(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          decoration: BoxDecoration(
            gradient: primary
                ? const LinearGradient(colors: [AppColors.red, AppColors.redLight])
                : null,
            color: primary ? null : Colors.white.withValues(alpha: _hovered ? 0.22 : 0.12),
            borderRadius: BorderRadius.circular(30),
            border: primary ? null : Border.all(color: Colors.white.withValues(alpha: 0.4)),
            boxShadow: primary
                ? [
                    BoxShadow(
                      color: AppColors.red.withValues(alpha: _hovered ? 0.55 : 0.35),
                      blurRadius: _hovered ? 26 : 16,
                      offset: Offset(0, _hovered ? 10 : 6),
                    ),
                  ]
                : const [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!primary) ...[
                Icon(widget.icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              if (primary) ...[
                const SizedBox(width: 8),
                AnimatedSlide(
                  offset: _hovered ? const Offset(0.3, 0) : Offset.zero,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(widget.icon, color: Colors.white, size: 20),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── CABEÇALHO DE SEÇÃO ──────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? subtitle;
  final bool center;

  const _SectionHeader({
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.center = true,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < kTabletBreakpoint;

    return _RevealOnScroll(
      child: Column(
        crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              eyebrow.toUpperCase(),
              style: const TextStyle(
                color: AppColors.red,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: TextStyle(
              fontSize: isMobile ? 26 : 36,
              fontWeight: FontWeight.w800,
              color: _kInk,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 10),
            Text(
              subtitle!,
              textAlign: center ? TextAlign.center : TextAlign.start,
              style: const TextStyle(fontSize: 16, color: Color(0xFF888888), height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}

// ── ABOUT ───────────────────────────────────────────────────────────────────

class _AboutSection extends StatelessWidget {
  final bool isMobile;
  const _AboutSection({super.key, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: ContentConstrained(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 56, vertical: isMobile ? 64 : 96),
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [_aboutText(), const SizedBox(height: 36), const _CredentialsPanel()],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(flex: 6, child: _aboutText()),
                  const SizedBox(width: 56),
                  const Expanded(flex: 5, child: _CredentialsPanel()),
                ],
              ),
      ),
    );
  }

  Widget _aboutText() {
    const body = TextStyle(fontSize: 16, color: _kBody, height: 1.75);
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          eyebrow: 'Sobre a Professora',
          title: 'Renata Cerqueira',
          center: false,
        ),
        SizedBox(height: 20),
        _RevealOnScroll(
          delay: Duration(milliseconds: 100),
          child: Text(
            'Professora de inglês há 20 anos — desde 2006 — com experiência em todas as idades e níveis, do básico ao avançado. Alguns dos seus alunos se tornaram professores de inglês!',
            style: body,
          ),
        ),
        SizedBox(height: 12),
        _RevealOnScroll(
          delay: Duration(milliseconds: 180),
          child: Text(
            'Fez intercâmbio na Nova Zelândia e em Londres, vivendo com famílias nativas e vivenciando o inglês no dia a dia: transporte público, compras, restaurantes, hotéis, viagens para outros países e interação com pessoas de diversas culturas.',
            style: body,
          ),
        ),
        SizedBox(height: 12),
        _RevealOnScroll(
          delay: Duration(milliseconds: 260),
          child: Text(
            'Especialista em pronúncia avançada, metodologia de ensino e linguística aplicada.',
            style: body,
          ),
        ),
      ],
    );
  }
}

// Painel navy com os destaques da carreira
class _CredentialsPanel extends StatelessWidget {
  const _CredentialsPanel();

  static const _items = [
    ('2006', 'Ensinando inglês desde'),
    ('20+', 'Anos de experiência'),
    ('🇳🇿 🇬🇧', 'Intercâmbio na Nova Zelândia e em Londres'),
    ('A–Z', 'Do básico ao avançado, todas as idades'),
  ];

  @override
  Widget build(BuildContext context) {
    return _RevealOnScroll(
      delay: const Duration(milliseconds: 150),
      slideFrom: const Offset(40, 0),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: AppPageHeader.gradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(color: Color(0x441A2150), blurRadius: 30, offset: Offset(0, 14)),
          ],
        ),
        child: Stack(
          children: [
            const Positioned(top: -50, right: -40, child: GlowCircle(size: 170, alpha: 0.07)),
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < _items.length; i++) ...[
                    if (i > 0)
                      Divider(height: 28, color: Colors.white.withValues(alpha: 0.12)),
                    Row(
                      children: [
                        SizedBox(
                          width: 92,
                          child: Text(
                            _items[i].$1,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _items[i].$2,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── BENEFITS ─────────────────────────────────────────────────────────────────

class _BenefitsSection extends StatelessWidget {
  final double width;
  const _BenefitsSection({required this.width});

  static const _benefits = [
    {'icon': '🌍', 'title': '20 Anos de Experiência', 'desc': 'Professora desde 2006, com alunos de todas as idades e níveis — do básico ao avançado.'},
    {'icon': '✈️', 'title': 'Vivência Internacional', 'desc': 'Intercâmbio na Nova Zelândia e em Londres, morando com famílias nativas e vivenciando o inglês real.'},
    {'icon': '🗣️', 'title': 'Foco em Conversação', 'desc': 'Todas as habilidades do idioma trabalhadas com ênfase na fala e na comunicação do dia a dia.'},
    {'icon': '🎧', 'title': 'Pronúncia Avançada', 'desc': 'Especialista em pronúncia: você vai soar natural e ser entendido em qualquer situação.'},
    {'icon': '💻', 'title': 'Aulas 100% Online', 'desc': 'Estude de onde estiver, com material interativo e audiovisual de alta qualidade.'},
    {'icon': '📚', 'title': 'Metodologia Comprovada', 'desc': 'Formação em metodologia de ensino e linguística aplicada para um aprendizado mais rápido e eficaz.'},
    {'icon': '👥', 'title': 'Aulas em Grupo', 'desc': 'Aprenda junto com outras pessoas em um ambiente dinâmico: conversação real, troca de experiências, interação cultural e prática do dia a dia — de forma simples, prática e eficiente.'},
    {'icon': '🎯', 'title': 'Aulas Individuais', 'desc': 'Atenção 100% focada em você: ritmo personalizado, correção imediata, conteúdo adaptado às suas necessidades e evolução muito mais rápida.'},
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = width < kTabletBreakpoint;
    final columns = width >= kDesktopBreakpoint ? 4 : (isMobile ? 1 : 2);

    return Container(
      color: const Color(0xFFF0F4FF),
      child: ContentConstrained(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 56, vertical: isMobile ? 64 : 96),
        child: Column(
          children: [
            const _SectionHeader(
              eyebrow: 'Diferenciais',
              title: 'Por que aprender com a Renata Cerqueira?',
            ),
            SizedBox(height: isMobile ? 36 : 52),
            ResponsiveGrid(
              columns: columns,
              children: List.generate(_benefits.length, (i) {
                final b = _benefits[i];
                return _RevealOnScroll(
                  // Escalona por coluna para a linha entrar em cascata
                  delay: Duration(milliseconds: (i % columns) * 110),
                  child: _BenefitCard(icon: b['icon']!, title: b['title']!, desc: b['desc']!),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  final String icon, title, desc;
  const _BenefitCard({required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return _HoverCard(
      builder: (hovered) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: hovered ? AppColors.navyBlue : const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: AnimatedScale(
                  scale: hovered ? 1.15 : 1,
                  duration: const Duration(milliseconds: 250),
                  child: Text(icon, style: const TextStyle(fontSize: 30)),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(title,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.navyBlue)),
            const SizedBox(height: 8),
            Text(desc,
                style: const TextStyle(fontSize: 14, color: Color(0xFF666666), height: 1.55)),
            const SizedBox(height: 16),
            // Barra de destaque que cresce no hover
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              width: hovered ? 56 : 24,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.red,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── APP SECTION ──────────────────────────────────────────────────────────────

class _AppSection extends StatelessWidget {
  final bool isMobile;
  const _AppSection({required this.isMobile});

  static const _features = [
    {'icon': '🎬', 'title': 'Aulas Gravadas', 'desc': 'Assista às aulas quando e onde quiser, no seu ritmo.'},
    {'icon': '💬', 'title': 'Tire suas Dúvidas', 'desc': 'Canal exclusivo para enviar perguntas e receber respostas da Renata.'},
    {'icon': '🃏', 'title': 'Flashcards', 'desc': 'Sistema de flashcards inteligente para fixar vocabulário e acelerar o aprendizado.'},
    {'icon': '📖', 'title': 'Dicionário', 'desc': 'Dicionário integrado para consultas rápidas durante os estudos.'},
    {'icon': '🎧', 'title': 'Rádios Internacionais', 'desc': 'Acesse rádios dos EUA, Reino Unido, Canadá, Austrália e muito mais para treinar o listening.'},
    {'icon': '🛡️', 'title': 'Suporte Exclusivo', 'desc': 'Suporte dedicado para alunos com atendimento prioritário.'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: ContentConstrained(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 56, vertical: isMobile ? 64 : 96),
        child: Column(
          children: [
            const _SectionHeader(
              eyebrow: 'Aplicativo exclusivo',
              title: 'Estude em qualquer lugar,\nna palma da sua mão',
              subtitle: 'Disponível para Web, Android e iOS',
            ),
            SizedBox(height: isMobile ? 40 : 56),
            isMobile
                ? Column(children: [
                    _appBanner(),
                    const SizedBox(height: 40),
                    _featuresList(),
                  ])
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: _featuresList()),
                      const SizedBox(width: 56),
                      Expanded(child: _appBanner()),
                    ],
                  ),
            const SizedBox(height: 48),
            _RevealOnScroll(
              child: Wrap(
                spacing: 16,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _platformBadge(Icons.language, 'Web'),
                  _platformBadge(Icons.phone_android, 'Android'),
                  _platformBadge(Icons.phone_iphone, 'iOS'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _appBanner() {
    return _RevealOnScroll(
      slideFrom: const Offset(40, 0),
      child: _Floating(
        amplitude: 8,
        period: const Duration(seconds: 6),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(color: Color(0x331A2150), blurRadius: 40, offset: Offset(0, 20)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.network(
              'https://repo-english-class.s3.us-east-2.amazonaws.com/lessons/banner3.jpg',
              fit: BoxFit.contain,
              width: double.infinity,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _featuresList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(_features.length, (i) {
        final f = _features[i];
        return _RevealOnScroll(
          delay: Duration(milliseconds: i * 90),
          slideFrom: const Offset(-30, 0),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _HoverCard(
              builder: (hovered) => Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: hovered ? AppColors.navyBlue : const Color(0xFFF0F4FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(child: Text(f['icon']!, style: const TextStyle(fontSize: 24))),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(f['title']!,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.navyBlue)),
                          const SizedBox(height: 4),
                          Text(f['desc']!,
                              style: const TextStyle(
                                  fontSize: 14, color: Color(0xFF666666), height: 1.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _platformBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.navyBlue, AppColors.navyBlueLight]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x261A2150), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}

// ── CHAMADA FINAL ───────────────────────────────────────────────────────────

class _CtaSection extends StatelessWidget {
  final bool isMobile;
  const _CtaSection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: ContentConstrained(
        padding: EdgeInsets.fromLTRB(isMobile ? 20 : 56, 0, isMobile ? 20 : 56, isMobile ? 64 : 96),
        child: _RevealOnScroll(
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: AppPageHeader.gradient,
              borderRadius: BorderRadius.circular(32),
              boxShadow: const [
                BoxShadow(color: Color(0x441A2150), blurRadius: 30, offset: Offset(0, 14)),
              ],
            ),
            child: Stack(
              children: [
                const Positioned(
                  top: -60,
                  right: -40,
                  child: _Floating(child: GlowCircle(size: 200, alpha: 0.07)),
                ),
                const Positioned(
                  bottom: -50,
                  left: -30,
                  child: GlowCircle(size: 150, alpha: 0.05),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 24 : 56,
                    vertical: isMobile ? 40 : 56,
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Pronto para falar inglês de verdade?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 24 : 34,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Fale com a Renata e descubra a turma ideal para você.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          _HeroButton(
                            label: 'Falar no WhatsApp',
                            icon: Icons.arrow_forward_rounded,
                            primary: true,
                            onTap: _openWhatsApp,
                          ),
                          _HeroLoginButton(),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── FOOTER ───────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kNavyDeep,
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 96),
      child: Column(
        children: [
          Image.asset('assets/logo.png', height: 80),
          const SizedBox(height: 12),
          const Text(
            '© 2026 English Effective Course · Renata Cerqueira · Todos os direitos reservados.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
