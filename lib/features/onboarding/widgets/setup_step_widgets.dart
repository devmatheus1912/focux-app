import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';

/// Normaliza rotas do wizard para deep-links consistentes no app.
String normalizeSetupActionRoute(String route) {
  final uri = Uri.parse(route);
  final path = switch (uri.path) {
    '/treinos' => '/treinos/novo',
    '/financeiro' => '/perfil/wallet',
    '/perfil' => '/perfil/editar',
    _ => uri.path.isEmpty ? route : uri.path,
  };
  if (uri.hasQuery) {
    return Uri(path: path, queryParameters: uri.queryParameters).toString();
  }
  return path;
}

/// Marca navegação vinda da ativação (FeatureGate oferece "Pular por agora").
String setupActionRouteFromAtivacao(String route) {
  final normalized = normalizeSetupActionRoute(route);
  final uri = Uri.parse(normalized);
  final params = Map<String, String>.from(uri.queryParameters);
  params['from'] = 'ativacao';
  return uri.replace(queryParameters: params).toString();
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
