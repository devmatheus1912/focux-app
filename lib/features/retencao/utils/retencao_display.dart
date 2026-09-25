import '../data/retencao_repository.dart';

String retencaoRiscoLabel(String risco) => switch (risco.trim().toUpperCase()) {
  'ALTO' => 'Risco alto',
  'MEDIO' || 'MÉDIO' => 'Risco médio',
  'BAIXO' => 'Saudável',
  _ => risco,
};

bool retencaoRiscoAlto(String risco) => risco.trim().toUpperCase() == 'ALTO';

const retencaoComoCalculamos =
    'Score 0–100 por dias únicos com check-in concluído (dois treinos no '
    'mesmo dia contam 1): alto abaixo de 40, médio 40–69, saudável 70+. '
    'A leitura atualiza ao abrir (e o job de domingo reforça). '
    'Contagens e top consideram só alunos ATIVOS com nome.';

const retencaoFiltroAlto = 'alto';

const retencaoEmptyTitle = 'Ainda sem leitura desta base';

const retencaoEmptySubtitle =
    'Cadastre alunos ativos. Ao abrir de novo, o score recalcula com os '
    'check-ins concluídos (dias únicos, sem duplicar o mesmo dia).';

/// Labels da faixa de métricas do fold (S1).
String retencaoMetricAltoLabel(int n) =>
    n == 1 ? '1 alto' : '$n altos';

String retencaoMetricMedioLabel(int n) =>
    n == 1 ? '1 médio' : '$n médios';

String retencaoMetricSaudavelLabel(int n) =>
    n == 1 ? '1 saudável' : '$n saudáveis';

/// Variação do risco alto contra a leitura de 7 dias atrás; nulo sem histórico.
String? retencaoAltoVariacaoHint(int alto, int? altoSemanaAnterior) {
  if (altoSemanaAnterior == null) return null;
  final delta = alto - altoSemanaAnterior;
  if (delta == 0) return 'Igual à semana passada';
  final sinal = delta > 0 ? '+' : '−';
  return '$sinal${delta.abs()} na semana';
}

bool retencaoNomeExibivel(String nome) {
  final t = nome.trim();
  if (t.isEmpty) return false;
  // Defesa FE: BE (#46) já exclui blank/"Aluno"; mantém filtro se payload antigo.
  return t.toLowerCase() != 'aluno';
}

/// Subtítulo do card de foco. Contagens BE já são ATIVO+#46; topNomeados
/// só reforça se o payload ainda trouxer placeholder.
String retencaoContagensSubtitulo({
  required int alto,
  required int medio,
  required int saudavel,
  required int topNomeados,
}) {
  final base = '$medio médios · $saudavel saudáveis';
  if (alto > 0 && topNomeados == 0) {
    return '$base · atualize a base se o top vier vazio';
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

/// Ações do focus — 1 P0 no fold (A30 / §0.1).
enum RetencaoFocusActionId { chat, cobrar, aluno360, verAlunos }

({RetencaoFocusActionId primary, List<RetencaoFocusActionId> secondary})
retencaoFocusActions({required bool hasAlto}) {
  if (!hasAlto) {
    return (
      primary: RetencaoFocusActionId.verAlunos,
      secondary: const <RetencaoFocusActionId>[],
    );
  }
  return (
    primary: RetencaoFocusActionId.chat,
    secondary: const [
      RetencaoFocusActionId.cobrar,
      RetencaoFocusActionId.aluno360,
    ],
  );
}

String retencaoFocusActionLabel(RetencaoFocusActionId id) => switch (id) {
  RetencaoFocusActionId.chat => 'Escrever',
  RetencaoFocusActionId.cobrar => 'Cobrar',
  RetencaoFocusActionId.aluno360 => 'Abrir aluno',
  RetencaoFocusActionId.verAlunos => 'Ver alunos',
};

/// Hubs satélite do fold — atrás de um toque.
enum RetencaoHubLinkId { winback, dunning }

const retencaoHubLinks = <RetencaoHubLinkId>[
  RetencaoHubLinkId.winback,
  RetencaoHubLinkId.dunning,
];

String retencaoHubLinkLabel(RetencaoHubLinkId id) => switch (id) {
  RetencaoHubLinkId.winback => 'Histórico win-back',
  RetencaoHubLinkId.dunning => 'Cobrança auto',
};

String retencaoHubLinkRoute(RetencaoHubLinkId id) => switch (id) {
  RetencaoHubLinkId.winback => '/winback',
  RetencaoHubLinkId.dunning => '/dunning',
};
