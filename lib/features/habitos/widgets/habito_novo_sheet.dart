import 'package:flutter/material.dart';

import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_inset_picker_row.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/utils/friendly_error.dart';
import '../../alunos/data/aluno_repository.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../data/habito_repository.dart';
import '../utils/habitos_display.dart';

/// Sheet de criação — título, template e aluno (todos ou um).
Future<bool> showHabitoNovoSheet({
  required BuildContext context,
  required HabitoRepository repo,
  required Future<List<Aluno>> Function() loadAlunos,
}) async {
  List<HabitoTemplate> templates = [];
  List<Aluno> alunos = [];
  try {
    templates = await repo.templates();
  } catch (e) {
    if (context.mounted) {
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }
  try {
    alunos = await loadAlunos();
  } catch (_) {
    alunos = const [];
  }
  if (!context.mounted) return false;

  HabitoTemplate? selected;
  var alunoId = habitoAlunoTodosId;
  var alunoLabel = habitoAlunoTodosLabel;
  final tituloCtrl = TextEditingController();
  final descricaoCtrl = TextEditingController();
  var created = false;
  try {
    final ok = await showFxFormSheet(
      context,
      title: 'Novo hábito',
      subtitle: 'Todos os alunos, ou só um.',
      icon: Icons.add_task_outlined,
      confirmLabel: 'Criar',
      child: StatefulBuilder(
        builder: (ctx, setDialogState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (templates.isNotEmpty)
              FxInsetPickerRow(
                icon: Icons.auto_awesome_outlined,
                label: 'Template',
                value: habitoTemplateValue(
                  selected?.titulo,
                  icone: selected?.icone,
                ),
                onTap: () async {
                  final picked = await showFxInsetPickerSheet<String>(
                    ctx,
                    title: 'Template',
                    selected: selected?.tipo,
                    items: [
                      for (final t in templates)
                        FxInsetPickerSheetItem(
                          value: t.tipo,
                          label: habitoTemplateLabel(
                            titulo: t.titulo,
                            icone: t.icone,
                          ),
                        ),
                    ],
                  );
                  if (picked == null) return;
                  HabitoTemplate? match;
                  for (final t in templates) {
                    if (t.tipo == picked) {
                      match = t;
                      break;
                    }
                  }
                  final template = match;
                  if (template == null) return;
                  setDialogState(() {
                    selected = template;
                    tituloCtrl.text = template.titulo;
                    descricaoCtrl.text = template.descricao ?? '';
                  });
                },
              ),
            if (alunos.isNotEmpty)
              FxInsetPickerRow(
                icon: Icons.person_outline,
                label: 'Aluno',
                value: alunoLabel,
                onTap: () async {
                  final picked = await showFxInsetPickerSheet<int>(
                    ctx,
                    title: 'Aluno',
                    selected: alunoId,
                    items: [
                      const FxInsetPickerSheetItem(
                        value: habitoAlunoTodosId,
                        label: habitoAlunoTodosLabel,
                      ),
                      for (final a in alunos)
                        FxInsetPickerSheetItem(
                          value: a.id,
                          label: habitoComplianceLabel(a.nome),
                        ),
                    ],
                  );
                  if (picked == null) return;
                  if (picked == habitoAlunoTodosId) {
                    setDialogState(() {
                      alunoId = habitoAlunoTodosId;
                      alunoLabel = habitoAlunoTodosLabel;
                    });
                    return;
                  }
                  Aluno? match;
                  for (final a in alunos) {
                    if (a.id == picked) {
                      match = a;
                      break;
                    }
                  }
                  final aluno = match;
                  if (aluno == null) return;
                  setDialogState(() {
                    alunoId = aluno.id;
                    alunoLabel = habitoComplianceLabel(aluno.nome);
                  });
                },
              ),
            AlunoInsetFormField(
              controller: tituloCtrl,
              label: 'Título',
              icon: Icons.title_outlined,
            ),
            AlunoInsetFormField(
              controller: descricaoCtrl,
              label: 'Descrição (opcional)',
              icon: Icons.notes_outlined,
              maxLines: 2,
              showDivider: false,
            ),
          ],
        ),
      ),
    );
    if (ok == true && tituloCtrl.text.trim().isNotEmpty) {
      await repo.criar(
        titulo: tituloCtrl.text.trim(),
        descricao: descricaoCtrl.text.trim().isEmpty
            ? null
            : descricaoCtrl.text.trim(),
        tipo: selected?.tipo ?? 'CUSTOM',
        metaDiaria: selected?.metaDiaria,
        metaSemanal: selected?.metaSemanal,
        icone: selected?.icone,
        alunoId: alunoId == habitoAlunoTodosId ? null : alunoId,
      );
      created = true;
    }
  } catch (e) {
    if (context.mounted) {
      FeedbackHelper.showError(context, friendlyError(e));
    }
  } finally {
    tituloCtrl.dispose();
    descricaoCtrl.dispose();
  }
  return created;
}
