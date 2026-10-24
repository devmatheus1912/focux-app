import 'package:flutter/material.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../l10n/app_localizations.dart';
import '../../treinos/utils/semana_da_fila.dart';

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
