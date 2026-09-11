import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/brand_palette.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/focux_hub_typography.dart';
import '../../../../core/theme/fx_settings_layout.dart';
import '../../../../core/widgets/fx_bottom_sheet.dart';
import '../../../../core/widgets/fx_settings_group.dart';
import '../../../../core/widgets/fx_settings_tile.dart';
import '../../../../core/widgets/fx_shell_scaffold.dart';
import '../../data/exercicio_repository.dart';
import '../../data/template_splits.dart';
import '../../utils/template_split_catalog.dart';
import 'padrao_exercicios_bottom_sheet.dart';

class TemplateSplitPicker extends StatelessWidget {
  const TemplateSplitPicker({
    super.key,
    required this.onAdicionar,
    this.onCompleted,
    this.alreadyInTreinoIds = const {},
  });

  final Future<void> Function(Exercicio exercicio) onAdicionar;
  final VoidCallback? onCompleted;
  final Set<int> alreadyInTreinoIds;

  void _openTemplate(BuildContext context, TemplateSplit template) {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => _TemplateSlotEditor(
              template: template,
              alreadyInTreinoIds: alreadyInTreinoIds,
              onAdicionar: onAdicionar,
              onCompleted: onCompleted,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final soft = BrandPalette.softened(primary);
    final sections = buildTemplateSplitSections();
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        FxSettingsLayout.pageInset,
        2,
        FxSettingsLayout.pageInset,
        FxSettingsLayout.footerAfterGroup,
      ),
      children: [
        const _TemplateIntro(),
        const SizedBox(height: FxSettingsLayout.groupGap),
        for (var s = 0; s < sections.length; s++) ...[
          FxSettingsGroup(
            accent: primary,
            header: sections[s].header,
            caption: sections[s].caption,
            children: [
              for (var i = 0; i < sections[s].items.length; i++)
                _TemplateTile(
                  template: sections[s].items[i],
                  accent: soft,
                  showDivider: i < sections[s].items.length - 1,
                  onTap: () => _openTemplate(context, sections[s].items[i]),
                ),
            ],
          ),
          if (s < sections.length - 1)
            const SizedBox(height: FxSettingsLayout.groupGap),
        ],
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
    final mute = scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(FxSettingsLayout.groupRadius),
        border: Border.all(color: primary.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.calendar_view_week_rounded,
            color: BrandPalette.softened(primary),
            size: FxSettingsLayout.iconSize,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quantos dias o aluno treina?',
                  style: FocuxHubTypography.body(
                    color: scheme.onSurface,
                  ).copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  'Toque no modelo e escolha os exercícios de cada slot.',
                  maxLines: 2,
                  style: FocuxHubTypography.bodyMuted(
                    color: mute,
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
    return FxSettingsTile(
      icon: Icons.view_week_rounded,
      accent: accent,
      label: template.nome,
      subtitle: templateSplitTileSubtitle(template),
      value: '',
      picker: true,
      showDivider: showDivider,
      onTap: onTap,
    );
  }
}

class _TemplateSlotEditor extends ConsumerStatefulWidget {
  const _TemplateSlotEditor({
    required this.template,
    required this.onAdicionar,
    this.onCompleted,
    this.alreadyInTreinoIds = const {},
  });

  final TemplateSplit template;
  final Future<void> Function(Exercicio exercicio) onAdicionar;
  final VoidCallback? onCompleted;
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
    final primary = scheme.primary;
    final soft = BrandPalette.softened(primary);

    return FxShellScaffold(
      // Pai já traz mesh — evita segundo CinematicMesh (custo/crash em low-end).
      useMesh: false,
      appBar: FxShellAppBar(
        title: widget.template.nome,
        subtitle: '$done de $slotsTotal exercícios',
        onBack: () => Navigator.pop(context),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          FxSettingsLayout.groupGap,
          FxSettingsLayout.pageInset,
          MediaQuery.paddingOf(context).bottom + FxSettingsLayout.footerAfterGroup,
        ),
        children: [
          _TemplateProgressCard(done: done, total: slotsTotal),
          const SizedBox(height: FxSettingsLayout.groupGap),
          for (final (dayIndex, day) in widget.template.dias.indexed) ...[
            FxSettingsGroup(
              accent: primary,
              header: _templateDayTitle(day.nome, dayIndex),
              children: [
                for (var i = 0; i < day.slots.length; i++)
                  _SlotTile(
                    done: _done.contains('${day.nome}-$i'),
                    slot: day.slots[i],
                    saving: _saving,
                    accent: soft,
                    showDivider: i < day.slots.length - 1,
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
              ],
            ),
            const SizedBox(height: FxSettingsLayout.groupGap),
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
                // Só fecha o editor; o pai (Montar por modelo) fecha e mostra snack.
                Navigator.pop(context);
                widget.onCompleted?.call();
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
            'Todos os exercícios foram adicionados com a prescrição ativa.',
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
                  'Complete o modelo',
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
    required this.accent,
    required this.showDivider,
    required this.onChoose,
    this.alreadyInTreinoIds = const {},
  });

  final bool done;
  final TemplateSlot slot;
  final bool saving;
  final Color accent;
  final bool showDivider;
  final ValueChanged<Exercicio> onChoose;
  final Set<int> alreadyInTreinoIds;

  @override
  Widget build(BuildContext context) {
    final good = EagleTokens.good;
    return FxSettingsTile(
      icon:
          done
              ? Icons.check_circle_rounded
              : Icons.add_circle_outline_rounded,
      accent: done ? good : accent,
      label: slot.label,
      subtitle: done ? 'Adicionado ao treino' : 'Escolher exercício',
      value: '',
      picker: true,
      showDivider: showDivider,
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
    );
  }
}
