import 'package:flutter/material.dart';

import '../../../../core/theme/fx_settings_layout.dart';
import '../../../../core/widgets/fx_empty_state.dart';
import '../../../../core/widgets/fx_settings_group.dart';
import '../../../../core/widgets/fx_settings_tile.dart';
import '../../models/busca_global_models.dart';
import '../../utils/busca_display.dart';

class BuscaGlobalResults extends StatelessWidget {
  const BuscaGlobalResults({
    super.key,
    required this.query,
    required this.filter,
    required this.result,
    required this.onOpen,
  });

  final String query;
  final BuscaTipo filter;
  final BuscaGlobalResult result;
  final ValueChanged<BuscaItem> onOpen;

  @override
  Widget build(BuildContext context) {
    if (query.trim().length < buscaMinQueryLength) {
      return FxEmptyState(
        icon: 'search',
        title: buscaMinQueryTitle(),
        subtitle: buscaMinQuerySubtitle(),
      );
    }
    if (result.isEmpty) {
      return FxEmptyState(
        icon: 'search',
        title: buscaEmptyTitle(query),
        subtitle: buscaEmptySubtitle(),
      );
    }
    if (filter != BuscaTipo.todos) {
      final items = buscaFilterByTipo(result, filter);
      if (items.isEmpty) {
        return FxEmptyState(
          icon: 'search',
          title: buscaEmptyFilterTitle(filter.label),
          subtitle: buscaEmptyFilterSubtitle(),
        );
      }
      return FxSettingsGroup(
        header: buscaSectionHeader(filter),
        caption: buscaCountInFilterLabel(items.length, filter.label),
        children: [
          for (var i = 0; i < items.length; i++)
            _tile(items[i], showDivider: i != items.length - 1),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (result.alunos.isNotEmpty) ...[
          FxSettingsGroup(
            header: buscaSectionHeader(BuscaTipo.aluno),
            caption: buscaCountLabel(result.alunos.length),
            children: [
              for (var i = 0; i < result.alunos.length; i++)
                _tile(
                  result.alunos[i],
                  showDivider: i != result.alunos.length - 1,
                ),
            ],
          ),
          const SizedBox(height: FxSettingsLayout.groupGap),
        ],
        if (result.treinos.isNotEmpty) ...[
          FxSettingsGroup(
            header: buscaSectionHeader(BuscaTipo.treino),
            caption: buscaCountLabel(result.treinos.length),
            children: [
              for (var i = 0; i < result.treinos.length; i++)
                _tile(
                  result.treinos[i],
                  showDivider: i != result.treinos.length - 1,
                ),
            ],
          ),
          const SizedBox(height: FxSettingsLayout.groupGap),
        ],
        if (result.cobrancas.isNotEmpty)
          FxSettingsGroup(
            header: buscaSectionHeader(BuscaTipo.cobranca),
            caption: buscaCountLabel(result.cobrancas.length),
            children: [
              for (var i = 0; i < result.cobrancas.length; i++)
                _tile(
                  result.cobrancas[i],
                  showDivider: i != result.cobrancas.length - 1,
                ),
            ],
          ),
      ],
    );
  }

  Widget _tile(BuscaItem item, {required bool showDivider}) {
    return FxSettingsTile(
      fxIcon: buscaItemFxIcon(item.tipo),
      label: item.titulo,
      subtitle: item.subtitulo,
      value: '',
      showDivider: showDivider,
      onTap: () => onOpen(item),
    );
  }
}
