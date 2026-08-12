import 'package:flutter/material.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../financeiro/data/financeiro_repository.dart';
import '../constants/dashboard_layout.dart';
import '../utils/dashboard_entry_motion.dart';
import '../utils/dashboard_home_focus.dart';
import '../utils/dashboard_microcopy.dart';
import 'dashboard_aderencia_semana_widget.dart';
import 'dashboard_collapsible_section.dart';
import 'dashboard_financial_hero_section.dart';
import 'dashboard_tools_section.dart';

/// Aderência + financeiro + tools — só entra quando `omitSecondarySections` é false.
class DashboardHomeSecondaryBlock extends StatelessWidget {
  const DashboardHomeSecondaryBlock({
    super.key,
    required this.focusRules,
    required this.isDark,
    required this.heroPrimary,
    required this.heroDeep,
    required this.mes,
    required this.receitaAtual,
    required this.pendente,
    required this.progressRaw,
    required this.metaSuperada,
    required this.loadingFin,
    required this.counterAnim,
    required this.finData,
    required this.receitaTrend,
    required this.gradientCtrl,
    required this.reduceMotion,
    required this.heroFade,
    required this.shortcutAspectRatio,
    required this.onOpenRelatorio,
  });

  final DashboardHomeFocusRules focusRules;
  final bool isDark;
  final Color heroPrimary;
  final Color heroDeep;
  final String mes;
  final double receitaAtual;
  final double pendente;
  final double progressRaw;
  final bool metaSuperada;
  final bool loadingFin;
  final Animation<double> counterAnim;
  final FinanceiroDashboard? finData;
  final List<double> receitaTrend;
  final AnimationController gradientCtrl;
  final bool reduceMotion;
  final Animation<double> heroFade;
  final double shortcutAspectRatio;
  final VoidCallback onOpenRelatorio;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: DashboardLayout.sliverSectionGap),
        DashboardCollapsibleSection(
          title: DashboardMicrocopy.aderenciaDaSemana,
          collapsedHint:
              focusRules.dayFocusCoversRetention
                  ? 'Ranking semanal · expandir se precisar'
                  : 'Treinos e ranking · ${DashboardMicrocopy.toqueParaExpandir}',
          isDark: isDark,
          initiallyExpanded: !focusRules.collapseAderencia,
          headerActionLabel: focusRules.focusMode ? null : 'Relatório',
          onHeaderAction: focusRules.focusMode ? null : onOpenRelatorio,
          child: DashboardAderenciaSemanaWidget(
            isDark: isDark,
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
          child: dashboardEntryMotion(
            context: context,
            fade: heroFade,
            slideBegin: const Offset(0, 0.05),
            child: DashboardFinancialHeroSection(
              gradientCtrl: gradientCtrl,
              reduceMotion: reduceMotion,
              themeDark: isDark,
              heroPrimary: heroPrimary,
              heroDeep: heroDeep,
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
        const SizedBox(height: TokensStrip.s3),
        DashboardCollapsibleToolsSection(
          isDark: isDark,
          shortcutAspectRatio: shortcutAspectRatio,
          hideFeaturedTools: focusRules.hideFeaturedTools,
        ),
      ],
    );
  }
}
