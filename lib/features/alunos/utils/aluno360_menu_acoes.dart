import '../data/aluno_repository.dart';
import 'aluno_status.dart';

enum Aluno360MenuAcao { editar, criarTarefa, reenviarLink, status, excluir }

/// Em qual grupo da folha do ⋮ a linha aparece.
enum Aluno360MenuGrupo { cadastro, acesso, perigo }

/// Uma linha do ⋮ do perfil 360. Em [status], [novoStatus] diz o destino.
class Aluno360MenuItem {
  const Aluno360MenuItem(this.acao, {this.novoStatus});

  final Aluno360MenuAcao acao;
  final String? novoStatus;

  bool get destrutivo =>
      acao == Aluno360MenuAcao.excluir || novoStatus == AlunoStatus.bloqueado;

  Aluno360MenuGrupo get grupo => switch (acao) {
    Aluno360MenuAcao.editar ||
    Aluno360MenuAcao.criarTarefa => Aluno360MenuGrupo.cadastro,
    Aluno360MenuAcao.reenviarLink => Aluno360MenuGrupo.acesso,
    Aluno360MenuAcao.status =>
      destrutivo ? Aluno360MenuGrupo.perigo : Aluno360MenuGrupo.acesso,
    Aluno360MenuAcao.excluir => Aluno360MenuGrupo.perigo,
  };

  @override
  bool operator ==(Object other) =>
      other is Aluno360MenuItem &&
      other.acao == acao &&
      other.novoStatus == novoStatus;

  @override
  int get hashCode => Object.hash(acao, novoStatus);
}

/// Itens do ⋮: cadastro e tarefa, acesso (link e status) e, por último, o que
/// é perigoso. O link de acesso aparece sempre: para conta ainda não ativa é o
/// primeiro acesso; para conta ativa, o jeito de o aluno criar uma senha nova.
List<Aluno360MenuItem> aluno360MenuItens(Aluno aluno) {
  final status = alunoStatusAcoesDisponiveis(aluno.status);
  return [
    const Aluno360MenuItem(Aluno360MenuAcao.editar),
    const Aluno360MenuItem(Aluno360MenuAcao.criarTarefa),
    const Aluno360MenuItem(Aluno360MenuAcao.reenviarLink),
    for (final novo in status)
      Aluno360MenuItem(Aluno360MenuAcao.status, novoStatus: novo),
    const Aluno360MenuItem(Aluno360MenuAcao.excluir),
  ];
}
