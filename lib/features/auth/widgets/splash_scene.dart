import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/hero_teal.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/focux_official_logo.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../utils/splash_navigation.dart';

/// Splash: o logo parado e mais nada. Sem animação de entrada, sem barra de
/// progresso e sem "Carregando": ela só segura a tela até o destino resolver.
/// Se demorar, aparece uma barra fina; se travar, uma mensagem e uma ação.
class SplashScene extends StatelessWidget {
  const SplashScene({
    super.key,
    required this.estado,
    required this.fadeOut,
    this.onTentarNovamente,
  });

  final SplashEstado estado;
  final Animation<double> fadeOut;
  final VoidCallback? onTentarNovamente;

  static const double larguraLogo = 168;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final reduceMotion = TokensStrip.prefersReducedMotion(context);
    return AnimatedBuilder(
      animation: fadeOut,
      builder:
          (context, child) =>
              Opacity(opacity: fadeOut.value.clamp(0.0, 1.0), child: child),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Semantics(
              label: 'Focux',
              image: true,
              child: FocuxOfficialLogo.full(width: larguraLogo),
            ),
          ),
          Positioned(
            left: TokensStrip.s5,
            right: TokensStrip.s5,
            bottom: TokensStrip.s6 * 2,
            child: Semantics(
              liveRegion: true,
              child: AnimatedSwitcher(
                duration:
                    reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 200),
                child: switch (estado) {
                  SplashEstado.resolvendo => const SizedBox(
                    key: ValueKey('splash-resolvendo'),
                    height: 64,
                  ),
                  SplashEstado.demorando => _BarraFina(
                    key: const ValueKey('splash-demorando'),
                    primary: primary,
                    estatica: reduceMotion,
                  ),
                  SplashEstado.travada => _Travada(
                    key: const ValueKey('splash-travada'),
                    onTentarNovamente: onTentarNovamente,
                  ),
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarraFina extends StatelessWidget {
  const _BarraFina({super.key, required this.primary, required this.estatica});

  final Color primary;
  final bool estatica;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 160),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: estatica ? 0.5 : null,
              minHeight: 3,
              color: primary,
              backgroundColor: heroTealSurface(0.10),
            ),
          ),
        ),
      ),
    );
  }
}

class _Travada extends StatelessWidget {
  const _Travada({super.key, required this.onTentarNovamente});

  final VoidCallback? onTentarNovamente;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Está demorando mais que o normal…',
          textAlign: TextAlign.center,
          style: FocuxHubTypography.bodyMuted(color: heroTealSurface(0.82)),
        ),
        const SizedBox(height: TokensStrip.s3),
        FxTonalButton(
          label: 'Tentar de novo',
          icon: Icons.refresh_rounded,
          onPressed: onTentarNovamente,
        ),
      ],
    );
  }
}
