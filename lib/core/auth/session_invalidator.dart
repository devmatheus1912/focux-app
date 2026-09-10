import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/agenda/utils/agenda_week_client_cache.dart';
import '../../features/alunos/data/aluno_copilot_ia_cache_store.dart';
import '../../features/alunos/data/aluno_followup_store.dart';
import '../../features/alunos/utils/aluno360_client_cache.dart';
import '../../features/alunos/utils/alunos_home_client_cache.dart';
import '../../features/checkin/data/meus_treinos_mem_cache.dart';
import '../../features/dashboard/utils/dashboard_home_client_cache.dart';
import '../../features/evolucao/utils/evolucao_home_client_cache.dart';
import '../../features/exercicios/data/biblioteca_wizard_draft.dart';
import '../../features/growth/data/migracao_magica_draft_cache.dart';
import '../../features/onboarding/data/onboarding_wizard_client_cache.dart';
import '../../features/planos/data/plano_features_bff_cache.dart';
import '../api/offline_sync_service.dart';
import '../cache/offline_cache.dart';
import '../storage/secure_storage.dart';

class SessionInvalidator {
  static final ValueNotifier<int> _notifier = ValueNotifier<int>(0);

  static Listenable get listenable => _notifier;

  static const _entitlementKeys = [
    'focux_plano_features_cache_v2',
  ];

  static Future<void> invalidate({String? reason}) async {
    clearTenantMemoryCaches();
    await Future.wait([
      AlunoCopilotIaCacheStore.clearAll(),
      SecureStorage.clearAll(),
      OfflineCache.clearAll(),
      LocalCache.clearAll(),
      OfflineSyncService.clearQueue(),
      _clearEntitlementCaches(),
      MigracaoMagicaDraftCache.clear(),
      AlunoFollowUpStore.clearAll(),
    ]);
    _notifier.value++;
    if (kDebugMode && reason != null && reason.isNotEmpty) {
      debugPrint('[SessionInvalidator] $reason');
    }
  }

  /// Snapshots estáticos por tenant. `ref.invalidate` não os esvazia.
  static void clearTenantMemoryCaches() {
    MeusTreinosMemCache.clear();
    AlunosHomeClientCache.clear();
    Aluno360ClientCache.clear();
    DashboardHomeClientCache.clear();
    PlanoFeaturesBffCache.clear();
    EvolucaoHomeClientCache.clear();
    AgendaWeekClientCache.clear();
    OnboardingWizardClientCache.clear();
    BibliotecaWizardDraftCache.clear();
  }

  static Future<void> _clearEntitlementCaches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in _entitlementKeys) {
        await prefs.remove(key);
      }
    } catch (_) {}
  }
}
