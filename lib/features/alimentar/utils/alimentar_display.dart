import '../data/alimentar_repository.dart';

String alimentarKcalLabel(int? caloriasDia) {
  if (caloriasDia == null) return 'Sem meta';
  return '$caloriasDia kcal/dia';
}

String alimentarHubSubtitle({
  String? alunoNome,
  String? freshness,
}) {
  const base = 'Nutrição prescrita para o aluno';
  final nome = alunoNome?.trim();
  final stamp = freshness?.trim();
  if (nome != null && nome.isNotEmpty && stamp != null && stamp.isNotEmpty) {
    return '$base · $nome · $stamp';
  }
  if (stamp != null && stamp.isNotEmpty) return '$base · $stamp';
  return base;
}

String alimentarDetailSubtitle(String? freshness) {
  const base = 'Refeições e macros do plano';
  final stamp = freshness?.trim();
  if (stamp == null || stamp.isEmpty) return base;
  return '$base · $stamp';
}

String alimentarRefeicaoKcalLabel(int? calorias) {
  if (calorias == null) return 'Sem kcal';
  return '$calorias kcal';
}

String alimentarPlanosMetricHint(int count) {
  if (count <= 0) return 'Crie o primeiro plano';
  return 'Toque para abrir as refeições';
}

PlanoAlimentar? alimentarPlanoById(List<PlanoAlimentar> planos, int planoId) {
  for (final plano in planos) {
    if (plano.id == planoId) return plano;
  }
  return null;
}

String alimentarFxIcon(int? caloriasDia) {
  if (caloriasDia == null) return 'target';
  return 'flame';
}

String alimentarKcalMetricValue(int? caloriasDia) {
  if (caloriasDia == null) return '—';
  return '$caloriasDia';
}

String alimentarKcalMetricHint(int? caloriasDia) {
  if (caloriasDia == null) return 'Sem meta diária';
  return 'kcal por dia';
}

String alimentarRefeicoesMetricValue(int count) => '$count';

String alimentarRefeicoesMetricHint(int count) {
  if (count <= 0) return 'Adicione a primeira';
  if (count == 1) return '1 refeição prescrita';
  return '$count refeições prescritas';
}

String alimentarMacrosMetricValue({
  int? proteinaG,
  int? carboidratoG,
  int? gorduraG,
}) {
  if (proteinaG == null && carboidratoG == null && gorduraG == null) {
    return '—';
  }
  final parts = <String>[];
  if (proteinaG != null) parts.add('${proteinaG}p');
  if (carboidratoG != null) parts.add('${carboidratoG}c');
  if (gorduraG != null) parts.add('${gorduraG}g');
  return parts.join(' · ');
}

String alimentarMacrosMetricHint({
  int? proteinaG,
  int? carboidratoG,
  int? gorduraG,
}) {
  if (proteinaG != null && carboidratoG != null && gorduraG != null) {
    return 'Proteína, carbo e gordura';
  }
  if (proteinaG == null && carboidratoG == null && gorduraG == null) {
    return 'Sem macros no plano';
  }
  return 'Macros parciais';
}

String alimentarRefeicaoTitle(String nome, String? horario) {
  final hora = horario?.trim();
  if (hora == null || hora.isEmpty) return nome;
  return '$nome · $hora';
}

String alimentarRefeicaoSubtitle({
  int? calorias,
  int? proteinaG,
  int? carboG,
  int? gorduraG,
}) {
  final parts = <String>[];
  if (calorias != null) parts.add(alimentarRefeicaoKcalLabel(calorias));
  if (proteinaG != null) parts.add('${proteinaG}g prot');
  if (carboG != null) parts.add('${carboG}g carbo');
  if (gorduraG != null) parts.add('${gorduraG}g gord');
  if (parts.isEmpty) return 'Sem macros nesta refeição';
  return parts.join(' · ');
}

String alimentarCampoNumerico(int? value) => value == null ? '' : '$value';

Map<String, dynamic> alimentarRefeicaoPayload({
  required String nome,
  required String horario,
  required String calorias,
  required String proteina,
  required String carbo,
  required String gordura,
  required String alimentos,
}) {
  return {
    'nomeRefeicao': nome.trim(),
    if (horario.trim().isNotEmpty) 'horario': horario.trim(),
    if (calorias.trim().isNotEmpty) 'calorias': int.tryParse(calorias.trim()),
    if (proteina.trim().isNotEmpty) 'proteinaG': int.tryParse(proteina.trim()),
    if (carbo.trim().isNotEmpty) 'carboG': int.tryParse(carbo.trim()),
    if (gordura.trim().isNotEmpty) 'gorduraG': int.tryParse(gordura.trim()),
    if (alimentos.trim().isNotEmpty) 'alimentos': alimentos.trim(),
  };
}
