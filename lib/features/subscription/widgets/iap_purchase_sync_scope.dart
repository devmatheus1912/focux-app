import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/fcm/plan_sync_coordinator.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/iap_purchase_coordinator.dart';
import '../services/iap_purchase_event.dart';
import '../utils/iap_session_gate.dart';

typedef IapPlanRefresh = Future<void> Function(ProviderContainer container);

/// Liga o listener global de compras à sessão do personal e reflete o plano
/// uma vez por lote com compra validada (renovação é silenciosa: sem toast).
class IapPurchaseSyncScope extends ConsumerStatefulWidget {
  const IapPurchaseSyncScope({
    super.key,
    required this.child,
    this.refreshPlan = PlanSyncCoordinator.refreshPlan,
  });

  final Widget child;
  final IapPlanRefresh refreshPlan;

  @override
  ConsumerState<IapPurchaseSyncScope> createState() =>
      _IapPurchaseSyncScopeState();
}

class _IapPurchaseSyncScopeState extends ConsumerState<IapPurchaseSyncScope> {
  StreamSubscription<IapPurchaseEvent>? _events;
  bool _verifiedInBatch = false;

  @override
  void initState() {
    super.initState();
    final coordinator = ref.read(iapPurchaseCoordinatorProvider);
    _events = coordinator.events.listen(_onEvent);
    ref.listenManual(
      authProvider,
      (_, status) => _syncSession(status),
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _events?.cancel();
    super.dispose();
  }

  void _syncSession(AuthStatus status) {
    final coordinator = ref.read(iapPurchaseCoordinatorProvider);
    final role = ref.read(authProvider.notifier).currentRole;
    if (iapShouldListenForPurchases(status: status, role: role)) {
      unawaited(coordinator.start());
    } else {
      _verifiedInBatch = false;
      unawaited(coordinator.stop());
    }
  }

  void _onEvent(IapPurchaseEvent event) {
    switch (event) {
      case IapPurchaseVerified():
        _verifiedInBatch = true;
      case IapPurchaseBatchProcessed() when _verifiedInBatch:
        _verifiedInBatch = false;
        if (mounted) unawaited(_refreshPlan());
      default:
        break;
    }
  }

  Future<void> _refreshPlan() async {
    try {
      await widget.refreshPlan(ProviderScope.containerOf(context));
    } catch (error) {
      debugPrint('[IAP] refresh do plano falhou: ${error.runtimeType}');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
