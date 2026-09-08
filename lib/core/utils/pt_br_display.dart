import '../money/fx_money.dart';

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

/// Nome do treino com acentos comuns (ex.: Força).
String displayWorkoutName(String raw) {
  var name = raw.trim();
  if (name.isEmpty) return name;
  const fixes = {
    ' Forca': ' Força',
    ' forca': ' Força',
    ' FORCA': ' Força',
    'Forca ': 'Força ',
    'Forca': 'Força',
  };
  for (final entry in fixes.entries) {
    name = name.replaceAll(entry.key, entry.value);
  }
  return displayPtBr(name);
}

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

/// Formata valor monetário no padrão brasileiro (ex.: R\$ 2.000,00).
String formatBrlCurrency(Object value, {bool showDecimals = true}) {
  if (value is FxMoney) return value.format(showDecimals: showDecimals);
  if (value is! num) {
    return FxMoney.parse(value).format(showDecimals: showDecimals);
  }
  final amount = value.toDouble();
  final negative = amount < 0;
  final abs = amount.abs();
  final fixed = abs.toStringAsFixed(showDecimals ? 2 : 0);
  final parts = fixed.split('.');
  final intPart = parts[0];
  final buffer = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(intPart[i]);
  }
  final decimals =
      showDecimals && parts.length > 1 ? ',${parts[1]}' : '';
  final prefix = negative ? '-' : '';
  return '$prefix R\$ ${buffer.toString()}$decimals'.replaceFirst(' ', '');
}

/// Rótulo de mês/ano em português (ex.: Maio 2026).
String monthYearLabelPtBr(DateTime date) {
  const months = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];
  return '${months[date.month - 1]} ${date.year}';
}
