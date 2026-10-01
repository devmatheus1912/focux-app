import '../models/progressao_sugestao.dart';

/// PT-BR copy helpers for progressão de carga flows.
const progressaoObservacoesMax = 500;

enum ProgressaoObjetivo {
  forca('FORCA', 'Força'),
  hipertrofia('HIPERTROFIA', 'Hipertrofia'),
  resistencia('RESISTENCIA', 'Resistência');

  const ProgressaoObjetivo(this.api, this.label);

  final String api;
  final String label;
}

String progressaoHubSubtitle(String alunoNome) {
  final nome = alunoNome.trim();
  if (nome.isEmpty) return 'Sugestão de carga, só se você pedir';
  return '$nome · só se você pedir';
}

String progressaoStickyLabel({required bool hasResult}) =>
    hasResult ? 'Gerar outra' : 'Gerar progressão';

String progressaoStickyLoadingLabel() => 'Gerando…';

String progressaoConfirmTitle() => 'Gerar progressão com IA?';

String progressaoConfirmMessage() =>
    'A IA lê o treino ativo e as últimas execuções. Nada entra no treino sem você aceitar.';

String progressaoConfirmLabel() => 'Gerar';

String progressaoPendingMetricHint(int count) {
  if (count <= 0) return 'Nada pendente neste aluno';
  if (count == 1) return '1 sugestão para revisar';
  return '$count sugestões para revisar';
}

String progressaoPendingReviewLabel(int count) {
  if (count <= 0) return 'Revisar sugestões pendentes';
  if (count == 1) return 'Revisar 1 sugestão pendente';
  return 'Revisar $count sugestões pendentes';
}

String progressaoSavedForReviewSnack(int count) {
  if (count == 1) return '1 sugestão salva para revisão.';
  return '$count sugestões salvas para revisão.';
}

String progressaoAceitarSemanticsLabel(int count) =>
    count > 0
        ? 'Revisar $count sugestões pendentes de progressão'
        : 'Revisar sugestões pendentes de progressão';

String progressaoContextoLine(ProgressaoContextoResumo resumo) {
  final partes = <String>[
    if (resumo.treinos.isNotEmpty) resumo.treinos.join(', '),
    resumo.exercicios == 1 ? '1 exercício' : '${resumo.exercicios} exercícios',
    switch (resumo.sessoes4Semanas) {
      0 => 'sem treinos concluídos em 4 semanas',
      1 => '1 treino concluído em 4 semanas',
      final n => '$n treinos concluídos em 4 semanas',
    },
  ];
  return partes.join(' · ');
}

const progressaoContextoTitulo = 'A IA vai ler';
const progressaoSemTreinoAtivo =
    'Sem treino ativo. Monte um treino para pedir progressão.';
const progressaoObservacoesLabel = 'Observações (opcional)';
const progressaoObservacoesHint = 'Ex.: dor no ombro, semana de deload';
const progressaoNaoEncontrada = 'Fora do treino ativo';
const progressaoNaoEncontradaHint =
    'O exercício mudou ou saiu do treino. Ajuste no treino ou descarte.';
const progressaoAbrirTreino = 'Abrir treino';
const progressaoRevisarAplicar = 'Revisar e aplicar';
const progressaoErroManteveResultado =
    'Mantive a sugestão anterior na tela.';

String progressaoAceitarTodasLabel(int count) =>
    count == 1 ? 'Aceitar 1 sugestão' : 'Aceitar todas ($count)';

String progressaoAceitarTodasConfirm(int count) =>
    count == 1
        ? 'Carga, séries e repetições vão para o treino ativo.'
        : 'As $count sugestões vão para o treino ativo (carga, séries e repetições).';

String progressaoAceitarTodasSnack(ProgressaoAceitarTodasResponse r) {
  final aplicadas = switch (r.aplicadas) {
    0 => 'Nenhuma sugestão aplicada',
    1 => '1 sugestão aplicada',
    final n => '$n sugestões aplicadas',
  };
  if (r.naoEncontradas == 0) return '$aplicadas no treino.';
  return '$aplicadas. ${r.naoEncontradas} fora do treino ativo.';
}

String progressaoForaDoTreinoResumo(int count) =>
    count == 1
        ? '1 sugestão fora do treino ativo'
        : '$count sugestões fora do treino ativo';

const progressaoTentarDeNovo = 'Tentar de novo';
const progressaoDescartarTodas = 'Descartar todas';

String progressaoDescartarForaConfirm(int count) =>
    count == 1
        ? 'A sugestão fora do treino ativo será removida.'
        : 'As $count sugestões fora do treino ativo serão removidas.';

String progressaoDescartadasSnack(int count) =>
    count == 1 ? '1 sugestão descartada.' : '$count sugestões descartadas.';

String _doisDigitos(int n) => n.toString().padLeft(2, '0');

String progressaoDataHora(DateTime d) =>
    '${_doisDigitos(d.day)}/${_doisDigitos(d.month)}/${d.year} '
    '${_doisDigitos(d.hour)}:${_doisDigitos(d.minute)}';

String progressaoGeradoLabel(DateTime d) => 'Gerado em ${progressaoDataHora(d)}';

String progressaoSlug(String value) {
  const de = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
  const para = 'aaaaaeeeeiiiiooooouuuucn';
  final buf = StringBuffer();
  for (final ch in value.trim().toLowerCase().split('')) {
    final i = de.indexOf(ch);
    buf.write(i >= 0 ? para[i] : ch);
  }
  final slug = buf
      .toString()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return slug.isEmpty ? 'aluno' : slug;
}

String progressaoPdfFileName(String alunoNome, DateTime d) =>
    'progressao_${progressaoSlug(alunoNome)}_'
    '${d.year}-${_doisDigitos(d.month)}-${_doisDigitos(d.day)}.pdf';
