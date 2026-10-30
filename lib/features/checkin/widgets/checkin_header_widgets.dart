import 'package:flutter/material.dart';

import '../../../core/widgets/fx_tonal_button.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/focux_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../l10n/app_localizations.dart';
import '../utils/checkin_execucao_display.dart';

class CheckinWorkoutHeader extends StatelessWidget {
  final String treinoNome;

  /// Tempo do treino, ou "Descanso".
  final String contextLine;
  final VoidCallback onBack;

  /// Abre as ações do exercício (ajustar, trocar, dicas, finalizar).
  final VoidCallback? onMais;

  /// Exercício atual (1 = primeiro) e total: a barra do treino.
  final int exercicioAtual;
  final int totalExercicios;
  final String? progressoLeitura;

  const CheckinWorkoutHeader({
    super.key,
    required this.treinoNome,
    required this.contextLine,
    required this.onBack,
    this.onMais,
    this.exercicioAtual = 0,
    this.totalExercicios = 0,
    this.progressoLeitura,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          TokensStrip.s2,
          TokensStrip.s3,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    treinoNome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FocuxHubTypography.sectionTitle(
                      context,
                      color: chrome.ink,
                    ),
                  ),
                ),
                const SizedBox(width: TokensStrip.s2),
                Text(
                  contextLine,
                  maxLines: 1,
                  style: FocuxTypography.bodySmall(color: chrome.mute),
                ),
                const Spacer(),
                if (onMais != null)
                  IconButton(
                    tooltip: s.checkinMais,
                    onPressed: onMais,
                    style: IconButton.styleFrom(
                      minimumSize: const Size(checkinExecutionControlMin, checkinExecutionControlMin),
                    ),
                    icon: Icon(Icons.more_horiz_rounded, color: chrome.ink),
                  ),
                SizedBox(
                  height: checkinExecutionControlMin,
                  child: Center(
                    child: FxTonalButton(
                      label: s.checkinSair,
                      compact: true,
                      onPressed: onBack,
                    ),
                  ),
                ),
              ],
            ),
            if (totalExercicios > 1)
              Padding(
                padding: const EdgeInsets.only(
                  right: TokensStrip.s1,
                  top: TokensStrip.s1,
                ),
                child: Semantics(
                  label: progressoLeitura,
                  excludeSemantics: true,
                  child: Row(
                    key: const ValueKey('checkin-barra-treino'),
                    children: [
                      for (var i = 1; i <= totalExercicios; i++) ...[
                        if (i > 1) const SizedBox(width: TokensStrip.s1),
                        Expanded(
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: i <= exercicioAtual ? primary : chrome.line,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
