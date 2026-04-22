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
  bool _isIos = false;
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

    // Registra callback JS para Android/Chrome
    registerPwaCallback(_onInstallAvailable);

    // Poll por até 10s para Android (beforeinstallprompt)
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (t) {
      if (isPwaInstallAvailable) {
        _onInstallAvailable(isIos: false);
        t.cancel();
      }
      if (t.tick >= 5) t.cancel();
    });

    // iOS: mostra banner após 2s se ainda não instalado
    if (isIosDevice && !isInStandaloneMode) {
      Future.delayed(const Duration(seconds: 2), () {
        _onInstallAvailable(isIos: true);
      });
    }
  }

  void _onInstallAvailable({bool isIos = false}) {
    if (!mounted || _showBanner) return;
    setState(() {
      _isIos = isIos;
      _showBanner = true;
    });
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
              child: _isIos
                  ? _IosBanner(onDismiss: _dismiss)
                  : _AndroidBanner(onInstall: _install, onDismiss: _dismiss),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Banner Android/Chrome — usa beforeinstallprompt
// ─────────────────────────────────────────────────────────────────────────────
class _AndroidBanner extends StatelessWidget {
  final VoidCallback onInstall;
  final VoidCallback onDismiss;

  const _AndroidBanner({required this.onInstall, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return _BannerShell(
      onDismiss: onDismiss,
      child: Row(
        children: [
          _AppIcon(),
          const SizedBox(width: 12),
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
                  style: textTheme.bodySmall?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _RedButton(label: 'Instalar', onPressed: onInstall),
          _CloseButton(onDismiss: onDismiss),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Banner iOS/Safari — instrução manual
// ─────────────────────────────────────────────────────────────────────────────
class _IosBanner extends StatelessWidget {
  final VoidCallback onDismiss;

  const _IosBanner({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return _BannerShell(
      onDismiss: onDismiss,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Linha topo: ícone + título + fechar
          Row(
            children: [
              _AppIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Instalar no iPhone / iPad',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _CloseButton(onDismiss: onDismiss),
            ],
          ),
          const SizedBox(height: 12),

          // Passo a passo
          _IosStep(
            icon: Icons.ios_share_rounded,
            text: 'Abra no Safari e toque em ',
            highlight: 'Compartilhar',
          ),
          const SizedBox(height: 8),
          _IosStep(
            icon: Icons.add_box_outlined,
            text: 'Depois toque em ',
            highlight: 'Adicionar à Tela de Início',
          ),
          const SizedBox(height: 8),
          _IosStep(
            icon: Icons.info_outline_rounded,
            text: 'Chrome no iPhone ',
            highlight: 'não suporta instalação de apps',
            suffix: ' — use o Safari.',
          ),
        ],
      ),
    );
  }
}

class _IosStep extends StatelessWidget {
  final IconData icon;
  final String text;
  final String highlight;
  final String suffix;

  const _IosStep({
    required this.icon,
    required this.text,
    required this.highlight,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: textTheme.bodySmall?.copyWith(color: Colors.white70, height: 1.4),
              children: [
                TextSpan(text: text),
                TextSpan(
                  text: highlight,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (suffix.isNotEmpty) TextSpan(text: suffix),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets compartilhados
// ─────────────────────────────────────────────────────────────────────────────
class _BannerShell extends StatelessWidget {
  final Widget child;
  final VoidCallback onDismiss;

  const _BannerShell({required this.child, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
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
        child: child,
      ),
    );
  }
}

class _AppIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(5),
      child: Image.asset('assets/logo.png', fit: BoxFit.contain),
    );
  }
}

class _RedButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _RedButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: AppColors.red,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        label,
        style: textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onDismiss;

  const _CloseButton({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 20),
      onPressed: onDismiss,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }
}

