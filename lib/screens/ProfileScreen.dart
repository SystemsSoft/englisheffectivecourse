import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/assinatura_status_model.dart';
import '../models/user_model.dart';
import '../services/aluno_ia_service.dart';
import '../services/megan_user_resolver.dart';
import '../viewmodels/user_viewmodel.dart';
import '../app_theme.dart';
import '../widgets/ui_kit.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AlunoIaService _alunoIaService = AlunoIaService();
  final MeganUserResolver _userResolver = MeganUserResolver();

  bool _loading = true;
  String? _loadError;
  String? _userId;
  AssinaturaStatusDto? _assinatura;

  bool _openingPortal = false;
  String? _portalError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = context.read<UserViewModel>().user!;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final (userId, _) = await _userResolver.resolve(user);
      final assinatura = await _alunoIaService.getAssinaturaStatus(userId);
      if (!mounted) return;
      setState(() {
        _userId = userId;
        _assinatura = assinatura;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Não foi possível carregar seu perfil: $e';
        _loading = false;
      });
    }
  }

  Future<void> _openPortal() async {
    final userId = _userId;
    if (userId == null) return;
    setState(() {
      _openingPortal = true;
      _portalError = null;
    });
    try {
      // A Stripe manda o aluno de volta pra cá quando ele sair do portal.
      final returnUrl = Uri.base.toString();
      final url = await _alunoIaService.getPortalAssinaturaUrl(userId, returnUrl);
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      if (!mounted) return;
      setState(() => _openingPortal = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _openingPortal = false;
        _portalError = '$e';
      });
    }
  }

  String _subscriptionStatusLabel() {
    final status = _assinatura;
    if (status == null || !status.assinante) {
      return 'Você ainda não tem uma assinatura ativa.';
    }
    if (status.ativa) return 'Sua assinatura está ativa.';
    if (status.cancelada) return 'Sua assinatura foi cancelada.';
    if (status.pagamentoFalhou) return 'Houve uma falha no pagamento da sua assinatura.';
    return 'Status da assinatura: ${status.status}';
  }

  // Cor e ícone do selo de status da assinatura
  (Color, IconData, String) _subscriptionBadge() {
    final status = _assinatura;
    if (status == null || !status.assinante) {
      return (kMutedColor, Icons.lock_outline_rounded, 'Sem assinatura');
    }
    if (status.ativa) return (const Color(0xFF2E7D32), Icons.verified_rounded, 'Ativa');
    if (status.pagamentoFalhou) return (AppColors.red, Icons.error_outline_rounded, 'Pagamento falhou');
    if (status.cancelada) return (const Color(0xFFF57C00), Icons.cancel_outlined, 'Cancelada');
    return (kMutedColor, Icons.info_outline_rounded, status.status);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserViewModel>().user;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: kPageBackground,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final hPadding = pagePadding(constraints.maxWidth);
            final isWide = constraints.maxWidth >= kTabletBreakpoint;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: AppPageHeader(
                    title: 'Meu Perfil',
                    subtitle: 'Seus dados e assinatura',
                    icon: Icons.person_rounded,
                    bottom: _ProfileIdentity(user: user),
                  ),
                ),
                SliverToBoxAdapter(
                  child: ContentConstrained(
                    maxWidth: 960,
                    padding: EdgeInsets.fromLTRB(hPadding, 24, hPadding, 40),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      child: _loading
                          ? const Padding(
                              key: ValueKey('loading'),
                              padding: EdgeInsets.symmetric(vertical: 60),
                              child: Center(
                                child: CircularProgressIndicator(color: AppColors.navyBlue),
                              ),
                            )
                          : _loadError != null
                              ? MessageCard(
                                  key: const ValueKey('error'),
                                  icon: Icons.cloud_off_rounded,
                                  iconColor: AppColors.red,
                                  title: 'Algo deu errado',
                                  subtitle: _loadError!,
                                  actionLabel: 'Tentar novamente',
                                  actionIcon: Icons.refresh_rounded,
                                  onAction: _load,
                                )
                              : _buildContent(user, isWide),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(User? user, bool isWide) {
    final accountCard = FadeSlideIn(
      delay: const Duration(milliseconds: 100),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(title: 'Dados da conta'),
            const SizedBox(height: 18),
            _DetailRow(icon: Icons.mail_outline_rounded, label: 'E-mail', value: user?.email ?? '-'),
            const Divider(height: 28, color: Color(0xFFEEF0F8)),
            _DetailRow(icon: Icons.class_rounded, label: 'Turma', value: user?.className ?? '-'),
            const Divider(height: 28, color: Color(0xFFEEF0F8)),
            _DetailRow(
              icon: Icons.tag_rounded,
              label: 'Código da Turma',
              value: user?.classCode ?? '-',
              accent: AppColors.red,
            ),
          ],
        ),
      ),
    );

    final subscriptionCard = FadeSlideIn(
      delay: const Duration(milliseconds: 180),
      child: _buildSubscriptionCard(),
    );

    if (isWide) {
      return IntrinsicHeight(
        key: const ValueKey('content'),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: accountCard),
            const SizedBox(width: 20),
            Expanded(child: subscriptionCard),
          ],
        ),
      );
    }

    return Column(
      key: const ValueKey('content'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [accountCard, const SizedBox(height: 16), subscriptionCard],
    );
  }

  Widget _buildSubscriptionCard() {
    final isAssinante = _assinatura?.assinante ?? false;
    final (badgeColor, badgeIcon, badgeLabel) = _subscriptionBadge();

    return AppCard(
      accent: isAssinante ? AppColors.red : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: SectionTitle(title: 'Assinatura')),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 14, color: badgeColor),
                    const SizedBox(width: 4),
                    Text(
                      badgeLabel,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: isAssinante
                      ? const LinearGradient(colors: [AppColors.red, AppColors.redLight])
                      : null,
                  color: isAssinante ? null : AppColors.navyBlue.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isAssinante ? Icons.workspace_premium_rounded : Icons.lock_outline_rounded,
                  color: isAssinante ? Colors.white : kMutedColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _subscriptionStatusLabel(),
                  style: const TextStyle(color: Color(0xFF44476A), fontSize: 14, height: 1.5),
                ),
              ),
            ],
          ),
          if (isAssinante) ...[
            const SizedBox(height: 22),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              child: _portalError != null
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        _portalError!,
                        style: const TextStyle(color: AppColors.red, fontSize: 12),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
            GradientButton(
              label: _openingPortal ? 'Abrindo...' : 'Gerenciar assinatura',
              icon: Icons.settings_rounded,
              loading: _openingPortal,
              onPressed: _openPortal,
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Avatar, nome e e-mail dentro do header
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileIdentity extends StatelessWidget {
  final User? user;

  const _ProfileIdentity({required this.user});

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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [AppColors.red, AppColors.redLight]),
              boxShadow: [
                BoxShadow(color: Color(0x55C8102E), blurRadius: 14, offset: Offset(0, 4)),
              ],
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.navyBlueLight,
              child: _initials.isEmpty
                  ? const Icon(Icons.person_rounded, size: 32, color: Colors.white)
                  : Text(
                      _initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 21,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user?.email ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(color: Colors.white70),
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
// Linha de detalhe (ícone + rótulo + valor)
// ─────────────────────────────────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.accent = AppColors.navyBlue,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: accent),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: textTheme.labelSmall?.copyWith(color: kMutedColor)),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.navyBlue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
