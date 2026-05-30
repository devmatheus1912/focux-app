import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/planos_repository.dart';
import '../providers/plano_features_provider.dart';

/// Features efetivas para gates de UI — aplica teto por tier e fallback conservador.
PlanoFeatures effectivePlanoFeatures(WidgetRef ref) {
  final async = ref.watch(planoFeaturesProvider);
  final fresh = async.valueOrNull?.withTierCeiling();
  if (fresh != null) return fresh;
  // Sem snapshot: conservador (não liberar Pro por optimistic fallback).
  return PlanoFeatures.free;
}
