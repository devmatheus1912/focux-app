import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/personal_brand_provider.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_sheet_frame.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../l10n/pt.dart';
import '../data/meta_corporal.dart';
import 'conquista_cartao.dart';
import 'conquista_selo.dart';
import '../../../core/theme/fx_icons.dart';

/// Faixa "Conquistas". Selo só existe depois do feito: sem selo bloqueado.
class EvolucaoConquistas extends StatelessWidget {
  const EvolucaoConquistas({
    super.key,
    required this.conquistas,
    this.compartilhar = false,
  });

  final List<Conquista> conquistas;

  /// Só o aluno decide divulgar o próprio resultado.
  final bool compartilhar;

  @override
  Widget build(BuildContext context) {
    if (conquistas.isEmpty) return const SizedBox.shrink();
    final chrome = ShellChrome.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          ptS.conquistasTitulo,
          style: FocuxHubTypography.cardTitle(color: chrome.ink),
        ),
        const SizedBox(height: TokensStrip.s2),
        // Linhas na largura toda: o detalhe ("de 100,0 kg para 110,0 kg em 2
        // dias") cabe inteiro, sem cartão de meia largura cortando a frase.
        Container(
          decoration: fxListCardDecoration(context),
          child: Column(
            children: [
              for (final (i, c) in conquistas.indexed) ...[
                if (i > 0) Divider(height: 1, color: chrome.line),
                Semantics(
                  button: true,
                  label: '${c.titulo}, ${c.detalhe}',
                  excludeSemantics: true,
                  child: InkWell(
                    onTap:
                        () => mostrarConquista(
                          context,
                          c,
                          compartilhar: compartilhar,
                        ),
                    child: Padding(
                      padding: const EdgeInsets.all(TokensStrip.s3),
                      child: Row(
                        children: [
                          ConquistaSelo(tipo: c.tipo),
                          const SizedBox(width: TokensStrip.s3),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.titulo,
                                  style: FocuxHubTypography.cardTitle(
                                    color: chrome.ink,
                                  ),
                                ),
                                Text(
                                  c.detalhe,
                                  style: FocuxHubTypography.bodyMuted(
                                    color: chrome.mute,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(FxIcons.chevronDireita, color: chrome.mute),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Detalhe da conquista; serve também de celebração ([celebrar]: o anel se
/// desenha). Com [compartilhar], mostra o cartão de story e a opção de
/// esconder o valor.
Future<void> mostrarConquista(
  BuildContext context,
  Conquista conquista, {
  bool compartilhar = false,
  bool celebrar = false,
}) => showFxHomeSheet<void>(
  context,
  builder:
      (_) => _FolhaConquista(
        conquista: conquista,
        compartilhar: compartilhar,
        celebrar: celebrar,
      ),
);

class _FolhaConquista extends ConsumerStatefulWidget {
  const _FolhaConquista({
    required this.conquista,
    required this.compartilhar,
    required this.celebrar,
  });

  final Conquista conquista;
  final bool compartilhar;
  final bool celebrar;

  @override
  ConsumerState<_FolhaConquista> createState() => _FolhaConquistaState();
}

class _FolhaConquistaState extends ConsumerState<_FolhaConquista> {
  final _cartao = GlobalKey();
  var _enviando = false;
  var _mostrarValor = true;

  Future<void> _compartilhar() async {
    if (_enviando) return;
    setState(() => _enviando = true);
    try {
      await compartilharCartao(_cartao);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final c = widget.conquista;
    if (!widget.compartilhar) {
      final numero = conquistaNumero(c.valor, chrome.ink);
      return FxSheetFrame(
        title: ptS.conquistaTitulo,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: TokensStrip.s2),
            widget.celebrar
                ? ConquistaSeloAnimado(tipo: c.tipo, tamanho: 120, miolo: numero)
                : ConquistaSelo(tipo: c.tipo, tamanho: 120, miolo: numero),
            const SizedBox(height: TokensStrip.s3),
            Text(
              c.tipoRotulo,
              textAlign: TextAlign.center,
              style: FocuxHubTypography.cardTitle(color: chrome.ink),
            ),
            const SizedBox(height: TokensStrip.s1),
            Text(
              c.detalhe,
              textAlign: TextAlign.center,
              style: FocuxHubTypography.bodyMuted(color: chrome.mute),
            ),
            const SizedBox(height: TokensStrip.s2),
          ],
        ),
      );
    }
    final brand = ref.watch(personalBrandProvider).value;
    final marca = (logoUrl: brand?.logoUrl, nome: brand?.appDisplayName ?? brand?.nomePersonal);
    return FxSheetFrame(
      title: ptS.conquistaTitulo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Prévia do cartão; a exportação usa o tamanho cheio (1080 × 1920).
          Center(
            child: SizedBox(
              height: 360,
              child: FittedBox(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(TokensStrip.rCard * 3),
                  child: RepaintBoundary(
                    key: _cartao,
                    child: ConquistaCartao(
                      conquista: c,
                      mostrarValor: _mostrarValor,
                      marca: marca,
                      animar: widget.celebrar,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: TokensStrip.s2),
          MergeSemantics(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    ptS.conquistaMostrarValor,
                    style: FocuxHubTypography.body(color: chrome.ink),
                  ),
                ),
                Switch.adaptive(
                  value: _mostrarValor,
                  onChanged: (v) => setState(() => _mostrarValor = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: TokensStrip.s2),
          FxTonalButton(
            label: ptS.conquistaCompartilhar,
            icon: FxIcons.compartilhar,
            expanded: true,
            onPressed: _enviando ? null : _compartilhar,
          ),
        ],
      ),
    );
  }
}
