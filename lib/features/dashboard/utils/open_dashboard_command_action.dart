import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../providers/dashboard_provider.dart';
import '../utils/dashboard_home_client_cache.dart';
import '../utils/dashboard_next_actions.dart';

/// Navega para o job da ação; gargalo agenda-semana fecha ao abrir `/agenda`.
Future<void> openDashboardCommandAction({
  required BuildContext context,
  required WidgetRef ref,
  required CommandActionItem item,
  String source = 'next_actions',
}) async {
  AnalyticsService.instance.track(
    ProductEvents.homeDayFocusAction,
    props: {
      'route': item.route,
      'title': item.title,
      'priority': item.priorityBadge,
      'source': source,
      if (item.actionKey != null) 'actionKey': item.actionKey,
    },
  );

  final key = item.actionKey;
  if (key != null &&
      key.isNotEmpty &&
      commandActionAutoCompletesOnOpen(item)) {
    try {
      await ref.read(dashboardRepositoryProvider).completeCommandAction(key);
      DashboardHomeClientCache.clear();
      ref.invalidate(dashboardHomeProvider);
    } catch (_) {
      // Navega mesmo se o complete falhar — o job da tela importa mais.
    }
  }

  if (!context.mounted) return;
  context.go(item.route);
}
