import 'package:flutter/material.dart';

import '../theme/focux_hub_typography.dart';
import '../theme/shell_chrome.dart';
import '../theme/tokens_strip.dart';
import 'fx_tap_row.dart';

class FxDaySession {
  const FxDaySession({
    required this.nome,
    this.detalhe,
    this.fim,
    this.onTap,
  });

  final String nome;
  final String? detalhe;

  /// Selo ou ícone no fim (ex.: "Montar" quando a sessão está vazia).
  final Widget? fim;
  final VoidCallback? onTap;
}

/// Uma linha por dia da ficha: coluna do dia + uma linha por sessão.
/// Dia sem sessão vira uma linha pontilhada de "Adicionar" ou de descanso.
class FxDayRow extends StatelessWidget {
  const FxDayRow({
    super.key,
    required this.dia,
    required this.sessoes,
    required this.descansoLabel,
    required this.adicionarLabel,
    required this.segundoTreinoLabel,
    this.hoje = false,
    this.hojeLabel,
    this.onAdicionar,
  });

  final String dia;
  final List<FxDaySession> sessoes;
  final String descansoLabel;
  final String adicionarLabel;
  final String segundoTreinoLabel;
  final bool hoje;
  final String? hojeLabel;
  final VoidCallback? onAdicionar;

  static const double colunaDia = 44;

  String? _detalhe(int indice, FxDaySession sessao) {
    final partes = [
      if (indice > 0) segundoTreinoLabel,
      if (sessao.detalhe != null) sessao.detalhe!,
    ];
    return partes.isEmpty ? null : partes.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: colunaDia,
          child: Padding(
            padding: const EdgeInsets.only(top: TokensStrip.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dia,
                  style: FocuxHubTypography.cardTitle(
                    color: hoje ? chrome.brand : chrome.ink,
                  ),
                ),
                if (hoje && hojeLabel != null)
                  Text(
                    hojeLabel!,
                    style: FocuxHubTypography.chip(chrome.brand),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (sessoes.isEmpty)
                FxTapRow(
                  title: onAdicionar == null ? descansoLabel : adicionarLabel,
                  subtitle: onAdicionar == null ? null : descansoLabel,
                  vazio: true,
                  onTap: onAdicionar,
                )
              else
                for (final (i, sessao) in sessoes.indexed) ...[
                  if (i > 0) const SizedBox(height: TokensStrip.s1),
                  FxTapRow(
                    title: sessao.nome,
                    subtitle: _detalhe(i, sessao),
                    trailing: sessao.fim,
                    onTap: sessao.onTap,
                  ),
                ],
            ],
          ),
        ),
      ],
    );
  }
}
