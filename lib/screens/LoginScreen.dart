import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'HomeScreen.dart';
import '../services/access_service.dart';
import '../models/access_model.dart';
import '../models/user_model.dart';
import '../viewmodels/user_viewmodel.dart';
import '../app_theme.dart';
import '../widgets/ui_kit.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  final _accessService = AccessService();

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final AccessDto aluno = await _accessService.login(
        _nameController.text.trim(),
        _passwordController.text.trim(),
      );
      if (!mounted) return;
      context.read<UserViewModel>().setUser(
            User(
              name: aluno.name,
              email: aluno.email,
              classCode: aluno.classCode,
              className: aluno.className,
              ulid: aluno.ulid,
            ),
          );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openSupport() async {
    final uri = Uri.parse('https://wa.me/5524992062668');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: kPageBackground,
        body: LayoutBuilder(
          builder: (context, constraints) {
            // Telas largas: painel da marca à esquerda e formulário à direita
            if (constraints.maxWidth >= 900) {
              return Row(
                children: [
                  const Expanded(flex: 5, child: _BrandPanel(fullHeight: true)),
                  Expanded(
                    flex: 4,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(40),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: _buildForm(context),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            // Celular / tablet: header com logo e card do formulário sobreposto
            return SingleChildScrollView(
              child: Column(
                children: [
                  const _BrandPanel(fullHeight: false),
                  Transform.translate(
                    offset: const Offset(0, -36),
                    child: ContentConstrained(
                      maxWidth: 480,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildForm(context),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return FadeSlideIn(
      delay: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: kCardBorder),
          boxShadow: const [
            BoxShadow(color: Color(0x1F1A2150), blurRadius: 32, offset: Offset(0, 12)),
          ],
        ),
        child: Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Título do card
                const SectionTitle(title: 'Entrar na conta'),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: Text(
                    'Que bom ter você aqui de novo!',
                    style: textTheme.bodySmall?.copyWith(color: kMutedColor),
                  ),
                ),
                const SizedBox(height: 28),

                // Campo Nome
                FadeSlideIn(
                  delay: const Duration(milliseconds: 300),
                  child: TextFormField(
                    controller: _nameController,
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.username],
                    style: const TextStyle(color: AppColors.navyBlue),
                    decoration: appInputDecoration(
                      label: 'Nome',
                      hint: 'Digite seu nome',
                      prefixIcon: Icons.person_outline_rounded,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor, informe seu nome';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Campo Senha
                FadeSlideIn(
                  delay: const Duration(milliseconds: 380),
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: (_) => _onLogin(),
                    style: const TextStyle(color: AppColors.navyBlue),
                    decoration: appInputDecoration(
                      label: 'Senha',
                      hint: 'Digite sua senha',
                      prefixIcon: Icons.lock_outline_rounded,
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, anim) =>
                              ScaleTransition(scale: anim, child: child),
                          child: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            key: ValueKey(_obscurePassword),
                            color: kMutedColor,
                          ),
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor, informe sua senha';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 28),

                // Botão Entrar com gradiente
                FadeSlideIn(
                  delay: const Duration(milliseconds: 460),
                  child: GradientButton(
                    label: 'Entrar',
                    loading: _isLoading,
                    onPressed: _onLogin,
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(color: kCardBorder),
                const SizedBox(height: 16),

                // Suporte via WhatsApp
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    const Text(
                      'Precisa de ajuda?',
                      style: TextStyle(color: kMutedColor, fontSize: 13),
                    ),
                    PressableScale(
                      onTap: _openSupport,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFC8E6C9)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.network(
                              'https://upload.wikimedia.org/wikipedia/commons/6/6b/WhatsApp.svg',
                              height: 18,
                              width: 18,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.chat,
                                color: Color(0xFF25D366),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Flexible(
                              child: Text(
                                'Suporte WhatsApp',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Color(0xFF1B5E20),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
// Painel da marca com gradiente e logo
// ─────────────────────────────────────────────────────────────────────────────
class _BrandPanel extends StatelessWidget {
  final bool fullHeight;

  const _BrandPanel({required this.fullHeight});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2150), Color(0xFF2B3A7A), Color(0xFF3D4FA0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: fullHeight
            ? const BorderRadius.only(
                topRight: Radius.circular(40),
                bottomRight: Radius.circular(40),
              )
            : const BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
        boxShadow: const [
          BoxShadow(color: Color(0x441A2150), blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
      child: Stack(
        children: [
          // Círculos decorativos
          const Positioned(top: -80, right: -60, child: GlowCircle(size: 260, alpha: 0.07)),
          const Positioned(bottom: -90, left: -60, child: GlowCircle(size: 220, alpha: 0.05)),
          const Positioned(
            top: 70,
            left: 40,
            child: GlowCircle(size: 12, alpha: 0.9, color: AppColors.redLight),
          ),

          SafeArea(
            bottom: false,
            child: SizedBox(
              width: double.infinity,
              height: fullHeight ? double.infinity : null,
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, fullHeight ? 24 : 64),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo com leve zoom de entrada
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.85, end: 1),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutBack,
                      builder: (context, scale, child) =>
                          Transform.scale(scale: scale, child: child),
                      child: FadeSlideIn(
                        child: Image.asset(
                          'assets/logo.png',
                          height: fullHeight ? 280 : 190,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 120),
                      child: Text(
                        'Faça login para continuar',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
