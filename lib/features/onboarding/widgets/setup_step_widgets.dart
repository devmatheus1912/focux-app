import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';

/// Normaliza rotas do wizard para deep-links consistentes no app.
String normalizeSetupActionRoute(String route) {
  switch (route) {
    case '/treinos':
      return '/treinos/novo';
    case '/financeiro':
      return '/perfil/wallet';
    case '/perfil':
      return '/perfil/editar';
    default:
      return route;
  }
}

String setupStepFxIconName(String name) {
  switch (name) {
    case 'person':
      return 'target';
    case 'person_add':
      return 'users';
    case 'fitness_center':
      return 'dumbbell';
    case 'inventory_2':
      return 'article';
    case 'repeat':
      return 'route';
    case 'attach_money':
      return 'pix';
    case 'link':
      return 'spark';
    default:
      return 'circle-check';
  }
}

class SetupWizardSkeleton extends StatelessWidget {
  const SetupWizardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? EagleTokens.darkCard : TokensStrip.borderDefault;
    final highlight = isDark ? EagleTokens.darkCardHi : TokensStrip.pageBg;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TokensStrip.s4,
              TokensStrip.s2,
              TokensStrip.s3,
              TokensStrip.s2,
            ),
            child: Container(
              height: FxSettingsLayout.rowMinHeight,
              decoration: BoxDecoration(
                color: highlight,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            height: 3,
            color: highlight,
          ),
        ],
      ),
    );
  }
}
