import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../onboarding/widgets/setup_step_widgets.dart';

/// CTAs de ativação quando o personal ainda não extraiu valor do app.
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
    final primary = Theme.of(context).colorScheme.primary;
    ({String title, String body, String cta, String route})? step;

    if (alunosAtivos == 0) {
      step = (
        title: 'Importe seus alunos em 2 minutos',
        body:
            'MFIT, Trainerize, planilha ou foto — migração mágica no Premium.',
        cta: 'Importar alunos',
        route: '/growth/migracao',
      );
    } else if (!temTreinos) {
      step = (
        title: 'Atribua o primeiro treino',
        body: 'Alunos engajados renovam plano. Gere com IA ou use um template.',
        cta: 'Criar treino',
        route: '/treinos/novo',
      );
    } else if (!temFinanceiro) {
      step = (
        title: 'Lance a primeira mensalidade',
        body: 'Cobrança automática via PIX + lembrete push para o aluno.',
        cta: 'Abrir financeiro',
        route: '/financeiro',
      );
    }

    if (step == null) return const SizedBox.shrink();

    final activeStep = step;

    return Padding(
      padding: const EdgeInsets.fromLTRB(TokensStrip.s5, 0, TokensStrip.s5, 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(TokensStrip.rCard),
          onTap: () {
            AnalyticsService.instance.track(
              'activation_cta_tapped',
              props: {'route': activeStep.route},
            );
            context.push(normalizeSetupActionRoute(activeStep.route));
          },
          child: Ink(
            decoration: fxStripCardDecoration(context, accent: primary),
            padding: const EdgeInsets.all(TokensStrip.s4),
            child: Semantics(
            button: true,
            label: '${activeStep.title}. ${activeStep.cta}',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activeStep.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activeStep.body,
                  style: const TextStyle(fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 10),
                Text(
                  activeStep.cta,
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }
}
