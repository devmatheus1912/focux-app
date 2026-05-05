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
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
      itemCount: templateSplits.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final template = templateSplits[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.view_week_rounded),
            title: Text(template.nome),
            subtitle: Text(template.descricao),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => _TemplateSlotEditor(
                          template: template,
                          onAdicionar: onAdicionar,
                        ),
                  ),
                ),
          ),
        );
      },
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
