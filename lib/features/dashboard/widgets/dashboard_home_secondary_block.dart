import 'package:flutter/material.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../financeiro/data/financeiro_repository.dart';
import '../constants/dashboard_layout.dart';
import '../data/dashboard_repository.dart';
import '../providers/aderencia_provider.dart';
import '../utils/dashboard_entry_motion.dart';
import '../utils/dashboard_home_focus.dart';
import '../utils/dashboard_radar_items.dart';
import '../utils/dashboard_microcopy.dart';
import 'dashboard_aderencia_semana_widget.dart';
import 'dashboard_base_radar_strip.dart';
import 'dashboard_collapsible_section.dart';
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
    required this.heroPrimary,
    required this.mes,
    required this.receitaAtual,
    required this.pendente,
    required this.progressRaw,
    required this.metaSuperada,
    required this.loadingFin,
    required this.counterAnim,
    required this.finData,
    required this.receitaTrend,
    required this.reduceMotion,
    required this.heroFade,
    required this.onOpenRelatorio,
    this.topAderencia = const [],
    this.alunosScore = const [],
    this.homePlanoFeatures,
    this.toolsSectionKey,
  });

  final DashboardHomeFocusRules focusRules;
  final bool isDark;
  final Color heroPrimary;
  final String mes;
  final double receitaAtual;
  final double pendente;
  final double progressRaw;
  final bool metaSuperada;
  final bool loadingFin;
  final Animation<double> counterAnim;
  final FinanceiroDashboard? finData;
  final List<double> receitaTrend;
  final bool reduceMotion;
  final Animation<double> heroFade;
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
        if (dashboardRadarVisibleOnHome(alunosScore)) ...[
          SizedBox(height: DashboardLayout.sliverSectionGap),
          DashboardBaseRadarStrip(scores: alunosScore),
        ],
        SizedBox(height: DashboardLayout.sliverSectionGap),
        DashboardCollapsibleSection(
          title: DashboardMicrocopy.aderenciaDaSemana,
          collapsedHint:
              focusRules.dayFocusCoversRetention
                  ? DashboardMicrocopy.rankingSemanalHint
                  : DashboardMicrocopy.treinosRankingHint,
          isDark: isDark,
          initiallyExpanded: !focusRules.collapseAderencia,
          quietChrome: true,
          headerActionLabel: showRelatorio ? 'Relatório' : null,
          onHeaderAction: showRelatorio ? onOpenRelatorio : null,
          child: DashboardAderenciaSemanaWidget(
            isDark: isDark,
            items:
                topAderencia
                    .map(AderenciaAlunoResumo.fromHomeItem)
                    .toList(growable: false),
            retentionFocus: focusRules.dayFocusCoversRetention,
            suppressEmptyActions: focusRules.suppressSecondaryEmptyCtas,
          ),
        ),
        SizedBox(height: DashboardLayout.sliverTightGap),
        DashboardCollapsibleSection(
          title: DashboardMicrocopy.panoramaFinanceiro,
          collapsedHint:
              receitaAtual > 0
                  ? 'R\$ ${receitaAtual.toInt()} recebido · ${DashboardMicrocopy.toqueParaExpandir}'
                  : 'R\$ 0 recebido · meta do mês',
          isDark: isDark,
          initiallyExpanded: !focusRules.collapseFinance,
          quietChrome: true,
          child: dashboardEntryMotion(
            context: context,
            fade: heroFade,
            slideBegin: const Offset(0, 0.05),
            child: DashboardFinancialHeroSection(
              reduceMotion: reduceMotion,
              themeDark: isDark,
              heroPrimary: heroPrimary,
              mes: mes,
              receitaAtual: receitaAtual,
              pendente: pendente,
              progressRaw: progressRaw,
              metaSuperada: metaSuperada,
              loadingFin: loadingFin,
              counterAnim: counterAnim,
              finData: finData,
              receitaTrend: receitaTrend,
            ),
          ),
        ),
        const SizedBox(height: TokensStrip.s2),
        KeyedSubtree(
          key: toolsSectionKey,
          child: DashboardCollapsibleToolsSection(
            isDark: isDark,
            hideFeaturedTools: focusRules.hideFeaturedTools,
            homePlanoFeatures: homePlanoFeatures,
            quietChrome: true,
          ),
        ),
      ],
    );
  }
}
