import 'package:flutter/material.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../l10n/app_localizations.dart';
import '../../treinos/models/rotina_fila.dart';
import '../../treinos/utils/semana_da_fila.dart';
import 'ficha_vigencia_aluno.dart';
import 'treinos_hub_rows.dart';

/// Uma linha por dia da ficha: o que o aluno treina e o dia de hoje em destaque.
class SuaSemanaRow extends StatelessWidget {
  const SuaSemanaRow({
    super.key,
    required this.diaNome,
    required this.dia,
    required this.hoje,
  });

  final String diaNome;
  final DiaDaSemana dia;
  final bool hoje;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final nomes = dia.sessoes
        .map((sessao) => sessao.nome.trim())
        .where((nome) => nome.isNotEmpty)
        .toList();
    final descanso = nomes.isEmpty;
    final peso = hoje ? FontWeight.w700 : FontWeight.w500;
    final cor = descanso
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.onSurface;

    return Semantics(
      label: '$diaNome, ${descanso ? s.rotinaDescanso : nomes.join(', ')}'
          '${hoje ? ', ${s.treinosSuaSemanaHoje}' : ''}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: TokensStrip.s3,
          vertical: TokensStrip.s2,
        ),
        decoration: hoje
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
                descanso ? s.rotinaDescanso : nomes.join(' · '),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: peso,
                  color: cor,
                ),
              ),
            ),
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
  const SuaSemanaBloco({super.key, required this.rotina, required this.hoje});

  final RotinaFila rotina;
  final DateTime hoje;

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
              ),
          ],
        ),
      ],
    );
  }
}
