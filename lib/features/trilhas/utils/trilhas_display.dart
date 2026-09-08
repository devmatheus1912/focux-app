import '../models/trilha.dart';

const trilhaMetaTipos = ['TREINOS', 'PESO', 'MEDIDA', 'CUSTOMIZADO'];
const trilhaFiltroAndamento = 'andamento';
const trilhaFiltroConcluidas = 'concluidas';

const trilhaFiltroOpcoes = <({String value, String label})>[
  (value: trilhaFiltroAndamento, label: 'Em andamento'),
  (value: trilhaFiltroConcluidas, label: 'Concluídas'),
];

String trilhaMetaTipoLabel(String? tipo) {
  switch ((tipo ?? '').trim().toUpperCase()) {
    case 'TREINOS':
      return 'Número de treinos';
    case 'PESO':
      return 'Meta de peso';
    case 'MEDIDA':
      return 'Meta de medida';
    case 'CUSTOMIZADO':
      return 'Customizado';
    case '':
      return 'Tipo de meta';
    default:
      return tipo!.trim();
  }
}

String trilhaMetaValorHint(String? tipo) {
  switch ((tipo ?? '').trim().toUpperCase()) {
    case 'TREINOS':
      return 'Quantos treinos fecham a meta';
    case 'PESO':
      return 'Peso alvo (kg)';
    case 'MEDIDA':
      return 'Medida alvo (cm)';
    default:
      return 'Valor da meta (opcional)';
  }
}

String trilhaStatusLabel(bool concluida) =>
    concluida ? 'Concluída' : 'Em andamento';

String trilhaPercentLabel(double percentual) =>
    '${percentual.toStringAsFixed(0)}%';

String trilhaHubSubtitle({
  required String alunoNome,
  String? freshness,
}) {
  final nome = alunoNome.trim().isEmpty ? 'Aluno' : alunoNome.trim();
  final stamp = freshness?.trim();
  if (stamp == null || stamp.isEmpty) return nome;
  return '$nome · $stamp';
}

int trilhaAtivasCount(List<TrilhaModel> trilhas) =>
    trilhas.where((t) => !t.concluida).length;

int trilhaConcluidasCount(List<TrilhaModel> trilhas) =>
    trilhas.where((t) => t.concluida).length;

int trilhaMarcosPendentes(List<TrilhaModel> trilhas) => trilhas
    .expand((t) => t.marcos)
    .where((m) => !m.concluido)
    .length;

double trilhaProgressoMedio(List<TrilhaModel> trilhas) {
  if (trilhas.isEmpty) return 0;
  final soma = trilhas.fold<double>(0, (acc, t) => acc + t.percentualConclusao);
  return soma / trilhas.length;
}

String trilhaProgressoMedioLabel(List<TrilhaModel> trilhas) =>
    trilhaPercentLabel(trilhaProgressoMedio(trilhas));

List<TrilhaModel> trilhaFiltradas(
  List<TrilhaModel> trilhas,
  String filtro,
) {
  if (filtro == trilhaFiltroConcluidas) {
    return trilhas.where((t) => t.concluida).toList();
  }
  return trilhas.where((t) => !t.concluida).toList();
}

MarcoModel? trilhaProximoMarco(TrilhaModel trilha) {
  for (final marco in trilha.marcos) {
    if (!marco.concluido) return marco;
  }
  return null;
}

String trilhaValorAtualLabel(TrilhaModel trilha) {
  if (trilha.metaValor == null) {
    final done = trilha.marcos.where((m) => m.concluido).length;
    return '$done/${trilha.marcos.length}';
  }
  final atual = trilha.valorAtual.toStringAsFixed(
    trilha.valorAtual == trilha.valorAtual.roundToDouble() ? 0 : 1,
  );
  final meta = trilha.metaValor!.toStringAsFixed(
    trilha.metaValor == trilha.metaValor!.roundToDouble() ? 0 : 1,
  );
  return '$atual / $meta';
}

double? trilhaParseNumero(String raw) {
  final text = raw.trim().replaceAll(',', '.');
  if (text.isEmpty) return null;
  return double.tryParse(text);
}

List<String> trilhaMarcosTitulos(Iterable<String> raw) =>
    raw.map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
