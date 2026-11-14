import 'package:flutter/widgets.dart';

import '../../features/subscription/models/subscription_plan.dart';
import '../widgets/feature_gate.dart';

/// Gates de recurso pago montados na rota, nunca dentro da tela: bloqueada,
/// a tela nem é construída (sem chamada à API por trás do aviso).
/// O nome mostrado vem de `PlanoRecursoTextos`; `featureName` é só reserva.
abstract final class AppRouterGates {
  static Widget habitos(Widget child) => FeatureGate(
    featureName: 'Hábitos',
    requiredPlan: SubscriptionPlan.PRO,
    capability: 'habitCoaching',
    child: child,
  );

  /// Desafios usam a chave legada `comunidadeGrupos` (traduzida para
  /// `desafios` em `PlanoRecursoKeys`).
  static Widget desafios(Widget child) => FeatureGate(
    featureName: 'Desafios',
    requiredPlan: SubscriptionPlan.ENTERPRISE,
    capability: 'comunidadeGrupos',
    child: child,
  );
}
