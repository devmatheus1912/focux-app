import '../../../core/utils/pt_br_display.dart';

String businessNdrStatus(double ndrPct) {
  if (ndrPct > 100) return 'Acima do mês passado';
  if (ndrPct == 100) return 'Igual ao mês passado';
  return 'Abaixo do mês passado';
}

const businessNdrLabel = 'Receita vs. mês passado (NDR)';
const businessArpaLabel = 'Média por aluno (ARPA)';
const businessLtvLabel = 'Valor em 12 meses (LTV)';

const businessNdrAjuda =
    'Recebido neste mês dividido pelo recebido no mês passado. 100% = igual; acima disso, entrou mais dinheiro. '
    'Conta só o que já foi pago, então no começo do mês o número costuma ficar baixo até os alunos pagarem.';

const businessArpaAjuda =
    'Recebido no mês dividido pelos alunos ativos. Mostra quanto cada aluno paga, em média. '
    'Aluno sem mensalidade paga no mês puxa a média para baixo.';

const businessLtvAjuda =
    'Estimativa simples: média por aluno × 12 meses. Serve para comparar meses, não é previsão exata de quanto cada aluno vai render.';

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
    'Recebido é a soma das mensalidades pagas do mês. Toque em cada número para ver a conta.';

bool businessTemInadimplencia(int inadimplentes) => inadimplentes > 0;

bool businessTemDunning(int abertas) => abertas > 0;
