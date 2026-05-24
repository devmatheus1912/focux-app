/// Normaliza textos exibidos quando a origem veio sem acentuação PT-BR.
String displayPtBr(String value) {
  if (value.isEmpty) return value;

  var result = value;
  const replacements = {
    'Abducao': 'Abdução',
    'abducao': 'abdução',
    'Aducao': 'Adução',
    'aducao': 'adução',
    'Adducao': 'Addução',
    'adducao': 'addução',
    'Elevacao': 'Elevação',
    'elevacao': 'elevação',
    'Extensao': 'Extensão',
    'extensao': 'extensão',
    'Flexao': 'Flexão',
    'flexao': 'flexão',
    'Rotacao': 'Rotação',
    'rotacao': 'rotação',
    'Inclinacao': 'Inclinação',
    'inclinacao': 'inclinação',
    'Panturrilha': 'Panturrilha',
    'Maquina': 'Máquina',
    'maquina': 'máquina',
    'Serie': 'Série',
    'serie': 'série',
    'Series': 'Séries',
    'series': 'séries',
    'Tecnica': 'Técnica',
    'tecnica': 'técnica',
    'Reducao': 'Redução',
    'reducao': 'redução',
    'Forca': 'Força',
    'forca': 'força',
    'Resistencia': 'Resistência',
    'resistencia': 'resistência',
    'Proxima': 'Próxima',
    'proxima': 'próxima',
    'Organizacao': 'Organização',
    'organizacao': 'organização',
    'Variacao': 'Variação',
    'variacao': 'variação',
    'Abdomen': 'Abdômen',
    'abdomen': 'abdômen',
    'Obliquo': 'Oblíquo',
    'obliquo': 'oblíquo',
    'Trapezio': 'Trapézio',
    'trapezio': 'trapézio',
    'Gluteo': 'Glúteo',
    'gluteo': 'glúteo',
    'Quadriceps': 'Quadríceps',
    'quadriceps': 'quadríceps',
    'Biceps': 'Bíceps',
    'biceps': 'bíceps',
    'Triceps': 'Tríceps',
    'triceps': 'tríceps',
    'Avanco': 'Avanço',
    'avanco': 'avanço',
    'Unilateral': 'Unilateral',
    'Posterior': 'Posterior',
    'Condicionamento': 'Condicionamento',
    'Demonstracao': 'Demonstração',
    'demonstracao': 'demonstração',
    'Execucao': 'Execução',
    'execucao': 'execução',
    'Respiracao': 'Respiração',
    'respiracao': 'respiração',
    'Amplitude': 'Amplitude',
  };

  for (final entry in replacements.entries) {
    result = result.replaceAll(entry.key, entry.value);
  }

  result = result.replaceAllMapped(
    RegExp(r'(\w)cao\b', caseSensitive: false),
    (match) => '${match.group(1)}ção',
  );
  result = result.replaceAllMapped(
    RegExp(r'(\w)sao\b', caseSensitive: false),
    (match) => '${match.group(1)}são',
  );
  result = result.replaceAllMapped(
    RegExp(r'(\w)aco\b', caseSensitive: false),
    (match) => '${match.group(1)}aço',
  );
  result = result.replaceAllMapped(
    RegExp(r'(\w)icio\b', caseSensitive: false),
    (match) => '${match.group(1)}ício',
  );

  return result;
}

String displayExerciseName(String nome) => displayPtBr(nome.trim());

String displayMetaToken(String value) {
  final normalized = value.trim().replaceAll('_', ' ').toLowerCase();
  if (normalized.isEmpty) return normalized;
  final titled = normalized
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1))
      .join(' ');
  return displayPtBr(titled);
}
