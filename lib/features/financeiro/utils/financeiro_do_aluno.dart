import '../../../core/money/fx_money.dart';
import '../../../core/utils/pt_br_display.dart';
import '../data/financeiro_repository.dart';
import 'financeiro_hub_display.dart';

/// Financeiro filtrado por um aluno: resumo, linhas por mês e meses sem cobrança.

/// Mês da cobrança ("2026-11" ou "2026-11-01" viram 01/11/2026).
DateTime? _mesDe(Mensalidade m) {
  final ref = m.mesReferencia.trim();
  final anoMes = ref.length >= 7 ? ref.substring(0, 7) : ref;
  return financeiroParseIsoDate('$anoMes-01');
}

DateTime? _vencimento(Mensalidade m) =>
    financeiroParseIsoDate(m.vencimento) ?? _mesDe(m);

/// Situação na linha do mês: "Paga em 09/11", "Vence 05/12",
/// "Atrasada desde 05/11", "Cancelada".
String financeiroSituacaoDoMes(Mensalidade m) {
  switch (m.status) {
    case 'PAGO':
      final pago = DateTime.tryParse(m.pagoEm ?? '');
      return pago == null ? 'Paga' : 'Paga em ${dataCurta(pago)}';
    case 'CANCELADO':
      return 'Cancelada';
    case 'ATRASADO':
      final v = _vencimento(m);
      return v == null ? 'Atrasada' : 'Atrasada desde ${dataCurta(v)}';
    default:
      final v = _vencimento(m);
      return v == null ? 'Em aberto' : 'Vence ${dataCurta(v)}';
  }
}

/// Resumo do aluno no topo: (texto, em alerta).
/// "Em dia · R$ 700 recebidos em 2026", "1 em aberto · R$ 200 vence 05/12",
/// "1 em atraso · R$ 200 desde 05/11". [parcial]: só as carregadas.
({String texto, bool alerta}) financeiroResumoDoAluno(
  List<Mensalidade> mensalidades, {
  required DateTime hoje,
  required bool parcial,
}) {
  final recorte = parcial ? ' · nas cobranças carregadas' : '';
  final atrasadas = mensalidades.where((m) => m.status == 'ATRASADO').toList();
  final abertas = mensalidades.where((m) => m.status == 'PENDENTE').toList();
  DateTime? maisAntigo(List<Mensalidade> l) {
    DateTime? r;
    for (final m in l) {
      final v = _vencimento(m);
      if (v != null && (r == null || v.isBefore(r))) r = v;
    }
    return r;
  }

  if (atrasadas.isNotEmpty) {
    final total = atrasadas.fold(FxMoney.zero, (s, m) => s + m.valor);
    final desde = maisAntigo(atrasadas);
    return (
      texto:
          '${atrasadas.length} em atraso · ${total.formatCobranca()}${desde == null ? '' : ' desde ${dataCurta(desde)}'}$recorte',
      alerta: true,
    );
  }
  if (abertas.isNotEmpty) {
    final total = abertas.fold(FxMoney.zero, (s, m) => s + m.valor);
    final vence = maisAntigo(abertas);
    return (
      texto:
          '${abertas.length} em aberto · ${total.formatCobranca()}${vence == null ? '' : ' vence ${dataCurta(vence)}'}$recorte',
      alerta: false,
    );
  }
  final recebido = mensalidades
      .where((m) {
        if (m.status != 'PAGO') return false;
        final quando = DateTime.tryParse(m.pagoEm ?? '') ?? _mesDe(m);
        return quando?.year == hoje.year;
      })
      .fold(FxMoney.zero, (s, m) => s + m.valor);
  return (
    texto: 'Em dia · ${recebido.formatCobranca()} recebidos em ${hoje.year}$recorte',
    alerta: false,
  );
}

/// Linha da lista do aluno: uma cobrança ou um mês sem cobrança.
sealed class LinhaDoAluno {
  const LinhaDoAluno(this.mes);
  final DateTime mes;
}

class LinhaCobranca extends LinhaDoAluno {
  const LinhaCobranca(super.mes, this.mensalidade);
  final Mensalidade mensalidade;
}

class LinhaMesSemCobranca extends LinhaDoAluno {
  const LinhaMesSemCobranca(super.mes);
}

/// Lista do aluno, mês mais recente primeiro. Com [comMesesVazios], cada mês
/// entre a primeira cobrança e o de hoje sem cobrança viva entra como linha
/// "sem cobrança" (só no filtro "Todas" e com o aluno ativo).
List<LinhaDoAluno> financeiroLinhasDoAluno(
  List<Mensalidade> mensalidades, {
  required DateTime hoje,
  required bool comMesesVazios,
}) {
  final cobrancas = [
    for (final m in mensalidades)
      if (_mesDe(m) case final mes?) LinhaCobranca(mes, m),
  ]..sort((a, b) => b.mes.compareTo(a.mes));
  if (!comMesesVazios || cobrancas.isEmpty) return cobrancas;

  final vivos = {
    for (final c in cobrancas)
      if (c.mensalidade.status != 'CANCELADO') '${c.mes.year}-${c.mes.month}',
  };
  final primeiro = cobrancas.last.mes;
  final vazios = <LinhaDoAluno>[];
  for (
    var mes = DateTime(hoje.year, hoje.month, 1);
    !mes.isBefore(primeiro);
    mes = DateTime(mes.year, mes.month - 1, 1)
  ) {
    if (!vivos.contains('${mes.year}-${mes.month}')) {
      vazios.add(LinhaMesSemCobranca(mes));
    }
  }
  return [...cobrancas, ...vazios]..sort((a, b) => b.mes.compareTo(a.mes));
}
