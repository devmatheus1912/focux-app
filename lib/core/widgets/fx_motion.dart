import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/physics.dart';

import '../theme/tokens_strip.dart';
import 'fx_loading.dart';

/// 3D interactive neon glow — TOKENS STRIP premium CTA halo.
class FxInteractiveGlow extends StatefulWidget {
  const FxInteractiveGlow({
    super.key,
    required this.child,
    required this.color,
    this.enabled = true,
    this.intensity = 1,
    this.borderRadius = TokensStrip.rMd,
    this.pulse = true,
  });

  final Widget child;
  final Color color;
  final bool enabled;
  final double intensity;
  final double borderRadius;
  final bool pulse;

  @override
  State<FxInteractiveGlow> createState() => _FxInteractiveGlowState();
}

class _FxInteractiveGlowState extends State<FxInteractiveGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _pulse = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    if (widget.enabled && widget.pulse) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant FxInteractiveGlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final reduceMotion = TokensStrip.prefersReducedMotion(context);
    if (widget.enabled && widget.pulse && !reduceMotion && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.enabled || !widget.pulse || reduceMotion) {
      _ctrl.stop();
      _ctrl.value = 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || TokensStrip.prefersReducedMotion(context)) {
      return widget.child;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final pulse = widget.pulse ? _pulse.value : 0.0;
        final shadows = TokensStrip.interactiveGlow(
          widget.color,
          intensity: widget.intensity * (0.85 + pulse * 0.15),
          dark: isDark,
        );
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: shadows,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Back-compat alias for premium glow wrappers.
typedef FxGlowSurface = FxInteractiveGlow;

/// Liquid Glass primary button with gradient + glow.
class FxLiquidPrimaryButton extends StatelessWidget {
  const FxLiquidPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.loadingLabel,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  /// Shown beside the spinner while [loading] is true (e.g. "Agendando…").
  final String? loadingLabel;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    // Saturated brand teals use light onPrimary in theme; labels stay white
    // (same rule as FilledButtonTheme in app_theme.dart).
    const labelColor = Colors.white;
    final enabled = onPressed != null && !loading;

    final button = FxInteractiveGlow(
      color: primary,
      enabled: enabled,
      borderRadius: TokensStrip.rButton,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(TokensStrip.rButton),
          child: Ink(
            decoration: BoxDecoration(
              gradient: TokensStrip.primaryButtonGradient(primary),
              borderRadius: BorderRadius.circular(TokensStrip.rButton),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.22),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: TokensStrip.s5,
              vertical: TokensStrip.s4,
            ),
            child: Center(
              child:
                  loading
                      ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: FxLoading(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          if (loadingLabel != null) ...[
                            const SizedBox(width: 10),
                            Text(
                              loadingLabel!,
                              style: const TextStyle(
                                color: labelColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ],
                      )
                      : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, size: 18, color: labelColor),
                            const SizedBox(width: TokensStrip.s2),
                          ],
                          Flexible(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: labelColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
            ),
          ),
        ),
      ),
    );

    if (!expand) return button;
    return SizedBox(
      width: double.infinity,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48, maxHeight: 52),
        child: button,
      ),
    );
  }
}

/// Outline secondary CTA — login / conta existente.
class FxLiquidSecondaryButton extends StatelessWidget {
  const FxLiquidSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final enabled = onPressed != null;

    void handleTap() {
      if (!enabled) return;
      HapticFeedback.lightImpact();
      onPressed!();
    }

    final button = Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? handleTap : null,
          borderRadius: BorderRadius.circular(TokensStrip.rButton),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(TokensStrip.rButton),
              color: Colors.white.withValues(alpha: enabled ? 0.05 : 0.03),
              border: Border.all(
                color: primary.withValues(alpha: enabled ? 0.55 : 0.28),
                width: 1.4,
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: TokensStrip.s5,
              vertical: TokensStrip.s4,
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: primary),
                    const SizedBox(width: TokensStrip.s2),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:
                            enabled ? primary : primary.withValues(alpha: 0.45),
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (!expand) return button;
    return SizedBox(
      width: double.infinity,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48, maxHeight: 52),
        child: button,
      ),
    );
  }
}

/// Tactile spring button
/// Uses real spring physics for premium, weighty feel instead of linear curves.
/// Use this wrapper around any CTA, card, or interactive element for
/// premium tactile feedback without managing AnimationControllers manually.
///
/// ```dart
/// FxSpringButton(
///   onTap: () => doSomething(),
///   child: Container(/* your button visuals */),
/// )
/// ```
class FxSpringButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressScale;

  const FxSpringButton({
    super.key,
    required this.child,
    this.onTap,
    this.pressScale = 0.96,
  });

  @override
  State<FxSpringButton> createState() => _FxSpringButtonState();
}

class _FxSpringButtonState extends State<FxSpringButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  // Spring config: stiffness 260 + damping 18 = snappy with subtle overshoot
  static const _spring = SpringDescription(
    mass: 1,
    stiffness: 260,
    damping: 18,
  );

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController.unbounded(vsync: this);
    _scale = _ctrl.drive(Tween<double>(begin: 1.0, end: widget.pressScale));
  }

  void _press() {
    _ctrl.animateWith(SpringSimulation(_spring, _ctrl.value, 1.0, 0));
  }

  void _release() {
    _ctrl.animateWith(SpringSimulation(_spring, _ctrl.value, 0.0, 0));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => _press() : null,
      onTapUp:
          widget.onTap != null
              ? (_) {
                _release();
                widget.onTap!();
              }
              : null,
      onTapCancel: widget.onTap != null ? () => _release() : null,
      child: AnimatedBuilder(
        animation: _scale,
        builder:
            (_, child) => Transform.scale(
              scale: 1.0 - (_scale.value * (1.0 - widget.pressScale)),
              child: child,
            ),
        child: widget.child,
      ),
    );
  }
}

/// Staggered fade-slide animation for list items.
/// Wraps any child in a slide-up + fade-in animation with configurable delay.
/// Uses a deceleration curve for premium feel — items glide in and settle.
///
/// ```dart
/// ListView.builder(
///   itemBuilder: (ctx, i) => FxStaggerItem(
///     index: i,
///     child: YourListTile(...),
///   ),
/// )
/// ```
class FxStaggerItem extends StatefulWidget {
  final int index;
  final Widget child;
  final Duration staggerDelay;
  final Duration duration;
  final double slideOffset;

  const FxStaggerItem({
    super.key,
    required this.index,
    required this.child,
    this.staggerDelay = const Duration(milliseconds: 60),
    this.duration = const Duration(milliseconds: 400),
    this.slideOffset = 20,
  });

  @override
  State<FxStaggerItem> createState() => _FxStaggerItemState();
}

class _FxStaggerItemState extends State<FxStaggerItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: Offset(0, widget.slideOffset),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    final delay = widget.staggerDelay * widget.index;
    Future.delayed(delay, () {
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
    return AnimatedBuilder(
      animation: _ctrl,
      builder:
          (_, child) => Opacity(
            opacity: _fade.value,
            child: Transform.translate(offset: _slide.value, child: child),
          ),
      child: widget.child,
    );
  }
}
