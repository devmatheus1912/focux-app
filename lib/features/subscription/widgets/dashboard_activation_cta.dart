import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../dashboard/constants/dashboard_layout.dart';
import '../../dashboard/widgets/dashboard_home_activation_strip.dart';
import '../utils/dashboard_activation_step.dart';

/// Alerta de ativação quando o personal ainda não extraiu valor do app.
class DashboardActivationCta extends StatelessWidget {
  const DashboardActivationCta({
    super.key,
    required this.alunosAtivos,
    required this.temTreinos,
    required this.temFinanceiro,
  });

  final int alunosAtivos;
  final bool temTreinos;
  final bool temFinanceiro;

  @override
  Widget build(BuildContext context) {
    final step = dashboardActivationStep(
      S.of(context),
      alunosAtivos: alunosAtivos,
      temTreinos: temTreinos,
      temFinanceiro: temFinanceiro,
    );
    if (step == null) return const SizedBox.shrink();

    return Padding(
      padding: DashboardLayout.foldCard,
      child: DashboardHomeActivationStrip(
        title: step.title,
        subtitle: step.body,
        semanticsLabel: '${step.title}. ${step.cta}',
        onTap: () {
          AnalyticsService.instance.track(
            ProductEvents.activationCtaTapped,
            props: {'route': step.route, 'source': 'home_activation'},
          );
          context.push(step.route);
        },
      ),
    );
  }
}
