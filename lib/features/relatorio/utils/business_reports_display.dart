import '../../../core/utils/pt_br_display.dart';

String businessNdrStatus(double? ndrPct) {
  if (ndrPct == null) return 'Sem mês anterior para comparar';
  if (ndrPct > 100) return 'Os mesmos alunos pagam mais';
  if (ndrPct == 100) return 'Os mesmos alunos pagam igual';
  return 'Os mesmos alunos pagam menos';
}

String businessPctLabel(double? pct) =>
    pct == null ? '—' : formatBrPercent(pct);

const businessNdrLabel = 'Retenção de receita (NDR)';
const businessArpaLabel = 'Média por aluno (ARPA)';
const businessLtvLabel = 'Valor por aluno (LTV)';

const businessNdrAjuda =
    'Pega só os alunos que tinham cobrança no mês passado e compara quanto eles têm neste mês. '
    '100% = igual; acima disso, eles pagam mais (aumento ou upgrade). Aluno novo não entra, então o número mostra se você segura a base.';

const businessArpaAjuda =
    'Faturado no mês dividido pelos alunos com cobrança no mês. Conta mensalidade paga e em aberto, '
    'então não oscila conforme o dia do pagamento.';

const businessLtvAjuda =
    'Média por aluno × quantos meses um aluno costuma ficar. A permanência sai da saída do último mês '
    '(1 ÷ churn), com teto de 36 meses. Sem histórico, usamos 12 meses.';

bool businessNdrRuim(double? ndrPct) => ndrPct != null && ndrPct < 100;

String businessArpaHint(int pagantes) => pagantes == 1
    ? 'Faturado ÷ 1 aluno com cobrança'
    : 'Faturado ÷ $pagantes alunos com cobrança';

String businessLtvHint(double vidaMediaMeses, double? churnPct) {
  final meses = vidaMediaMeses.toStringAsFixed(
    vidaMediaMeses == vidaMediaMeses.roundToDouble() ? 0 : 1,
  ).replaceAll('.', ',');
  if (churnPct == null) return 'Média por aluno × $meses meses (sem histórico)';
  return 'Média × $meses meses · saída ${businessPctLabel(churnPct)} no mês';
}

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

String businessAlunosLabel(int ativos, int total) =>
    total == 1 ? '$ativos de 1 aluno ativo' : '$ativos de $total alunos ativos';

String businessRecuperacaoLabel(double pct, int abertas) => abertas <= 0
    ? businessDunningFalhasLabel(abertas)
    : '${businessPctLabel(pct)} recuperado · ${businessDunningFalhasLabel(abertas)}';

String businessDunningFalhasLabel(int abertas) {
  if (abertas <= 0) return 'Nenhuma aberta';
  if (abertas == 1) return '1 falha aberta';
  return '$abertas falhas abertas';
}

String businessMoneyLabel(num value) => formatBrlCurrency(value);

const businessComoCalculamos =
    'Recebido é o que entrou no mês pela data do pagamento. Previsto é tudo lançado para o mês, pago ou não. Toque em cada número para ver a conta.';

bool businessTemInadimplencia(int inadimplentes) => inadimplentes > 0;

bool businessTemDunning(int abertas) => abertas > 0;
