import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/planos_repository.dart';
import '../providers/plano_features_provider.dart';

  /// Features efetivas para gates de UI — perfil canônico do tier + fallback conservador.
  PlanoFeatures effectivePlanoFeatures(WidgetRef ref) {
    final async = ref.watch(planoFeaturesProvider);
    final fresh = async.valueOrNull?.normalizeForTier();
    if (fresh != null) return fresh;
    return PlanoFeatures.free;
  }
