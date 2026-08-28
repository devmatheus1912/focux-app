import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/focux_hub_typography.dart';
import '../../../../core/theme/tokens_strip.dart';
import '../../../../core/widgets/feedback_helper.dart';
import '../../../../core/widgets/fx_bottom_sheet.dart';
import '../../../../core/widgets/fx_settings_group.dart';
import '../../../../core/widgets/fx_settings_tile.dart';
import '../../../../core/theme/fx_settings_layout.dart';
import '../../../../core/widgets/fx_shell_scaffold.dart';
import '../../data/exercicio_repository.dart';
import '../../data/template_splits.dart';
import 'padrao_exercicios_bottom_sheet.dart';

class TemplateSplitPicker extends StatelessWidget {
  const TemplateSplitPicker({
    super.key,
    required this.onAdicionar,
    this.alreadyInTreinoIds = const {},
  });

  final Future<void> Function(Exercicio exercicio) onAdicionar;
  final Set<int> alreadyInTreinoIds;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
      children: [
        const _TemplateIntro(),
        const SizedBox(height: FxSettingsLayout.groupGap),
        FxSettingsGroup(
          accent: primary,
          children: [
            for (var index = 0; index < templateSplits.length; index++)
              _TemplateTile(
                template: templateSplits[index],
                accent: primary,
                showDivider: index < templateSplits.length - 1,
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => _TemplateSlotEditor(
                              template: templateSplits[index],
                              alreadyInTreinoIds: alreadyInTreinoIds,
                              onAdicionar: onAdicionar,
                            ),
                      ),
                    ),
              ),
          ],
        ),
      ],
    );
  }
}

