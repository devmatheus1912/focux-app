import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/utils/pt_br_display.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../financeiro/data/financeiro_repository.dart';
import '../constants/dashboard_layout.dart';
import '../utils/dashboard_microcopy.dart';
import '../utils/dashboard_screen_helpers.dart';
import 'dashboard_finance_empty.dart';
import 'dashboard_section_header.dart';

/// Panorama financeiro — tiles inset, sem hero KPI.
class DashboardFinancialHeroSection extends StatelessWidget {
  const DashboardFinancialHeroSection({
    super.key,
    required this.mes,
    required this.receitaAtual,
    required this.pendente,
    required this.progressRaw,
    required this.metaSuperada,
    required this.loadingFin,
    required this.finData,
  });

  final String mes;
  final double receitaAtual;
  final double pendente;
  final double progressRaw;
  final bool metaSuperada;
  final bool loadingFin;
  final FinanceiroDashboard? finData;

  @override
  Widget build(BuildContext context) {
    final zero = receitaAtual <= 0 && !loadingFin;
    return Padding(
      padding: DashboardLayout.foldCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardSectionHeader(
            title: DashboardMicrocopy.panoramaFinanceiro,
            actionLabel: DashboardMicrocopy.abrirFinanceiro,
            onAction: () => context.go('/financeiro'),
          ),
          const SizedBox(height: FxSettingsLayout.headerToGroup),
          if (zero)
            DashboardFinanceEmptyState(
              mes: mes,
              ctaLabel: finData?.zeroCta,
              onOpen: () => context.go('/financeiro'),
            )
          else
            _FinanceTiles(
              mes: mes,
              receitaAtual: receitaAtual,
              pendente: pendente,
              progressRaw: progressRaw,
              metaSuperada: metaSuperada,
              finData: finData,
            ),
        ],
      ),
    );
  }
}

class _FinanceTiles extends StatelessWidget {
  const _FinanceTiles({
    required this.mes,
    required this.receitaAtual,
    required this.pendente,
    required this.progressRaw,
    required this.metaSuperada,
    required this.finData,
  });

  final String mes;
  final double receitaAtual;
  final double pendente;
  final double progressRaw;
  final bool metaSuperada;
  final FinanceiroDashboard? finData;

  @override
  Widget build(BuildContext context) {
    final ticket = finData?.ticketMedio ?? 0;
    final showTicket = receitaAtual > 0 && ticket > 0;
    final inadimpl = finData?.totalInadimplentes ?? 0;
    final metaLabel = financePercentLabel(
      progressRaw,
      exceeded: metaSuperada,
    );
    final recebido = formatBrlCurrency(receitaAtual, showDecimals: false);
    final pendenteLabel = formatBrlCurrency(pendente, showDecimals: false);

    return Semantics(
      label:
          'Panorama financeiro de $mes. '
          'Recebido $recebido. '
          'Toque para abrir financeiro',
      child: FxSettingsGroup(
        children: [
          FxSettingsTile(
            fxIcon: 'dollar-sign',
            label: 'Recebido · $mes',
            subtitle: metaSuperada
                ? 'Meta superada'
                : pendente > 0
                    ? 'Faltam $pendenteLabel para a meta'
                    : 'Meta do mês sob controle',
            value: recebido,
            numeric: true,
            showDivider: true,
            onTap: () => context.go('/financeiro'),
          ),
          FxSettingsTile(
            fxIcon: 'alert-triangle',
            label: 'Pendente',
            subtitle: inadimpl > 0
                ? '$inadimpl ${financeInadimplLabel(MediaQuery.sizeOf(context).width).toLowerCase()}'
                : 'Sem inadimplência no recorte',
            value: pendenteLabel,
            numeric: true,
            showDivider: true,
            onTap: () => context.go('/financeiro'),
          ),
          FxSettingsTile(
            fxIcon: 'target',
            label: 'Meta',
            subtitle: showTicket
                ? 'Ticket ${formatBrlCurrency(ticket, showDecimals: false)}'
                : null,
            value: metaLabel,
            showDivider: false,
            onTap: () => context.go('/financeiro'),
          ),
        ],
      ),
    );
  }
}
