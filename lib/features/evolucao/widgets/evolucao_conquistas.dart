import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/media/escolher_foto_de_fundo.dart';
import '../../../core/providers/personal_brand_provider.dart';
import '../../../core/widgets/fx_choice_strip.dart';
import '../../alunos/providers/alunos_provider.dart';

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
import '../../../core/widgets/fx_link_row.dart';

/// Ações do personal na folha da conquista.
class ConquistaAcoes {
  const ConquistaAcoes({required this.onParabenizar, required this.onVer});

  /// Abre o chat do aluno com a mensagem pronta.
  final ValueChanged<Conquista> onParabenizar;

  /// "Ver exercício" (recorde) ou "Ver medida" (meta): a aba com o item.
  final ValueChanged<Conquista> onVer;
}

/// Faixa "Conquistas". Selo só existe depois do feito: sem selo bloqueado.
class EvolucaoConquistas extends StatelessWidget {
  const EvolucaoConquistas({
    super.key,
    required this.conquistas,
    this.compartilhar = false,
    this.acoesDoPersonal,
  });

  final List<Conquista> conquistas;

  /// Só o aluno decide divulgar o próprio resultado.
  final bool compartilhar;

  /// Personal: "Parabenizar" e "Ver …" na folha (antes ela não tinha ação).
  final ConquistaAcoes? acoesDoPersonal;

  @override
  Widget build(BuildContext context) {
    if (conquistas.isEmpty) return const SizedBox.shrink();
    final chrome = ShellChrome.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensStrip.s3),
      child: Column(
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
                          acoes: acoesDoPersonal,
                        ),
                    child: Padding(
                      padding: const EdgeInsets.all(TokensStrip.s3),
                      child: Row(
                        children: [
                          ConquistaSelo(tipo: c.tipo, glifo: conquistaGlifo(c)),
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
      ),
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
  ConquistaAcoes? acoes,
}) => showFxHomeSheet<void>(
  context,
  builder:
      (_) => _FolhaConquista(
        conquista: conquista,
        compartilhar: compartilhar,
        celebrar: celebrar,
        acoes: acoes,
      ),
);

class _FolhaConquista extends ConsumerStatefulWidget {
  const _FolhaConquista({
    required this.conquista,
    required this.compartilhar,
    required this.celebrar,
    this.acoes,
  });

  final Conquista conquista;
  final bool compartilhar;
  final bool celebrar;
  final ConquistaAcoes? acoes;

  @override
  ConsumerState<_FolhaConquista> createState() => _FolhaConquistaState();
}

class _FolhaConquistaState extends ConsumerState<_FolhaConquista> {
  final _cartao = GlobalKey();
  var _enviando = false;
  var _mostrarValor = true;

  /// Fundo "Minha foto": fica só na memória, não sobe para o servidor.
  Uint8List? _foto;
  var _fundoFoto = false;

  Future<void> _escolherFoto() async {
    final foto = await escolherFotoDeFundo(context);
    if (!mounted) return;
    setState(() {
      if (foto != null) _foto = foto;
      _fundoFoto = _foto != null;
    });
  }

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
      final glifo = conquistaGlifo(c);
      return FxSheetFrame(
        title: ptS.conquistaTitulo,
        child: Semantics(
          container: true,
          label: '${c.tipoRotulo}: ${c.detalhe}',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: TokensStrip.s2),
              widget.celebrar
                  ? ConquistaSeloAnimado(
                    tipo: c.tipo,
                    glifo: glifo,
                    tamanho: 160,
                  )
                  : ConquistaSelo(tipo: c.tipo, glifo: glifo, tamanho: 160),
              const SizedBox(height: TokensStrip.s3),
              // O número fica embaixo do selo, no papel de destaque.
              conquistaNumero(c.valor, chrome.ink),
              const SizedBox(height: TokensStrip.s1),
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
              if (widget.acoes case final acoes?) ...[
                const SizedBox(height: TokensStrip.s2),
                FxTonalButton(
                  label: ptS.conquistaParabenizar,
                  icon: FxIcons.chat,
                  expanded: true,
                  onPressed: () {
                    Navigator.pop(context);
                    acoes.onParabenizar(c);
                  },
                ),
                const SizedBox(height: TokensStrip.s2),
                FxLinkRow(
                  label:
                      c.tipo == ConquistaTipo.recorde
                          ? ptS.conquistaVerExercicio
                          : ptS.conquistaVerMedida,
                  onTap: () {
                    Navigator.pop(context);
                    acoes.onVer(c);
                  },
                ),
              ],
            ],
          ),
        ),
      );
    }
    final brand = ref.watch(personalBrandProvider).value;
    final marca = (
      logoUrl: brand?.logoUrl,
      nome: brand?.appDisplayName ?? brand?.nomePersonal,
    );
    final aluno = ref.watch(alunoMeProvider).value?.nome.trim().split(' ').first;
    final alturaPrevia = (MediaQuery.sizeOf(context).height * 0.5).clamp(320.0, 460.0);
    return FxSheetFrame(
      title: ptS.conquistaTitulo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Prévia do cartão; a exportação usa o tamanho cheio (1080 × 1920).
          Center(
            child: SizedBox(
              height: alturaPrevia,
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
                      aluno: aluno,
                      instagram: brand?.instagram,
                      foto: _fundoFoto ? _foto : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: TokensStrip.s3),
          FxChoiceStrip<bool>(
            itens: [
              FxChoiceItem(value: false, label: ptS.conquistaFundoCor),
              FxChoiceItem(value: true, label: ptS.conquistaFundoFoto),
            ],
            selecionado: _fundoFoto,
            onSelecionar: (foto) {
              if (foto && _foto == null) {
                _escolherFoto();
              } else {
                setState(() => _fundoFoto = foto);
              }
            },
          ),
          if (_fundoFoto) ...[
            const SizedBox(height: TokensStrip.s2),
            FxLinkRow(
              label: ptS.conquistaTrocarFoto,
              icon: FxIcons.galeria,
              onTap: _escolherFoto,
            ),
          ],
          const SizedBox(height: TokensStrip.s2),
          MergeSemantics(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    ptS.conquistaMostrarNumero,
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
