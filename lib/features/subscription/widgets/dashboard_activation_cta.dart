import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../dashboard/constants/dashboard_layout.dart';
import '../../dashboard/widgets/dashboard_home_activation_strip.dart';
import '../../onboarding/widgets/setup_step_widgets.dart';

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
    ({String title, String body, String cta, String route})? step;

    if (alunosAtivos == 0) {
      step = (
        title: 'Importe seus alunos',
        body: 'Migração em cerca de 2 min',
        cta: 'Importar alunos',
        route: '/growth/migracao',
      );
    } else if (!temTreinos) {
      step = (
        title: 'Atribua o primeiro treino',
        body: 'Gere com IA ou use um template',
        cta: 'Criar treino',
        route: '/treinos/novo',
      );
    } else if (!temFinanceiro) {
      step = (
        title: 'Lance a primeira mensalidade',
        body: 'PIX automático + lembrete',
        cta: 'Abrir financeiro',
        route: '/financeiro',
      );
    }

    if (step == null) return const SizedBox.shrink();

    final activeStep = step;

    return Padding(
      padding: DashboardLayout.foldCard,
      child: DashboardHomeActivationStrip(
        title: activeStep.title,
        subtitle: activeStep.body,
        semanticsLabel: '${activeStep.title}. ${activeStep.cta}',
        onTap: () {
          AnalyticsService.instance.track(
            ProductEvents.activationCtaTapped,
            props: {'route': activeStep.route, 'source': 'home_activation'},
          );
          context.push(normalizeSetupActionRoute(activeStep.route));
        },
      ),
    );
  }
}
