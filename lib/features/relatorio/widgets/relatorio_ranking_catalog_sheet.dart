import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../data/relatorio_repository.dart';
import '../utils/relatorio_global_display.dart';
import 'relatorio_ranking_tile.dart';

Future<void> showRelatorioRankingCatalogSheet(
  BuildContext context, {
  required String title,
  required List<ResumoAluno> alunos,
  required bool attention,
  required void Function(ResumoAluno aluno) onAluno,
}) {
  return showFxHomeSheet<void>(
    context,
    builder:
        (ctx) => _RelatorioRankingCatalogSheet(
          title: title,
          alunos: alunos,
          attention: attention,
          onAluno: onAluno,
        ),
  );
}

class _RelatorioRankingCatalogSheet extends StatefulWidget {
  const _RelatorioRankingCatalogSheet({
    required this.title,
    required this.alunos,
    required this.attention,
    required this.onAluno,
  });

  final String title;
  final List<ResumoAluno> alunos;
  final bool attention;
  final void Function(ResumoAluno aluno) onAluno;

  @override
  State<_RelatorioRankingCatalogSheet> createState() =>
      _RelatorioRankingCatalogSheetState();
}

class _RelatorioRankingCatalogSheetState
    extends State<_RelatorioRankingCatalogSheet> {
  final _search = TextEditingController();
  Timer? _debounce;
  var _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final filtered = relatorioRankingSearch(
      widget.alunos,
      _query,
      (aluno) => aluno.alunoNome,
    );
    return FxHomeSheetSurface(
      isDark: isDark,
      child: ListView(
        shrinkWrap: true,
        children: [
          FxHomeSheetHeader(
            title: widget.title,
            subtitle: '${widget.alunos.length} alunos neste recorte.',
            leading: Icon(
              widget.attention ? Icons.warning_amber_outlined : Icons.emoji_events_outlined,
              size: 18,
              color: primary,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TokensStrip.s4,
              0,
              TokensStrip.s4,
              TokensStrip.s3,
            ),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 350), () {
                  if (!mounted) return;
                  setState(() => _query = value);
                });
              },
              onSubmitted: (value) => setState(() => _query = value),
              onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
              decoration: FxInputDeco.build(context, 'Buscar aluno'),
            ),
          ),
          if (filtered.isEmpty)
            const FxEmptyState(
              icon: 'users',
              title: 'Nenhum aluno nessa busca',
              subtitle: 'Tente outro nome ou limpe o filtro.',
            )
          else
            for (var i = 0; i < filtered.length; i++)
              RelatorioRankingTile(
                aluno: filtered[i],
                attention: widget.attention,
                accentFirst: !widget.attention && i == 0 && _query.trim().isEmpty,
                onTap: () {
                  Navigator.of(context).pop();
                  widget.onAluno(filtered[i]);
                },
              ),
        ],
      ),
    );
  }
}
