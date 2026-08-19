import 'package:flutter/material.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_help.dart';
import '../utils/dashboard_microcopy.dart';
import '../utils/dashboard_readability.dart';

Future<void> showDashboardHomeHelpSheet(
  BuildContext context, {
  required bool isDark,
}) {
  AnalyticsService.instance.track(ProductEvents.homeHelpOpened);

  return showFxHelpSheet(
    context,
    title: DashboardMicrocopy.helpHomeTitle,
    subtitle: DashboardMicrocopy.helpHomeBody,
    extra: [
      Text(
        DashboardMicrocopy.scoreComoCalculamos,
        style: dashboardCardSubtitleStyle(context, isDark: isDark),
      ),
      SizedBox(height: TokensStrip.s2),
      Text(
        DashboardMicrocopy.sugestaoIaDisclaimer,
        style: dashboardCardSubtitleStyle(context, isDark: isDark),
      ),
    ],
  );
}
