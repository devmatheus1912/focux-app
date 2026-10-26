import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/design_tokens.dart';
import '../theme/focux_hub_typography.dart';
import '../theme/shell_chrome.dart';
import '../theme/tokens_strip.dart';

enum FxWeekDayState { treino, descanso, concluido }

/// Um dia da faixa. `dia`: 1 = segunda … 7 = domingo.
class FxWeekDay {
  const FxWeekDay({
    required this.dia,
    required this.estado,
    this.hoje = false,
    this.proximo = false,
  });

  final int dia;
  final FxWeekDayState estado;
  final bool hoje;

  /// Próximo dia de treino, só quando hoje não é dia de treino.
  final bool proximo;
}

/// Os sete dias da semana em uma linha: treino cheio, concluído com marca,
/// descanso apagado, hoje com anel e o próximo treino com contorno.
class FxWeekStrip extends StatelessWidget {
  const FxWeekStrip({super.key, required this.dias});

  final List<FxWeekDay> dias;

  static List<String> nomes(S s) => [
    s.rotinaDiaSeg,
    s.rotinaDiaTer,
    s.rotinaDiaQua,
    s.rotinaDiaQui,
    s.rotinaDiaSex,
    s.rotinaDiaSab,
    s.rotinaDiaDom,
  ];

  /// Leitura em voz alta: "Seg: treino. Qua: treino, Hoje. …".
  static String semantica(S s, List<FxWeekDay> dias) {
    final n = nomes(s);
    String estado(FxWeekDay d) => switch (d.estado) {
      FxWeekDayState.concluido => s.alunoSemanaFaixaConcluido,
      FxWeekDayState.treino => s.alunoSemanaFaixaTreino,
      FxWeekDayState.descanso => s.alunoSemanaFaixaDescanso,
    };
    return [
      for (final (i, d) in dias.indexed)
        [
          '${n[i]}: ${estado(d)}',
          if (d.hoje) s.treinosSuaSemanaHoje,
          if (d.proximo) s.alunoSemanaFaixaProximo,
        ].join(', '),
    ].join('. ');
  }

  @override
  Widget build(BuildContext context) {
    if (dias.isEmpty) return const SizedBox.shrink();
    final n = nomes(S.of(context));
    final chrome = ShellChrome.of(context);
    return Row(
      children: [
        for (final (i, d) in dias.indexed)
          Expanded(child: _Dia(nome: n[i], dia: d, chrome: chrome)),
      ],
    );
  }
}

class _Dia extends StatelessWidget {
  const _Dia({required this.nome, required this.dia, required this.chrome});

  final String nome;
  final FxWeekDay dia;
  final ShellPalette chrome;

  @override
  Widget build(BuildContext context) {
    final brand = chrome.brand;
    final concluido = dia.estado == FxWeekDayState.concluido;
    final treino = dia.estado == FxWeekDayState.treino;
    final fundo = concluido
        ? EagleTokens.good
        : treino
        ? brand
        : Colors.transparent;
    final borda = dia.proximo
        ? brand
        : (concluido || treino)
        ? fundo
        : chrome.lineStrong;

    return Column(
      children: [
        Text(
          nome,
          style: FocuxHubTypography.cardSubtitle(
            color: dia.hoje ? chrome.ink : chrome.mute,
          ).copyWith(fontWeight: dia.hoje ? FontWeight.w700 : FontWeight.w500),
        ),
        const SizedBox(height: TokensStrip.s1),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fundo,
            border: Border.all(color: borda, width: dia.proximo ? 2 : 1),
          ),
          foregroundDecoration: dia.hoje
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: chrome.ink, width: 2),
                )
              : null,
          child: concluido
              ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
              : treino
              ? const Icon(Icons.fitness_center, size: 14, color: Colors.white)
              : null,
        ),
      ],
    );
  }
}
