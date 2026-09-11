import '../data/retencao_repository.dart';

String retencaoRiscoLabel(String risco) => switch (risco.trim().toUpperCase()) {
  'ALTO' => 'Risco alto',
  'MEDIO' || 'MÉDIO' => 'Risco médio',
  'BAIXO' => 'Saudável',
  _ => risco,
};

bool retencaoRiscoAlto(String risco) => risco.trim().toUpperCase() == 'ALTO';

const retencaoComoCalculamos =
    'Score 0–100: alto abaixo de 40, médio 40–69, saudável 70 ou mais. '
    'Contagens vêm do último score por aluno (podem incluir inativos). '
    'O catálogo pagina a base e busca pelo nome.';

const retencaoFiltroAlto = 'alto';

const retencaoEmptyTitle = 'Ainda sem leitura desta base';

const retencaoEmptySubtitle =
    'O cálculo roda no domingo. Cadastre alunos ativos ou fale no win-back com quem já sumiu.';

bool retencaoNomeExibivel(String nome) {
  final t = nome.trim();
  if (t.isEmpty) return false;
  return t.toLowerCase() != 'aluno';
}

/// Subtítulo do card de foco: contagens BE + recorte nomeado do top.
String retencaoContagensSubtitulo({
  required int alto,
  required int medio,
  required int saudavel,
  required int topNomeados,
}) {
  final base = '$medio médios · $saudavel saudáveis';
  if (alto > 0 && topNomeados == 0) {
    return '$base · top sem nome — confira a base';
  }
  if (alto > topNomeados && topNomeados > 0) {
    return '$base · $topNomeados com nome no top';
  }
  return base;
}

String retencaoNormalizeFiltro(String? raw) {
  final value = (raw ?? '').trim().toLowerCase();
  return value == retencaoFiltroAlto ? retencaoFiltroAlto : '';
}

String retencaoPorque(RetencaoAlunoScore score) {
  final risco = retencaoRiscoLabel(score.riscoChurn);
  if (score.delta < 0) return '$risco · caiu ${-score.delta} pts';
  if (score.delta > 0) return '$risco · subiu ${score.delta} pts';
  return '$risco · score ${score.scoreAtual}';
}

List<RetencaoAlunoScore> retencaoItemsForFiltro(
  List<RetencaoAlunoScore> scores,
  String? filtro,
) {
  final named = scores.where((s) => retencaoNomeExibivel(s.alunoNome)).toList();
  if (retencaoNormalizeFiltro(filtro) == retencaoFiltroAlto) {
    return named.where((s) => retencaoRiscoAlto(s.riscoChurn)).toList();
  }
  return named;
}

RetencaoAlunoScore? firstAltoRetencao(List<RetencaoAlunoScore> scores) {
  for (final s in scores) {
    if (retencaoRiscoAlto(s.riscoChurn) && retencaoNomeExibivel(s.alunoNome)) {
      return s;
    }
  }
  return null;
}
