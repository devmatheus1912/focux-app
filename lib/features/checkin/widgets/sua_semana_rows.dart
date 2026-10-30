import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../l10n/app_localizations.dart';
import '../../treinos/models/rotina_fila.dart';
import '../../treinos/utils/ficha_vigencia.dart';
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
    this.feitoExtra,
    this.feitosNoDia = const [],
    this.acao,
    this.onAbrir,
  });

  final String diaNome;
  final DiaDaSemana dia;
  final bool hoje;

  /// Nome previsto pela fila para um dia que segue a sequência.
  final String? previsto;

  /// `true` feito, `false` não feito (dia que já passou); nulo sem marcação.
  final bool? status;

  /// Treino feito num dia de descanso: aparece no dia em que aconteceu.
  final String? feitoExtra;

  /// Outra sessão feita neste dia: o previsto fica, sem marcar como feito.
  final List<String> feitosNoDia;

  /// Só na linha de hoje: o que fazer agora, sem repetir a Hoje num cartão.
  final Widget? acao;

  /// Abre a prévia da sessão do dia.
  final VoidCallback? onAbrir;

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
    final descanso = nomes.isEmpty && !segue && feitoExtra == null;
    final texto = feitoExtra != null
        ? feitoExtra!
        : segue
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
    final outros = semanaFeitosTexto(s, feitosNoDia, hoje: hoje);
    return Semantics(
      label:
          '$diaNome, $texto'
          '${hoje ? ', ${s.treinosSuaSemanaHoje}' : ''}'
          '${marca == null ? '' : ', $marca'}'
          '${feitoExtra == null ? '' : ', ${s.treinosSemanaExtra}'}'
      '${outros == null ? '' : ', $outros'}',
      button: onAbrir != null,
      excludeSemantics: acao == null,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        alignment: Alignment.center,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: onAbrir,
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
                  if (feitoExtra != null) ...[
                    Text(
                      s.treinosSemanaExtra,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: TokensStrip.s1),
                  ],
                  if (hoje) ...[
                    Text(
                      s.treinosSuaSemanaHoje,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: TokensStrip.s1),
                  ],
                  // Colunas fixas: status e seta alinham em todas as linhas.
                  SizedBox(
                    width: 22,
                    child: status == null
                        ? null
                        : Icon(
                            status! ? Icons.check_circle_rounded : Icons.remove_rounded,
                            size: 18,
                            color:
                                status!
                                    ? EagleTokens.good
                                    : theme.colorScheme.onSurfaceVariant,
                          ),
                  ),
                  SizedBox(
                    width: 20,
                    child: onAbrir == null
                        ? null
                        : Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                  ),
                ],
              ),
            ),
            if (outros != null)
              Padding(
                padding: const EdgeInsets.only(left: 44, top: TokensStrip.s1),
                child: Text(
                  outros,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            if (acao != null) ...[
              const SizedBox(height: TokensStrip.s2),
              acao!,
            ],
          ],
        ),
      ),
    );
  }
}

/// "Feito hoje: A · Peito", até dois nomes e "+N". Nulo sem nada feito.
String? semanaFeitosTexto(S s, List<String> nomes, {required bool hoje}) {
  if (nomes.isEmpty) return null;
  final vistos = nomes.take(2).join(' · ');
  final resto = nomes.length - 2;
  final texto = resto > 0 ? '$vistos ${s.treinosFeitosMais(resto)}' : vistos;
  return hoje ? s.treinosFeitoHoje(texto) : s.treinosFeitoNoDia(texto);
}

/// A ficha (validade) e a lista de segunda a domingo, sempre aberta.
class SuaSemanaBloco extends StatelessWidget {
  const SuaSemanaBloco({
    super.key,
    required this.rotina,
    required this.hoje,
    this.historico = const [],
    this.acaoDeHoje,
    this.onAbrirSessao,
  });

  final RotinaFila rotina;
  final DateTime hoje;

  final List<ExecucaoTreino> historico;

  /// Vai dentro da linha de hoje.
  final Widget? acaoDeHoje;

  /// Abre a prévia; nulo se o aluno não tem esse treino.
  final VoidCallback? Function(int treinoId)? onAbrirSessao;

  /// Dia com treino que já passou: feito ou não feito; hoje só quando feito.
  /// Sessão feita em outro dia da semana também conta (faltar não pula a letra).
  bool? _statusDoDia(DiaDaSemana dia, Map<int, List<FeitoDoDia>> feitos) {
    final semPrevisto = dia.sessoes.every((x) => x.nome.trim().isEmpty);
    if (semPrevisto && feitos.containsKey(dia.dia)) return true;
    if (_descanso(dia)) return null;
    final ids = {
      for (final doDia in feitos.values)
        for (final f in doDia) f.treinoId,
    };
    if (dia.sessoes.any((x) => ids.contains(x.treinoId))) return true;
    return dia.dia < hoje.weekday ? false : null;
  }

  /// Sessões feitas no dia que não são a prevista para ele.
  List<String> _outrosDoDia(DiaDaSemana dia, Map<int, List<FeitoDoDia>> feitos) {
    if (dia.sessoes.every((x) => x.nome.trim().isEmpty)) return const [];
    final previstos = dia.sessoes.map((x) => x.treinoId).toSet();
    return [
      for (final f in feitos[dia.dia] ?? const <FeitoDoDia>[])
        if (!previstos.contains(f.treinoId)) f.nome,
    ];
  }

  bool _descanso(DiaDaSemana dia) =>
      !dia.segueSequencia && dia.sessoes.every((x) => x.nome.trim().isEmpty);

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
    final feitos = feitosDaSemana(historico, hoje);
    final previstos = nomesPrevistosDaSemana(rotina: rotina, historico: historico, hoje: hoje);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (temAvisoDaFicha(rotina, agora))
          Padding(
            padding: const EdgeInsets.only(bottom: TokensStrip.s2),
            child: FichaVigenciaAluno(
              rotina: rotina,
              hoje: agora,
              prazoNoTitulo: true,
            ),
          ),
        TreinosHubSecao(
          titulo: rotina.vigencia.estado(agora) == EstadoVigencia.emDia
              ? s.treinosSuaSemanaAte(dataCurta(rotina.vigencia.fim!))
              : s.treinosSuaSemana,
          linhas: [
            for (final (i, dia) in dias.indexed) ...[
              if (i > 0) const Divider(height: 1, indent: TokensStrip.s3, endIndent: TokensStrip.s3),
              SuaSemanaRow(
                diaNome: nomes[i],
                dia: dia,
                hoje: dia.dia == hoje.weekday,
                status: _statusDoDia(dia, feitos),
                previsto: previstos[dia.dia],
                feitoExtra: _descanso(dia)
                    ? feitos[dia.dia]?.map((f) => f.nome).join(' · ')
                    : null,
                feitosNoDia: _outrosDoDia(dia, feitos),
                acao: dia.dia == hoje.weekday ? acaoDeHoje : null,
                onAbrir: dia.sessoes.isEmpty || dia.sessoes.first.treinoId == null
                    ? null
                    : onAbrirSessao?.call(dia.sessoes.first.treinoId!),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
