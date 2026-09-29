import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/fcm/plan_sync_coordinator.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/iap_purchase_coordinator.dart';
import '../utils/iap_session_gate.dart';

/// Liga o listener global de compras à sessão do personal e reflete o plano
/// depois de cada validação (renovação é silenciosa: sem toast).
class IapPurchaseSyncScope extends ConsumerStatefulWidget {
  const IapPurchaseSyncScope({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<IapPurchaseSyncScope> createState() =>
      _IapPurchaseSyncScopeState();
}

class _IapPurchaseSyncScopeState extends ConsumerState<IapPurchaseSyncScope> {
  StreamSubscription<IapPurchaseEvent>? _events;

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
      unawaited(coordinator.stop());
    }
  }

  void _onEvent(IapPurchaseEvent event) {
    if (!mounted || event is! IapPurchaseVerified) return;
    unawaited(
      PlanSyncCoordinator.refreshPlan(ProviderScope.containerOf(context)),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
