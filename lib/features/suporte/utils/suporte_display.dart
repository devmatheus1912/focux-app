const suporteSeveridadeValues = ['BAIXA', 'MEDIA', 'ALTA', 'CRITICA'];

String suporteSeveridadeLabel(String? value) {
  switch ((value ?? '').trim().toUpperCase()) {
    case 'BAIXA':
      return 'Baixa';
    case 'MEDIA':
      return 'Média';
    case 'ALTA':
      return 'Alta';
    case 'CRITICA':
      return 'Crítica';
    case '':
      return 'Média';
    default:
      return value!.trim();
  }
}
