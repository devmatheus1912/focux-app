import 'package:flutter/material.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../financeiro/data/financeiro_repository.dart';
import '../data/dashboard_repository.dart';
import '../providers/aderencia_provider.dart';
import '../utils/dashboard_home_focus.dart';
import '../utils/dashboard_radar_items.dart';
import 'dashboard_aderencia_semana_widget.dart';
import 'dashboard_base_radar_strip.dart';
import 'dashboard_financial_hero_section.dart';
import 'dashboard_tools_section.dart';
import '../data/command_center_data.dart';
import '../../planos/data/planos_repository.dart';

/// Aderência + financeiro + tools — só entra quando `omitSecondarySections` é false.
class DashboardHomeSecondaryBlock extends StatelessWidget {
  const DashboardHomeSecondaryBlock({
    super.key,
    required this.focusRules,
    required this.isDark,
    required this.mes,
    required this.receitaAtual,
    required this.pendente,
    required this.progressRaw,
    required this.metaSuperada,
    required this.loadingFin,
    required this.finData,
    required this.onOpenRelatorio,
    this.topAderencia = const [],
    this.alunosScore = const [],
    this.homePlanoFeatures,
    this.toolsSectionKey,
  });

  final DashboardHomeFocusRules focusRules;
  final bool isDark;
  final String mes;
  final double receitaAtual;
  final double pendente;
  final double progressRaw;
  final bool metaSuperada;
  final bool loadingFin;
  final FinanceiroDashboard? finData;
  final VoidCallback onOpenRelatorio;
  final List<DashboardAderenciaTopItem> topAderencia;
  final List<AlunoScoreResumo> alunosScore;
  final PlanoFeatures? homePlanoFeatures;
  final GlobalKey? toolsSectionKey;

  @override
  Widget build(BuildContext context) {
    final showRelatorio = dashboardShowAderenciaRelatorio(
      focusMode: focusRules.focusMode,
      coversRetention: focusRules.dayFocusCoversRetention,
      weeklyCheckins: topAderencia.map((e) => e.totalCheckinsSemana),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (dashboardRadarVisibleOnHome(alunosScore))
          DashboardBaseRadarStrip(scores: alunosScore),
        DashboardAderenciaSemanaWidget(
          isDark: isDark,
          items:
              topAderencia
                  .map(AderenciaAlunoResumo.fromHomeItem)
                  .toList(growable: false),
          retentionFocus: focusRules.dayFocusCoversRetention,
          suppressEmptyActions: focusRules.suppressSecondaryEmptyCtas,
          showRelatorio: showRelatorio,
          onOpenRelatorio: onOpenRelatorio,
        ),
        DashboardFinancialHeroSection(
          mes: mes,
          receitaAtual: receitaAtual,
          pendente: pendente,
          progressRaw: progressRaw,
          metaSuperada: metaSuperada,
          loadingFin: loadingFin,
          finData: finData,
        ),
        const SizedBox(height: TokensStrip.s2),
        KeyedSubtree(
          key: toolsSectionKey,
          child: DashboardHomeToolsSection(
            isDark: isDark,
            hideFeaturedTools: focusRules.hideFeaturedTools,
            homePlanoFeatures: homePlanoFeatures,
          ),
        ),
      ],
    );
  }
}
