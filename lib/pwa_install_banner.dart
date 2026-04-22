import 'dart:async';
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'services/pwa_install_service.dart';

/// Wrapper que exibe um banner de instalação do PWA quando disponível.
/// Envolva o widget raiz com este componente.
class PwaInstallWrapper extends StatefulWidget {
  final Widget child;

  const PwaInstallWrapper({super.key, required this.child});

  @override
  State<PwaInstallWrapper> createState() => _PwaInstallWrapperState();
}

class _PwaInstallWrapperState extends State<PwaInstallWrapper>
    with SingleTickerProviderStateMixin {
  bool _showBanner = false;
  late final AnimationController _animCtrl;
  late final Animation<Offset> _slideAnim;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    // Registra callback JS para quando o evento disparar após Flutter iniciar
    registerPwaCallback(_onInstallAvailable);

    // Poll por até 10s para capturar prompts que dispararam antes do Flutter
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (t) {
      if (isPwaInstallAvailable) {
        _onInstallAvailable();
        t.cancel();
      }
      if (t.tick >= 5) t.cancel();
    });
  }

  void _onInstallAvailable() {
    if (!mounted || _showBanner) return;
    setState(() => _showBanner = true);
    _animCtrl.forward();
  }

  void _dismiss() {
    _animCtrl.reverse().then((_) {
      if (mounted) setState(() => _showBanner = false);
    });
  }

  void _install() {
    triggerPwaInstall();
    _dismiss();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showBanner)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SlideTransition(
              position: _slideAnim,
              child: _InstallBanner(
                onInstall: _install,
                onDismiss: _dismiss,
              ),
            ),
          ),
      ],
    );
  }
}

class _InstallBanner extends StatelessWidget {
  final VoidCallback onInstall;
  final VoidCallback onDismiss;

  const _InstallBanner({required this.onInstall, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2150), Color(0xFF2B3A7A), Color(0xFF3D4FA0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x661A2150),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Row(
          children: [
            // Ícone do app
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(6),
              child: Image.asset('assets/logo.png', fit: BoxFit.contain),
            ),
            const SizedBox(width: 12),

            // Texto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Adicionar à tela inicial',
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Instale o app para acesso rápido',
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Botão Instalar
            TextButton(
              onPressed: onInstall,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Instalar',
                style: textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Fechar
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 20),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }
}

