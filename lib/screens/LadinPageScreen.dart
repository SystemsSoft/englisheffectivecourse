import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'LoginScreen.dart';



class LandingPageScreen extends StatelessWidget {
  const LandingPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'English Effective Course - Renata Cerqueira',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A237E)),
        useMaterial3: true,
        fontFamily: 'Arial',
      ),
      home: const LandingPage(),
    );
  }
}

// ── ANIMAÇÃO UTILITÁRIA: fade + slide ao entrar na viewport ──────────────────

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
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: widget.slideFrom,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: AnimatedBuilder(
        animation: _slide,
        builder: (_, child) => Transform.translate(
          offset: _slide.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

// ── ANIMAÇÃO DE ENTRADA DO HERO ──────────────────────────────────────────────

class _HeroEntrance extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const _HeroEntrance({required this.child, this.delay = Duration.zero});

  @override
  State<_HeroEntrance> createState() => _HeroEntranceState();
}

class _HeroEntranceState extends State<_HeroEntrance>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 30), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: AnimatedBuilder(
        animation: _slide,
        builder: (_, child) =>
            Transform.translate(offset: _slide.value, child: child),
        child: widget.child,
      ),
    );
  }
}

// ── LANDING PAGE ─────────────────────────────────────────────────────────────

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Tooltip(
              message: 'Acesso do Aluno',
              child: IconButton(
                icon: const Icon(Icons.login_rounded, color: Color(0xFF0D1B6E), size: 28),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final uri = Uri.parse(
            'https://wa.me/5524992611560?text=Ol%C3%A1%20Renata%2C%20gostaria%20de%20saber%20mais%20sobre%20as%20aulas%20de%20ingl%C3%AAs!',
          );
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        backgroundColor: const Color(0xFF25D366),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.chat),
        label: const Text('WhatsApp',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _HeroSection(isMobile: isMobile),
            _RevealOnScroll(
                delay: const Duration(milliseconds: 100),
                slideFrom: const Offset(0, 50),
                child: _AboutSection(isMobile: isMobile)),
            _BenefitsSection(isMobile: isMobile),
            _RevealOnScroll(
                delay: const Duration(milliseconds: 100),
                slideFrom: const Offset(0, 50),
                child: _AppSection(isMobile: isMobile)),
            _RevealOnScroll(
                delay: const Duration(milliseconds: 200),
                slideFrom: const Offset(0, 30),
                child: _Footer()),
          ],
        ),
      ),
    );
  }
}

// ── HERO ────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final bool isMobile;
  const _HeroSection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0D1B6E), // fundo azul para áreas sem imagem
      child: Stack(
        children: [
          // Imagem de fundo sem cortes — contida dentro do espaço
          Positioned.fill(
            child: Image.network(
              'https://repo-english-class.s3.us-east-2.amazonaws.com/lessons/banner-transparent.png',
              fit: BoxFit.contain,
              alignment: isMobile ? Alignment.bottomCenter : Alignment.centerRight,
              loadingBuilder: (_, child, progress) =>
              progress == null ? child : const SizedBox.shrink(),
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
          // Overlay mobile: gradiente de baixo para cima (imagem fica embaixo)
          if (true)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF0D1B6E).withValues(alpha: isMobile ? 0.6 : 0.3),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5],
                  ),
                ),
              ),
            ),
          // Conteúdo
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 28 : 96,
              vertical: isMobile ? 56 : 90,
            ),
            child: isMobile ? _mobileContent() : _desktopContent(),
          ),
        ],
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
    // Badge
    _HeroEntrance(
      delay: const Duration(milliseconds: 100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF25D366).withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.5)),
        ),
        child: const Text(
          '🌎  O inglês é o idioma do mundo',
          style: TextStyle(
            color: Color(0xFF90EFB0),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    ),
    const SizedBox(height: 22),
    // Título principal
    _HeroEntrance(
      delay: const Duration(milliseconds: 260),
      child: Text(
        'Inglês não é\nmais opcional.',
        textAlign: center ? TextAlign.center : TextAlign.start,
        style: TextStyle(
          color: Colors.white,
          fontSize: center ? 38 : 58,
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
    _HeroEntrance(
      delay: const Duration(milliseconds: 420),
      child: Text(
        'Em um mundo conectado, quem fala inglês acessa\nmelhores empregos, viagens e oportunidades\nque os outros simplesmente não enxergam.',
        textAlign: center ? TextAlign.center : TextAlign.start,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.85),
          fontSize: center ? 15 : 18,
          height: 1.65,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
            ),
          ],
        ),
      ),
    ),
    const SizedBox(height: 14),
    // Destaque Renata
    _HeroEntrance(
      delay: const Duration(milliseconds: 540),
      child: Text(
        'Com Renata Cerqueira, você aprende de verdade —\nde forma simples, prática e eficiente.',
        textAlign: center ? TextAlign.center : TextAlign.start,
        style: TextStyle(
          color: const Color(0xFF90EFB0),
          fontSize: center ? 14 : 17,
          fontWeight: FontWeight.w700,
          height: 1.5,
        ),
      ),
    ),
    const SizedBox(height: 36),
    // Stats chips
    _HeroEntrance(
      delay: const Duration(milliseconds: 630),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75), fontSize: 12)),
        ],
      ),
    );
  }
}

