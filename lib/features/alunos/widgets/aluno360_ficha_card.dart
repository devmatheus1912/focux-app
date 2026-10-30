import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_action_link.dart';
import '../../../core/widgets/fx_status_pill.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../core/widgets/fx_week_strip.dart';
import '../../../l10n/app_localizations.dart';
import '../../dashboard/utils/aluno_semana_faixa.dart';
import '../../treinos/providers/treinos_provider.dart';
import '../../treinos/utils/semana_da_fila.dart';
import '../../treinos/widgets/ficha_vigencia_linha.dart';

/// A ficha de treino do aluno no Resumo: a semana em sete dias, a validade e
/// um verbo que abre a ficha de verdade (`/alunos/:id/rotina`).
class Aluno360FichaCard extends ConsumerWidget {
  const Aluno360FichaCard({
    super.key,
    required this.alunoId,
    required this.alunoNome,
    this.hoje,
  });

  final int alunoId;
  final String alunoNome;

  /// Para teste; por padrão, agora.
  final DateTime? hoje;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rotina = ref.watch(alunoRotinaProvider(alunoId)).asData?.value;
    if (rotina == null) return const SizedBox.shrink();
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final agora = hoje ?? DateTime.now();
    final dias = faixaDaSemana(rotina, const [], agora);
    final vazia = !rotina.temTreino || dias.isEmpty;
    final rotulo = !vazia && rotina.vigencia.temPrazo
        ? rotuloDaVigencia(s, rotina.vigencia, agora)
        : null;
    final verbo = vazia ? s.alunoResumoFichaMontar : s.alunoResumoFichaAbrir;
    final semana = semanaDaFila(rotina);
    final diasComLetra = [
      for (final d in dias)
        FxWeekDay(
          dia: d.dia,
          estado: d.estado,
          hoje: d.hoje,
          proximo: d.proximo,
          letra: [
            for (final x in semana)
              if (x.dia == d.dia && x.sessoes.isNotEmpty)
                letraDaSessao(x.sessoes.first.nome),
          ].firstOrNull,
        ),
    ];
    void abrir() => context.push(
      '/alunos/$alunoId/rotina',
      extra: alunoNome.trim(),
    );

    return Semantics(
      button: true,
      label: [
        s.alunoResumoFichaTitulo,
        if (vazia) s.alunoResumoFichaVazia else FxWeekStrip.semantica(s, dias),
        if (rotulo != null) rotulo.texto,
        verbo,
      ].join('. '),
      excludeSemantics: true,
      // O painel fica por fora: Ink com sombra deixava cantos cinza atrás.
      child: DecoratedBox(
        decoration: chrome.panel(radius: 20),
        child: Material(
          color: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: abrir,
            child: Padding(
              padding: const EdgeInsets.all(TokensStrip.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: TokensStrip.s2,
                    runSpacing: TokensStrip.s1,
                    children: [
                      Text(
                        s.alunoResumoFichaTitulo,
                        style: FocuxHubTypography.cardTitle(color: chrome.ink),
                      ),
                      if (vazia)
                        FxTonalButton(
                          label: verbo,
                          icon: Icons.add_rounded,
                          compact: true,
                          onPressed: abrir,
                        )
                      else
                        FxActionLink(label: verbo, onTap: abrir),
                    ],
                  ),
                  const SizedBox(height: TokensStrip.s3),
                  if (vazia)
                    Text(
                      s.alunoResumoFichaVazia,
                      style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                    )
                  else
                    FxWeekStrip(dias: diasComLetra),
                  if (rotulo != null) ...[
                    const SizedBox(height: TokensStrip.s3),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FxStatusPill(label: rotulo.texto, tone: rotulo.tom),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final _letraDaSessao = RegExp(r'^(?:Treino\s+)?([A-Za-z])(?:\s+·\s+.*)?$');

/// "A · Peito" e "Treino A" dão "A"; outro nome não tem letra.
String? letraDaSessao(String nome) =>
    _letraDaSessao.firstMatch(nome.trim())?.group(1)?.toUpperCase();
