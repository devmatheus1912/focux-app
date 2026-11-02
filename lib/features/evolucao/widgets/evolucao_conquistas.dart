import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_sheet_frame.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../l10n/pt.dart';
import '../data/meta_corporal.dart';

IconData _icone(ConquistaTipo tipo) => switch (tipo) {
  ConquistaTipo.meta => Icons.flag_rounded,
  ConquistaTipo.mantido => Icons.verified_rounded,
  ConquistaTipo.recorde => Icons.emoji_events_rounded,
};

/// Medalha na cor da marca.
class ConquistaMedalha extends StatelessWidget {
  const ConquistaMedalha({super.key, required this.tipo, this.tamanho = 56});

  final ConquistaTipo tipo;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      width: tamanho,
      height: tamanho,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
      child: Icon(
        _icone(tipo),
        color: Theme.of(context).colorScheme.onPrimary,
        size: tamanho * 0.5,
      ),
    );
  }
}

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
        SizedBox(
          height: 148,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: conquistas.length,
            separatorBuilder: (_, __) => const SizedBox(width: TokensStrip.s2),
            itemBuilder: (context, i) {
              final c = conquistas[i];
              return Semantics(
                button: true,
                label: '${c.titulo}, ${c.detalhe}',
                excludeSemantics: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(TokensStrip.rCard),
                  onTap:
                      () => mostrarConquista(
                        context,
                        c,
                        compartilhar: compartilhar,
                      ),
                  child: Container(
                    width: 132,
                    padding: const EdgeInsets.all(TokensStrip.s2),
                    decoration: fxListCardDecoration(context),
                    child: Column(
                      children: [
                        ConquistaMedalha(tipo: c.tipo, tamanho: 48),
                        const SizedBox(height: TokensStrip.s1),
                        Text(
                          c.titulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: FocuxHubTypography.cardTitle(color: chrome.ink),
                        ),
                        Text(
                          c.detalhe,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: FocuxHubTypography.chip(chrome.mute),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Detalhe da conquista; serve também de celebração.
Future<void> mostrarConquista(
  BuildContext context,
  Conquista conquista, {
  bool compartilhar = false,
}) => showFxHomeSheet<void>(
  context,
  builder: (_) => _FolhaConquista(conquista: conquista, compartilhar: compartilhar),
);

class _FolhaConquista extends StatefulWidget {
  const _FolhaConquista({required this.conquista, required this.compartilhar});

  final Conquista conquista;
  final bool compartilhar;

  @override
  State<_FolhaConquista> createState() => _FolhaConquistaState();
}

class _FolhaConquistaState extends State<_FolhaConquista> {
  final _imagem = GlobalKey();
  var _enviando = false;

  Future<void> _compartilhar() async {
    if (_enviando) return;
    setState(() => _enviando = true);
    try {
      final limite =
          _imagem.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final imagem = await limite.toImage(pixelRatio: 3);
      final bytes = await imagem.toByteData(format: ui.ImageByteFormat.png);
      final pasta = await getTemporaryDirectory();
      final arquivo = File('${pasta.path}/conquista.png');
      await arquivo.writeAsBytes(bytes!.buffer.asUint8List());
      await SharePlus.instance.share(ShareParams(files: [XFile(arquivo.path)]));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final c = widget.conquista;
    return FxSheetFrame(
      title: ptS.conquistaTitulo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          RepaintBoundary(
            key: _imagem,
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(TokensStrip.s4),
                child: Column(
                  children: [
                    ConquistaMedalha(tipo: c.tipo, tamanho: 88),
                    const SizedBox(height: TokensStrip.s3),
                    Text(
                      c.titulo,
                      textAlign: TextAlign.center,
                      style: FocuxHubTypography.metric(
                        color: chrome.ink,
                        fontSize: 30,
                      ),
                    ),
                    const SizedBox(height: TokensStrip.s1),
                    Text(
                      c.detalhe,
                      textAlign: TextAlign.center,
                      style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (widget.compartilhar) ...[
            const SizedBox(height: TokensStrip.s3),
            FxTonalButton(
              label: ptS.conquistaCompartilhar,
              icon: Icons.ios_share_rounded,
              expanded: true,
              onPressed: _enviando ? null : _compartilhar,
            ),
          ],
        ],
      ),
    );
  }
}
