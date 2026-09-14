import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_toggle_chip.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../utils/ia_copiloto_display.dart';

/// Chip sticky S1 após gerar — paridade [DashboardPrioritiesOverlay].
/// Overlay flutuante (não barra `bottomNavigationBar` / S3–S5).
/// O pai posiciona no Stack; scroll reserva folga para não cobrir Insights.
class IaCopilotResultActionBar extends StatelessWidget {
  const IaCopilotResultActionBar({
    super.key,
    required this.brand,
    required this.onPrimary,
    required this.onMore,
    this.primaryLabel,
  });

  final Color brand;
  final String? primaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onMore;

  /// Folga de scroll quando o overlay está visível (chip + link + padding).
  static const double scrollReserve = 96;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final moreLabel = iaCopilotoMaisAcoesLabel();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TokensStrip.s4,
        0,
        TokensStrip.s4,
        10,
      ),
      child: Align(
        alignment: AlignmentDirectional.bottomStart,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardHomeActionChip(
              label: primaryLabel ?? iaCopilotoCriarTarefaLabel(),
              accent: brand,
              isDark: isDark,
              onPressed: onPrimary,
            ),
            Semantics(
              button: true,
              label: moreLabel,
              child: InkWell(
                onTap: onMore,
                borderRadius: BorderRadius.circular(TokensStrip.rSm),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 10, 12, 4),
                  child: Text(
                    moreLabel,
                    style: TextStyle(
                      color: brand,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class IaCopilotHeaderStatus extends StatelessWidget {
  const IaCopilotHeaderStatus({
    super.key,
    required this.dark,
    required this.brand,
    required this.ink,
    this.quotaLabel = 'Pronto',
  });

  final bool dark;
  final Color brand;
  final Color ink;
  final String quotaLabel;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forBrightness(context, dark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: chrome.headerAction(radius: 999),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: brand, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            quotaLabel,
            style: TextStyle(
              color: ink,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class IaCopilotStudentSelector extends StatelessWidget {
  const IaCopilotStudentSelector({
    super.key,
    required this.alunoNome,
    required this.onTap,
  });

  final String? alunoNome;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected = alunoNome != null;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      label:
          selected
              ? 'Aluno selecionado, $alunoNome. Toque para trocar.'
              : 'Selecionar aluno',
      child: Align(
        alignment: Alignment.centerLeft,
        // Tonal — não compete com o P0 (Gerar / sticky de resultado). §11/§12.
        child: FxToggleChip(
          label: selected ? alunoNome! : 'Selecionar aluno',
          icon: Icons.person_outline_rounded,
          selected: selected,
          isDark: dark,
          showCheckmark: selected,
          onTap: onTap,
        ),
      ),
    );
  }
}

class IaCopilotModeSelector extends StatelessWidget {
  const IaCopilotModeSelector({
    super.key,
    required this.modes,
    required this.selectedIndex,
    required this.dark,
    required this.onSelect,
  });

  final List<String> modes;
  final int selectedIndex;
  final bool dark;
  final ValueChanged<int> onSelect;

  String _label(String mode) => mode == 'Progressão' ? 'Progresso' : mode;

  IconData _icon(String mode) {
    switch (mode) {
      case 'Progressão':
        return Icons.trending_up_outlined;
      default:
        return Icons.fitness_center_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Modo do Copiloto',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DashboardSectionHeader(title: 'Modo'),
          const SizedBox(height: TokensStrip.s3),
          Wrap(
            spacing: TokensStrip.s2,
            runSpacing: TokensStrip.s2,
            children: [
              for (final e in modes.asMap().entries)
                FxToggleChip(
                  label: _label(e.value),
                  icon: _icon(e.value),
                  selected: e.key == selectedIndex,
                  isDark: dark,
                  onTap: () => onSelect(e.key),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class IaCopilotSafetyNote extends StatelessWidget {
  const IaCopilotSafetyNote({
    super.key,
    required this.mute,
  });

  final Color mute;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DashboardSectionHeader(title: 'Revisão obrigatória'),
        const SizedBox(height: TokensStrip.s2),
        Text(
          'Nada é aplicado automaticamente. A IA sugere. Você decide o que entra no aluno.',
          style: TextStyle(
            color: mute,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class IaCopilotMetaChip extends StatelessWidget {
  const IaCopilotMetaChip({
    super.key,
    required this.label,
    required this.icon,
    required this.brand,
    required this.ink,
    required this.line,
  });

  final String label;
  final IconData icon;
  final Color brand;
  final Color ink;
  final Color line;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 7, 10, 7),
      decoration: BoxDecoration(
        color: brand.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: brand),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: ink,
              fontSize: 11.2,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class IaCopilotMenuAction extends StatelessWidget {
  const IaCopilotMenuAction({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.ink,
    required this.mute,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color ink;
  final Color mute;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: fxListCardDecoration(
            context,
            accent: primary,
            radius: 18,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: dark ? 0.16 : 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: ink,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: mute,
                        fontSize: 11.5,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class IaCopilotPrimaryAction extends StatelessWidget {
  const IaCopilotPrimaryAction({
    super.key,
    required this.label,
    required this.brand,
    required this.onTap,
  });

  final String label;
  final Color brand;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    assert(brand.a >= 0);
    return Semantics(
      button: true,
      label: label,
      child: Align(
        alignment: Alignment.centerLeft,
        child: DashboardHomeActionChip(
          label: label,
          accent: brand,
          isDark: Theme.of(context).brightness == Brightness.dark,
          onPressed: onTap,
        ),
      ),
    );
  }
}

class IaCopilotGenerationStatus extends StatelessWidget {
  const IaCopilotGenerationStatus({
    super.key,
    required this.gerando,
    required this.gerado,
    required this.elapsedMs,
    required this.ink,
    required this.mute,
    required this.wash,
  });

  final bool gerando;
  final bool gerado;
  final int elapsedMs;
  final Color ink;
  final Color mute;
  final Color wash;

  @override
  Widget build(BuildContext context) {
    final elapsed =
        elapsedMs >= 1000
            ? '${(elapsedMs / 1000).toStringAsFixed(1)}s'
            : '${elapsedMs}ms';

    // Pós-gerar: linha compacta — não empurra Insights abaixo do fold (§9 S1 / pilar 13).
    if (gerado && !gerando) {
      return Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: EagleTokens.copilotSuccess,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Pronto para revisão',
              style: TextStyle(
                color: ink,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (elapsedMs > 0)
            Text(
              elapsed,
              style: TextStyle(
                color: mute,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
        ],
      );
    }

    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(TokensStrip.s4),
      decoration: fxListCardDecoration(context, accent: primary, radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: EagleTokens.copilotSuccess,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Gerando recomendações...',
                  style: TextStyle(
                    color: ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 6,
              backgroundColor: wash,
              valueColor: const AlwaysStoppedAnimation(
                EagleTokens.copilotSuccess,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class IaCopilotPreviewCard extends StatelessWidget {
  const IaCopilotPreviewCard({
    super.key,
    required this.howItWorks,
    required this.brand,
    required this.ink,
    required this.mute,
    required this.checks,
  });

  final String howItWorks;
  final Color brand;
  final Color ink;
  final Color mute;
  final List<String> checks;

  @override
  Widget build(BuildContext context) {
    assert(ink.a >= 0 && mute.a >= 0);
    return Semantics(
      container: true,
      label: 'Como funciona o Copiloto. $howItWorks',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DashboardSectionHeader(title: 'Como funciona'),
          const SizedBox(height: TokensStrip.s2),
          Text(
            howItWorks,
            style: TextStyle(
              color: mute,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: TokensStrip.s3),
          for (final check in checks)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.check, color: brand, size: 15),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      check,
                      style: TextStyle(
                        color: ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
