import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/services.dart';

import '../../../core/brand/focux_brand_copy.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/focux_typography.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/focux_system_chrome.dart';
import '../../../core/theme/hero_teal.dart';
import '../../../core/theme/theme_provider.dart';
import 'package:focux_app/core/widgets/fx_input_deco.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/focux_official_logo.dart';
import '../../../core/widgets/focux_brand_tagline.dart';
import '../../../core/widgets/fx_conversion.dart';
import '../../../core/widgets/cinematic_mesh_background.dart';
import '../../../core/widgets/fx_premium_entrance.dart';
import '../../../core/widgets/mesh_scope.dart';
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
    final primary = Theme.of(context).colorScheme.primary;
    // Mesh é sempre escuro; o tema do app (light no celular) não pode
    // pintar card branco com tinta branca por cima.
    final content =
        forceDark
            ? Theme(data: AppTheme.buildDarkTheme(primary), child: child)
            : child;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: FocuxSystemChrome.dark,
      child: CinematicMeshBackground(
        forceDark: forceDark,
        showCenterGlow: showCenterGlow,
        showCornerGlow: showCornerGlow,
        flatBackground: flatBackground,
        showGrid: showGrid,
        animateGridIn: animateGridIn,
        child: MeshScope(
          active: true,
          child: SafeArea(child: content),
        ),
      ),
    );
  }
}

/// Título de página auth — mesmo papel do `pageTitle` da Home (ink hero).
TextStyle authPageTitleStyle(BuildContext context, {Color? color}) =>
    FocuxHubTypography.pageTitle(context, color: color ?? heroTealInk());

/// Subtítulo/apoio abaixo do título — `bodyMuted` da Home sobre mesh.
TextStyle authSubtitleStyle({Color? color}) =>
    FocuxHubTypography.bodyMuted(color: color ?? heroTealSurface(0.78));

/// Erro inline padrão das telas auth (mesma cor semântica em todas).
TextStyle authInlineErrorStyle() =>
    FocuxHubTypography.bodyMuted(color: EagleTokens.authErrorSoft);

/// Sucesso inline padrão das telas auth.
TextStyle authInlineSuccessStyle() =>
    FocuxHubTypography.bodyMuted(color: EagleTokens.authSuccessSoft);

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

/// Cabeçalho do login — lockup S6 oficial. Nunca usa logoUrl de sessão.
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
    final reduceMotion = TokensStrip.prefersReducedMotion(context);
    return AnimatedSwitcher(
      duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: FxConversionLockup(
        key: ValueKey(isAluno ? 'login-aluno' : 'login-personal'),
        width: logoWidth,
        semanticLabel: isAluno ? 'Focux ALUNO' : 'Focux PERSONAL',
        tagline: AuthWordmark(taglineSize: taglineSize),
        aluno: isAluno,
      ),
    );
  }
}

/// Entrada do formulário auth — mesma linguagem da Home ([FxPremiumEntrance]).
class AuthFormEntrance extends StatelessWidget {
  const AuthFormEntrance({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FxPremiumEntrance(child: child);
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
            style: FocuxTypography.display(color: Colors.white).copyWith(
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
              duration: TokensStrip.prefersReducedMotion(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(vertical: TokensStrip.s3),
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
                        ? TokensStrip.coloredDepthGlow(primary, strength: 0.18)
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
    this.padding = const EdgeInsets.symmetric(
      horizontal: TokensStrip.s5,
      vertical: TokensStrip.s5 + 2,
    ),
    this.radius = TokensStrip.rCard,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    // Vidro escuro do mesh — nunca o strip branco da Home (tinta auth é clara).
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: DecoratedBox(
          decoration: TokensStrip.glassPanel(
            dark: true,
            radius: radius,
            accent: primary,
            elevationLevel: 10,
          ),
          child: Padding(padding: padding, child: child),
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
          style: FocuxHubTypography.chip(heroTealSurface(0.86)).copyWith(
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
          style: FocuxHubTypography.body(color: heroTealInk()),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: FocuxHubTypography.body(color: heroTealSurface(0.72)),
            prefixIcon:
                icon == null
                    ? null
                    : Icon(icon, color: heroTealSurface(0.78), size: 18),
            suffixIcon: suffix,
            filled: true,
            fillColor: TokensStrip.glassFill(dark: true, opacity: 0.55),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: TokensStrip.s4,
              vertical: TokensStrip.s3,
            ),
            enabledBorder: FxInputDeco.outlineBorder(
              borderRadius: BorderRadius.circular(TokensStrip.rInput),
              borderSide: BorderSide(color: primary.withValues(alpha: 0.18)),
            ),
            focusedBorder: FxInputDeco.outlineBorder(
              borderRadius: BorderRadius.circular(TokensStrip.rInput),
              borderSide: BorderSide(color: primary, width: 1.35),
            ),
            errorBorder: FxInputDeco.outlineBorder(
              borderRadius: BorderRadius.circular(TokensStrip.rInput),
              borderSide: BorderSide(color: EagleTokens.authErrorBorder),
            ),
            focusedErrorBorder: FxInputDeco.outlineBorder(
              borderRadius: BorderRadius.circular(TokensStrip.rInput),
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

    final button = Semantics(button: true, label: 'Voltar', child: icon);

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

/// Barra fixa de marca no cadastro / esqueci — back + papel sempre no viewport.
class AuthStickyRoleBar extends StatelessWidget {
  const AuthStickyRoleBar({
    super.key,
    required this.roleLabel,
    required this.onBack,
  });

  final String roleLabel;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Semantics(
      label: 'Focux $roleLabel',
      child: Padding(
        padding: const EdgeInsets.only(bottom: TokensStrip.s2),
        child: Row(
          children: [
            AuthBackButton(onTap: onBack),
            Expanded(
              child: Text(
                '— ${roleLabel.toUpperCase()} —',
                textAlign: TextAlign.center,
                style: FocuxHubTypography.chip(
                  primary.withValues(alpha: 0.92),
                ).copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.4,
                ),
              ),
            ),
            const SizedBox(width: 38),
          ],
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
