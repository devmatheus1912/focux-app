import '../../../core/money/fx_money.dart';
import '../data/financeiro_repository.dart';

/// Escolha do vencimento de uma mensalidade: o mês da cobrança é o mês do
/// vencimento (a mesma regra da recorrência). Funções puras: a folha só
/// desenha o resultado.
class VencimentoAtalho {
  const VencimentoAtalho(this.rotulo, this.data);

  final String rotulo;
  final DateTime data;
}

DateTime _soData(DateTime d) => DateTime(d.year, d.month, d.day);

int _ultimoDia(DateTime mes) => DateTime(mes.year, mes.month + 1, 0).day;

/// Dia [dia] do mês, ou o último dia quando o mês não tem esse dia.
DateTime vencimentoNoDia(DateTime mes, int dia) {
  final ultimo = _ultimoDia(mes);
  return DateTime(mes.year, mes.month, dia > ultimo ? ultimo : dia);
}

/// "Hoje" (só no mês corrente), dia 5, 10, 15 e último dia do mês.
List<VencimentoAtalho> vencimentoAtalhos({
  required DateTime mesReferencia,
  required DateTime hoje,
}) {
  final mes = DateTime(mesReferencia.year, mesReferencia.month, 1);
  final dataHoje = _soData(hoje);
  return [
    if (dataHoje.year == mes.year && dataHoje.month == mes.month)
      VencimentoAtalho('Hoje', dataHoje),
    VencimentoAtalho('Dia 5', vencimentoNoDia(mes, 5)),
    VencimentoAtalho('Dia 10', vencimentoNoDia(mes, 10)),
    VencimentoAtalho('Dia 15', vencimentoNoDia(mes, 15)),
    VencimentoAtalho('Último dia', vencimentoNoDia(mes, 31)),
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

/// Meses oferecidos: o próximo, o atual e os [anteriores] de antes.
List<DateTime> vencimentoMeses(DateTime hoje, {int anteriores = 3}) => [
  for (var i = -1; i <= anteriores; i++) DateTime(hoje.year, hoje.month - i, 1),
];

/// O que o aluno já tem num mês: bloqueia o mês, salvo se a cobrança foi
/// cancelada (o backend reaproveita a linha).
class MesOcupado {
  const MesOcupado({required this.status, required this.valor});

  final String status;
  final FxMoney valor;

  bool get bloqueia => status != 'CANCELADO';

  /// "Já lançada · R$ 175,00 · paga".
  String get rotulo => switch (status) {
    'CANCELADO' => 'Cancelada · dá para lançar de novo',
    'PAGO' => 'Já lançada · ${valor.formatCobranca()} · paga',
    'ATRASADO' => 'Já lançada · ${valor.formatCobranca()} · atrasada',
    _ => 'Já lançada · ${valor.formatCobranca()} · em aberto',
  };
}

/// Chave `aaaa-mm` do mês.
String vencimentoChaveMes(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}';

/// Meses que o aluno já tem, pela referência. [ignorarId] é a própria
/// mensalidade na edição.
Map<String, MesOcupado> vencimentoMesesOcupados(
  List<Mensalidade> doAluno, {
  int? ignorarId,
}) {
  final out = <String, MesOcupado>{};
  for (final m in doAluno) {
    if (m.id == ignorarId) continue;
    final ref = DateTime.tryParse(m.mesReferencia);
    if (ref == null) continue;
    final chave = vencimentoChaveMes(ref);
    final atual = out[chave];
    // Uma cobrança viva vence a cancelada do mesmo mês.
    if (atual == null || (!atual.bloqueia && m.status != 'CANCELADO')) {
      out[chave] = MesOcupado(status: m.status, valor: m.valor);
    }
  }
  return out;
}

/// Dia sugerido: o da última mensalidade do aluno, senão o 5.
int vencimentoDiaPreferido(List<Mensalidade> doAluno) {
  for (final m in doAluno) {
    final v = DateTime.tryParse(m.vencimento ?? '');
    if (v != null) return v.day;
  }
  return 5;
}

/// Primeiro vencimento sugerido: o primeiro mês livre a partir do atual, no
/// dia preferido; no mês corrente, se o dia já passou, hoje + 5 (lançada agora
/// não nasce atrasada). Nulo se não houver mês livre.
DateTime? vencimentoSugerido({
  required DateTime hoje,
  required Map<String, MesOcupado> ocupados,
  required int dia,
}) {
  final dataHoje = _soData(hoje);
  for (final mes in [DateTime(hoje.year, hoje.month, 1), DateTime(hoje.year, hoje.month + 1, 1)]) {
    if (ocupados[vencimentoChaveMes(mes)]?.bloqueia ?? false) continue;
    var d = vencimentoNoDia(mes, dia);
    if (d.isBefore(dataHoje)) {
      final mais5 = dataHoje.add(const Duration(days: 5));
      d = mais5.month == mes.month ? mais5 : vencimentoNoDia(mes, 31);
    }
    return d;
  }
  return null;
}

/// ISO `aaaa-mm-dd`.
String vencimentoIso(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
