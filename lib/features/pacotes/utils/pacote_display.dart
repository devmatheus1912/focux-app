const pacoteDuracaoMesesValues = [1, 3, 6, 12];

String pacoteDuracaoLabel(int meses) {
  if (meses <= 1) return '1 mês';
  return '$meses meses';
}

String pacoteIncluiValue(bool on) => on ? 'Sim' : 'Não';
