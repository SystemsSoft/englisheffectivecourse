import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Componentes visuais compartilhados entre as telas (animações, header,
// cards e botões) — mantêm a identidade navy/vermelho em todo o app.
// ─────────────────────────────────────────────────────────────────────────────

// Breakpoints e largura máxima do conteúdo
const double kTabletBreakpoint = 720;
const double kDesktopBreakpoint = 1080;
const double kMaxContentWidth = 1200;

const Color kMutedColor = Color(0xFF767AA8);
const Color kPageBackground = Color(0xFFF4F6FB);
const Color kCardBorder = Color(0xFFE8EAF6);

/// Padding horizontal da página conforme a largura da tela.
double pagePadding(double width) {
  if (width >= kDesktopBreakpoint) return 40;
  if (width >= kTabletBreakpoint) return 28;
  return 20;
}

// ─────────────────────────────────────────────────────────────────────────────
// Centraliza o conteúdo e limita a largura em telas grandes
// ─────────────────────────────────────────────────────────────────────────────
class ContentConstrained extends StatelessWidget {
  final EdgeInsets padding;
  final double maxWidth;
  final Widget child;

  const ContentConstrained({
    super.key,
    this.padding = EdgeInsets.zero,
    this.maxWidth = kMaxContentWidth,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animação de entrada (fade + slide) com atraso opcional
// ─────────────────────────────────────────────────────────────────────────────
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Offset beginOffset;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.beginOffset = const Offset(0, 0.08),
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  );
  late final Animation<double> _curve =
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween<Offset>(begin: widget.beginOffset, end: Offset.zero)
            .animate(_curve),
        child: widget.child,
      ),
    );
  }
}

/// Atraso escalonado para listas, limitado para listas longas não demorarem.
Duration staggerDelay(int index, {int baseMs = 0, int stepMs = 60}) =>
    Duration(milliseconds: baseMs + stepMs * (index < 10 ? index : 10));

// ─────────────────────────────────────────────────────────────────────────────
// Efeito de toque: encolhe levemente ao pressionar
// ─────────────────────────────────────────────────────────────────────────────
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.96,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                widget.onTap!();
              },
        child: AnimatedScale(
          scale: _pressed ? widget.pressedScale : 1,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Grade responsiva que mantém a altura natural dos cards
// ─────────────────────────────────────────────────────────────────────────────
int gridColumnsFor(double width) {
  if (width >= kDesktopBreakpoint) return 3;
  if (width >= kTabletBreakpoint) return 2;
  return 1;
}

class ResponsiveGrid extends StatelessWidget {
  final int columns;
  final List<Widget> children;
  static const double spacing = 14;

  const ResponsiveGrid({
    super.key,
    required this.columns,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    if (columns <= 1) {
      return Column(
        children: [
          for (final child in children)
            Padding(padding: const EdgeInsets.only(bottom: spacing), child: child),
        ],
      );
    }

    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: spacing),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var c = 0; c < columns; c++) ...[
                  if (c > 0) const SizedBox(width: spacing),
                  Expanded(
                    child: i + c < children.length ? children[i + c] : const SizedBox(),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card branco com borda suave; com onTap ganha hover (sobe) e toque (encolhe)
// ─────────────────────────────────────────────────────────────────────────────
class AppCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final double radius;
  final Color? accent;
  final bool selected;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
    this.radius = 22,
    this.accent,
    this.selected = false,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent ?? AppColors.navyBlue;
    final lifted = (_hovered && widget.onTap != null) || widget.selected;

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, _hovered && widget.onTap != null ? -3 : 0, 0),
      padding: widget.padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(widget.radius),
        border: Border.all(
          color: widget.selected
              ? accent
              : lifted
                  ? accent.withValues(alpha: 0.2)
                  : kCardBorder,
          width: widget.selected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: lifted ? 0.16 : 0.06),
            blurRadius: lifted ? 24 : 12,
            offset: Offset(0, lifted ? 10 : 4),
          ),
        ],
      ),
      child: widget.child,
    );

    if (widget.onTap == null) return card;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: PressableScale(onTap: widget.onTap, pressedScale: 0.98, child: card),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Círculo decorativo usado nos headers com gradiente
// ─────────────────────────────────────────────────────────────────────────────
class GlowCircle extends StatelessWidget {
  final double size;
  final double alpha;
  final Color color;

  const GlowCircle({
    super.key,
    required this.size,
    required this.alpha,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: alpha),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Botão de ícone translúcido (sobre o header navy)
// ─────────────────────────────────────────────────────────────────────────────
class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const GlassIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: PressableScale(
        onTap: onPressed,
        pressedScale: 0.88,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header com gradiente navy padrão das telas internas
// ─────────────────────────────────────────────────────────────────────────────
class AppPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<Widget> actions;
  final Widget? bottom;
  final bool showBack;

  const AppPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.actions = const [],
    this.bottom,
    this.showBack = true,
  });

