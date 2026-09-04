import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../data/retencao_repository.dart';
import '../utils/retencao_display.dart';

Future<void> showRetencaoCatalogSheet(
  BuildContext context, {
  required RetencaoRepository repo,
}) {
  return showFxHomeSheet<void>(
    context,
    builder: (ctx) => _RetencaoCatalogSheet(repo: repo),
  );
}

class _RetencaoCatalogSheet extends StatefulWidget {
  const _RetencaoCatalogSheet({required this.repo});

  final RetencaoRepository repo;

  @override
  State<_RetencaoCatalogSheet> createState() => _RetencaoCatalogSheetState();
}

class _RetencaoCatalogSheetState extends State<_RetencaoCatalogSheet> {
  final _search = TextEditingController();
  Timer? _debounce;
  var _itens = const <RetencaoAlunoScore>[];
  var _page = 0;
  var _hasNext = false;
  var _total = 0;
  var _loading = true;
  var _loadingMore = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _reload('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _reload(String query) async {
    final next = await widget.repo.listarBase(q: query);
    if (!mounted) return;
    setState(() {
      _query = query;
      _itens = List.of(next.itens);
      _page = next.page;
      _hasNext = next.hasNext;
      _total = next.totalItens;
      _loading = false;
      _loadingMore = false;
    });
  }

  Future<void> _carregarMais() async {
    if (_loadingMore || !_hasNext) return;
    setState(() => _loadingMore = true);
    try {
      final next = await widget.repo.listarBase(page: _page + 1, q: _query);
      if (!mounted) return;
      final seen = _itens.map((item) => item.alunoId).toSet();
      setState(() {
        _itens = [
          ..._itens,
          ...next.itens.where((item) => seen.add(item.alunoId)),
        ];
        _page = next.page;
        _hasNext = next.hasNext;
        _total = next.totalItens;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    return FxHomeSheetSurface(
      isDark: isDark,
      child: ListView(
        shrinkWrap: true,
        children: [
          FxHomeSheetHeader(
            title: 'Base toda',
            subtitle: '$_total alunos neste recorte.',
            leading: Icon(Icons.favorite_outline, size: 18, color: primary),
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
                  _reload(value);
                });
              },
              onSubmitted: _reload,
              onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
              decoration: FxInputDeco.build(context, 'Buscar aluno'),
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(TokensStrip.s4),
              child: Center(child: SizedBox.shrink()),
            )
          else if (_itens.isEmpty)
            const FxEmptyState(
              icon: 'users',
              title: 'Nenhum aluno nessa busca',
              subtitle: 'Tente outro nome ou limpe o filtro.',
            )
          else ...[
            for (final score in _itens)
              FxSatelliteListTile(
                title: score.alunoNome,
                subtitle: Text(
                  'Score ${score.scoreAtual} · ${retencaoRiscoLabel(score.riscoChurn)}',
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/alunos/${score.alunoId}');
                },
              ),
            if (_hasNext)
              FxSatelliteListTile(
                title: _loadingMore ? 'Carregando…' : 'Carregar mais',
                subtitle:
                    _loadingMore
                        ? null
                        : Text('Mais ${_total - _itens.length} nesta lista.'),
                onTap: _loadingMore ? null : _carregarMais,
              ),
          ],
        ],
      ),
    );
  }
}
