import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/fx_icons.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../utils/checkin_personal_display.dart';

/// Tocar no check-in abre o que o aluno fez: com um treino, o resumo da
/// sessão; com vários, a escolha. O perfil fica no fim da escolha e no avatar.
Future<void> abrirCheckinDoAluno(
  BuildContext context,
  CheckinDoAluno grupo,
) async {
  final itens = grupo.itens;
  if (itens.length == 1) {
    await context.push('/alunos/${grupo.alunoId}/sessoes/${itens.first.id}');
    return;
  }
  const perfil = -1;
  final id = await showFxInsetPickerSheet<int>(
    context,
    title: grupo.alunoNome,
    subtitle: checkinDoAlunoLinha(grupo),
    headerIcon: FxIcons.treino,
    items: [
      for (final i in itens)
        FxInsetPickerSheetItem(
          value: i.id,
          label: i.treinoNome,
          subtitle: [
            if (i.iniciadoEm != null) checkinHoraLinha(i.iniciadoEm!),
            if (i.parcial) 'parcial',
          ].join(' · '),
          icon: FxIcons.treino,
        ),
      const FxInsetPickerSheetItem(
        value: perfil,
        label: 'Abrir perfil',
        icon: FxIcons.pessoa,
      ),
    ],
  );
  if (id == null || !context.mounted) return;
  await context.push(
    id == perfil
        ? '/alunos/${grupo.alunoId}'
        : '/alunos/${grupo.alunoId}/sessoes/$id',
  );
}
