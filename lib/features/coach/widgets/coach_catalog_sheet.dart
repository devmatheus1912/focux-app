import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../data/coach_proativo_repository.dart';
import '../utils/coach_display.dart';

Future<void> showCoachCatalogSheet(
  BuildContext context, {
  required CoachHome firstPage,
  required CoachProativoRepository repo,
}) {
  return showFxHomeSheet<void>(
    context,
    builder:
        (ctx) => _CoachCatalogSheet(firstPage: firstPage, repo: repo),
  );
}

class _CoachCatalogSheet extends StatefulWidget {
  const _CoachCatalogSheet({
    required this.firstPage,
    required this.repo,
  });

  final CoachHome firstPage;
  final CoachProativoRepository repo;

  @override
  State<_CoachCatalogSheet> createState() => _CoachCatalogSheetState();
}

class _CoachCatalogSheetState extends State<_CoachCatalogSheet> {
  final _search = TextEditingController();
  Timer? _debounce;
  late List<CoachHomeItem> _itens = List.of(widget.firstPage.itens);
  late int _page = widget.firstPage.page;
  late bool _hasNext = widget.firstPage.hasNext;
  late int _total = widget.firstPage.totalItens;
  var _loadingMore = false;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _reload(String query) async {
    final next = await widget.repo.getHome(q: query);
    if (!mounted) return;
    setState(() {
      _query = query;
      _itens = List.of(next.itens);
      _page = next.page;
      _hasNext = next.hasNext;
      _total = next.totalItens;
      _loadingMore = false;
    });
  }

  Future<void> _carregarMais() async {
    if (_loadingMore || !_hasNext) return;
    setState(() => _loadingMore = true);
    try {
      final next = await widget.repo.getHome(page: _page + 1, q: _query);
      if (!mounted) return;
      final seen = _itens.map((item) => item.id).toSet();
      setState(() {
        _itens = [
          ..._itens,
          ...next.itens.where((item) => seen.add(item.id)),
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
            title: 'Fila do coach',
            subtitle: '$_total orientações neste recorte.',
            leading: Icon(Icons.auto_awesome_outlined, size: 18, color: primary),
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
          if (_itens.isEmpty)
            const FxEmptyState(
              icon: 'spark',
              title: 'Nenhuma orientação nessa busca',
              subtitle: 'Tente outro nome ou limpe o filtro.',
            )
          else ...[
            for (final item in _itens)
              FxSatelliteListTile(
                title: item.alunoNome,
                subtitle: Text(item.mensagem),
                onTap: () {
                  Navigator.of(context).pop();
                  context.push(coachRota(item));
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
