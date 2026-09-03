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
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/focux_official_logo.dart';
import '../../../core/widgets/focux_brand_tagline.dart';
import '../../../core/widgets/fx_conversion.dart';
import '../../../core/widgets/cinematic_mesh_background.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_premium_entrance.dart';
import '../../../core/widgets/mesh_scope.dart';
import '../utils/auth_layout.dart';

export '../utils/auth_layout.dart'
    show
        kAuthFormLogoWidth,
        authLogoWidthFor,
        authScrollPadding,
        authUnfocusAndGo,
        authUnfocusAndLeave;
export 'auth_field.dart';
export 'auth_chrome.dart';

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
          child: FxKeyboardPopScope(
            child: SafeArea(child: FxKeyboardDismissScope(child: content)),
          ),
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
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 280),
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
              duration:
                  TokensStrip.prefersReducedMotion(context)
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
