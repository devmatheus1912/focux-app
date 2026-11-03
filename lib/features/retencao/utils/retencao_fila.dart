import '../data/retencao_repository.dart';

enum RetencaoNivel {
  alto('ALTO'),
  atencao('MEDIO'),
  saudavel('BAIXO');

  const RetencaoNivel(this.api);

  final String api;

  static RetencaoNivel de(String api) => values.firstWhere(
    (n) => n.api == api,
    orElse: () => RetencaoNivel.saudavel,
  );
}

extension RetencaoAlunoNivel on RetencaoAlunoScore {
  RetencaoNivel get nivelTela => RetencaoNivel.de(nivel);
}

/// Fila sem quem já está em Chamar agora.
List<RetencaoAlunoScore> filaSem(
  List<RetencaoAlunoScore> todos,
  List<RetencaoAlunoScore> destaque,
) {
  final ids = {for (final s in destaque) s.alunoId};
  return [
    for (final s in todos)
      if (!ids.contains(s.alunoId)) s,
  ];
}

/// Busca só com lista grande: com poucos alunos, a lista inteira já está na tela.
bool mostrarBusca(RetencaoHome home) =>
    home.alto + home.medio + home.saudavel > 8;

Map<RetencaoNivel, int> retencaoContagem(RetencaoHome home) => {
  RetencaoNivel.alto: home.alto,
  RetencaoNivel.atencao: home.medio,
  RetencaoNivel.saudavel: home.saudavel,
};