// ── ABOUT ───────────────────────────────────────────────────────────────────

class _AboutSection extends StatelessWidget {
  final bool isMobile;
  const _AboutSection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 80,
        vertical: 60,
      ),
      child: isMobile
          ? Column(children: [_aboutText(), const SizedBox(height: 32), _aboutImage()])
          : Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: _aboutText()),
          const SizedBox(width: 48),
          Expanded(child: _aboutImage()),
        ],
      ),
    );
  }

  Widget _aboutText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Sobre a Professora',
            style: TextStyle(
                color: Color(0xFF1A237E),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 2)),
        const SizedBox(height: 8),
        const Text('Renata Cerqueira',
            style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A))),
        const SizedBox(height: 16),
        const Text(
          'Professora de inglês há 20 anos — desde 2006 — com experiência em todas as idades e níveis, do básico ao avançado. Alguns dos seus alunos se tornaram professores de inglês!',
          style: TextStyle(fontSize: 16, color: Color(0xFF555555), height: 1.7),
        ),
        const SizedBox(height: 12),
        const Text(
          'Fez intercâmbio na Nova Zelândia e em Londres, vivendo com famílias nativas e vivenciando o inglês no dia a dia: transporte público, compras, restaurantes, hotéis, viagens para outros países e interação com pessoas de diversas culturas.',
          style: TextStyle(fontSize: 16, color: Color(0xFF555555), height: 1.7),
        ),
        const SizedBox(height: 12),
        const Text(
          'Especialista em pronúncia avançada, metodologia de ensino e linguística aplicada.',
          style: TextStyle(fontSize: 16, color: Color(0xFF555555), height: 1.7),
        ),
      ],
    );
  }

  Widget _aboutImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
          'https://repo-english-class.s3.us-east-2.amazonaws.com/lessons/banner.jpg',
          fit: BoxFit.contain, width: double.infinity),
    );
  }
}

// ── BENEFITS ─────────────────────────────────────────────────────────────────

class _BenefitsSection extends StatelessWidget {
  final bool isMobile;
  const _BenefitsSection({required this.isMobile});

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
    return Container(
      color: const Color(0xFFF0F4FF),
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 24 : 80, vertical: 60),
      child: Column(
        children: [
          _RevealOnScroll(
            child: const Text(
              'Por que aprender com a Renata Cerqueira?',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A)),
            ),
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: List.generate(_benefits.length, (i) {
              final b = _benefits[i];
              return _RevealOnScroll(
                delay: Duration(milliseconds: i * 100),
                slideFrom: const Offset(0, 40),
                child: _BenefitCard(
                  icon: b['icon']!,
                  title: b['title']!,
                  desc: b['desc']!,
                  isMobile: isMobile,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  final String icon, title, desc;
  final bool isMobile;
  const _BenefitCard(
      {required this.icon,
        required this.title,
        required this.desc,
        required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isMobile ? double.infinity : 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 36)),
          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E))),
          const SizedBox(height: 8),
          Text(desc,
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF666666), height: 1.5)),
        ],
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
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 24 : 80, vertical: 60),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1A237E).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('APLICATIVO EXCLUSIVO',
                style: TextStyle(
                    color: Color(0xFF1A237E),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2)),
          ),
          const SizedBox(height: 12),
          const Text(
            'Estude em qualquer lugar,\nna palma da sua mão',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
                height: 1.3),
          ),
          const SizedBox(height: 8),
          const Text('Disponível para Web, Android e iOS',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Color(0xFF888888))),
          const SizedBox(height: 48),
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
              const SizedBox(width: 48),
              Expanded(child: _appBanner()),
            ],
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _platformBadge(Icons.language, 'Web'),
              _platformBadge(Icons.phone_android, 'Android'),
              _platformBadge(Icons.phone_iphone, 'iOS'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _appBanner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
          'https://repo-english-class.s3.us-east-2.amazonaws.com/lessons/banner3.jpg',
          fit: BoxFit.contain, width: double.infinity),
    );
  }

  Widget _featuresList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(_features.length, (i) {
        final f = _features[i];
        return _RevealOnScroll(
          delay: Duration(milliseconds: i * 90),
          slideFrom: const Offset(-30, 0),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(12)),
                  child: Center(
                      child: Text(f['icon']!,
                          style: const TextStyle(fontSize: 24))),
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
                              color: Color(0xFF1A237E))),
                      const SizedBox(height: 4),
                      Text(f['desc']!,
                          style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF666666),
                              height: 1.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _platformBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
          color: const Color(0xFF1A237E),
          borderRadius: BorderRadius.circular(24)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ],
      ),
    );
  }
}

// ── FOOTER ───────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF111111),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: const Center(
        child: Text(
          '© 2026 English Effective Course · Renata Cerqueira · Todos os direitos reservados.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
      ),
    );
  }
}
