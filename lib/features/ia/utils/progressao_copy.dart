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

  String get descricao => switch (this) {
    ProgressaoObjetivo.forca => 'Mais carga, menos repetições.',
    ProgressaoObjetivo.hipertrofia => 'Carga e repetições para crescer.',
    ProgressaoObjetivo.resistencia => 'Mais repetições, carga moderada.',
  };
}

const progressaoTitulo = 'Ajustar cargas';
const progressaoAdicionarObservacao = 'Algo para considerar? (opcional)';

/// Atalhos do pedido: viram `sinais` para o servidor (que trava o resultado),
/// não texto no campo.
enum ProgressaoSinal {
  semanaLeve('Semana leve', 'SEMANA_LEVE'),
  dor('Dor', 'DOR'),
  poucoTempo('Pouco tempo', 'POUCO_TEMPO');

  const ProgressaoSinal(this.label, this.api);
  final String label;
  final String api;
}

const progressaoSemExecucao =
    'Sem treino concluído em 4 semanas. As sugestões precisam de pelo menos um.';

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

const progressaoContextoTitulo = 'Sugestões com base no que foi treinado';
const progressaoSemTreinoAtivo =
    'Sem treino ativo. Monte um treino para pedir progressão.';
const progressaoObservacoesLabel = 'Observação (opcional)';
const progressaoObservacoesHint = 'Ex.: dor no ombro direito';
const progressaoAbrirTreino = 'Abrir treino';

/// "18 kg · 4×8-10" vira a carga e a prescrição.
({String carga, String prescricao}) progressaoPartes(String texto) {
  final m = RegExp(r'^(.*?kg)\s*[·\s]*(.*)$').firstMatch(texto.trim());
  if (m == null) return (carga: texto.trim(), prescricao: '');
  return (carga: m.group(1)!.trim(), prescricao: m.group(2)!.trim());
}

String progressaoKg(double kg) =>
    '${kg.toStringAsFixed(kg % 1 == 0 ? 0 : 1).replaceAll('.', ',')} kg';

/// "+1,5 kg" ou "−1,5 kg", já com a carga editada. Nulo sem mudança ou sem número.
String? progressaoDiferenca(ProgressaoSugestao s, double? editada) {
  final delta =
      editada != null && s.cargaSugeridaKg != null
          ? (s.deltaKg ?? 0) + editada - s.cargaSugeridaKg!
          : s.deltaKg;
  if (delta == null || delta == 0) return null;
  return '${delta > 0 ? '+' : '−'}${progressaoKg(delta.abs())}';
}

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

String progressaoGeradoLabel(DateTime d) =>
    'Gerado em ${progressaoDataHora(d)}';

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

/// Frase do "Gerando": muda com o tempo e diz o que a IA está fazendo, com os
/// números do cartão de cima quando há contexto.
String progressaoGerandoFrase(
  Duration passou,
  ProgressaoContextoResumo? contexto,
) {
  if (passou < const Duration(seconds: 4)) {
    final n = contexto?.sessoes4Semanas ?? 0;
    return n > 0
        ? (n == 1
            ? 'Lendo o treino das últimas 4 semanas…'
            : 'Lendo os $n treinos das últimas 4 semanas…')
        : 'Lendo os treinos recentes…';
  }
  if (passou < const Duration(seconds: 10)) {
    final n = contexto?.exercicios ?? 0;
    return n > 0
        ? (n == 1
            ? 'Comparando as cargas de 1 exercício…'
            : 'Comparando as cargas de $n exercícios…')
        : 'Comparando as cargas…';
  }
  return 'Quase pronto. A IA leva até 30 segundos.';
}

String progressaoProntas(int n) =>
    n == 1 ? '1 sugestão pronta' : '$n sugestões prontas';

const progressaoPodeSair =
    'Pode sair desta tela. As sugestões ficam esperando em Ajustar cargas.';

/// O que foi pedido, em uma linha: objetivo, sinais e a observação.
String progressaoPedidoLinha({
  required ProgressaoObjetivo objetivo,
  required Iterable<ProgressaoSinal> sinais,
  required String observacao,
}) {
  final obs = observacao.trim();
  return [
    objetivo.label,
    for (final s in sinais) s.label,
    if (obs.isNotEmpty) '“$obs”',
  ].join(' · ');
}
