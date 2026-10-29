import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../l10n/app_localizations.dart';
import '../../treinos/models/rotina_fila.dart';
import '../../treinos/utils/semana_da_fila.dart';
import 'ficha_vigencia_aluno.dart';
import '../data/checkin_repository.dart';
import '../utils/semana_prevista.dart';
import '../utils/treinos_hub_view.dart';
import 'treinos_hub_rows.dart';

/// Uma linha por dia da ficha: o que o aluno treina e o dia de hoje em destaque.
class SuaSemanaRow extends StatelessWidget {
  const SuaSemanaRow({
    super.key,
    required this.diaNome,
    required this.dia,
    required this.hoje,
    this.status,
    this.previsto,
  });

  final String diaNome;
  final DiaDaSemana dia;
  final bool hoje;

  /// Nome previsto pela fila para um dia que segue a sequência.
  final String? previsto;

  /// `true` feito, `false` não feito (dia que já passou); nulo sem marcação.
  final bool? status;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final nomes =
        dia.sessoes
            .map((sessao) => sessao.nome.trim())
            .where((nome) => nome.isNotEmpty)
            .toList();
    final segue = nomes.isEmpty && dia.segueSequencia;
    final descanso = nomes.isEmpty && !segue;
    final texto = segue
        ? (previsto?.isNotEmpty == true ? s.treinosSemanaProxima(previsto!) : s.rotinaSegueSequencia)
        : descanso
        ? s.rotinaDescanso
        : nomes.join(' · ');
    final peso = hoje ? FontWeight.w700 : FontWeight.w500;
    final cor =
        descanso
            ? theme.colorScheme.onSurfaceVariant
            : theme.colorScheme.onSurface;

    final marca = switch (status) {
      true => s.treinosSemanaFeito,
      false => s.treinosSemanaNaoFeito,
      null => null,
    };
    return Semantics(
      label:
          '$diaNome, $texto'
          '${hoje ? ', ${s.treinosSuaSemanaHoje}' : ''}'
          '${marca == null ? '' : ', $marca'}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: TokensStrip.s3,
          vertical: TokensStrip.s2,
        ),
        decoration:
            hoje
                ? BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                )
                : null,
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: Text(
                diaNome,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: peso,
                  color: cor,
                ),
              ),
            ),
            Expanded(
              child: Text(
                texto,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: peso,
                  color: cor,
                ),
              ),
            ),
            if (status != null) ...[
              Icon(
                status! ? Icons.check_circle_rounded : Icons.remove_rounded,
                size: 18,
                color:
                    status!
                        ? EagleTokens.good
                        : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: TokensStrip.s2),
            ],
            if (hoje)
              Text(
                s.treinosSuaSemanaHoje,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A ficha (validade) e a lista de segunda a domingo, sempre aberta.
class SuaSemanaBloco extends StatelessWidget {
  const SuaSemanaBloco({
    super.key,
    required this.rotina,
    required this.hoje,
    this.historico = const [],
  });

  final RotinaFila rotina;
  final DateTime hoje;

  final List<ExecucaoTreino> historico;

  /// Dia com treino que já passou: feito ou não feito; hoje só quando feito.
  bool? _statusDoDia(DiaDaSemana dia, Set<int> feitos) {
    if (!dia.segueSequencia && dia.sessoes.every((x) => x.nome.trim().isEmpty)) return null;
    if (feitos.contains(dia.dia)) return true;
    return dia.dia < hoje.weekday ? false : null;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final nomes = [
      s.rotinaDiaSeg,
      s.rotinaDiaTer,
      s.rotinaDiaQua,
      s.rotinaDiaQui,
      s.rotinaDiaSex,
      s.rotinaDiaSab,
      s.rotinaDiaDom,
    ];
    final dias = semanaDaFila(rotina);
    final agora = hoje;
    final feitos = diasFeitosNaSemana(historico, hoje);
    final previstos = nomesPrevistosDaSemana(rotina: rotina, historico: historico, hoje: hoje);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (temAvisoDaFicha(rotina, agora))
          Padding(
            padding: const EdgeInsets.only(bottom: TokensStrip.s2),
            child: FichaVigenciaAluno(rotina: rotina, hoje: agora),
          ),
        TreinosHubSecao(
          titulo: s.treinosSuaSemana,
          linhas: [
            for (final (i, dia) in dias.indexed)
              SuaSemanaRow(
                diaNome: nomes[i],
                dia: dia,
                hoje: dia.dia == hoje.weekday,
                status: _statusDoDia(dia, feitos),
                previsto: previstos[dia.dia],
              ),
          ],
        ),
      ],
    );
  }
}
