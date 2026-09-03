import 'package:flutter/material.dart';

import '../../../../core/theme/focux_hub_typography.dart';
import '../../../../core/theme/fx_settings_layout.dart';
import '../../../../core/theme/tokens_strip.dart';
import '../../../../core/widgets/fx_empty_state.dart';
import '../../../../core/widgets/fx_shell_scaffold.dart';
import '../../../dashboard/widgets/dashboard_section_header.dart';
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
      return _section(context, filter, items, buscaCountInFilterLabel(items.length, filter.label));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (result.alunos.isNotEmpty)
          _section(
            context,
            BuscaTipo.aluno,
            result.alunos,
            buscaCountLabel(result.alunos.length),
          ),
        if (result.treinos.isNotEmpty)
          _section(
            context,
            BuscaTipo.treino,
            result.treinos,
            buscaCountLabel(result.treinos.length),
          ),
        if (result.cobrancas.isNotEmpty)
          _section(
            context,
            BuscaTipo.cobranca,
            result.cobrancas,
            buscaCountLabel(result.cobrancas.length),
          ),
      ],
    );
  }

  Widget _section(
    BuildContext context,
    BuscaTipo tipo,
    List<BuscaItem> items,
    String caption,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: FxSettingsLayout.groupGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardSectionHeader(title: buscaSectionHeader(tipo)),
          Padding(
            padding: const EdgeInsets.only(
              top: TokensStrip.s1,
              bottom: TokensStrip.s3,
            ),
            child: Text(
              caption,
              style: FocuxHubTypography.bodyMuted(
                color: fxScreenMute(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (final item in items) _tile(item),
        ],
      ),
    );
  }

  Widget _tile(BuscaItem item) {
    return FxSatelliteListTile(
      title: item.titulo,
      subtitle: item.subtitulo == null || item.subtitulo!.trim().isEmpty
          ? null
          : Text(item.subtitulo!),
      onTap: () => onOpen(item),
    );
  }
}
