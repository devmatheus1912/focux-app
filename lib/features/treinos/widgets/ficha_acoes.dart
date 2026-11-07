import 'package:flutter/material.dart';

import '../../../core/brand/focux_microcopy.dart';
import '../../../core/widgets/fx_action_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../../alunos/data/aluno_repository.dart';
import '../models/ficha_modelo.dart';
import 'aplicar_em_alunos_folha.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../core/theme/fx_icons.dart';

enum FichaAcao {
  mudarDivisao,
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

enum ModeloAcao { renomear, aplicar, mudarDivisao, recomecar, excluir }

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
        value: FichaAcao.mudarDivisao,
        label: s.rotinaMudarDivisao,
        icon: FxIcons.semana,
      ),
      FxActionSheetItem(
        value: FichaAcao.aplicarModelo,
        label: s.rotinaAplicarModelo,
        icon: FxIcons.semana,
      ),
      FxActionSheetItem(
        value: FichaAcao.salvarModelo,
        label: s.rotinaSalvarModelo,
        icon: FxIcons.salvar,
      ),
      FxActionSheetItem(
        value: FichaAcao.duplicarBase,
        label: s.rotinaDuplicarBase,
        icon: FxIcons.copiar,
      ),
      FxActionSheetItem(
        value: FichaAcao.usarEmOutro,
        label: s.rotinaUsarEmOutro,
        icon: FxIcons.grupo,
      ),
      FxActionSheetItem(
        value: FichaAcao.fichasAnteriores,
        label: s.historicoMenu,
        icon: FxIcons.historico,
      ),
      FxActionSheetItem(
        value: FichaAcao.recomecar,
        label: s.rotinaRecomecar,
        icon: FxIcons.recomecar,
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
        icon: FxIcons.adicionarPessoa,
      ),
      FxActionSheetItem(
        value: ModeloAcao.renomear,
        label: s.modeloRenomear,
        icon: FxIcons.editar,
      ),
      if (comRecomecar)
        FxActionSheetItem(
          value: ModeloAcao.mudarDivisao,
          label: s.rotinaMudarDivisao,
          icon: FxIcons.semana,
        ),
      if (comRecomecar)
        FxActionSheetItem(
          value: ModeloAcao.recomecar,
          label: s.modeloRecomecar,
          icon: FxIcons.recomecar,
        ),
      FxActionSheetItem(
        value: ModeloAcao.excluir,
        label: s.modeloExcluir,
        icon: FxIcons.excluir,
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
        icon: FxIcons.adicionar,
      ),
      if (podeCopiar)
        FxActionSheetItem(
          value: SessaoAcao.renomear,
          label: s.treinoRenomear,
          icon: FxIcons.editar,
        ),
      FxActionSheetItem(
        value: SessaoAcao.mover,
        label: s.rotinaMoverDia,
        icon: FxIcons.trocar,
      ),
      if (podeCopiar)
        FxActionSheetItem(
          value: SessaoAcao.copiar,
          label: s.rotinaCopiarDia,
          icon: FxIcons.copiar,
        ),
      FxActionSheetItem(
        value: SessaoAcao.descanso,
        label: s.rotinaMarcarDescanso,
        icon: FxIcons.sono,
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
          icon: FxIcons.repetir,
        ),
      FxActionSheetItem(
        value: DiaAcao.adicionar,
        label: segue ? s.rotinaAdicionarTreinoAqui : s.rotinaAdicionarTreino,
        icon: FxIcons.adicionar,
      ),
      if (segue)
        FxActionSheetItem(
          value: DiaAcao.descanso,
          label: s.rotinaMarcarDescanso,
          icon: FxIcons.sono,
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
            icon: FxIcons.calendario,
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
        icon: FxIcons.treino,
      ),
      FxActionSheetItem(
        value: false,
        label: s.rotinaCargasZero,
        icon: FxIcons.recomecar,
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
          icon: FxIcons.semana,
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
}) async {
  final escolhidos = await escolherAlunos(
    context,
    alunos: alunos,
    titulo: titulo ?? S.of(context).rotinaUsarEmOutro,
    varios: false,
    excluirId: excluirId,
  );
  return escolhidos?.firstOrNull?.id;
}
