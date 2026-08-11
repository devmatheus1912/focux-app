import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/alunos/data/aluno_copilot_ia_cache_store.dart';
import '../../features/checkin/data/meus_treinos_mem_cache.dart';
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
    MeusTreinosMemCache.clear();
    await AlunoCopilotIaCacheStore.clearAll();
    await Future.wait([
      SecureStorage.clearAll(),
      OfflineCache.clearAll(),
      LocalCache.clearAll(),
      OfflineSyncService.clearQueue(),
      _clearEntitlementCaches(),
    ]);
    _notifier.value++;
    if (kDebugMode && reason != null && reason.isNotEmpty) {
      debugPrint('[SessionInvalidator] $reason');
    }
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
