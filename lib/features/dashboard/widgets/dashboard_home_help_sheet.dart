import 'package:flutter/material.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/widgets/fx_help.dart';
import '../utils/dashboard_microcopy.dart';
import '../../../core/theme/fx_icons.dart';

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
        icon: FxIcons.raio,
      ),
      FxHelpTip(
        DashboardMicrocopy.helpHomeBaseTitle,
        DashboardMicrocopy.helpHomeBaseBody,
        icon: FxIcons.grafico,
      ),
      FxHelpTip(
        DashboardMicrocopy.helpHomeDinheiroTitle,
        DashboardMicrocopy.helpHomeDinheiroBody,
        icon: FxIcons.dinheiro,
      ),
      FxHelpTip(
        DashboardMicrocopy.helpHomeSearchTitle,
        DashboardMicrocopy.helpHomeSearchBody,
        icon: FxIcons.buscar,
      ),
      FxHelpTip(
        'Índice Focux',
        DashboardMicrocopy.scoreComoCalculamos,
        icon: FxIcons.estrela,
      ),
    ],
    footer: DashboardMicrocopy.helpHomeFooter,
  );
}
