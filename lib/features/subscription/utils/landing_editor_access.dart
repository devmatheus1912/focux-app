import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../planos/data/plano_recurso.dart';
import '../../planos/utils/plan_gate.dart';

/// Abre o editor de landing ou paywall de upgrade (recurso `landing`).
Future<void> openLandingEditorOrUpgrade(
  BuildContext context,
  WidgetRef ref,
) async {
  // Tap explícito no Perfil — sempre mostra (sem cooldown silencioso).
  final ok = await PlanGate.guard(
    context,
    ref,
    PlanoRecursoKeys.landing,
    featureName: 'Landing page completa',
    source: 'perfil_personalizar',
  );
  if (ok && context.mounted) context.push('/perfil/landing-editor');
}
