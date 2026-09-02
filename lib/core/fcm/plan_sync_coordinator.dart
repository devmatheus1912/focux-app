import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/assinatura/providers/assinatura_provider.dart';
import '../../features/perfil/providers/perfil_provider.dart';
import '../../features/planos/data/plano_features_bff_cache.dart';
import '../../features/planos/providers/plano_features_provider.dart';
import 'fcm_service.dart';

/// Invalida entitlements e vitrine quando o backend envia `plan_sync` via FCM.
class PlanSyncCoordinator {
  PlanSyncCoordinator._();

  static ProviderContainer? _container;

  static void bind(ProviderContainer container) {
    _container = container;
    FcmService.onPlanSync = _handlePlanSync;
  }

  static void unbind() {
    if (FcmService.onPlanSync == _handlePlanSync) {
      FcmService.onPlanSync = null;
    }
    _container = null;
  }

  static Future<void> _handlePlanSync(Map<String, dynamic> data) async {
    final container = _container;
    if (container == null) return;

    final event = data['event'] as String? ?? 'tier_updated';
    if (kDebugMode) {
      debugPrint('[PlanSync] FCM event=$event plano=${data['plano']}');
    }

    PlanoFeaturesBffCache.clear();
    await container.read(planosRepositoryProvider).clearPlanoFeaturesCache();
    await container.read(assinaturaRepositoryProvider).clearVitrineCache();
    container.invalidate(paywallHomeProvider);
    container.invalidate(perfilProvider);
    await container
        .read(planoFeaturesProvider.notifier)
        .refresh(reconcileFirst: event == 'tier_revoked');
  }
}
