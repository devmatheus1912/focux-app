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

const progressaoTitulo = 'Ajustar cargas';
const progressaoAdicionarObservacao = 'Adicionar observação';
const progressaoSemExecucao =
    'Falta um treino concluído nas últimas 4 semanas para sugerir cargas.';

/// Parte do objetivo do aluno; o personal pode trocar na tela.
ProgressaoObjetivo progressaoObjetivoDoAluno(String? objetivo) {
  final texto = objetivo?.toLowerCase() ?? '';
  if (texto.contains('for')) return ProgressaoObjetivo.forca;
  if (texto.contains('resist')) return ProgressaoObjetivo.resistencia;
  return ProgressaoObjetivo.hipertrofia;
}

const progressaoGerarSugestoes = 'Gerar sugestões';
const progressaoNadaParaAjustar =
    'A IA não encontrou ajuste para este treino agora.';

String progressaoStickyLoadingLabel() => 'Gerando…';

String progressaoConfirmTitle() => 'Gerar sugestões de carga?';

String progressaoConfirmMessage() =>
    'A IA lê o treino ativo e as últimas execuções. Nada entra no treino sem você aceitar.';

String progressaoConfirmLabel() => 'Gerar';

String progressaoContextoLine(ProgressaoContextoResumo resumo) {
  return [
    resumo.exercicios == 1 ? '1 exercício' : '${resumo.exercicios} exercícios',
    switch (resumo.sessoes4Semanas) {
      0 => 'sem treinos em 4 semanas',
      1 => '1 treino em 4 semanas',
      final n => '$n treinos em 4 semanas',
    },
  ].join(' · ');
}

const progressaoContextoTitulo = 'A IA vai ler';
const progressaoSemTreinoAtivo =
    'Sem treino ativo. Monte um treino para pedir progressão.';
const progressaoObservacoesLabel = 'Observações (opcional)';
const progressaoObservacoesHint = 'Ex.: dor no ombro, semana de deload';
const progressaoAbrirTreino = 'Abrir treino';

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

/// Mudou a carga de verdade: vem marcada e aparece primeiro na revisão.
bool progressaoMudaCarga(ProgressaoSugestao s) =>
    s.deltaKg != null && s.deltaKg != 0;

/// Grupos da revisão por sessão, na ordem em que aparecem. Sem sessão fica por último.
List<(String?, List<ProgressaoSugestao>)> progressaoPorTreino(
  List<ProgressaoSugestao> sugestoes,
) {
  final grupos = <String?, List<ProgressaoSugestao>>{};
  for (final s in sugestoes) {
    grupos.putIfAbsent(s.treinoNome, () => []).add(s);
  }
  final nomes =
      grupos.keys.toList()..sort((a, b) {
        if (a == null) return 1;
        if (b == null) return -1;
        return a.compareTo(b);
      });
  return [for (final n in nomes) (n, grupos[n]!)];
}
