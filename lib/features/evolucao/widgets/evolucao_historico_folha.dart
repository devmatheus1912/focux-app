import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../l10n/pt.dart';
import '../utils/evolucao_display.dart';
import '../../../core/theme/fx_icons.dart';

/// Folha "Histórico": um bloco por mês, uma linha por data. As datas em
/// [destaque] (o par que pede "Confira") vêm marcadas. Devolve o registro
/// tocado; [podeAbrir] decide quais linhas respondem ao toque.
Future<RegistroDoHistorico?> abrirHistoricoDaEvolucao(
  BuildContext context, {
  required List<RegistroDoHistorico> registros,
  Set<String> destaque = const {},
  bool Function(RegistroDoHistorico)? podeAbrir,
}) => showFxHomeSheet<RegistroDoHistorico>(
  context,
  builder:
      (_) => _FolhaHistorico(
        registros: registros,
        destaque: destaque,
        podeAbrir: podeAbrir ?? (_) => false,
      ),
);

class _FolhaHistorico extends StatelessWidget {
  const _FolhaHistorico({
    required this.registros,
    required this.destaque,
    required this.podeAbrir,
  });

  final List<RegistroDoHistorico> registros;
  final Set<String> destaque;
  final bool Function(RegistroDoHistorico) podeAbrir;

  static String _mes(String data) {
    final d = DateTime.tryParse(data);
    return d == null ? data : evolucaoMesAno(d);
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final porMes = <String, List<RegistroDoHistorico>>{};
    for (final r in registros) {
      porMes.putIfAbsent(_mes(r.data), () => []).add(r);
    }
    return FxHomeSheetSurface(
      isDark: chrome.isDark,
      maxHeight:
          MediaQuery.sizeOf(context).height * FxHomeSheetChrome.maxHeightFactor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FxHomeSheetHandle(isDark: chrome.isDark),
          const SizedBox(height: TokensStrip.s3),
          FxHomeSheetHeader(
            isDark: chrome.isDark,
            title: ptS.evolucaoHistoricoTitulo,
          ),
          const SizedBox(height: TokensStrip.s2),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final MapEntry(key: mes, value: doMes) in porMes.entries) ...[
                  Padding(
                    padding: const EdgeInsets.only(
                      top: TokensStrip.s2,
                      bottom: TokensStrip.s1,
                    ),
                    child: Text(mes, style: FocuxHubTypography.chip(chrome.mute)),
                  ),
                  // Lista agrupada: um cartão por mês, linhas com divisor.
                  Container(
                    decoration: fxListCardDecoration(context),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (final (i, r) in doMes.indexed) ...[
                          if (i > 0) Divider(height: 1, color: chrome.line),
                          _Linha(
                            registro: r,
                            destacada: destaque.contains(r.data),
                            onTap:
                                podeAbrir(r)
                                    ? () => Navigator.of(context).pop(r)
                                    : null,
                          ),
                        ],
                      ],
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

class _Linha extends StatelessWidget {
  const _Linha({required this.registro, required this.destacada, this.onTap});

  final RegistroDoHistorico registro;
  final bool destacada;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final alerta = chrome.isDark ? EagleTokens.warnDark : EagleTokens.warn;
    final autor = evolucaoAutorLabel(registro.medida?.registradoPor);
    final titulo = evolucaoRegistroLabel(registro);
    final detalhe = evolucaoRegistroSubtitle(registro);
    return Semantics(
      button: onTap != null,
      label: [
        titulo,
        detalhe,
        if (autor != null) autor,
        if (destacada) ptS.comparacaoConfira,
      ].join(', '),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: destacada ? alerta.withValues(alpha: 0.08) : null,
          padding: const EdgeInsets.all(TokensStrip.s3),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          titulo,
                          style: FocuxHubTypography.cardTitle(color: chrome.ink),
                        ),
                        if (destacada) ...[
                          const SizedBox(width: TokensStrip.s2),
                          Icon(FxIcons.alertaPequeno, size: 14, color: alerta),
                          const SizedBox(width: 2),
                          Text(
                            ptS.comparacaoConfira,
                            style: FocuxHubTypography.chip(alerta),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      detalhe,
                      style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                    ),
                    if (autor != null)
                      Text(autor, style: FocuxHubTypography.chip(chrome.mute)),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(FxIcons.chevronDireita, color: chrome.mute),
            ],
          ),
        ),
      ),
    );
  }
}