class _TemplateIntro extends StatelessWidget {
  const _TemplateIntro();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: primary.withValues(alpha: 0.22),
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded, color: primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dica',
                  style: FocuxHubTypography.chip(primary).copyWith(
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Comece por uma estrutura',
                  style: FocuxHubTypography.body(
                    color: scheme.onSurface,
                  ).copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  'Escolha um modelo abaixo e preencha cada slot com exercícios da biblioteca (${templateSplits.length} opções).',
                  maxLines: 3,
                  style: FocuxHubTypography.bodyMuted(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
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

class _TemplateTile extends StatelessWidget {
  final TemplateSplit template;
  final Color accent;
  final bool showDivider;
  final VoidCallback onTap;

  const _TemplateTile({
    required this.template,
    required this.accent,
    required this.showDivider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final slots = template.dias.fold<int>(
      0,
      (sum, day) => sum + day.slots.length,
    );
    final dias = template.dias.length;
    return FxSettingsTile(
      icon: Icons.view_week_rounded,
      accent: accent,
      label: template.nome,
      subtitle: template.descricao,
      value: '$dias ${dias == 1 ? 'dia' : 'dias'} · $slots slots',
      showDivider: showDivider,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
    );
  }
}

class _TemplateSlotEditor extends ConsumerStatefulWidget {
  const _TemplateSlotEditor({
    required this.template,
    required this.onAdicionar,
    this.alreadyInTreinoIds = const {},
  });

  final TemplateSplit template;
  final Future<void> Function(Exercicio exercicio) onAdicionar;
  final Set<int> alreadyInTreinoIds;

  @override
  ConsumerState<_TemplateSlotEditor> createState() =>
      _TemplateSlotEditorState();
}

class _TemplateSlotEditorState extends ConsumerState<_TemplateSlotEditor> {
  final Set<String> _done = {};
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final slotsTotal = widget.template.dias.fold<int>(
      0,
      (sum, day) => sum + day.slots.length,
    );
    final done = _done.length;
    final scheme = Theme.of(context).colorScheme;
    final mute = scheme.onSurfaceVariant;

    return FxShellScaffold(
      useMesh: true,
      appBar: FxShellAppBar(
        title: widget.template.nome,
        subtitle: '$done de $slotsTotal slots',
        onBack: () => Navigator.pop(context),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          MediaQuery.paddingOf(context).bottom + 18,
        ),
        children: [
          _TemplateProgressCard(done: done, total: slotsTotal),
          const SizedBox(height: 18),
          for (final (dayIndex, day) in widget.template.dias.indexed) ...[
            Text(
              _templateDayTitle(day.nome, dayIndex),
              style: FocuxHubTypography.body(color: scheme.onSurface).copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(TokensStrip.rCard),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.7),
                ),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < day.slots.length; i++) ...[
                    _SlotTile(
                      done: _done.contains('${day.nome}-$i'),
                      slot: day.slots[i],
                      saving: _saving,
                      alreadyInTreinoIds: widget.alreadyInTreinoIds,
                      onChoose: (ex) async {
                        setState(() => _saving = true);
                        try {
                          await widget.onAdicionar(ex);
                          if (mounted) {
                            setState(() => _done.add('${day.nome}-$i'));
                          }
                        } finally {
                          if (mounted) setState(() => _saving = false);
                        }
                      },
                    ),
                    if (i != day.slots.length - 1)
                      Divider(
                        height: 1,
                        indent: 56,
                        color: scheme.outlineVariant.withValues(alpha: 0.52),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],
          if (_saving)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Salvando exercício...',
                textAlign: TextAlign.center,
                style: FocuxHubTypography.bodyMuted(
                  color: mute,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (done == slotsTotal && slotsTotal > 0) ...[
            const SizedBox(height: 8),
            _TemplateCompleteCard(
              onBackToWorkout: () {
                HapticFeedback.mediumImpact();
                FeedbackHelper.showSuccess(
                  context,
                  'Modelo concluído! Exercícios adicionados ao treino.',
                );
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _TemplateCompleteCard extends StatelessWidget {
  const _TemplateCompleteCard({required this.onBackToWorkout});

  final VoidCallback onBackToWorkout;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primary.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_rounded, color: primary, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Modelo concluído',
                  style: FocuxHubTypography.cardTitle(
                    color: scheme.onSurface,
                  ).copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Todos os slots foram preenchidos com a prescrição ativa.',
            style: FocuxHubTypography.bodyMuted(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onBackToWorkout,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: primary,
            ),
            child: const Text('Voltar ao treino'),
          ),
        ],
      ),
    );
  }
}

class _TemplateProgressCard extends StatelessWidget {
  final int done;
  final int total;

  const _TemplateProgressCard({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = total == 0 ? 0.0 : done / total;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.playlist_add_check_rounded, color: scheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Preencha os slots do modelo',
                  style: FocuxHubTypography.body(
                    color: scheme.onSurface,
                  ).copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                '$done/$total',
                style: FocuxHubTypography.metric(
                  color: scheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: progress,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}

String _templateDayTitle(String value, int index) {
  final trimmed = value.trim();
  if (trimmed.length == 1 && RegExp(r'^[A-Za-z]$').hasMatch(trimmed)) {
    return 'Bloco ${trimmed.toUpperCase()}';
  }
  if (trimmed.isEmpty) return 'Bloco ${index + 1}';
  return trimmed;
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.done,
    required this.slot,
    required this.saving,
    required this.onChoose,
    this.alreadyInTreinoIds = const {},
  });

  final bool done;
  final TemplateSlot slot;
  final bool saving;
  final ValueChanged<Exercicio> onChoose;
  final Set<int> alreadyInTreinoIds;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap:
          saving
              ? null
              : () => showFxBottomSheet(
                context: context,
                builder:
                    (_) => PadraoExerciciosBottomSheet(
                      padrao: slot.padrao,
                      grupo: slot.grupo,
                      alreadyInTreinoIds: alreadyInTreinoIds,
                      onAdicionar: onChoose,
                    ),
              ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
        child: Row(
          children: [
            Icon(
              done
                  ? Icons.check_circle_rounded
                  : Icons.add_circle_outline_rounded,
              color: done ? EagleTokens.good : scheme.primary,
              size: 21,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slot.label,
                    style: FocuxHubTypography.cardTitle(
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    done ? 'Adicionado ao treino' : 'Escolher exercício',
                    style: FocuxHubTypography.bodyMuted(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
