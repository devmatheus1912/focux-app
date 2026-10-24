import 'package:flutter/material.dart';

import '../../../core/brand/focux_microcopy.dart';
import '../../../core/widgets/fx_action_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../../alunos/data/aluno_repository.dart';

enum FichaAcao { recomecar, duplicarBase, usarEmOutro }

enum SessaoAcao { maisUm, descanso, mover, copiar }

List<String> nomesDosDias(S s) => [
  s.rotinaDiaSeg,
  s.rotinaDiaTer,
  s.rotinaDiaQua,
  s.rotinaDiaQui,
  s.rotinaDiaSex,
  s.rotinaDiaSab,
  s.rotinaDiaDom,
];

Future<FichaAcao?> mostrarMenuDaFicha(BuildContext context) {
  final s = S.of(context);
  return showFxActionSheet<FichaAcao>(
    context,
    title: s.rotinaMenuFicha,
    itens: [
      FxActionSheetItem(
        value: FichaAcao.recomecar,
        label: s.rotinaRecomecar,
        icon: Icons.restart_alt_rounded,
        destructive: true,
      ),
      FxActionSheetItem(
        value: FichaAcao.duplicarBase,
        label: s.rotinaDuplicarBase,
        icon: Icons.copy_all_rounded,
      ),
      FxActionSheetItem(
        value: FichaAcao.usarEmOutro,
        label: s.rotinaUsarEmOutro,
        icon: Icons.people_alt_outlined,
      ),
    ],
  );
}

Future<SessaoAcao?> mostrarMenuDaSessao(
  BuildContext context, {
  required String nome,
  required bool podeCopiar,
}) {
  final s = S.of(context);
  return showFxActionSheet<SessaoAcao>(
    context,
    title: nome,
    itens: [
      FxActionSheetItem(
        value: SessaoAcao.maisUm,
        label: s.rotinaMaisUmNesteDia,
        icon: Icons.add_rounded,
      ),
      FxActionSheetItem(
        value: SessaoAcao.mover,
        label: s.rotinaMoverDia,
        icon: Icons.swap_horiz_rounded,
      ),
      if (podeCopiar)
        FxActionSheetItem(
          value: SessaoAcao.copiar,
          label: s.rotinaCopiarDia,
          icon: Icons.copy_rounded,
        ),
      FxActionSheetItem(
        value: SessaoAcao.descanso,
        label: s.rotinaMarcarDescanso,
        icon: Icons.bedtime_outlined,
        destructive: true,
      ),
    ],
  );
}

/// Dia de 1 (segunda) a 7 (domingo). [excluir] fica de fora da lista.
Future<int?> escolherDia(BuildContext context, {int? excluir}) {
  final s = S.of(context);
  final nomes = nomesDosDias(s);
  return showFxActionSheet<int>(
    context,
    title: s.rotinaEscolhaODia,
    itens: [
      for (var dia = 1; dia <= 7; dia++)
        if (dia != excluir)
          FxActionSheetItem(
            value: dia,
            label: nomes[dia - 1],
            icon: Icons.calendar_today_rounded,
          ),
    ],
  );
}

/// true = manter as cargas; false = começar do zero; null = fechou.
Future<bool?> escolherCargas(BuildContext context) {
  final s = S.of(context);
  return showFxActionSheet<bool>(
    context,
    title: s.rotinaManterCargasTitulo,
    itens: [
      FxActionSheetItem(
        value: true,
        label: s.rotinaManterCargas,
        icon: Icons.fitness_center_rounded,
      ),
      FxActionSheetItem(
        value: false,
        label: s.rotinaCargasZero,
        icon: Icons.restart_alt_rounded,
      ),
    ],
  );
}

Future<String?> pedirNomeDaSessao(BuildContext context) async {
  final s = S.of(context);
  final controle = TextEditingController();
  final nome = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(s.rotinaNomeDaSessao),
      content: TextField(
        controller: controle,
        autofocus: true,
        decoration: InputDecoration(hintText: s.rotinaNomeExemplo),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(FocuxMicrocopy.cancelar),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, controle.text.trim()),
          child: Text(s.rotinaPronto),
        ),
      ],
    ),
  );
  controle.dispose();
  return nome == null || nome.isEmpty ? null : nome;
}

Future<int?> escolherAluno(
  BuildContext context, {
  required List<Aluno> alunos,
  required int excluirId,
}) {
  return showDialog<int>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: Text(S.of(dialogContext).rotinaUsarEmOutro),
      children: [
        for (final aluno in alunos)
          if (aluno.id != excluirId)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, aluno.id),
              child: Text(aluno.nome),
            ),
      ],
    ),
  );
}
