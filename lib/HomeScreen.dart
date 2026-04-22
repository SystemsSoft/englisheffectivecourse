import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'viewmodels/user_viewmodel.dart';
import 'LoginScreen.dart';
import 'app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final user = context.watch<UserViewModel>().user;

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

                    // Placeholder aulas
                    _EmptyLessonsCard(textTheme: textTheme),
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
            Color(0xFF3D4FA0), // azul royal
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
                  Image.asset('assets/logo.png', height: 36),
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
// Placeholder de aulas
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyLessonsCard extends StatelessWidget {
  final TextTheme textTheme;

  const _EmptyLessonsCard({required this.textTheme});

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
              gradient: const LinearGradient(
                colors: [Color(0xFFDDE3FF), Color(0xFFFFDADA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              size: 48,
              color: AppColors.navyBlue,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma aula disponível',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.navyBlue,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Suas aulas aparecerão aqui\nquando estiverem disponíveis.',
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
