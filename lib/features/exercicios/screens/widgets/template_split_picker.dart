import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/tokens_strip.dart';
import '../../../../core/widgets/feedback_helper.dart';
import '../../../../core/widgets/fx_bottom_sheet.dart';
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
      children: [
        const _TemplateIntro(),
        const SizedBox(height: 12),
        for (var index = 0; index < templateSplits.length; index++) ...[
          _TemplateCard(
            template: templateSplits[index],
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
          if (index != templateSplits.length - 1) const SizedBox(height: 10),
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
                  style: AppTypography.inter(
                    color: primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Comece por uma estrutura',
                  style: AppTypography.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Escolha um modelo abaixo e preencha cada slot com exercícios da biblioteca (${templateSplits.length} opções).',
                  maxLines: 3,
                  style: AppTypography.inter(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11.5,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
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

class _TemplateCard extends StatelessWidget {
  final TemplateSplit template;
  final VoidCallback onTap;

  const _TemplateCard({required this.template, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;
    final slots = template.dias.fold<int>(
      0,
      (sum, day) => sum + day.slots.length,
    );
    final dias = template.dias.length;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.82),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.view_week_rounded, color: primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      template.descricao,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.inter(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$dias ${dias == 1 ? 'dia' : 'dias'} · $slots slots',
                      style: AppTypography.inter(
                        color: primary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
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
              style: AppTypography.inter(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: scheme.onSurface,
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
                style: AppTypography.inter(
                  color: mute,
                  fontSize: 12.5,
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
                  style: AppTypography.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Todos os slots foram preenchidos com a prescrição ativa.',
            style: AppTypography.inter(
              color: scheme.onSurfaceVariant,
              fontSize: 12.5,
              height: 1.35,
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
                  style: AppTypography.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '$done/$total',
                style: AppTypography.inter(
                  color: scheme.primary,
                  fontSize: 12.5,
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
              color: done ? Colors.green : scheme.primary,
              size: 21,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slot.label,
                    style: AppTypography.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    done ? 'Adicionado ao treino' : 'Escolher exercício',
                    style: AppTypography.inter(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
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
