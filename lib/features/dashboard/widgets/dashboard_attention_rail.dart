import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../alunos/data/aluno_repository.dart';
import '../../financeiro/data/financeiro_repository.dart';
import '../constants/dashboard_layout.dart';
import '../utils/dashboard_a11y.dart';
import '../utils/dashboard_attention_items.dart';
import '../utils/dashboard_microcopy.dart';
import 'dashboard_section_header.dart';

/// Precisa de atenção — 2 no fold, resto na sheet. Sem accordion nem rail.
class DashboardAttentionRail extends StatelessWidget {
  const DashboardAttentionRail({
    super.key,
    required this.attentionRiskItems,
    required this.attentionVencItems,
  });

  final List<Aluno> attentionRiskItems;
  final List<VencimentoItem> attentionVencItems;

  @override
  Widget build(BuildContext context) {
    final split = dashboardAttentionSplit(
      dashboardAttentionEntries(
        riskItems: attentionRiskItems,
        vencItems: attentionVencItems,
      ),
    );
    if (split.fold.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: DashboardLayout.foldCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardSectionHeader(
            title: DashboardMicrocopy.precisaDeAtencao,
            actionLabel: split.hasMore ? DashboardMicrocopy.radarVerTodos : null,
            onAction: split.hasMore
                ? () => _showSheet(context, split.pool)
                : null,
          ),
          const SizedBox(height: FxSettingsLayout.headerToGroup),
          for (var i = 0; i < split.fold.length; i++)
            _AttentionTile(
              entry: split.fold[i],
              index: i,
              total: split.total,
            ),
        ],
      ),
    );
  }

  Future<void> _showSheet(
    BuildContext parent,
    List<DashboardAttentionEntry> items,
  ) {
    final isDark = Theme.of(parent).brightness == Brightness.dark;
    final brand = Theme.of(parent).colorScheme.primary;
    return showFxHomeSheet<void>(
      parent,
      builder: (sheet) {
        return FxHomeSheetSurface(
          isDark: isDark,
          maxHeight:
              MediaQuery.sizeOf(sheet).height *
              FxHomeSheetChrome.maxHeightFactor,
          expand: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FxHomeSheetHandle(isDark: isDark),
              SizedBox(height: FxSettingsLayout.headerToGroup),
              FxHomeSheetHeader(
                isDark: isDark,
                title: DashboardMicrocopy.precisaDeAtencao,
                subtitle: 'Contato e cobrança — toque para abrir.',
                leading: FxIcon(
                  name: 'alert-triangle',
                  size: FxSettingsLayout.iconSize,
                  color: brand,
                ),
              ),
              SizedBox(height: FxSettingsLayout.headerToGroup),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  physics: const BouncingScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    return _AttentionTile(
                      entry: items[i],
                      index: i,
                      total: items.length,
                      onOpen: () {
                        Navigator.of(sheet).pop();
                        _open(parent, items[i]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

void _open(BuildContext context, DashboardAttentionEntry entry) {
  if (entry.route == '/financeiro') {
    context.go(entry.route);
  } else {
    context.push(entry.route);
  }
}

class _AttentionTile extends StatelessWidget {
  const _AttentionTile({
    required this.entry,
    required this.index,
    required this.total,
    this.onOpen,
  });

  final DashboardAttentionEntry entry;
  final int index;
  final int total;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final nome = fxTitleCaseName(entry.nome);
    return Semantics(
      label: dashboardAttentionItemSemantics(
        index: index + 1,
        total: total,
        nome: nome,
        titulo: entry.titulo,
        subt: entry.subt,
        acao: entry.acao,
      ),
      button: true,
      child: FxSatelliteListTile(
        title: nome,
        subtitle: Text('${entry.titulo} · ${entry.subt}'),
        trailing: Text(
          entry.acao,
          style: FocuxHubTypography.bodyMuted(
            color: fxScreenMute(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        onTap: onOpen ?? () => _open(context, entry),
      ),
    );
  }
}
