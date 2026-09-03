import 'package:flutter/material.dart';

import '../../../../core/theme/focux_hub_typography.dart';
import '../../../../core/theme/fx_settings_layout.dart';
import '../../../../core/theme/shell_chrome.dart';
import '../../../../core/theme/tokens_strip.dart';
import '../../../../core/widgets/fx_toggle_chip.dart';
import '../../data/enums.dart';
import '../../data/exercicio_taxonomy_labels.dart';
import '../../models/curated_biblioteca.dart';
import '../../utils/biblioteca_wizard_display.dart';

class WizardStepModalidades extends StatelessWidget {
  const WizardStepModalidades({
    super.key,
    required this.selecionadas,
    required this.onToggle,
  });

  final Set<Modalidade> selecionadas;
  final ValueChanged<Modalidade> onToggle;

  @override
  Widget build(BuildContext context) {
    final isDark = ShellChrome.of(context).isDark;
    return Wrap(
      spacing: TokensStrip.s2,
      runSpacing: TokensStrip.s2,
      children: [
        for (final modalidade in Modalidade.values)
          FxToggleChip(
            label:
                TaxonomyLabels.modalidade[modalidade] ?? modalidade.backendName,
            selected: selecionadas.contains(modalidade),
            isDark: isDark,
            showCheckmark: true,
            onTap: () => onToggle(modalidade),
          ),
      ],
    );
  }
}

class WizardStepEspacos extends StatelessWidget {
  const WizardStepEspacos({
    super.key,
    required this.selecionados,
    required this.onToggle,
  });

  final Set<Espaco> selecionados;
  final ValueChanged<Espaco> onToggle;

  @override
  Widget build(BuildContext context) {
    final isDark = ShellChrome.of(context).isDark;
    return Wrap(
      spacing: TokensStrip.s2,
      runSpacing: TokensStrip.s2,
      children: [
        for (final espaco in Espaco.values)
          FxToggleChip(
            label: TaxonomyLabels.espaco[espaco] ?? espaco.backendName,
            selected: selecionados.contains(espaco),
            isDark: isDark,
            showCheckmark: true,
            onTap: () => onToggle(espaco),
          ),
      ],
    );
  }
}

class WizardStepConfirmacao extends StatelessWidget {
  const WizardStepConfirmacao({
    super.key,
    required this.modalidades,
    required this.espacos,
    required this.preview,
  });

  final Set<Modalidade> modalidades;
  final Set<Espaco> espacos;
  final CuratedBibliotecaPreview preview;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final subtitle = bibliotecaPreviewSubtitle(modalidades, espacos);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          bibliotecaPreviewTitle(preview.totalCandidatos),
          style: FocuxHubTypography.cardTitle(color: chrome.ink),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: TokensStrip.s2),
          Text(
            subtitle,
            style: FocuxHubTypography.bodyMuted(color: chrome.mute),
          ),
        ],
      ],
    );
  }
}

class BibliotecaWizardPagePadding extends StatelessWidget {
  const BibliotecaWizardPagePadding({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FxSettingsLayout.pageInset,
        TokensStrip.s3,
        FxSettingsLayout.pageInset,
        0,
      ),
      child: child,
    );
  }
}
