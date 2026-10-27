import '../data/retencao_repository.dart';
import 'retencao_display.dart';

/// Nível de saúde do aluno. O score vai de 0 a 100 e quanto maior, mais saudável.
enum RetencaoNivel { alto, atencao, saudavel }

/// Limites do servidor (`RetencaoScoreCalculator`): 70+ saudável, 40 a 69 atenção.
RetencaoNivel nivelDoScore(int score) => score >= 70
    ? RetencaoNivel.saudavel
    : score >= 40
    ? RetencaoNivel.atencao
    : RetencaoNivel.alto;

/// Fila sem o aluno em destaque (por id: o destaque pode vir de outra lista).
List<RetencaoAlunoScore> filaSemAluno(
  List<RetencaoAlunoScore> todos,
  int? alunoId,
) => alunoId == null
    ? todos
    : [
        for (final s in todos)
          if (s.alunoId != alunoId) s,
      ];

/// Chips de filtro só quando há mais de um grupo não vazio: com um grupo só,
/// "Todos" e o grupo dariam a mesma lista.
bool mostrarFiltros(Map<RetencaoNivel, int> contagem) =>
    contagem.values.where((n) => n > 0).length > 1;

Map<RetencaoNivel, int> retencaoContagem(RetencaoHome home) => {
  RetencaoNivel.alto: home.alto,
  RetencaoNivel.atencao: home.medio,
  RetencaoNivel.saudavel: home.saudavel,
};

/// Filtra pelo nível (nulo = todos), sem alunos sem nome real.
List<RetencaoAlunoScore> retencaoFiltrar(
  List<RetencaoAlunoScore> scores,
  RetencaoNivel? nivel,
) => [
  for (final s in scores)
    if (retencaoNomeExibivel(s.alunoNome) &&
        (nivel == null || nivelDoScore(s.scoreAtual) == nivel))
      s,
];

/// Quem chamar agora: o primeiro em risco alto, olhando a lista do servidor
/// e depois as páginas carregadas.
RetencaoAlunoScore? retencaoChamarAgora(
  List<RetencaoAlunoScore> top3,
  List<RetencaoAlunoScore> base,
) =>
    _primeiroAlto(top3) ?? _primeiroAlto(base);

RetencaoAlunoScore? _primeiroAlto(List<RetencaoAlunoScore> l) {
  for (final s in l) {
    if (retencaoNomeExibivel(s.alunoNome) &&
        nivelDoScore(s.scoreAtual) == RetencaoNivel.alto) {
      return s;
    }
  }
  return null;
}
