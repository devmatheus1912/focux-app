/// Atalhos de vencimento ("Hoje", "Dia 5", "Dia 10", "Fim do mês") para o mês
/// de referência escolhido. Funções puras: a tela só desenha o resultado.
class VencimentoAtalho {
  const VencimentoAtalho(this.rotulo, this.data);

  final String rotulo;
  final DateTime data;
}

DateTime _soData(DateTime d) => DateTime(d.year, d.month, d.day);

int _ultimoDia(DateTime mes) => DateTime(mes.year, mes.month + 1, 0).day;

/// Os atalhos do mês; dia que o mês não tem vira o último dia. "Hoje" só
/// aparece quando o mês de referência é o mês corrente.
List<VencimentoAtalho> vencimentoAtalhos({
  required DateTime mesReferencia,
  required DateTime hoje,
}) {
  final mes = DateTime(mesReferencia.year, mesReferencia.month, 1);
  final ultimo = _ultimoDia(mes);
  DateTime dia(int d) => DateTime(mes.year, mes.month, d > ultimo ? ultimo : d);
  final dataHoje = _soData(hoje);
  return [
    if (dataHoje.year == mes.year && dataHoje.month == mes.month)
      VencimentoAtalho('Hoje', dataHoje),
    VencimentoAtalho('Dia 5', dia(5)),
    VencimentoAtalho('Dia 10', dia(10)),
    VencimentoAtalho('Fim do mês', dia(ultimo)),
  ];
}

/// Data já passou: a cobrança entra como atrasada.
bool vencimentoEntraAtrasado(DateTime vencimento, DateTime hoje) =>
    _soData(vencimento).isBefore(_soData(hoje));

String vencimentoAvisoAtraso(DateTime vencimento, DateTime hoje) {
  final dias = _soData(hoje).difference(_soData(vencimento)).inDays;
  return dias == 1
      ? 'Vai entrar como atrasada (venceu ontem).'
      : 'Vai entrar como atrasada (venceu há $dias dias).';
}
