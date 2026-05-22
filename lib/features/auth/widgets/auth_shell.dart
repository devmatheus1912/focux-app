import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/theme_provider.dart';
import 'package:focux_app/core/widgets/fx_input_deco.dart';
import 'package:focux_app/core/widgets/fx_loading.dart';
import '../../../core/widgets/brand_glass_mark.dart';
import '../../../core/widgets/cinematic_mesh_background.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.child,
    this.dark = false,
    this.showCenterGlow = true,
    this.showCornerGlow = true,
  });

  final Widget child;
  final bool dark;
  final bool showCenterGlow;
  final bool showCornerGlow;

  @override
  Widget build(BuildContext context) {
    return CinematicMeshBackground(
      showCenterGlow: showCenterGlow,
      showCornerGlow: showCornerGlow,
      child: SafeArea(child: child),
    );
  }
}

class AuthLogoMark extends ConsumerStatefulWidget {
  const AuthLogoMark({super.key, this.size = 96});

  final double size;

  @override
  ConsumerState<AuthLogoMark> createState() => _AuthLogoMarkState();
}

class _AuthLogoMarkState extends ConsumerState<AuthLogoMark>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _shimmerAnim = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final logoUrl = ref.watch(logoUrlProvider);

    return AnimatedBuilder(
      animation: _shimmerAnim,
      builder: (_, __) {
        return BrandGlassMark(
          size: widget.size,
          logoUrl: logoUrl,
          glowColor: primary,
          shimmerAlpha: _shimmerAnim.value,
        );
      },
    );
  }
}

class AuthWordmark extends StatelessWidget {
  const AuthWordmark({
    super.key,
    this.center = true,
    this.titleSize = 36,
    this.subtitleSize = 13,
    this.taglineSize = 12,
  });

  final bool center;
  final double titleSize;
  final double subtitleSize;
  final double taglineSize;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final align = center ? TextAlign.center : TextAlign.left;
    final crossAxis =
        center ? CrossAxisAlignment.center : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: crossAxis,
      children: [
        Text(
          'FOCUX',
          textAlign: align,
          style: TextStyle(
            color: Colors.white,
            fontSize: titleSize,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.2,
            height: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'PERSONAL',
          textAlign: align,
          style: TextStyle(
            color: primary,
            fontSize: subtitleSize,
            fontWeight: FontWeight.w600,
            letterSpacing: subtitleSize * 0.32,
            height: 1,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Treine com dados. Evolua com inteligência.',
          textAlign: align,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.42),
            fontSize: taglineSize,
            fontStyle: FontStyle.italic,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class AuthRoleToggle extends StatelessWidget {
  const AuthRoleToggle({
    super.key,
    required this.isAluno,
    required this.onPersonalTap,
    required this.onAlunoTap,
  });

  final bool isAluno;
  final VoidCallback onPersonalTap;
  final VoidCallback onAlunoTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    Widget tab({
      required String label,
      required bool selected,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: Semantics(
          label: label,
          button: true,
          selected: selected,
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient:
                    selected
                        ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [primary, BrandPalette.deep(primary)],
                        )
                        : null,
                color: selected ? null : Colors.transparent,
                boxShadow:
                    selected
                        ? [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.28),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                        : null,
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: selected ? 1.0 : 0.48),
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EagleTokens.glassBorder),
      ),
      child: Row(
        children: [
          tab(label: 'Personal', selected: !isAluno, onTap: onPersonalTap),
          tab(label: 'Aluno', selected: isAluno, onTap: onAlunoTap),
        ],
      ),
    );
  }
}

class AuthGlassCard extends StatelessWidget {
  const AuthGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
    this.radius = 22,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: const Color(0x1AFFFFFF),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: EagleTokens.glassBorder),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.label,
    required this.controller,
    required this.hintText,
    this.icon,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.obscureText = false,
    this.onFieldSubmitted,
    this.suffix,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final IconData? icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final bool obscureText;
  final ValueChanged<String>? onFieldSubmitted;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          obscureText: obscureText,
          onFieldSubmitted: onFieldSubmitted,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 15,
            ),
            prefixIcon:
                icon == null
                    ? null
                    : Icon(
                      icon,
                      color: Colors.white.withValues(alpha: 0.5),
                      size: 18,
                    ),
            suffixIcon: suffix,
            filled: true,
            fillColor: EagleTokens.glassFill,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            enabledBorder: FxInputDeco.outlineBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: primary.withValues(alpha: 0.28),
              ),
            ),
            focusedBorder: FxInputDeco.outlineBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: primary, width: 1.5),
            ),
            errorBorder: FxInputDeco.outlineBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFFF8B8B)),
            ),
            focusedErrorBorder: FxInputDeco.outlineBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFFF8B8B)),
            ),
            errorStyle: const TextStyle(
              color: Color(0xFFFFB6B6),
              fontSize: 11.5,
            ),
          ),
        ),
      ],
    );
  }
}

class AuthPrimaryButton extends StatefulWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  State<AuthPrimaryButton> createState() => _AuthPrimaryButtonState();
}

class _AuthPrimaryButtonState extends State<AuthPrimaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 280),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTapDown: widget.isLoading ? null : (_) => _ctrl.forward(),
      onTapUp:
          widget.isLoading
              ? null
              : (_) {
                _ctrl.reverse();
                widget.onPressed?.call();
              },
      onTapCancel: widget.isLoading ? null : () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder:
            (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primary,
                  widget.isLoading
                      ? primary.withValues(alpha: 0.45)
                      : BrandPalette.deep(primary),
                ],
              ),
              boxShadow: [
                if (!widget.isLoading)
                  BoxShadow(
                    color: primary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Center(
              child:
                  widget.isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: FxLoading(strokeWidth: 2, color: Colors.white),
                      )
                      : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(widget.icon, size: 16, color: Colors.white),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            widget.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthSecondaryButton extends StatelessWidget {
  const AuthSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: EagleTokens.glassBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: EagleTokens.glassFill,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 17, color: Colors.white),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthBackButton extends StatelessWidget {
  const AuthBackButton({
    super.key,
    required this.onTap,
    this.showLabel = false,
  });

  final VoidCallback onTap;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: EagleTokens.glassFill,
          shape: BoxShape.circle,
          border: Border.all(color: EagleTokens.glassBorder),
        ),
        child: const Icon(
          Icons.chevron_left_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
    );

    if (!showLabel) {
      return button;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        button,
        const SizedBox(width: 10),
        Text(
          'Voltar',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class AuthPlanCard extends StatelessWidget {
  const AuthPlanCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String price;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient:
              selected
                  ? LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      BrandPalette.deep(Theme.of(context).colorScheme.primary),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                  : null,
          color: selected ? null : EagleTokens.glassFill,
          border:
              selected
                  ? null
                  : Border.all(color: EagleTokens.glassBorder),
          boxShadow:
              selected
                  ? [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ]
                  : null,
        ),
        child: Column(
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.48,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 10,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              price,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

