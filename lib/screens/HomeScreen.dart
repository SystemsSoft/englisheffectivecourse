import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/upload_model.dart';
import '../models/user_model.dart';
import '../viewmodels/user_viewmodel.dart';
import '../viewmodels/upload_viewmodel.dart';
import 'LoginScreen.dart';
import 'VideoPlayerScreen.dart';
import 'ListeningScreen.dart';
import 'ProfileScreen.dart';
import '../WordOfTheDayScreen.dart';
import 'FlashcardsScreen.dart';
import '../app_theme.dart';
import '../widgets/ui_kit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    final user = context.read<UserViewModel>().user;
    if (user != null) {
      await context.read<UploadViewModel>().fetchByClassName(user.className);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserViewModel>().user;
    final uploadVM = context.watch<UploadViewModel>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: kPageBackground,
        extendBody: true,
        bottomNavigationBar: const _FloatingBottomBar(),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isWide = width >= kTabletBreakpoint;
            final hPadding = pagePadding(width);

            return RefreshIndicator(
              color: AppColors.navyBlue,
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  // ── Header com gradiente ──────────────────────────────
                  SliverToBoxAdapter(
                    child: _GradientHeader(
                      user: user,
                      horizontalPadding: hPadding,
                      lessonsCount: uploadVM.status == UploadStatus.success
                          ? uploadVM.uploads.length
                          : null,
                    ),
                  ),

                  // ── Card turma ────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: ContentConstrained(
                      padding: EdgeInsets.fromLTRB(hPadding, 24, hPadding, 0),
                      child: FadeSlideIn(
                        delay: const Duration(milliseconds: 150),
                        child: _ClassCard(user: user, isWide: isWide),
                      ),
                    ),
                  ),

                  // ── Título seção ──────────────────────────────────────
                  SliverToBoxAdapter(
                    child: ContentConstrained(
                      padding: EdgeInsets.fromLTRB(hPadding, 28, hPadding, 14),
                      child: FadeSlideIn(
                        delay: const Duration(milliseconds: 250),
                        child: SectionTitle(
                          title: 'Suas Aulas',
                          trailing: uploadVM.status == UploadStatus.success &&
                                  uploadVM.uploads.isNotEmpty
                              ? '${uploadVM.uploads.length} ${uploadVM.uploads.length == 1 ? 'aula' : 'aulas'}'
                              : null,
                        ),
                      ),
                    ),
                  ),

                  // ── Lista de aulas ────────────────────────────────────
                  SliverToBoxAdapter(
                    child: ContentConstrained(
                      padding: EdgeInsets.symmetric(horizontal: hPadding),
                      child: _LessonsSection(vm: uploadVM, maxWidth: width),
                    ),
                  ),

                  // Espaço para a barra flutuante
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}






// ─────────────────────────────────────────────────────────────────────────────
// Floating Bottom Navigation Bar (Barra Flutuante)
// ─────────────────────────────────────────────────────────────────────────────
class _FloatingBottomBar extends StatelessWidget {
  const _FloatingBottomBar();

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      delay: const Duration(milliseconds: 350),
      beginOffset: const Offset(0, 0.6),
      child: SafeArea(
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                height: 68,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.navyBlue, AppColors.navyBlueLight],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x401A2150),
                      blurRadius: 24,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _FloatingNavItem(
                      icon: Icons.headphones_rounded,
                      label: 'Listening',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ListeningScreen()),
                      ),
                    ),
                    _FloatingNavItem(
                      icon: Icons.style_rounded,
                      label: 'Flashcards',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const FlashcardsScreen()),
                      ),
                    ),
                    _FloatingNavItem(
                      icon: Icons.auto_stories_rounded,
                      label: 'Word of Day',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const WordOfTheDayScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FloatingNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_FloatingNavItem> createState() => _FloatingNavItemState();
}

