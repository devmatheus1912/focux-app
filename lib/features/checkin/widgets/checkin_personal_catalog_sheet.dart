import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../alunos/widgets/aluno_avatar.dart';
import '../data/checkin_repository.dart';
import '../models/checkin_personal_home.dart';

Future<void> showCheckinPersonalCatalogSheet(
  BuildContext context, {
  required String title,
  required CheckinPersonalHomeBundle firstPage,
  required CheckinRepository repo,
}) {
  return showFxHomeSheet<void>(
    context,
    builder: (ctx) {
      return _CheckinCatalogSheet(
        title: title,
        firstPage: firstPage,
        repo: repo,
      );
    },
  );
}

class _CheckinCatalogSheet extends StatefulWidget {
  const _CheckinCatalogSheet({
    required this.title,
    required this.firstPage,
    required this.repo,
  });

  final String title;
  final CheckinPersonalHomeBundle firstPage;
  final CheckinRepository repo;

  @override
  State<_CheckinCatalogSheet> createState() => _CheckinCatalogSheetState();
}

class _CheckinCatalogSheetState extends State<_CheckinCatalogSheet> {
  final _search = TextEditingController();
  Timer? _debounce;
  late List<CheckinPersonalItem> _itens = List.of(widget.firstPage.itens);
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
    final next = await widget.repo.personalHome(q: query);
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
      final next = await widget.repo.personalHome(
        page: _page + 1,
        q: _query,
      );
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
            title: widget.title,
            subtitle: '$_total check-ins neste recorte.',
            leading: Icon(Icons.fitness_center, size: 18, color: primary),
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
            FxEmptyState(
              icon: 'users',
              title: 'Nenhum check-in nessa busca',
              subtitle: 'Tente outro nome ou limpe o filtro.',
            )
          else ...[
            for (final item in _itens)
              FxSatelliteListTile(
                title: item.alunoNome,
                subtitle: Text(item.treinoNome),
                leading: AlunoAvatar(
                  name: item.alunoNome,
                  photoUrl: item.fotoUrl,
                  variant: AlunoAvatarVariant.strip,
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/alunos/${item.alunoId}');
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
