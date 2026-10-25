import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../l10n/app_localizations.dart';
import '../utils/aluno_semana_faixa.dart';
import 'dashboard_section_header.dart';

/// "Esta semana": sete dias, hoje com anel, treino cheio, descanso apagado.
/// A faixa toda toca e leva à aba Treinos.
class AlunoSemanaFaixa extends StatelessWidget {
  const AlunoSemanaFaixa({super.key, required this.dias, required this.onTap});

  final List<AlunoDiaFaixa> dias;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (dias.isEmpty) return const SizedBox.shrink();
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final nomes = [
      s.rotinaDiaSeg,
      s.rotinaDiaTer,
      s.rotinaDiaQua,
      s.rotinaDiaQui,
      s.rotinaDiaSex,
      s.rotinaDiaSab,
      s.rotinaDiaDom,
    ];
    String estado(AlunoDiaFaixa d) => switch (d.estado) {
      AlunoDiaEstado.concluido => s.alunoSemanaFaixaConcluido,
      AlunoDiaEstado.treino => s.alunoSemanaFaixaTreino,
      AlunoDiaEstado.descanso => s.alunoSemanaFaixaDescanso,
    };
    final resumo = [
      for (final (i, d) in dias.indexed)
        [
          '${nomes[i]}: ${estado(d)}',
          if (d.hoje) s.treinosSuaSemanaHoje,
          if (d.proximo) s.alunoSemanaFaixaProximo,
        ].join(', '),
    ].join('. ');

    return Semantics(
      button: true,
      label: '${s.alunoSemanaFaixaTitulo}. $resumo',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TokensStrip.rCard),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DashboardSectionHeader(title: s.alunoSemanaFaixaTitulo),
            const SizedBox(height: TokensStrip.s2),
            Row(
              children: [
                for (final (i, d) in dias.indexed)
                  Expanded(child: _Dia(nome: nomes[i], dia: d, chrome: chrome)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Dia extends StatelessWidget {
  const _Dia({required this.nome, required this.dia, required this.chrome});

  final String nome;
  final AlunoDiaFaixa dia;
  final ShellPalette chrome;

  @override
  Widget build(BuildContext context) {
    final brand = chrome.brand;
    final concluido = dia.estado == AlunoDiaEstado.concluido;
    final treino = dia.estado == AlunoDiaEstado.treino;
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
