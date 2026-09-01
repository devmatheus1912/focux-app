import 'package:flutter/material.dart';

import '../../../../core/theme/fx_settings_layout.dart';
import '../../../../core/theme/tokens_strip.dart';
import '../../../../core/widgets/fx_settings_group.dart';
import '../../../../core/widgets/fx_settings_tile.dart';
import '../../data/enums.dart';
import '../../data/exercicio_taxonomy_labels.dart';
import '../../models/curated_biblioteca.dart';
import '../../utils/biblioteca_wizard_display.dart';

class BibliotecaWizardProgress extends StatelessWidget {
  const BibliotecaWizardProgress({
    super.key,
    required this.step,
    this.totalSteps = 4,
  });

  final int step;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final value = totalSteps <= 0 ? 0.0 : ((step + 1) / totalSteps).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 4,
      ),
    );
  }
}

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
    return FxSettingsGroup(
      header: 'Modalidades',
      caption: 'A biblioteca vem pronta. Escolha o que faz sentido agora.',
      children: [
        for (var i = 0; i < Modalidade.values.length; i++)
          FxSettingsTile(
            fxIcon: bibliotecaModalidadeIcon(Modalidade.values[i]),
            label:
                TaxonomyLabels.modalidade[Modalidade.values[i]] ??
                Modalidade.values[i].backendName,
            value: bibliotecaChoiceValue(
              selecionadas.contains(Modalidade.values[i]),
            ),
            highlight: selecionadas.contains(Modalidade.values[i]),
            showDivider: i != Modalidade.values.length - 1,
            onTap: () => onToggle(Modalidade.values[i]),
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
    return FxSettingsGroup(
      header: 'Onde treinam',
      caption: 'Filtra exercícios por equipamento e ambiente.',
      children: [
        for (var i = 0; i < Espaco.values.length; i++)
          FxSettingsTile(
            fxIcon: bibliotecaEspacoIcon(Espaco.values[i]),
            label:
                TaxonomyLabels.espaco[Espaco.values[i]] ??
                Espaco.values[i].backendName,
            value: bibliotecaChoiceValue(
              selecionados.contains(Espaco.values[i]),
            ),
            highlight: selecionados.contains(Espaco.values[i]),
            showDivider: i != Espaco.values.length - 1,
            onTap: () => onToggle(Espaco.values[i]),
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
    final subtitle = bibliotecaPreviewSubtitle(modalidades, espacos);
    return FxSettingsGroup(
      header: 'Confirmar',
      caption:
          'Vamos carregar exercícios com taxonomia pronta. Vídeos entram para curadoria quando ainda não forem seus.',
      children: [
        FxSettingsTile(
          fxIcon: 'spark',
          label: bibliotecaPreviewTitle(preview.totalCandidatos),
          subtitle: subtitle.isEmpty ? null : subtitle,
          value: '',
          showDivider: false,
          onTap: () {},
        ),
      ],
    );
  }
}

class BibliotecaWizardActions extends StatelessWidget {
  const BibliotecaWizardActions({
    super.key,
    required this.step,
    required this.canContinue,
    required this.importing,
    required this.onBack,
    required this.onContinue,
    required this.onImport,
  });

  final int step;
  final bool canContinue;
  final bool importing;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    if (step >= 3) return const SizedBox.shrink();
    final tiles = <Widget>[];
    if (step > 0) {
      tiles.add(
        FxSettingsTile(
          fxIcon: 'arrow-left',
          label: 'Voltar',
          value: '',
          showDivider: true,
          onTap: importing ? () {} : onBack,
        ),
      );
    }
    if (step < 2) {
      tiles.add(
        FxSettingsTile(
          fxIcon: 'chevron-right',
          label: 'Continuar',
          value: '',
          highlight: canContinue,
          showDivider: false,
          onTap: importing ? () {} : onContinue,
        ),
      );
    } else {
      tiles.add(
        FxSettingsTile(
          fxIcon: 'spark',
          label: 'Carregar biblioteca',
          value: '',
          highlight: true,
          showDivider: false,
          onTap: importing ? () {} : onImport,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: TokensStrip.s5),
      child: FxSettingsGroup(children: tiles),
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
        FxSettingsLayout.pageInset,
      ),
      child: child,
    );
  }
}
