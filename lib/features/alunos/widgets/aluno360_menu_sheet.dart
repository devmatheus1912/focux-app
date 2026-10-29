import 'package:flutter/material.dart';

import '../../../core/widgets/fx_grouped_action_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../data/aluno_repository.dart';
import '../utils/aluno360_menu_acoes.dart';
import '../utils/aluno_status.dart';

/// Folha do ⋮ do perfil 360: cadastro, acesso e, por último, o que é perigoso.
/// Devolve o item escolhido; quem chama roda o fluxo (cada um já confirma).
Future<Aluno360MenuItem?> showAluno360MenuSheet(
  BuildContext context,
  Aluno aluno,
) {
  final s = S.of(context);
  final itens = aluno360MenuItens(aluno);

  FxActionItem<Aluno360MenuItem> linha(Aluno360MenuItem i) {
    final (icone, rotulo, descricao) = switch (i.acao) {
      Aluno360MenuAcao.editar => (
        Icons.edit_outlined,
        s.aluno360MenuEditar,
        s.aluno360MenuEditarSub,
      ),
      Aluno360MenuAcao.criarTarefa => (
        Icons.playlist_add_check_rounded,
        s.aluno360MenuCriarTarefa,
        s.aluno360MenuCriarTarefaSub,
      ),
      Aluno360MenuAcao.reenviarLink =>
        aluno.contaAtiva
            ? (
              Icons.lock_reset_rounded,
              s.aluno360MenuLinkNovaSenha,
              s.aluno360MenuLinkNovaSenhaSub,
            )
            : (
              Icons.link_rounded,
              s.alunoReenviarLinkAcao,
              s.aluno360MenuLinkAcessoSub,
            ),
      Aluno360MenuAcao.status => (
        alunoStatusIcon(i.novoStatus ?? ''),
        alunoStatusAcaoLabel(i.novoStatus ?? ''),
        switch (alunoStatusNormalizado(i.novoStatus ?? '')) {
          AlunoStatus.inativo => s.aluno360MenuPausarSub,
          AlunoStatus.bloqueado => s.aluno360MenuBloquearSub,
          _ => s.aluno360MenuReativarSub,
        },
      ),
      Aluno360MenuAcao.excluir => (
        Icons.delete_outline_rounded,
        s.aluno360MenuExcluir,
        s.aluno360MenuExcluirSub,
      ),
    };
    return FxActionItem(
      valor: i,
      rotulo: rotulo,
      icone: icone,
      descricao: descricao,
      perigo: i.destrutivo && i.acao != Aluno360MenuAcao.excluir,
    );
  }

  List<FxActionItem<Aluno360MenuItem>> doGrupo(Aluno360MenuGrupo g) => [
    for (final i in itens)
      if (i.grupo == g && i.acao != Aluno360MenuAcao.excluir) linha(i),
  ];

  final excluir = itens.where((i) => i.acao == Aluno360MenuAcao.excluir);
  final perigo = doGrupo(Aluno360MenuGrupo.perigo);
  return showFxGroupedActionSheet<Aluno360MenuItem>(
    context,
    titulo: s.aluno360MenuTitulo,
    subtitulo: aluno.nome,
    grupos: [
      FxActionGroup(
        s.aluno360MenuGrupoCadastro,
        doGrupo(Aluno360MenuGrupo.cadastro),
      ),
      FxActionGroup(s.aluno360MenuGrupoAcesso, doGrupo(Aluno360MenuGrupo.acesso)),
      if (perigo.isNotEmpty) FxActionGroup(s.aluno360MenuGrupoPerigo, perigo),
    ],
    destrutiva: excluir.isEmpty ? null : linha(excluir.first),
    // Cada fluxo (bloquear, excluir) já tem a própria confirmação.
    confirmar: false,
  );
}
