import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/services.dart';

import '../../../core/brand/focux_brand_copy.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/hero_teal.dart';
import '../../../core/theme/theme_provider.dart';
import 'package:focux_app/core/widgets/fx_input_deco.dart';
import 'package:focux_app/core/widgets/fx_loading.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/focux_official_logo.dart';
import '../../../core/widgets/focux_brand_tagline.dart';
import '../../../core/widgets/cinematic_mesh_background.dart';
import '../utils/auth_layout.dart';

export '../utils/auth_layout.dart'
    show kAuthFormLogoWidth, authLogoWidthFor, authScrollPadding;

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.child,
    this.dark = false,
    this.showCenterGlow = false,
    this.showCornerGlow = false,
    this.forceDark = true,
    this.flatBackground = true,
    this.showGrid = true,
    this.animateGridIn = true,
  });

  final Widget child;
  final bool dark;
  final bool showCenterGlow;
  final bool showCornerGlow;
  final bool flatBackground;
  final bool showGrid;
  final bool animateGridIn;

  /// Auth/splash UI is authored for the dark cinematic mesh (white type).
  final bool forceDark;

  @override
  Widget build(BuildContext context) {
    return CinematicMeshBackground(
      forceDark: forceDark,
      showCenterGlow: showCenterGlow,
      showCornerGlow: showCornerGlow,
      flatBackground: flatBackground,
      showGrid: showGrid,
      animateGridIn: animateGridIn,
      child: SafeArea(child: child),
    );
  }
}

class AuthLogoMark extends ConsumerWidget {
  const AuthLogoMark({
    super.key,
    this.width = kAuthFormLogoWidth,
    this.forceOfficial = false,
  });

  final double width;

  /// Telas públicas de auth devem usar `true` para ignorar logo de sessão.
  final bool forceOfficial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logoUrl = forceOfficial ? null : ref.watch(logoUrlProvider);

    return Semantics(
      label: 'Focux Personal',
      image: true,
      child: FocuxOfficialLogo.full(width: width, logoUrl: logoUrl),
    );
  }
}

/// Cabeçalho compacto para cadastro — ícone + FOCUX / papel (sem lockup duplicado).
/// Cabeçalho de marca nas telas auth — mesmo lockup oficial do splash/onboarding.
class AuthRoleHeader extends StatelessWidget {
  const AuthRoleHeader({
    super.key,
    required this.roleLabel,
    this.center = false,
    this.width = kAuthFormLogoWidth,
  });

  final String roleLabel;
  final bool center;
  final double width;

  @override
  Widget build(BuildContext context) {
    final logo = Semantics(
      label: 'Focux $roleLabel',
      image: true,
      child: FocuxOfficialLogo.full(width: width),
    );
    return center ? Center(child: logo) : logo;
  }
}

/// Cabeçalho do login — mesmo lockup oficial Focux para Personal e Aluno,
/// apenas trocando o rótulo do papel. Nenhuma variante é apenas ícone.
/// Nunca usa logoUrl de sessão anterior (evita foto de perfil no login).
class AuthLoginBrandHeader extends ConsumerWidget {
  const AuthLoginBrandHeader({
    super.key,
    required this.isAluno,
    this.taglineSize = 13.5,
  });

  final bool isAluno;
  final double taglineSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logoWidth = authLogoWidthFor(context, withTagline: true);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child:
          isAluno
              ? Column(
                key: const ValueKey('login-aluno'),
                children: [
                  AuthRoleHeader(
                    roleLabel: 'ALUNO',
                    center: true,
                    width: logoWidth,
                  ),
                  const SizedBox(height: 10),
                  AuthWordmark(taglineSize: taglineSize),
                ],
              )
              : Column(
                key: const ValueKey('login-personal'),
                children: [
                  AuthRoleHeader(
                    roleLabel: 'PERSONAL',
                    center: true,
                    width: logoWidth,
                  ),
                  const SizedBox(height: 10),
                  AuthWordmark(taglineSize: taglineSize),
                ],
              ),
    );
  }
}

