import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../utils/checkin_personal_display.dart';
import 'checkin_personal_abrir.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../alunos/widgets/aluno_avatar.dart';
import '../data/checkin_repository.dart';
import '../models/checkin_personal_home.dart';
import '../../../core/theme/fx_icons.dart';

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
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mute = ShellChrome.of(context).mute;
    // Mesmo recorte e mesmo agrupamento da tela: só os dias antes de hoje,
    // por dia e por aluno, com a hora (SPEC 12/11).
    final semHoje = checkinSemHoje(_itens);
    final alunos = semHoje.map((i) => i.alunoId).toSet().length;
    final busca = alunos > 6 || _query.isNotEmpty;
    return FxHomeSheetSurface(
      isDark: isDark,
      child: ListView(
        shrinkWrap: true,
        children: [
          FxHomeSheetHeader(
            title: widget.title,
            subtitle: checkinSemanaContagem(semHoje.length),
          ),
          if (busca)
            Padding(
              padding: const EdgeInsets.only(bottom: TokensStrip.s3),
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
                onTapOutside:
                    (_) => FocusManager.instance.primaryFocus?.unfocus(),
                decoration: FxInputDeco.build(context, 'Buscar aluno'),
              ),
            ),
          if (semHoje.isEmpty)
            FxEmptyState(
              icon: FxIcons.grupo,
              title: 'Nenhum check-in nessa busca',
              subtitle: 'Tente outro nome ou limpe o filtro.',
            )
          else ...[
            for (final (dia, grupos) in checkinPorDia(semHoje)) ...[
              Padding(
                padding: const EdgeInsets.only(
                  top: TokensStrip.s2,
                  bottom: TokensStrip.s1,
                ),
                child: Text(
                  dia,
                  style: FocuxHubTypography.bodyMuted(color: mute),
                ),
              ),
              for (final grupo in grupos)
                FxSatelliteListTile(
                  title: grupo.alunoNome,
                  subtitle: Text(checkinDoAlunoLinha(grupo)),
                  leading: AlunoAvatar(
                    name: grupo.alunoNome,
                    photoUrl: grupo.fotoUrl,
                    variant: AlunoAvatarVariant.strip,
                  ),
                  trailing:
                      grupo.ultimoEm == null
                          ? null
                          : Text(
                            checkinHoraLinha(grupo.ultimoEm!),
                            style: FocuxHubTypography.bodyMuted(color: mute),
                          ),
                  onTap: () {
                    Navigator.of(context).pop();
                    abrirCheckinDoAluno(context, grupo);
                  },
                ),
            ],
            if (_hasNext)
              FxSatelliteListTile(
                title: _loadingMore ? 'Carregando…' : 'Carregar mais',
                onTap: _loadingMore ? null : _carregarMais,
              ),
          ],
        ],
      ),
    );
  }
}
