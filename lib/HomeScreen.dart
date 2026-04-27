import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'viewmodels/user_viewmodel.dart';
import 'viewmodels/upload_viewmodel.dart';
import 'LoginScreen.dart';
import 'VideoPlayerScreen.dart';
import 'app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<UserViewModel>().user;
      if (user != null) {
        context.read<UploadViewModel>().fetchByClassName(user.className);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final user = context.watch<UserViewModel>().user;
    final uploadVM = context.watch<UploadViewModel>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FB),
        body: Column(
          children: [
            // ── Header com gradiente ──────────────────────────────────
            _GradientHeader(user: user, textTheme: textTheme),

            // ── Conteúdo scrollável ───────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Card turma
                    _ClassCard(user: user, textTheme: textTheme),
                    const SizedBox(height: 24),

                    // Título seção
                    Text(
                      'Suas Aulas',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.navyBlue,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Lista de aulas
                    _LessonsSection(vm: uploadVM, textTheme: textTheme),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header com gradiente
// ─────────────────────────────────────────────────────────────────────────────
class _GradientHeader extends StatelessWidget {
  final dynamic user;
  final TextTheme textTheme;

  const _GradientHeader({required this.user, required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x441A2150),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barra superior
              Row(
                children: [
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: Colors.white70),
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
              const SizedBox(height: 20),

              // Saudação
              Row(
                children: [
                  // Avatar com borda gradiente vermelha
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.red, AppColors.redLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const CircleAvatar(
                      radius: 26,
                      backgroundColor: Color(0xFF2B3A7A),
                      child: Icon(Icons.person_rounded, size: 28, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bem-vindo(a),',
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.white60,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          user?.name ?? '',
                          style: textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card de informações da turma
// ─────────────────────────────────────────────────────────────────────────────
class _ClassCard extends StatelessWidget {
  final dynamic user;
  final TextTheme textTheme;

  const _ClassCard({required this.user, required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x181A2150),
            blurRadius: 16,
            offset: Offset(0, 4),
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
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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

          // Linhas de info
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _InfoTile(
                  icon: Icons.class_rounded,
                  label: 'Nome da Turma',
                  value: user?.className ?? '-',
                ),
                const SizedBox(height: 14),
                _InfoTile(
                  icon: Icons.tag_rounded,
                  label: 'Código da Turma',
                  value: user?.classCode ?? '-',
                  highlight: true,
                ),
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

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: highlight
                ? AppColors.red.withValues(alpha: 0.08)
                : AppColors.navyBlue.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: highlight ? AppColors.red : AppColors.navyBlue,
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: const Color(0xFF767AA8),
                letterSpacing: 0.3,
              ),
            ),
            Text(
              value,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.navyBlue,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Utilitário: extrai DateTime de um título no formato "Aula dd/MM/yyyy"
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
  final TextTheme textTheme;

  const _LessonsSection({required this.vm, required this.textTheme});

  @override
  Widget build(BuildContext context) {
    switch (vm.status) {
      case UploadStatus.loading:
      case UploadStatus.idle:
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: CircularProgressIndicator(color: AppColors.navyBlue),
          ),
        );

      case UploadStatus.error:
        return _MessageCard(
          icon: Icons.error_outline_rounded,
          iconColor: AppColors.red,
          title: 'Erro ao carregar aulas',
          subtitle: vm.errorMessage ?? 'Tente novamente mais tarde.',
          textTheme: textTheme,
        );

      case UploadStatus.success:
        if (vm.uploads.isEmpty) {
          return _MessageCard(
            icon: Icons.menu_book_rounded,
            iconColor: AppColors.navyBlue,
            title: 'Nenhuma aula disponível',
            subtitle: 'Suas aulas aparecerão aqui\nquando estiverem disponíveis.',
            textTheme: textTheme,
          );
        }

        // Ordena da aula mais recente para a mais antiga pelo título
        final sortedUploads = [...vm.uploads]..sort((a, b) {
            final dateA = _parseLessonDate(a.title as String?);
            final dateB = _parseLessonDate(b.title as String?);
            if (dateA == null && dateB == null) return 0;
            if (dateA == null) return 1;
            if (dateB == null) return -1;
            return dateB.compareTo(dateA); // mais recente primeiro
          });

        return Column(
          children: sortedUploads
              .map((upload) => _LessonCard(upload: upload, textTheme: textTheme))
              .toList(),
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card genérico de mensagem (vazio / erro)
// ─────────────────────────────────────────────────────────────────────────────
class _MessageCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final TextTheme textTheme;

  const _MessageCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x101A2150),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFFDDE3FF), iconColor.withValues(alpha: 0.15)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(icon, size: 48, color: iconColor),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.navyBlue,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: const Color(0xFF767AA8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card individual de aula
// ─────────────────────────────────────────────────────────────────────────────
class _LessonCard extends StatelessWidget {
  final dynamic upload;
  final TextTheme textTheme;

  const _LessonCard({required this.upload, required this.textTheme});

  @override
  Widget build(BuildContext context) {
    final hasVideo = upload.videoName != null && upload.videoName!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x101A2150),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A2150), Color(0xFF3D4FA0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            hasVideo ? Icons.play_circle_outline_rounded : Icons.article_outlined,
            color: Colors.white,
            size: 26,
          ),
        ),
        title: Text(
          upload.title ?? '',
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.navyBlue,
          ),
        ),
        subtitle: hasVideo
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    const Icon(Icons.videocam_outlined, size: 14, color: AppColors.red),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        upload.videoName!,
                        style: textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF767AA8),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )
            : null,
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.navyBlue,
        ),
        onTap: hasVideo
            ? () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => VideoPlayerScreen(
                      title: upload.title ?? '',
                      videoName: upload.videoName!,
                    ),
                  ),
                );
              }
            : null,
      ),
    );
  }
}

