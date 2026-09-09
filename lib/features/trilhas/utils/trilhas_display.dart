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

String trilhaHubSubtitle({required String alunoNome}) {
  final nome = alunoNome.trim().isEmpty ? 'Aluno' : alunoNome.trim();
  return nome;
}

const trilhaPrazoDias = [7, 14, 30, 60, 90];

DateTime? trilhaParseData(String? raw) {
  final text = raw?.trim();
  if (text == null || text.isEmpty) return null;
  return DateTime.tryParse(text);
}

String trilhaDataLabel(DateTime data) {
  final day = data.day.toString().padLeft(2, '0');
  final month = data.month.toString().padLeft(2, '0');
  return '$day/$month';
}

String trilhaPrazoOpcaoLabel(int? dias) {
  if (dias == null) return 'Sem prazo';
  return 'Em $dias dias';
}

String? trilhaPrazoIso(int? dias, DateTime today) {
  if (dias == null) return null;
  final data = DateTime(today.year, today.month, today.day).add(
    Duration(days: dias),
  );
  final y = data.year.toString().padLeft(4, '0');
  final m = data.month.toString().padLeft(2, '0');
  final d = data.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

DateTime? trilhaProximoPrazo(List<TrilhaModel> trilhas) {
  DateTime? nearest;
  for (final trilha in trilhas) {
    if (trilha.concluida) continue;
    final data = trilhaParseData(trilha.dataFim);
    if (data == null) continue;
    if (nearest == null || data.isBefore(nearest)) nearest = data;
  }
  return nearest;
}

String trilhaPrazoMetricValue(List<TrilhaModel> trilhas) {
  final data = trilhaProximoPrazo(trilhas);
  if (data == null) return '—';
  return trilhaDataLabel(data);
}

String trilhaPrazoMetricHint(List<TrilhaModel> trilhas) {
  if (trilhaAtivasCount(trilhas) == 0) return 'Nenhuma trilha ativa';
  if (trilhaProximoPrazo(trilhas) == null) return 'Sem prazo nas ativas';
  return 'Próximo prazo das ativas';
}

int trilhaListaAtivas(TrilhaLista lista) =>
    lista.ativas ?? trilhaAtivasCount(lista.items);

String trilhaListaProgressoLabel(TrilhaLista lista) {
  if (lista.progressoMedio != null) {
    return trilhaPercentLabel(lista.progressoMedio!);
  }
  return trilhaProgressoMedioLabel(lista.items);
}

String trilhaListaPrazoValue(TrilhaLista lista) {
  final parsed = trilhaParseData(lista.proximoPrazo);
  if (parsed != null) return trilhaDataLabel(parsed);
  return trilhaPrazoMetricValue(lista.items);
}

String trilhaListaPrazoHint(TrilhaLista lista) {
  if (trilhaListaAtivas(lista) == 0) return 'Nenhuma trilha ativa';
  if (trilhaParseData(lista.proximoPrazo) != null ||
      trilhaProximoPrazo(lista.items) != null) {
    return 'Próximo prazo das ativas';
  }
  return 'Sem prazo nas ativas';
}

String trilhaCardContexto(TrilhaModel trilha) {
  final parts = <String>[
    trilhaMetaTipoLabel(trilha.metaTipo),
    trilhaValorAtualLabel(trilha),
  ];
  final prazo = trilhaParseData(trilha.dataFim);
  if (prazo != null) parts.add('até ${trilhaDataLabel(prazo)}');
  return parts.join(' · ');
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
