import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
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
          FxSettingsGroup(
            children: [
              for (var i = 0; i < split.fold.length; i++)
                _AttentionTile(
                  entry: split.fold[i],
                  index: i,
                  total: split.total,
                  showDivider: i < split.fold.length - 1,
                ),
            ],
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
                      showDivider: i < items.length - 1,
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
    required this.showDivider,
    this.onOpen,
  });

  final DashboardAttentionEntry entry;
  final int index;
  final int total;
  final bool showDivider;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final nome = fxTitleCaseName(entry.nome);
    return FxSettingsTile(
      fxIcon: entry.icon,
      label: nome,
      subtitle: '${entry.titulo} · ${entry.subt}',
      value: entry.acao,
      showDivider: showDivider,
      semanticsLabel: dashboardAttentionItemSemantics(
        index: index + 1,
        total: total,
        nome: nome,
        titulo: entry.titulo,
        subt: entry.subt,
        acao: entry.acao,
      ),
      onTap: onOpen ?? () => _open(context, entry),
    );
  }
}
