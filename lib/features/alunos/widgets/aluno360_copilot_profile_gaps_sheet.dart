import 'package:flutter/material.dart';

import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../data/aluno_repository.dart';
import '../utils/aluno360_copilot_logic.dart';

Future<void> showAluno360CopilotProfileGapsSheet(
  BuildContext context, {
  required Aluno aluno,
  required List<CopilotProfileGap> gaps,
  required Future<void> Function(CopilotProfileGap gap) onSelectGap,
}) async {
  if (gaps.isEmpty) return;
  final picked = await showFxInsetPickerSheet<CopilotProfileGap>(
    context,
    title: 'Completar perfil',
    subtitle:
        '${gaps.length} lacuna${gaps.length == 1 ? '' : 's'} no perfil de ${aluno.nome}.',
    headerIcon: Icons.fact_check_outlined,
    items: [
      for (final gap in gaps)
        FxInsetPickerSheetItem(
          value: gap,
          label: gap.title,
          subtitle: gap.detail,
          icon: gap.icon,
        ),
    ],
    sameValue: (a, b) => a.route == b.route,
  );
  if (picked == null) return;
  await onSelectGap(picked);
}
