import 'package:flutter/material.dart';

import '../../../core/theme/tokens_strip.dart';
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
    this.onMaisDoDia,
    this.alertarVazia = true,
  });

  final List<DiaDaSemana> dias;
  final int hoje;
  final bool ocupado;
  final void Function(int treinoId) onAbrir;

  /// Sem [onAdicionar] e [onMais] a semana é só de leitura (tela do modelo).
  final void Function(int dia)? onAdicionar;
  final void Function(int dia, int indice)? onMais;

  /// "…" do dia sem sessão (descanso ou segue a sequência).
  final void Function(int dia)? onMaisDoDia;

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
              segueLabel: dia.segueSequencia ? s.rotinaSegueSequencia : null,
              onAdicionar: ocupado || onAdicionar == null
                  ? null
                  : () => onAdicionar!(dia.dia),
              fimVazio: onMaisDoDia == null
                  ? null
                  : IconButton(
                      tooltip: s.rotinaMaisAcoes,
                      onPressed: ocupado ? null : () => onMaisDoDia!(dia.dia),
                      icon: const Icon(Icons.more_horiz_rounded),
                    ),
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