/// Entrada suave do formulário auth (respeita reduce-motion).
class AuthFormEntrance extends StatelessWidget {
  const AuthFormEntrance({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (TokensStrip.prefersReducedMotion(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - t)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class AuthWordmark extends ConsumerWidget {
  const AuthWordmark({
    super.key,
    this.center = true,
    this.taglineSize = 14,
    this.showTagline = true,
  });

  final bool center;
  final double taglineSize;
  final bool showTagline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hideFocux = ref.watch(hideFocuxBrandingProvider);
    final appName = ref.watch(appDisplayNameProvider);
    final personalName = ref.watch(personalNameProvider);
    final align = center ? TextAlign.center : TextAlign.left;
    final crossAxis =
        center ? CrossAxisAlignment.center : CrossAxisAlignment.start;

    if (hideFocux) {
      final displayName =
          (appName != null && appName.trim().isNotEmpty)
              ? appName.trim()
              : (personalName != null && personalName.trim().isNotEmpty)
              ? personalName.trim()
              : 'Meu Personal';
      return Column(
        crossAxisAlignment: crossAxis,
        children: [
          Text(
            displayName,
            textAlign: align,
            style: AppTypography.inter(
              color: Colors.white,
              fontSize: taglineSize * 1.65,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              height: 1.15,
            ),
          ),
          if (showTagline) ...[
            const SizedBox(height: 10),
            FocuxBrandTagline(center: center, fontSize: taglineSize),
          ],
        ],
      );
    }

    if (!showTagline) return const SizedBox.shrink();

    return FocuxBrandTagline(center: center, fontSize: taglineSize);
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
                        ? TokensStrip.coloredDepthGlow(
                          primary,
                          strength: 0.18,
                        )
                        : null,
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: selected ? 1.0 : 0.82),
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
          tab(
            label: FocuxBrandCopy.onboardingPersonaPersonal,
            selected: !isAluno,
            onTap: onPersonalTap,
          ),
          tab(
            label: FocuxBrandCopy.onboardingPersonaAluno,
            selected: isAluno,
            onTap: onAlunoTap,
          ),
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
    this.radius = 20,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    // Paridade Home: strip soft (glow ~0.12), sem neon.
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: TokensStrip.glassFill(dark: true, opacity: 0.90),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: primary.withValues(alpha: 0.14)),
            boxShadow: [
              ...TokensStrip.elevation(8, dark: true, accent: primary),
              ...TokensStrip.coloredDepthGlow(primary, strength: 0.12),
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
    this.focusNode,
    this.inputFormatters,
    this.autofillHints,
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
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.inter(
            color: heroTealSurface(0.86),
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          autofillHints: autofillHints,
          validator: validator,
          obscureText: obscureText,
          onFieldSubmitted: onFieldSubmitted,
          style: AppTypography.inter(color: heroTealInk(), fontSize: 15),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTypography.inter(
              color: heroTealSurface(0.72),
              fontSize: 15,
            ),
            prefixIcon:
                icon == null
                    ? null
                    : Icon(
                      icon,
                      color: heroTealSurface(0.78),
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
              borderSide: BorderSide(color: primary.withValues(alpha: 0.18)),
            ),
            focusedBorder: FxInputDeco.outlineBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: primary, width: 1.35),
            ),
            errorBorder: FxInputDeco.outlineBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: EagleTokens.authErrorBorder),
            ),
            focusedErrorBorder: FxInputDeco.outlineBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: EagleTokens.authErrorBorder),
            ),
            errorStyle: const TextStyle(
              color: EagleTokens.authErrorSoft,
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
              boxShadow:
                  widget.isLoading
                      ? null
                      : TokensStrip.coloredDepthGlow(primary, strength: 0.18),
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
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.45),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TokensStrip.rButton),
          ),
          backgroundColor: TokensStrip.glassFill(dark: true, opacity: 0.55),
          foregroundColor: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 17,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
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
    final primary = Theme.of(context).colorScheme.primary;
    // Soft chrome = mesmo espírito do ShellHeaderIconButton da Home.
    final icon = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 38,
          height: 38,
          decoration: TokensStrip.glassPanel(
            dark: true,
            radius: 19,
            accent: primary,
            elevationLevel: 4,
          ),
          child: Center(
            child: Icon(
              Icons.chevron_left_rounded,
              color: Colors.white.withValues(alpha: 0.92),
              size: 22,
            ),
          ),
        ),
      ),
    );

    final button = Semantics(
      button: true,
      label: 'Voltar',
      child: icon,
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
            color: Colors.white.withValues(alpha: 0.78),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Link de rich text acessível para rodapés de auth (ex.: "Não tem conta? Criar conta").
/// Expõe Semantics(link, button) em vez de depender apenas do gesto visual.
class AuthTextLink extends StatelessWidget {
  const AuthTextLink({
    super.key,
    required this.text,
    required this.actionText,
    required this.onTap,
    this.textColor,
    this.actionColor,
    this.fontSize = 14,
  });

  final String text;
  final String actionText;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? actionColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final primary = actionColor ?? Theme.of(context).colorScheme.primary;
    return Semantics(
      link: true,
      button: true,
      label: '$text$actionText',
      child: GestureDetector(
        onTap: onTap,
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: AppTypography.inter(
              color: textColor ?? heroTealSurface(0.82),
              fontSize: fontSize,
            ),
            children: [
              TextSpan(text: text),
              TextSpan(
                text: actionText,
                style: TextStyle(color: primary, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
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
          border: selected ? null : Border.all(color: EagleTokens.glassBorder),
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
