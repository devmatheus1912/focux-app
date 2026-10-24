import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_choice_strip.dart';
import '../../../core/widgets/fx_day_row.dart';
import '../../../core/widgets/fx_status_pill.dart';
import '../../../l10n/app_localizations.dart';
import '../utils/semana_da_fila.dart';
import 'ficha_acoes.dart';

/// Sete linhas, uma por dia da semana. [hoje] segue `DateTime.weekday` (1 a 7).
class FichaSemana extends StatelessWidget {
  const FichaSemana({
    super.key,
    required this.dias,
    required this.hoje,
    required this.ocupado,
    required this.onAdicionar,
    required this.onAbrir,
    required this.onMais,
  });

  final List<DiaDaSemana> dias;
  final int hoje;
  final bool ocupado;
  final void Function(int dia) onAdicionar;
  final void Function(int treinoId) onAbrir;
  final void Function(int dia, int indice) onMais;

  String? _detalhe(S s, SessaoDaSemana sessao) =>
      switch (sessao.exerciciosCount) {
        null => s.rotinaSessaoMontar,
        0 => s.rotinaSessaoVazia,
        final n => s.rotinaSessaoExercicios(n),
      };

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final nomes = nomesDosDias(s);
    return Column(
      children: [
        for (final (i, dia) in dias.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: TokensStrip.s2),
            child: FxDayRow(
              dia: nomes[i],
              hoje: dia.dia == hoje,
              hojeLabel: s.treinosSuaSemanaHoje,
              descansoLabel: s.rotinaDescanso,
              adicionarLabel: s.rotinaAdicionarTreino,
              segundoTreinoLabel: s.rotinaSegundoTreino,
              onAdicionar: ocupado ? null : () => onAdicionar(dia.dia),
              sessoes: [
                for (final (j, sessao) in dia.sessoes.indexed)
                  FxDaySession(
                    nome: sessao.nome,
                    detalhe: _detalhe(s, sessao),
                    onTap: ocupado || sessao.treinoId == null
                        ? null
                        : () => onAbrir(sessao.treinoId!),
                    fim: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (sessao.exerciciosCount == 0)
                          FxStatusPill(
                            label: s.rotinaMontar,
                            tone: FxPillTone.warning,
                          ),
                        IconButton(
                          tooltip: s.rotinaMaisAcoes,
                          onPressed: ocupado ? null : () => onMais(dia.dia, j),
                          icon: const Icon(Icons.more_horiz_rounded),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Ficha vazia: pergunta de quantos dias, com chips que não esticam.
class FichaFrequencia extends StatelessWidget {
  const FichaFrequencia({super.key, required this.ocupado, required this.onEscolher});

  final bool ocupado;
  final ValueChanged<int> onEscolher;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensStrip.s4),
      child: DecoratedBox(
        decoration: chrome.panel(radius: 20),
        child: Padding(
          padding: const EdgeInsets.all(TokensStrip.s3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.rotinaFrequenciaTitulo,
                style: FocuxHubTypography.cardTitle(color: chrome.ink),
              ),
              const SizedBox(height: TokensStrip.s1),
              Text(
                s.rotinaFrequenciaDica,
                style: FocuxHubTypography.bodyMuted(color: chrome.mute),
              ),
              const SizedBox(height: TokensStrip.s2),
              IgnorePointer(
                ignoring: ocupado,
                child: FxChoiceStrip<int>(
                  quebrar: true,
                  itens: [
                    for (final n in const [2, 3, 4, 5, 6, 7])
                      FxChoiceItem(value: n, label: '$n'),
                  ],
                  selecionado: null,
                  onSelecionar: onEscolher,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