class _FloatingNavItemState extends State<_FloatingNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: PressableScale(
          onTap: widget.onTap,
          pressedScale: 0.9,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _hovered ? Colors.white.withValues(alpha: 0.10) : Colors.transparent,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSlide(
                  offset: _hovered ? const Offset(0, -0.12) : Offset.zero,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(widget.icon, color: Colors.white, size: 22),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _hovered ? Colors.white : Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
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

// ─────────────────────────────────────────────────────────────────────────────
// Header com gradiente
// ─────────────────────────────────────────────────────────────────────────────
class _GradientHeader extends StatelessWidget {
  final User? user;
  final double horizontalPadding;
  final int? lessonsCount;

  const _GradientHeader({
    required this.user,
    required this.horizontalPadding,
    required this.lessonsCount,
  });

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia,';
    if (hour < 18) return 'Boa tarde,';
    return 'Boa noite,';
  }

  String get _initials {
    final parts = (user?.name ?? '').trim().split(RegExp(r'\s+'))
      ..removeWhere((p) => p.isEmpty);
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isWide = MediaQuery.sizeOf(context).width >= kTabletBreakpoint;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1A2150), // navy escuro
            Color(0xFF2B3A7A), // navy médio
            Color(0xFF47569C), // azul royal
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x441A2150),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Círculos decorativos
          const Positioned(top: -60, right: -40, child: GlowCircle(size: 200, alpha: 0.07)),
          const Positioned(bottom: -70, left: -50, child: GlowCircle(size: 180, alpha: 0.05)),
          const Positioned(
            top: 40,
            right: 90,
            child: GlowCircle(size: 14, alpha: 0.9, color: AppColors.redLight),
          ),

          SafeArea(
            bottom: false,
            child: ContentConstrained(
              padding: EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding - 4, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Barra superior
                  Row(
                    children: [
                      FadeSlideIn(
                        beginOffset: const Offset(-0.1, 0),
                        child: Image.asset('assets/logo.png', height: 52),
                      ),
                      const Spacer(),
                      GlassIconButton(
                        icon: Icons.person_outline_rounded,
                        tooltip: 'Meu Perfil',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ProfileScreen()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GlassIconButton(
                        icon: Icons.logout_rounded,
                        tooltip: 'Sair',
                        onPressed: () {
                          context.read<UserViewModel>().clear();
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: isWide ? 32 : 24),

                  // Saudação
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 80),
                    child: Row(
                      children: [
                        _GradientAvatar(initials: _initials, radius: isWide ? 32 : 28),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _greeting,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: Colors.white60,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user?.name ?? '',
                                style: (isWide
                                        ? textTheme.headlineSmall
                                        : textTheme.titleLarge)
                                    ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Chips de resumo
                  if (user != null) ...[
                    const SizedBox(height: 20),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 160),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _HeaderChip(icon: Icons.school_rounded, label: user!.className),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: lessonsCount == null
                                ? const SizedBox.shrink()
                                : _HeaderChip(
                                    key: ValueKey(lessonsCount),
                                    icon: Icons.play_lesson_rounded,
                                    label:
                                        '$lessonsCount ${lessonsCount == 1 ? 'aula' : 'aulas'}',
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}



class _GradientAvatar extends StatelessWidget {
  final String initials;
  final double radius;

  const _GradientAvatar({required this.initials, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.red, AppColors.redLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: Color(0x55C8102E), blurRadius: 14, offset: Offset(0, 4)),
        ],
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.navyBlueLight,
        child: initials.isEmpty
            ? Icon(Icons.person_rounded, size: radius, color: Colors.white)
            : Text(
                initials,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: radius * 0.7,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeaderChip({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Card de informações da turma
// ─────────────────────────────────────────────────────────────────────────────
class _ClassCard extends StatelessWidget {
  final User? user;
  final bool isWide;

  const _ClassCard({required this.user, required this.isWide});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final nameTile = _InfoTile(
      icon: Icons.class_rounded,
      label: 'Nome da Turma',
      value: user?.className ?? '-',
    );
    final codeTile = _InfoTile(
      icon: Icons.tag_rounded,
      label: 'Código da Turma',
      value: user?.classCode ?? '-',
      highlight: true,
      copyable: user?.classCode != null,
    );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8EAF6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x141A2150),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Topo colorido com gradiente sutil
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFDDE3FF), Color(0xFFEEF0FF)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.school_rounded, color: AppColors.navyBlue, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Sua Turma',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.navyBlue,
                  ),
                ),
              ],
            ),
          ),

          // Linhas de info — lado a lado em telas largas
          Padding(
            padding: const EdgeInsets.all(20),
            child: isWide
                ? Row(
                    children: [
                      Expanded(child: nameTile),
                      Container(
                        width: 1,
                        height: 40,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        color: const Color(0xFFE8EAF6),
                      ),
                      Expanded(child: codeTile),
                    ],
                  )
                : Column(
                    children: [
                      nameTile,
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, color: Color(0xFFEEF0F8)),
                      ),
                      codeTile,
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tile de info individual
// ─────────────────────────────────────────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;
  final bool copyable;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
    this.copyable = false,
  });

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Código copiado!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.navyBlue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 96),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accent = highlight ? AppColors.red : AppColors.navyBlue;

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: highlight ? 0.08 : 0.07),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: accent),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: kMutedColor,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.navyBlue,
                ),
              ),
            ],
          ),
        ),
        if (copyable)
          IconButton(
            tooltip: 'Copiar código',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.copy_rounded, size: 18, color: kMutedColor),
            onPressed: () => _copy(context),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
DateTime? _parseLessonDate(String? title) {
  if (title == null) return null;
  final match = RegExp(r'(\d{2})/(\d{2})/(\d{4})').firstMatch(title);
  if (match == null) return null;
  final day = int.tryParse(match.group(1)!);
  final month = int.tryParse(match.group(2)!);
  final year = int.tryParse(match.group(3)!);
  if (day == null || month == null || year == null) return null;
  return DateTime(year, month, day);
}

// ─────────────────────────────────────────────────────────────────────────────
// Seção de aulas (loading / erro / vazia / lista)
// ─────────────────────────────────────────────────────────────────────────────
class _LessonsSection extends StatelessWidget {
  final UploadViewModel vm;
  final double maxWidth;

