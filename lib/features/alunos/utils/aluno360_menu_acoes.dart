import '../data/aluno_repository.dart';
import 'aluno_status.dart';

enum Aluno360MenuAcao { editar, criarTarefa, reenviarLink, status, excluir }

/// Uma linha do ⋮ do perfil 360. Em [status], [novoStatus] diz o destino.
class Aluno360MenuItem {
  const Aluno360MenuItem(
    this.acao, {
    this.novoStatus,
    this.separadorAntes = false,
  });

  final Aluno360MenuAcao acao;
  final String? novoStatus;
  final bool separadorAntes;

  bool get destrutivo =>
      acao == Aluno360MenuAcao.excluir || novoStatus == AlunoStatus.bloqueado;

  @override
  bool operator ==(Object other) =>
      other is Aluno360MenuItem &&
      other.acao == acao &&
      other.novoStatus == novoStatus &&
      other.separadorAntes == separadorAntes;

  @override
  int get hashCode => Object.hash(acao, novoStatus, separadorAntes);
}

/// Itens do ⋮: cadastro e tarefa, status e, por último e separado, excluir.
/// "Reenviar link" só aparece com a conta ainda não ativa.
List<Aluno360MenuItem> aluno360MenuItens(Aluno aluno) {
  final status = alunoStatusAcoesDisponiveis(aluno.status);
  return [
    const Aluno360MenuItem(Aluno360MenuAcao.editar),
    const Aluno360MenuItem(Aluno360MenuAcao.criarTarefa),
    if (!aluno.contaAtiva) const Aluno360MenuItem(Aluno360MenuAcao.reenviarLink),
    for (final (i, novo) in status.indexed)
      Aluno360MenuItem(
        Aluno360MenuAcao.status,
        novoStatus: novo,
        separadorAntes: i == 0,
      ),
    const Aluno360MenuItem(Aluno360MenuAcao.excluir, separadorAntes: true),
  ];
}
