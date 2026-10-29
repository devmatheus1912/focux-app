import 'package:flutter/material.dart';

import '../../../core/brand/focux_microcopy.dart';
import '../../../core/widgets/fx_action_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../../alunos/data/aluno_repository.dart';
import '../models/ficha_modelo.dart';
import '../../../core/widgets/fx_tonal_button.dart';

enum FichaAcao {
  aplicarModelo,
  salvarModelo,
  duplicarBase,
  usarEmOutro,
  recomecar,
  fichasAnteriores,
}

enum SessaoAcao { maisUm, renomear, descanso, mover, copiar }

/// Dia sem sessão: descanso ou "segue a sequência".
enum DiaAcao { adicionar, treinar, descanso }

enum ModeloAcao { renomear, aplicar, recomecar, excluir }

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
        value: FichaAcao.aplicarModelo,
        label: s.rotinaAplicarModelo,
        icon: Icons.view_week_rounded,
      ),
      FxActionSheetItem(
        value: FichaAcao.salvarModelo,
        label: s.rotinaSalvarModelo,
        icon: Icons.bookmark_add_outlined,
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
      FxActionSheetItem(
        value: FichaAcao.fichasAnteriores,
        label: s.historicoMenu,
        icon: Icons.history_rounded,
      ),
      FxActionSheetItem(
        value: FichaAcao.recomecar,
        label: s.rotinaRecomecar,
        icon: Icons.restart_alt_rounded,
        destructive: true,
      ),
    ],
  );
}

Future<ModeloAcao?> mostrarMenuDoModelo(
  BuildContext context, {
  required String nome,
  bool comRecomecar = true,
}) {
  final s = S.of(context);
  return showFxActionSheet<ModeloAcao>(
    context,
    title: nome,
    itens: [
      FxActionSheetItem(
        value: ModeloAcao.aplicar,
        label: s.modeloAplicarEmAluno,
        icon: Icons.person_add_alt_1_rounded,
      ),
      FxActionSheetItem(
        value: ModeloAcao.renomear,
        label: s.modeloRenomear,
        icon: Icons.edit_outlined,
      ),
      if (comRecomecar)
        FxActionSheetItem(
          value: ModeloAcao.recomecar,
          label: s.modeloRecomecar,
          icon: Icons.restart_alt_rounded,
        ),
      FxActionSheetItem(
        value: ModeloAcao.excluir,
        label: s.modeloExcluir,
        icon: Icons.delete_outline_rounded,
        destructive: true,
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
      if (podeCopiar)
        FxActionSheetItem(
          value: SessaoAcao.renomear,
          label: s.treinoRenomear,
          icon: Icons.edit_outlined,
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

/// "…" de um dia sem sessão. [segue] = o dia hoje segue a sequência; senão é descanso.
Future<DiaAcao?> mostrarMenuDoDia(
  BuildContext context, {
  required String dia,
  required bool segue,
}) {
  final s = S.of(context);
  return showFxActionSheet<DiaAcao>(
    context,
    title: dia,
    itens: [
      if (!segue)
        FxActionSheetItem(
          value: DiaAcao.treinar,
          label: s.rotinaTreinarNesteDia,
          icon: Icons.repeat_rounded,
        ),
      FxActionSheetItem(
        value: DiaAcao.adicionar,
        label: segue ? s.rotinaAdicionarTreinoAqui : s.rotinaAdicionarTreino,
        icon: Icons.add_rounded,
      ),
      if (segue)
        FxActionSheetItem(
          value: DiaAcao.descanso,
          label: s.rotinaMarcarDescanso,
          icon: Icons.bedtime_outlined,
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

Future<String?> pedirNomeDaSessao(BuildContext context) {
  final s = S.of(context);
  return pedirTexto(
    context,
    titulo: s.rotinaNomeDaSessao,
    dica: s.rotinaNomeExemplo,
  );
}

/// Pede um nome ao personal; devolve null se cancelar ou deixar vazio.
Future<String?> pedirTexto(
  BuildContext context, {
  required String titulo,
  String? dica,
  String inicial = '',
}) async {
  final nome = await showDialog<String>(
    context: context,
    builder:
        (_) => _DialogoDeTexto(titulo: titulo, dica: dica, inicial: inicial),
  );
  return nome == null || nome.isEmpty ? null : nome;
}

/// O controller mora aqui para ser descartado só quando o diálogo sai da árvore,
/// depois da animação de saída (descartar logo após o `await` quebra em debug).
class _DialogoDeTexto extends StatefulWidget {
  const _DialogoDeTexto({
    required this.titulo,
    required this.inicial,
    this.dica,
  });

  final String titulo;
  final String? dica;
  final String inicial;

  @override
  State<_DialogoDeTexto> createState() => _DialogoDeTextoState();
}

class _DialogoDeTextoState extends State<_DialogoDeTexto> {
  late final TextEditingController _controle = TextEditingController(
    text: widget.inicial,
  );

  @override
  void dispose() {
    _controle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return AlertDialog(
      title: Text(widget.titulo),
      content: TextField(
        controller: _controle,
        autofocus: true,
        decoration: InputDecoration(hintText: widget.dica),
      ),
      actions: [
        FxTonalButton(
          label: FocuxMicrocopy.cancelar,
          onPressed: () => Navigator.pop(context),
          compact: true,
        ),
        FxTonalButton(
          label: s.rotinaPronto,
          onPressed: () => Navigator.pop(context, _controle.text.trim()),
          compact: true,
        ),
      ],
    );
  }
}

/// Lista os modelos do personal e devolve o escolhido (ou null).
Future<FichaModelo?> escolherModelo(
  BuildContext context,
  List<FichaModelo> modelos,
) async {
  final s = S.of(context);
  final id = await showFxActionSheet<int>(
    context,
    title: s.rotinaAplicarModelo,
    itens: [
      for (final modelo in modelos)
        FxActionSheetItem(
          value: modelo.id,
          label: modelo.nome,
          icon: Icons.view_week_rounded,
        ),
    ],
  );
  if (id == null) return null;
  return modelos.where((m) => m.id == id).firstOrNull;
}

Future<int?> escolherAluno(
  BuildContext context, {
  required List<Aluno> alunos,
  required int excluirId,
  String? titulo,
}) {
  return showDialog<int>(
    context: context,
    builder:
        (dialogContext) => SimpleDialog(
          title: Text(titulo ?? S.of(dialogContext).rotinaUsarEmOutro),
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
