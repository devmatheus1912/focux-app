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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: abrir,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: chrome.panel(radius: 20),
            padding: const EdgeInsets.all(TokensStrip.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.alunoResumoFichaTitulo,
                        style: FocuxHubTypography.cardTitle(color: chrome.ink),
                      ),
                    ),
                    if (rotulo != null)
                      FxStatusPill(label: rotulo.texto, tone: rotulo.tom),
                  ],
                ),
                const SizedBox(height: TokensStrip.s3),
                if (vazia)
                  Text(
                    s.alunoResumoFichaVazia,
                    style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                  )
                else
                  FxWeekStrip(dias: dias),
                const SizedBox(height: TokensStrip.s3),
                Align(
                  alignment: Alignment.centerRight,
                  child: vazia
                      ? FxTonalButton(
                          label: verbo,
                          icon: Icons.add_rounded,
                          compact: true,
                          onPressed: abrir,
                        )
                      : FxActionLink(label: verbo, onTap: abrir),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
