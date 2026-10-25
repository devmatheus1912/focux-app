import 'package:flutter/material.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/widgets/fx_help.dart';
import '../utils/dashboard_microcopy.dart';

Future<void> showDashboardHomeHelpSheet(BuildContext context) {
  AnalyticsService.instance.track(ProductEvents.homeHelpOpened);

  return showFxHelpSheet(
    context,
    title: DashboardMicrocopy.helpHomeTitle,
    subtitle: DashboardMicrocopy.helpHomeBody,
    tips: const [
      FxHelpTip(
        DashboardMicrocopy.helpHomeAgoraTitle,
        DashboardMicrocopy.helpHomeAgoraBody,
        icon: 'zap',
      ),
      FxHelpTip(
        DashboardMicrocopy.helpHomeBaseTitle,
        DashboardMicrocopy.helpHomeBaseBody,
        icon: 'trend',
      ),
      FxHelpTip(
        DashboardMicrocopy.helpHomeDinheiroTitle,
        DashboardMicrocopy.helpHomeDinheiroBody,
        icon: 'dollar-sign',
      ),
      FxHelpTip(
        DashboardMicrocopy.helpHomeSearchTitle,
        DashboardMicrocopy.helpHomeSearchBody,
        icon: 'search',
      ),
      FxHelpTip(
        'Índice Focux',
        DashboardMicrocopy.scoreComoCalculamos,
        icon: 'star',
      ),
    ],
    footer: DashboardMicrocopy.helpHomeFooter,
  );
}
