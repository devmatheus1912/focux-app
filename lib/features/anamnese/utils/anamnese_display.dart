const anamneseNiveis = [
  'SEDENTARIO',
  'LEVE',
  'MODERADO',
  'INTENSO',
  'MUITO_INTENSO',
];

String anamneseNivelLabel(String? code) {
  switch (code) {
    case 'SEDENTARIO':
      return 'Sedentário';
    case 'LEVE':
      return 'Leve';
    case 'MODERADO':
      return 'Moderado';
    case 'INTENSO':
      return 'Intenso';
    case 'MUITO_INTENSO':
      return 'Muito intenso';
    default:
      return 'Selecionar';
  }
}

String? anamneseNivelOuNulo(String? code) {
  if (code == null) return null;
  return anamneseNiveis.contains(code) ? code : null;
}

String anamneseDisponibilidadeLabel(int dias) {
  if (dias <= 1) return '1 dia por semana';
  return '$dias dias por semana';
}

int anamneseDisponibilidadeClamp(int? dias) {
  final n = dias ?? 3;
  if (n < 1) return 1;
  if (n > 7) return 7;
  return n;
}
