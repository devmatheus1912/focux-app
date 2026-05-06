import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/exercicio_repository.dart';
import '../../data/template_splits.dart';
import 'padrao_exercicios_bottom_sheet.dart';

class TemplateSplitPicker extends StatelessWidget {
  const TemplateSplitPicker({super.key, required this.onAdicionar});

  final Future<void> Function(Exercicio exercicio) onAdicionar;

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
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.view_agenda_rounded, color: primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Comece por uma estrutura',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  'Escolha um modelo e preencha cada slot com exercícios da biblioteca.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11.5,
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
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      template.descricao,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$dias ${dias == 1 ? 'dia' : 'dias'} · $slots slots',
                      style: TextStyle(
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
  });

  final TemplateSplit template;
  final Future<void> Function(Exercicio exercicio) onAdicionar;

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

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template.nome),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Center(child: Text('${_done.length}/$slotsTotal')),
          ),
        ],
      ),
      body: ListView(
        children: [
          for (final day in widget.template.dias) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
              child: Text(
                day.nome,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (var i = 0; i < day.slots.length; i++)
              _SlotTile(
                done: _done.contains('${day.nome}-$i'),
                slot: day.slots[i],
                saving: _saving,
                onChoose: (ex) async {
                  setState(() => _saving = true);
                  try {
                    await widget.onAdicionar(ex);
                    setState(() => _done.add('${day.nome}-$i'));
                  } finally {
                    if (mounted) setState(() => _saving = false);
                  }
                },
              ),
          ],
        ],
      ),
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.done,
    required this.slot,
    required this.saving,
    required this.onChoose,
  });

  final bool done;
  final TemplateSlot slot;
  final bool saving;
  final ValueChanged<Exercicio> onChoose;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        done ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
        color: done ? Colors.green : null,
      ),
      title: Text(slot.label),
      subtitle: Text(done ? 'Adicionado ao treino' : 'Toque para escolher'),
      enabled: !saving,
      onTap:
          saving
              ? null
              : () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder:
                    (_) => PadraoExerciciosBottomSheet(
                      padrao: slot.padrao,
                      grupo: slot.grupo,
                      onAdicionar: onChoose,
                    ),
              ),
    );
  }
}
