import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_icons.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_toggle_chip.dart';
import '../data/feed_repository.dart';
import '../utils/feed_display.dart';

/// Lista do feed (personal e aluno): bloco "Fixado" no topo e o resto do
/// mais novo ao mais antigo. Com filtro, a ordem que o servidor mandou.
class FeedLista extends StatelessWidget {
  const FeedLista({
    super.key,
    required this.posts,
    required this.filtrando,
    required this.cartao,
    required this.onRefresh,
    required this.hasMore,
    required this.loadingMore,
    required this.onCarregarMais,
    this.bottomPad = TokensStrip.s4,
  });

  final List<FeedPost> posts;
  final bool filtrando;
  final Widget Function(FeedPost post, int index) cartao;
  final Future<void> Function() onRefresh;
  final bool hasMore;
  final bool loadingMore;
  final VoidCallback onCarregarMais;
  final double bottomPad;

  @override
  Widget build(BuildContext context) {
    final mute = ShellChrome.of(context).mute;
    final grupos = feedSepararFixados(posts, filtrando: filtrando);
    final itens = <Widget>[];
    var i = 0;
    if (grupos.fixados.isNotEmpty) {
      itens.add(_Rotulo('Fixado', mute));
      for (final p in grupos.fixados) {
        itens.add(cartao(p, i++));
      }
      if (grupos.outros.isNotEmpty) itens.add(_Rotulo('Publicações', mute));
    }
    for (final p in grupos.outros) {
      itens.add(cartao(p, i++));
    }
    if (hasMore) {
      itens.add(
        FxSatelliteListTile(
          title: loadingMore ? 'Carregando…' : 'Carregar mais',
          onTap: loadingMore ? null : onCarregarMais,
        ),
      );
    }
    return RefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          TokensStrip.s2,
          FxSettingsLayout.pageInset,
          bottomPad + MediaQuery.viewInsetsOf(context).bottom,
        ),
        children: itens,
      ),
    );
  }
}

class _Rotulo extends StatelessWidget {
  const _Rotulo(this.texto, this.cor);

  final String texto;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: TokensStrip.s1,
        top: TokensStrip.s1,
        bottom: TokensStrip.s2,
      ),
      child: Text(texto, style: FocuxHubTypography.chip(cor)),
    );
  }
}

/// Busca e filtros (Todas, Fixados, Fotos, Vídeos, Dicas), só com 5 posts
/// ou mais, ou com um filtro ativo.
class FeedFiltros extends StatelessWidget {
  const FeedFiltros({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.query,
    required this.chip,
    required this.onQuery,
    required this.onLimparBusca,
    required this.onChip,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String query;
  final FeedListChip chip;
  final ValueChanged<String> onQuery;
  final VoidCallback onLimparBusca;
  final ValueChanged<FeedListChip> onChip;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            TokensStrip.s4,
            TokensStrip.s2,
            TokensStrip.s4,
            TokensStrip.s2,
          ),
          child: DecoratedBox(
            decoration: fxStripCardDecoration(
              context,
              accent: primary,
              radius: TokensStrip.rCard,
              glowStrength: 0.03,
            ),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onQuery,
              onTapOutside: (_) => FxKeyboardDismissScope.dismiss(),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                filled: false,
                isDense: true,
                hintText: 'Buscar publicação',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                prefixIcon: Icon(FxIcons.buscar, color: primary, size: 20),
                suffixIcon:
                    query.trim().isEmpty
                        ? null
                        : IconButton(
                          tooltip: 'Limpar busca',
                          onPressed: onLimparBusca,
                          icon: Icon(
                            FxIcons.fechar,
                            color: chrome.mute,
                            size: 18,
                          ),
                        ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            TokensStrip.s4,
            0,
            TokensStrip.s4,
            TokensStrip.s2,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final c in FeedListChip.values)
                    Padding(
                      padding: const EdgeInsets.only(right: TokensStrip.s2),
                      child: FxToggleChip(
                        label: feedListChipLabel(c),
                        selected: chip == c,
                        isDark: chrome.isDark,
                        filledWhenSelected: true,
                        onTap: () {
                          if (chip != c) onChip(c);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