  const _LessonsSection({required this.vm, required this.maxWidth});

  @override
  Widget build(BuildContext context) {
    final columns = gridColumnsFor(maxWidth);

    final Widget content;
    switch (vm.status) {
      case UploadStatus.loading:
      case UploadStatus.idle:
        content = _LessonsSkeleton(key: const ValueKey('loading'), columns: columns);

      case UploadStatus.error:
        content = MessageCard(
          key: const ValueKey('error'),
          icon: Icons.error_outline_rounded,
          iconColor: AppColors.red,
          title: 'Erro ao carregar aulas',
          subtitle: vm.errorMessage ?? 'Tente novamente mais tarde.',
        );

      case UploadStatus.success:
        if (vm.uploads.isEmpty) {
          content = const MessageCard(
            key: ValueKey('empty'),
            icon: Icons.menu_book_rounded,
            iconColor: AppColors.navyBlue,
            title: 'Nenhuma aula disponível',
            subtitle: 'Suas aulas aparecerão aqui\nquando estiverem disponíveis.',
          );
          break;
        }

        // Ordena da aula mais recente para a mais antiga pelo título
        final sortedUploads = [...vm.uploads]..sort((a, b) {
            final dateA = _parseLessonDate(a.title);
            final dateB = _parseLessonDate(b.title);
            if (dateA == null && dateB == null) return 0;
            if (dateA == null) return 1;
            if (dateB == null) return -1;
            return dateB.compareTo(dateA); // mais recente primeiro
          });

        content = ResponsiveGrid(
          key: const ValueKey('list'),
          columns: columns,
          children: [
            for (var i = 0; i < sortedUploads.length; i++)
              FadeSlideIn(
                // Escalonamento limitado para listas longas não demorarem
                delay: Duration(milliseconds: 60 * (i < 10 ? i : 10)),
                child: _LessonCard(upload: sortedUploads[i], isLatest: i == 0),
              ),
          ],
        );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: content,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Skeleton de carregamento com brilho animado
// ─────────────────────────────────────────────────────────────────────────────
class _LessonsSkeleton extends StatefulWidget {
  final int columns;

  const _LessonsSkeleton({super.key, required this.columns});

  @override
  State<_LessonsSkeleton> createState() => _LessonsSkeletonState();
}

class _LessonsSkeletonState extends State<_LessonsSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final shader = LinearGradient(
          colors: const [Color(0xFFE8EAF6), Color(0xFFF6F7FD), Color(0xFFE8EAF6)],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment(-1.5 + 3 * t, 0),
          end: Alignment(-0.5 + 3 * t, 0),
        );

        Widget bar(double width, double height) => Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                gradient: shader,
                borderRadius: BorderRadius.circular(6),
              ),
            );

        return ResponsiveGrid(
          columns: widget.columns,
          children: List.generate(
            widget.columns * 2,
            (_) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: shader,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        bar(double.infinity, 14),
                        const SizedBox(height: 8),
                        bar(120, 10),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Card individual de aula
// ─────────────────────────────────────────────────────────────────────────────
class _LessonCard extends StatefulWidget {
  final UploadFilteredDto upload;
  final bool isLatest;

  const _LessonCard({required this.upload, this.isLatest = false});

  @override
  State<_LessonCard> createState() => _LessonCardState();
}

class _LessonCardState extends State<_LessonCard> {
  bool _hovered = false;

  bool get _hasVideo =>
      widget.upload.videoName != null && widget.upload.videoName!.isNotEmpty;

  void _open() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(
          title: widget.upload.title,
          videoName: widget.upload.videoName!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final enabled = _hasVideo;

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: PressableScale(
        onTap: enabled ? _open : null,
        pressedScale: 0.97,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _hovered && enabled ? -3 : 0, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _hovered && enabled
                  ? AppColors.navyBlue.withValues(alpha: 0.18)
                  : const Color(0xFFE8EAF6),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.navyBlue.withValues(alpha: _hovered && enabled ? 0.14 : 0.06),
                blurRadius: _hovered && enabled ? 24 : 12,
                offset: Offset(0, _hovered && enabled ? 10 : 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Ícone com gradiente
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _hovered && enabled
                        ? const [AppColors.red, AppColors.redLight]
                        : const [Color(0xFF1A2150), Color(0xFF3D4FA0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _hasVideo ? Icons.play_arrow_rounded : Icons.article_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.isLatest)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.red.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'MAIS RECENTE',
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    Text(
                      widget.upload.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.navyBlue,
                        height: 1.3,
                      ),
                    ),
                    if (_hasVideo) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.videocam_outlined, size: 14, color: AppColors.red),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.upload.videoName!,
                              style: textTheme.labelSmall?.copyWith(color: kMutedColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              if (enabled) ...[
                const SizedBox(width: 8),
                AnimatedSlide(
                  offset: _hovered ? const Offset(0.2, 0) : Offset.zero,
                  duration: const Duration(milliseconds: 220),
                  child: const Icon(Icons.chevron_right_rounded, color: AppColors.navyBlue),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
