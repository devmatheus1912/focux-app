import '../models/trilha.dart';

/// Trilha = caminho em etapas até uma conquista (barra fixa, 5 km…).
/// Peso e medida são Metas (Evolução); frequência é Aderência.
const trilhaEtapasMin = 2;
const trilhaEtapasMax = 10;

/// Etapas em ordem.
List<MarcoModel> trilhaEtapas(TrilhaModel t) =>
    [...t.marcos]..sort((a, b) => a.ordem.compareTo(b.ordem));

int trilhaEtapasFeitas(TrilhaModel t) => t.marcos.where((m) => m.concluido).length;

/// A primeira etapa ainda não feita; null quando todas estão feitas.
MarcoModel? trilhaEtapaAtual(TrilhaModel t) {
  for (final m in trilhaEtapas(t)) {
    if (!m.concluido) return m;
  }
  return null;
}

/// Data em que a última etapa foi feita (a conclusão da trilha).
DateTime? trilhaConcluidaEm(TrilhaModel t) {
  DateTime? ultima;
  for (final m in t.marcos) {
    final em = m.concluidoEm;
    if (em != null && (ultima == null || em.isAfter(ultima))) ultima = em;
  }
  return ultima;
}

/// "Etapa 2 de 5 · Próxima: Correr 3 km"; concluída, "Concluída em 10/11".
String trilhaResumoLinha(TrilhaModel t) {
  final total = t.marcos.length;
  if (total == 0) return 'Sem etapas';
  final atual = trilhaEtapaAtual(t);
  if (atual == null) {
    final em = trilhaConcluidaEm(t);
    return em == null ? 'Concluída' : 'Concluída em ${trilhaDiaMes(em.toLocal())}';
  }
  final n = trilhaEtapasFeitas(t) + 1;
  return 'Etapa $n de $total · Próxima: ${atual.titulo}';
}

DateTime? trilhaPrazo(TrilhaModel t) {
  final raw = t.dataFim?.trim();
  if (raw == null || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

String trilhaDiaMes(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

/// "até 30/11" ou, vencido e em andamento, "venceu 30/11". Concluída: sem prazo.
String? trilhaPrazoLabel(TrilhaModel t, DateTime hoje) {
  final p = trilhaPrazo(t);
  if (p == null || trilhaEtapaAtual(t) == null && t.marcos.isNotEmpty) {
    return null;
  }
  final dia = DateTime(hoje.year, hoje.month, hoje.day);
  if (!t.concluida && p.isBefore(dia)) return 'venceu ${trilhaDiaMes(p)}';
  return 'até ${trilhaDiaMes(p)}';
}

bool trilhaPrazoVencido(TrilhaModel t, DateTime hoje) {
  final p = trilhaPrazo(t);
  if (p == null || t.concluida) return false;
  return p.isBefore(DateTime(hoje.year, hoje.month, hoje.day));
}

/// Em andamento primeiro; concluídas à parte.
({List<TrilhaModel> andamento, List<TrilhaModel> concluidas}) trilhaGrupos(
  List<TrilhaModel> trilhas,
) => (
  andamento: trilhas.where((t) => !t.concluida).toList(),
  concluidas: trilhas.where((t) => t.concluida).toList(),
);

/// Linha de Trilhas nas Ferramentas do 360: a primeira trilha em andamento e a
/// etapa em que o aluno está ("Força · etapa 2 de 5 · +1").
String trilhaResumo360(TrilhaLista? lista) {
  if (lista == null) return 'Etapas e progresso';
  if (lista.items.isEmpty) return 'Nenhuma trilha';
  final ativa = lista.items.where((t) => !t.concluida).firstOrNull;
  if (ativa == null) {
    final n = lista.items.length;
    return n == 1 ? '1 trilha concluída' : '$n trilhas concluídas';
  }
  final total = ativa.marcos.length;
  final etapa = total == 0
      ? '${ativa.percentualConclusao.toStringAsFixed(0)}%'
      : 'etapa ${(trilhaEtapasFeitas(ativa) + 1).clamp(1, total)} de $total';
  final outras = lista.items.where((t) => !t.concluida).length - 1;
  final mais = outras > 0 ? ' · +$outras' : '';
  return '${ativa.titulo} · $etapa$mais';
}

/// Modelos prontos na criação (só no app): um toque preenche nome e etapas.
class TrilhaModeloPronto {
  const TrilhaModeloPronto(this.nome, this.etapas);
  final String nome;
  final List<String> etapas;
}

const trilhaModelos = [
  TrilhaModeloPronto('Primeira barra fixa', [
    'Pendurar 30 s na barra',
    '5 negativas controladas',
    'Barra com elástico 3×5',
    '1 barra fixa completa',
  ]),
  TrilhaModeloPronto('Correr 5 km', [
    'Correr 1 km sem parar',
    'Correr 2 km',
    'Correr 3 km',
    'Correr 5 km',
  ]),
  TrilhaModeloPronto('Agachamento livre', [
    'Agachar até a caixa com técnica',
    'Agachamento com halteres 3×10',
    'Agachamento livre com barra vazia',
    'Agachamento livre com carga',
  ]),
  TrilhaModeloPronto('Flexão completa', [
    'Flexão na parede 3×15',
    'Flexão com joelhos 3×10',
    'Flexão inclinada 3×10',
    '10 flexões completas',
  ]),
];

/// Etapas preenchidas, sem espaço sobrando.
List<String> trilhaEtapasValidas(Iterable<String> textos) =>
    [for (final t in textos) if (t.trim().isNotEmpty) t.trim()];

/// Erro do formulário de trilha, ou null quando dá para criar.
String? trilhaErroFormulario({required String nome, required List<String> etapas}) {
  if (nome.trim().isEmpty) return 'Dê um nome à trilha.';
  if (etapas.length < trilhaEtapasMin) return 'Preencha pelo menos 2 etapas.';
  if (etapas.length > trilhaEtapasMax) return 'Uma trilha tem no máximo 10 etapas.';
  return null;
}