  static const gradient = LinearGradient(
    colors: [
      Color(0xFF1A2150), // navy escuro
      Color(0xFF2B3A7A), // navy médio
      Color(0xFF47569C), // azul royal
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= kTabletBreakpoint;
    final hPadding = pagePadding(width);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
        boxShadow: [
          BoxShadow(color: Color(0x441A2150), blurRadius: 24, offset: Offset(0, 10)),
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
            child: GlowCircle(size: 12, alpha: 0.9, color: AppColors.redLight),
          ),

          SafeArea(
            bottom: false,
            child: ContentConstrained(
              padding: EdgeInsets.fromLTRB(hPadding, 12, hPadding, bottom == null ? 28 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Barra superior
                  Row(
                    children: [
                      if (showBack && Navigator.of(context).canPop())
                        GlassIconButton(
                          icon: Icons.arrow_back_rounded,
                          tooltip: 'Voltar',
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      const Spacer(),
                      for (var i = 0; i < actions.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        actions[i],
                      ],
                    ],
                  ),
                  SizedBox(height: isWide ? 24 : 18),

                  // Título
                  FadeSlideIn(
                    child: Row(
                      children: [
                        if (icon != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                            ),
                            child: Icon(icon, color: Colors.white, size: isWide ? 30 : 26),
                          ),
                          const SizedBox(width: 16),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: (isWide ? textTheme.headlineSmall : textTheme.titleLarge)
                                    ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              if (subtitle != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  subtitle!,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: Colors.white60,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (bottom != null) ...[
                    const SizedBox(height: 18),
                    FadeSlideIn(delay: const Duration(milliseconds: 100), child: bottom!),
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

// ─────────────────────────────────────────────────────────────────────────────
// Título de seção com barra vermelha
// ─────────────────────────────────────────────────────────────────────────────
class SectionTitle extends StatelessWidget {
  final String title;
  final String? trailing;

  const SectionTitle({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.red,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.navyBlue,
              letterSpacing: 0.4,
            ),
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: textTheme.labelMedium?.copyWith(color: kMutedColor),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Botão principal com gradiente navy (com estado de carregamento)
// ─────────────────────────────────────────────────────────────────────────────
class GradientButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;

  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: PressableScale(
        onTap: enabled ? widget.onPressed : null,
        pressedScale: 0.97,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 54,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A2150), Color(0xFF2B3A7A), Color(0xFF3D4FA0)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.navyBlue.withValues(alpha: _hovered && enabled ? 0.40 : 0.25),
                blurRadius: _hovered && enabled ? 22 : 12,
                offset: Offset(0, _hovered && enabled ? 8 : 4),
              ),
            ],
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: ScaleTransition(scale: anim, child: child)),
              child: widget.loading
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : Row(
                      key: const ValueKey('label'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.label,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (widget.icon == null) ...[
                          const SizedBox(width: 8),
                          AnimatedSlide(
                            offset: _hovered ? const Offset(0.25, 0) : Offset.zero,
                            duration: const Duration(milliseconds: 200),
                            child: const Icon(Icons.arrow_forward_rounded,
                                color: Colors.white, size: 20),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Estado vazio / erro com ícone animado e ação opcional
// ─────────────────────────────────────────────────────────────────────────────
class MessageCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  const MessageCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kCardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.6, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFFDDE3FF), iconColor.withValues(alpha: 0.15)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: iconColor),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.navyBlue,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(color: kMutedColor, height: 1.5),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 24),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: GradientButton(
                label: actionLabel!,
                icon: actionIcon,
                onPressed: onAction,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Decoração padrão dos campos de formulário
// ─────────────────────────────────────────────────────────────────────────────
InputDecoration appInputDecoration({
  required String label,
  String? hint,
  IconData? prefixIcon,
  Widget? suffixIcon,
}) {
  OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );

  return InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: const TextStyle(color: kMutedColor),
    hintStyle: const TextStyle(color: Color(0xFFB0B3CC)),
    prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, color: AppColors.navyBlue),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: kPageBackground,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: border(kCardBorder),
    enabledBorder: border(kCardBorder),
    focusedBorder: border(AppColors.navyBlue, 2),
    errorBorder: border(AppColors.red),
    focusedErrorBorder: border(AppColors.red, 2),
  );
}

/// SnackBar flutuante no padrão do app.
void showAppSnackBar(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? AppColors.red : AppColors.navyBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 3),
      ),
    );
}
