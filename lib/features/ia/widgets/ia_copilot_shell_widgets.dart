import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/widgets/fx_conversion.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_toggle_chip.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../utils/ia_copiloto_display.dart';

/// Footer de resultado após gerar — [Scaffold.bottomNavigationBar].
/// Sem SafeArea: o [MainShell] já aplica `FxDock.shellClearance`.
/// Superfície opaca evita insights “vazando” por baixo do CTA.
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

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: chrome.cardFill.withValues(alpha: isDark ? 0.96 : 0.94),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          TokensStrip.s2,
          FxSettingsLayout.pageInset,
          TokensStrip.s3,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: DashboardHomeActionChip(
                label: primaryLabel ?? iaCopilotoCriarTarefaLabel(),
                accent: brand,
                isDark: isDark,
                onPressed: onPrimary,
              ),
            ),
            FxConversionTextLink(
              text: '',
              actionText: iaCopilotoMaisAcoesLabel(),
              onTap: onMore,
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
    required this.line,
    required this.ink,
    this.quotaLabel = 'Pronto',
  });

  final bool dark;
  final Color brand;
  final Color line;
  final Color ink;
  final String quotaLabel;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forDark(dark);
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
    required this.brand,
    this.ink,
    required this.mute,
    required this.onTap,
  });

  final String? alunoNome;
  final Color brand;
  final Color? ink;
  final Color mute;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected = alunoNome != null;

    assert((ink == null || ink!.a >= 0) && mute.a >= 0);
    return Semantics(
      button: true,
      label:
          selected
              ? 'Aluno selecionado, $alunoNome. Toque para trocar.'
              : 'Selecionar aluno',
      child: Align(
        alignment: Alignment.centerLeft,
        child: DashboardHomeActionChip(
          label: selected ? alunoNome! : 'Selecionar aluno',
          accent: brand,
          isDark: Theme.of(context).brightness == Brightness.dark,
          onPressed: onTap,
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
    required this.brand,
    required this.dark,
    required this.line,
    required this.mute,
    required this.onSelect,
  });

  final List<String> modes;
  final int selectedIndex;
  final Color brand;
  final bool dark;
  final Color line;
  final Color mute;
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
    assert(dark || !dark);
    assert(line.a >= 0 && mute.a >= 0);
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
    required this.ink,
    required this.mute,
    required this.brand,
  });

  final Color ink;
  final Color mute;
  final Color brand;

  @override
  Widget build(BuildContext context) {
    assert(ink.a >= 0 && brand.a >= 0);
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
    required this.mode,
    required this.ink,
    required this.mute,
    required this.wash,
  });

  final bool gerando;
  final bool gerado;
  final int elapsedMs;
  final String mode;
  final Color ink;
  final Color mute;
  final Color wash;

  @override
  Widget build(BuildContext context) {
    final elapsed =
        elapsedMs >= 1000
            ? '${(elapsedMs / 1000).toStringAsFixed(1)}s'
            : '${elapsedMs}ms';
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(TokensStrip.s4),
      decoration: fxListCardDecoration(context, accent: primary, radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  Text(
                    gerando
                        ? 'Gerando recomendações...'
                        : 'Recomendações prontas',
                    style: TextStyle(
                      color: ink,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              if (!gerando && elapsedMs > 0)
                Text(
                  elapsed,
                  style: TextStyle(
                    color: mute,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: gerado ? 1.0 : null,
              minHeight: 6,
              backgroundColor: wash,
              valueColor: const AlwaysStoppedAnimation(EagleTokens.copilotSuccess),
            ),
          ),
          if (gerado) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children:
                  [
                    'Histórico analisado',
                    'Sinais priorizados',
                    'Pronto para sua revisão',
                  ].map((s) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: EagleTokens.copilotSuccess,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          s,
                          style: const TextStyle(
                            color: EagleTokens.copilotSuccess,
                            fontSize: 10.8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
            ),
          ],
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
