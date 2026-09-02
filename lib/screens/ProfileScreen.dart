import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/assinatura_status_model.dart';
import '../models/user_model.dart';
import '../services/aluno_ia_service.dart';
import '../services/megan_user_resolver.dart';
import '../viewmodels/user_viewmodel.dart';
import '../app_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserViewModel>().user;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.navyBlue,
        title: const Text('Meu Perfil'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.navyBlue))
          : _loadError != null
              ? _buildError()
              : _buildContent(user),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF767AA8)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Tentar novamente')),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(User? user) {
    final isAssinante = _assinatura?.assinante ?? false;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [AppColors.red, AppColors.redLight]),
              ),
              child: const CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.navyBlueLight,
                child: Icon(Icons.person_rounded, size: 44, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              user?.name ?? '',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navyBlue),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              user?.email ?? '',
              style: const TextStyle(fontSize: 13, color: Color(0xFF767AA8)),
            ),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Color(0x181A2150), blurRadius: 16, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isAssinante ? Icons.workspace_premium_rounded : Icons.lock_outline_rounded,
                      color: isAssinante ? AppColors.red : const Color(0xFF767AA8),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Assinatura',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyBlue, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _subscriptionStatusLabel(),
                  style: const TextStyle(color: Color(0xFF767AA8), fontSize: 14, height: 1.4),
                ),
                if (isAssinante) ...[
                  const SizedBox(height: 18),
                  if (_portalError != null) ...[
                    Text(_portalError!, style: const TextStyle(color: AppColors.red, fontSize: 12)),
                    const SizedBox(height: 8),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openingPortal ? null : _openPortal,
                      icon: _openingPortal
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navyBlue),
                            )
                          : const Icon(Icons.settings_rounded),
                      label: Text(_openingPortal ? 'Abrindo...' : 'Gerenciar assinatura'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navyBlue,
                        side: const BorderSide(color: AppColors.navyBlue),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
