import 'package:flutter/material.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/tokens_strip.dart';
import '../utils/dashboard_microcopy.dart';
import '../utils/dashboard_readability.dart';

Future<void> showDashboardHomeHelpSheet(
  BuildContext context, {
  required bool isDark,
}) {
  AnalyticsService.instance.track(ProductEvents.homeHelpOpened);
  final ink =
      isDark
          ? Theme.of(context).colorScheme.onSurface
          : TokensStrip.textPrimary;

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor:
        isDark ? const Color(0xFF101C2E) : Theme.of(context).colorScheme.surface,
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DashboardMicrocopy.helpHomeTitle,
              style: dashboardCardTitleStyle(ink),
            ),
            const SizedBox(height: 12),
            Text(
              DashboardMicrocopy.helpHomeBody,
              style: dashboardCardSubtitleStyle(
                context,
                isDark: isDark,
              ).copyWith(color: ink, height: 1.35),
            ),
            const SizedBox(height: 14),
            Text(
              DashboardMicrocopy.scoreComoCalculamos,
              style: dashboardCardSubtitleStyle(context, isDark: isDark),
            ),
            const SizedBox(height: 8),
            Text(
              DashboardMicrocopy.sugestaoIaDisclaimer,
              style: dashboardCardSubtitleStyle(context, isDark: isDark),
            ),
          ],
        ),
      );
    },
  );
}
