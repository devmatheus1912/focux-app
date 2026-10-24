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
    required this.onAbrir,
    this.onAdicionar,
    this.onMais,
    this.alertarVazia = true,
  });

  final List<DiaDaSemana> dias;
  final int hoje;
  final bool ocupado;
  final void Function(int treinoId) onAbrir;

  /// Sem [onAdicionar] e [onMais] a semana é só de leitura (tela do modelo).
  final void Function(int dia)? onAdicionar;
  final void Function(int dia, int indice)? onMais;

  /// Sessão sem exercício ganha o selo "Montar". Fica desligado onde não dá para montar.
  final bool alertarVazia;

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
              onAdicionar: ocupado || onAdicionar == null
                  ? null
                  : () => onAdicionar!(dia.dia),
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
                        if (alertarVazia && sessao.exerciciosCount == 0)
                          FxStatusPill(
                            label: s.rotinaMontar,
                            tone: FxPillTone.warning,
                          ),
                        if (onMais != null)
                          IconButton(
                            tooltip: s.rotinaMaisAcoes,
                            onPressed: ocupado ? null : () => onMais!(dia.dia, j),
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

/// Ficha vazia: quantos dias por semana e por quanto tempo a ficha vale.
/// [onEscolher] recebe os dias e as semanas de vigência (nulo = sem prazo).
class FichaFrequencia extends StatefulWidget {
  const FichaFrequencia({super.key, required this.ocupado, required this.onEscolher});

  final bool ocupado;
  final void Function(int dias, int? semanas) onEscolher;

  @override
  State<FichaFrequencia> createState() => _FichaFrequenciaState();
}

class _FichaFrequenciaState extends State<FichaFrequencia> {
  /// 0 = sem prazo.
  var _semanas = 8;

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
                s.valePorTitulo,
                style: FocuxHubTypography.cardTitle(color: chrome.ink),
              ),
              const SizedBox(height: TokensStrip.s1),
              FxChoiceStrip<int>(
                quebrar: true,
                itens: [
                  for (final n in const [4, 8, 12])
                    FxChoiceItem(value: n, label: s.valePorSemanas(n)),
                  FxChoiceItem(value: 0, label: s.vigenciaSemPrazo),
                ],
                selecionado: _semanas,
                onSelecionar: (n) => setState(() => _semanas = n),
              ),
              const SizedBox(height: TokensStrip.s3),
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
                ignoring: widget.ocupado,
                child: FxChoiceStrip<int>(
                  quebrar: true,
                  itens: [
                    for (final n in const [2, 3, 4, 5, 6, 7])
                      FxChoiceItem(value: n, label: '$n'),
                  ],
                  selecionado: null,
                  onSelecionar: (dias) =>
                      widget.onEscolher(dias, _semanas == 0 ? null : _semanas),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
