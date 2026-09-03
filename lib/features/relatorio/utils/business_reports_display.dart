import '../../../core/utils/pt_br_display.dart';

String businessNdrStatus(double ndrPct) {
  if (ndrPct >= 100) return 'Expansão';
  return 'Contração';
}

bool businessNdrRuim(double ndrPct) => ndrPct < 100;

String businessPqlLabel(String raw) {
  switch (raw.trim().toUpperCase()) {
    case 'PRIORIDADE':
      return 'Prioridade';
    case 'PQL':
      return 'Qualificado';
    case 'NURTURE':
      return 'Nutrir';
    case 'EARLY':
      return 'Início';
    default:
      return raw.trim().isEmpty ? 'Início' : raw;
  }
}

String businessAlunosLabel(int ativos, int total) => '$ativos / $total';

String businessDunningFalhasLabel(int abertas) {
  if (abertas <= 0) return 'Nenhuma aberta';
  if (abertas == 1) return '1 falha aberta';
  return '$abertas falhas abertas';
}

String businessMoneyLabel(num value) => formatBrlCurrency(value);

const businessComoCalculamos =
    'Recebido é o que entrou no mês. NDR compara o recorrente com o mês anterior.';
